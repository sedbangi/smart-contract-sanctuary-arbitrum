// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

import "../interfaces/IPriceFeed.sol";
import "../interfaces/IThalesAMMUtils.sol";
import "../interfaces/IPositionalMarket.sol";
import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IStakingThales.sol";
import "../interfaces/IReferrals.sol";
import "../interfaces/ICurveSUSD.sol";

import "./LiquidityPool/ThalesAMMLiquidityPool.sol";

/// @title An AMM using BlackScholes odds algorithm to provide liqudidity for traders of UP or DOWN positions
contract ThalesAMM is Initializable, ProxyOwned, ProxyPausable, ProxyReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct BuyPriceImpactParams {
        address market;
        IThalesAMM.Position position;
        uint amount;
        uint _availableToBuyFromAMM;
        uint _availableToBuyFromAMMOtherSide;
        ThalesAMMLiquidityPool liquidityPool;
        uint basePrice;
    }

    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;

    IPriceFeed public priceFeed;
    IERC20Upgradeable public sUSD;
    address public manager;

    uint public capPerMarket;
    uint public min_spread;
    uint public max_spread;

    mapping(bytes32 => uint) public impliedVolatilityPerAsset;

    uint public minimalTimeLeftToMaturity;

    mapping(address => uint) public spentOnMarket;

    address public safeBox;
    uint public safeBoxImpact;

    IStakingThales public stakingThales;

    uint public minSupportedPrice;
    uint public maxSupportedPrice;

    mapping(bytes32 => uint) private _capPerAsset;

    mapping(address => bool) public whitelistedAddresses;

    address public referrals;
    uint public referrerFee;

    ICurveSUSD public curveSUSD;

    address public usdc;
    address public usdt;
    address public dai;

    bool public curveOnrampEnabled;

    uint public maxAllowedPegSlippagePercentage;

    IThalesAMMUtils ammUtils;

    int private constant ONE_INT = 1e18;
    int private constant ONE_PERCENT_INT = 1e16;

    mapping(address => uint) public safeBoxFeePerAddress;
    mapping(address => uint) public min_spreadPerAddress;

    ThalesAMMLiquidityPool public liquidityPool;

    function initialize(
        address _owner,
        IPriceFeed _priceFeed,
        IERC20Upgradeable _sUSD,
        uint _capPerMarket,
        // address _deciMath,
        uint _min_spread,
        uint _max_spread,
        uint _minimalTimeLeftToMaturity
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        priceFeed = _priceFeed;
        sUSD = _sUSD;
        capPerMarket = _capPerMarket;
        min_spread = _min_spread;
        max_spread = _max_spread;
        minimalTimeLeftToMaturity = _minimalTimeLeftToMaturity;
    }

    // READ public methods

    /// @notice get how many positions of a certain type (UP or DOWN) can be bought from the given positional market
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @return _available how many positions of that type can be bought
    function availableToBuyFromAMM(address market, IThalesAMM.Position position) public view returns (uint _available) {
        if (isMarketInAMMTrading(market)) {
            uint basePrice = price(market, position);
            if (basePrice > 0) {
                basePrice = basePrice < minSupportedPrice ? minSupportedPrice : basePrice;
                _available = _availableToBuyFromAMMWithBasePrice(market, position, basePrice, false);
            }
        }
    }

    /// @notice get a quote in sUSD on how much the trader would need to pay to buy the amount of UP or DOWN positions
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount number of positions to buy with 18 decimals
    /// @return _quote in sUSD on how much the trader would need to pay to buy the amount of UP or DOWN positions
    function buyFromAmmQuote(
        address market,
        IThalesAMM.Position position,
        uint amount
    ) public view returns (uint _quote) {
        uint basePrice = price(market, position);
        uint basePriceOtherSide = ONE - basePrice;
        if (basePrice > 0) {
            basePrice = basePrice < minSupportedPrice ? minSupportedPrice : basePrice;
            _quote = _buyFromAmmQuoteWithBasePrice(market, position, amount, basePrice, basePriceOtherSide, safeBoxImpact);
        }
    }

    /// @notice get a quote in the collateral of choice (USDC, USDT or DAI) on how much the trader would need to pay to buy the amount of UP or DOWN positions
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount number of positions to buy with 18 decimals
    /// @param collateral USDT, USDC or DAI address
    /// @return collateralQuote a quote in collateral on how much the trader would need to pay to buy the amount of UP or DOWN positions
    /// @return sUSDToPay a quote in sUSD on how much the trader would need to pay to buy the amount of UP or DOWN positions
    function buyFromAmmQuoteWithDifferentCollateral(
        address market,
        IThalesAMM.Position position,
        uint amount,
        address collateral
    ) public view returns (uint collateralQuote, uint sUSDToPay) {
        int128 curveIndex = _mapCollateralToCurveIndex(collateral);
        if (curveIndex > 0 && curveOnrampEnabled) {
            sUSDToPay = buyFromAmmQuote(market, position, amount);
            //cant get a quote on how much collateral is needed from curve for sUSD,
            //so rather get how much of collateral you get for the sUSD quote and add 0.2% to that
            collateralQuote = (curveSUSD.get_dy_underlying(0, curveIndex, sUSDToPay) * (ONE + (ONE_PERCENT / 5))) / ONE;
        }
    }

    /// @notice get the skew impact applied to that side of the market on buy
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount number of positions to buy with 18 decimals
    /// @return _priceImpact the skew impact applied to that side of the market
    function buyPriceImpact(
        address market,
        IThalesAMM.Position position,
        uint amount
    ) public view returns (int _priceImpact) {
        IThalesAMM.Position positionOtherSide = position == IThalesAMM.Position.Up
            ? IThalesAMM.Position.Down
            : IThalesAMM.Position.Up;
        uint basePrice = price(market, position);

        if (basePrice >= minSupportedPrice && basePrice <= maxSupportedPrice) {
            uint basePriceOtherSide = ONE - basePrice;
            uint _availableToBuyFromAMM = _availableToBuyFromAMMWithBasePrice(market, position, basePrice, true);
            uint _availableToBuyFromAMMOtherSide = _availableToBuyFromAMMWithBasePrice(
                market,
                positionOtherSide,
                basePriceOtherSide,
                true
            );
            if (amount > 0 && amount <= _availableToBuyFromAMM) {
                _priceImpact = _buyPriceImpact(
                    BuyPriceImpactParams(
                        market,
                        position,
                        amount,
                        _availableToBuyFromAMM,
                        _availableToBuyFromAMMOtherSide,
                        liquidityPool,
                        basePrice
                    )
                );
            }
        }
    }

    /// @notice get how many positions of a certain type (UP or DOWN) can be sold for the given positional market
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @return _available how many positions of that type can be sold
    function availableToSellToAMM(address market, IThalesAMM.Position position) public view returns (uint _available) {
        if (isMarketInAMMTrading(market)) {
            uint basePrice = price(market, position);
            basePrice = basePrice > maxSupportedPrice ? maxSupportedPrice : basePrice;
            _available = _availableToSellToAMM(market, position, basePrice);
        }
    }

    /// @notice get a quote in sUSD on how much the trader would receive as payment to sell the amount of UP or DOWN positions
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount number of positions to buy with 18 decimals
    /// @return _quote in sUSD on how much the trader would receive as payment to sell the amount of UP or DOWN positions
    function sellToAmmQuote(
        address market,
        IThalesAMM.Position position,
        uint amount
    ) public view returns (uint _quote) {
        uint basePrice = price(market, position);
        basePrice = basePrice > maxSupportedPrice ? maxSupportedPrice : basePrice;
        uint _available = _availableToSellToAMM(market, position, basePrice);
        _quote = _sellToAmmQuote(market, position, amount, basePrice, _available);
    }

    /// @notice get the skew impact applied to that side of the market on sell
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount number of positions to buy with 18 decimals
    /// @return _impact the skew impact applied to that side of the market
    function sellPriceImpact(
        address market,
        IThalesAMM.Position position,
        uint amount
    ) public view returns (uint _impact) {
        uint _available = availableToSellToAMM(market, position);
        if (amount <= _available) {
            _impact = _sellPriceImpact(market, position, amount, _available);
        }
    }

    /// @notice get the base price (odds) of a given side of the market
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @return priceToReturn the base price (odds) of a given side of the market
    function price(address market, IThalesAMM.Position position) public view returns (uint priceToReturn) {
        if (isMarketInAMMTrading(market)) {
            // add price calculation
            IPositionalMarket marketContract = IPositionalMarket(market);
            (uint maturity, ) = marketContract.times();

            uint timeLeftToMaturity = maturity - block.timestamp;
            uint timeLeftToMaturityInDays = (timeLeftToMaturity * ONE) / 86400;
            uint oraclePrice = marketContract.oraclePrice();

            (bytes32 key, uint strikePrice, ) = marketContract.getOracleDetails();

            priceToReturn =
                ammUtils.calculateOdds(oraclePrice, strikePrice, timeLeftToMaturityInDays, impliedVolatilityPerAsset[key]) /
                1e2;

            if (position == IThalesAMM.Position.Down) {
                priceToReturn = ONE - priceToReturn;
            }
        }
    }

    /// @notice check if market is supported by the AMM
    /// @param market positional market known to manager
    /// @return isTrading is market supported by the AMM
    function isMarketInAMMTrading(address market) public view returns (bool isTrading) {
        if (IPositionalMarketManager(manager).isActiveMarket(market)) {
            IPositionalMarket marketContract = IPositionalMarket(market);
            (bytes32 key, , ) = marketContract.getOracleDetails();
            (uint maturity, ) = marketContract.times();

            if (!(impliedVolatilityPerAsset[key] == 0 || maturity < block.timestamp)) {
                uint timeLeftToMaturity = maturity - block.timestamp;
                isTrading = timeLeftToMaturity > minimalTimeLeftToMaturity;
            }
        }
    }

    /// @notice get the maximum risk in sUSD the AMM will offer on a certain asset on an individual market
    /// @param asset e.g. ETH, BTC, SNX....
    /// @return _cap the maximum risk in sUSD the AMM will offer on a certain asset on an individual market
    function getCapPerAsset(bytes32 asset) public view returns (uint _cap) {
        if (!(priceFeed.rateForCurrency(asset) == 0)) {
            _cap = _capPerAsset[asset] == 0 ? capPerMarket : _capPerAsset[asset];
        }
    }

    // write methods

    /// @notice buy positions of the defined type of a given market from the AMM coming from a referrer
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount how many positions
    /// @param expectedPayout how much does the buyer expect to pay (retrieved via quote)
    /// @param additionalSlippage how much of a slippage on the sUSD expectedPayout will the buyer accept
    /// @param _referrer who referred the buyer to Thales
    function buyFromAMMWithReferrer(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage,
        address _referrer
    ) public nonReentrant notPaused returns (uint) {
        if (_referrer != address(0)) {
            IReferrals(referrals).setReferrer(_referrer, msg.sender);
        }
        return _buyFromAMM(market, position, amount, expectedPayout, additionalSlippage, true, 0);
    }

    /// @notice buy positions of the defined type of a given market from the AMM with USDC, USDT or DAI
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount how many positions
    /// @param expectedPayout how much does the buyer expect to pay (retrieved via quote)
    /// @param collateral USDC, USDT or DAI
    /// @param additionalSlippage how much of a slippage on the sUSD expectedPayout will the buyer accept
    /// @param _referrer who referred the buyer to Thales
    function buyFromAMMWithDifferentCollateralAndReferrer(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage,
        address collateral,
        address _referrer
    ) public nonReentrant notPaused returns (uint) {
        if (_referrer != address(0)) {
            IReferrals(referrals).setReferrer(_referrer, msg.sender);
        }

        int128 curveIndex = _mapCollateralToCurveIndex(collateral);
        require(curveIndex > 0 && curveOnrampEnabled, "unsupported collateral");

        (uint collateralQuote, uint susdQuote) = buyFromAmmQuoteWithDifferentCollateral(
            market,
            position,
            amount,
            collateral
        );

        uint transformedCollateralForPegCheck = collateral == usdc || collateral == usdt
            ? collateralQuote * (1e12)
            : collateralQuote;
        require(
            maxAllowedPegSlippagePercentage > 0 &&
                transformedCollateralForPegCheck >= (susdQuote * (ONE - (maxAllowedPegSlippagePercentage))) / ONE,
            "Amount below max allowed peg slippage"
        );

        require((collateralQuote * ONE) / (expectedPayout) <= (ONE + additionalSlippage), "Slippage too high!");

        IERC20Upgradeable collateralToken = IERC20Upgradeable(collateral);
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralQuote);
        curveSUSD.exchange_underlying(curveIndex, 0, collateralQuote, susdQuote);

        return _buyFromAMM(market, position, amount, susdQuote, additionalSlippage, false, susdQuote);
    }

    /// @notice buy positions of the defined type of a given market from the AMM
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount how many positions
    /// @param expectedPayout how much does the buyer expect to pay (retrieved via quote)
    /// @param additionalSlippage how much of a slippage on the sUSD expectedPayout will the buyer accept
    function buyFromAMM(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) public nonReentrant notPaused returns (uint) {
        return _buyFromAMM(market, position, amount, expectedPayout, additionalSlippage, true, 0);
    }

    /// @notice sell positions of the defined type of a given market to the AMM
    /// @param market a Positional Market known to Market Manager
    /// @param position UP or DOWN
    /// @param amount how many positions
    /// @param expectedPayout how much does the seller to receive(retrieved via quote)
    /// @param additionalSlippage how much of a slippage on the sUSD expectedPayout will the seller accept
    function sellToAMM(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) public nonReentrant notPaused returns (uint) {
        require(isMarketInAMMTrading(market), "Market is not in Trading phase");

        uint basePrice = price(market, position);
        basePrice = basePrice > maxSupportedPrice ? maxSupportedPrice : basePrice;
        uint availableToSellToAMMATM = _availableToSellToAMM(market, position, basePrice);
        require(availableToSellToAMMATM > 0 && amount <= availableToSellToAMMATM, "Not enough liquidity.");

        uint pricePaid = _sellToAmmQuote(market, position, amount, basePrice, availableToSellToAMMATM);
        require((expectedPayout * ONE) / (pricePaid) <= (ONE + (additionalSlippage)), "Slippage too high");

        address target = _getTarget(market, position);

        _transferPositions(market);

        //transfer options first to have max burn available
        IERC20Upgradeable(target).safeTransferFrom(msg.sender, address(this), amount);

        uint sUSDFromBurning = IPositionalMarketManager(manager).transformCollateral(
            IPositionalMarket(market).getMaximumBurnable(address(this))
        );
        if (sUSDFromBurning > 0) {
            IPositionalMarket(market).burnOptionsMaximum();
        }

        uint safeBoxShare = (pricePaid * ONE) / (ONE - (safeBoxImpact)) - pricePaid;
        uint referrerShare = (pricePaid * ONE) / (ONE - (referrerFee)) - pricePaid;
        if (safeBoxImpact == 0) {
            safeBoxShare = 0;
        }

        liquidityPool.commitTrade(
            market,
            IPositionalMarketManager(manager).reverseTransformCollateral(pricePaid + safeBoxShare + referrerShare)
        );
        sUSD.safeTransfer(msg.sender, pricePaid);

        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(msg.sender, pricePaid);
        }

        _updateSpentOnMarketOnSell(market, pricePaid, sUSDFromBurning, msg.sender, safeBoxShare);

        _sendMintedPositionsAndUSDToLiquidityPool(market);

        emit SoldToAMM(msg.sender, market, position, amount, pricePaid, address(sUSD), target);
        return pricePaid;
    }

    function _transferPositions(address market) internal {
        (uint upBalance, uint downBalance) = ammUtils.getBalanceOfPositionsOnMarket(
            market,
            liquidityPool.getMarketPool(market)
        );

        liquidityPool.getOptionsForBuy(market, upBalance, IThalesAMM.Position.Up);
        liquidityPool.getOptionsForBuy(market, downBalance, IThalesAMM.Position.Down);
    }

    /// @notice Retrieve sUSD from the contract
    /// @param account whom to send the sUSD
    /// @param amount how much sUSD to retrieve
    function retrieveSUSDAmount(address payable account, uint amount) external onlyOwner {
        sUSD.safeTransfer(account, amount);
    }

    // Internal

    function _availableToSellToAMM(
        address market,
        IThalesAMM.Position position,
        uint basePrice
    ) internal view returns (uint _available) {
        uint sell_max_price = _getSellMaxPrice(basePrice);
        if (sell_max_price > 0) {
            (, uint balanceOfTheOtherSide) = ammUtils.balanceOfPositionsOnMarket(
                market,
                position,
                liquidityPool.getMarketPool(market)
            );

            // any balanceOfTheOtherSide will be burned to get sUSD back (1 to 1) at the `willPay` cost
            uint willPay = (balanceOfTheOtherSide * (sell_max_price)) / ONE;
            uint capWithBalance = _capOnMarket(market) + (balanceOfTheOtherSide);
            if (capWithBalance >= (spentOnMarket[market] + willPay)) {
                uint usdAvailable = capWithBalance - (spentOnMarket[market]) - (willPay);
                _available = (usdAvailable / (sell_max_price)) * ONE + (balanceOfTheOtherSide);
            }
        }
    }

    function _sellToAmmQuote(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint basePrice,
        uint _available
    ) internal view returns (uint _quote) {
        if (amount <= _available) {
            basePrice = basePrice - (min_spread);

            uint tempAmount = (amount *
                ((basePrice * (ONE - (_sellPriceImpact(market, position, amount, _available)))) / ONE)) / ONE;

            uint returnQuote = (tempAmount * (ONE - (safeBoxImpact))) / ONE;
            _quote = IPositionalMarketManager(manager).transformCollateral(returnQuote);
        }
    }

    function _availableToBuyFromAMMWithBasePrice(
        address market,
        IThalesAMM.Position position,
        uint basePrice,
        bool skipCheck
    ) internal view returns (uint availableAmount) {
        if (skipCheck || basePrice < maxSupportedPrice) {
            basePrice = basePrice + min_spread;
            if (basePrice < ONE) {
                uint discountedPrice = (basePrice * (ONE - max_spread / 2)) / ONE;
                uint balance = ammUtils.balanceOfPositionOnMarket(market, position, liquidityPool.getMarketPool(market));
                uint additionalBufferFromSelling = (balance * discountedPrice) / ONE;

                if ((_capOnMarket(market) + additionalBufferFromSelling) > spentOnMarket[market]) {
                    uint availableUntilCapSUSD = _capOnMarket(market) + additionalBufferFromSelling - spentOnMarket[market];
                    if (availableUntilCapSUSD > _capOnMarket(market)) {
                        availableUntilCapSUSD = _capOnMarket(market);
                    }

                    uint midImpactPriceIncrease = ((ONE - basePrice) * (max_spread / 2)) / ONE;
                    if ((basePrice + midImpactPriceIncrease) < ONE) {
                        uint divider_price = ONE - (basePrice + midImpactPriceIncrease);

                        availableAmount = balance + ((availableUntilCapSUSD * ONE) / divider_price);
                    }
                }
            }
        }
    }

    function _buyFromAmmQuoteWithBasePrice(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint basePrice,
        uint basePriceOtherSide,
        uint safeBoxImpactForCaller
    ) internal view returns (uint returnQuote) {
        uint _available = _availableToBuyFromAMMWithBasePrice(market, position, basePrice, false);
        uint _availableOtherSide = _availableToBuyFromAMMWithBasePrice(
            market,
            position == IThalesAMM.Position.Up ? IThalesAMM.Position.Down : IThalesAMM.Position.Up,
            basePriceOtherSide,
            true
        );

        if (amount <= _available) {
            int tempQuote;
            int skewImpact = _buyPriceImpact(
                BuyPriceImpactParams(market, position, amount, _available, _availableOtherSide, liquidityPool, basePrice)
            );
            basePrice = basePrice + (min_spreadPerAddress[msg.sender] > 0 ? min_spreadPerAddress[msg.sender] : min_spread);
            if (skewImpact >= 0) {
                int impactPrice = ((ONE_INT - int(basePrice)) * skewImpact) / ONE_INT;
                // add 2% to the price increase to avoid edge cases on the extremes
                impactPrice = (impactPrice * (ONE_INT + (ONE_PERCENT_INT * 2))) / ONE_INT;
                tempQuote = (int(amount) * (int(basePrice) + impactPrice)) / ONE_INT;
            } else {
                tempQuote = ((int(amount)) * ((int(basePrice) * (ONE_INT + skewImpact)) / ONE_INT)) / ONE_INT;
            }
            tempQuote = (tempQuote * (ONE_INT + (int(safeBoxImpactForCaller)))) / ONE_INT;
            returnQuote = IPositionalMarketManager(manager).transformCollateral(uint(tempQuote));
        }
    }

    function _getSellMaxPrice(uint basePrice) internal view returns (uint sell_max_price) {
        if (basePrice > minSupportedPrice) {
            sell_max_price = ((basePrice - min_spread) * (ONE - (max_spread / (2)))) / ONE;
        }
    }

    function _buyFromAMM(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage,
        bool sendSUSD,
        uint sUSDPaidCarried
    ) internal returns (uint sUSDPaid) {
        require(isMarketInAMMTrading(market), "Market is not in Trading phase");

        sUSDPaid = sUSDPaidCarried;

        uint basePrice = price(market, position);
        uint basePriceOtherSide = ONE - basePrice;

        basePrice = basePrice < minSupportedPrice ? minSupportedPrice : basePrice;

        uint availableToBuyFromAMMatm = _availableToBuyFromAMMWithBasePrice(market, position, basePrice, false);
        require(amount > 0 && amount <= availableToBuyFromAMMatm, "Not enough liquidity.");

        if (sendSUSD) {
            sUSDPaid = _buyFromAmmQuoteWithBasePrice(
                market,
                position,
                amount,
                basePrice,
                basePriceOtherSide,
                safeBoxFeePerAddress[msg.sender] > 0 ? safeBoxFeePerAddress[msg.sender] : safeBoxImpact
            );
            require((sUSDPaid * ONE) / (expectedPayout) <= (ONE + additionalSlippage), "Slippage too high");

            sUSD.safeTransferFrom(msg.sender, address(this), sUSDPaid);
        }

        uint toMint = _getMintableAmount(market, position, amount);
        if (toMint > 0) {
            liquidityPool.commitTrade(market, toMint);
            IPositionalMarket(market).mint(toMint);
            spentOnMarket[market] = spentOnMarket[market] + toMint;
        }
        liquidityPool.getOptionsForBuy(market, amount - toMint, position);

        address target = _getTarget(market, position);
        IERC20Upgradeable(target).safeTransfer(msg.sender, amount);

        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(msg.sender, sUSDPaid);
        }
        _updateSpentOnMarketOnBuy(market, sUSDPaid, msg.sender);

        if (amount > toMint) {
            uint discountedAmount = amount - toMint;
            uint paidForDiscountedAmount = (sUSDPaid * discountedAmount) / amount;
            emit BoughtWithDiscount(msg.sender, discountedAmount, paidForDiscountedAmount);
        }

        _sendMintedPositionsAndUSDToLiquidityPool(market);

        emit BoughtFromAmm(msg.sender, market, position, amount, sUSDPaid, address(sUSD), target);
        _handleInTheMoneyEvent(market, position, sUSDPaid, msg.sender);
    }

    function _handleInTheMoneyEvent(
        address market,
        IThalesAMM.Position position,
        uint sUSDPaid,
        address sender
    ) internal {
        (bytes32 key, uint strikePrice, ) = IPositionalMarket(market).getOracleDetails();
        uint currentAssetPrice = priceFeed.rateForCurrency(key);
        bool inTheMoney = position == IThalesAMM.Position.Up
            ? currentAssetPrice >= strikePrice
            : currentAssetPrice < strikePrice;
        emit BoughtOptionType(msg.sender, sUSDPaid, inTheMoney);
    }

    function _getTarget(address market, IThalesAMM.Position position) internal view returns (address target) {
        (IPosition up, IPosition down) = IPositionalMarket(market).getOptions();
        target = address(position == IThalesAMM.Position.Up ? up : down);
    }

    function _updateSpentOnMarketOnSell(
        address market,
        uint sUSDPaid,
        uint sUSDFromBurning,
        address seller,
        uint safeBoxShare
    ) internal {
        if (safeBoxImpact > 0) {
            sUSD.safeTransfer(safeBox, safeBoxShare);
        }

        spentOnMarket[market] =
            spentOnMarket[market] +
            (IPositionalMarketManager(manager).reverseTransformCollateral(sUSDPaid + (safeBoxShare)));
        if (spentOnMarket[market] <= IPositionalMarketManager(manager).reverseTransformCollateral(sUSDFromBurning)) {
            spentOnMarket[market] = 0;
        } else {
            spentOnMarket[market] =
                spentOnMarket[market] -
                (IPositionalMarketManager(manager).reverseTransformCollateral(sUSDFromBurning));
        }

        if (referrerFee > 0 && referrals != address(0)) {
            uint referrerShare = (sUSDPaid * ONE) / (ONE - (referrerFee)) - (sUSDPaid);
            _handleReferrer(seller, referrerShare, sUSDPaid);
        }
    }

    function _updateSpentOnMarketOnBuy(
        address market,
        uint sUSDPaid,
        address buyer
    ) internal {
        uint safeBoxShare;
        if (safeBoxImpact > 0) {
            safeBoxShare = (sUSDPaid -
                (sUSDPaid * ONE) /
                (ONE + (safeBoxFeePerAddress[msg.sender] > 0 ? safeBoxFeePerAddress[msg.sender] : safeBoxImpact)));
            sUSD.safeTransfer(safeBox, safeBoxShare);
        }

        if (
            spentOnMarket[market] <= IPositionalMarketManager(manager).reverseTransformCollateral(sUSDPaid - (safeBoxShare))
        ) {
            spentOnMarket[market] = 0;
        } else {
            spentOnMarket[market] =
                spentOnMarket[market] -
                (IPositionalMarketManager(manager).reverseTransformCollateral(sUSDPaid - (safeBoxShare)));
        }

        if (referrerFee > 0 && referrals != address(0)) {
            uint referrerShare = sUSDPaid - ((sUSDPaid * ONE) / (ONE + (referrerFee)));
            _handleReferrer(buyer, referrerShare, sUSDPaid);
        }
    }

    function _buyPriceImpact(BuyPriceImpactParams memory params) internal view returns (int priceImpact) {
        if (params.basePrice >= minSupportedPrice && params.basePrice <= maxSupportedPrice) {
            (uint balancePosition, uint balanceOtherSide) = ammUtils.balanceOfPositionsOnMarket(
                params.market,
                params.position,
                params.liquidityPool.getMarketPool(params.market)
            );

            uint balancePositionAfter = balancePosition > params.amount ? balancePosition - params.amount : 0;
            uint balanceOtherSideAfter = balanceOtherSide +
                (balancePosition > params.amount ? 0 : (params.amount - balancePosition));
            if (balancePositionAfter >= balanceOtherSideAfter) {
                priceImpact = ammUtils.calculateDiscount(
                    IThalesAMMUtils.DiscountParams(
                        balancePosition,
                        balanceOtherSide,
                        params.amount,
                        params._availableToBuyFromAMMOtherSide,
                        max_spread
                    )
                );
            } else {
                if (params.amount > balancePosition && balancePosition > 0) {
                    uint amountToBeMinted = params.amount - balancePosition;
                    uint positiveSkew = ammUtils.buyPriceImpactImbalancedSkew(
                        IThalesAMMUtils.PriceImpactParams(
                            amountToBeMinted,
                            balanceOtherSide + balancePosition,
                            0,
                            balanceOtherSide + amountToBeMinted,
                            0,
                            params._availableToBuyFromAMM - balancePosition,
                            max_spread
                        )
                    );

                    uint pricePosition = price(params.market, params.position);
                    uint priceOtherPosition = price(
                        params.market,
                        params.position == IThalesAMM.Position.Up ? IThalesAMM.Position.Down : IThalesAMM.Position.Up
                    );
                    uint skew = (priceOtherPosition * positiveSkew) / pricePosition;

                    int discount = ammUtils.calculateDiscount(
                        IThalesAMMUtils.DiscountParams(
                            balancePosition,
                            balanceOtherSide,
                            balancePosition,
                            params._availableToBuyFromAMMOtherSide,
                            max_spread
                        )
                    );

                    int discountBalance = int(balancePosition) * discount;
                    int discountMinted = int(amountToBeMinted * skew);
                    int amountInt = int(balancePosition + amountToBeMinted);

                    priceImpact = (discountBalance + discountMinted) / amountInt;

                    if (priceImpact > 0) {
                        int numerator = int(pricePosition) * priceImpact;
                        priceImpact = numerator / int(priceOtherPosition);
                    }
                } else {
                    priceImpact = int(
                        ammUtils.buyPriceImpactImbalancedSkew(
                            IThalesAMMUtils.PriceImpactParams(
                                params.amount,
                                balanceOtherSide,
                                balancePosition,
                                balanceOtherSideAfter,
                                balancePositionAfter,
                                params._availableToBuyFromAMM,
                                max_spread
                            )
                        )
                    );
                }
            }
        }
    }

    function _handleReferrer(
        address buyer,
        uint referrerShare,
        uint volume
    ) internal {
        address referrer = IReferrals(referrals).referrals(buyer);
        if (referrer != address(0) && referrerFee > 0) {
            sUSD.safeTransfer(referrer, referrerShare);
            emit ReferrerPaid(referrer, buyer, referrerShare, volume);
        }
    }

    function _sellPriceImpact(
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint available
    ) internal view returns (uint _sellImpact) {
        (uint _balancePosition, uint balanceOtherSide) = ammUtils.balanceOfPositionsOnMarket(
            market,
            position,
            liquidityPool.getMarketPool(market)
        );
        uint balancePositionAfter = _balancePosition > 0 ? _balancePosition + (amount) : balanceOtherSide > amount
            ? 0
            : amount - (balanceOtherSide);
        uint balanceOtherSideAfter = balanceOtherSide > amount ? balanceOtherSide - (amount) : 0;
        if (!(balancePositionAfter < balanceOtherSideAfter)) {
            _sellImpact = ammUtils.sellPriceImpactImbalancedSkew(
                amount,
                balanceOtherSide,
                _balancePosition,
                balanceOtherSideAfter,
                balancePositionAfter,
                available,
                max_spread
            );
        }
    }

    function _getMintableAmount(
        address market,
        IThalesAMM.Position position,
        uint amount
    ) internal view returns (uint mintable) {
        uint availableInContract = ammUtils.balanceOfPositionOnMarket(market, position, liquidityPool.getMarketPool(market));
        if (availableInContract < amount) {
            mintable = amount - availableInContract;
        }
    }

    function _capOnMarket(address market) internal view returns (uint) {
        (bytes32 key, , ) = IPositionalMarket(market).getOracleDetails();
        return getCapPerAsset(key);
    }

    function _mapCollateralToCurveIndex(address collateral) internal view returns (int128) {
        if (collateral == dai) {
            return 1;
        }
        if (collateral == usdc) {
            return 2;
        }
        if (collateral == usdt) {
            return 3;
        }
        return 0;
    }

    function _sendMintedPositionsAndUSDToLiquidityPool(address market) internal {
        address _liquidityPool = liquidityPool.getOrCreateMarketPool(market);

        if (sUSD.balanceOf(address(this)) > 0) {
            sUSD.safeTransfer(_liquidityPool, sUSD.balanceOf(address(this)));
        }

        (IPosition up, IPosition down) = IPositionalMarket(market).getOptions();

        (uint upBalance, uint downBalance) = ammUtils.getBalanceOfPositionsOnMarket(market, address(this));

        if (upBalance > 0) {
            IERC20Upgradeable(address(up)).safeTransfer(_liquidityPool, upBalance);
        }

        if (downBalance > 0) {
            IERC20Upgradeable(address(down)).safeTransfer(_liquidityPool, downBalance);
        }
    }

    // setters

    /// @notice Updates contract parametars
    /// @param _minimalTimeLeftToMaturity how long till maturity will AMM support trading on a given market
    function setMinimalTimeLeftToMaturity(uint _minimalTimeLeftToMaturity) external onlyOwner {
        minimalTimeLeftToMaturity = _minimalTimeLeftToMaturity;
        emit SetMinimalTimeLeftToMaturity(_minimalTimeLeftToMaturity);
    }

    /// @notice Updates contract parametars
    /// @param _address which can update implied volatility
    /// @param enabled update if the address can set implied volatility
    function setWhitelistedAddress(address _address, bool enabled) external onlyOwner {
        whitelistedAddresses[_address] = enabled;
    }

    /// @notice Updates contract parametars
    /// @param _address which has a specific safe box fee
    /// @param newFee the fee
    function setSafeBoxFeePerAddress(address _address, uint newFee) external onlyOwner {
        safeBoxFeePerAddress[_address] = newFee;
    }

    /// @notice Updates contract parametars
    /// @param _address which has a specific min_spread fee
    /// @param newFee the fee
    function setMinSpreadPerAddress(address _address, uint newFee) external onlyOwner {
        min_spreadPerAddress[_address] = newFee;
    }

    /// @notice Updates contract parametars
    /// @param _minspread minimum spread applied to base price
    /// @param _maxspread maximum skew impact, e.g. if all UP positions are drained, skewImpact on that side = _maxspread
    function setMinMaxSpread(uint _minspread, uint _maxspread) external onlyOwner {
        min_spread = _minspread;
        max_spread = _maxspread;
        emit SetMinSpread(_minspread);
        emit SetMaxSpread(_maxspread);
    }

    /// @notice Updates contract parametars
    /// @param _safeBox where to send a fee reserved for protocol from each trade
    /// @param _safeBoxImpact how much is the SafeBoxFee
    function setSafeBoxData(address _safeBox, uint _safeBoxImpact) external onlyOwner {
        safeBoxImpact = _safeBoxImpact;
        safeBox = _safeBox;
        emit SetSafeBoxImpact(_safeBoxImpact);
    }

    /// @notice Updates contract parametars
    /// @param _minSupportedPrice whats the max price AMM supports, e.g. 10 cents
    /// @param _maxSupportedPrice whats the max price AMM supports, e.g. 90 cents
    /// @param _capPerMarket default amount the AMM will risk on markets, overrided by capPerAsset if existing
    function setMinMaxSupportedPriceAndCap(
        uint _minSupportedPrice,
        uint _maxSupportedPrice,
        uint _capPerMarket
    ) external onlyOwner {
        minSupportedPrice = _minSupportedPrice;
        maxSupportedPrice = _maxSupportedPrice;
        capPerMarket = _capPerMarket;
        emit SetMinMaxSupportedPriceCapPerMarket(_minSupportedPrice, _maxSupportedPrice, _capPerMarket);
    }

    /// @notice Updates contract parametars. Can be set by owner or whitelisted addresses. In the future try to get it as a feed from Chainlink.
    /// @param asset e.g. ETH, BTC, SNX...
    /// @param _impliedVolatility IV for BlackScholes
    function setImpliedVolatilityPerAsset(bytes32 asset, uint _impliedVolatility) external {
        require(
            whitelistedAddresses[msg.sender] || owner == msg.sender,
            "Only whitelisted addresses or owner can change IV!"
        );
        require(_impliedVolatility > ONE * 10 && _impliedVolatility < ONE * 300, "IV outside min/max range!");
        require(priceFeed.rateForCurrency(asset) != 0, "Asset has no price!");
        impliedVolatilityPerAsset[asset] = _impliedVolatility;
        emit SetImpliedVolatilityPerAsset(asset, _impliedVolatility);
    }

    /// @notice Updates contract parametars
    /// @param _priceFeed contract from which we read prices, can be chainlink or twap
    /// @param _sUSD address of sUSD
    function setPriceFeedAndSUSD(IPriceFeed _priceFeed, IERC20Upgradeable _sUSD) external onlyOwner {
        priceFeed = _priceFeed;
        emit SetPriceFeed(address(_priceFeed));

        sUSD = _sUSD;
        emit SetSUSD(address(sUSD));
    }

    /// @notice Updates contract parametars
    /// @param _ammUtils address of AMMUtils
    function setAmmUtils(IThalesAMMUtils _ammUtils) external onlyOwner {
        ammUtils = _ammUtils;
    }

    /// @notice Updates contract parametars
    /// @param _stakingThales contract address for staking bonuses
    /// @param _referrals contract for referrals storage
    /// @param _referrerFee how much of a fee to pay to referrers
    function setStakingThalesAndReferrals(
        IStakingThales _stakingThales,
        address _referrals,
        uint _referrerFee
    ) external onlyOwner {
        stakingThales = _stakingThales;
        referrals = _referrals;
        referrerFee = _referrerFee;
    }

    /// @notice Updates contract parametars
    /// @param _manager Positional Market Manager contract
    function setPositionalMarketManager(address _manager) external onlyOwner {
        if (address(manager) != address(0)) {
            sUSD.approve(address(manager), 0);
        }
        manager = _manager;
        sUSD.approve(manager, type(uint256).max);
        emit SetPositionalMarketManager(_manager);
    }

    /// @notice Updates contract parametars
    /// @param _liquidityPool address of ThalesAMMLiquidityPool
    function setLiquidityPool(ThalesAMMLiquidityPool _liquidityPool) external onlyOwner {
        liquidityPool = _liquidityPool;
    }

    /// @notice Updates contract parametars
    /// @param _curveSUSD curve sUSD pool exchanger contract
    /// @param _dai DAI address
    /// @param _usdc USDC address
    /// @param _usdt USDT addresss
    /// @param _curveOnrampEnabled whether AMM supports curve onramp
    /// @param _maxAllowedPegSlippagePercentage maximum discount AMM accepts for sUSD purchases
    function setCurveSUSD(
        address _curveSUSD,
        address _dai,
        address _usdc,
        address _usdt,
        bool _curveOnrampEnabled,
        uint _maxAllowedPegSlippagePercentage
    ) external onlyOwner {
        curveSUSD = ICurveSUSD(_curveSUSD);
        dai = _dai;
        usdc = _usdc;
        usdt = _usdt;
        IERC20Upgradeable(dai).approve(_curveSUSD, type(uint256).max);
        IERC20Upgradeable(usdc).approve(_curveSUSD, type(uint256).max);
        IERC20Upgradeable(usdt).approve(_curveSUSD, type(uint256).max);
        // not needed unless selling into different collateral is enabled
        //sUSD.approve(_curveSUSD, type(uint256).max);
        curveOnrampEnabled = _curveOnrampEnabled;
        maxAllowedPegSlippagePercentage = _maxAllowedPegSlippagePercentage;
    }

    /// @notice Updates contract parametars
    /// @param asset e.g. ETH, BTC, SNX
    /// @param _cap how much risk can AMM take on markets for given asset
    function setCapPerAsset(bytes32 asset, uint _cap) external onlyOwner {
        _capPerAsset[asset] = _cap;
        emit SetCapPerAsset(asset, _cap);
    }

    /// @notice Send tokens from this contract to the destination address
    /// @param tokens to iterate and transfer
    /// @param account Address where to send the tokens
    /// @param amount Amount of tokens to be sent
    /// @param all ignore amount and send whole balance
    function transferTokens(
        address[] calldata tokens,
        address payable account,
        uint amount,
        bool all
    ) external onlyOwner {
        require(tokens.length > 0, "tokens array cant be empty");
        for (uint256 index = 0; index < tokens.length; index++) {
            if (all) {
                IERC20Upgradeable(tokens[index]).safeTransfer(
                    account,
                    IERC20Upgradeable(tokens[index]).balanceOf(address(this))
                );
            } else {
                IERC20Upgradeable(tokens[index]).safeTransfer(account, amount);
            }
        }
    }

    // events
    event SoldToAMM(
        address seller,
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint sUSDPaid,
        address susd,
        address asset
    );
    event BoughtFromAmm(
        address buyer,
        address market,
        IThalesAMM.Position position,
        uint amount,
        uint sUSDPaid,
        address susd,
        address asset
    );

    event BoughtWithDiscount(address buyer, uint amount, uint sUSDPaid);
    event BoughtOptionType(address buyer, uint sUSDPaid, bool inTheMoney);
    event SetPositionalMarketManager(address _manager);
    event SetSUSD(address sUSD);
    event SetPriceFeed(address _priceFeed);
    event SetImpliedVolatilityPerAsset(bytes32 asset, uint _impliedVolatility);
    event SetCapPerAsset(bytes32 asset, uint _cap);
    event SetMaxSpread(uint _spread);
    event SetMinSpread(uint _spread);
    event SetSafeBoxImpact(uint _safeBoxImpact);
    event SetSafeBox(address _safeBox);
    event SetMinimalTimeLeftToMaturity(uint _minimalTimeLeftToMaturity);
    event SetMinMaxSupportedPriceCapPerMarket(uint minPrice, uint maxPrice, uint capPerMarket);
    event ReferrerPaid(address refferer, address trader, uint amount, uint volume);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor

contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../interfaces/IThalesAMM.sol";

interface IThalesAMMUtils {
    struct PriceImpactParams {
        uint amount;
        uint balanceOtherSide;
        uint balancePosition;
        uint balanceOtherSideAfter;
        uint balancePositionAfter;
        uint availableToBuyFromAMM;
        uint max_spread;
    }

    struct DiscountParams {
        uint balancePosition;
        uint balanceOtherSide;
        uint amount;
        uint availableToBuyFromAMM;
        uint max_spread;
    }

    function calculateOdds(
        uint _price,
        uint strike,
        uint timeLeftInDays,
        uint volatility
    ) external view returns (uint);

    function calculateDiscount(DiscountParams memory params) external view returns (int);

    function buyPriceImpactImbalancedSkew(PriceImpactParams memory params) external view returns (uint);

    function sellPriceImpactImbalancedSkew(
        uint amount,
        uint balanceOtherSide,
        uint _balancePosition,
        uint balanceOtherSideAfter,
        uint balancePositionAfter,
        uint available,
        uint max_spread
    ) external view returns (uint _sellImpactReturned);

    function balanceOfPositionOnMarket(
        address market,
        IThalesAMM.Position position,
        address addressToCheck
    ) external view returns (uint balance);

    function balanceOfPositionsOnMarket(
        address market,
        IThalesAMM.Position position,
        address addressToCheck
    ) external view returns (uint balance, uint balanceOtherSide);

