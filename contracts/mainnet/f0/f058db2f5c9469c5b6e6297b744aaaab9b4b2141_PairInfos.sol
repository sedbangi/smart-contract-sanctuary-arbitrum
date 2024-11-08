// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '../interfaces/ITradingStorage.sol';


contract PairInfos {

    uint256 constant PRECISION = 1e10;     
    uint256 constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)
    
    struct PairParams{
        uint256 onePercentDepthAbove; 
        uint256 onePercentDepthBelow; 
        uint256 rolloverFeePerBlockP; 
        uint256 fundingFeePerBlockP;  
    }

    struct PairFundingFees{
        int256 accPerOiLong; 
        int256 accPerOiShort; 
        uint256 lastUpdateBlock;
    }

    struct PairRolloverFees{
        uint256 accPerCollateral; 
        uint256 lastUpdateBlock;
    }

    struct TradeInitialAccFees{
        uint256 rollover; 
        int256 funding;   
        bool openedAfterUpdate;
    }

    ITradingStorage public storageT;
    address public manager;

    uint256 public maxNegativePnlOnOpenP;

    mapping(uint256 => PairParams) public pairParams;
    mapping(uint => PairFundingFees) public pairFundingFees;
    mapping(uint256 => PairRolloverFees) public pairRolloverFees;

    mapping(
        address => mapping(
            uint256 => mapping(
                uint256 => TradeInitialAccFees
            )
        )
    ) public tradeInitialAccFees;

    event ManagerUpdated(address value);
    event MaxNegativePnlOnOpenPUpdated(uint256 value);
    event PairParamsUpdated(uint256 pairIndex, PairParams value);
    event OnePercentDepthUpdated(uint256 pairIndex, uint256 valueAbove, uint256 valueBelow);
    event RolloverFeePerBlockPUpdated(uint256 pairIndex, uint256 value);
    event FundingFeePerBlockPUpdated(uint256 pairIndex, uint256 value);

    event TradeInitialAccFeesStored(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 rollover,
        int256 funding
    );

    event AccFundingFeesStored(uint256 pairIndex, int256 valueLong, int256 valueShort);
    event AccRolloverFeesStored(uint256 pairIndex, uint256 value);

    event FeesCharged(
        uint256 pairIndex,
        bool long,
        uint256 collateral, 
        uint256 leverage,
        int256 percentProfit, 
        uint256 rolloverFees, 
        int256 fundingFees   
    );

    error PairInfosWrongParameters();
    error PairInfosInvalidGovAddress(address account);
    error PairInfosInvalidManagerAddress(address account);
    error PairInfosInvalidCallbacksContract(address account);
    error PairInfosInvalidAddress(address account);
    error PairInfosTooHigh();

    modifier onlyGov(){
        if (msg.sender != storageT.gov()) {
            revert PairInfosInvalidGovAddress(msg.sender);
        }
        _;
    }
    modifier onlyManager(){
        if (msg.sender != manager) {
            revert PairInfosInvalidManagerAddress(msg.sender);
        }
        _;
    }
    modifier onlyCallbacks(){
        if (msg.sender != storageT.callbacks()) {
            revert PairInfosInvalidCallbacksContract(msg.sender);
        }
        _;
    }

    constructor(
        ITradingStorage _storageT,
        address _manager,
        uint256 _maxNegativePnlOnOpenP
    ) {
        if (address(_storageT) == address(0) || 
            _manager == address(0) ||
            _maxNegativePnlOnOpenP == 0) {
            revert PairInfosWrongParameters();
        }

        storageT = _storageT;
        manager = _manager;
        maxNegativePnlOnOpenP = _maxNegativePnlOnOpenP;
    }

    function setManager(address _manager) external onlyGov{
        if (_manager == address(0)) {
            revert PairInfosInvalidAddress(address(0));
        }
        manager = _manager;

        emit ManagerUpdated(_manager);
    }

    function setMaxNegativePnlOnOpenP(uint256 value) external onlyManager{
        maxNegativePnlOnOpenP = value;

        emit MaxNegativePnlOnOpenPUpdated(value);
    }

    function setPairParamsArray(
        uint256[] memory indices,
        PairParams[] memory values
    ) external onlyManager{
        if (indices.length != values.length) revert PairInfosWrongParameters();

        for(uint256 i = 0; i < indices.length; i++){
            setPairParams(indices[i], values[i]);
        }
    }

    function setOnePercentDepthArray(
        uint256[] memory indices,
        uint256[] memory valuesAbove,
        uint256[] memory valuesBelow
    ) external onlyManager{
        if (indices.length != valuesAbove.length || indices.length != valuesBelow.length) {
            revert PairInfosWrongParameters();
        }

        for(uint256 i = 0; i < indices.length; i++){
            setOnePercentDepth(indices[i], valuesAbove[i], valuesBelow[i]);
        }
    }

    function setRolloverFeePerBlockPArray(
        uint256[] memory indices,
        uint256[] memory values
    ) external onlyManager{
        if (indices.length != values.length) revert PairInfosWrongParameters();

        for(uint256 i = 0; i < indices.length; i++){
            setRolloverFeePerBlockP(indices[i], values[i]);
        }
    }

    function setFundingFeePerBlockPArray(
        uint256[] memory indices,
        uint256[] memory values
    ) external onlyManager{
        if (indices.length != values.length) revert PairInfosWrongParameters();

        for(uint256 i = 0; i < indices.length; i++){
            setFundingFeePerBlockP(indices[i], values[i]);
        }
    }

    function storeTradeInitialAccFees(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long
    ) external onlyCallbacks{
        storeAccFundingFees(pairIndex);

        TradeInitialAccFees storage t = tradeInitialAccFees[trader][pairIndex][index];

        t.rollover = getPendingAccRolloverFees(pairIndex);

        t.funding = long ? 
            pairFundingFees[pairIndex].accPerOiLong :
            pairFundingFees[pairIndex].accPerOiShort;

        t.openedAfterUpdate = true;

        emit TradeInitialAccFeesStored(trader, pairIndex, index, t.rollover, t.funding);
    }

    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral,  
        uint256 leverage,
        int256 percentProfit,
        uint256 closingFee    
    ) external onlyCallbacks returns(uint256 amount){ 
        storeAccFundingFees(pairIndex);

        uint256 r = getTradeRolloverFee(trader, pairIndex, index, collateral);
        int256 f = getTradeFundingFee(trader, pairIndex, index, long, collateral, leverage);

        amount = getTradeValuePure(collateral, percentProfit, r, f, closingFee);

        emit FeesCharged(pairIndex, long, collateral, leverage, percentProfit, r, f);
    }

    function getTradePriceImpact(
        uint256 openPrice,        
        uint256 pairIndex,
        bool long,
        uint256 tradeOpenInterest 
    ) external view returns(
        uint256 priceImpactP,     
        uint256 priceAfterImpact  
    ){
        (priceImpactP, priceAfterImpact) = getTradePriceImpactPure(
            openPrice,
            long,
            storageT.openInterestStable(pairIndex, long ? 0 : 1),
            tradeOpenInterest,
            long ?
                pairParams[pairIndex].onePercentDepthAbove :
                pairParams[pairIndex].onePercentDepthBelow
        );
    }

    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, 
        bool long,
        uint256 collateral, 
        uint256 leverage
    ) external view returns(uint256){ 
        return getTradeLiquidationPricePure(
            openPrice,
            long,
            collateral,
            leverage,
            getTradeRolloverFee(trader, pairIndex, index, collateral),
            getTradeFundingFee(trader, pairIndex, index, long, collateral, leverage)
        );
    }

    function getPairInfos(uint256[] memory indices) external view returns(
        PairParams[] memory,
        PairRolloverFees[] memory,
        PairFundingFees[] memory
    ){
        PairParams[] memory params = new PairParams[](indices.length);
        PairRolloverFees[] memory rolloverFees = new PairRolloverFees[](indices.length);
        PairFundingFees[] memory fundingFees = new PairFundingFees[](indices.length);

        for(uint256 i = 0; i < indices.length; i++){
            uint256 index = indices[i];

            params[i] = pairParams[index];
            rolloverFees[i] = pairRolloverFees[index];
            fundingFees[i] = pairFundingFees[index];
        }

        return (params, rolloverFees, fundingFees);
    }

    function getOnePercentDepthAbove(uint256 pairIndex) external view returns(uint256){
        return pairParams[pairIndex].onePercentDepthAbove;
    }

    function getOnePercentDepthBelow(uint256 pairIndex) external view returns(uint256){
        return pairParams[pairIndex].onePercentDepthBelow;
    }

    function getRolloverFeePerBlockP(uint256 pairIndex) external view returns(uint256){
        return pairParams[pairIndex].rolloverFeePerBlockP;
    }

    function getFundingFeePerBlockP(uint256 pairIndex) external view returns(uint256){
        return pairParams[pairIndex].fundingFeePerBlockP;
    }

    function getAccRolloverFees(uint256 pairIndex) external view returns(uint256){
        return pairRolloverFees[pairIndex].accPerCollateral;
    }

    function getAccRolloverFeesUpdateBlock(uint256 pairIndex) external view returns(uint256){
        return pairRolloverFees[pairIndex].lastUpdateBlock;
    }

    function getAccFundingFeesLong(uint256 pairIndex) external view returns(int256){
        return pairFundingFees[pairIndex].accPerOiLong;
    }

    function getAccFundingFeesShort(uint256 pairIndex) external view returns(int256){
        return pairFundingFees[pairIndex].accPerOiShort;
    }

    function getAccFundingFeesUpdateBlock(uint256 pairIndex) external view returns(uint256){
        return pairFundingFees[pairIndex].lastUpdateBlock;
    }

    function getTradeInitialAccRolloverFeesPerCollateral(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external view returns(uint256){
        return tradeInitialAccFees[trader][pairIndex][index].rollover;
    }

    function getTradeInitialAccFundingFeesPerOi(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external view returns(int256){
        return tradeInitialAccFees[trader][pairIndex][index].funding;
    }

    function getTradeOpenedAfterUpdate(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external view returns(bool){
        return tradeInitialAccFees[trader][pairIndex][index].openedAfterUpdate;
    }

    function setPairParams(uint256 pairIndex, PairParams memory value) public onlyManager{
        storeAccRolloverFees(pairIndex);
        storeAccFundingFees(pairIndex);

        pairParams[pairIndex] = value;

        emit PairParamsUpdated(pairIndex, value);
    }

    function setOnePercentDepth(
        uint256 pairIndex,
        uint256 valueAbove,
        uint256 valueBelow
    ) public onlyManager{
        PairParams storage p = pairParams[pairIndex];

        p.onePercentDepthAbove = valueAbove;
        p.onePercentDepthBelow = valueBelow;
        
        emit OnePercentDepthUpdated(pairIndex, valueAbove, valueBelow);
    }
    
    function setRolloverFeePerBlockP(uint256 pairIndex, uint256 value) public onlyManager{
        if (value > 25000000) revert PairInfosTooHigh();

        storeAccRolloverFees(pairIndex);

        pairParams[pairIndex].rolloverFeePerBlockP = value;
        
        emit RolloverFeePerBlockPUpdated(pairIndex, value);
    }
    
    function setFundingFeePerBlockP(uint256 pairIndex, uint256 value) public onlyManager{
        if (value > 10000000) revert PairInfosTooHigh();

        storeAccFundingFees(pairIndex);

        pairParams[pairIndex].fundingFeePerBlockP = value;
        
        emit FundingFeePerBlockPUpdated(pairIndex, value);
    }

    function getPendingAccRolloverFees(
        uint256 pairIndex
    ) public view returns(uint256){ 
        PairRolloverFees storage r = pairRolloverFees[pairIndex];
        
        return r.accPerCollateral +
            (block.number - r.lastUpdateBlock)
            * pairParams[pairIndex].rolloverFeePerBlockP
            * 1e18 / PRECISION / 100;
    }

    function getPendingAccFundingFees(uint256 pairIndex) public view returns(
        int256 valueLong,
        int256 valueShort
    ){
        PairFundingFees storage f = pairFundingFees[pairIndex];

        valueLong = f.accPerOiLong;
        valueShort = f.accPerOiShort;

        int256 openInterestStableLong = int256(storageT.openInterestStable(pairIndex, 0));
        int256 openInterestStableShort = int256(storageT.openInterestStable(pairIndex, 1));

        int256 fundingFeesPaidByLongs = (openInterestStableLong - openInterestStableShort)
            * int256(block.number - f.lastUpdateBlock)
            * int256(pairParams[pairIndex].fundingFeePerBlockP)
            / int256(PRECISION) / 100;

        if(openInterestStableLong > 0){
            valueLong += fundingFeesPaidByLongs * 1e18
                / openInterestStableLong;
        }

        if(openInterestStableShort > 0){
            valueShort += fundingFeesPaidByLongs * 1e18 * (-1)
                / openInterestStableShort;
        }
    }

    function getTradeRolloverFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 collateral 
    ) public view returns(uint256){ 
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][index];

        if(!t.openedAfterUpdate){
            return 0;
        }

        return getTradeRolloverFeePure(
            t.rollover,
            getPendingAccRolloverFees(pairIndex),
            collateral
        );
    }

    function getTradeFundingFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, 
        uint256 leverage
    ) public view returns(
        int256 // Positive => Fee, Negative => Reward
    ){
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][index];

        if(!t.openedAfterUpdate){
            return 0;
        }

        (int256 pendingLong, int256 pendingShort) = getPendingAccFundingFees(pairIndex);

        return getTradeFundingFeePure(
            t.funding,
            long ? pendingLong : pendingShort,
            collateral,
            leverage
        );
    }
    
    function getTradeRolloverFeePure(
        uint256 accRolloverFeesPerCollateral,
        uint256 endAccRolloverFeesPerCollateral,
        uint256 collateral 
    ) public pure returns(uint256){ 
        return (endAccRolloverFeesPerCollateral - accRolloverFeesPerCollateral)
            * collateral / 1e18;
    }

    function getTradePriceImpactPure(
        uint256 openPrice,        
        bool long,
        uint256 startOpenInterest, 
        uint256 tradeOpenInterest, 
        uint256 onePercentDepth
    ) public pure returns(
        uint256 priceImpactP,      
        uint256 priceAfterImpact   
    ){
        if(onePercentDepth == 0){
            return (0, openPrice);
        }

        priceImpactP = (startOpenInterest + tradeOpenInterest / 2)
            * PRECISION / 1e18 / onePercentDepth;
        
        uint256 priceImpact = priceImpactP * openPrice / PRECISION / 100;

        priceAfterImpact = long ? openPrice + priceImpact : openPrice - priceImpact;
    }

    function getTradeFundingFeePure(
        int256 accFundingFeesPerOi,
        int256 endAccFundingFeesPerOi,
        uint256 collateral,
        uint256 leverage
    ) public pure returns(
        int256 // Positive => Fee, Negative => Reward
    ){
        return (endAccFundingFeesPerOi - accFundingFeesPerOi)
            * int256(collateral) * int256(leverage) / 1e18;
    }

    function getTradeLiquidationPricePure(
        uint256 openPrice,  
        bool long,
        uint256 collateral, 
        uint256 leverage,
        uint256 rolloverFee, 
        int256 fundingFee   
    ) public pure returns(uint256){ 
        int256 liqPriceDistance = int256(openPrice) * (
                int256(collateral * LIQ_THRESHOLD_P / 100)
                - int256(rolloverFee) - fundingFee
            ) / int256(collateral) / int256(leverage);

        int256 liqPrice = long ?
            int256(openPrice) - liqPriceDistance :
            int256(openPrice) + liqPriceDistance;

        return liqPrice > 0 ? uint256(liqPrice) : 0;
    }

    function getTradeValuePure(
        uint256 collateral,   
        int256 percentProfit, 
        uint256 rolloverFee,  
        int256 fundingFee,   
        uint256 closingFee    
    ) public pure returns(uint256){ 
        int256 value = int256(collateral)
            + int256(collateral) * percentProfit / int256(PRECISION) / 100
            - int256(rolloverFee) - fundingFee;

        if(value <= int256(collateral) * int256(100 - LIQ_THRESHOLD_P) / 100){
            return 0;
        }

        value -= int256(closingFee);

        return value > 0 ? uint256(value) : 0;
    }

    function storeAccRolloverFees(uint256 pairIndex) private{
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        r.accPerCollateral = getPendingAccRolloverFees(pairIndex);
        r.lastUpdateBlock = block.number;

        emit AccRolloverFeesStored(pairIndex, r.accPerCollateral);
    }
    
    function storeAccFundingFees(uint256 pairIndex) private{
        PairFundingFees storage f = pairFundingFees[pairIndex];

        (f.accPerOiLong, f.accPerOiShort) = getPendingAccFundingFees(pairIndex);
        f.lastUpdateBlock = block.number;

        emit AccFundingFeesStored(pairIndex, f.accPerOiLong, f.accPerOiShort);
    }  
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./TokenInterface.sol";
import "./IWorkPool.sol";
import "./IPairsStorage.sol";
import "./IChainlinkFeed.sol";


