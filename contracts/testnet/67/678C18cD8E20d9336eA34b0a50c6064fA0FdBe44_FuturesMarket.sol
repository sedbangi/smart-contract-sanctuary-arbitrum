// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;
    mapping(bytes32 => address) public availableBridge;
    mapping(address => bool) public isBridge;

    bytes32[] public bridgeList;

    constructor(address _owner) Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    function addAvailableBridge(bytes32 bridgeName, address bridgeAddress) external onlyOwner {
        _addAvailableBridge(bridgeName, bridgeAddress);
    }

    function removeAvailableBridge(bytes32 bridgeName) external onlyOwner {
        _removeAvailableBridge(bridgeName);
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    function _addAvailableBridge(bytes32 bridgeName, address bridgeAddress) private {
        if (availableBridge[bridgeName] != address(0)) {
            _removeAvailableBridge(bridgeName);
        }
        availableBridge[bridgeName] = bridgeAddress;
        isBridge[bridgeAddress] = true;
        bridgeList.push(bridgeName);
        emit AddBridge(bridgeName, bridgeAddress);
    }

    function _removeAvailableBridge(bytes32 bridgeName) private {
        require(availableBridge[bridgeName] != address(0), "The bridge no exist.");
        uint lastBridgeNumber = bridgeList.length - 1;
        for (uint ii = 0; ii <= lastBridgeNumber; ii++) {
            if (bridgeList[ii] == bridgeName) {
                bridgeList[ii] = bridgeList[lastBridgeNumber];
                bridgeList.pop();
                break;
            }
        }
        address bridgeToRemove = availableBridge[bridgeName];
        delete availableBridge[bridgeName];
        delete isBridge[bridgeToRemove];
        emit RemoveBridge(bridgeName, bridgeToRemove);
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    function getAvailableBridge(bytes32 bridgeName) external view returns (address) {
        return availableBridge[bridgeName];
    }

    function getBridgeList() external view returns (bytes32[] memory) {
        return bridgeList;
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
    event AddBridge(bytes32 indexed bridgeName, address bridgeAddress);
    event RemoveBridge(bytes32 indexed bridgeName, address bridgeAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./FuturesMarketBase.sol";
import "./MixinFuturesNextPriceOrders.sol";
import "./interfaces/IFuturesMarket.sol";

/*
 * Synthetic Futures
 * =================
 *
 * Futures markets allow users leveraged exposure to an asset, long or short.
 * A user must post some margin in order to open a futures account, and profits/losses are
 * continually tallied against this margin. If a user's margin runs out, then their position is closed
 * by a liquidation keeper, which is rewarded with a flat fee extracted from the margin.
 *
 * The Synth debt pool is effectively the counterparty to each trade, so if a particular position
 * is in profit, then the debt pool pays by issuing sUSD into their margin account,
 * while if the position makes a loss then the debt pool burns sUSD from the margin, reducing the
 * debt load in the system.
 *
 * As the debt pool underwrites all positions, the debt-inflation risk to the system is proportional to the
 * long-short skew in the market. It is therefore in the interest of the system to reduce the skew.
 * To encourage the minimisation of the skew, each position is charged a funding rate, which increases with
 * the size of the skew. The funding rate is charged continuously, and positions on the heavier side of the
 * market are charged the current funding rate times the notional value of their position, while positions
 * on the lighter side are paid at the same rate to keep their positions open.
 * As the funding rate is the same (but negated) on both sides of the market, there is an excess quantity of
 * funding being charged, which is collected by the debt pool, and serves to reduce the system debt.
 *
 * The contract architecture is as follows:
 *
 *     - FuturesMarket.sol:         one of these exists per asset. Margin is maintained isolated per market.
 *                                  this contract is composed of several mixins: `base` contains all the core logic,
 *                                  `nextPrice` contains the next-price order flows, and `views` contains logic
 *                                  that is only used by external / manager contracts.
 *
 *     - FuturesMarketManager.sol:  the manager keeps track of which markets exist, and is the main window between
 *                                  futures markets and the rest of the system. It accumulates the total debt
 *                                  over all markets, and issues and burns sUSD on each market's behalf.
 *
 *     - FuturesMarketSettings.sol: Holds the settings for each market in the global FlexibleStorage instance used
 *                                  by SystemSettings, and provides an interface to modify these values. Other than
 *                                  the base asset, these settings determine the behaviour of each market.
 *                                  See that contract for descriptions of the meanings of each setting.
 *
 * Technical note: internal functions within the FuturesMarket contract assume the following:
 *
 *     - prices passed into them are valid;
 *
 *     - funding has already been recomputed up to the current time (hence unrecorded funding is nil);
 *
 *     - the account being managed was not liquidated in the same transaction;
 */

contract FuturesMarket is MixinFuturesNextPriceOrders {
    constructor(
        address _resolver,
        bytes32 _baseAsset,
        bytes32 _marketKey
    ) MixinFuturesNextPriceOrders(_resolver, _baseAsset, _marketKey) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./MixinFuturesMarketSettings.sol";
import "./interfaces/IFuturesMarketBaseTypes.sol";

// Libraries
// import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./externals/openzeppelin/SafeMath.sol";
import "./SafeCast.sol";
import "./SignedSafeMath.sol";
import "./SignedSafeDecimalMath.sol";
import "./SafeDecimalMath.sol";

// Internal references
import "./interfaces/IExchangeCircuitBreaker.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/ISynthrBridge.sol";
import "./interfaces/IERC20.sol";

/*
 * Synthetic Futures
 * =================
 *
 * Futures markets allow users leveraged exposure to an asset, long or short.
 * A user must post some margin in order to open a futures account, and profits/losses are
 * continually tallied against this margin. If a user's margin runs out, then their position is closed
 * by a liquidation keeper, which is rewarded with a flat fee extracted from the margin.
 *
 * The Synth debt pool is effectively the counterparty to each trade, so if a particular position
 * is in profit, then the debt pool pays by issuing sUSD into their margin account,
 * while if the position makes a loss then the debt pool burns sUSD from the margin, reducing the
 * debt load in the system.
 *
 * As the debt pool underwrites all positions, the debt-inflation risk to the system is proportional to the
 * long-short skew in the market. It is therefore in the interest of the system to reduce the skew.
 * To encourage the minimisation of the skew, each position is charged a funding rate, which increases with
 * the size of the skew. The funding rate is charged continuously, and positions on the heavier side of the
 * market are charged the current funding rate times the notional value of their position, while positions
 * on the lighter side are paid at the same rate to keep their positions open.
 * As the funding rate is the same (but negated) on both sides of the market, there is an excess quantity of
 * funding being charged, which is collected by the debt pool, and serves to reduce the system debt.
 *
 * To combat front-running, the system does not confirm a user's order until the next price is received from
 * the oracle. Therefore opening a position is a three stage procedure: depositing margin, submitting an order,
 * and waiting for that order to be confirmed. The last transaction is performed by a keeper,
 * once a price update is detected.
 *
 * The contract architecture is as follows:
 *
 *     - FuturesMarket.sol:         one of these exists per asset. Margin is maintained isolated per market.
 *
 *     - FuturesMarketManager.sol:  the manager keeps track of which markets exist, and is the main window between
 *                                  futures markets and the rest of the system. It accumulates the total debt
 *                                  over all markets, and issues and burns sUSD on each market's behalf.
 *
 *     - FuturesMarketSettings.sol: Holds the settings for each market in the global FlexibleStorage instance used
 *                                  by SystemSettings, and provides an interface to modify these values. Other than
 *                                  the base asset, these settings determine the behaviour of each market.
 *                                  See that contract for descriptions of the meanings of each setting.
 *
 * Each futures market and the manager operates behind a proxy, and for efficiency they communicate with one another
 * using their underlying implementations.
 *
 * Technical note: internal functions within the FuturesMarket contract assume the following:
 *
 *     - prices passed into them are valid;
 *
 *     - funding has already been recomputed up to the current time (hence unrecorded funding is nil);
 *
 *     - the account being managed was not liquidated in the same transaction;
 */
interface IFuturesMarketManagerInternal {
    function issueSUSD(address account, uint256 amount) external;

    function burnSUSD(address account, uint256 amount) external returns (uint256 postReclamationAmount);

    function payFee(uint256 amount) external;

    function sendIncreaseSynth(bytes32 bridgeKey, bytes32 synthKey, uint256 synthAmount) external;
}

contract FuturesMarketBase is MixinFuturesMarketSettings, IFuturesMarketBaseTypes {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;
    using SignedSafeDecimalMath for int256;
    using SafeDecimalMath for uint256;

    /* ========== CONSTANTS ========== */

    // This is the same unit as used inside `SignedSafeDecimalMath`.
    int256 private constant _UNIT = int256(10 ** uint256(18));

    //slither-disable-next-line naming-convention
    bytes32 internal constant sUSD = "sUSD";

    uint16 internal constant PT_WITHDRAW_MARGIN_SYNTH = 10;

    /* ========== STATE VARIABLES ========== */

    // The market identifier in the futures system (manager + settings). Multiple markets can co-exist
    // for the same asset in order to allow migrations.
    bytes32 public marketKey;

    // The asset being traded in this market. This should be a valid key into the ExchangeRates contract.
    bytes32 public baseAsset;

    // The total number of base units in long and short positions.
    uint128 public marketSize;

    /*
     * The net position in base units of the whole market.
     * When this is positive, longs outweigh shorts. When it is negative, shorts outweigh longs.
     */
    int128 public marketSkew;

    /*
     * The funding sequence allows constant-time calculation of the funding owed to a given position.
     * Each entry in the sequence holds the net funding accumulated per base unit since the market was created.
     * Then to obtain the net funding over a particular interval, subtract the start point's sequence entry
     * from the end point's sequence entry.
     * Positions contain the funding sequence entry at the time they were confirmed; so to compute
     * the net funding on a given position, obtain from this sequence the net funding per base unit
     * since the position was confirmed and multiply it by the position size.
     */
    uint32 public fundingLastRecomputed;
    int128[] public fundingSequence;

    /*
     * Each user's position. Multiple positions can always be merged, so each user has
     * only have one position at a time.
     */
    mapping(address => Position) public positions;

    /*
     * This holds the value: sum_{p in positions}{p.margin - p.size * (p.lastPrice + fundingSequence[p.lastFundingIndex])}
     * Then marketSkew * (price + _nextFundingEntry()) + _entryDebtCorrection yields the total system debt,
     * which is equivalent to the sum of remaining margins in all positions.
     */
    int128 internal _entryDebtCorrection;

    // This increments for each position; zero reflects a position that does not exist.
    uint64 internal _nextPositionId = 1;

    // Holds the revert message for each type of error.
    mapping(uint8 => string) internal _errorMessages;

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 internal constant CONTRACT_CIRCUIT_BREAKER = "ExchangeCircuitBreaker";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 internal constant CONTRACT_FUTURESMARKETMANAGER = "FuturesMarketManager";
    bytes32 internal constant CONTRACT_FUTURESMARKETSETTINGS = "FuturesMarketSettings";
    bytes32 internal constant CONTRACT_SYSTEMSTATUS = "SystemStatus";

    // convenience struct for passing params between position modification helper functions
    struct TradeParams {
        int256 sizeDelta;
        uint256 price;
        uint256 takerFee;
        uint256 makerFee;
        bytes32 trackingCode; // optional tracking code for volume source fee sharing
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _resolver, bytes32 _baseAsset, bytes32 _marketKey) MixinFuturesMarketSettings(_resolver) {
        baseAsset = _baseAsset;
        marketKey = _marketKey;

        // Initialise the funding sequence with 0 initially accrued, so that the first usable funding index is 1.
        fundingSequence.push(0);

        // Set up the mapping between error codes and their revert messages.
        _errorMessages[uint8(Status.InvalidPrice)] = "Invalid price";
        _errorMessages[uint8(Status.PriceOutOfBounds)] = "Price out of acceptable range";
        _errorMessages[uint8(Status.CanLiquidate)] = "Position can be liquidated";
        _errorMessages[uint8(Status.CannotLiquidate)] = "Position cannot be liquidated";
        _errorMessages[uint8(Status.MaxMarketSizeExceeded)] = "Max market size exceeded";
        _errorMessages[uint8(Status.MaxLeverageExceeded)] = "Max leverage exceeded";
        _errorMessages[uint8(Status.InsufficientMargin)] = "Insufficient margin";
        _errorMessages[uint8(Status.NotPermitted)] = "Not permitted by this address";
        _errorMessages[uint8(Status.NilOrder)] = "Cannot submit empty order";
        _errorMessages[uint8(Status.NoPositionOpen)] = "No position open";
        _errorMessages[uint8(Status.PriceTooVolatile)] = "Price too volatile";
    }

    /* ========== VIEWS ========== */

    /* ---------- External Contracts ---------- */

    function resolverAddressesRequired() public view override returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinFuturesMarketSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](5);
        newAddresses[0] = CONTRACT_EXCHANGER;
        newAddresses[1] = CONTRACT_CIRCUIT_BREAKER;
        newAddresses[2] = CONTRACT_FUTURESMARKETMANAGER;
        newAddresses[3] = CONTRACT_FUTURESMARKETSETTINGS;
        newAddresses[4] = CONTRACT_SYSTEMSTATUS;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function _exchangeCircuitBreaker() internal view returns (IExchangeCircuitBreaker) {
        return IExchangeCircuitBreaker(requireAndGetAddress(CONTRACT_CIRCUIT_BREAKER));
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function _systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function _synthrBridge(bytes32 bridgeName) internal view returns (ISynthrBridge) {
        return ISynthrBridge(resolver.getAvailableBridge(bridgeName));
    }

    function _manager() internal view returns (IFuturesMarketManagerInternal) {
        return IFuturesMarketManagerInternal(requireAndGetAddress(CONTRACT_FUTURESMARKETMANAGER));
    }

    function _settings() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_FUTURESMARKETSETTINGS);
    }

    /* ---------- Market Details ---------- */

    /*
     * The size of the skew relative to the size of the market skew scaler.
     * This value can be outside of [-1, 1] values.
     * Scaler used for skew is at skewScaleUSD to prevent extreme funding rates for small markets.
     */
    function _proportionalSkew(uint256 price) internal view returns (int256) {
        // marketSize is in baseAsset units so we need to convert from USD units
        require(price > 0, "price can't be zero");
        uint256 skewScaleBaseAsset = _skewScaleUSD(marketKey).divideDecimal(price);
        require(skewScaleBaseAsset != 0, "skewScale is zero"); // don't divide by zero
        return int256(marketSkew).divideDecimal(int256(skewScaleBaseAsset));
    }

    function _currentFundingRate(uint256 price) internal view returns (int256) {
        int256 maxFundingRate = int256(_maxFundingRate(marketKey));
        // Note the minus sign: funding flows in the opposite direction to the skew.
        return _min(_max(-_UNIT, -_proportionalSkew(price)), _UNIT).multiplyDecimal(maxFundingRate);
    }

    function _unrecordedFunding(uint256 price) internal view returns (int256 funding) {
        int256 elapsed = int256(block.timestamp.sub(fundingLastRecomputed));
        // The current funding rate, rescaled to a percentage per second.
        int256 currentFundingRatePerSecond = _currentFundingRate(price) / 1 days;
        return currentFundingRatePerSecond.multiplyDecimal(int256(price)).mul(elapsed);
    }

    /*
     * The new entry in the funding sequence, appended when funding is recomputed. It is the sum of the
     * last entry and the unrecorded funding, so the sequence accumulates running total over the market's lifetime.
     */
    function _nextFundingEntry(uint256 price) internal view returns (int256 funding) {
        return int256(fundingSequence[_latestFundingIndex()]).add(_unrecordedFunding(price));
    }

    function _netFundingPerUnit(uint256 startIndex, uint256 price) internal view returns (int256) {
        // Compute the net difference between start and end indices.
        return _nextFundingEntry(price).sub(fundingSequence[startIndex]);
    }

    function getSendWithdrawMargin(
        address _account,
        uint256 _marginDelta,
        bytes32 _bridgeName,
        uint16 _destChainId
    ) external view returns (uint256) {
        bytes memory lzPayload = abi.encode(PT_WITHDRAW_MARGIN_SYNTH, abi.encodePacked(_account), _marginDelta);
        return _synthrBridge(_bridgeName).calcFee(lzPayload, PT_WITHDRAW_MARGIN_SYNTH, _destChainId);
    }

    /* ---------- Position Details ---------- */

    /*
     * Determines whether a change in a position's size would violate the max market value constraint.
     */
    function _orderSizeTooLarge(uint256 maxSize, int256 oldSize, int256 newSize) internal view returns (bool) {
        // Allow users to reduce an order no matter the market conditions.
        if (_sameSide(oldSize, newSize) && _abs(newSize) <= _abs(oldSize)) {
            return false;
        }

        // Either the user is flipping sides, or they are increasing an order on the same side they're already on;
        // we check that the side of the market their order is on would not break the limit.
        int256 newSkew = int256(marketSkew).sub(oldSize).add(newSize);
        int256 newMarketSize = int256(int128(marketSize)).sub(_signedAbs(oldSize)).add(_signedAbs(newSize));

        int256 newSideSize;
        if (0 < newSize) {
            // long case: marketSize + skew
            //            = (|longSize| + |shortSize|) + (longSize + shortSize)
            //            = 2 * longSize
            newSideSize = newMarketSize.add(newSkew);
        } else {
            // short case: marketSize - skew
            //            = (|longSize| + |shortSize|) - (longSize + shortSize)
            //            = 2 * -shortSize
            newSideSize = newMarketSize.sub(newSkew);
        }

        // newSideSize still includes an extra factor of 2 here, so we will divide by 2 in the actual condition
        if (maxSize < _abs(newSideSize.div(2))) {
            return true;
        }

        return false;
    }

    function _notionalValue(int256 positionSize, uint256 price) internal pure returns (int256 value) {
        return positionSize.multiplyDecimal(int256(price));
    }

    function _profitLoss(Position memory position, uint256 price) internal pure returns (int256 pnl) {
        int256 priceShift = int256(price).sub(int256(int128(position.lastPrice)));
        return int256(position.size).multiplyDecimal(priceShift);
    }

    function _accruedFunding(Position memory position, uint256 price) internal view returns (int256 funding) {
        uint256 lastModifiedIndex = position.lastFundingIndex;
        if (lastModifiedIndex == 0) {
            return 0; // The position does not exist -- no funding.
        }
        int256 net = _netFundingPerUnit(lastModifiedIndex, price);
        return int256(position.size).multiplyDecimal(net);
    }

    /*
     * The initial margin of a position, plus any PnL and funding it has accrued. The resulting value may be negative.
     */
    function _marginPlusProfitFunding(Position memory position, uint256 price) internal view returns (int256) {
        int256 funding = _accruedFunding(position, price);
        return int256(int128(position.margin)).add(_profitLoss(position, price)).add(funding);
    }

    /*
     * The value in a position's margin after a deposit or withdrawal, accounting for funding and profit.
     * If the resulting margin would be negative or below the liquidation threshold, an appropriate error is returned.
     * If the result is not an error, callers of this function that use it to update a position's margin
     * must ensure that this is accompanied by a corresponding debt correction update, as per `_applyDebtCorrection`.
     */
    function _recomputeMarginWithDelta(
        Position memory position,
        uint256 price,
        int256 marginDelta
    ) internal view returns (uint256 margin, Status statusCode) {
        int256 newMargin = _marginPlusProfitFunding(position, price).add(marginDelta);
        if (newMargin < 0) {
            return (0, Status.InsufficientMargin);
        }

        uint256 uMargin = uint256(newMargin);
        int256 positionSize = int256(position.size);
        // minimum margin beyond which position can be liquidated
        uint256 lMargin = _liquidationMargin(positionSize, price);
        if (positionSize != 0 && uMargin <= lMargin) {
            return (uMargin, Status.CanLiquidate);
        }

        return (uMargin, Status.Ok);
    }

    function _remainingMargin(Position memory position, uint256 price) internal view returns (uint256) {
        int256 remaining = _marginPlusProfitFunding(position, price);

        // If the margin went past zero, the position should have been liquidated - return zero remaining margin.
        return uint256(_max(0, remaining));
    }

    function _accessibleMargin(Position memory position, uint256 price) internal view returns (uint256) {
        // Ugly solution to rounding safety: leave up to an extra tenth of a cent in the account/leverage
        // This should guarantee that the value returned here can always been withdrawn, but there may be
        // a little extra actually-accessible value left over, depending on the position size and margin.
        uint256 milli = uint256(_UNIT / 1000);
        int256 maxLeverage = int256(_maxLeverage(marketKey).sub(milli));
        uint256 inaccessible = _abs(_notionalValue(position.size, price).divideDecimal(maxLeverage));

        // If the user has a position open, we'll enforce a min initial margin requirement.
        if (0 < inaccessible) {
            uint256 minInitialMargin = _minInitialMargin();
            if (inaccessible < minInitialMargin) {
                inaccessible = minInitialMargin;
            }
            inaccessible = inaccessible.add(milli);
        }

        uint256 remaining = _remainingMargin(position, price);
        if (remaining <= inaccessible) {
            return 0;
        }

        return remaining.sub(inaccessible);
    }

    /**
     * The fee charged from the margin during liquidation. Fee is proportional to position size
     * but is at least the _minKeeperFee() of sUSD to prevent underincentivising
     * liquidations of small positions.
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lFee liquidation fee to be paid to liquidator in sUSD fixed point decimal units
     */
    function _liquidationFee(int256 positionSize, uint256 price) internal view returns (uint256 lFee) {
        // size * price * fee-ratio
        uint256 proportionalFee = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationFeeRatio());
        uint256 minFee = _minKeeperFee();
        // max(proportionalFee, minFee) - to prevent not incentivising liquidations enough
        return proportionalFee > minFee ? proportionalFee : minFee; // not using _max() helper because it's for signed ints
    }

    /**
     * The minimal margin at which liquidation can happen. Is the sum of liquidationBuffer and liquidationFee
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lMargin liquidation margin to maintain in sUSD fixed point decimal units
     * @dev The liquidation margin contains a buffer that is proportional to the position
     * size. The buffer should prevent liquidation happenning at negative margin (due to next price being worse)
     * so that stakers would not leak value to liquidators through minting rewards that are not from the
     * account's margin.
     */
    function _liquidationMargin(int256 positionSize, uint256 price) internal view returns (uint256 lMargin) {
        uint256 liquidationBuffer = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationBufferRatio());
        return liquidationBuffer.add(_liquidationFee(positionSize, price));
    }

    function _canLiquidate(Position memory position, uint256 price) internal view returns (bool) {
        // No liquidating empty positions.
        if (position.size == 0) {
            return false;
        }

        return _remainingMargin(position, price) <= _liquidationMargin(int256(position.size), price);
    }

    function _currentLeverage(
        Position memory position,
        uint256 price,
        uint256 remainingMargin_
    ) internal pure returns (int256 leverage) {
        // No position is open, or it is ready to be liquidated; leverage goes to nil
        if (remainingMargin_ == 0) {
            return 0;
        }

        return _notionalValue(position.size, price).divideDecimal(int256(remainingMargin_));
    }

    function _orderFee(TradeParams memory params, uint256 dynamicFeeRate) internal view returns (uint256 fee) {
        // usd value of the difference in position
        int256 notionalDiff = params.sizeDelta.multiplyDecimal(int256(params.price));

        // If the order is submitted on the same side as the skew (increasing it) - the taker fee is charged.
        // Otherwise if the order is opposite to the skew, the maker fee is charged.
        // the case where the order flips the skew is ignored for simplicity due to being negligible
        // in both size of effect and frequency of occurrence
        uint256 staticRate = _sameSide(notionalDiff, marketSkew) ? params.takerFee : params.makerFee;
        uint256 feeRate = staticRate.add(dynamicFeeRate);
        return _abs(notionalDiff.multiplyDecimal(int256(feeRate)));
    }

    /// Uses the exchanger to get the dynamic fee (SIP-184) for trading from sUSD to baseAsset
    /// this assumes dynamic fee is symmetric in direction of trade.
    /// @dev this is a pretty expensive action in terms of execution gas as it queries a lot
    ///   of past rates from oracle. Shoudn't be much of an issue on a rollup though.
    function _dynamicFeeRate() internal view returns (uint256 feeRate, bool tooVolatile) {
        return _exchanger().dynamicFeeRateForExchange(sUSD, baseAsset);
    }

    function _latestFundingIndex() internal view returns (uint256) {
        return fundingSequence.length.sub(1); // at least one element is pushed in constructor
    }

    function _postTradeDetails(
        Position memory oldPos,
        TradeParams memory params
    ) internal view returns (Position memory newPosition, uint256 fee, Status tradeStatus) {
        // Reverts if the user is trying to submit a size-zero order.
        if (params.sizeDelta == 0) {
            return (oldPos, 0, Status.NilOrder);
        }

        // The order is not submitted if the user's existing position needs to be liquidated.
        if (_canLiquidate(oldPos, params.price)) {
            return (oldPos, 0, Status.CanLiquidate);
        }

        // get the dynamic fee rate SIP-184
        (uint256 dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        if (tooVolatile) {
            return (oldPos, 0, Status.PriceTooVolatile);
        }

        // calculate the total fee for exchange
        fee = _orderFee(params, dynamicFeeRate);

        // Deduct the fee.
        // It is an error if the realised margin minus the fee is negative or subject to liquidation.
        (uint256 newMargin, Status status) = _recomputeMarginWithDelta(oldPos, params.price, -int256(fee));
        if (_isError(status)) {
            return (oldPos, 0, status);
        }

        // construct new position
        Position memory newPos = Position({
            id: oldPos.id,
            lastFundingIndex: uint64(_latestFundingIndex()),
            margin: uint128(newMargin),
            lastPrice: uint128(params.price),
            size: int128(int256(oldPos.size).add(params.sizeDelta))
        });

        // always allow to decrease a position, otherwise a margin of minInitialMargin can never
        // decrease a position as the price goes against them.
        // we also add the paid out fee for the minInitialMargin because otherwise minInitialMargin
        // is never the actual minMargin, because the first trade will always deduct
        // a fee (so the margin that otherwise would need to be transferred would have to include the future
        // fee as well, making the UX and definition of min-margin confusing).
        bool positionDecreasing = _sameSide(oldPos.size, newPos.size) && _abs(newPos.size) < _abs(oldPos.size);
        if (!positionDecreasing) {
            // minMargin + fee <= margin is equivalent to minMargin <= margin - fee
            // except that we get a nicer error message if fee > margin, rather than arithmetic overflow.
            if (uint256(newPos.margin).add(fee) < _minInitialMargin()) {
                return (oldPos, 0, Status.InsufficientMargin);
            }
        }

        // check that new position margin is above liquidation margin
        // (above, in _recomputeMarginWithDelta() we checked the old position, here we check the new one)
        // Liquidation margin is considered without a fee, because it wouldn't make sense to allow
        // a trade that will make the position liquidatable.
        if (newMargin <= _liquidationMargin(newPos.size, params.price)) {
            return (newPos, 0, Status.CanLiquidate);
        }

        // Check that the maximum leverage is not exceeded when considering new margin including the paid fee.
        // The paid fee is considered for the benefit of UX of allowed max leverage, otherwise, the actual
        // max leverage is always below the max leverage parameter since the fee paid for a trade reduces the margin.
        // We'll allow a little extra headroom for rounding errors.
        {
            // stack too deep
            int256 leverage = int256(newPos.size).multiplyDecimal(int256(params.price)).divideDecimal(int256(newMargin.add(fee)));
            if (_maxLeverage(marketKey).add(uint256(_UNIT) / 100) < _abs(leverage)) {
                return (oldPos, 0, Status.MaxLeverageExceeded);
            }
        }

        // Check that the order isn't too large for the market.
        // Allow a bit of extra value in case of rounding errors.
        if (
            _orderSizeTooLarge(
                uint256(int256(_maxMarketValueUSD(marketKey).add(100 * uint256(_UNIT))).divideDecimal(int256(params.price))),
                oldPos.size,
                newPos.size
            )
        ) {
            return (oldPos, 0, Status.MaxMarketSizeExceeded);
        }

        return (newPos, fee, Status.Ok);
    }

    /* ---------- Utilities ---------- */

    /*
     * Absolute value of the input, returned as a signed number.
     */
    function _signedAbs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function _abs(int256 x) internal pure returns (uint256) {
        return uint256(_signedAbs(x));
    }

    function _max(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? y : x;
    }

    function _min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }

    // True if and only if two positions a and b are on the same side of the market;
    // that is, if they have the same sign, or either of them is zero.
    function _sameSide(int256 a, int256 b) internal pure returns (bool) {
        return (a >= 0) == (b >= 0);
    }

    /*
     * True if and only if the given status indicates an error.
     */
    function _isError(Status status) internal pure returns (bool) {
        return status != Status.Ok;
    }

    /*
     * Revert with an appropriate message if the first argument is true.
     */
    function _revertIfError(bool isError, Status status) internal view {
        if (isError) {
            revert(_errorMessages[uint8(status)]);
        }
    }

    /*
     * Revert with an appropriate message if the input is an error.
     */
    function _revertIfError(Status status) internal view {
        if (_isError(status)) {
            revert(_errorMessages[uint8(status)]);
        }
    }

    /*
     * The current base price from the oracle, and whether that price was invalid. Zero prices count as invalid.
     * Public because used both externally and internally
     */
    function assetPrice() public view returns (uint256 price, bool invalid) {
        (price, invalid) = _exchangeCircuitBreaker().rateWithInvalid(baseAsset);
        // Ensure we catch uninitialised rates or suspended state / synth
        invalid = invalid || price == 0 || _systemStatus().synthSuspended(baseAsset);
        return (price, invalid);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Market Operations ---------- */

    /*
     * The current base price, reverting if it is invalid, or if system or synth is suspended.
     * This is mutative because the circuit breaker stores the last price on every invocation.
     */
    function _assetPriceRequireSystemChecks() internal returns (uint256) {
        // check that futures market isn't suspended, revert with appropriate message
        _systemStatus().requireFuturesMarketActive(marketKey); // asset and market may be different
        // check that synth is active, and wasn't suspended, revert with appropriate message
        _systemStatus().requireSynthActive(baseAsset);
        // check if circuit breaker if price is within deviation tolerance and system & synth is active
        // note: rateWithBreakCircuit (mutative) is used here instead of rateWithInvalid (view). This is
        //  despite reverting immediately after if circuit is broken, which may seem silly.
        //  This is in order to persist last-rate in exchangeCircuitBreaker in the happy case
        //  because last-rate is what used for measuring the deviation for subsequent trades.
        (uint256 price, bool circuitBroken) = _exchangeCircuitBreaker().rateWithBreakCircuit(baseAsset);
        // revert if price is invalid or circuit was broken
        // note: we revert here, which means that circuit is not really broken (is not persisted), this is
        //  because the futures methods and interface are designed for reverts, and do not support no-op
        //  return values.
        _revertIfError(circuitBroken, Status.InvalidPrice);
        return price;
    }

    function _recomputeFunding(uint256 price) internal returns (uint256 lastIndex) {
        uint256 sequenceLengthBefore = fundingSequence.length;

        int256 funding = _nextFundingEntry(price);
        fundingSequence.push(int128(funding));
        fundingLastRecomputed = uint32(block.timestamp);
        emit FundingRecomputed(funding, sequenceLengthBefore, fundingLastRecomputed);

        return sequenceLengthBefore;
    }

    /**
     * Pushes a new entry to the funding sequence at the current price and funding rate.
     * @dev Admin only method accessible to FuturesMarketSettings. This is admin only because:
     * - When system parameters change, funding should be recomputed, but system may be paused
     *   during that time for any reason, so this method needs to work even if system is paused.
     *   But in that case, it shouldn't be accessible to external accounts.
     */
    function recomputeFunding() external returns (uint256 lastIndex) {
        // only FuturesMarketSettings is allowed to use this method
        _revertIfError(msg.sender != _settings(), Status.NotPermitted);
        // This method is the only mutative method that uses the view _assetPrice()
        // and not the mutative _assetPriceRequireSystemChecks() that reverts on system flags.
        // This is because this method is used by system settings when changing funding related
        // parameters, so needs to function even when system / market is paused. E.g. to facilitate
        // market migration.
        (uint256 price, bool invalid) = assetPrice();
        // A check for a valid price is still in place, to ensure that a system settings action
        // doesn't take place when the price is invalid (e.g. some oracle issue).
        require(!invalid, "Invalid price");
        return _recomputeFunding(price);
    }

    /*
     * The impact of a given position on the debt correction.
     */
    function _positionDebtCorrection(Position memory position) internal view returns (int256) {
        /**
        This method only returns the correction term for the debt calculation of the position, and not it's 
        debt. This is needed for keeping track of the _marketDebt() in an efficient manner to allow O(1) marketDebt
        calculation in _marketDebt().

        The overall market debt is the sum of the remaining margin in all positions. The intuition is that
        the debt of a single position is the value withdrawn upon closing that position.

        single position remaining margin = initial-margin + profit-loss + accrued-funding =
            = initial-margin + q * (price - last-price) + q * funding-accrued-per-unit
            = initial-margin + q * price - q * last-price + q * (funding - initial-funding)

        Total debt = sum ( position remaining margins )
            = sum ( initial-margin + q * price - q * last-price + q * (funding - initial-funding) )
            = sum( q * price ) + sum( q * funding ) + sum( initial-margin - q * last-price - q * initial-funding )
            = skew * price + skew * funding + sum( initial-margin - q * ( last-price + initial-funding ) )
            = skew (price + funding) + sum( initial-margin - q * ( last-price + initial-funding ) )

        The last term: sum( initial-margin - q * ( last-price + initial-funding ) ) being the position debt correction
            that is tracked with each position change using this method. 
        
        The first term and the full debt calculation using current skew, price, and funding is calculated globally in _marketDebt().
         */
        return
            int256(int128(position.margin)).sub(
                int256(position.size).multiplyDecimal(
                    int256(int128(position.lastPrice)).add(fundingSequence[position.lastFundingIndex])
                )
            );
    }

    function _marketDebt(uint256 price) internal view returns (uint256) {
        // short circuit and also convenient during setup
        if (marketSkew == 0 && _entryDebtCorrection == 0) {
            // if these are 0, the resulting calculation is necessarily zero as well
            return 0;
        }
        // see comment explaining this calculation in _positionDebtCorrection()
        int256 priceWithFunding = int256(price).add(_nextFundingEntry(price));
        int256 totalDebt = int256(marketSkew).multiplyDecimal(priceWithFunding).add(_entryDebtCorrection);
        return uint256(_max(totalDebt, 0));
    }

    /*
     * Alter the debt correction to account for the net result of altering a position.
     */
    function _applyDebtCorrection(Position memory newPosition, Position memory oldPosition) internal {
        int256 newCorrection = _positionDebtCorrection(newPosition);
        int256 oldCorrection = _positionDebtCorrection(oldPosition);
        _entryDebtCorrection = int128(int256(_entryDebtCorrection).add(newCorrection).sub(oldCorrection));
    }

    function _transferMargin(
        int256 marginDelta,
        uint256 price,
        address sender,
        uint16 destChainId,
        bool isReceived
    ) internal returns (uint256) {
        // Transfer no tokens if marginDelta is 0
        uint256 absDelta = _abs(marginDelta);
        Position storage position = positions[sender];
        if (marginDelta > 0) {
            // A positive margin delta corresponds to a deposit, which will be burnt from their
            // sUSD balance and credited to their margin account.
            if (destChainId == 0 && !isReceived) {
                // Ensure we handle reclamation when burning tokens.
                uint256 postReclamationAmount = _manager().burnSUSD(sender, absDelta);
                if (postReclamationAmount != absDelta) {
                    // If balance was insufficient, the actual delta will be smaller
                    marginDelta = int256(postReclamationAmount);
                }
            }
            _updatePositionMargin(position, price, marginDelta);
        } else if (marginDelta < 0) {
            // A negative margin delta corresponds to a withdrawal, which will be minted into
            // their sUSD balance, and debited from their margin account.
            _updatePositionMargin(position, price, marginDelta);

            if (destChainId == 0) {
                _manager().issueSUSD(sender, absDelta);
            }
        } else {
            // Zero delta is a no-op
            return 0;
        }

        emit MarginTransferred(sender, marginDelta, destChainId, isReceived);

        emit PositionModified(position.id, sender, position.margin, position.size, 0, price, _latestFundingIndex(), 0);
        return _abs(marginDelta);
    }

    // updates the stored position margin in place (on the stored position)
    function _updatePositionMargin(Position storage position, uint256 price, int256 marginDelta) internal {
        Position memory oldPosition = position;
        // Determine new margin, ensuring that the result is positive.
        (uint256 margin, Status status) = _recomputeMarginWithDelta(oldPosition, price, marginDelta);
        _revertIfError(status);

        // Update the debt correction.
        int256 positionSize = position.size;
        uint256 fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), uint128(margin), uint128(price), int128(positionSize)),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, int128(positionSize))
        );

        // Update the account's position with the realised margin.
        position.margin = uint128(margin);
        // We only need to update their funding/PnL details if they actually have a position open
        if (positionSize != 0) {
            position.lastPrice = uint128(price);
            position.lastFundingIndex = uint64(fundingIndex);

            // The user can always decrease their margin if they have no position, or as long as:
            //     * they have sufficient margin to do so
            //     * the resulting margin would not be lower than the liquidation margin or min initial margin
            //     * the resulting leverage is lower than the maximum leverage
            if (marginDelta < 0) {
                _revertIfError(
                    (margin < _minInitialMargin()) ||
                        (margin <= _liquidationMargin(position.size, price)) ||
                        (_maxLeverage(marketKey) < _abs(_currentLeverage(position, price, margin))),
                    Status.InsufficientMargin
                );
            }
        }
    }

    /*
     * Alter the amount of margin in a position. A positive input triggers a deposit; a negative one, a
     * withdrawal. The margin will be burnt or issued directly into/out of the caller's sUSD wallet.
     * Reverts on deposit if the caller lacks a sufficient sUSD balance.
     * Reverts on withdrawal if the amount to be withdrawn would expose an open position to liquidation.
     */
    function transferMargin(int256 marginDelta, bytes32 bridgeName, uint16 destChainId, bool erc20Payment) external payable {
        if (marginDelta > 0) {
            require(destChainId == 0, "Not allowed cross chain transfer margin");
        }
        uint256 price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        uint256 absValue = _transferMargin(marginDelta, price, msg.sender, destChainId, false);
        if (marginDelta < 0) {
            _synthrBridge(bridgeName).sendWithdrawMargin{value: msg.value}(msg.sender, absValue, destChainId, erc20Payment);
        } else {
            _synthrBridge(bridgeName).sendTransferMargin(msg.sender, absValue);
        }
    }

    function destTransferMargin(address account, uint256 marginDelta) external onlyAllowedCaller returns (uint) {
        uint256 price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        uint marginResult = _transferMargin(marginDelta.toInt256(), price, account, 0, true);
        return marginResult;
    }

    /*
     * Withdraws all accessible margin in a position. This will leave some remaining margin
     * in the account if the caller has a position open. Equivalent to `transferMargin(-accessibleMargin(sender))`.
     */
    function withdrawAllMargin(bytes32 bridgeName, uint16 destChainId, bool erc20Payment) external payable {
        address sender = msg.sender;
        uint256 price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        int256 marginDelta = -int256(_accessibleMargin(positions[sender], price));
        _transferMargin(marginDelta, price, sender, destChainId, false);
        _synthrBridge(bridgeName).sendWithdrawMargin{value: msg.value}(msg.sender, _abs(marginDelta), destChainId, erc20Payment);
    }

    function _trade(address sender, TradeParams memory params) internal returns (uint256) {
        Position storage position = positions[sender];
        Position memory oldPosition = position;

        // Compute the new position after performing the trade
        (Position memory newPosition, uint256 fee, Status status) = _postTradeDetails(oldPosition, params);
        _revertIfError(status);

        // Update the aggregated market size and skew with the new order size
        marketSkew = int128(int256(marketSkew).add(newPosition.size).sub(oldPosition.size));
        marketSize = uint128(uint256(marketSize).add(_abs(newPosition.size)).sub(_abs(oldPosition.size)));

        // Send the fee to the fee pool
        if (0 < fee) {
            _manager().payFee(fee);
            // emit tracking code event
            if (params.trackingCode != bytes32(0)) {
                emit FuturesTracking(params.trackingCode, baseAsset, marketKey, params.sizeDelta, fee);
            }
        }

        // Update the margin, and apply the resulting debt correction
        position.margin = newPosition.margin;
        _applyDebtCorrection(newPosition, oldPosition);

        // Record the trade
        uint64 id = oldPosition.id;
        uint256 fundingIndex = _latestFundingIndex();
        if (newPosition.size == 0) {
            // If the position is being closed, we no longer need to track these details.
            delete position.id;
            delete position.size;
            delete position.lastPrice;
            delete position.lastFundingIndex;
        } else {
            if (oldPosition.size == 0) {
                // New positions get new ids.
                id = _nextPositionId;
                _nextPositionId += 1;
            }
            position.id = id;
            position.size = newPosition.size;
            position.lastPrice = uint128(params.price);
            position.lastFundingIndex = uint64(fundingIndex);
        }
        // emit the modification event
        emit PositionModified(
            id,
            sender,
            newPosition.margin,
            newPosition.size,
            params.sizeDelta,
            params.price,
            fundingIndex,
            fee
        );
        return fee;
    }

    /*
     * Adjust the sender's position size.
     * Reverts if the resulting position is too large, outside the max leverage, or is liquidating.
     */
    function modifyPosition(int256 sizeDelta, bytes32 bridgeKey) external {
        _modifyPosition(sizeDelta, bytes32(0), bridgeKey);
    }

    /*
     * Same as modifyPosition, but emits an event with the passed tracking code to
     * allow offchain calculations for fee sharing with originating integrations
     */
    function modifyPositionWithTracking(int256 sizeDelta, bytes32 trackingCode, bytes32 bridgeKey) external {
        _modifyPosition(sizeDelta, trackingCode, bridgeKey);
    }

    function _modifyPosition(int256 sizeDelta, bytes32 trackingCode, bytes32 bridgeKey) internal {
        uint256 price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        uint256 fee = _trade(
            msg.sender,
            TradeParams({
                sizeDelta: sizeDelta,
                price: price,
                takerFee: _takerFee(marketKey),
                makerFee: _makerFee(marketKey),
                trackingCode: trackingCode
            })
        );
        if (fee > 0) {
            _manager().sendIncreaseSynth(bridgeKey, sUSD, fee);
        }
    }

    /*
     * Submit an order to close a position.
     */
    function closePosition(bytes32 bridgeKey) external {
        _closePosition(bytes32(0), bridgeKey);
    }

    /// Same as closePosition, but emits an even with the trackingCode for volume source fee sharing
    function closePositionWithTracking(bytes32 trackingCode, bytes32 bridgeKey) external {
        _closePosition(trackingCode, bridgeKey);
    }

    function _closePosition(bytes32 trackingCode, bytes32 bridgeKey) internal {
        int256 size = positions[msg.sender].size;
        _revertIfError(size == 0, Status.NoPositionOpen);
        uint256 price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);
        uint256 fee = _trade(
            msg.sender,
            TradeParams({
                sizeDelta: -size,
                price: price,
                takerFee: _takerFee(marketKey),
                makerFee: _makerFee(marketKey),
                trackingCode: trackingCode
            })
        );
        if (fee > 0) {
            _manager().sendIncreaseSynth(bridgeKey, sUSD, fee);
        }
    }

    function _liquidatePosition(address account, address liquidator, uint256 price, bytes32 bridgeKey) internal {
        Position storage position = positions[account];

        // get remaining margin for sending any leftover buffer to fee pool
        uint256 remMargin = _remainingMargin(position, price);

        // Record updates to market size and debt.
        int256 positionSize = position.size;
        uint256 positionId = position.id;
        marketSkew = int128(int256(marketSkew).sub(positionSize));
        marketSize = uint128(uint256(marketSize).sub(_abs(positionSize)));

        uint256 fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), 0, uint128(price), 0),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, int128(positionSize))
        );

        // Close the position itself.
        delete positions[account];

        uint256 syUSDToIncrease;
        // Issue the reward to the liquidator.
        uint256 liqFee = _liquidationFee(positionSize, price);
        _manager().issueSUSD(liquidator, liqFee);
        syUSDToIncrease += liqFee;

        emit PositionModified(positionId, account, 0, 0, 0, price, fundingIndex, 0);
        emit PositionLiquidated(positionId, account, liquidator, positionSize, price, liqFee);

        // Send any positive margin buffer to the fee pool
        if (remMargin > liqFee) {
            _manager().payFee(remMargin.sub(liqFee));
            syUSDToIncrease += liqFee;
        }

        if (syUSDToIncrease > 0) {
            _manager().sendIncreaseSynth(bridgeKey, sUSD, syUSDToIncrease);
        }
    }

    /*
     * Liquidate a position if its remaining margin is below the liquidation fee. This succeeds if and only if
     * `canLiquidate(account)` is true, and reverts otherwise.
     * Upon liquidation, the position will be closed, and the liquidation fee minted into the liquidator's account.
     */
    function liquidatePosition(address account, bytes32 bridgeKey) external {
        uint256 price = _assetPriceRequireSystemChecks();
        _recomputeFunding(price);

        _revertIfError(!_canLiquidate(positions[account], price), Status.CannotLiquidate);

        _liquidatePosition(account, msg.sender, price, bridgeKey);
    }

    /* ========== MODIFIER ======== */
    modifier onlyAllowedCaller() {
        require(
            resolver.isBridge(msg.sender) || getAddressFromResolver("WrappedSynthr") == msg.sender,
            "Only the caller allowed can perform this action"
        );
        _;
    }

    function getAddressFromResolver(bytes32 name) private view returns (address) {
        return resolver.getAddress(name);
    }

    /* ========== EVENTS ========== */

    event MarginTransferred(address indexed account, int256 marginDelta, uint16 destChainId, bool isReceived);

    event PositionModified(
        uint256 indexed id,
        address indexed account,
        uint256 margin,
        int256 size,
        int256 tradeSize,
        uint256 lastPrice,
        uint256 fundingIndex,
        uint256 fee
    );

    event PositionLiquidated(
        uint256 indexed id,
        address indexed account,
        address indexed liquidator,
        int256 size,
        uint256 price,
        uint256 fee
    );

    event FundingRecomputed(int256 funding, uint256 index, uint256 timestamp);

    event FuturesTracking(bytes32 indexed trackingCode, bytes32 baseAsset, bytes32 marketKey, int256 sizeDelta, uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MixinResolver.sol";

// Internal references
import "./interfaces/IFlexibleStorage.sol";

contract MixinFuturesMarketSettings is MixinResolver {
    /* ========== CONSTANTS ========== */

    bytes32 internal constant SETTING_CONTRACT_NAME = "FuturesMarketSettings";

    /* ---------- Parameter Names ---------- */

    // Per-market settings
    bytes32 internal constant PARAMETER_TAKER_FEE = "takerFee";
    bytes32 internal constant PARAMETER_MAKER_FEE = "makerFee";
    bytes32 internal constant PARAMETER_TAKER_FEE_NEXT_PRICE = "takerFeeNextPrice";
    bytes32 internal constant PARAMETER_MAKER_FEE_NEXT_PRICE = "makerFeeNextPrice";
    bytes32 internal constant PARAMETER_NEXT_PRICE_CONFIRM_WINDOW = "nextPriceConfirmWindow";
    bytes32 internal constant PARAMETER_MAX_LEVERAGE = "maxLeverage";
    bytes32 internal constant PARAMETER_MAX_MARKET_VALUE = "maxMarketValueUSD";
    bytes32 internal constant PARAMETER_MAX_FUNDING_RATE = "maxFundingRate";
    bytes32 internal constant PARAMETER_MIN_SKEW_SCALE = "skewScaleUSD";

    // Global settings
    // minimum liquidation fee payable to liquidator
    bytes32 internal constant SETTING_MIN_KEEPER_FEE = "futuresMinKeeperFee";
    // liquidation fee basis points payed to liquidator
    bytes32 internal constant SETTING_LIQUIDATION_FEE_RATIO = "futuresLiquidationFeeRatio";
    // liquidation buffer to prevent negative margin upon liquidation
    bytes32 internal constant SETTING_LIQUIDATION_BUFFER_RATIO = "futuresLiquidationBufferRatio";
    bytes32 internal constant SETTING_MIN_INITIAL_MARGIN = "futuresMinInitialMargin";

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _resolver) MixinResolver(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view virtual override returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function _flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    /* ---------- Internals ---------- */

    function _parameter(bytes32 _marketKey, bytes32 key) internal view returns (uint256 value) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, keccak256(abi.encodePacked(_marketKey, key)));
    }

    function _takerFee(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE);
    }

    function _makerFee(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE);
    }

    function _takerFeeNextPrice(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE_NEXT_PRICE);
    }

    function _makerFeeNextPrice(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE_NEXT_PRICE);
    }

    function _nextPriceConfirmWindow(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW);
    }

    function _maxLeverage(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_LEVERAGE);
    }

    function _maxMarketValueUSD(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_MARKET_VALUE);
    }

    function _skewScaleUSD(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MIN_SKEW_SCALE);
    }

    function _maxFundingRate(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_FUNDING_RATE);
    }

    function _minKeeperFee() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE);
    }

    function _liquidationFeeRatio() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FEE_RATIO);
    }

    function _liquidationBufferRatio() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_BUFFER_RATIO);
    }

    function _minInitialMargin() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_INITIAL_MARGIN);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
