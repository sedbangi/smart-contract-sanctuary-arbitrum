// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";

// interfaces
import "../../interfaces/ISportsAMM.sol";

// internal
import "../../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";
import "../../utils/libraries/AddressSetLib.sol";

import "./ParlayMarket.sol";
import "./ParlayVerifier.sol";

// interfaces
import "../../interfaces/IParlayMarketData.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/IStakingThales.sol";
import "../../interfaces/IReferrals.sol";
import "../../interfaces/ICurveSUSD.sol";
import "../../interfaces/IParlayAMMLiquidityPool.sol";
import "../../interfaces/IMultiCollateralOnOffRamp.sol";

contract ParlayMarketsAMM is Initializable, ProxyOwned, ProxyPausable, ProxyReentrancyGuard {
    using AddressSetLib for AddressSetLib.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;
    uint private constant DEFAULT_PARLAY_SIZE = 4;
    uint private constant MAX_APPROVAL = type(uint256).max;
    uint private constant POSITION_TAG_CONSTANT = 1e8;

    ISportsAMM public sportsAmm;
    ISportPositionalMarketManager public sportManager;
    IERC20Upgradeable public sUSD;
    //REMOVE stakingThales prior to deploy on mainnet
    IStakingThales public stakingThales;
    ICurveSUSD public curveSUSD;

    address public parlayMarketMastercopy;
    address public parlayMarketData;
    address public safeBox;
    address public referrals;

    address private usdc; // deprecated see MultiCollateralOnOffRamp.sol
    address private usdt; // deprecated see MultiCollateralOnOffRamp.sol
    address private dai; // deprecated see MultiCollateralOnOffRamp.sol

    uint public parlayAmmFee;
    uint public parlaySize;
    uint public maxSupportedAmount;
    uint public maxSupportedOdds;
    uint public safeBoxImpact;

    uint private referrerFee; // deprecated, moved to Referrals.sol
    bool private curveOnrampEnabled; // deprecated see MultiCollateralOnOffRamp.sol
    bool private reducedFeesEnabled; // deprecated

    AddressSetLib.AddressSet internal _knownMarkets;
    mapping(address => bool) public resolvedParlay;

    // deprecated see MultiCollateralOnOffRamp.sol
    uint private maxAllowedPegSlippagePercentage;

    ParlayVerifier public parlayVerifier;
    uint public minUSDAmount;

    uint public maxAllowedRiskPerCombination;
    mapping(address => mapping(uint => mapping(address => mapping(uint => mapping(address => mapping(uint => mapping(address => mapping(uint => uint))))))))
        public riskPerCombination; // deprecated due to TIP-117

    mapping(address => mapping(address => mapping(address => mapping(address => mapping(address => mapping(address => mapping(address => mapping(address => uint))))))))
        public riskPerGameCombination;

    // @return specific SafeBoxFee per address
    mapping(address => uint) public safeBoxFeePerAddress;
    // @return specific parlayAmmFee per address
    mapping(address => uint) public parlayAmmFeePerAddress;

    mapping(bytes32 => uint) public riskPerPackedGamesCombination;

    mapping(uint => mapping(uint => mapping(uint => uint))) public SGPFeePerCombination;

    address public parlayLP;

    /// @return The sUSD amount bought from AMM by users for the parent
    IMultiCollateralOnOffRamp public multiCollateralOnOffRamp;
    bool public multicollateralEnabled;

    address public parlayPolicy;

    mapping(address => mapping(uint => uint)) public riskPerMarketAndPosition;

    mapping(address => bool) public parlaysWithNewFormat;

    receive() external payable {}

    function initialize(
        address _owner,
        ISportsAMM _sportsAmm,
        ISportPositionalMarketManager _sportManager,
        uint _parlayAmmFee,
        uint _maxSupportedAmount,
        uint _maxSupportedOdds,
        IERC20Upgradeable _sUSD,
        address _safeBox,
        uint _safeBoxImpact
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        sportsAmm = _sportsAmm;
        sportManager = _sportManager;
        maxSupportedAmount = _maxSupportedAmount;
        maxSupportedOdds = _maxSupportedOdds;
        parlayAmmFee = _parlayAmmFee;
        sUSD = _sUSD;
        safeBox = _safeBox;
        safeBoxImpact = _safeBoxImpact;
        parlaySize = DEFAULT_PARLAY_SIZE;
        sUSD.approve(address(sportsAmm), type(uint256).max);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isActiveParlay(address _parlayMarket) external view returns (bool isActiveParlayMarket) {
        isActiveParlayMarket = _knownMarkets.contains(_parlayMarket);
    }

    function activeParlayMarkets(uint index, uint pageSize) external view returns (address[] memory) {
        return _knownMarkets.getPage(index, pageSize);
    }

    function numActiveParlayMarkets() external view returns (uint) {
        return _knownMarkets.elements.length;
    }

    function getSgpFeePerCombination(
        uint tag1,
        uint tag2_1,
        uint tag2_2,
        uint position1,
        uint position2
    ) external view returns (uint sgpFee) {
        if (position1 > 2 || position2 > 2) {
            sgpFee = SGPFeePerCombination[tag1][tag2_1][tag2_2];
        } else {
            uint posTag2_1 = tag2_1 + (POSITION_TAG_CONSTANT + ((POSITION_TAG_CONSTANT / 10) * position1));
            uint posTag2_2 = tag2_2 + (POSITION_TAG_CONSTANT + ((POSITION_TAG_CONSTANT / 10) * position2));
            if (SGPFeePerCombination[tag1][posTag2_1][posTag2_2] > 0) {
                if (SGPFeePerCombination[tag1][posTag2_1][posTag2_2] < ONE) {
                    sgpFee = SGPFeePerCombination[tag1][posTag2_1][posTag2_2];
                }
            } else {
                sgpFee = SGPFeePerCombination[tag1][tag2_1][tag2_2];
            }
        }
    }

    function buyQuoteFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid
    )
        external
        view
        returns (
            uint sUSDAfterFees,
            uint totalBuyAmount,
            uint totalQuote,
            uint initialQuote,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        )
    {
        (
            sUSDAfterFees,
            totalBuyAmount,
            totalQuote,
            initialQuote,
            skewImpact,
            finalQuotes,
            amountsToBuy
        ) = _buyQuoteFromParlay(_sportMarkets, _positions, _sUSDPaid);
    }

    function buyQuoteFromParlayWithDifferentCollateral(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        address _collateral
    )
        external
        view
        returns (
            uint collateralQuote,
            uint sUSDAfterFees,
            uint totalBuyAmount,
            uint totalQuote,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        )
    {
        (sUSDAfterFees, totalBuyAmount, totalQuote, , skewImpact, finalQuotes, amountsToBuy) = _buyQuoteFromParlay(
            _sportMarkets,
            _positions,
            _sUSDPaid
        );
        collateralQuote = multiCollateralOnOffRamp.getMinimumNeeded(_collateral, _sUSDPaid);
    }

    function canCreateParlayMarket(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDToPay
    ) external view returns (bool canBeCreated) {
        (, uint totalBuyAmount, uint totalQuote, , , , ) = _buyQuoteFromParlay(_sportMarkets, _positions, _sUSDToPay);
        canBeCreated = totalQuote >= maxSupportedOdds && totalBuyAmount <= maxSupportedAmount;
    }

    function isParlayOwnerTheWinner(address _parlayMarket) external view returns (bool isUserTheWinner) {
        if (_knownMarkets.contains(_parlayMarket)) {
            isUserTheWinner = ParlayMarket(_parlayMarket).isUserTheWinner();
        }
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function buyFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address _differentRecipient
    ) external nonReentrant notPaused {
        _buyFromParlayCommon(
            _sportMarkets,
            _positions,
            _sUSDPaid,
            _additionalSlippage,
            _expectedPayout,
            _differentRecipient
        );
    }

    function buyFromParlayWithReferrer(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address _differentRecipient,
        address _referrer
    ) external nonReentrant notPaused {
        if (_referrer != address(0)) {
            IReferrals(referrals).setReferrer(_referrer, msg.sender);
        }
        _buyFromParlayCommon(
            _sportMarkets,
            _positions,
            _sUSDPaid,
            _additionalSlippage,
            _expectedPayout,
            _differentRecipient
        );
    }

    function _buyFromParlayCommon(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address _differentRecipient
    ) internal {
        if (_differentRecipient == address(0)) {
            _differentRecipient = msg.sender;
        }
        _buyFromParlay(
            _sportMarkets,
            _positions,
            _sUSDPaid,
            _additionalSlippage,
            _expectedPayout,
            true,
            _differentRecipient
        );

        _transferSuprlusIfExists();
    }

    function buyFromParlayWithDifferentCollateralAndReferrer(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address collateral,
        address _referrer
    ) external nonReentrant notPaused {
        _buyFromParlayWithDifferentCollateralAndReferrer(
            _sportMarkets,
            _positions,
            _sUSDPaid,
            _additionalSlippage,
            _expectedPayout,
            collateral,
            _referrer,
            false
        );
    }

    function buyFromParlayWithEth(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address collateral,
        address _referrer
    ) external payable nonReentrant notPaused {
        _buyFromParlayWithDifferentCollateralAndReferrer(
            _sportMarkets,
            _positions,
            _sUSDPaid,
            _additionalSlippage,
            _expectedPayout,
            collateral,
            _referrer,
            true
        );
    }

    function _buyFromParlayWithDifferentCollateralAndReferrer(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address collateral,
        address _referrer,
        bool isEth
    ) internal {
        if (_referrer != address(0)) {
            IReferrals(referrals).setReferrer(_referrer, msg.sender);
        }

        uint collateralQuote = multiCollateralOnOffRamp.getMinimumNeeded(collateral, _sUSDPaid);

        uint exactReceived;

        if (isEth) {
            require(collateral == multiCollateralOnOffRamp.WETH9(), "Wrong collateral sent");
            require(msg.value >= collateralQuote, "not enough ETH sent");
            exactReceived = multiCollateralOnOffRamp.onrampWithEth{value: msg.value}(msg.value);
        } else {
            IERC20Upgradeable(collateral).safeTransferFrom(msg.sender, address(this), collateralQuote);
            IERC20Upgradeable(collateral).approve(address(multiCollateralOnOffRamp), collateralQuote);
            exactReceived = multiCollateralOnOffRamp.onramp(collateral, collateralQuote);
        }

        require(exactReceived >= _sUSDPaid, "Not enough sUSD received");

        //send the surplus to SB
        if (exactReceived > _sUSDPaid) {
            sUSD.safeTransfer(safeBox, exactReceived - _sUSDPaid);
        }

        _buyFromParlay(_sportMarkets, _positions, _sUSDPaid, _additionalSlippage, _expectedPayout, false, msg.sender);
        _transferSuprlusIfExists();
    }

    function _transferSuprlusIfExists() internal {
        uint balance = sUSD.balanceOf(address(this));
        if (balance > 0) {
            sUSD.transfer(
                IParlayAMMLiquidityPool(parlayLP).getMarketPool(_knownMarkets.elements[_knownMarkets.elements.length - 1]),
                balance
            );
        }
    }

    function exerciseParlay(address _parlayMarket) external nonReentrant notPaused onlyKnownMarkets(_parlayMarket) {
        _exerciseParlay(_parlayMarket);
    }

    function exerciseParlayWithOfframp(
        address _parlayMarket,
        address collateral,
        bool toEth
    ) external nonReentrant notPaused onlyKnownMarkets(_parlayMarket) {
        ParlayMarket parlayMarket = ParlayMarket(_parlayMarket);
        address parlayOwner = parlayMarket.parlayOwner();
        require(msg.sender == parlayOwner, "Only allowed from parlay owner");
        uint amountBefore = sUSD.balanceOf(parlayOwner);
        _exerciseParlay(_parlayMarket);
        uint amountDiff = sUSD.balanceOf(parlayOwner) - amountBefore;
        sUSD.safeTransferFrom(parlayOwner, address(this), amountDiff);
        if (amountDiff > 0) {
            if (toEth) {
                uint offramped = multiCollateralOnOffRamp.offrampIntoEth(amountDiff);
                address payable _to = payable(parlayOwner);
                bool sent = _to.send(offramped);
                require(sent, "Failed to send Ether");
            } else {
                uint offramped = multiCollateralOnOffRamp.offramp(collateral, amountDiff);
                IERC20Upgradeable(collateral).safeTransfer(parlayOwner, offramped);
            }
        }
    }

    function _exerciseParlay(address _parlayMarket) internal {
        ParlayMarket parlayMarket = ParlayMarket(_parlayMarket);
        parlayMarket.exerciseWiningSportMarkets();
        uint amount = sUSD.balanceOf(address(this));
        if (amount > 0) {
            IParlayAMMLiquidityPool(parlayLP).transferToPool(_parlayMarket, amount);
        }
    }

    // TODO: to remove
    function resolveParlay() external notPaused onlyKnownMarkets(msg.sender) {
        if (!ParlayMarket(msg.sender).resolved()) {
            resolvedParlay[msg.sender] = true;
            _knownMarkets.remove(msg.sender);
        }
    }

    function expireMarkets(address[] calldata _parlayMarkets) external onlyOwner {
        for (uint i = 0; i < _parlayMarkets.length; i++) {
            if (ParlayMarket(_parlayMarkets[i]).phase() == ParlayMarket.Phase.Expiry) {
                ParlayMarket(_parlayMarkets[i]).expire(payable(safeBox));
            }
        }
    }

    function setPausedMarkets(address[] calldata _parlayMarkets, bool _paused) external onlyOwner {
        for (uint i = 0; i < _parlayMarkets.length; i++) {
            ParlayMarket(_parlayMarkets[i]).setPaused(_paused);
        }
    }

    function triggerResolvedEvent(address _account, bool _userWon) external notPaused onlyKnownMarkets(msg.sender) {
        if (parlaysWithNewFormat[msg.sender]) {
            resolvedParlay[msg.sender] = true;
            _knownMarkets.remove(msg.sender);
        }
        emit ParlayResolved(msg.sender, _account, _userWon);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _buyFromParlay(
        address[] memory _sportMarkets,
        uint[] memory _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        bool _sendSUSD,
        address _differentRecipient
    ) internal {
        uint totalAmount;
        uint totalQuote;
        uint[] memory amountsToBuy = new uint[](_sportMarkets.length);
        uint[] memory marketQuotes = new uint[](_sportMarkets.length);
        uint sUSDAfterFees;
        (sUSDAfterFees, totalAmount, totalQuote, , , marketQuotes, amountsToBuy) = _buyQuoteFromParlay(
            _sportMarkets,
            _positions,
            _sUSDPaid
        );
        // apply all checks
        require(_sUSDPaid >= minUSDAmount, "Low sUSD buy");
        require(totalQuote >= maxSupportedOdds, "Can not create parlay market!");
        require((totalAmount - _sUSDPaid) <= maxSupportedAmount, "Amount exceeds MaxSupportedAmount");
        require(((ONE * _expectedPayout) / totalAmount) <= (ONE + _additionalSlippage), "Slippage too high");

        for (uint i = 0; i < _sportMarkets.length; i++) {
            riskPerMarketAndPosition[_sportMarkets[i]][_positions[i]] += amountsToBuy[i];
            require(
                riskPerMarketAndPosition[_sportMarkets[i]][_positions[i]] <
                    sportsAmm.riskManager().calculateCapToBeUsed(_sportMarkets[i]) * 2,
                "Risk per individual market and position exceeded"
            );
            if (!ISportPositionalMarket(_sportMarkets[i]).optionsInitialized()) {
                ISportPositionalMarket(_sportMarkets[i]).initializeOptions();
            }
        }

        if (_sendSUSD) {
            sUSD.safeTransferFrom(msg.sender, address(this), _sUSDPaid);
        }

        uint safeBoxAmount = _handleReferrerAndSB(_sUSDPaid, sUSDAfterFees);

        // clone a parlay market
        ParlayMarket parlayMarket = ParlayMarket(Clones.clone(parlayMarketMastercopy));
        parlayMarket.initialize(
            _sportMarkets,
            _positions,
            totalAmount,
            sUSDAfterFees,
            (block.timestamp + sportManager.expiryDuration()),
            address(this),
            _differentRecipient,
            totalQuote,
            marketQuotes
        );

        _knownMarkets.add(address(parlayMarket));
        parlaysWithNewFormat[address(parlayMarket)] = true;
        sportsAmm.updateParlayVolume(_differentRecipient, _sUSDPaid);

        IParlayAMMLiquidityPool(parlayLP).commitTrade(
            address(parlayMarket),
            totalAmount - sportManager.reverseTransformCollateral(sUSDAfterFees)
        );
        // buy the positions
        sUSD.safeTransfer(address(parlayMarket), sportManager.transformCollateral(totalAmount));
        _storeRisk(_sportMarkets, (totalAmount - sportManager.reverseTransformCollateral(sUSDAfterFees)));

        emit NewParlayMarket(address(parlayMarket), _sportMarkets, _positions, totalAmount, sUSDAfterFees);

        emit ParlayMarketCreated(
            address(parlayMarket),
            _differentRecipient,
            totalAmount,
            _sUSDPaid,
            sUSDAfterFees,
            totalQuote,
            safeBoxAmount,
            marketQuotes
        );
    }

    function _buyQuoteFromParlay(
        address[] memory _sportMarkets,
        uint[] memory _positions,
        uint _sUSDPaid
    )
        internal
        view
        returns (
            uint sUSDAfterFees,
            uint totalBuyAmount,
            uint totalQuote,
            uint initialQuote,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        )
    {
        sUSDAfterFees = ((ONE - ((safeBoxImpact + parlayAmmFee))) * _sUSDPaid) / ONE;
        (totalQuote, totalBuyAmount, skewImpact, finalQuotes, amountsToBuy) = parlayVerifier.calculateInitialQuotesForParlay(
            ParlayVerifier.InitialQuoteParameters(
                _sportMarkets,
                _positions,
                sportManager.reverseTransformCollateral(sUSDAfterFees),
                parlaySize,
                sportManager.reverseTransformCollateral(1),
                finalQuotes,
                sportsAmm,
                address(this)
            )
        );

        // check if any market breaches cap
        for (uint i = 0; i < _sportMarkets.length; i++) {
            if (
                riskPerMarketAndPosition[_sportMarkets[i]][_positions[i]] + amountsToBuy[i] >
                sportsAmm.riskManager().calculateCapToBeUsed(_sportMarkets[i]) * 2
            ) {
                finalQuotes[i] = 0;
                totalQuote = 0;
                skewImpact = 0;
            }
        }
    }

    function _handleReferrerAndSB(uint _sUSDPaid, uint sUSDAfterFees) internal returns (uint safeBoxAmount) {
        uint referrerShare;
        address referrer = IReferrals(referrals).sportReferrals(msg.sender);
        if (referrer != address(0)) {
            uint referrerFeeByTier = IReferrals(referrals).getReferrerFee(referrer);
            if (referrerFeeByTier > 0) {
                referrerShare = (_sUSDPaid * referrerFeeByTier) / ONE;
                sUSD.safeTransfer(referrer, referrerShare);
                emit ReferrerPaid(referrer, msg.sender, referrerShare, _sUSDPaid);
            }
        }
        safeBoxAmount = _getSafeBoxAmount(_sUSDPaid, sUSDAfterFees, msg.sender);
        sUSD.safeTransfer(safeBox, safeBoxAmount - referrerShare);
    }

    function _storeRisk(address[] memory _sportMarkets, uint _sUSDPaid) internal {
        if (_sportMarkets.length > 1 && _sportMarkets.length <= parlaySize) {
            riskPerPackedGamesCombination[parlayVerifier.calculateCombinationKey(_sportMarkets)] += _sUSDPaid;
        }
    }

    function _getSafeBoxFeePerAddress(address toCheck) internal view returns (uint toReturn) {
        return safeBoxFeePerAddress[toCheck] > 0 ? safeBoxFeePerAddress[toCheck] : safeBoxImpact;
    }

    function _getParlayAmmFeePerAddress(address toCheck) internal view returns (uint toReturn) {
        return parlayAmmFeePerAddress[toCheck] > 0 ? parlayAmmFeePerAddress[toCheck] : parlayAmmFee;
    }

    function _obtainSportsAMMPosition(uint _position) internal pure returns (ISportsAMM.Position) {
        if (_position == 0) {
            return ISportsAMM.Position.Home;
        } else if (_position == 1) {
            return ISportsAMM.Position.Away;
        }
        return ISportsAMM.Position.Draw;
    }

    function _getSafeBoxAmount(
        uint sUSDPaid,
        uint sUSDAfterFees,
        address toCheck
    ) internal view returns (uint safeBoxAmount) {
        uint safeBoxFee = _getSafeBoxFeePerAddress(toCheck);
        safeBoxAmount = ((sUSDPaid - sUSDAfterFees) * safeBoxFee) / (safeBoxFee + _getParlayAmmFeePerAddress(toCheck));
    }

    /* ========== SETTERS FUNCTIONS ========== */

    function setParlayMarketMastercopies(address _parlayMarketMastercopy) external onlyOwner {
        parlayMarketMastercopy = _parlayMarketMastercopy;
        emit NewParlayMastercopy(_parlayMarketMastercopy);
    }

    function setParameters(uint _parlaySize) external onlyOwner {
        parlaySize = _parlaySize;
        emit NewParametersSet(_parlaySize);
    }

    function setSgpFeePerCombination(
        uint tag1,
        uint tag2_1,
        uint tag2_2,
        uint fee
    ) external onlyOwner {
        SGPFeePerCombination[tag1][tag2_1][tag2_2] = fee;
        SGPFeePerCombination[tag1][tag2_2][tag2_1] = fee;
    }

    function setSGPFeePerPosition(
        uint[] calldata tag1,
        uint tag2_1,
        uint tag2_2,
        uint position_1,
        uint position_2,
        uint fee
    ) external onlyOwner {
        for (uint i = 0; i < tag1.length; i++) {
            require(SGPFeePerCombination[tag1[i]][tag2_1][tag2_2] > 0, "SGP not set for tags");
            uint posTag2_1 = tag2_1 + (POSITION_TAG_CONSTANT + ((POSITION_TAG_CONSTANT / 10) * position_1));
            uint posTag2_2 = tag2_2 + (POSITION_TAG_CONSTANT + ((POSITION_TAG_CONSTANT / 10) * position_2));
            SGPFeePerCombination[tag1[i]][posTag2_1][posTag2_2] = fee;
            SGPFeePerCombination[tag1[i]][posTag2_2][posTag2_1] = fee;
            emit SetSGPFeePerPosition(tag1[i], posTag2_2, posTag2_1, fee);
        }
    }

    /// @notice Updates contract parametars
    /// @param _address which has a specific safe box fee
    /// @param newFee the fee
    function setSafeBoxFeePerAddress(address _address, uint newFee) external onlyOwner {
        safeBoxFeePerAddress[_address] = newFee;
        emit SafeBoxFeePerAddressChanged(_address, newFee);
    }

    /// @notice Updates contract parametars
    /// @param _address which has a specific parlay amm fee
    /// @param newFee the fee
    function setParlayAmmFeePerAddress(address _address, uint newFee) external onlyOwner {
        parlayAmmFeePerAddress[_address] = newFee;
        emit ParlayAmmFeePerAddressChanged(_address, newFee);
    }

    function setAmounts(
        uint _minUSDAmount,
        uint _maxSupportedAmount,
        uint _maxSupportedOdds,
        uint _parlayAMMFee,
        uint _safeBoxImpact,
        uint _referrerFee,
        uint _maxAllowedRiskPerCombination
    ) external onlyOwner {
        minUSDAmount = _minUSDAmount;
        maxSupportedAmount = _maxSupportedAmount;
        maxSupportedOdds = _maxSupportedOdds;
        parlayAmmFee = _parlayAMMFee;
        safeBoxImpact = _safeBoxImpact;
        // deprecated
        //referrerFee = _referrerFee;
        maxAllowedRiskPerCombination = _maxAllowedRiskPerCombination;
        emit SetAmounts(
            _minUSDAmount,
            _maxSupportedAmount,
            maxSupportedOdds,
            _parlayAMMFee,
            _safeBoxImpact,
            _referrerFee,
            _maxAllowedRiskPerCombination
        );
    }

    function setAddresses(
        address _sportsAMM,
        address _safeBox,
        address _referrals,
        address _parlayMarketData
    ) external onlyOwner {
        sportsAmm = ISportsAMM(_sportsAMM);
        sUSD.approve(address(sportsAmm), type(uint256).max);
        safeBox = _safeBox;
        referrals = _referrals;
        parlayMarketData = _parlayMarketData;
        emit AddressesSet(_sportsAMM, _safeBox, _referrals, _parlayMarketData);
    }

    function setVerifierAndPolicyAddresses(address _parlayVerifier, address _parlayPolicy) external onlyOwner {
        require(_parlayVerifier != address(0) && _parlayPolicy != address(0), "InvAdd0");
        parlayPolicy = _parlayPolicy;
        parlayVerifier = ParlayVerifier(_parlayVerifier);
        emit VerifierAndPolicySet(_parlayVerifier, _parlayPolicy);
    }

    /// @notice set multicollateral onramp contract
    function setMultiCollateralOnOffRamp(address _onramper, bool enabled) external onlyOwner {
        if (address(multiCollateralOnOffRamp) != address(0)) {
            sUSD.approve(address(multiCollateralOnOffRamp), 0);
        }
        multiCollateralOnOffRamp = IMultiCollateralOnOffRamp(_onramper);
        multicollateralEnabled = enabled;
        sUSD.approve(_onramper, MAX_APPROVAL);
        emit SetMultiCollateralOnOffRamp(_onramper, enabled);
    }

    function setParlayLP(address _parlayLP) external onlyOwner {
        if (parlayLP != address(0)) {
            sUSD.approve(parlayLP, 0);
        }
        parlayLP = _parlayLP;
        sUSD.approve(_parlayLP, type(uint256).max);
        emit ParlayLPSet(_parlayLP);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyKnownMarkets(address _parlayMarket) {
        require(_knownMarkets.contains(_parlayMarket), "Unknown parlay market");
        _;
    }

    /* ========== EVENTS ========== */
    event SetSUSD(address sUSDToken);
    event NewParlayMarket(address market, address[] markets, uint[] positions, uint amount, uint sUSDpaid);
    event ParlayMarketCreated(
        address market,
        address account,
        uint amount,
        uint sUSDPaid,
        uint sUSDAfterFees,
        uint totalQuote,
        uint skewImpact,
        uint[] marketQuotes
    );
    event SetAmounts(
        uint minUSDamount,
        uint max_amount,
        uint max_odds,
        uint _parlayAMMFee,
        uint _safeBoxImpact,
        uint _referrerFee,
        uint _maxAllowedRiskPerCombination
    );
    event AddressesSet(address _thalesAMM, address _safeBox, address _referrals, address _parlayMarketData);
    event VerifierAndPolicySet(address _parlayVerifier, address _parlayPolicy);
    event ReferrerPaid(address refferer, address trader, uint amount, uint volume);
    event ExtraAmountTransferredDueToCancellation(address receiver, uint amount);
    event ParlayResolved(address _parlayMarket, address _parlayOwner, bool _userWon);
    event SafeBoxFeePerAddressChanged(address _address, uint newFee);
    event ParlayAmmFeePerAddressChanged(address _address, uint newFee);
    event NewParlayMastercopy(address parlayMarketMastercopy);
    event NewParametersSet(uint parlaySize);
    event ParlayLPSet(address parlayLP);
    event SetMultiCollateralOnOffRamp(address _onramper, bool enabled);
    event SetSGPFeePerPosition(uint tag1, uint tag2_1, uint tag2_2, uint fee);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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

import "../interfaces/ISportAMMRiskManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISportsAMM {
    /* ========== VIEWS / VARIABLES ========== */

    enum Position {
        Home,
        Away,
        Draw
    }

    struct SellRequirements {
        address user;
        address market;
        Position position;
        uint amount;
        uint expectedPayout;
        uint additionalSlippage;
    }

    function theRundownConsumer() external view returns (address);

    function riskManager() external view returns (ISportAMMRiskManager riskManager);

    function getMarketDefaultOdds(address _market, bool isSell) external view returns (uint[] memory);

    function isMarketInAMMTrading(address _market) external view returns (bool);

    function isMarketForSportOnePositional(uint _tag) external view returns (bool);

    function availableToBuyFromAMM(address market, Position position) external view returns (uint _available);

    function parlayAMM() external view returns (address);

    function minSupportedOdds() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function minSupportedOddsPerSport(uint) external view returns (uint);

    function min_spread() external view returns (uint);

    function max_spread() external view returns (uint);

    function minimalTimeLeftToMaturity() external view returns (uint);

    function getSpentOnGame(address market) external view returns (uint);

    function safeBoxImpact() external view returns (uint);

    function manager() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function sUSD() external view returns (IERC20Upgradeable);

    function buyFromAMM(
        address market,
        Position position,
        uint amount,
        uint expectedPayout,
        uint additionalSlippage
    ) external;

    function buyFromAmmQuote(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function buyFromAmmQuoteForParlayAMM(
        address market,
        Position position,
        uint amount
    ) external view returns (uint);

    function updateParlayVolume(address _account, uint _amount) external;

    function buyPriceImpact(
        address market,
        ISportsAMM.Position position,
        uint amount
    ) external view returns (int impact);

    function obtainOdds(address _market, ISportsAMM.Position _position) external view returns (uint oddsToReturn);

    function buyFromAmmQuoteWithDifferentCollateral(
        address market,
        ISportsAMM.Position position,
        uint amount,
        address collateral
    ) external view returns (uint collateralQuote, uint sUSDToPay);

    function availableToBuyFromAMMWithBaseOdds(
        address market,
        ISportsAMM.Position position,
        uint baseOdds,
        uint balance,
        bool useBalance
    ) external view returns (uint availableAmount);

    function floorBaseOdds(uint baseOdds, address market) external view returns (uint);
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

pragma solidity ^0.8.0;

library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(
        AddressSet storage set,
        uint index,
        uint pageSize
    ) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../OwnedWithInit.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/utils/SafeERC20.sol";

// Internal references
import "../../interfaces/IParlayMarketsAMM.sol";
import "../SportPositions/SportPosition.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";

contract ParlayMarket is OwnedWithInit {
    using SafeERC20 for IERC20;

    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;
    uint private constant TWELVE_DECIMAL = 1e6;

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }

    struct SportMarkets {
        address sportAddress;
        uint position;
        uint odd;
        uint result;
        bool resolved;
        bool exercised;
        bool hasWon;
        bool isCancelled;
    }

    IParlayMarketsAMM public parlayMarketsAMM;
    address public parlayOwner;

    uint public expiry;
    uint public amount;
    uint public sUSDPaid;
    uint public totalResultQuote;
    uint public numOfSportMarkets;

    bool public resolved;
    bool public paused;
    bool public parlayAlreadyLost;
    bool public initialized;

    mapping(uint => SportMarkets) public sportMarket;
    mapping(address => uint) private _sportMarketIndex;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address[] calldata _sportMarkets,
        uint[] calldata _positionPerMarket,
        uint _amount,
        uint _sUSDPaid,
        uint _expiryDuration,
        address _parlayMarketsAMM,
        address _parlayOwner,
        uint _totalQuote,
        uint[] calldata _marketQuotes
    ) external {
        require(!initialized, "Parlay Market already initialized");
        initialized = true;
        initOwner(msg.sender);
        parlayMarketsAMM = IParlayMarketsAMM(_parlayMarketsAMM);
        require(_sportMarkets.length == _positionPerMarket.length, "Lengths not matching");
        numOfSportMarkets = _sportMarkets.length;
        for (uint i = 0; i < numOfSportMarkets; i++) {
            sportMarket[i].sportAddress = _sportMarkets[i];
            sportMarket[i].position = _positionPerMarket[i];
            sportMarket[i].odd = _marketQuotes[i];
            _sportMarketIndex[_sportMarkets[i]] = i + 1;
        }
        amount = _amount;
        expiry = _expiryDuration;
        sUSDPaid = _sUSDPaid;
        parlayOwner = _parlayOwner;
        totalResultQuote = _totalQuote;
    }

    //===================== VIEWS ===========================

    function isParlayLost() public view returns (bool) {
        bool marketWinning;
        bool marketResolved;
        bool hasPendingWinningMarkets;
        for (uint i = 0; i < numOfSportMarkets; i++) {
            (marketWinning, marketResolved) = _isWinningPosition(sportMarket[i].sportAddress, sportMarket[i].position);
            if (marketResolved && !marketWinning) {
                return true;
            }
        }
        return false;
    }

    function areAllPositionsResolved() public view returns (bool) {
        for (uint i = 0; i < numOfSportMarkets; i++) {
            if (!ISportPositionalMarket(sportMarket[i].sportAddress).resolved()) {
                return false;
            }
        }
        return true;
    }

    function isUserTheWinner() external view returns (bool hasUserWon) {
        if (areAllPositionsResolved()) {
            hasUserWon = !isParlayLost();
        }
    }

    function phase() public view returns (Phase) {
        if (resolved) {
            if (resolved && expiry < block.timestamp) {
                return Phase.Expiry;
            } else {
                return Phase.Maturity;
            }
        } else {
            return Phase.Trading;
        }
    }

    //exercisedOrExercisableMarkets left for legacy support
    function isParlayExercisable() public view returns (bool isExercisable, bool[] memory exercisedOrExercisableMarkets) {
        isExercisable = !resolved && (areAllPositionsResolved() || isParlayLost());
    }

    //============================== UPDATE PARAMETERS ===========================

    function setPaused(bool _paused) external onlyAMM {
        require(paused != _paused, "State not changed");
        paused = _paused;
        emit PauseUpdated(_paused);
    }

    //============================== EXERCISE ===================================

    function exerciseWiningSportMarkets() external onlyAMM {
        require(!paused, "Market paused");
        (bool isExercisable, ) = isParlayExercisable();
        require(isExercisable, "Parlay not exercisable yet");
        uint totalSUSDamount = parlayMarketsAMM.sUSD().balanceOf(address(this));
        if (isParlayLost()) {
            if (totalSUSDamount > 0) {
                parlayMarketsAMM.sUSD().transfer(address(parlayMarketsAMM), totalSUSDamount);
            }
        } else {
            uint finalPayout = parlayMarketsAMM.sUSD().balanceOf(address(this));
            for (uint i = 0; i < numOfSportMarkets; i++) {
                address _sportMarket = sportMarket[i].sportAddress;
                ISportPositionalMarket currentSportMarket = ISportPositionalMarket(_sportMarket);
                uint result = uint(currentSportMarket.result());
                if (result == 0) {
                    finalPayout = (finalPayout * sportMarket[i].odd) / ONE;
                }
            }
            parlayMarketsAMM.sUSD().transfer(address(parlayOwner), finalPayout);
            parlayMarketsAMM.sUSD().transfer(address(parlayMarketsAMM), parlayMarketsAMM.sUSD().balanceOf(address(this)));
        }

        _resolve(!isParlayLost());
    }

    //============================== INTERNAL FUNCTIONS ===================================

    function _resolve(bool _userWon) internal {
        parlayAlreadyLost = !_userWon;
        resolved = true;
        parlayMarketsAMM.triggerResolvedEvent(parlayOwner, _userWon);
        emit Resolved(_userWon);
    }

    function _isWinningPosition(address _sportMarket, uint _userPosition)
        internal
        view
        returns (bool isWinning, bool isResolved)
    {
        ISportPositionalMarket currentSportMarket = ISportPositionalMarket(_sportMarket);
        isResolved = currentSportMarket.resolved();
        if (
            isResolved &&
            (uint(currentSportMarket.result()) == (_userPosition + 1) ||
                currentSportMarket.result() == ISportPositionalMarket.Side.Cancelled)
        ) {
            isWinning = true;
        }
    }

    //============================== ON EXPIRY FUNCTIONS ===================================

    function withdrawCollateral(address recipient) external onlyAMM {
        parlayMarketsAMM.sUSD().transfer(recipient, parlayMarketsAMM.sUSD().balanceOf(address(this)));
    }

    function expire(address payable beneficiary) external onlyAMM {
        require(phase() == Phase.Expiry, "Ticket Expired");
        require(!resolved, "Can't expire resolved parlay.");
        emit Expired(beneficiary);
        _selfDestruct(beneficiary);
    }

    function _selfDestruct(address payable beneficiary) internal {
        uint balance = parlayMarketsAMM.sUSD().balanceOf(address(this));
        if (balance != 0) {
            parlayMarketsAMM.sUSD().transfer(beneficiary, balance);
        }

        // Destroy the option tokens before destroying the market itself.
        // selfdestruct(beneficiary);
    }

    modifier onlyAMM() {
        require(msg.sender == address(parlayMarketsAMM), "only the AMM may perform these methods");
        _;
    }

    event Resolved(bool isUserTheWinner);
    event Expired(address beneficiary);
    event PauseUpdated(bool _paused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interfaces
import "../../interfaces/IParlayMarketsAMM.sol";
import "../../interfaces/ISportsAMM.sol";
// import "../../interfaces/IParlayMarketData.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/IParlayPolicy.sol";

contract ParlayVerifier {
    uint private constant ONE = 1e18;
    uint private constant ONE_PERCENT = 1e16;

    uint private constant TAG_F1 = 9445;
    uint private constant TAG_MOTOGP = 9497;
    uint private constant TAG_GOLF = 100121;
    uint private constant TAG_NUMBER_SPREAD = 10001;
    uint private constant TAG_NUMBER_TOTAL = 10002;
    uint private constant DOUBLE_CHANCE_TAG = 10003;
    uint private constant PLAYER_PROPS_TAG = 10010;

    struct InitialQuoteParameters {
        address[] sportMarkets;
        uint[] positions;
        uint totalSUSDToPay;
        uint parlaySize;
        uint defaultONE;
        uint[] sgpFees;
        ISportsAMM sportsAMM;
        address parlayAMM;
    }

    struct VerifyMarket {
        address[] sportMarkets;
        uint[] positions;
        ISportsAMM sportsAMM;
        address parlayAMM;
        uint defaultONE;
    }

    struct CachedMarket {
        bytes32 gameId;
        uint gameCounter;
    }

    struct CheckSGP {
        address[] sportMarkets;
        uint[] positions;
        uint[] tag1;
        uint[] tag2;
        IParlayPolicy parlayPolicy;
        uint defaultONE;
    }

    /// @notice Verifying if given parlay is able to be created given the policies in state
    /// @param params VerifyMarket parameters
    /// @return eligible if the parlay can be created
    /// @return odds the odds for each position
    /// @return sgpFees the fees applied per position in case of SameGameParlay
    function _verifyMarkets(VerifyMarket memory params)
        internal
        view
        returns (
            bool eligible,
            uint[] memory odds,
            uint[] memory sgpFees
        )
    {
        eligible = true;
        uint[] memory tags1;
        uint[] memory tags2;
        IParlayPolicy parlayPolicy = IParlayPolicy(IParlayMarketsAMM(params.parlayAMM).parlayPolicy());
        (tags1, tags2) = _obtainAllTags(params.sportMarkets);
        (odds, sgpFees) = _checkSGPAndGetOdds(
            CheckSGP(params.sportMarkets, params.positions, tags1, tags2, parlayPolicy, params.defaultONE)
        );
    }

    /// @notice Obtain all the tags for each position and calculate unique ones
    /// @param sportMarkets the sport markets for the parlay
    /// @return tag1 all the tags 1 per market
    /// @return tag2 all the tags 2 per market
    function _obtainAllTags(address[] memory sportMarkets) internal view returns (uint[] memory tag1, uint[] memory tag2) {
        tag1 = new uint[](sportMarkets.length);
        tag2 = new uint[](sportMarkets.length);
        address sportMarket;
        for (uint i = 0; i < sportMarkets.length; i++) {
            // 1. Get all tags for a sport market (tag1, tag2)
            sportMarket = sportMarkets[i];
            tag1[i] = ISportPositionalMarket(sportMarket).tags(0);
            tag2[i] = ISportPositionalMarket(sportMarket).getTagsLength() > 1
                ? ISportPositionalMarket(sportMarket).tags(1)
                : 0;
            for (uint j = 0; j < i; j++) {
                if (sportMarkets[i] == sportMarkets[j]) {
                    revert("SameTeamOnParlay");
                }
            }
        }
    }

    /// @notice Check the names, check if any markets are SGPs, obtain odds and apply fees if needed
    /// @param params all the parameters to calculate the fees and odds per position
    /// @return odds all the odds per position
    /// @return sgpFees all the fees per position
    function _checkSGPAndGetOdds(CheckSGP memory params) internal view returns (uint[] memory odds, uint[] memory sgpFees) {
        odds = new uint[](params.sportMarkets.length);
        sgpFees = new uint[](odds.length);
        bool[] memory alreadyInSGP = new bool[](sgpFees.length);
        for (uint i = 0; i < params.sportMarkets.length; i++) {
            for (uint j = 0; j < i; j++) {
                if (params.sportMarkets[j] != params.sportMarkets[i]) {
                    if (!alreadyInSGP[j] && params.tag1[j] == params.tag1[i] && (params.tag2[i] > 0 || params.tag2[j] > 0)) {
                        address parentI = address(ISportPositionalMarket(params.sportMarkets[i]).parentMarket());
                        address parentJ = address(ISportPositionalMarket(params.sportMarkets[j]).parentMarket());
                        if (
                            (params.tag2[j] > 0 && parentJ == params.sportMarkets[i]) ||
                            (params.tag2[i] > 0 && parentI == params.sportMarkets[j]) ||
                            // the following line is for totals + spreads or totals + playerProps
                            (params.tag2[i] > 0 && params.tag2[j] > 0 && parentI == parentJ)
                        ) {
                            uint sgpFee = params.parlayPolicy.getSgpFeePerCombination(
                                IParlayPolicy.SGPData(
                                    params.tag1[i],
                                    params.tag2[i],
                                    params.tag2[j],
                                    params.positions[i],
                                    params.positions[j]
                                )
                            );
                            if (params.tag2[j] == PLAYER_PROPS_TAG && params.tag2[i] == PLAYER_PROPS_TAG) {
                                // check if the markets are elibible props markets
                                if (
                                    !params.parlayPolicy.areEligiblePropsMarkets(
                                        params.sportMarkets[i],
                                        params.sportMarkets[j],
                                        params.tag1[i]
                                    )
                                ) {
                                    revert("InvalidPlayerProps");
                                }
                            } else if (sgpFee == 0) {
                                revert("SameTeamOnParlay");
                            } else {
                                alreadyInSGP[i] = true;
                                alreadyInSGP[j] = true;
                                if (params.tag2[j] > 0) {
                                    (odds[i], odds[j], sgpFees[i], sgpFees[j]) = _getSGPSingleOdds(
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[i],
                                            params.positions[i]
                                        ),
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[j],
                                            params.positions[j]
                                        ),
                                        params.positions[j],
                                        sgpFee,
                                        params.parlayPolicy.getChildMarketTotalLine(params.sportMarkets[j]),
                                        params.defaultONE
                                    );
                                } else {
                                    (odds[j], odds[i], sgpFees[j], sgpFees[i]) = _getSGPSingleOdds(
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[j],
                                            params.positions[j]
                                        ),
                                        params.parlayPolicy.getMarketDefaultOdds(
                                            params.sportMarkets[i],
                                            params.positions[i]
                                        ),
                                        params.positions[i],
                                        sgpFee,
                                        params.parlayPolicy.getChildMarketTotalLine(params.sportMarkets[i]),
                                        params.defaultONE
                                    );
                                }
                            }
                        }
                    }
                } else {
                    revert("SameTeamOnParlay");
                }
            }
            if (odds[i] == 0) {
                odds[i] = params.parlayPolicy.getMarketDefaultOdds(params.sportMarkets[i], params.positions[i]);
            }
        }
    }

    function getSPGOdds(
        uint odds1,
        uint odds2,
        uint position2,
        uint sgpFee,
        uint totalsLine,
        uint defaultONE
    )
        external
        pure
        returns (
            uint resultOdds1,
            uint resultOdds2,
            uint sgpFee1,
            uint sgpFee2
        )
    {
        (resultOdds1, resultOdds2, sgpFee1, sgpFee2) = _getSGPSingleOdds(
            odds1,
            odds2,
            position2,
            sgpFee,
            totalsLine,
            defaultONE
        );
    }

    /// @notice Calculate the sgpFees for the positions of two sport markets, given their odds and default sgpfee
    /// @param odds1 the odd of position 1 (usually the moneyline odd)
    /// @param odds2 the odd of position 2 (usually the totals/spreads odd)
    /// @param sgpFee the default sgp fee
    /// @return resultOdds1 the odd1
    /// @return resultOdds2 the odd2
    /// @return sgpFee1 the fee for position 1 or odd1
    /// @return sgpFee2 the fee for position 2 or odd2
    function _getSGPSingleOdds(
        uint odds1,
        uint odds2,
        uint position2,
        uint sgpFee,
        uint totalsLine,
        uint defaultONE
    )
        internal
        pure
        returns (
            uint resultOdds1,
            uint resultOdds2,
            uint sgpFee1,
            uint sgpFee2
        )
    {
        resultOdds1 = odds1;
        resultOdds2 = odds2;

        odds1 = odds1 * defaultONE;
        odds2 = odds2 * defaultONE;

        if (odds1 > 0 && odds2 > 0) {
            if (totalsLine == 2) {
                sgpFee2 = sgpFee;
            } else if (totalsLine == 250) {
                if (position2 == 0) {
                    if (odds1 < (6 * ONE_PERCENT) && odds2 < (70 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee);
                    } else if (odds1 >= (99 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) - 1 * ONE_PERCENT);
                    } else if (odds1 >= (96 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (93 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 75 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (90 * ONE_PERCENT) && odds2 >= (65 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (83 * ONE_PERCENT) && odds2 >= (98 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + (5 * ONE_PERCENT);
                    } else if (odds1 >= (83 * ONE_PERCENT) && odds2 >= (52 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (74 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 20 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (70 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (60 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds1 >= (80 * ONE_PERCENT) && odds2 >= (50 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (60 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 >= (55 * ONE_PERCENT) && odds1 <= (19 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (55 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (54 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (52 * ONE_PERCENT)) {
                        if (odds1 <= (10 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (23 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 45 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + (((5 * ONE_PERCENT) * (ONE - odds1)) / ONE);
                        } else {
                            sgpFee2 = sgpFee;
                        }
                    } else if (odds2 >= (51 * ONE_PERCENT) && odds1 <= (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (51 * ONE_PERCENT) && odds1 <= (25 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((sgpFee * 10 * ONE_PERCENT) / ONE);
                    } else if (odds2 >= (50 * ONE_PERCENT)) {
                        if (odds1 < (10 * ONE_PERCENT)) {
                            sgpFee2 = ONE + odds1;
                        } else if (odds1 <= (21 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (23 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                        } else if (odds1 <= (56 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                        } else {
                            uint oddsDiff = odds2 > odds1 ? odds2 - odds1 : odds1 - odds2;
                            if (oddsDiff > 0) {
                                oddsDiff = (oddsDiff - (5 * ONE_PERCENT) / (90 * ONE_PERCENT));
                                oddsDiff = ((ONE - sgpFee) * oddsDiff) / ONE;
                                sgpFee2 = (sgpFee * (ONE + oddsDiff)) / ONE;
                            } else {
                                sgpFee2 = sgpFee;
                            }
                        }
                    } else if (odds2 >= (49 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT) && odds1 <= (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT) && odds1 <= (40 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT) && odds1 <= (50 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (48 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 >= (46 * ONE_PERCENT) && odds1 <= (43 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (46 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 >= (43 * ONE_PERCENT)) {
                        if (odds1 <= (24 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                        } else if (odds2 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee > 5 * ONE_PERCENT ? sgpFee - (2 * ONE_PERCENT) : sgpFee;
                        } else {
                            uint oddsDiff = odds2 > odds1 ? odds2 - odds1 : odds1 - odds2;
                            if (oddsDiff > 0) {
                                oddsDiff = (oddsDiff - (5 * ONE_PERCENT) / (90 * ONE_PERCENT));
                                oddsDiff = ((ONE - sgpFee + (ONE - sgpFee) / 2) * oddsDiff) / ONE;

                                sgpFee2 = (sgpFee * (ONE + oddsDiff)) / ONE;
                            } else {
                                sgpFee2 = sgpFee;
                            }
                        }
                    } else if (odds2 >= (39 * ONE_PERCENT) && odds1 >= (43 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 >= (35 * ONE_PERCENT)) {
                        if (odds1 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - (((ONE - sgpFee) * (ONE - odds1)) / ONE);
                        } else {
                            sgpFee2 = sgpFee > 5 * ONE_PERCENT ? sgpFee - (2 * ONE_PERCENT) : sgpFee;
                        }
                    } else if (odds2 < (35 * ONE_PERCENT)) {
                        if (odds1 <= (46 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + ((ONE - sgpFee) * 90 * ONE_PERCENT) / ONE;
                        } else {
                            sgpFee2 = sgpFee > 5 * ONE_PERCENT ? sgpFee - (2 * ONE_PERCENT) : sgpFee;
                        }
                    }
                } else {
                    if (odds2 >= (56 * ONE_PERCENT)) {
                        if (odds2 > (68 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                        } else if (odds1 >= 76 * ONE_PERCENT) {
                            sgpFee2 = (ONE + (15 * ONE_PERCENT) + (odds1 * 15 * ONE_PERCENT) / ONE);
                        } else if (odds1 >= 60 * ONE_PERCENT) {
                            sgpFee2 = ONE + (ONE - sgpFee);
                        } else if (odds2 >= (58 * ONE_PERCENT) && odds1 <= (18 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                        } else if (odds2 >= (58 * ONE_PERCENT) && odds1 <= (32 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                        } else if (odds2 >= (55 * ONE_PERCENT) && odds1 >= (58 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee;
                        } else if (odds2 >= (55 * ONE_PERCENT) && odds1 <= (18 * ONE_PERCENT)) {
                            sgpFee2 = sgpFee;
                        } else if (odds1 <= 35 * ONE_PERCENT && odds1 >= 30 * ONE_PERCENT) {
                            sgpFee2 = sgpFee;
                        } else if (odds1 <= 15 * ONE_PERCENT) {
                            sgpFee2 = sgpFee - ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                        } else {
                            sgpFee2 = (ONE + (15 * ONE_PERCENT) + (odds1 * 10 * ONE_PERCENT) / ONE);
                        }
                    } else if (odds2 <= (32 * ONE_PERCENT) && odds1 >= (65 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee);
                    } else if (odds2 <= (32 * ONE_PERCENT) && odds1 >= (85 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 <= (125 * 1e15)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 10 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 > (125 * 1e15) && odds1 <= (13 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (35 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (37 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee);
                    } else if (odds2 <= (37 * ONE_PERCENT) && odds1 <= (16 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 60 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (80 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 5 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (70 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 10 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (66 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 25 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (50 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 5 * ONE_PERCENT);
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (25 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (2 * (ONE - sgpFee));
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 >= (23 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (38 * ONE_PERCENT) && odds1 < (23 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (39 * ONE_PERCENT) && odds1 < (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (9 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (11 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (13 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (14 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (30 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 <= (54 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (40 * ONE_PERCENT) && odds1 > (54 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (11 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (12 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 75 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (14 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (43 * ONE_PERCENT) && odds1 <= (51 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 <= (44 * ONE_PERCENT) && odds1 >= (55 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (44 * ONE_PERCENT) && odds1 <= (55 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (70 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (2 * (ONE - sgpFee)) - ((ONE - sgpFee) * 40 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (44 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (40 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 10 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 >= (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (45 * ONE_PERCENT) && odds1 < (20 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (47 * ONE_PERCENT) && odds1 <= (17 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 70 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (47 * ONE_PERCENT) && odds1 <= (23 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 8 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (48 * ONE_PERCENT) && odds1 <= (11 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (48 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + (sgpFee * 20 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (49 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (49 * ONE_PERCENT) && odds1 <= (25 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 80 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (49 * ONE_PERCENT) && odds1 <= (33 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (17 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (20 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 <= (50 * ONE_PERCENT) && odds1 <= (25 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee - (ONE - sgpFee) - (ONE - sgpFee);
                    } else if (odds2 <= (51 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 <= (10 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 <= (15 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 45 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (52 * ONE_PERCENT) && odds1 > (72 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 35 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (53 * ONE_PERCENT) && odds1 <= (24 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (sgpFee * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 <= (53 * ONE_PERCENT) && odds1 <= (40 * ONE_PERCENT)) {
                        sgpFee2 = ONE;
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 >= (74 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 >= (58 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee + 10 * ONE_PERCENT);
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 >= (24 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 < (54 * ONE_PERCENT) && odds1 < (24 * ONE_PERCENT)) {
                        sgpFee2 = sgpFee + ((ONE - sgpFee) * 30 * ONE_PERCENT) / ONE;
                    } else if (odds2 < (56 * ONE_PERCENT) && odds1 >= (82 * ONE_PERCENT)) {
                        sgpFee2 = ONE + ((ONE - sgpFee) * 50 * ONE_PERCENT) / ONE;
                    } else if (odds2 < (56 * ONE_PERCENT) && odds1 >= (40 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else if (odds2 < (56 * ONE_PERCENT) && odds1 >= (10 * ONE_PERCENT)) {
                        sgpFee2 = ONE + (ONE - sgpFee);
                    } else {
                        sgpFee2 = sgpFee;
                    }
                }
            } else {
                sgpFee2 = sgpFee;
            }
            if (sgpFee2 > 0) {
                uint totalQuote = (odds1 * odds2) / ONE;
                uint totalQuoteWSGP = ((totalQuote * ONE * ONE) / sgpFee2) / ONE;
                if (totalQuoteWSGP < (10 * ONE_PERCENT)) {
                    if (odds1 > (10 * ONE_PERCENT)) {
                        sgpFee2 = ((totalQuote * ONE * ONE) / (10 * ONE_PERCENT)) / ONE;
                    } else {
                        sgpFee2 = ((totalQuote * ONE * ONE) / (odds1 - ((odds1 * 10 * ONE_PERCENT) / ONE))) / ONE;
                    }
                } else if (totalQuoteWSGP > odds1 && odds1 < odds2) {
                    sgpFee2 = odds2 + (4 * 1e15);
                } else if (totalQuoteWSGP > odds2 && odds2 <= odds1) {
                    sgpFee2 = odds1 + (4 * 1e15);
                }
            }
        }
    }

    function calculateInitialQuotesForParlay(InitialQuoteParameters memory params)
        external
        view
        returns (
            uint totalQuote,
            uint totalBuyAmount,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        )
    {
        uint numOfMarkets = params.sportMarkets.length;
        uint inverseSum;
        bool eligible;
        amountsToBuy = new uint[](numOfMarkets);
        (eligible, finalQuotes, params.sgpFees) = _verifyMarkets(
            VerifyMarket(params.sportMarkets, params.positions, params.sportsAMM, params.parlayAMM, params.defaultONE)
        );
        if (eligible && numOfMarkets == params.positions.length && numOfMarkets > 0 && numOfMarkets <= params.parlaySize) {
            for (uint i = 0; i < numOfMarkets; i++) {
                if (params.positions[i] > 2) {
                    totalQuote = 0;
                    break;
                }
                if (finalQuotes.length == 0) {
                    totalQuote = 0;
                    break;
                }
                if (finalQuotes[i] == 0) {
                    totalQuote = 0;
                    break;
                }
                finalQuotes[i] = (params.defaultONE * finalQuotes[i]);
                if (params.sgpFees[i] > 0) {
                    finalQuotes[i] = ((finalQuotes[i] * ONE * ONE) / params.sgpFees[i]) / ONE;
                }
                totalQuote = totalQuote == 0 ? finalQuotes[i] : (totalQuote * finalQuotes[i]) / ONE;
            }
            if (totalQuote != 0) {
                if (totalQuote < IParlayMarketsAMM(params.parlayAMM).maxSupportedOdds()) {
                    totalQuote = IParlayMarketsAMM(params.parlayAMM).maxSupportedOdds();
                }
                totalBuyAmount = (params.totalSUSDToPay * ONE) / totalQuote;
                _calculateRisk(params.sportMarkets, (totalBuyAmount - params.totalSUSDToPay), params.sportsAMM.parlayAMM());
            }

            for (uint i = 0; i < numOfMarkets; i++) {
                //consider if this works well for Arbitrum at 6 decimals
                if (finalQuotes[i] > 0) {
                    amountsToBuy[i] = (ONE * params.totalSUSDToPay) / finalQuotes[i];
                }
            }
        }
    }

    function obtainSportsAMMPosition(uint _position) public pure returns (ISportsAMM.Position) {
        if (_position == 0) {
            return ISportsAMM.Position.Home;
        } else if (_position == 1) {
            return ISportsAMM.Position.Away;
        }
        return ISportsAMM.Position.Draw;
    }

    function _calculateRisk(
        address[] memory _sportMarkets,
        uint _sUSDInRisky,
        address _parlayAMM
    ) internal view returns (bool riskFree) {
        require(_checkRisk(_sportMarkets, _sUSDInRisky, _parlayAMM), "RiskPerComb exceeded");
        riskFree = true;
    }

    function _checkRisk(
        address[] memory _sportMarkets,
        uint _sUSDInRisk,
        address _parlayAMM
    ) internal view returns (bool riskFree) {
        if (_sportMarkets.length > 1 && _sportMarkets.length <= IParlayMarketsAMM(_parlayAMM).parlaySize()) {
            uint riskCombination = IParlayMarketsAMM(_parlayAMM).riskPerPackedGamesCombination(
                _calculateCombinationKey(_sportMarkets)
            );
            riskFree = (riskCombination + _sUSDInRisk) <= IParlayMarketsAMM(_parlayAMM).maxAllowedRiskPerCombination();
        }
    }

    function _calculateCombinationKey(address[] memory _sportMarkets) internal pure returns (bytes32) {
        address[] memory sortedAddresses = new address[](_sportMarkets.length);
        sortedAddresses = _sort(_sportMarkets);
        return keccak256(abi.encodePacked(sortedAddresses));
    }

    function _sort(address[] memory data) internal pure returns (address[] memory) {
        _quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function _quickSort(
        address[] memory arr,
        int left,
        int right
    ) internal pure {
        int i = left;
        int j = right;
        if (i == j) return;
        address pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    function sort(address[] memory data) external pure returns (address[] memory) {
        _quickSort(data, int(0), int(data.length - 1));
        return data;
    }

    function calculateCombinationKey(address[] memory _sportMarkets) external pure returns (bytes32) {
        return _calculateCombinationKey(_sportMarkets);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IParlayMarketData {
    /* ========== VIEWS / VARIABLES ========== */
    function hasParlayGamePosition(
        address _parlay,
        address _game,
        uint _position
    ) external view returns (bool containsParlay);

    function addParlayForGamePosition(
        address _game,
        uint _position,
        address _parlayMarket,
        address _parlayOwner
    ) external;

    function removeParlayForGamePosition(
        address _game,
        uint _position,
        address _parlayMarket
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface ISportPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Cancelled,
        Home,
        Away,
        Draw
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions()
        external
        view
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        );

    function times() external view returns (uint maturity, uint destruction);

    function getGameDetails() external view returns (bytes32 gameId, string memory gameLabel);

    function getGameId() external view returns (bytes32);

    function deposited() external view returns (uint);

    function optionsCount() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function cancelled() external view returns (bool);

    function paused() external view returns (bool);

    function phase() external view returns (Phase);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function isChild() external view returns (bool);

    function optionsInitialized() external view returns (bool);

    function tags(uint idx) external view returns (uint);

    function getTags() external view returns (uint tag1, uint tag2);

    function getTagsLength() external view returns (uint tagsLength);

    function getParentMarketPositions() external view returns (IPosition position1, IPosition position2);

    function getParentMarketPositionsUint() external view returns (uint position1, uint position2);

    function getStampedOdds()
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function balancesOf(address account)
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function totalSupplies()
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function isDoubleChance() external view returns (bool);

    function parentMarket() external view returns (ISportPositionalMarket);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPaused(bool _paused) external;

    function updateDates(uint256 _maturity, uint256 _expiry) external;

    function mint(uint value) external;

    function exerciseOptions() external;

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external;

    function initializeOptions() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISportPositionalMarket.sol";

interface ISportPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function marketCreationEnabled() external view returns (bool);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isDoubleChanceMarket(address candidate) external view returns (bool);

    function doesSportSupportDoubleChance(uint _sport) external view returns (bool);

    function isDoubleChanceSupported() external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getActiveMarketAddress(uint _index) external view returns (address);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function isMarketPaused(address _market) external view returns (bool);

    function expiryDuration() external view returns (uint);

    function isWhitelistedAddress(address _address) external view returns (bool);

    function getOddsObtainer() external view returns (address obtainer);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        uint positionCount,
        uint[] memory tags,
        bool isChild,
        address parentMarket
    ) external returns (ISportPositionalMarket);

    function setMarketPaused(address _market, bool _paused) external;

    function updateDatesForMarket(address _market, uint256 _newStartTime) external;

    function resolveMarket(address market, uint outcome) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;

    function queryMintsAndMaturityStatusForPlayerProps(address[] memory _playerPropsMarkets)
        external
        view
        returns (
            bool[] memory _hasAnyMintsArray,
            bool[] memory _isMaturedArray,
            bool[] memory _isResolvedArray,
            uint[] memory _maturities
        );
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
pragma solidity >=0.5.16;

interface IParlayAMMLiquidityPool {
    function commitTrade(address market, uint amountToMint) external;

    function getMarketRound(address market) external view returns (uint _round);

    function getMarketPool(address market) external view returns (address roundPool);

    function transferToPool(address market, uint amount) external;

    function isUserLPing(address user) external view returns (bool isUserInLP);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IMultiCollateralOnOffRamp {
    function onramp(address collateral, uint collateralAmount) external returns (uint);

    function onrampWithEth(uint amount) external payable returns (uint);

    function getMinimumReceived(address collateral, uint amount) external view returns (uint);

    function getMinimumNeeded(address collateral, uint amount) external view returns (uint);

    function WETH9() external view returns (address);

    function offrampIntoEth(uint amount) external returns (uint);

    function offramp(address collateral, uint amount) external returns (uint);
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

pragma solidity ^0.8.0;

interface ISportAMMRiskManager {
    function calculateCapToBeUsed(address _market) external view returns (uint toReturn);

    function isTotalSpendingLessThanTotalRisk(uint _totalSpent, address _market) external view returns (bool _isNotRisky);

    function isMarketForSportOnePositional(uint _tag) external view returns (bool);

    function isMarketForPlayerPropsOnePositional(uint _tag) external view returns (bool);

    function minSupportedOddsPerSport(uint tag) external view returns (uint);

    function minSpreadPerSport(uint tag1, uint tag2) external view returns (uint);

    function maxSpreadPerSport(uint tag) external view returns (uint);

    function getMinSpreadToUse(
        bool useDefaultMinSpread,
        address market,
        uint min_spread,
        uint min_spreadPerAddress
    ) external view returns (uint);

    function getMaxSpreadForMarket(address _market, uint max_spread) external view returns (uint);

    function getMinOddsForMarket(address _market, uint minSupportedOdds) external view returns (uint minOdds);

    function getCapAndMaxSpreadForMarket(address _market, uint max_spread) external view returns (uint, uint);

    function getCapMaxSpreadAndMinOddsForMarket(
        address _market,
        uint max_spread,
        uint minSupportedOdds
    )
        external
        view
        returns (
            uint cap,
            uint maxSpread,
            uint minOddsForMarket
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnedWithInit {
    address public owner;
    address public nominatedOwner;

    constructor() {}

    function initOwner(address _owner) internal {
        require(owner == address(0), "Init can only be called when owner is 0");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../SportMarkets/Parlay/ParlayVerifier.sol";

interface IParlayMarketsAMM {
    /* ========== VIEWS / VARIABLES ========== */

    function parlaySize() external view returns (uint);

    function sUSD() external view returns (IERC20Upgradeable);

    function sportsAmm() external view returns (address);

    function parlayPolicy() external view returns (address);

    function parlayAmmFee() external view returns (uint);

    function maxAllowedRiskPerCombination() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function getSgpFeePerCombination(
        uint tag1,
        uint tag2_1,
        uint tag2_2,
        uint position1,
        uint position2
    ) external view returns (uint sgpFee);

    function riskPerCombination(
        address _sportMarkets1,
        uint _position1,
        address _sportMarkets2,
        uint _position2,
        address _sportMarkets3,
        uint _position3,
        address _sportMarkets4,
        uint _position4
    ) external view returns (uint);

    function riskPerGameCombination(
        address _sportMarkets1,
        address _sportMarkets2,
        address _sportMarkets3,
        address _sportMarkets4,
        address _sportMarkets5,
        address _sportMarkets6,
        address _sportMarkets7,
        address _sportMarkets8
    ) external view returns (uint);

    function riskPerPackedGamesCombination(bytes32 gamesPacked) external view returns (uint);

    function isActiveParlay(address _parlayMarket) external view returns (bool isActiveParlayMarket);

    function exerciseParlay(address _parlayMarket) external;

    function triggerResolvedEvent(address _account, bool _userWon) external;

    function resolveParlay() external;

    function buyFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid,
        uint _additionalSlippage,
        uint _expectedPayout,
        address _differentRecepient
    ) external;

    function buyQuoteFromParlay(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDPaid
    )
        external
        view
        returns (
            uint sUSDAfterFees,
            uint totalBuyAmount,
            uint totalQuote,
            uint initialQuote,
            uint skewImpact,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        );

    function canCreateParlayMarket(
        address[] calldata _sportMarkets,
        uint[] calldata _positions,
        uint _sUSDToPay
    ) external view returns (bool canBeCreated);

    function numActiveParlayMarkets() external view returns (uint);

    function activeParlayMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function parlayVerifier() external view returns (ParlayVerifier);

    function minUSDAmount() external view returns (uint);

    function maxSupportedAmount() external view returns (uint);

    function safeBoxImpact() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";

import "../../interfaces/IPosition.sol";

// Libraries
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./SportPositionalMarket.sol";

contract SportPosition is IERC20, IPosition {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;

    /* ========== STATE VARIABLES ========== */

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    SportPositionalMarket public market;

    mapping(address => uint) public override balanceOf;
    uint public override totalSupply;

    // The argument order is allowance[owner][spender]
    mapping(address => mapping(address => uint)) private allowances;

    // Enforce a 1 cent minimum amount
    uint internal constant _MINIMUM_AMOUNT = 1e16;

    address public sportsAMM;
    /* ========== CONSTRUCTOR ========== */

    bool public initialized = false;

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _sportsAMM
    ) external {
        require(!initialized, "Positional Market already initialized");
        initialized = true;
        name = _name;
        symbol = _symbol;
        market = SportPositionalMarket(msg.sender);
        // add through constructor
        sportsAMM = _sportsAMM;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        if (spender == sportsAMM) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        } else {
            return allowances[owner][spender];
        }
    }

    function _requireMinimumAmount(uint amount) internal pure returns (uint) {
        require(amount >= _MINIMUM_AMOUNT || amount == 0, "Balance < $0.01");
        return amount;
    }

    function mint(address minter, uint amount) external onlyMarket {
        _requireMinimumAmount(amount);
        totalSupply = totalSupply.add(amount);
        balanceOf[minter] = balanceOf[minter].add(amount); // Increment rather than assigning since a transfer may have occurred.

        emit Transfer(address(0), minter, amount);
        emit Issued(minter, amount);
    }

    // This must only be invoked after maturity.
    function exercise(address claimant) external onlyMarket {
        uint balance = balanceOf[claimant];

        if (balance == 0) {
            return;
        }

        balanceOf[claimant] = 0;
        totalSupply = totalSupply.sub(balance);

        emit Transfer(claimant, address(0), balance);
        emit Burned(claimant, balance);
    }

    // This must only be invoked after maturity.
    function exerciseWithAmount(address claimant, uint amount) external override onlyMarket {
        require(amount > 0, "Can not exercise zero amount!");

        require(balanceOf[claimant] >= amount, "Balance must be greather or equal amount that is burned");

        balanceOf[claimant] = balanceOf[claimant] - amount;
        totalSupply = totalSupply.sub(amount);

        emit Transfer(claimant, address(0), amount);
        emit Burned(claimant, amount);
    }

    // This must only be invoked after the exercise window is complete.
    // Note that any options which have not been exercised will linger.
    function expire(address payable beneficiary) external onlyMarket {
        selfdestruct(beneficiary);
    }

    /* ---------- ERC20 Functions ---------- */

    function _transfer(
        address _from,
        address _to,
        uint _value
    ) internal returns (bool success) {
        market.requireUnpaused();
        require(_to != address(0) && _to != address(this), "Invalid address");

        uint fromBalance = balanceOf[_from];
        require(_value <= fromBalance, "Insufficient balance");

        balanceOf[_from] = fromBalance.sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external override returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
    ) external override returns (bool success) {
        if (msg.sender != sportsAMM) {
            uint fromAllowance = allowances[_from][msg.sender];
            require(_value <= fromAllowance, "Insufficient allowance");
            allowances[_from][msg.sender] = fromAllowance.sub(_value);
        }
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) external override returns (bool success) {
        require(_spender != address(0));
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function getBalanceOf(address account) external view override returns (uint) {
        return balanceOf[account];
    }

    function getTotalSupply() external view override returns (uint) {
        return totalSupply;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyMarket() {
        require(msg.sender == address(market), "Only market allowed");
        _;
    }

    /* ========== EVENTS ========== */

    event Issued(address indexed account, uint value);
    event Burned(address indexed account, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.0;

interface IParlayPolicy {
    struct SGPData {
        uint tag1;
        uint tag2_1;
        uint tag2_2;
        uint position1;
        uint position2;
    }

    /* ========== VIEWS / VARIABLES ========== */
    function consumer() external view returns (address);

    function getSgpFeePerCombination(SGPData memory params) external view returns (uint sgpFee);

    function getMarketDefaultOdds(address _sportMarket, uint _position) external view returns (uint odd);

    function areEligiblePropsMarkets(
        address _childMarket1,
        address _childMarket2,
        uint _tag1
    ) external view returns (bool samePlayerDifferentProp);

    function getChildMarketTotalLine(address _sportMarket) external view returns (uint childTotalsLine);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
pragma solidity ^0.8.0;

// Inheritance
import "../../OwnedWithInit.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ITherundownConsumer.sol";
import "../../interfaces/ISportsAMM.sol";
import "../../interfaces/ISportPositionalMarketFactory.sol";

// Libraries
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./SportPositionalMarketManager.sol";
import "./SportPosition.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";

contract SportPositionalMarket is OwnedWithInit, ISportPositionalMarket {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;

    /* ========== TYPES ========== */

    struct Options {
        SportPosition home;
        SportPosition away;
        SportPosition draw;
    }

    struct Times {
        uint maturity;
        uint expiry;
    }

    struct GameDetails {
        bytes32 gameId;
        string gameLabel;
    }

    struct SportPositionalMarketParameters {
        address owner;
        address creator;
        bytes32 gameId;
        string gameLabel;
        uint[2] times; // [maturity, expiry]
        uint positionCount;
        address[] positions;
        uint[] tags;
        bool isChild;
        address parentMarket;
        bool isDoubleChance;
        address factory;
    }

    /* ========== STATE VARIABLES ========== */

    Options public options;
    uint public override optionsCount;
    Times public parentTimes;
    GameDetails private gameDetails;
    string private childGameLabel;
    uint[] public override tags;
    uint public finalResult;

    // `deposited` tracks the sum of all deposits.
    // This must explicitly be kept, in case tokens are transferred to the contract directly.
    uint public override deposited;
    address public override creator;
    bool public override resolved;
    bool public override cancelled;
    uint public cancelTimestamp;
    uint public homeOddsOnCancellation;
    uint public awayOddsOnCancellation;
    uint public drawOddsOnCancellation;

    bool public invalidOdds;
    bool public initialized = false;
    bool public override paused;
    bool public override isChild;
    ISportPositionalMarket public override parentMarket;

    bool public override isDoubleChance;
    bool public override optionsInitialized;
    address public factory;

    /* ========== CONSTRUCTOR ========== */
    function initialize(SportPositionalMarketParameters calldata _parameters) external {
        require(!initialized, "Positional Market already initialized");
        initialized = true;
        initOwner(_parameters.owner);

        optionsCount = _parameters.positionCount;
        require(optionsCount == _parameters.positions.length, "Position count mismatch");

        creator = _parameters.creator;
        if (_parameters.isChild || _parameters.isDoubleChance) {
            isChild = _parameters.isChild;
            isDoubleChance = _parameters.isDoubleChance;
            parentMarket = ISportPositionalMarket(_parameters.parentMarket);
            childGameLabel = _parameters.gameLabel;
        } else {
            parentTimes = Times(_parameters.times[0], _parameters.times[1]);
            gameDetails = GameDetails(_parameters.gameId, _parameters.gameLabel);
        }

        tags = _parameters.tags;
        factory = _parameters.factory;
    }

    /* ---------- External Contracts ---------- */

    function _manager() internal view returns (SportPositionalMarketManager) {
        return SportPositionalMarketManager(owner);
    }

    /* ---------- Phases ---------- */

    function _times() internal view returns (Times memory) {
        if (isChild || isDoubleChance) {
            (uint maturity, uint expiry) = parentMarket.times();
            return Times(maturity, expiry);
        }
        return parentTimes;
    }

    function _matured() internal view returns (bool) {
        return _times().maturity < block.timestamp;
    }

    function _expired() internal view returns (bool) {
        return resolved && (_times().expiry < block.timestamp || deposited == 0);
    }

    function _isPaused() internal view returns (bool) {
        return isDoubleChance ? parentMarket.paused() : paused;
    }

    function getTags() external view override returns (uint tag1, uint tag2) {
        if (tags.length > 1) {
            tag1 = tags[0];
            tag2 = tags[1];
        } else {
            tag1 = tags[0];
        }
    }

    function getTagsLength() external view override returns (uint tagsLength) {
        return tags.length;
    }

    function times() external view override returns (uint maturity, uint destruction) {
        Times memory time = _times();
        return (time.maturity, time.expiry);
    }

    function phase() external view override returns (Phase) {
        if (!_matured()) {
            return Phase.Trading;
        }
        if (!_expired()) {
            return Phase.Maturity;
        }
        return Phase.Expiry;
    }

    function setPaused(bool _paused) external override onlyOwner managerNotPaused {
        require(paused != _paused, "State not changed");
        paused = _paused;
        emit PauseUpdated(_paused);
    }

    function updateDates(uint256 _maturity, uint256 _expiry) external override onlyOwner managerNotPaused noDoubleChance {
        require(_maturity > block.timestamp, "Maturity must be in a future");
        if (!isChild) {
            parentTimes = Times(_maturity, _expiry);
        }
        emit DatesUpdated(_maturity, _expiry);
    }

    /* ---------- Market Resolution ---------- */

    function canResolve() public view override returns (bool) {
        return !resolved && _matured() && !paused;
    }

    function getGameDetails() external view override returns (bytes32 gameId, string memory gameLabel) {
        return (_getDetails().gameId, _getDetails().gameLabel);
    }

    function getParentMarketPositionsUint() public view override returns (uint position1, uint position2) {
        if (isDoubleChance) {
            (IPosition home, , ) = parentMarket.getOptions();
            if (_hasNotBeenInitialized(home)) {
                if (
                    keccak256(abi.encodePacked(_getDetails().gameLabel)) == keccak256(abi.encodePacked("HomeTeamNotToLose"))
                ) {
                    (position1, position2) = (0, 2);
                } else if (
                    keccak256(abi.encodePacked(_getDetails().gameLabel)) == keccak256(abi.encodePacked("AwayTeamNotToLose"))
                ) {
                    (position1, position2) = (1, 2);
                } else {
                    (position1, position2) = (0, 1);
                }
            }
        }
    }

    function getParentMarketPositions() public view override returns (IPosition position1, IPosition position2) {
        if (isDoubleChance) {
            (IPosition home, IPosition away, IPosition draw) = parentMarket.getOptions();
            if (keccak256(abi.encodePacked(_getDetails().gameLabel)) == keccak256(abi.encodePacked("HomeTeamNotToLose"))) {
                (position1, position2) = (home, draw);
            } else if (
                keccak256(abi.encodePacked(_getDetails().gameLabel)) == keccak256(abi.encodePacked("AwayTeamNotToLose"))
            ) {
                (position1, position2) = (away, draw);
            } else {
                (position1, position2) = (home, away);
            }
        }
    }

    function _result() internal view returns (Side) {
        if (!resolved || cancelled) {
            return Side.Cancelled;
        } else if (finalResult == 3 && optionsCount > 2) {
            return Side.Draw;
        } else {
            return finalResult == 1 ? Side.Home : Side.Away;
        }
    }

    function result() external view override returns (Side) {
        return _result();
    }

    /* ---------- Option Balances and Mints ---------- */
    function getGameId() external view override returns (bytes32) {
        return _getDetails().gameId;
    }

    function getStampedOdds()
        public
        view
        override
        returns (
            uint,
            uint,
            uint
        )
    {
        if (cancelled) {
            if (isDoubleChance) {
                (uint position1Odds, uint position2Odds) = _getParentPositionOdds();

                return (position1Odds + position2Odds, 0, 0);
            }
            return (homeOddsOnCancellation, awayOddsOnCancellation, drawOddsOnCancellation);
        } else {
            return (0, 0, 0);
        }
    }

    function _getParentPositionOdds() internal view returns (uint odds1, uint odds2) {
        (uint homeOddsParent, uint awayOddsParent, uint drawOddsParent) = parentMarket.getStampedOdds();
        (IPosition position1, IPosition position2) = getParentMarketPositions();
        (IPosition home, IPosition away, ) = parentMarket.getOptions();

        if (_hasNotBeenInitialized(home)) {
            return (0, 0);
        }

        odds1 = position1 == home ? homeOddsParent : position1 == away ? awayOddsParent : drawOddsParent;
        odds2 = position2 == home ? homeOddsParent : position2 == away ? awayOddsParent : drawOddsParent;
    }

    function _balancesOf(address account)
        internal
        view
        returns (
            uint home,
            uint away,
            uint draw
        )
    {
        if (!optionsInitialized) {
            return (0, 0, 0);
        }
        if (optionsCount > 2) {
            return (
                options.home.getBalanceOf(account),
                options.away.getBalanceOf(account),
                options.draw.getBalanceOf(account)
            );
        }
        return (options.home.getBalanceOf(account), options.away.getBalanceOf(account), 0);
    }

    function balancesOf(address account)
        external
        view
        override
        returns (
            uint home,
            uint away,
            uint draw
        )
    {
        return _balancesOf(account);
    }

    function totalSupplies()
        external
        view
        override
        returns (
            uint home,
            uint away,
            uint draw
        )
    {
        if (optionsCount > 2) {
            return (options.home.totalSupply(), options.away.totalSupply(), options.draw.totalSupply());
        }
        return (options.home.totalSupply(), options.away.totalSupply(), 0);
    }

    function getOptions()
        external
        view
        override
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        )
    {
        home = options.home;
        away = options.away;
        draw = options.draw;
    }

    function _getMaximumBurnable(address account) internal view returns (uint amount) {
        (uint homeBalance, uint awayBalance, uint drawBalance) = _balancesOf(account);
        uint min = homeBalance;
        if (min > awayBalance) {
            min = awayBalance;
            if (optionsCount > 2 && drawBalance < min) {
                min = drawBalance;
            }
        } else {
            if (optionsCount > 2 && drawBalance < min) {
                min = drawBalance;
            }
        }
        return min;
    }

    function _getDetails() internal view returns (GameDetails memory) {
        if (isChild || isDoubleChance) {
            (bytes32 gameId, ) = parentMarket.getGameDetails();
            return GameDetails(gameId, childGameLabel);
        }
        return gameDetails;
    }

    /* ---------- Utilities ---------- */

    function _incrementDeposited(uint value) internal returns (uint _deposited) {
        _deposited = deposited.add(value);
        deposited = _deposited;
        _manager().incrementTotalDeposited(value);
    }

    function _decrementDeposited(uint value) internal returns (uint _deposited) {
        _deposited = deposited.sub(value);
        deposited = _deposited;
        _manager().decrementTotalDeposited(value);
    }

    function _requireManagerNotPaused() internal view {
        require(!_manager().paused(), "This action cannot be performed while the contract is paused");
    }

    function requireUnpaused() external view {
        _requireManagerNotPaused();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Minting ---------- */

    function mint(uint value) external override {
        require(!_matured() && !_isPaused(), "Minting inactive");
        require(msg.sender == ISportPositionalMarketFactory(factory).sportsAMM(), "Invalid minter");
        if (value == 0) {
            return;
        }

        _mint(msg.sender, value);

        if (!isDoubleChance) {
            _incrementDeposited(value);
            _manager().transferSusdTo(msg.sender, address(this), value);
        }
    }

    function _mint(address minter, uint amount) internal {
        if (!optionsInitialized) {
            _initializeOptions();
        }
        if (isDoubleChance) {
            options.home.mint(minter, amount);
            emit Mint(Side.Home, minter, amount);
        } else {
            options.home.mint(minter, amount);
            options.away.mint(minter, amount);
            emit Mint(Side.Home, minter, amount);
            emit Mint(Side.Away, minter, amount);
            if (optionsCount > 2) {
                options.draw.mint(minter, amount);
                emit Mint(Side.Draw, minter, amount);
            }
        }
    }

    function initializeOptions() external override {
        _initializeOptions();
    }

    function _initializeOptions() internal {
        require(!optionsInitialized, "already initialized");
        address[] memory positions = new address[](optionsCount);
        for (uint i = 0; i < optionsCount; i++) {
            positions[i] = address(SportPosition(Clones.clone(ISportPositionalMarketFactory(factory).positionMastercopy())));
        }

        // Instantiate the options themselves
        options.home = SportPosition(positions[0]);
        options.away = SportPosition(positions[1]);
        if (isChild) {
            require(tags.length > 1, "Child markets must have more then one tag");
            if (tags[1] == 10001) {
                options.home.initialize(_getDetails().gameLabel, "HOME", ISportPositionalMarketFactory(factory).sportsAMM());
                options.away.initialize(_getDetails().gameLabel, "AWAY", ISportPositionalMarketFactory(factory).sportsAMM());
            } else if (tags[1] == 10002 || tags[1] == 10010) {
                options.home.initialize(_getDetails().gameLabel, "OVER", ISportPositionalMarketFactory(factory).sportsAMM());
                options.away.initialize(
                    _getDetails().gameLabel,
                    "UNDER",
                    ISportPositionalMarketFactory(factory).sportsAMM()
                );
            }
        } else {
            options.home.initialize(_getDetails().gameLabel, "HOME", ISportPositionalMarketFactory(factory).sportsAMM());
            options.away.initialize(_getDetails().gameLabel, "AWAY", ISportPositionalMarketFactory(factory).sportsAMM());
        }

        if (optionsCount > 2) {
            options.draw = SportPosition(positions[2]);
            options.draw.initialize(_getDetails().gameLabel, "DRAW", ISportPositionalMarketFactory(factory).sportsAMM());
        }
        optionsInitialized = true;
        emit PositionsInitialized(
            address(this),
            address(options.home),
            address(options.away),
            optionsCount > 2 ? address(options.draw) : address(0)
        );
    }

    function _hasNotBeenInitialized(IPosition home) internal view returns (bool) {
        return address(home) == address(0);
    }

    /* ---------- Market Resolution ---------- */

    function resolve(uint _outcome) external onlyOwner managerNotPaused {
        require(_outcome <= optionsCount, "Invalid outcome");
        if (_outcome == 0) {
            cancelled = true;
            cancelTimestamp = block.timestamp;
            if (!isDoubleChance) {
                stampOdds();
            }
        } else {
            require(canResolve(), "Can not resolve market");
        }
        finalResult = _outcome;
        resolved = true;
        emit MarketResolved(_result(), deposited, 0, 0);
    }

    function stampOdds() internal {
        uint[] memory odds = new uint[](optionsCount);
        odds = ITherundownConsumer(creator).getNormalizedOddsForMarket(address(this));
        if (odds[0] == 0 || odds[1] == 0) {
            invalidOdds = true;
        }
        homeOddsOnCancellation = odds[0];
        awayOddsOnCancellation = odds[1];
        drawOddsOnCancellation = optionsCount > 2 ? odds[2] : 0;
        emit StoredOddsOnCancellation(homeOddsOnCancellation, awayOddsOnCancellation, drawOddsOnCancellation);
    }

    /* ---------- Claiming and Exercising Options ---------- */

    function exerciseOptions() external override {
        // The market must be resolved if it has not been.
        require(resolved, "Unresolved");
        require(!_isPaused(), "Paused");
        // If the account holds no options, revert.
        (uint homeBalance, uint awayBalance, uint drawBalance) = _balancesOf(msg.sender);
        require(homeBalance != 0 || awayBalance != 0 || drawBalance != 0, "Nothing to exercise");

        if (isDoubleChance && _canExerciseParentOptions()) {
            parentMarket.exerciseOptions();
        }
        // Each option only needs to be exercised if the account holds any of it.
        if (homeBalance != 0) {
            options.home.exercise(msg.sender);
        }
        if (awayBalance != 0) {
            options.away.exercise(msg.sender);
        }
        if (drawBalance != 0) {
            options.draw.exercise(msg.sender);
        }
        uint payout = _getPayout(homeBalance, awayBalance, drawBalance);

        if (cancelled) {
            require(
                block.timestamp > cancelTimestamp.add(_manager().cancelTimeout()) && !invalidOdds,
                "Unexpired timeout/ invalid odds"
            );
            payout = calculatePayoutOnCancellation(homeBalance, awayBalance, drawBalance);
        }
        emit OptionsExercised(msg.sender, payout);
        if (payout != 0) {
            if (!isDoubleChance) {
                _decrementDeposited(payout);
            }
            payout = _manager().transformCollateral(payout);
            ISportsAMM(ISportPositionalMarketFactory(factory).sportsAMM()).sUSD().transfer(msg.sender, payout);
        }
    }

    function _canExerciseParentOptions() internal view returns (bool) {
        if (!parentMarket.resolved() && !parentMarket.canResolve()) {
            return false;
        }

        (uint homeBalance, uint awayBalance, uint drawBalance) = parentMarket.balancesOf(address(this));

        if (homeBalance == 0 && awayBalance == 0 && drawBalance == 0) {
            return false;
        }

        return true;
    }

    function _getPayout(
        uint homeBalance,
        uint awayBalance,
        uint drawBalance
    ) internal view returns (uint payout) {
        if (isDoubleChance) {
            if (_result() == Side.Home) {
                payout = homeBalance;
            }
        } else {
            payout = (_result() == Side.Home) ? homeBalance : awayBalance;

            if (optionsCount > 2 && _result() != Side.Home) {
                payout = _result() == Side.Away ? awayBalance : drawBalance;
            }
        }
    }

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external override onlyOwner {
        require(_homeOdds > 0 && _awayOdds > 0, "Invalid odd");
        homeOddsOnCancellation = _homeOdds;
        awayOddsOnCancellation = _awayOdds;
        drawOddsOnCancellation = optionsCount > 2 ? _drawOdds : 0;
        invalidOdds = false;
        emit StoredOddsOnCancellation(homeOddsOnCancellation, awayOddsOnCancellation, drawOddsOnCancellation);
    }

    function calculatePayoutOnCancellation(
        uint _homeBalance,
        uint _awayBalance,
        uint _drawBalance
    ) public view returns (uint payout) {
        if (!cancelled) {
            return 0;
        } else {
            if (isDoubleChance) {
                (uint position1Odds, uint position2Odds) = _getParentPositionOdds();
                payout = _homeBalance.mul(position1Odds).div(1e18);
                payout = payout.add(_homeBalance.mul(position2Odds).div(1e18));
            } else {
                payout = _homeBalance.mul(homeOddsOnCancellation).div(1e18);
                payout = payout.add(_awayBalance.mul(awayOddsOnCancellation).div(1e18));
                payout = payout.add(_drawBalance.mul(drawOddsOnCancellation).div(1e18));
            }
        }
    }

    /* ---------- Market Expiry ---------- */

    function _selfDestruct(address payable beneficiary) internal {
        uint _deposited = deposited;
        if (_deposited != 0) {
            _decrementDeposited(_deposited);
        }

        // Transfer the balance rather than the deposit value in case there are any synths left over
        // from direct transfers.
        uint balance = ISportsAMM(ISportPositionalMarketFactory(factory).sportsAMM()).sUSD().balanceOf(address(this));
        if (balance != 0) {
            ISportsAMM(ISportPositionalMarketFactory(factory).sportsAMM()).sUSD().transfer(beneficiary, balance);
        }

        // Destroy the option tokens before destroying the market itself.
        options.home.expire(beneficiary);
        options.away.expire(beneficiary);
        selfdestruct(beneficiary);
    }

    function expire(address payable beneficiary) external onlyOwner {
        require(_expired(), "Unexpired options remaining");
        emit Expired(beneficiary);
        _selfDestruct(beneficiary);
    }

    /* ========== MODIFIERS ========== */

    modifier managerNotPaused() {
        _requireManagerNotPaused();
        _;
    }

    modifier noDoubleChance() {
        require(!isDoubleChance, "Not supported for double chance markets");
        _;
    }

    /* ========== EVENTS ========== */

    event Mint(Side side, address indexed account, uint value);
    event MarketResolved(Side result, uint deposited, uint poolFees, uint creatorFees);

    event OptionsExercised(address indexed account, uint value);
    event OptionsBurned(address indexed account, uint value);
    event Expired(address beneficiary);
    event StoredOddsOnCancellation(uint homeOdds, uint awayOdds, uint drawOdds);
    event PauseUpdated(bool _paused);
    event DatesUpdated(uint256 _maturity, uint256 _expiry);
    event PositionsInitialized(address _market, address _home, address _away, address _draw);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITherundownConsumer {
    struct GameCreate {
        bytes32 gameId;
        uint256 startTime;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        string homeTeam;
        string awayTeam;
    }

    // view functions
    function supportedSport(uint _sportId) external view returns (bool);

    function gameOnADate(bytes32 _gameId) external view returns (uint);

    function isGameResolvedOrCanceled(bytes32 _gameId) external view returns (bool);

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function getGamesPerDatePerSport(uint _sportId, uint _date) external view returns (bytes32[] memory);

    function getGamePropsForOdds(address _market)
        external
        view
        returns (
            uint,
            uint,
            bytes32
        );

    function gameIdPerMarket(address _market) external view returns (bytes32);

    function getGameCreatedById(bytes32 _gameId) external view returns (GameCreate memory);

    function isChildMarket(address _market) external view returns (bool);

    function gameFulfilledCreated(bytes32 _gameId) external view returns (bool);

    function playerProps() external view returns (address);

    function oddsObtainer() external view returns (address);

    // write functions
    function fulfillGamesCreated(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportsId,
        uint _date
    ) external;

    function fulfillGamesResolved(
        bytes32 _requestId,
        bytes[] memory _games,
        uint _sportsId
    ) external;

    function fulfillGamesOdds(bytes32 _requestId, bytes[] memory _games) external;

    function setPausedByCanceledStatus(address _market, bool _flag) external;

    function setGameIdPerChildMarket(bytes32 _gameId, address _child) external;

    function pauseOrUnpauseMarket(address _market, bool _pause) external;

    function pauseOrUnpauseMarketForPlayerProps(
        address _market,
        bool _pause,
        bool _invalidOdds,
        bool _circuitBreakerMain
    ) external;

    function setChildMarkets(
        bytes32 _gameId,
        address _main,
        address _child,
        bool _isSpread,
        int16 _spreadHome,
        uint24 _totalOver
    ) external;

    function resolveMarketManually(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        bool _usebackupOdds
    ) external;

    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            int24,
            int24,
            int24
        );

    function sportsIdPerGame(bytes32 _gameId) external view returns (uint);

    function getGameStartTime(bytes32 _gameId) external view returns (uint256);

    function getLastUpdatedFromGameResolve(bytes32 _gameId) external view returns (uint40);

    function marketPerGameId(bytes32 _gameId) external view returns (address);

    function marketResolved(address _market) external view returns (bool);

    function marketCanceled(address _market) external view returns (bool);

    function invalidOdds(address _market) external view returns (bool);

    function isPausedByCanceledStatus(address _market) external view returns (bool);

    function isSportOnADate(uint _date, uint _sportId) external view returns (bool);

    function isSportTwoPositionsSport(uint _sportsId) external view returns (bool);

    function marketForTeamName(string memory _teamName) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISportPositionalMarketFactory {
    function sportsAMM() external view returns (address);

    function positionMastercopy() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../../utils/proxy/solidity-0.8.0/ProxyPausable.sol";

// Libraries
import "../../utils/libraries/AddressSetLib.sol";
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";

// Internal references
import "./SportPositionalMarketFactory.sol";
import "./SportPositionalMarket.sol";
import "./SportPosition.sol";
import "../../interfaces/ISportPositionalMarketManager.sol";
import "../../interfaces/ISportPositionalMarket.sol";
import "../../interfaces/ITherundownConsumer.sol";

import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IGamesOddsObtainer.sol";
import "../../interfaces/IGamesPlayerProps.sol";

import "../../interfaces/IGameChildMarket.sol";

contract SportPositionalMarketManager is Initializable, ProxyOwned, ProxyPausable, ISportPositionalMarketManager {
    /* ========== LIBRARIES ========== */
    using SafeMath for uint;
    using AddressSetLib for AddressSetLib.AddressSet;

    /* ========== STATE VARIABLES ========== */

    uint public override expiryDuration;

    bool public override marketCreationEnabled;
    bool public customMarketCreationEnabled;

    uint public override totalDeposited;

    AddressSetLib.AddressSet internal _activeMarkets;
    AddressSetLib.AddressSet internal _maturedMarkets;

    SportPositionalMarketManager internal _migratingManager;

    IERC20 public sUSD;

    address public theRundownConsumer;
    address public sportPositionalMarketFactory;
    bool public needsTransformingCollateral;
    mapping(address => bool) public whitelistedAddresses;
    address private apexConsumer; // deprecated
    uint public cancelTimeout;
    mapping(address => bool) public whitelistedCancelAddresses;
    address public oddsObtainer;

    mapping(address => bool) public isDoubleChance;
    bool public override isDoubleChanceSupported;
    mapping(address => address[]) public doubleChanceMarketsByParent;
    mapping(uint => bool) public override doesSportSupportDoubleChance;
    address public playerProps;

    /* ========== CONSTRUCTOR ========== */

    function initialize(address _owner, IERC20 _sUSD) external initializer {
        setOwner(_owner);
        sUSD = _sUSD;

        // Temporarily change the owner so that the setters don't revert.
        owner = msg.sender;

        marketCreationEnabled = true;
        customMarketCreationEnabled = false;
    }

    /* ========== SETTERS ========== */
    function setSportPositionalMarketFactory(address _sportPositionalMarketFactory) external onlyOwner {
        sportPositionalMarketFactory = _sportPositionalMarketFactory;
        emit SetSportPositionalMarketFactory(_sportPositionalMarketFactory);
    }

    function setTherundownConsumer(address _theRundownConsumer) external onlyOwner {
        theRundownConsumer = _theRundownConsumer;
        emit SetTherundownConsumer(_theRundownConsumer);
    }

    function setOddsObtainer(address _oddsObtainer) external onlyOwner {
        oddsObtainer = _oddsObtainer;
        emit SetObtainerAddress(_oddsObtainer);
    }

    function setPlayerProps(address _playerProps) external onlyOwner {
        playerProps = _playerProps;
        emit SetPlayerPropsAddress(_playerProps);
    }

    function getOddsObtainer() external view override returns (address obtainer) {
        obtainer = oddsObtainer;
    }

    /// @notice setNeedsTransformingCollateral sets needsTransformingCollateral value
    /// @param _needsTransformingCollateral boolen value to be set
    function setNeedsTransformingCollateral(bool _needsTransformingCollateral) external onlyOwner {
        needsTransformingCollateral = _needsTransformingCollateral;
    }

    /// @notice setWhitelistedAddresses enables whitelist addresses of given array
    /// @param _whitelistedAddresses array of whitelisted addresses
    /// @param _flag adding or removing from whitelist (true: add, false: remove)
    function setWhitelistedAddresses(
        address[] calldata _whitelistedAddresses,
        bool _flag,
        uint8 _group
    ) external onlyOwner {
        require(_whitelistedAddresses.length > 0, "Whitelisted addresses cannot be empty");
        for (uint256 index = 0; index < _whitelistedAddresses.length; index++) {
            // only if current flag is different, if same skip it
            if (_group == 1) {
                if (whitelistedAddresses[_whitelistedAddresses[index]] != _flag) {
                    whitelistedAddresses[_whitelistedAddresses[index]] = _flag;
                    emit AddedIntoWhitelist(_whitelistedAddresses[index], _flag);
                }
            }
            if (_group == 2) {
                if (whitelistedCancelAddresses[_whitelistedAddresses[index]] != _flag) {
                    whitelistedCancelAddresses[_whitelistedAddresses[index]] = _flag;
                    emit AddedIntoWhitelist(_whitelistedAddresses[index], _flag);
                }
            }
        }
    }

    /* ========== VIEWS ========== */

    /* ---------- Market Information ---------- */

    function isKnownMarket(address candidate) public view override returns (bool) {
        return _activeMarkets.contains(candidate) || _maturedMarkets.contains(candidate);
    }

    function isActiveMarket(address candidate) public view override returns (bool) {
        return _activeMarkets.contains(candidate) && !ISportPositionalMarket(candidate).paused();
    }

    function isDoubleChanceMarket(address candidate) public view override returns (bool) {
        return isDoubleChance[candidate];
    }

    function numActiveMarkets() external view override returns (uint) {
        return _activeMarkets.elements.length;
    }

    function activeMarkets(uint index, uint pageSize) external view override returns (address[] memory) {
        return _activeMarkets.getPage(index, pageSize);
    }

    function numMaturedMarkets() external view override returns (uint) {
        return _maturedMarkets.elements.length;
    }

    function getActiveMarketAddress(uint _index) external view override returns (address) {
        if (_index < _activeMarkets.elements.length) {
            return _activeMarkets.elements[_index];
        } else {
            return address(0);
        }
    }

    function getDoubleChanceMarketsByParentMarket(address market) external view returns (address[] memory) {
        return _getDoubleChanceMarkets(market);
    }

    function maturedMarkets(uint index, uint pageSize) external view override returns (address[] memory) {
        return _maturedMarkets.getPage(index, pageSize);
    }

    function setMarketPaused(address _market, bool _paused) external override {
        require(
            msg.sender == owner ||
                msg.sender == theRundownConsumer ||
                msg.sender == oddsObtainer ||
                msg.sender == playerProps ||
                whitelistedAddresses[msg.sender],
            "Invalid caller"
        );
        require(ISportPositionalMarket(_market).paused() != _paused, "No state change");
        ISportPositionalMarket(_market).setPaused(_paused);
    }

    function updateDatesForMarket(address _market, uint256 _newStartTime) external override {
        require(msg.sender == owner || msg.sender == theRundownConsumer, "Invalid caller");

        uint expiry = _newStartTime.add(expiryDuration);

        // Update main market
        _updateDatesForMarket(_market, _newStartTime, expiry);

        // Update child markets
        _updateDatesForChildMarkets(_market, _newStartTime, expiry, oddsObtainer);
        _updateDatesForChildMarkets(_market, _newStartTime, expiry, playerProps);
    }

    function _updateDatesForChildMarkets(
        address _market,
        uint256 _newStartTime,
        uint256 _expiry,
        address _childMarketContract
    ) internal {
        uint numberOfChildMarkets = IGameChildMarket(_childMarketContract).numberOfChildMarkets(_market);

        for (uint i = 0; i < numberOfChildMarkets; i++) {
            address child = IGameChildMarket(_childMarketContract).mainMarketChildMarketIndex(_market, i);
            _updateDatesForMarket(child, _newStartTime, _expiry);
        }
    }

    function isMarketPaused(address _market) external view override returns (bool) {
        return ISportPositionalMarket(_market).paused();
    }

    function queryMintsAndMaturityStatusForParents(address[] memory _parents)
        external
        view
        returns (
            bool[] memory _hasAnyMintsArray,
            bool[] memory _isMaturedArray,
            bool[] memory _isResolvedArray
        )
    {
        _hasAnyMintsArray = new bool[](_parents.length);
        _isMaturedArray = new bool[](_parents.length);
        _isResolvedArray = new bool[](_parents.length);
        for (uint i = 0; i < _parents.length; i++) {
            (bool _hasAnyMints, uint _maturity) = _hasAnyMintsAndMaturityDatesForMarket(_parents[i]);
            _isResolvedArray[i] = _isResolvedMarket(_parents[i]);
            _hasAnyMintsArray[i] = _hasAnyMints;
            _isMaturedArray[i] = _maturity <= block.timestamp;
        }
    }

    function queryMintsAndMaturityStatusForPlayerProps(address[] memory _playerPropsMarkets)
        external
        view
        override
        returns (
            bool[] memory _hasAnyMintsArray,
            bool[] memory _isMaturedArray,
            bool[] memory _isResolvedArray,
            uint[] memory _maturities
        )
    {
        _hasAnyMintsArray = new bool[](_playerPropsMarkets.length);
        _isMaturedArray = new bool[](_playerPropsMarkets.length);
        _isResolvedArray = new bool[](_playerPropsMarkets.length);
        _maturities = new uint[](_playerPropsMarkets.length);
        for (uint i = 0; i < _playerPropsMarkets.length; i++) {
            (bool _hasAnyMints, uint _maturity) = _hasAnyMintsAndMaturityDatesForPP(_playerPropsMarkets[i]);
            _isResolvedArray[i] = _isResolvedMarket(_playerPropsMarkets[i]);
            _hasAnyMintsArray[i] = _hasAnyMints;
            _isMaturedArray[i] = _maturity <= block.timestamp;
            _maturities[i] = _maturity;
        }
    }

    function _hasAnyMintsAndMaturityDatesForMarket(address _parent)
        internal
        view
        returns (bool _hasAnyMints, uint _maturity)
    {
        ISportPositionalMarket marketContract = ISportPositionalMarket(_parent);
        (uint maturity, ) = marketContract.times();
        _hasAnyMints = marketContract.optionsInitialized() || _hasAnyMintsForChildren(_parent);
        _maturity = maturity;
    }

    function _hasAnyMintsAndMaturityDatesForPP(address _market) internal view returns (bool _hasAnyMints, uint _maturity) {
        ISportPositionalMarket marketContract = ISportPositionalMarket(_market);
        (uint maturity, ) = marketContract.times();
        _hasAnyMints = marketContract.optionsInitialized();
        _maturity = maturity;
    }

    function _isResolvedMarket(address _market) internal view returns (bool _flag) {
        return ISportPositionalMarket(_market).resolved();
    }

    function _getDoubleChanceMarkets(address market) internal view returns (address[] memory markets) {
        uint length = doubleChanceMarketsByParent[market].length;
        if (length > 0) {
            markets = new address[](length);
            for (uint i = 0; i < length; i++) {
                markets[i] = doubleChanceMarketsByParent[market][i];
            }
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Setters ---------- */

    function setExpiryDuration(uint _expiryDuration) public onlyOwner {
        expiryDuration = _expiryDuration;
        emit ExpiryDurationUpdated(_expiryDuration);
    }

    function setsUSD(address _address) external onlyOwner {
        sUSD = IERC20(_address);
        emit SetsUSD(_address);
    }

    /* ---------- Deposit Management ---------- */

    function incrementTotalDeposited(uint delta) external onlyActiveMarkets notPaused {
        totalDeposited = totalDeposited.add(delta);
    }

    function decrementTotalDeposited(uint delta) external onlyKnownMarkets notPaused {
        // NOTE: As individual market debt is not tracked here, the underlying markets
        //       need to be careful never to subtract more debt than they added.
        //       This can't be enforced without additional state/communication overhead.
        totalDeposited = totalDeposited.sub(delta);
    }

    /* ---------- Market Lifecycle ---------- */

    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint maturity,
        uint initialMint, // initial sUSD to mint options for,
        uint positionCount,
        uint[] memory tags,
        bool isChild,
        address parentMarket
    )
        external
        override
        notPaused
        returns (
            ISportPositionalMarket // no support for returning PositionalMarket polymorphically given the interface
        )
    {
        require(marketCreationEnabled, "Market creation is disabled");
        require(
            msg.sender == theRundownConsumer || msg.sender == oddsObtainer || msg.sender == playerProps,
            "Invalid creator"
        );

        uint expiry = maturity.add(expiryDuration);

        require(block.timestamp < maturity, "Maturity has to be in the future");
        // We also require maturity < expiry. But there is no need to check this.
        // The market itself validates the capital and skew requirements.

        ISportPositionalMarket market = _createMarket(
            SportPositionalMarketFactory.SportPositionCreationMarketParameters(
                msg.sender,
                gameId,
                gameLabel,
                [maturity, expiry],
                positionCount,
                tags,
                isChild,
                parentMarket,
                false
            )
        );

        if (positionCount > 2 && isDoubleChanceSupported) {
            _createDoubleChanceMarkets(msg.sender, gameId, maturity, expiry, address(market), tags[0]);
        }

        return market;
    }

    function createDoubleChanceMarketsForParent(address market) external notPaused onlyOwner {
        require(marketCreationEnabled, "Market creation is disabled");
        require(isDoubleChanceSupported, "Double chance not supported");
        ISportPositionalMarket marketContract = ISportPositionalMarket(market);

        require(marketContract.optionsCount() > 2, "Not supported for 2 options market");

        (uint maturity, uint expiry) = marketContract.times();
        _createDoubleChanceMarkets(
            marketContract.creator(),
            marketContract.getGameId(),
            maturity,
            expiry,
            market,
            marketContract.tags(0)
        );
    }

    function _createMarket(SportPositionalMarketFactory.SportPositionCreationMarketParameters memory parameters)
        internal
        returns (ISportPositionalMarket)
    {
        SportPositionalMarket market = SportPositionalMarketFactory(sportPositionalMarketFactory).createMarket(parameters);

        _activeMarkets.add(address(market));

        (IPosition up, IPosition down, IPosition draw) = market.getOptions();

        emit MarketCreated(
            address(market),
            parameters.creator,
            parameters.gameId,
            parameters.times[0],
            parameters.times[1],
            address(up),
            address(down),
            address(draw)
        );
        emit MarketLabel(address(market), parameters.gameLabel);
        return market;
    }

    function _createDoubleChanceMarkets(
        address creator,
        bytes32 gameId,
        uint maturity,
        uint expiry,
        address market,
        uint tag
    ) internal onlySupportedGameId(gameId) {
        string[3] memory labels = ["HomeTeamNotToLose", "AwayTeamNotToLose", "NoDraw"];
        uint[] memory tagsDoubleChance = new uint[](2);
        tagsDoubleChance[0] = tag;
        tagsDoubleChance[1] = 10003;
        for (uint i = 0; i < 3; i++) {
            ISportPositionalMarket doubleChanceMarket = _createMarket(
                SportPositionalMarketFactory.SportPositionCreationMarketParameters(
                    creator,
                    gameId,
                    labels[i],
                    [maturity, expiry],
                    2,
                    tagsDoubleChance,
                    false,
                    address(market),
                    true
                )
            );
            _activeMarkets.add(address(doubleChanceMarket));

            doubleChanceMarketsByParent[address(market)].push(address(doubleChanceMarket));
            isDoubleChance[address(doubleChanceMarket)] = true;

            IGamesOddsObtainer(oddsObtainer).setChildMarketGameId(gameId, address(doubleChanceMarket));

            emit DoubleChanceMarketCreated(address(market), address(doubleChanceMarket), tagsDoubleChance[1], labels[i]);
        }
    }

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external override {
        //only to be called by markets themselves
        require(isKnownMarket(address(msg.sender)), "Market unknown.");
        amount = _transformCollateral(amount);
        amount = needsTransformingCollateral ? amount + 1 : amount;
        bool success = sUSD.transferFrom(sender, receiver, amount);
        if (!success) {
            revert("TransferFrom function failed");
        }
    }

    function resolveMarket(address market, uint _outcome) external override {
        require(
            msg.sender == theRundownConsumer ||
                msg.sender == owner ||
                msg.sender == oddsObtainer ||
                msg.sender == playerProps ||
                whitelistedCancelAddresses[msg.sender],
            "Invalid resolver"
        );
        require(_activeMarkets.contains(market), "Not an active market");
        require(!isDoubleChance[market], "Not supported for double chance markets");
        // unpause if paused
        if (ISportPositionalMarket(market).paused()) {
            ISportPositionalMarket(market).setPaused(false);
        }
        SportPositionalMarket(market).resolve(_outcome);
        _activeMarkets.remove(market);
        _maturedMarkets.add(market);

        if (doubleChanceMarketsByParent[market].length > 0) {
            if (_outcome == 1) {
                // HomeTeamNotLose, NoDraw
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(2);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(1);
            } else if (_outcome == 2) {
                // AwayTeamNotLose, NoDraw
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(2);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(1);
            } else if (_outcome == 3) {
                // HomeTeamNotLose, AwayTeamNotLose
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(1);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(2);
            } else {
                // cancelled
                SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(0);
                SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(0);
                SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(0);
            }
            for (uint i = 0; i < doubleChanceMarketsByParent[market].length; i++) {
                _activeMarkets.remove(doubleChanceMarketsByParent[market][i]);
                _maturedMarkets.add(doubleChanceMarketsByParent[market][i]);
            }
        }
    }

    function resolveMarketWithResult(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        address _consumer,
        bool _useBackupOdds
    ) external {
        require(msg.sender == owner || whitelistedCancelAddresses[msg.sender], "Invalid resolver");
        require(!isDoubleChance[_market], "Not supported for double chance markets");

        if (_outcome != 0) {
            require(!_useBackupOdds, "Only use backup odds on cancelation, if needed!");
        }

        if (_consumer == theRundownConsumer) {
            ITherundownConsumer(theRundownConsumer).resolveMarketManually(
                _market,
                _outcome,
                _homeScore,
                _awayScore,
                _useBackupOdds
            );
        }
    }

    function cancelMarketsForParents(address[] memory _parents) external {
        for (uint i = 0; i < _parents.length; i++) {
            require(!isDoubleChance[_parents[i]], "Not supported for double chance markets");
            (bool _hasAnyMints, uint _maturity) = _hasAnyMintsAndMaturityDatesForMarket(_parents[i]);
            if (!_hasAnyMints && _maturity <= block.timestamp && !_isResolvedMarket(_parents[i])) {
                ITherundownConsumer(theRundownConsumer).resolveMarketManually(_parents[i], 0, 0, 0, false);
            }
        }
    }

    function cancelMarketsForPlayerProps(address[] memory _playerPropsMarkets) external {
        for (uint i = 0; i < _playerPropsMarkets.length; i++) {
            require(!isDoubleChance[_playerPropsMarkets[i]], "Not supported for double chance markets");
            (bool _hasAnyMints, uint _maturity) = _hasAnyMintsAndMaturityDatesForPP(_playerPropsMarkets[i]);
            if (!_hasAnyMints && _maturity <= block.timestamp && !_isResolvedMarket(_playerPropsMarkets[i])) {
                IGamesPlayerProps(playerProps).cancelMarketFromManager(_playerPropsMarkets[i]);
            }
        }
    }

    function overrideResolveWithCancel(address market, uint _outcome) external {
        require(msg.sender == owner || whitelistedCancelAddresses[msg.sender], "Invalid resolver");
        require(_outcome == 0, "Can only set 0 outcome");
        require(SportPositionalMarket(market).resolved(), "Market not resolved");
        require(!_activeMarkets.contains(market), "Active market");
        require(!isDoubleChance[market], "Not supported for double chance markets");
        // unpause if paused
        if (ISportPositionalMarket(market).paused()) {
            ISportPositionalMarket(market).setPaused(false);
        }
        SportPositionalMarket(market).resolve(_outcome);

        if (doubleChanceMarketsByParent[market].length > 0) {
            SportPositionalMarket(doubleChanceMarketsByParent[market][0]).resolve(0);
            SportPositionalMarket(doubleChanceMarketsByParent[market][1]).resolve(0);
            SportPositionalMarket(doubleChanceMarketsByParent[market][2]).resolve(0);
        }
    }

    function expireMarkets(address[] calldata markets) external override notPaused onlyOwner {
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];

            require(isKnownMarket(address(market)), "Market unknown.");

            // The market itself handles decrementing the total deposits.
            SportPositionalMarket(market).expire(payable(msg.sender));

            // Note that we required that the market is known, which guarantees
            // its index is defined and that the list of markets is not empty.
            _maturedMarkets.remove(market);

            emit MarketExpired(market);
        }
    }

    function restoreInvalidOddsForMarket(
        address _market,
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external onlyOwner {
        require(isKnownMarket(address(_market)), "Market unknown.");
        require(SportPositionalMarket(_market).cancelled(), "Market not cancelled.");
        SportPositionalMarket(_market).restoreInvalidOdds(_homeOdds, _awayOdds, _drawOdds);
        emit OddsForMarketRestored(_market, _homeOdds, _awayOdds, _drawOdds);
    }

    function setMarketCreationEnabled(bool enabled) external onlyOwner {
        if (enabled != marketCreationEnabled) {
            marketCreationEnabled = enabled;
            emit MarketCreationEnabledUpdated(enabled);
        }
    }

    function setCancelTimeout(uint _cancelTimeout) external onlyOwner {
        cancelTimeout = _cancelTimeout;
    }

    function setIsDoubleChanceSupported(bool _isDoubleChanceSupported) external onlyOwner {
        isDoubleChanceSupported = _isDoubleChanceSupported;
        emit DoubleChanceSupportChanged(_isDoubleChanceSupported);
    }

    function setSupportedSportForDoubleChance(uint[] memory _sportIds, bool _isSupported) external onlyOwner {
        for (uint256 index = 0; index < _sportIds.length; index++) {
            // only if current flag is different, if same skip it
            if (doesSportSupportDoubleChance[_sportIds[index]] != _isSupported) {
                doesSportSupportDoubleChance[_sportIds[index]] = _isSupported;
                emit SupportedSportForDoubleChanceAdded(_sportIds[index], _isSupported);
            }
        }
    }

    // support USDC with 6 decimals
    function transformCollateral(uint value) external view override returns (uint) {
        return _transformCollateral(value);
    }

    function _transformCollateral(uint value) internal view returns (uint) {
        if (needsTransformingCollateral) {
            return value / 1e12;
        } else {
            return value;
        }
    }

    function _updateDatesForMarket(
        address _market,
        uint256 _newStartTime,
        uint256 _expiry
    ) internal {
        ISportPositionalMarket(_market).updateDates(_newStartTime, _expiry);

        emit DatesUpdatedForMarket(_market, _newStartTime, _expiry);
    }

    function _hasAnyMintsForChildren(address _market) internal view returns (bool) {
        return _hasAnyMints(_market, true) || _hasAnyMints(_market, false) || _hasAnyMintsDoubleChance(_market);
    }

    function _hasAnyMints(address _market, bool checkPlayerProps) internal view returns (bool) {
        uint numberOfChildMarkets;
        address childMarketContract;

        if (checkPlayerProps) {
            numberOfChildMarkets = IGameChildMarket(playerProps).numberOfChildMarkets(_market);
            childMarketContract = playerProps;
        } else {
            numberOfChildMarkets = IGameChildMarket(oddsObtainer).numberOfChildMarkets(_market);
            childMarketContract = oddsObtainer;
        }

        for (uint i = 0; i < numberOfChildMarkets; i++) {
            address child = IGameChildMarket(childMarketContract).mainMarketChildMarketIndex(_market, i);
            if (ISportPositionalMarket(child).optionsInitialized()) {
                return true;
            }
        }

        return false;
    }

    function _hasAnyMintsDoubleChance(address _market) internal view returns (bool) {
        address[] memory childMarkets = _getDoubleChanceMarkets(_market);

        for (uint i = 0; i < childMarkets.length; i++) {
            if (childMarkets[i] != address(0) && ISportPositionalMarket(childMarkets[i]).optionsInitialized()) {
                return true;
            }
        }

        return false;
    }

    function reverseTransformCollateral(uint value) external view override returns (uint) {
        if (needsTransformingCollateral) {
            return value * 1e12;
        } else {
            return value;
        }
    }

    function isWhitelistedAddress(address _address) external view override returns (bool) {
        return whitelistedAddresses[_address];
    }

    /* ========== MODIFIERS ========== */

    modifier onlyActiveMarkets() {
        require(_activeMarkets.contains(msg.sender), "Permitted only for active markets.");
        _;
    }

    modifier onlyKnownMarkets() {
        require(isKnownMarket(msg.sender), "Permitted only for known markets.");
        _;
    }

    modifier onlySupportedGameId(bytes32 gameId) {
        uint sportId = ITherundownConsumer(theRundownConsumer).sportsIdPerGame(gameId);
        if (doesSportSupportDoubleChance[sportId] && isDoubleChanceSupported) {
            _;
        }
    }

    /* ========== EVENTS ========== */

    event MarketCreated(
        address market,
        address indexed creator,
        bytes32 indexed gameId,
        uint maturityDate,
        uint expiryDate,
        address up,
        address down,
        address draw
    );
    event MarketLabel(address market, string gameLabel);
    event MarketExpired(address market);
    event MarketCreationEnabledUpdated(bool enabled);
    event MarketsMigrated(SportPositionalMarketManager receivingManager, SportPositionalMarket[] markets);
    event MarketsReceived(SportPositionalMarketManager migratingManager, SportPositionalMarket[] markets);
    event SetMigratingManager(address migratingManager);
    event ExpiryDurationUpdated(uint duration);
    event MaxTimeToMaturityUpdated(uint duration);
    event CreatorCapitalRequirementUpdated(uint value);
    event SetSportPositionalMarketFactory(address _sportPositionalMarketFactory);
    event SetsUSD(address _address);
    event SetTherundownConsumer(address theRundownConsumer);
    event SetObtainerAddress(address _obratiner);
    event SetPlayerPropsAddress(address _playerProps);
    event OddsForMarketRestored(address _market, uint _homeOdds, uint _awayOdds, uint _drawOdds);
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event DatesUpdatedForMarket(address _market, uint256 _newStartTime, uint256 _expiry);
    event DoubleChanceMarketCreated(address _parentMarket, address _doubleChanceMarket, uint tag, string label);
    event DoubleChanceSupportChanged(bool _isDoubleChanceSupported);
    event SupportedSportForDoubleChanceAdded(uint _sportId, bool _isSupported);
}

pragma solidity ^0.8.0;

// Inheritance
import "../../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

// Internal references
import "./SportPosition.sol";
import "./SportPositionalMarket.sol";
import "./SportPositionalMarketFactory.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SportPositionalMarketFactory is Initializable, ProxyOwned {
    /* ========== STATE VARIABLES ========== */
    address public positionalMarketManager;

    address public positionalMarketMastercopy;
    address public positionMastercopy;

    address public sportsAMM;

    struct SportPositionCreationMarketParameters {
        address creator;
        bytes32 gameId;
        string gameLabel;
        uint[2] times; // [maturity, expiry]
        uint positionCount;
        uint[] tags;
        bool isChild;
        address parentMarket;
        bool isDoubleChance;
    }

    /* ========== INITIALIZER ========== */

    function initialize(address _owner) external initializer {
        setOwner(_owner);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(SportPositionCreationMarketParameters calldata _parameters)
        external
        returns (SportPositionalMarket)
    {
        require(positionalMarketManager == msg.sender, "Only permitted by the manager.");

        SportPositionalMarket pom = SportPositionalMarket(Clones.clone(positionalMarketMastercopy));
        address[] memory positions = new address[](_parameters.positionCount);

        pom.initialize(
            SportPositionalMarket.SportPositionalMarketParameters(
                positionalMarketManager,
                _parameters.creator,
                _parameters.gameId,
                _parameters.gameLabel,
                _parameters.times,
                _parameters.positionCount,
                positions,
                _parameters.tags,
                _parameters.isChild,
                _parameters.parentMarket,
                _parameters.isDoubleChance,
                address(this)
            )
        );
        emit MarketCreated(
            address(pom),
            _parameters.gameId,
            _parameters.gameLabel,
            _parameters.times[0],
            _parameters.times[1],
            0,
            _parameters.positionCount,
            _parameters.tags,
            _parameters.isChild,
            _parameters.parentMarket
        );
        return pom;
    }

    /* ========== SETTERS ========== */
    function setSportPositionalMarketManager(address _positionalMarketManager) external onlyOwner {
        positionalMarketManager = _positionalMarketManager;
        emit SportPositionalMarketManagerChanged(_positionalMarketManager);
    }

    function setSportPositionalMarketMastercopy(address _positionalMarketMastercopy) external onlyOwner {
        positionalMarketMastercopy = _positionalMarketMastercopy;
        emit SportPositionalMarketMastercopyChanged(_positionalMarketMastercopy);
    }

    function setSportPositionMastercopy(address _positionMastercopy) external onlyOwner {
        positionMastercopy = _positionMastercopy;
        emit SportPositionMastercopyChanged(_positionMastercopy);
    }

    function setSportsAMM(address _sportsAMM) external onlyOwner {
        sportsAMM = _sportsAMM;
        emit SetSportsAMM(_sportsAMM);
    }

    event SportPositionalMarketManagerChanged(address _positionalMarketManager);
    event SportPositionalMarketMastercopyChanged(address _positionalMarketMastercopy);
    event SportPositionMastercopyChanged(address _positionMastercopy);
    event SetSportsAMM(address _sportsAMM);
    event SetLimitOrderProvider(address _limitOrderProvider);
    event MarketCreated(
        address market,
        bytes32 indexed gameId,
        string gameLabel,
        uint maturityDate,
        uint expiryDate,
        uint initialMint,
        uint positionCount,
        uint[] tags,
        bool isChild,
        address parent
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGamesOddsObtainer {
    struct GameOdds {
        bytes32 gameId;
        int24 homeOdds;
        int24 awayOdds;
        int24 drawOdds;
        int16 spreadHome;
        int24 spreadHomeOdds;
        int16 spreadAway;
        int24 spreadAwayOdds;
        uint24 totalOver;
        int24 totalOverOdds;
        uint24 totalUnder;
        int24 totalUnderOdds;
    }

    // view

    function getActiveChildMarketsFromParent(address _parent) external view returns (address, address);

    function getSpreadTotalsChildMarketsFromParent(address _parent)
        external
        view
        returns (
            uint numOfSpreadMarkets,
            address[] memory spreadMarkets,
            uint numOfTotalsMarkets,
            address[] memory totalMarkets
        );

    function areOddsValid(
        bytes32 _gameId,
        bool _useBackup,
        bool _isTwoPositional
    ) external view returns (bool);

    function invalidOdds(address _market) external view returns (bool);

    function playersReportTimestamp(address _market) external view returns (uint);

    function getNormalizedOdds(bytes32 _gameId) external view returns (uint[] memory);

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function getOddsForGames(bytes32[] memory _gameIds) external view returns (int24[] memory odds);

    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);

    function mainMarketSpreadChildMarket(address _main, int16 _spread) external view returns (address);

    function mainMarketTotalChildMarket(address _main, uint24 _total) external view returns (address);

    function childMarketMainMarket(address _market) external view returns (address);

    function childMarketTotal(address _market) external view returns (uint24);

    function currentActiveTotalChildMarket(address _main) external view returns (address);

    function currentActiveSpreadChildMarket(address _main) external view returns (address);

    function isSpreadChildMarket(address _child) external view returns (bool);

    function childMarketCreated(address _child) external view returns (bool);

    function getOddsForGame(bytes32 _gameId)
        external
        view
        returns (
            int24,
            int24,
            int24,
            int24,
            int24,
            int24,
            int24
        );

    function getLinesForGame(bytes32 _gameId)
        external
        view
        returns (
            int16,
            int16,
            uint24,
            uint24
        );

    // executable

    function obtainOdds(
        bytes32 requestId,
        GameOdds memory _game,
        uint _sportId,
        address _main,
        bool _isTwoPositional,
        bool _isPlayersReport
    ) external;

    function setFirstOdds(
        bytes32 _gameId,
        int24 _homeOdds,
        int24 _awayOdds,
        int24 _drawOdds
    ) external;

    function setFirstNormalizedOdds(
        bytes32 _gameId,
        address _market,
        bool _isTwoPositional
    ) external;

    function setBackupOddsAsMainOddsForGame(bytes32 _gameId) external;

    function pauseUnpauseChildMarkets(address _main, bool _flag) external;

    function pauseUnpauseCurrentActiveChildMarket(
        bytes32 _gameId,
        address _main,
        bool _flag
    ) external;

    function resolveChildMarkets(
        address _market,
        uint _outcome,
        uint8 _homeScore,
        uint8 _awayScore
    ) external;

    function setChildMarketGameId(bytes32 gameId, address market) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGamesPlayerProps {
    struct PlayerProps {
        bytes32 gameId;
        bytes32 playerId;
        uint8 option;
        string playerName;
        uint16 line;
        int24 overOdds;
        int24 underOdds;
    }

    struct PlayerPropsResolver {
        bytes32 gameId;
        bytes32 playerId;
        uint8 option;
        uint16 score;
        uint8 statusId;
    }

    function obtainPlayerProps(PlayerProps memory _player, uint _sportId) external;

    function cancelMartketsForPlayerInAGame(bytes32 gameId, bytes32 playerId) external;

    function resolvePlayerProps(PlayerPropsResolver memory _result) external;

    function cancelMarketFromManager(address _market) external;

    function pauseAllPlayerPropsMarketForMain(
        address _main,
        bool _flag,
        bool _invalidOddsOnMain,
        bool _circuitBreakerMain
    ) external;

    function createFulfilledForPlayerProps(
        bytes32 gameId,
        bytes32 playerId,
        uint8 option
    ) external view returns (bool);

    function cancelPlayerPropsMarketForMain(address _main) external;

    function getNormalizedOddsForMarket(address _market) external view returns (uint[] memory);

    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);

    function doesSportSupportPlayerProps(uint _sportId) external view returns (bool);

    function pausedByInvalidOddsOnMain(address _main) external view returns (bool);

    function pausedByCircuitBreakerOnMain(address _main) external view returns (bool);

    function playerIdPerChildMarket(address _market) external view returns (bytes32);

    function optionIdPerChildMarket(address _market) external view returns (uint8);

    function getAllOptionsWithPlayersForGameId(bytes32 _gameId)
        external
        view
        returns (
            bytes32[] memory _playerIds,
            uint8[] memory _options,
            bool[] memory _isResolved,
            address[][] memory _childMarketsPerOption
        );

    function getPlayerPropsDataForMarket(address _market)
        external
        view
        returns (
            address,
            bytes32,
            bytes32,
            uint8
        );

    function getPlayerPropForOption(
        bytes32 gameId,
        bytes32 playerId,
        uint8 option
    )
        external
        view
        returns (
            uint16,
            int24,
            int24,
            bool
        );

    function fulfillPlayerPropsCLResolved(bytes[] memory _playerProps) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGameChildMarket {
    function mainMarketChildMarketIndex(address _main, uint _index) external view returns (address);

    function numberOfChildMarkets(address _main) external view returns (uint);
}