interface ITradingStorage {

    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }

    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSizeStable;
        uint256 openPrice;
        bool buy;
        uint256 leverage;
        uint256 tp;
        uint256 sl; 
    }

    struct TradeInfo {
        uint256 tokenId;
        uint256 openInterestStable; 
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }

    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize;
        bool buy;
        uint256 leverage;
        uint256 tp;
        uint256 sl; 
        uint256 minPrice; 
        uint256 maxPrice; 
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; 
        uint256 slippageP;
        uint256 tokenId; // index in supportedTokens
    }

    struct PendingBotOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function ref() external view returns (address);

    function devFeesStable() external view returns (uint256);

    function govFeesStable() external view returns (uint256);

    function refFeesStable() external view returns (uint256);

    function stable() external view returns (TokenInterface);

    function token() external view returns (TokenInterface);

    function orderTokenManagement() external view returns (IOrderExecutionTokenManagement);

    function linkErc677() external view returns (TokenInterface);

    function priceAggregator() external view returns (IAggregator01);

    function workPool() external view returns (IWorkPool);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint256, bool) external;

    function transferStable(address, address, uint256) external;

    function transferLinkToAggregator(address, uint256, uint256) external;

    function unregisterTrade(address, uint256, uint256) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(address, uint256, uint256) external;

    function hasOpenLimitOrder(address, uint256, uint256) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint256, bool) external;

    function openTrades(address, uint256, uint256) external view returns (Trade memory);

    function openTradesInfo(address, uint256, uint256) external view returns (TradeInfo memory);

    function updateSl(address, uint256, uint256, uint256) external;

    function updateTp(address, uint256, uint256, uint256) external;

    function getOpenLimitOrder(address, uint256, uint256) external view returns (OpenLimitOrder memory);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256) external view returns (PendingMarketOrder memory);

    function storePendingBotOrder(PendingBotOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256) external view returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256) external view returns (uint256);

    function reqID_pendingBotOrder(uint256) external view returns (PendingBotOrder memory);

    function updateTrade(Trade memory) external;

    function unregisterPendingBotOrder(uint256) external;

    function handleDevGovRefFees(uint256, uint256, bool, bool) external returns (uint256);

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint256) external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256) external view returns (uint256);

    function pendingMarketCloseCount(address, uint256) external view returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestStable(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address) external view returns (uint256[] memory);

    function pairTradersArray(uint256) external view returns(address[] memory);

    function setWorkPool(address) external;

}