// import "./FuturesMarketBase.sol";
import "./MixinFuturesViews.sol";

/**
 Mixin that implements NextPrice orders mechanism for the futures market.
 The purpose of the mechanism is to allow reduced fees for trades that commit to next price instead
 of current price. Specifically, this should serve funding rate arbitrageurs, such that funding rate
 arb is profitable for smaller skews. This in turn serves the protocol by reducing the skew, and so
 the risk to the debt pool, and funding rate for traders. 
 The fees can be reduced when comitting to next price, because front-running (MEV and oracle delay)
 is less of a risk when committing to next price.
 The relative complexity of the mechanism is due to having to enforce the "commitment" to the trade
 without either introducing free (or cheap) optionality to cause cancellations, and without large
 sacrifices to the UX / risk of the traders (e.g. blocking all actions, or penalizing failures too much).
 */
contract MixinFuturesNextPriceOrders is MixinFuturesViews {
    /// @dev Holds a mapping of accounts to orders. Only one order per account is supported
    mapping(address => NextPriceOrder) public nextPriceOrders;

    constructor(address _resolver, bytes32 _baseAsset, bytes32 _marketKey) MixinFuturesViews(_resolver, _baseAsset, _marketKey) {}

    ///// Mutative methods

    /**
     * @notice submits an order to be filled at a price of the next oracle update.
     * Reverts if a previous order still exists (wasn't executed or cancelled).
     * Reverts if the order cannot be filled at current price to prevent witholding commitFee for
     * incorrectly submitted orders (that cannot be filled).
     * @param sizeDelta size in baseAsset (notional terms) of the order, similar to `modifyPosition` interface
     */
    function submitNextPriceOrder(int256 sizeDelta) external {
        _submitNextPriceOrder(sizeDelta, bytes32(0));
    }

    /// same as submitNextPriceOrder but emits an event with the tracking code
    /// to allow volume source fee sharing for integrations
    function submitNextPriceOrderWithTracking(int256 sizeDelta, bytes32 trackingCode) external {
        _submitNextPriceOrder(sizeDelta, trackingCode);
    }

    function _submitNextPriceOrder(int256 sizeDelta, bytes32 trackingCode) internal {
        // check that a previous order doesn't exist
        require(nextPriceOrders[msg.sender].sizeDelta == 0, "previous order exists");

        // storage position as it's going to be modified to deduct commitFee and keeperFee
        Position storage position = positions[msg.sender];

        // to prevent submitting bad orders in good faith and being charged commitDeposit for them
        // simulate the order with current price and market and check that the order doesn't revert
        uint256 price = _assetPriceRequireSystemChecks();
        uint256 fundingIndex = _recomputeFunding(price);
        TradeParams memory params = TradeParams({
            sizeDelta: sizeDelta,
            price: price,
            takerFee: _takerFeeNextPrice(marketKey),
            makerFee: _makerFeeNextPrice(marketKey),
            trackingCode: trackingCode
        });
        (, , Status status) = _postTradeDetails(position, params);
        _revertIfError(status);

        // deduct fees from margin
        uint256 commitDeposit = _nextPriceCommitDeposit(params);
        uint256 keeperDeposit = _minKeeperFee();
        _updatePositionMargin(position, price, -int256(commitDeposit + keeperDeposit));
        // emit event for modifying the position (subtracting the fees from margin)
        emit PositionModified(position.id, msg.sender, position.margin, position.size, 0, price, fundingIndex, 0);

        // create order
        uint256 targetRoundId = _exchangeRates().getCurrentRoundId(baseAsset) + 1; // next round
        NextPriceOrder memory order = NextPriceOrder({
            sizeDelta: int128(sizeDelta),
            targetRoundId: uint128(targetRoundId),
            commitDeposit: uint128(commitDeposit),
            keeperDeposit: uint128(keeperDeposit),
            trackingCode: trackingCode
        });
        // emit event
        emit NextPriceOrderSubmitted(
            msg.sender,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
        // store order
        nextPriceOrders[msg.sender] = order;
    }

    /**
     * @notice Cancels an existing order for an account.
     * Anyone can call this method for any account, but only the account owner
     *  can cancel their own order during the period when it can still potentially be executed (before it becomes stale).
     *  Only after the order becomes stale, can anyone else (e.g. a keeper) cancel the order for the keeperFee.
     * Cancelling the order:
     * - Removes the stored order.
     * - commitFee (deducted during submission) is sent to the fee pool.
     * - keeperFee (deducted during submission) is refunded into margin if it's the account holder,
     *  or send to the msg.sender if it's not the account holder.
     * @param account the account for which the stored order should be cancelled
     */
    function cancelNextPriceOrder(address account, bytes32 bridgeKey) external {
        // important!! order of the account, not the msg.sender
        NextPriceOrder memory order = nextPriceOrders[account];
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        uint256 currentRoundId = _exchangeRates().getCurrentRoundId(baseAsset);
        uint256 syUSDToIncrease;
        if (account == msg.sender) {
            // this is account owner
            // refund keeper fee to margin
            Position storage position = positions[account];
            uint256 price = _assetPriceRequireSystemChecks();
            uint256 fundingIndex = _recomputeFunding(price);
            _updatePositionMargin(position, price, int256(uint256(order.keeperDeposit)));

            // emit event for modifying the position (add the fee to margin)
            emit PositionModified(position.id, account, position.margin, position.size, 0, price, fundingIndex, 0);
        } else {
            // this is someone else (like a keeper)
            // cancellation by third party is only possible when execution cannot be attempted any longer
            // otherwise someone might try to grief an account by cancelling for the keeper fee
            require(_confirmationWindowOver(currentRoundId, order.targetRoundId), "cannot be cancelled by keeper yet");

            // send keeper fee to keeper
            _manager().issueSUSD(msg.sender, order.keeperDeposit);
            syUSDToIncrease += order.keeperDeposit;
        }

        // pay the commitDeposit as fee to the FeePool
        _manager().payFee(order.commitDeposit);
        syUSDToIncrease += order.commitDeposit;
        if (syUSDToIncrease > 0) {
            _manager().sendIncreaseSynth(bridgeKey, sUSD, syUSDToIncrease);
        }

        // remove stored order
        // important!! position of the account, not the msg.sender
        delete nextPriceOrders[account];
        // emit event
        emit NextPriceOrderRemoved(
            account,
            currentRoundId,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
    }

    /**
     * @notice Tries to execute a previously submitted next-price order.
     * Reverts if:
     * - There is no order
     * - Target roundId wasn't reached yet
     * - Order is stale (target roundId is too low compared to current roundId).
     * - Order fails for accounting reason (e.g. margin was removed, leverage exceeded, etc)
     * If order reverts, it has to be removed by calling cancelNextPriceOrder().
     * Anyone can call this method for any account.
     * If this is called by the account holder - the keeperFee is refunded into margin,
     *  otherwise it sent to the msg.sender.
     * @param account address of the account for which to try to execute a next-price order
     */
    function executeNextPriceOrder(address account, bytes32 bridgeKey) external {
        // important!: order  of the account, not the sender!
        NextPriceOrder memory order = nextPriceOrders[account];
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        // check round-Id
        uint256 currentRoundId = _exchangeRates().getCurrentRoundId(baseAsset);
        require(order.targetRoundId <= currentRoundId, "target roundId not reached");

        // check order is not too old to execute
        // we cannot allow executing old orders because otherwise future knowledge
        // can be used to trigger failures of orders that are more profitable
        // then the commitFee that was charged, or can be used to confirm
        // orders that are more profitable than known then (which makes this into a "cheap option").
        require(!_confirmationWindowOver(currentRoundId, order.targetRoundId), "order too old, use cancel");

        // handle the fees and refunds according to the mechanism rules
        uint256 toRefund = order.commitDeposit; // refund the commitment deposit
        uint256 syUSDToIncrease;
        // refund keeperFee to margin if it's the account holder
        if (msg.sender == account) {
            toRefund += order.keeperDeposit;
        } else {
            _manager().issueSUSD(msg.sender, order.keeperDeposit);
            syUSDToIncrease += order.keeperDeposit;
        }

        Position storage position = positions[account];
        uint256 currentPrice = _assetPriceRequireSystemChecks();
        uint256 fundingIndex = _recomputeFunding(currentPrice);
        // refund the commitFee (and possibly the keeperFee) to the margin before executing the order
        // if the order later fails this is reverted of course
        _updatePositionMargin(position, currentPrice, int256(toRefund));
        // emit event for modifying the position (refunding fee/s)
        emit PositionModified(position.id, account, position.margin, position.size, 0, currentPrice, fundingIndex, 0);

        // the correct price for the past round
        (uint256 pastPrice, ) = _exchangeRates().rateAndTimestampAtRound(baseAsset, order.targetRoundId);
        // execute or revert
        uint256 fee = _trade(
            account,
            TradeParams({
                sizeDelta: order.sizeDelta, // using the pastPrice from the target roundId
                price: pastPrice, // the funding is applied only from order confirmation time
                takerFee: _takerFeeNextPrice(marketKey),
                makerFee: _makerFeeNextPrice(marketKey),
                trackingCode: order.trackingCode
            })
        );
        syUSDToIncrease += fee;
        if (syUSDToIncrease > 0) {
            _manager().sendIncreaseSynth(bridgeKey, sUSD, syUSDToIncrease);
        }

        // remove stored order
        delete nextPriceOrders[account];
        // emit event
        emit NextPriceOrderRemoved(
            account,
            currentRoundId,
            order.sizeDelta,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.trackingCode
        );
    }

    ///// Internal views

    // confirmation window is over when current roundId is more than nextPriceConfirmWindow
    // rounds after target roundId
    function _confirmationWindowOver(uint256 currentRoundId, uint256 targetRoundId) internal view returns (bool) {
        return (currentRoundId > targetRoundId) && (currentRoundId - targetRoundId > _nextPriceConfirmWindow(marketKey)); // don't underflow
    }

    // convenience view to access exchangeRates contract for methods that are not exposed
    // via _exchangeCircuitBreaker() contract
    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(_exchangeCircuitBreaker().exchangeRates());
    }

    // calculate the commitFee, which is the fee that would be charged on the order if it was spot
    function _nextPriceCommitDeposit(TradeParams memory params) internal view returns (uint256) {
        // modify params to spot fee
        params.takerFee = _takerFee(marketKey);
        params.makerFee = _makerFee(marketKey);
        // Commit fee is equal to the spot fee that would be paid.
        // This is to prevent free cancellation manipulations (by e.g. withdrawing the margin).
        // The dynamic fee rate is passed as 0 since for the purposes of the commitment deposit
        // it is not important since at the time of order execution it will be refunded and the correct
        // dynamic fee will be charged.
        return _orderFee(params, 0);
    }

    ///// Events
    event NextPriceOrderSubmitted(
        address indexed account,
        int256 sizeDelta,
        uint256 targetRoundId,
        uint256 commitDeposit,
        uint256 keeperDeposit,
        bytes32 trackingCode
    );

    event NextPriceOrderRemoved(
        address indexed account,
        uint256 currentRoundId,
        int256 sizeDelta,
        uint256 targetRoundId,
        uint256 commitDeposit,
        uint256 keeperDeposit,
        bytes32 trackingCode
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./FuturesMarketBase.sol";
import "./SignedSafeMath.sol";
import "./SignedSafeDecimalMath.sol";

/**
 * A mixin that implements vairous useful views that are used externally but
 * aren't used inside the core contract (so don't need to clutter the contract file)
 */
contract MixinFuturesViews is FuturesMarketBase {
    using SignedSafeMath for int256;
    using SignedSafeDecimalMath for int256;

    constructor(address _resolver, bytes32 _baseAsset, bytes32 _marketKey) FuturesMarketBase(_resolver, _baseAsset, _marketKey) {}

    /*
     * Sizes of the long and short sides of the market (in sUSD)
     */
    function marketSizes() public view returns (uint256 long, uint256 short) {
        int256 size = int256(uint256(marketSize));
        int256 skew = marketSkew;
        return (_abs(size.add(skew).div(2)), _abs(size.sub(skew).div(2)));
    }

    /*
     * The debt contributed by this market to the overall system.
     * The total market debt is equivalent to the sum of remaining margins in all open positions.
     */
    function marketDebt() external view returns (uint256 debt, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        return (_marketDebt(price), isInvalid);
    }

    /*
     * The current funding rate as determined by the market skew; this is returned as a percentage per day.
     * If this is positive, shorts pay longs, if it is negative, longs pay shorts.
     */
    function currentFundingRate() external view returns (int256) {
        (uint256 price, ) = assetPrice();
        return _currentFundingRate(price);
    }

    /*
     * The funding per base unit accrued since the funding rate was last recomputed, which has not yet
     * been persisted in the funding sequence.
     */
    function unrecordedFunding() external view returns (int256 funding, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        return (_unrecordedFunding(price), isInvalid);
    }

    /*
     * The number of entries in the funding sequence.
     */
    function fundingSequenceLength() external view returns (uint256) {
        return fundingSequence.length;
    }

    /*
     * The notional value of a position is its size multiplied by the current price. Margin and leverage are ignored.
     */
    function notionalValue(address account) external view returns (int256 value, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        return (_notionalValue(positions[account].size, price), isInvalid);
    }

    /*
     * The PnL of a position is the change in its notional value. Funding is not taken into account.
     */
    function profitLoss(address account) external view returns (int256 pnl, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        return (_profitLoss(positions[account], price), isInvalid);
    }

    /*
     * The funding accrued in a position since it was opened; this does not include PnL.
     */
    function accruedFunding(address account) external view returns (int256 funding, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        return (_accruedFunding(positions[account], price), isInvalid);
    }

    /*
     * The initial margin plus profit and funding; returns zero balance if losses exceed the initial margin.
     */
    function remainingMargin(address account) external view returns (uint256 marginRemaining, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        return (_remainingMargin(positions[account], price), isInvalid);
    }

    /*
     * The approximate amount of margin the user may withdraw given their current position; this underestimates the
     * true value slightly.
     */
    function accessibleMargin(address account) external view returns (uint256 marginAccessible, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        return (_accessibleMargin(positions[account], price), isInvalid);
    }

    /*
     * The price at which a position is subject to liquidation; otherwise the price at which the user's remaining
     * margin has run out. When they have just enough margin left to pay a liquidator, then they are liquidated.
     * If a position is long, then it is safe as long as the current price is above the liquidation price; if it is
     * short, then it is safe whenever the current price is below the liquidation price.
     * A position's accurate liquidation price can move around slightly due to accrued funding.
     */
    function liquidationPrice(address account) external view returns (uint256 price, bool invalid) {
        (uint256 aPrice, bool isInvalid) = assetPrice();
        uint256 liqPrice = _approxLiquidationPrice(positions[account], aPrice);
        return (liqPrice, isInvalid);
    }

    /**
     * The fee paid to liquidator in the event of successful liquidation of an account at current price.
     * Returns 0 if account cannot be liquidated right now.
     * @param account address of the trader's account
     * @return fee that will be paid for liquidating the account if it can be liquidated
     *  in sUSD fixed point decimal units or 0 if account is not liquidatable.
     */
    function liquidationFee(address account) external view returns (uint256) {
        (uint256 price, bool invalid) = assetPrice();
        if (!invalid && _canLiquidate(positions[account], price)) {
            return _liquidationFee(int256(positions[account].size), price);
        } else {
            // theoretically we can calculate a value, but this value is always incorrect because
            // it's for a price at which liquidation cannot happen - so is misleading, because
            // it won't be paid, and what will be paid is a different fee (for a different price)
            return 0;
        }
    }

    /*
     * True if and only if a position is ready to be liquidated.
     */
    function canLiquidate(address account) external view returns (bool) {
        (uint256 price, bool invalid) = assetPrice();
        return !invalid && _canLiquidate(positions[account], price);
    }

    /*
     * Reports the fee for submitting an order of a given size. Orders that increase the skew will be more
     * expensive than ones that decrease it. Dynamic fee is added according to the recent volatility
     * according to SIP-184.
     * @param sizeDelta size of the order in baseAsset units (negative numbers for shorts / selling)
     * @return fee in sUSD decimal, and invalid boolean flag for invalid rates or dynamic fee that is
     * too high due to recent volatility.
     */
    function orderFee(int256 sizeDelta) external view returns (uint256 fee, bool invalid) {
        (uint256 price, bool isInvalid) = assetPrice();
        (uint256 dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        TradeParams memory params = TradeParams({
            sizeDelta: sizeDelta,
            price: price,
            takerFee: _takerFee(marketKey),
            makerFee: _makerFee(marketKey),
            trackingCode: bytes32(0)
        });
        return (_orderFee(params, dynamicFeeRate), isInvalid || tooVolatile);
    }

    /*
     * Returns all new position details if a given order from `sender` was confirmed at the current price.
     */
    function postTradeDetails(
        int256 sizeDelta,
        address sender
    ) external view returns (uint256 margin, int256 size, uint256 price, uint256 liqPrice, uint256 fee, Status status) {
        bool invalid;
        (price, invalid) = assetPrice();
        if (invalid) {
            return (0, 0, 0, 0, 0, Status.InvalidPrice);
        }

        TradeParams memory params = TradeParams({
            sizeDelta: sizeDelta,
            price: price,
            takerFee: _takerFee(marketKey),
            makerFee: _makerFee(marketKey),
            trackingCode: bytes32(0)
        });
        (Position memory newPosition, uint256 fee_, Status status_) = _postTradeDetails(positions[sender], params);

        liqPrice = _approxLiquidationPrice(newPosition, newPosition.lastPrice);
        return (newPosition.margin, newPosition.size, newPosition.lastPrice, liqPrice, fee_, status_);
    }

    /// helper methods calculates the approximate liquidation price
    function _approxLiquidationPrice(Position memory position, uint256 currentPrice) internal view returns (uint256) {
        int256 positionSize = int256(position.size);

        // short circuit
        if (positionSize == 0) {
            return 0;
        }

        // price = lastPrice + (liquidationMargin - margin) / positionSize - netAccrued
        int256 fundingPerUnit = _netFundingPerUnit(position.lastFundingIndex, currentPrice);

        // minimum margin beyond which position can be liqudiated
        uint256 liqMargin = _liquidationMargin(positionSize, currentPrice);

        // A position can be liquidated whenever:
        //     remainingMargin <= liquidationMargin
        // Hence, expanding the definition of remainingMargin the exact price
        // at which a position can first be liquidated is:
        //     margin + profitLoss + funding =  liquidationMargin
        //     substitute with: profitLoss = (price - last-price) * positionSize
        //     and also with: funding = netFundingPerUnit * positionSize
        //     we get: margin + (price - last-price) * positionSize + netFundingPerUnit * positionSize =  liquidationMargin
        //     moving around: price  = lastPrice + (liquidationMargin - margin) / positionSize - netFundingPerUnit
        int256 result = int256(uint256(position.lastPrice))
            .add(int256(liqMargin).sub(int256(uint256(position.margin))).divideDecimal(positionSize))
            .sub(fundingPerUnit);

        // If the user has leverage less than 1, their liquidation price may actually be negative; return 0 instead.
        return uint256(_max(0, result));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Internal references
import "./AddressResolver.sol";

contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second) internal pure returns (bytes32[] memory combination) {
        combination = new bytes32[](first.length + second.length);

        for (uint256 i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint256 j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
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

    modifier onlyOwner() {
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

/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2 ** 64, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2 ** 32, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2 ** 16, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2 ** 8, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2 ** 255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
// import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./externals/openzeppelin/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10 ** uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10 ** uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(uint256 x, uint256 y, uint256 precisionUnit) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(uint256 x, uint256 y, uint256 precisionUnit) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int256 x) internal pure returns (uint256) {
        return uint256(signedAbs(x));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignedSafeMath.sol";

// TODO: Test suite

library SignedSafeDecimalMath {
    using SignedSafeMath for int256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    int256 public constant UNIT = int256(10 ** uint256(decimals));

    /* The number representing 1.0 for higher fidelity numbers. */
    int256 public constant PRECISE_UNIT = int256(10 ** uint256(highPrecisionDecimals));
    int256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = int256(10 ** uint256(highPrecisionDecimals - decimals));

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (int256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (int256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Rounds an input with an extra zero of precision, returning the result without the extra zero.
     * Half increments round away from zero; positive numbers at a half increment are rounded up,
     * while negative such numbers are rounded down. This behaviour is designed to be consistent with the
     * unsigned version of this library (SafeDecimalMath).
     */
    function _roundDividingByTen(int256 valueTimesTen) private pure returns (int256) {
        int256 increment;
        if (valueTimesTen % 10 >= 5) {
            increment = 10;
        } else if (valueTimesTen % 10 <= -5) {
            increment = -10;
        }
        return (valueTimesTen + increment) / 10;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(int256 x, int256 y) internal pure returns (int256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(int256 x, int256 y, int256 precisionUnit) private pure returns (int256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        int256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);
        return _roundDividingByTen(quotientTimesTen);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(int256 x, int256 y) internal pure returns (int256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(int256 x, int256 y) internal pure returns (int256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(int256 x, int256 y) internal pure returns (int256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(int256 x, int256 y, int256 precisionUnit) private pure returns (int256) {
        int256 resultTimesTen = x.mul(precisionUnit * 10).div(y);
        return _roundDividingByTen(resultTimesTen);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(int256 x, int256 y) internal pure returns (int256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(int256 x, int256 y) internal pure returns (int256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(int256 i) internal pure returns (int256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(int256 i) internal pure returns (int256) {
        int256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);
        return _roundDividingByTen(quotientTimesTen);
    }
}

// SPDX-License-Identifier: MIT

/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
 * When we upgrade to solidity v0.6.0 or above, we should be able to
 * just do import `"openzeppelin-solidity-3.0.0/contracts/math/SignedSafeMath.sol";`
 * wherever this is used.
 */

pragma solidity ^0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant _INT256_MIN = -2 ** 255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function getAvailableBridge(bytes32 bridgeName) external view returns (address);

    function getBridgeList() external view returns (bytes32[] memory);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchangeCircuitBreaker {
    // Views

    function exchangeRates() external view returns (address);

    function rateWithInvalid(bytes32 currencyKey) external view returns (uint256, bool);

    function priceDeviationThresholdFactor() external view returns (uint256);

    function isDeviationAboveThreshold(uint256 base, uint256 comparison) external view returns (bool);

    function lastExchangeRate(bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function resetLastExchangeRate(bytes32[] calldata currencyKeys) external;

    function rateWithBreakCircuit(bytes32 currencyKey) external returns (uint256 lastValidRate, bool circuitBroken);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint256[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value, uint256 sourceRate, uint256 destinationRate);

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) external view returns (uint256 value, uint256 sourceRate, uint256 destinationRate);

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value, uint256 systemValue, uint256 systemSourceRate, uint256 systemDestinationRate);

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint256);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint256 startingRoundId,
        uint256 startingTimestamp,
        uint256 timediff
    ) external view returns (uint256);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId) external view returns (uint256 rate, uint256 time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint256 rate, uint256 time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint256 rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint256);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint256);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint256 numRounds,
        uint256 roundId
    ) external view returns (uint256[] memory rates, uint256[] memory times);

    function ratesAndInvalidForCurrencies(
        bytes32[] calldata currencyKeys
    ) external view returns (uint256[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint256[] memory);

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);

    function rateWithSafetyChecks(bytes32 currencyKey) external returns (uint256 rate, bool broken, bool invalid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint256 amount;
        bytes32 dest;
        uint256 reclaim;
        uint256 rebate;
        uint256 srcRoundIdAtPeriodEnd;
        uint256 destRoundIdAtPeriodEnd;
        uint256 timestamp;
    }

    struct ExchangeEntry {
        uint256 sourceRate;
        uint256 destinationRate;
        uint256 destinationAmount;
        uint256 exchangeFeeRate;
        uint256 exchangeDynamicFeeRate;
        uint256 roundIdForSrc;
        uint256 roundIdForDest;
    }

    struct ExchangeArgs {
        address fromAccount;
        address destAccount;
        bytes32 sourceCurrencyKey;
        bytes32 destCurrencyKey;
        uint256 sourceAmount;
        uint256 destAmount;
        uint256 fee;
        uint256 reclaimed;
        uint256 refunded;
        uint16 destChainId;
        bool erc20Payment;
    }

    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint256 amount,
        uint256 refunded
    ) external view returns (uint256 amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint256);

    function settlementOwing(
        address account,
        bytes32 currencyKey
    ) external view returns (uint256 reclaimAmount, uint256 rebateAmount, uint256 numEntries);

    // function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint256);

    function dynamicFeeRateForExchange(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 amountReceived, uint256 fee, uint256 exchangeFeeRate);

    // function priceDeviationThresholdFactor() external view returns (uint256);

    // function waitingPeriodSecs() external view returns (uint256);

    // function lastExchangeRate(bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function exchange(ExchangeArgs calldata args, bytes32 bridgeName) external payable returns (uint256 amountReceived);

    function exchangeAtomically(
        uint256 minAmount,
        ExchangeArgs calldata args,
        bytes32 bridgeName
    ) external payable returns (uint256 amountReceived);

    function settle(address from, bytes32 currencyKey) external returns (uint256 reclaimed, uint256 refunded, uint256 numEntries);

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;

    function updateDestinationForExchange(address recipient, bytes32 destinationKey, uint256 destinationAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint256);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint256[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int256);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int256[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record) external view returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records) external view returns (bytes32[] memory);

    // Mutative functions
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    function deleteIntValue(bytes32 contractName, bytes32 record) external;

    function deleteAddressValue(bytes32 contractName, bytes32 record) external;

    function deleteBoolValue(bytes32 contractName, bytes32 record) external;

    function deleteBytes32Value(bytes32 contractName, bytes32 record) external;

    function setUIntValue(bytes32 contractName, bytes32 record, uint256 value) external;

    function setUIntValues(bytes32 contractName, bytes32[] calldata records, uint256[] calldata values) external;

    function setIntValue(bytes32 contractName, bytes32 record, int256 value) external;

    function setIntValues(bytes32 contractName, bytes32[] calldata records, int256[] calldata values) external;

    function setAddressValue(bytes32 contractName, bytes32 record, address value) external;

    function setAddressValues(bytes32 contractName, bytes32[] calldata records, address[] calldata values) external;

    function setBoolValue(bytes32 contractName, bytes32 record, bool value) external;

    function setBoolValues(bytes32 contractName, bytes32[] calldata records, bool[] calldata values) external;

    function setBytes32Value(bytes32 contractName, bytes32 record, bytes32 value) external;

    function setBytes32Values(bytes32 contractName, bytes32[] calldata records, bytes32[] calldata values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFuturesMarketBaseTypes.sol";

interface IFuturesMarket {
    /* ========== FUNCTION INTERFACE ========== */

    /* ---------- Market Details ---------- */

    function marketKey() external view returns (bytes32 key);

    function baseAsset() external view returns (bytes32 key);

    function marketSize() external view returns (uint128 size);

    function marketSkew() external view returns (int128 skew);

    function fundingLastRecomputed() external view returns (uint32 timestamp);

    function fundingSequence(uint256 index) external view returns (int128 netFunding);

    function positions(
        address account
    ) external view returns (uint64 id, uint64 fundingIndex, uint128 margin, uint128 lastPrice, int128 size);

    function assetPrice() external view returns (uint256 price, bool invalid);

    function marketSizes() external view returns (uint256 long, uint256 short);

    function marketDebt() external view returns (uint256 debt, bool isInvalid);

    function currentFundingRate() external view returns (int256 fundingRate);

    function unrecordedFunding() external view returns (int256 funding, bool invalid);

    function fundingSequenceLength() external view returns (uint256 length);

    /* ---------- Position Details ---------- */

    function notionalValue(address account) external view returns (int256 value, bool invalid);

    function profitLoss(address account) external view returns (int256 pnl, bool invalid);

    function accruedFunding(address account) external view returns (int256 funding, bool invalid);

    function remainingMargin(address account) external view returns (uint256 marginRemaining, bool invalid);

    function accessibleMargin(address account) external view returns (uint256 marginAccessible, bool invalid);

    function liquidationPrice(address account) external view returns (uint256 price, bool invalid);

    function liquidationFee(address account) external view returns (uint256);

    function canLiquidate(address account) external view returns (bool);

    function orderFee(int256 sizeDelta) external view returns (uint256 fee, bool invalid);

    function postTradeDetails(
        int256 sizeDelta,
        address sender
    )
        external
        view
        returns (
            uint256 margin,
            int256 size,
            uint256 price,
            uint256 liqPrice,
            uint256 fee,
            IFuturesMarketBaseTypes.Status status
        );

    /* ---------- Market Operations ---------- */

    function recomputeFunding() external returns (uint256 lastIndex);

    function transferMargin(int256 marginDelta) external;

    function withdrawAllMargin() external;

    function modifyPosition(int256 sizeDelta) external;

    function modifyPositionWithTracking(int256 sizeDelta, bytes32 trackingCode) external;

    function submitNextPriceOrder(int256 sizeDelta) external;

    function submitNextPriceOrderWithTracking(int256 sizeDelta, bytes32 trackingCode) external;

    function cancelNextPriceOrder(address account) external;

    function executeNextPriceOrder(address account) external;

    function closePosition() external;

    function closePositionWithTracking(bytes32 trackingCode) external;

    function liquidatePosition(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFuturesMarketBaseTypes {
    /* ========== TYPES ========== */

    enum Status {
        Ok,
        InvalidPrice,
        PriceOutOfBounds,
        CanLiquidate,
        CannotLiquidate,
        MaxMarketSizeExceeded,
        MaxLeverageExceeded,
        InsufficientMargin,
        NotPermitted,
        NilOrder,
        NoPositionOpen,
        PriceTooVolatile
    }

    // If margin/size are positive, the position is long; if negative then it is short.
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

    // next-price order storage
    struct NextPriceOrder {
        int128 sizeDelta; // difference in position to pass to modifyPosition
        uint128 targetRoundId; // price oracle roundId using which price this order needs to exucted
        uint128 commitDeposit; // the commitDeposit paid upon submitting that needs to be refunded if order succeeds
        uint128 keeperDeposit; // the keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
        bytes32 trackingCode; // tracking code to emit on execution for volume source fee sharing
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISynth.sol";

interface IIssuer {
    // Views

    function allNetworksDebtInfo() external view returns (uint256 debt, uint256 sharesSupply);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer) external view returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(
        address _issuer
    ) external view returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer) external view returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer) external view returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(
        address issuer
    ) external view returns (uint256 maxIssuable, uint256 alreadyIssued, uint256 totalSystemDebt);

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint256);

    function checkFreeCollateral(
        address _issuer,
        bytes32 _collateralKey,
        uint16 _chainId
    ) external view returns (uint256 withdrawableSynthr);

    function issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function issueMaxSynths(address from, uint256 destChainId) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynths(
        address from,
        bytes32 synthKey,
        uint256 amount
    ) external returns (uint256 synthAmount, uint256 debtShare, uint256 reclaimed, uint256 refunded);

    function burnSynthsToTarget(
        address from,
        bytes32 synthKey
    ) external returns (uint256 synthAmount, uint256 debtShare, uint256 reclaimed, uint256 refunded);

    function burnForRedemption(address deprecatedSynthProxy, address account, uint256 balance) external;

    function burnSynthsWithoutDebt(bytes32 currencyKey, address from, uint amount) external returns (uint256 burnAmount);

    function synthIssueFromSynthrSwap(address _account, bytes32 _synthKey, uint256 _synthAmount) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        uint16 chainId,
        bool isSelfLiquidation
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate, uint256 sharesToRemove);

    function destIssue(address _account, bytes32 _synthKey, uint256 _synthAmount) external;

    function destBurn(address _account, bytes32 _synthKey, uint256 _synthAmount) external returns (uint256);

    function transferMargin(address account, uint256 marginDelta) external returns (uint256);

    function destTransferMargin(address _account, uint256 _marginDelta, bytes32 _marketKey) external returns (bool);

    function setCurrentPeriodId(uint128 periodId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISynth {
    // Views
    function balanceOf(address _account) external view returns (uint256);

    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external payable returns (bool);

    function transferFromAndSettle(address from, address to, uint256 value) external payable returns (bool);

    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExchanger.sol";

interface ISynthrBridge {
    /* ========== MUTATIVE FUNCTIONS ========== */
    function sendDepositCollateral(address account, bytes32 collateralKey, uint256 amount) external;

    function sendMint(
        address account,
        bytes32 synthKey,
        uint256 synthAmount,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    function sendWithdraw(
        address account,
        bytes32 collateralKey,
        uint256 amount,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    // should call destBurn function of source contract(SynthrGateway.sol) on the dest chains while broadcasting message
    // note: should update entry for liquidatorRewards whenever calling this function.
    function sendBurn(
        address accountForSynth,
        bytes32 synthKey,
        uint256 synthAmount,
        uint256 reclaimed,
        uint256 refunded
    ) external;

    // function sendExchange(IExchanger.ExchangeArgs calldata args) external payable;

    function sendExchange(
        address account,
        bytes32 sourceCurrencyKey,
        bytes32 destCurrencyKey,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 reclaimed,
        uint256 refund,
        uint256 fee,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    function sendLiquidate(
        address account,
        bytes32 collateralKey,
        uint256 collateralAmount,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    function sendBridgeSyToken(
        address account,
        bytes32 synthKey,
        uint256 amount,
        uint16 dstChainId,
        bool erc20Payment
    ) external payable;

    function sendTransferMargin(address account, uint256 amount) external;

    function sendWithdrawMargin(address account, uint256 amount, uint16 destChainId, bool erc20Payment) external payable;

    function sendCrossSwapSyAssetToNative(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        address dexAddress,
        uint256 fee,
        bytes calldata dexPayload,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapNativeToSyAsset(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapNativeToNative(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        address dexAddress,
        uint256 fee,
        bytes calldata dexPayload,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapSyAssetToNativeWithDex(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapNativeToNativeWithDex(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee,
        bool erc20Payment
    ) external payable;

    function sendBurnFeePool(uint amount) external;

    function sendIncreaseSynth(bytes32 synthKey, uint256 synthAmount) external;

    function calcFee(bytes memory lzPayload, uint16 packetType, uint16 dstChainId) external view returns (uint256 lzFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function systemSuspended() external view returns (bool);

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireFuturesActive() external view;

    function requireFuturesMarketActive(bytes32 marketKey) external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function synthSuspended(bytes32 currencyKey) external view returns (bool);

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(
        bytes32[] calldata synths
    ) external view returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(
        bytes32[] calldata synths
    ) external view returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(
        bytes32[] calldata marketKeys
    ) external view returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(bytes32 section, address account, bool canSuspend, bool canResume) external;
}