    function getBalanceOfPositionsOnMarket(address market, address addressToCheck)
        external
        view
        returns (uint upBalance, uint downBalance);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Up,
        Down
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IStakingThales {
    function updateVolume(address account, uint amount) external;

    function updateStakingRewards(
        uint _currentPeriodRewards,
        uint _extraRewards,
        uint _revShare
    ) external;

    /* ========== VIEWS / VARIABLES ==========  */
    function totalStakedAmount() external view returns (uint);

    function stakedBalanceOf(address account) external view returns (uint);

    function currentPeriodRewards() external view returns (uint);

    function currentPeriodFees() external view returns (uint);

    function getLastPeriodOfClaimedRewards(address account) external view returns (uint);

    function getRewardsAvailable(address account) external view returns (uint);

    function getRewardFeesAvailable(address account) external view returns (uint);

    function getAlreadyClaimedRewards(address account) external view returns (uint);

    function getContractRewardFunds() external view returns (uint);

    function getContractFeeFunds() external view returns (uint);

    function getAMMVolume(address account) external view returns (uint);

    function updateVolumeAtAmountDecimals(
        address account,
        uint amount,
        uint decimals
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IReferrals {
    function referrals(address) external view returns (address);

    function getReferrerFee(address) external view returns (uint);

    function sportReferrals(address) external view returns (address);

    function setReferrer(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface ICurveSUSD {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    //    @notice Perform an exchange between two underlying coins
    //    @param i Index value for the underlying coin to send
    //    @param j Index valie of the underlying coin to receive
    //    @param _dx Amount of `i` being exchanged
    //    @param _min_dy Minimum amount of `j` to receive
    //    @param _receiver Address that receives `j`
    //    @return Actual amount of `j` received

    // indexes:
    // 0 = sUSD 18 dec 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9
    // 1= DAI 18 dec 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
    // 2= USDC 6 dec 0x7F5c764cBc14f9669B88837ca1490cCa17c31607
    // 3= USDT 6 dec 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";

import "../../interfaces/IThalesAMM.sol";
import "../../interfaces/IPositionalMarket.sol";
import "../../interfaces/IStakingThales.sol";

import "./ThalesAMMLiquidityPoolRound.sol";

contract ThalesAMMLiquidityPool is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    /* ========== LIBRARIES ========== */
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InitParams {
        address _owner;
        IThalesAMM _thalesAMM;
        IERC20Upgradeable _sUSD;
        uint _roundLength;
        uint _maxAllowedDeposit;
        uint _minDepositAmount;
        uint _maxAllowedUsers;
        bool _needsTransformingCollateral;
    }

    /* ========== CONSTANTS ========== */
    uint private constant HUNDRED = 1e20;
    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;

    /* ========== STATE VARIABLES ========== */

    IThalesAMM public thalesAMM;
    IERC20Upgradeable public sUSD;

    bool public started;

    uint public round;
    uint public roundLength;
    uint public firstRoundStartTime;

    mapping(uint => address) public roundPools;

    mapping(uint => address[]) public usersPerRound;
    mapping(uint => mapping(address => bool)) public userInRound;

    mapping(uint => mapping(address => uint)) public balancesPerRound;
    mapping(uint => uint) public allocationPerRound;

    mapping(address => bool) public withdrawalRequested;

    mapping(uint => address[]) public tradingMarketsPerRound;
    mapping(uint => mapping(address => bool)) public isTradingMarketInARound;

    mapping(uint => uint) public profitAndLossPerRound;
    mapping(uint => uint) public cumulativeProfitAndLoss;

    uint public maxAllowedDeposit;
    uint public minDepositAmount;
    uint public maxAllowedUsers;
    uint public usersCurrentlyInPool;

    address public defaultLiquidityProvider;

    IStakingThales public stakingThales;

    uint public stakedThalesMultiplier;

    address public poolRoundMastercopy;

    mapping(address => bool) public whitelistedDeposits;

    uint public totalDeposited;

    bool public onlyWhitelistedStakersAllowed;

    mapping(address => bool) public whitelistedStakers;

    bool public needsTransformingCollateral;

    mapping(uint => mapping(address => bool)) public marketAlreadyExercisedInRound;

    bool public roundClosingPrepared;

    uint public usersProcessedInRound;

    uint public marketsProcessedInRound;

    mapping(address => uint) public withdrawalShare;

    uint public utilizationRate;

    address public safeBox;
    uint public safeBoxImpact;

    /* ========== CONSTRUCTOR ========== */

    function initialize(InitParams calldata params) external initializer {
        setOwner(params._owner);
        initNonReentrant();
        thalesAMM = IThalesAMM(params._thalesAMM);

        sUSD = params._sUSD;
        roundLength = params._roundLength;
        maxAllowedDeposit = params._maxAllowedDeposit;
        minDepositAmount = params._minDepositAmount;
        maxAllowedUsers = params._maxAllowedUsers;

        needsTransformingCollateral = params._needsTransformingCollateral;

        sUSD.approve(address(thalesAMM), type(uint256).max);
    }

    /// @notice Start pool and begin round #1
    function start() external onlyOwner {
        require(!started, "Liquidity pool has already started");
        require(allocationPerRound[1] > 0, "can not start with 0 deposits");

        firstRoundStartTime = block.timestamp;
        round = 1;

        address roundPool = _getOrCreateRoundPool(1);
        ThalesAMMLiquidityPoolRound(roundPool).updateRoundTimes(firstRoundStartTime, getRoundEndTime(1));

        started = true;
        emit PoolStarted();
    }

    /// @notice Deposit funds from user into pool for the next round
    /// @param amount Value to be deposited
    function deposit(uint amount) external canDeposit(amount) nonReentrant whenNotPaused roundClosingNotPrepared {
        uint nextRound = round + 1;
        address roundPool = _getOrCreateRoundPool(nextRound);
        sUSD.safeTransferFrom(msg.sender, roundPool, amount);

        require(msg.sender != defaultLiquidityProvider, "Can't deposit directly as default liquidity provider");

        // new user enters the pool
        if (balancesPerRound[round][msg.sender] == 0 && balancesPerRound[nextRound][msg.sender] == 0) {
            require(usersCurrentlyInPool < maxAllowedUsers, "Max amount of users reached");
            usersPerRound[nextRound].push(msg.sender);
            userInRound[nextRound][msg.sender] = true;
            usersCurrentlyInPool = usersCurrentlyInPool + 1;
        }

        balancesPerRound[nextRound][msg.sender] += amount;

        allocationPerRound[nextRound] += amount;
        totalDeposited += amount;

        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(msg.sender, amount);
        }

        emit Deposited(msg.sender, amount, round);
    }

    /// @notice get sUSD to mint for buy and store market as trading in the round
    /// @param market to trade
    /// @param amountToMint amount to get for mint
    function commitTrade(address market, uint amountToMint)
        external
        nonReentrant
        whenNotPaused
        onlyAMM
        roundClosingNotPrepared
    {
        require(started, "Pool has not started");
        require(amountToMint > 0, "Can't commit a zero trade");

        amountToMint = _transformCollateral(amountToMint);
        // add 1e-6 due to rounding issue, will be sent back to AMM at the end
        amountToMint = needsTransformingCollateral ? amountToMint + 1 : amountToMint;

        uint marketRound = getMarketRound(market);
        address liquidityPoolRound = _getOrCreateRoundPool(marketRound);

        if (marketRound == round) {
            sUSD.safeTransferFrom(liquidityPoolRound, address(thalesAMM), amountToMint);
            require(
                sUSD.balanceOf(liquidityPoolRound) >=
                    (allocationPerRound[round] - ((allocationPerRound[round] * utilizationRate) / ONE)),
                "Amount exceeds available utilization for round"
            );
        } else {
            uint poolBalance = sUSD.balanceOf(liquidityPoolRound);
            if (poolBalance >= amountToMint) {
                sUSD.safeTransferFrom(liquidityPoolRound, address(thalesAMM), amountToMint);
            } else {
                uint differenceToLPAsDefault = amountToMint - poolBalance;
                _depositAsDefault(differenceToLPAsDefault, liquidityPoolRound, marketRound);
                sUSD.safeTransferFrom(liquidityPoolRound, address(thalesAMM), amountToMint);
            }
        }

        if (!isTradingMarketInARound[marketRound][market]) {
            tradingMarketsPerRound[marketRound].push(market);
            isTradingMarketInARound[marketRound][market] = true;
        }
    }

    /// @notice get options that are in the LP into the AMM for the buy tx
    /// @param market to get options for
    /// @param optionsAmount to get options for
    /// @param position to get options for
    function getOptionsForBuy(
        address market,
        uint optionsAmount,
        IThalesAMM.Position position
    ) external nonReentrant whenNotPaused onlyAMM roundClosingNotPrepared {
        if (optionsAmount > 0) {
            require(started, "Pool has not started");

            uint marketRound = getMarketRound(market);
            address liquidityPoolRound = _getOrCreateRoundPool(marketRound);

            (IPosition up, IPosition down) = IPositionalMarket(market).getOptions();
            IPosition target = position == IThalesAMM.Position.Up ? up : down;

            ThalesAMMLiquidityPoolRound(liquidityPoolRound).moveOptions(
                IERC20Upgradeable(address(target)),
                optionsAmount,
                address(thalesAMM)
            );
        }
    }

    /// @notice get options that are in the LP into the AMM for the buy tx
    /// @param market to get options for
    /// @param optionsAmount to get options for
    /// @param position to get options for
    function getOptionsForBuyByAddress(
        address market,
        uint optionsAmount,
        address position
    ) external nonReentrant whenNotPaused onlyAMM roundClosingNotPrepared {
        if (optionsAmount > 0) {
            require(started, "Pool has not started");

            uint marketRound = getMarketRound(market);
            address liquidityPoolRound = _getOrCreateRoundPool(marketRound);

            ThalesAMMLiquidityPoolRound(liquidityPoolRound).moveOptions(
                IERC20Upgradeable(position),
                optionsAmount,
                address(thalesAMM)
            );
        }
    }

    /// @notice Create a round pool by market maturity date if it doesnt already exist
    /// @param market to use
    /// @return roundPool the pool for the passed market
    function getOrCreateMarketPool(address market)
        external
        onlyAMM
        nonReentrant
        whenNotPaused
        roundClosingNotPrepared
        returns (address roundPool)
    {
        uint marketRound = getMarketRound(market);
        roundPool = _getOrCreateRoundPool(marketRound);
    }

    /// @notice request withdrawal from the LP
    function withdrawalRequest() external nonReentrant canWithdraw whenNotPaused roundClosingNotPrepared {
        if (totalDeposited > balancesPerRound[round][msg.sender]) {
            totalDeposited -= balancesPerRound[round][msg.sender];
        } else {
            totalDeposited = 0;
        }

        usersCurrentlyInPool = usersCurrentlyInPool - 1;
        withdrawalRequested[msg.sender] = true;
        emit WithdrawalRequested(msg.sender);
    }

    /// @notice request partial withdrawal from the LP.
    /// @param share the percentage the user is wihdrawing from his total deposit
    function partialWithdrawalRequest(uint share) external nonReentrant canWithdraw whenNotPaused roundClosingNotPrepared {
        require(share >= ONE_PERCENT * 10 && share <= ONE_PERCENT * 90, "Share has to be between 10% and 90%");

        uint toWithdraw = (balancesPerRound[round][msg.sender] * share) / ONE;
        if (totalDeposited > toWithdraw) {
            totalDeposited -= toWithdraw;
        } else {
            totalDeposited = 0;
        }

        withdrawalRequested[msg.sender] = true;
        withdrawalShare[msg.sender] = share;
        emit WithdrawalRequested(msg.sender);
    }

    /// @notice Prepare round closing
    /// excercise options of trading markets and ensure there are no markets left unresolved
    function prepareRoundClosing() external nonReentrant whenNotPaused roundClosingNotPrepared {
        require(canCloseCurrentRound(), "Can't close current round");
        // excercise market options
        exerciseMarketsReadyToExercised();

        address roundPool = roundPools[round];
        // final balance is the final amount of sUSD in the round pool
        uint currentBalance = sUSD.balanceOf(roundPool);

        // send profit reserved for SafeBox if positive round
        if (currentBalance > allocationPerRound[round]) {
            uint safeBoxAmount = ((currentBalance - allocationPerRound[round]) * safeBoxImpact) / ONE;
            sUSD.safeTransferFrom(roundPool, safeBox, safeBoxAmount);
            currentBalance = currentBalance - safeBoxAmount;
            emit SafeBoxSharePaid(safeBoxImpact, safeBoxAmount);
        }

        // calculate PnL

        // if no allocation for current round
        if (allocationPerRound[round] == 0) {
            profitAndLossPerRound[round] = 1;
        } else {
            profitAndLossPerRound[round] = (currentBalance * ONE) / allocationPerRound[round];
        }

        roundClosingPrepared = true;

        emit RoundClosingPrepared(round);
    }

    /// @notice Prepare round closing
    /// excercise options of trading markets and ensure there are no markets left unresolved
    function processRoundClosingBatch(uint batchSize) external nonReentrant whenNotPaused {
        require(roundClosingPrepared, "Round closing not prepared");
        require(usersProcessedInRound < usersPerRound[round].length, "All users already processed");
        require(batchSize > 0, "batchSize has to be greater than 0");

        address roundPool = roundPools[round];

        uint endCursor = usersProcessedInRound + batchSize;
        if (endCursor > usersPerRound[round].length) {
            endCursor = usersPerRound[round].length;
        }

        for (uint i = usersProcessedInRound; i < endCursor; i++) {
            address user = usersPerRound[round][i];
            uint balanceAfterCurRound = (balancesPerRound[round][user] * profitAndLossPerRound[round]) / ONE;
            if (!withdrawalRequested[user] && (profitAndLossPerRound[round] > 0)) {
                balancesPerRound[round + 1][user] = balancesPerRound[round + 1][user] + balanceAfterCurRound;
                usersPerRound[round + 1].push(user);
                if (address(stakingThales) != address(0)) {
                    stakingThales.updateVolume(user, balanceAfterCurRound);
                }
            } else {
                if (withdrawalShare[user] > 0) {
                    uint amountToClaim = (balanceAfterCurRound * withdrawalShare[user]) / ONE;
                    sUSD.safeTransferFrom(roundPool, user, amountToClaim);
                    emit Claimed(user, amountToClaim);
                    withdrawalRequested[user] = false;
                    withdrawalShare[user] = 0;
                    usersPerRound[round + 1].push(user);
                    balancesPerRound[round + 1][user] = balanceAfterCurRound - amountToClaim;
                } else {
                    balancesPerRound[round + 1][user] = 0;
                    sUSD.safeTransferFrom(roundPool, user, balanceAfterCurRound);
                    withdrawalRequested[user] = false;
                    emit Claimed(user, balanceAfterCurRound);
                }
            }
            usersProcessedInRound = usersProcessedInRound + 1;
        }

        emit RoundClosingBatchProcessed(round, batchSize);
    }

    /// @notice Close current round and begin next round,
    /// calculate profit and loss and process withdrawals
    function closeRound() external nonReentrant whenNotPaused {
        require(roundClosingPrepared, "Round closing not prepared");
        require(usersProcessedInRound == usersPerRound[round].length, "Not all users processed yet");
        // set for next round to false
        roundClosingPrepared = false;

        address roundPool = roundPools[round];

        //always claim for defaultLiquidityProvider
        if (balancesPerRound[round][defaultLiquidityProvider] > 0) {
            uint balanceAfterCurRound = (balancesPerRound[round][defaultLiquidityProvider] * profitAndLossPerRound[round]) /
                ONE;
            sUSD.safeTransferFrom(roundPool, defaultLiquidityProvider, balanceAfterCurRound);
            emit Claimed(defaultLiquidityProvider, balanceAfterCurRound);
        }

        if (round == 1) {
            cumulativeProfitAndLoss[round] = profitAndLossPerRound[round];
        } else {
            cumulativeProfitAndLoss[round] = (cumulativeProfitAndLoss[round - 1] * profitAndLossPerRound[round]) / ONE;
        }

        // start next round
        round += 1;

        //add all carried over sUSD
        allocationPerRound[round] += sUSD.balanceOf(roundPool);

        totalDeposited = allocationPerRound[round] - balancesPerRound[round][defaultLiquidityProvider];

        address roundPoolNewRound = _getOrCreateRoundPool(round);

        sUSD.safeTransferFrom(roundPool, roundPoolNewRound, sUSD.balanceOf(roundPool));

        usersProcessedInRound = 0;

        emit RoundClosed(round - 1, profitAndLossPerRound[round - 1]);
    }

    /// @notice Iterate all markets in the current round and exercise those ready to be exercised
    function exerciseMarketsReadyToExercised() public roundClosingNotPrepared {
        ThalesAMMLiquidityPoolRound poolRound = ThalesAMMLiquidityPoolRound(roundPools[round]);
        IPositionalMarket market;
        for (uint i = 0; i < tradingMarketsPerRound[round].length; i++) {
            address marketAddress = tradingMarketsPerRound[round][i];
            if (!marketAlreadyExercisedInRound[round][marketAddress]) {
                market = IPositionalMarket(marketAddress);
                if (market.resolved()) {
                    poolRound.exerciseMarketReadyToExercised(market);
                    marketAlreadyExercisedInRound[round][marketAddress] = true;
                }
            }
        }
    }

    /// @notice Exercises markets in a round
    /// @param batchSize number of markets to be processed
    function exerciseMarketsReadyToExercisedBatch(uint batchSize)
        external
        nonReentrant
        whenNotPaused
        roundClosingNotPrepared
    {
        require(batchSize > 0, "batchSize has to be greater than 0");

        ThalesAMMLiquidityPoolRound poolRound = ThalesAMMLiquidityPoolRound(roundPools[round]);
        uint count = 0;
        IPositionalMarket market;
        for (uint i = 0; i < tradingMarketsPerRound[round].length; i++) {
            if (count == batchSize) break;
            address marketAddress = tradingMarketsPerRound[round][i];
            if (!marketAlreadyExercisedInRound[round][marketAddress]) {
                market = IPositionalMarket(marketAddress);
                if (market.resolved()) {
                    poolRound.exerciseMarketReadyToExercised(market);
                    marketAlreadyExercisedInRound[round][marketAddress] = true;
                    count += 1;
                }
            }
        }
    }

    /* ========== VIEWS ========== */

    /// @notice whether the user is currently LPing
    /// @param user to check
    /// @return isUserInLP whether the user is currently LPing
    function isUserLPing(address user) external view returns (bool isUserInLP) {
        isUserInLP =
            (balancesPerRound[round][user] > 0 || balancesPerRound[round + 1][user] > 0) &&
            (!withdrawalRequested[user] || withdrawalShare[user] > 0);
    }

    /// @notice Return the maximum amount the user can deposit now
    /// @param user address to check
    /// @return maxDepositForUser the maximum amount the user can deposit in total including already deposited
    /// @return availableToDepositForUser the maximum amount the user can deposit now
    /// @return stakedThalesForUser how much THALES the user has staked
    function getMaxAvailableDepositForUser(address user)
        external
        view
        returns (
            uint maxDepositForUser,
            uint availableToDepositForUser,
            uint stakedThalesForUser
        )
    {
        uint nextRound = round + 1;
        stakedThalesForUser = stakingThales.stakedBalanceOf(user);
        maxDepositForUser = _transformCollateral((stakedThalesForUser * stakedThalesMultiplier) / ONE);
        availableToDepositForUser = maxDepositForUser > (balancesPerRound[round][user] + balancesPerRound[nextRound][user])
            ? (maxDepositForUser - balancesPerRound[round][user] - balancesPerRound[nextRound][user])
            : 0;
    }

    /// @notice get the pool address for the market
    /// @param market to check
    /// @return roundPool the pool address for the market
    function getMarketPool(address market) external view returns (address roundPool) {
        roundPool = roundPools[getMarketRound(market)];
    }

    /// @notice Checks if all conditions are met to close the round
    /// @return bool
    function canCloseCurrentRound() public view returns (bool) {
        if (!started || block.timestamp < getRoundEndTime(round)) {
            return false;
        }
        IPositionalMarket market;
        for (uint i = 0; i < tradingMarketsPerRound[round].length; i++) {
            address marketAddress = tradingMarketsPerRound[round][i];
            if (!marketAlreadyExercisedInRound[round][marketAddress]) {
                market = IPositionalMarket(marketAddress);
                if (!market.resolved()) {
                    return false;
                }
            }
        }
        return true;
    }

    /// @notice Iterate all markets in the current round and return true if at least one can be exercised
    function hasMarketsReadyToBeExercised() public view returns (bool) {
        ThalesAMMLiquidityPoolRound poolRound = ThalesAMMLiquidityPoolRound(roundPools[round]);
        IPositionalMarket market;
        for (uint i = 0; i < tradingMarketsPerRound[round].length; i++) {
            address marketAddress = tradingMarketsPerRound[round][i];
            if (!marketAlreadyExercisedInRound[round][marketAddress]) {
                market = IPositionalMarket(marketAddress);
                if (market.resolved()) {
                    (uint upBalance, uint downBalance) = market.balancesOf(address(poolRound));
                    if (upBalance > 0 || downBalance > 0) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /// @notice Return multiplied PnLs between rounds
    /// @param roundA Round number from
    /// @param roundB Round number to
    /// @return uint
    function cumulativePnLBetweenRounds(uint roundA, uint roundB) public view returns (uint) {
        return (cumulativeProfitAndLoss[roundB] * profitAndLossPerRound[roundA]) / cumulativeProfitAndLoss[roundA];
    }

    /// @notice Return the start time of the passed round
    /// @param _round number
    /// @return uint the start time of the given round
    function getRoundStartTime(uint _round) public view returns (uint) {
        return firstRoundStartTime + (_round - 1) * roundLength;
    }

    /// @notice Return the end time of the passed round
    /// @param _round number
    /// @return uint the end time of the given round
    function getRoundEndTime(uint _round) public view returns (uint) {
        return firstRoundStartTime + _round * roundLength;
    }

    /// @notice Return the round to which a market belongs to
    /// @param market to get the round for
    /// @return _round the round which the market belongs to
    function getMarketRound(address market) public view returns (uint _round) {
        IPositionalMarket marketContract = IPositionalMarket(market);
        (uint maturity, ) = marketContract.times();
        if (maturity > firstRoundStartTime) {
            _round = (maturity - firstRoundStartTime) / roundLength + 1;
        } else {
            _round = 1;
        }
    }

    /// @notice Return the count of users in current round
    /// @return _the count of users in current round
    function getUsersCountInCurrentRound() external view returns (uint) {
        return usersPerRound[round].length;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _transformCollateral(uint value) internal view returns (uint) {
        if (needsTransformingCollateral) {
            return value / 1e12;
        } else {
            return value;
        }
    }

    function _reverseTransformCollateral(uint value) internal view returns (uint) {
        if (needsTransformingCollateral) {
            return value * 1e12;
        } else {
            return value;
        }
    }

    function _depositAsDefault(
        uint amount,
        address roundPool,
        uint _round
    ) internal {
        require(defaultLiquidityProvider != address(0), "default liquidity provider not set");

        sUSD.safeTransferFrom(defaultLiquidityProvider, roundPool, amount);

        balancesPerRound[_round][defaultLiquidityProvider] += amount;
        allocationPerRound[_round] += amount;

        emit Deposited(defaultLiquidityProvider, amount, _round);
    }

    function _getOrCreateRoundPool(uint _round) internal returns (address roundPool) {
        roundPool = roundPools[_round];
        if (roundPool == address(0)) {
            require(poolRoundMastercopy != address(0), "Round pool mastercopy not set");
            ThalesAMMLiquidityPoolRound newRoundPool = ThalesAMMLiquidityPoolRound(Clones.clone(poolRoundMastercopy));
            newRoundPool.initialize(address(this), sUSD, _round, getRoundEndTime(_round - 1), getRoundEndTime(_round));
            roundPool = address(newRoundPool);
            roundPools[_round] = roundPool;
            emit RoundPoolCreated(_round, roundPool);
        }
    }

    /* ========== SETTERS ========== */

    function setPaused(bool _setPausing) external onlyOwner {
        _setPausing ? _pause() : _unpause();
    }

    /// @notice Set _poolRoundMastercopy
    /// @param _poolRoundMastercopy to clone round pools from
    function setPoolRoundMastercopy(address _poolRoundMastercopy) external onlyOwner {
        require(_poolRoundMastercopy != address(0), "Can not set a zero address!");
        poolRoundMastercopy = _poolRoundMastercopy;
        emit PoolRoundMastercopyChanged(poolRoundMastercopy);
    }

    /// @notice Set IStakingThales contract
    /// @param _stakingThales IStakingThales address
    function setStakingThales(IStakingThales _stakingThales) external onlyOwner {
        stakingThales = _stakingThales;
        emit StakingThalesChanged(address(_stakingThales));
    }

    /// @notice Set max allowed deposit
    /// @param _maxAllowedDeposit Deposit value
    function setMaxAllowedDeposit(uint _maxAllowedDeposit) external onlyOwner {
        maxAllowedDeposit = _maxAllowedDeposit;
        emit MaxAllowedDepositChanged(_maxAllowedDeposit);
    }

    /// @notice Set min allowed deposit
    /// @param _minDepositAmount Deposit value
    function setMinAllowedDeposit(uint _minDepositAmount) external onlyOwner {
        minDepositAmount = _minDepositAmount;
        emit MinAllowedDepositChanged(_minDepositAmount);
    }

    /// @notice Set _maxAllowedUsers
    /// @param _maxAllowedUsers Deposit value
    function setMaxAllowedUsers(uint _maxAllowedUsers) external onlyOwner {
        maxAllowedUsers = _maxAllowedUsers;
        emit MaxAllowedUsersChanged(_maxAllowedUsers);
    }

    /// @notice Set ThalesAMM contract
    /// @param _thalesAMM ThalesAMM address
    function setThalesAmm(IThalesAMM _thalesAMM) external onlyOwner {
        require(address(_thalesAMM) != address(0), "Can not set a zero address!");
        thalesAMM = _thalesAMM;
        sUSD.approve(address(thalesAMM), type(uint256).max);
        emit ThalesAMMChanged(address(_thalesAMM));
    }

    /// @notice Set defaultLiquidityProvider wallet
    /// @param _defaultLiquidityProvider default liquidity provider
    function setDefaultLiquidityProvider(address _defaultLiquidityProvider) external onlyOwner {
        require(_defaultLiquidityProvider != address(0), "Can not set a zero address!");
        defaultLiquidityProvider = _defaultLiquidityProvider;
        emit DefaultLiquidityProviderChanged(_defaultLiquidityProvider);
    }

    /// @notice Set length of rounds
    /// @param _roundLength Length of a round in miliseconds
    function setRoundLength(uint _roundLength) external onlyOwner {
        require(!started, "Can't change round length after start");
        roundLength = _roundLength;
        emit RoundLengthChanged(_roundLength);
    }

    /// @notice set utilization rate parameter
    /// @param _utilizationRate value as percentage
    function setUtilizationRate(uint _utilizationRate) external onlyOwner {
        utilizationRate = _utilizationRate;
        emit UtilizationRateChanged(_utilizationRate);
    }

    /// @notice set SafeBox params
    /// @param _safeBox where to send a profit reserved for protocol from each round
    /// @param _safeBoxImpact how much is the SafeBox percentage
    function setSafeBoxParams(address _safeBox, uint _safeBoxImpact) external onlyOwner {
        safeBox = _safeBox;
        safeBoxImpact = _safeBoxImpact;
        emit SetSafeBoxParams(_safeBox, _safeBoxImpact);
    }

    /* ========== MODIFIERS ========== */

    modifier canDeposit(uint amount) {
        require(!withdrawalRequested[msg.sender], "Withdrawal is requested, cannot deposit");
        require(totalDeposited + amount <= maxAllowedDeposit, "Deposit amount exceeds AMM LP cap");
        if (balancesPerRound[round][msg.sender] == 0 && balancesPerRound[round + 1][msg.sender] == 0) {
            require(amount >= minDepositAmount, "Amount less than minDepositAmount");
        }
        _;
    }

    modifier canWithdraw() {
        require(started, "Pool has not started");
        require(!withdrawalRequested[msg.sender], "Withdrawal already requested");
        require(balancesPerRound[round][msg.sender] > 0, "Nothing to withdraw");
        require(balancesPerRound[round + 1][msg.sender] == 0, "Can't withdraw as you already deposited for next round");
        _;
    }

    modifier onlyAMM() {
        require(msg.sender == address(thalesAMM), "only the AMM may perform these methods");
        _;
    }

    modifier roundClosingNotPrepared() {
        require(!roundClosingPrepared, "Not allowed during roundClosingPrepared");
        _;
    }

    /* ========== EVENTS ========== */
    event PoolStarted();
    event Deposited(address user, uint amount, uint round);
    event WithdrawalRequested(address user);
    event RoundClosed(uint round, uint roundPnL);
    event Claimed(address user, uint amount);
    event RoundPoolCreated(uint _round, address roundPool);
    event PoolRoundMastercopyChanged(address newMastercopy);
    event StakedThalesMultiplierChanged(uint _stakedThalesMultiplier);
    event StakingThalesChanged(address stakingThales);
    event MaxAllowedDepositChanged(uint maxAllowedDeposit);
    event MinAllowedDepositChanged(uint minAllowedDeposit);
    event MaxAllowedUsersChanged(uint MaxAllowedUsersChanged);
    event ThalesAMMChanged(address thalesAMM);
    event DefaultLiquidityProviderChanged(address newProvider);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event AddedIntoWhitelistStaker(address _whitelistAddress, bool _flag);
    event RoundLengthChanged(uint roundLength);
    event RoundClosingPrepared(uint round);
    event RoundClosingBatchProcessed(uint round, uint batchSize);
    event UtilizationRateChanged(uint utilizationRate);
    event SetSafeBoxParams(address safeBox, uint safeBoxImpact);
    event SafeBoxSharePaid(uint safeBoxShare, uint safeBoxAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "./IPriceFeed.sol";

interface IThalesAMM {
    enum Position {
        Up,
        Down
    }

    function manager() external view returns (address);

    function availableToBuyFromAMM(address market, Position position) external view returns (uint);

    function impliedVolatilityPerAsset(bytes32 oracleKey) external view returns (uint);

    function buyFromAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function buyFromAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external returns (uint);

    function availableToSellToAMM(address market, Position position) external view returns (uint);

    function sellToAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function sellToAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external returns (uint);

    function isMarketInAMMTrading(address market) external view returns (bool);

    function price(address market, Position position) external view returns (uint);

    function buyPriceImpact(
        address market,
        Position position,
        uint amount
    ) external view returns (int);

    function sellPriceImpact(
        address market,
        Position position,
        uint amount
    ) external view returns (int);

    function priceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../interfaces/IPositionalMarket.sol";

import "./ThalesAMMLiquidityPool.sol";

contract ThalesAMMLiquidityPoolRound {
    /* ========== LIBRARIES ========== */
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    ThalesAMMLiquidityPool public liquidityPool;
    IERC20Upgradeable public sUSD;

    uint public round;
    uint public roundStartTime;
    uint public roundEndTime;

    /* ========== CONSTRUCTOR ========== */

    bool public initialized;

    function initialize(
        address _liquidityPool,
        IERC20Upgradeable _sUSD,
        uint _round,
        uint _roundStartTime,
        uint _roundEndTime
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;
        liquidityPool = ThalesAMMLiquidityPool(_liquidityPool);
        sUSD = _sUSD;
        round = _round;
        roundStartTime = _roundStartTime;
        roundEndTime = _roundEndTime;
        sUSD.approve(_liquidityPool, type(uint256).max);
    }

    function updateRoundTimes(uint _roundStartTime, uint _roundEndTime) external onlyLiquidityPool {
        roundStartTime = _roundStartTime;
        roundEndTime = _roundEndTime;
        emit RoundTimesUpdated(_roundStartTime, _roundEndTime);
    }

    function exerciseMarketReadyToExercised(IPositionalMarket market) external onlyLiquidityPool {
        if (market.resolved()) {
            (uint upBalance, uint downBalance) = market.balancesOf(address(this));
            if (upBalance > 0 || downBalance > 0) {
                market.exerciseOptions();
            }
        }
    }

    function moveOptions(
        IERC20Upgradeable option,
        uint optionsAmount,
        address destination
    ) external onlyLiquidityPool {
        option.safeTransfer(destination, optionsAmount);
    }

    modifier onlyLiquidityPool() {
        require(msg.sender == address(liquidityPool), "only the Pool manager may perform these methods");
        _;
    }

    event RoundTimesUpdated(uint _roundStartTime, uint _roundEndTime);
}