interface IAggregator01 {

    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    struct PendingSl {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice;
        bool buy;
        uint256 newSl;
    }

    function pairsStorage() external view returns (IPairsStorage);

    function getPrice(uint256, OrderType, uint256) external returns (uint256);

    function tokenPriceStable() external returns (uint256);

    function linkFee() external view returns (uint256);

    function openFeeP(uint256) external view returns (uint256);

    function pendingSlOrders(uint256) external view returns (PendingSl memory);

    function storePendingSlOrder(uint256 orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint256 orderId) external;
}


interface IAggregator02 is IAggregator01 {
    function linkPriceFeed() external view returns (IChainlinkFeed);
}


interface IOrderExecutionTokenManagement {

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function setOpenLimitOrderType(address, uint256, uint256, OpenLimitOrderType) external;

    function openLimitOrderTypes(address, uint256, uint256) external view returns (OpenLimitOrderType);
    
    function addAggregatorFund() external returns (uint256);
}


interface ITradingCallbacks01 {

    enum TradeType {
        MARKET,
        LIMIT
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }
    
    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    function tradeLastUpdated(address, uint256, uint256, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function canExecuteTimeout() external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlinkFeed{
    function latestRoundData() external view returns (uint80,int256,uint256,uint256,uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairsStorage {

    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } 

    function incrementCurrentOrderId() external returns (uint256);

    function updateGroupCollateral(uint256, uint256, bool, bool) external;

    function pairJob(uint256) external returns (string memory, string memory, bytes32, uint256);

    function pairFeed(uint256) external view returns (Feed memory);

    function pairSpreadP(uint256) external view returns (uint256);

    function pairMinLeverage(uint256) external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    function groupMaxCollateral(uint256) external view returns (uint256);

    function groupCollateral(uint256, bool) external view returns (uint256);

    function guaranteedSlEnabled(uint256) external view returns (bool);

    function pairOpenFeeP(uint256) external view returns (uint256);

    function pairCloseFeeP(uint256) external view returns (uint256);

    function pairOracleFeeP(uint256) external view returns (uint256);

    function pairExecuteLimitOrderFeeP(uint256) external view returns (uint256);

    function pairReferralFeeP(uint256) external view returns (uint256);

    function pairMinLevPosStable(uint256) external view returns (uint256);

    function pairsCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";

interface IWorkPool {
    
    function mainPool() external view returns (address);

    function mainPoolOwner() external view returns (address);

    function currentEpochStart() external view returns (uint256);

    function currentEpochPositiveOpenPnl() external view returns (uint256);

    function updateAccPnlPerTokenUsed(uint256 prevPositiveOpenPnl, uint256 newPositiveOpenPnl) external returns (uint256);

    function sendAssets(uint256 assets, address receiver) external;

    function receiveAssets(uint256 assets, address user) external;

    function distributeReward(uint256 assets) external;

    function currentBalanceStable() external view returns (uint256);

    function tvl() external view returns (uint256);

    function marketCap() external view returns (uint256);

    function getPendingAccBlockWeightedMarketCap(uint256 currentBlock) external view returns (uint256);

    function shareToAssetsPrice() external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    function refill(uint256 assets) external; 

    function deplete(uint256 assets) external;

    function withdrawEpochsTimelock() external view returns (uint256);

    function collateralizationP() external view returns (uint256); 

    function currentEpoch() external view returns (uint256);

    function accPnlPerTokenUsed() external view returns (int256);

    function accPnlPerToken() external view returns (int256);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterface{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}