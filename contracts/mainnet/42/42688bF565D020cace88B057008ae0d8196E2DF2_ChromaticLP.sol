// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IChromaticLiquidityCallback
 * @dev Interface for a contract that handles liquidity callbacks in the Chromatic protocol.
 *      Liquidity callbacks are used to handle various operations related to liquidity management.
 *      This interface defines the function signatures for different types of liquidity callbacks.
 */
interface IChromaticLiquidityCallback {
    /**
     * @notice Handles the callback after adding liquidity to the Chromatic protocol.
     * @param settlementToken The address of the settlement token used for adding liquidity.
     * @param vault The address of the vault where the liquidity is added.
     * @param data Additional data associated with the liquidity addition.
     */
    function addLiquidityCallback(
        address settlementToken,
        address vault,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after adding liquidity to the Chromatic protocol.
     * @param settlementToken The address of the settlement token used for adding liquidity.
     * @param vault The address of the vault where the liquidity is added.
     * @param data Additional data associated with the liquidity addition.
     */
    function addLiquidityBatchCallback(
        address settlementToken,
        address vault,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after claiming liquidity from the Chromatic protocol.
     * @param receiptId The ID of the liquidity claim receipt.
     * @param feeRate The trading fee rate associated with the liquidity claim.
     * @param depositedAmount The amount of liquidity deposited.
     * @param mintedCLBTokenAmount The amount of CLB tokens minted as liquidity.
     * @param data Additional data associated with the liquidity claim.
     */
    function claimLiquidityCallback(
        uint256 receiptId,
        int16 feeRate,
        uint256 depositedAmount,
        uint256 mintedCLBTokenAmount,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after claiming liquidity from the Chromatic protocol.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param feeRates The array of trading fee rates associated with each claim in the batch.
     * @param depositedAmounts The array of deposited liquidity amounts for each receipt in the batch.
     * @param mintedCLBTokenAmounts The array of CLB token amounts minted for each receipt in the batch.
     * @param data Additional data associated with the liquidity claim.
     */
    function claimLiquidityBatchCallback(
        uint256[] calldata receiptIds,
        int16[] calldata feeRates,
        uint256[] calldata depositedAmounts,
        uint256[] calldata mintedCLBTokenAmounts,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after removing liquidity from the Chromatic protocol.
     * @param clbToken The address of the Chromatic liquidity token.
     * @param clbTokenId The ID of the Chromatic liquidity token to be removed.
     * @param data Additional data associated with the liquidity removal.
     */
    function removeLiquidityCallback(
        address clbToken,
        uint256 clbTokenId,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after removing liquidity from the Chromatic protocol.
     * @param clbToken The address of the Chromatic liquidity token.
     * @param clbTokenIds The array of the Chromatic liquidity token IDs to be removed.
     * @param data Additional data associated with the liquidity removal.
     */
    function removeLiquidityBatchCallback(
        address clbToken,
        uint256[] calldata clbTokenIds,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after withdrawing liquidity from the Chromatic protocol.
     * @param receiptId The ID of the liquidity withdrawal receipt.
     * @param feeRate The trading fee rate associated with the liquidity withdrawal.
     * @param withdrawnAmount The amount of liquidity that has been withdrawn.
     * @param burnedCLBTokenAmount The amount of CLB tokens burned during the withdrawal.
     * @param data Additional data associated with the liquidity withdrawal.
     */
    function withdrawLiquidityCallback(
        uint256 receiptId,
        int16 feeRate,
        uint256 withdrawnAmount,
        uint256 burnedCLBTokenAmount,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after withdrawing liquidity from the Chromatic protocol.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param feeRates The array of trading fee rates associated with each withdrawal in the batch.
     * @param withdrawnAmounts The array of withdrawn liquidity amounts for each receipt in the batch.
     * @param burnedCLBTokenAmounts The array of CLB token amounts burned for each receipt in the batch.
     * @param data Additional data associated with the liquidity withdrawal.
     */
    function withdrawLiquidityBatchCallback(
        uint256[] calldata receiptIds,
        int16[] calldata feeRates,
        uint256[] calldata withdrawnAmounts,
        uint256[] calldata burnedCLBTokenAmounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title An interface for a contract that is capable of deploying Chromatic markets
 * @notice A contract that constructs a market must implement this to pass arguments to the market
 * @dev This is used to avoid having constructor arguments in the market contract, which results in the init code hash
 * of the market being constant allowing the CREATE2 address of the market to be cheaply computed on-chain
 */
interface IMarketDeployer {
    /**
     * @notice Get the parameters to be used in constructing the market, set transiently during market creation.
     * @dev Called by the market constructor to fetch the parameters of the market
     * Returns underlyingAsset The underlying asset of the market
     * Returns settlementToken The settlement token of the market
     * Returns protocolFeeRate The protocol fee rate of the market
     * Returns vPoolCapacity Capacity of virtual future pool
     * Returns vPoolA Amplification coefficient of virtual future pool, precise value
     */
    function parameters()
        external
        view
        returns (address oracleProvider, address settlementToken, uint16 protocolFeeRate);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {OracleProviderProperties} from "@chromatic-protocol/contracts/core/libraries/registry/OracleProviderProperties.sol";

/**
 * @title IOracleProviderRegistry
 * @dev Interface for the Oracle Provider Registry contract.
 */
interface IOracleProviderRegistry {
    /**
     * @dev Emitted when a new oracle provider is registered.
     * @param oracleProvider The address of the registered oracle provider.
     * @param properties The properties of the registered oracle provider.
     */
    event OracleProviderRegistered(
        address indexed oracleProvider,
        OracleProviderProperties properties
    );

    /**
     * @dev Emitted when an oracle provider is unregistered.
     * @param oracleProvider The address of the unregistered oracle provider.
     */
    event OracleProviderUnregistered(address indexed oracleProvider);

    /**
     * @dev Emitted when the take-profit basis points range of an oracle provider is updated.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    event UpdateTakeProfitBPSRange(
        address indexed oracleProvider,
        uint32 indexed minTakeProfitBPS,
        uint32 indexed maxTakeProfitBPS
    );

    /**
     * @dev Emitted when the level of an oracle provider is set.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new level set for the oracle provider.
     */
    event UpdateLeverageLevel(address indexed oracleProvider, uint8 indexed level);

    /**
     * @notice Registers an oracle provider.
     * @param oracleProvider The address of the oracle provider to register.
     * @param properties The properties of the oracle provider.
     */
    function registerOracleProvider(
        address oracleProvider,
        OracleProviderProperties memory properties
    ) external;

    /**
     * @notice Unregisters an oracle provider.
     * @param oracleProvider The address of the oracle provider to unregister.
     */
    function unregisterOracleProvider(address oracleProvider) external;

    /**
     * @notice Gets the registered oracle providers.
     * @return An array of registered oracle provider addresses.
     */
    function registeredOracleProviders() external view returns (address[] memory);

    /**
     * @notice Checks if an oracle provider is registered.
     * @param oracleProvider The address of the oracle provider to check.
     * @return A boolean indicating if the oracle provider is registered.
     */
    function isRegisteredOracleProvider(address oracleProvider) external view returns (bool);

    /**
     * @notice Retrieves the properties of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @return The properties of the oracle provider.
     */
    function getOracleProviderProperties(
        address oracleProvider
    ) external view returns (OracleProviderProperties memory);

    /**
     * @notice Updates the take-profit basis points range of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    function updateTakeProfitBPSRange(
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) external;

    /**
     * @notice Updates the leverage level of an oracle provider in the registry.
     * @dev The level must be either 0 or 1, and the max leverage must be x10 for level 0 or x20 for level 1.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new leverage level to be set for the oracle provider.
     */
    function updateLeverageLevel(address oracleProvider, uint8 level) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";

/**
 * @title ISettlementTokenRegistry
 * @dev Interface for the Settlement Token Registry contract.
 */
interface ISettlementTokenRegistry {
    /**
     * @dev Emitted when a new settlement token is registered.
     * @param token The address of the registered settlement token.
     * @param oracleProvider The oracle provider address for the settlement token.
     * @param minimumMargin The minimum margin for the markets using this settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    event SettlementTokenRegistered(
        address indexed token,
        address indexed oracleProvider,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    );

    /**
     * @dev Emitted when the oracle provider address for a settlement token is set.
     * @param token The address of the settlement token.
     * @param oracleProvider The oracle provider address for the settlement token.
     */
    event SetSettlementTokenOracleProvider(address indexed token, address indexed oracleProvider);

    /**
     * @dev Emitted when the minimum margin for a settlement token is set.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    event SetMinimumMargin(address indexed token, uint256 indexed minimumMargin);

    /**
     * @dev Emitted when the flash loan fee rate for a settlement token is set.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    event SetFlashLoanFeeRate(address indexed token, uint256 indexed flashLoanFeeRate);

    /**
     * @dev Emitted when the earning distribution threshold for a settlement token is set.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    event SetEarningDistributionThreshold(
        address indexed token,
        uint256 indexed earningDistributionThreshold
    );

    /**
     * @dev Emitted when the Uniswap fee tier for a settlement token is set.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    event SetUniswapFeeTier(address indexed token, uint24 indexed uniswapFeeTier);

    /**
     * @dev Emitted when an interest rate record is appended for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event InterestRateRecordAppended(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @dev Emitted when the last interest rate record is removed for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event LastInterestRateRecordRemoved(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @notice Registers a new settlement token.
     * @param token The address of the settlement token to register.
     * @param oracleProvider The oracle provider address for the settlement token.
     * @param minimumMargin The minimum margin for the settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    function registerSettlementToken(
        address token,
        address oracleProvider,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) external;

    /**
     * @notice Gets the list of registered settlement tokens.
     * @return An array of addresses representing the registered settlement tokens.
     */
    function registeredSettlementTokens() external view returns (address[] memory);

    /**
     * @notice Checks if a settlement token is registered.
     * @param token The address of the settlement token to check.
     * @return True if the settlement token is registered, false otherwise.
     */
    function isRegisteredSettlementToken(address token) external view returns (bool);

    /**
     * @notice Gets the oracle provider address for a settlement token.
     * @param token The address of the settlement token.
     * @return The oracle provider address for the settlement token.
     */
    function getSettlementTokenOracleProvider(address token) external view returns (address);

    /**
     * @notice Sets the oracle provider address for a settlement token.
     * @param token The address of the settlement token.
     * @param oracleProvider The new oracle provider address for the settlement token.
     */
    function setSettlementTokenOracleProvider(address token, address oracleProvider) external;

    /**
     * @notice Gets the minimum margin for a settlement token.
     * @dev The minimumMargin is used as the minimum value for the taker margin of a position
     *      or as the minimum value for the maker margin of each bin.
     * @param token The address of the settlement token.
     * @return The minimum margin for the settlement token.
     */
    function getMinimumMargin(address token) external view returns (uint256);

    /**
     * @notice Sets the minimum margin for a settlement token.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    function setMinimumMargin(address token, uint256 minimumMargin) external;

    /**
     * @notice Gets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The flash loan fee rate for the settlement token.
     */
    function getFlashLoanFeeRate(address token) external view returns (uint256);

    /**
     * @notice Sets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    function setFlashLoanFeeRate(address token, uint256 flashLoanFeeRate) external;

    /**
     * @notice Gets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @return The earning distribution threshold for the settlement token.
     */
    function getEarningDistributionThreshold(address token) external view returns (uint256);

    /**
     * @notice Sets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    function setEarningDistributionThreshold(
        address token,
        uint256 earningDistributionThreshold
    ) external;

    /**
     * @notice Gets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @return The Uniswap fee tier for the settlement token.
     */
    function getUniswapFeeTier(address token) external view returns (uint24);

    /**
     * @notice Sets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    function setUniswapFeeTier(address token, uint24 uniswapFeeTier) external;

    /**
     * @notice Appends an interest rate record for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    function appendInterestRateRecord(
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) external;

    /**
     * @notice Removes the last interest rate record for a settlement token.
     * @param token The address of the settlement token.
     */
    function removeLastInterestRateRecord(address token) external;

    /**
     * @notice Gets the current interest rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The current interest rate for the settlement token.
     */
    function currentInterestRate(address token) external view returns (uint256);

    /**
     * @notice Gets all the interest rate records for a settlement token.
     * @param token The address of the settlement token.
     * @return An array of interest rate records for the settlement token.
     */
    function getInterestRateRecords(
        address token
    ) external view returns (InterestRate.Record[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IMarketTradeOpenPosition} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTradeOpenPosition.sol";
import {IMarketTradeClosePosition} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTradeClosePosition.sol";
import {IMarketAddLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketAddLiquidity.sol";
import {IMarketRemoveLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketRemoveLiquidity.sol";
import {IMarketLens} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLens.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {IMarketSettle} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketSettle.sol";
import {IMarketEvents} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketEvents.sol";
import {IMarketErrors} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketErrors.sol";

/**
 * @title IChromaticMarket
 * @dev Interface for the Chromatic Market contract, which combines trade and liquidity functionalities.
 */
interface IChromaticMarket is
    IMarketEvents,
    IMarketErrors,
    IMarketTradeOpenPosition,
    IMarketTradeClosePosition,
    IMarketAddLiquidity,
    IMarketRemoveLiquidity,
    IMarketLens,
    IMarketState,
    IMarketLiquidate,
    IMarketSettle
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IMarketDeployer} from "@chromatic-protocol/contracts/core/interfaces/factory/IMarketDeployer.sol";
import {ISettlementTokenRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/ISettlementTokenRegistry.sol";
import {IOracleProviderRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/IOracleProviderRegistry.sol";

/**
 * @title IChromaticMarketFactory
 * @dev Interface for the Chromatic Market Factory contract.
 */
interface IChromaticMarketFactory is
    IMarketDeployer,
    IOracleProviderRegistry,
    ISettlementTokenRegistry,
    IInterestCalculator
{
    /**
     * @notice Emitted when the DAO address is updated.
     * @param daoOld The old DAO address.
     * @param daoNew The new DAO address.
     */
    event DaoUpdated(address indexed daoOld, address indexed daoNew);

    /**
     * @notice Emitted when the DAO treasury address is updated.
     * @param treasuryOld The old DAO treasury address.
     * @param treasuryNew The new DAO treasury address.
     */
    event TreasuryUpdated(address indexed treasuryOld, address indexed treasuryNew);

    /**
     * @notice Emitted when the liquidator address is updated.
     * @param liquidatorOld The old liquidator address.
     * @param liquidatorNew The new liquidator address.
     */
    event LiquidatorUpdated(address indexed liquidatorOld, address indexed liquidatorNew);

    /**
     * @notice Emitted when the keeper fee payer address is updated.
     * @param keeperFeePayerOld The old keeper fee payer address.
     * @param keeperFeePayerNew The new keeper fee payer address.
     */
    event KeeperFeePayerUpdated(
        address indexed keeperFeePayerOld,
        address indexed keeperFeePayerNew
    );

    /**
     * @notice Emitted when the default protocol fee rate is updated.
     * @param defaultProtocolFeeRateOld The old default protocol fee rate.
     * @param defaultProtocolFeeRateNew The new default protocol fee rate.
     */
    event DefaultProtocolFeeRateUpdated(
        uint16 indexed defaultProtocolFeeRateOld,
        uint16 indexed defaultProtocolFeeRateNew
    );

    /**
     * @notice Emitted when the vault address is set.
     * @param vault The vault address.
     */
    event VaultSet(address indexed vault);

    /**
     * @notice Emitted when the market settlement task address is updated.
     * @param marketSettlementOld The old market settlement task address.
     * @param marketSettlementNew The new market settlement task address.
     */
    event MarketSettlementUpdated(
        address indexed marketSettlementOld,
        address indexed marketSettlementNew
    );

    /**
     * @notice Emitted when a market is created.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @param market The address of the created market.
     */
    event MarketCreated(
        address indexed oracleProvider,
        address indexed settlementToken,
        address indexed market
    );

    /**
     * @notice Returns the address of the DAO.
     * @return The address of the DAO.
     */
    function dao() external view returns (address);

    /**
     * @notice Returns the address of the DAO treasury.
     * @return The address of the DAO treasury.
     */
    function treasury() external view returns (address);

    /**
     * @notice Returns the address of the liquidator.
     * @return The address of the liquidator.
     */
    function liquidator() external view returns (address);

    /**
     * @notice Returns the address of the vault.
     * @return The address of the vault.
     */
    function vault() external view returns (address);

    /**
     * @notice Returns the address of the keeper fee payer.
     * @return The address of the keeper fee payer.
     */
    function keeperFeePayer() external view returns (address);

    /**
     * @notice Returns the address of the market settlement task.
     * @return The address of the market settlement task.
     */
    function marketSettlement() external view returns (address);

    /**
     * @notice Returns the default protocol fee rate.
     * @return The default protocol fee rate.
     */
    function defaultProtocolFeeRate() external view returns (uint16);

    /**
     * @notice Updates the DAO address.
     * @param _dao The new DAO address.
     */
    function updateDao(address _dao) external;

    /**
     * @notice Updates the DAO treasury address.
     * @param _treasury The new DAO treasury address.
     */
    function updateTreasury(address _treasury) external;

    /**
     * @notice Updates the liquidator address.
     * @param _liquidator The new liquidator address.
     */
    function updateLiquidator(address _liquidator) external;

    /**
     * @notice Updates the keeper fee payer address.
     * @param _keeperFeePayer The new keeper fee payer address.
     */
    function updateKeeperFeePayer(address _keeperFeePayer) external;

    /**
     * @notice Updates the default protocl fee rate.
     * @param _defaultProtocolFeeRate The new default protocol fee rate.
     */
    function updateDefaultProtocolFeeRate(uint16 _defaultProtocolFeeRate) external;

    /**
     * @notice Sets the vault address.
     * @param _vault The vault address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Updates the market settlement task address.
     * @param _marketSettlement The new market settlement task address.
     */
    function updateMarketSettlement(address _marketSettlement) external;

    /**
     * @notice Returns an array of all market addresses.
     * @return markets An array of all market addresses.
     */
    function getMarkets() external view returns (address[] memory markets);

    /**
     * @notice Returns an array of market addresses associated with a settlement token.
     * @param settlementToken The address of the settlement token.
     * @return An array of market addresses.
     */
    function getMarketsBySettlmentToken(
        address settlementToken
    ) external view returns (address[] memory);

    /**
     * @notice Returns the address of a market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @return The address of the market.
     */
    function getMarket(
        address oracleProvider,
        address settlementToken
    ) external view returns (address);

    /**
     * @notice Creates a new market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     */
    function createMarket(address oracleProvider, address settlementToken) external;

    /**
     * @notice Checks if a market is registered.
     * @param market The address of the market.
     * @return True if the market is registered, false otherwise.
     */
    function isRegisteredMarket(address market) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ILendingPool} from "@chromatic-protocol/contracts/core/interfaces/vault/ILendingPool.sol";
import {IVault} from "@chromatic-protocol/contracts/core/interfaces/vault/IVault.sol";

/**
 * @title IChromaticVault
 * @notice Interface for the Chromatic Vault contract.
 */
interface IChromaticVault is IVault, ILendingPool {
    /**
     * @dev Emitted when market earning is accumulated.
     * @param market The address of the market.
     * @param earning The amount of earning accumulated.
     */
    event MarketEarningAccumulated(address indexed market, uint256 earning);

    /**
     * @dev Emitted when maker earning is distributed.
     * @param token The address of the settlement token.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     */
    event MakerEarningDistributed(
        address indexed token,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee
    );

    /**
     * @dev Emitted when market earning is distributed.
     * @param market The address of the market.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     * @param marketBalance The balance of the market.
     */
    event MarketEarningDistributed(
        address indexed market,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee,
        uint256 marketBalance
    );

    /**
     * @notice Emitted when the vault earning distributor address is set.
     * @param vaultEarningDistributor The vault earning distributor address.
     * @param oldVaultEarningDistributor The old vault earning distributor address.
     */
    event VaultEarningDistributorSet(
        address indexed vaultEarningDistributor,
        address indexed oldVaultEarningDistributor
    );

    function setVaultEarningDistributor(address _earningDistributor) external;

    function pendingMakerEarnings(address token) external view returns (uint256);

    function pendingMarketEarnings(address market) external view returns (uint256);

    /**
     * @notice Creates a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function createMakerEarningDistributionTask(address token) external;

    /**
     * @notice Cancels a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function cancelMakerEarningDistributionTask(address token) external;

    /**
     * @notice Distributes the maker earning for a token to the each markets.
     * @param token The address of the settlement token.
     * @param fee The keeper fee amount.
     * @param keeper The keeper address to receive fee.
     */
    function distributeMakerEarning(address token, uint256 fee, address keeper) external;

    /**
     * @notice Creates a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function createMarketEarningDistributionTask(address market) external;

    /**
     * @notice Cancels a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function cancelMarketEarningDistributionTask(address market) external;

    /**
     * @notice Distributes the market earning for a market to the each bins.
     * @param market The address of the market.
     * @param fee The fee amount.
     * @param keeper The keeper address to receive fee.
     */
    function distributeMarketEarning(address market, uint256 fee, address keeper) external;

    function acquireTradingLock() external;

    function releaseTradingLock() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

/**
 * @title ICLBToken
 * @dev Interface for CLBToken contract, which represents Liquidity Bin tokens.
 */
interface ICLBToken is IERC1155, IERC1155MetadataURI {
    /**
     * @dev Total amount of tokens in with a given id.
     * @param id The token ID for which to retrieve the total supply.
     * @return The total supply of tokens for the given token ID.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Total amounts of tokens in with the given ids.
     * @param ids The token IDs for which to retrieve the total supply.
     * @return The total supples of tokens for the given token IDs.
     */
    function totalSupplyBatch(uint256[] memory ids) external view returns (uint256[] memory);

    /**
     * @dev Mints new tokens and assigns them to the specified address.
     * @param to The address to which the minted tokens will be assigned.
     * @param id The token ID to mint.
     * @param amount The amount of tokens to mint.
     * @param data Additional data to pass during the minting process.
     */
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev Burns tokens from a specified address.
     * @param from The address from which to burn tokens.
     * @param id The token ID to burn.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 id, uint256 amount) external;

    /**
     * @dev Retrieves the number of decimals used for token amounts.
     * @return The number of decimals used for token amounts.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Retrieves the name of a token.
     * @param id The token ID for which to retrieve the name.
     * @return The name of the token.
     */
    function name(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the description of a token.
     * @param id The token ID for which to retrieve the description.
     * @return The description of the token.
     */
    function description(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the image URI of a token.
     * @param id The token ID for which to retrieve the image URI.
     * @return The image URI of the token.
     */
    function image(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IInterestCalculator
 * @dev Interface for an interest calculator contract.
 */
interface IInterestCalculator {
    /**
     * @notice Calculates the interest accrued for a given token and amount within a specified time range.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param from The starting timestamp (inclusive) of the time range.
     * @param to The ending timestamp (exclusive) of the time range.
     * @return The accrued interest for the specified token and amount within the given time range.
     */
    function calculateInterest(
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IKeeperFeePayer
 * @dev Interface for a contract that pays keeper fees.
 */
interface IKeeperFeePayer {
    event SetRouter(address indexed);

    /**
     * @notice Approves or revokes approval to the Uniswap router for a given token.
     * @param token The address of the token.
     * @param approve A boolean indicating whether to approve or revoke approval.
     */
    function approveToRouter(address token, bool approve) external;

    /**
     * @notice Pays the keeper fee using Uniswap swaps.
     * @param tokenIn The address of the token being swapped.
     * @param amountOut The desired amount of output tokens.
     * @param keeperAddress The address of the keeper to receive the fee.
     * @return amountIn The actual amount of input tokens used for the swap.
     */
    function payKeeperFee(
        address tokenIn,
        uint256 amountOut,
        address keeperAddress
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IMarketAddLiquidity
 * @dev The interface for adding and claiming liquidity in a market.
 */
interface IMarketAddLiquidity {
    /**
     * @dev Adds liquidity to the market.
     * @param recipient The address to receive the liquidity tokens.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function addLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @notice Adds liquidity to multiple liquidity bins of the market in a batch.
     * @param recipient The address of the recipient for each liquidity bin.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param amounts An array of amounts to add as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return An array of LP receipts.
     */
    function addLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;

    /**
     * @dev Distributes earning to the liquidity bins.
     * @param earning The amount of earning to distribute.
     * @param marketBalance The balance of the market.
     */
    function distributeEarningToBins(uint256 earning, uint256 marketBalance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IMarketErrors
 */
interface IMarketErrors {
    /**
     * @dev Throws an error indicating that the caller is not the DAO.
     */
    error OnlyAccessableByDao();

    /**
     * @dev Throws an error indicating that the caller is nether the chormatic factory contract nor the DAO.
     */
    error OnlyAccessableByFactoryOrDao();

    /**
     * @dev Throws an error indicating that the caller is not the chromatic liquidator contract.
     */

    error OnlyAccessableByLiquidator();

    /**
     * @dev Throws an error indicating that the caller is not the chromatch vault contract.
     */
    error OnlyAccessableByVault();

    /**
     * @dev Throws an error indicating that the amount of liquidity is too small.
     *      This error is thrown when attempting to remove liquidity with an amount of zero.
     */
    error TooSmallAmount();

    /**
     * @dev Throws an error indicating that the specified liquidity receipt does not exist.
     */
    error NotExistLpReceipt();

    /**
     * @dev Throws an error indicating that the liquidity receipt is not claimable.
     */
    error NotClaimableLpReceipt();

    /**
     * @dev Throws an error indicating that the liquidity receipt is not withdrawable.
     */
    error NotWithdrawableLpReceipt();

    /**
     * @dev Throws an error indicating that the liquidity receipt action is invalid.
     */
    error InvalidLpReceiptAction();

    /**
     * @dev Throws an error indicating that the transferred token amount is invalid.
     *      This error is thrown when the transferred token amount does not match the expected amount.
     */
    error InvalidTransferredTokenAmount();

    error DuplicatedTradingFeeRate();

    error AddLiquidityDisabled();
    error RemoveLiquidityDisabled();

    /**
     * @dev Throws an error indicating that the taker margin provided is smaller than the minimum required margin for the specific settlement token.
     *      The minimum required margin is determined by the DAO and represents the minimum amount required for operations such as liquidation and payment of keeper fees.
     */
    error TooSmallTakerMargin();

    /**
     * @dev Throws an error indicating that the margin settlement token balance does not increase by the required margin amount after the callback.
     */
    error NotEnoughMarginTransferred();

    /**
     * @dev Throws an error indicating that the caller is not permitted to perform the action as they are not the owner of the position.
     */
    error NotPermitted();

    /**
     * @dev Throws an error indicating that the total trading fee (including protocol fee) exceeds the maximum allowable trading fee.
     */
    error ExceedMaxAllowableTradingFee();

    /**
     * @dev Throws an error indicating thatwhen the specified leverage exceeds the maximum allowable leverage level set by the Oracle Provider.
     *      Each Oracle Provider has a specific maximum allowable leverage level, which is determined by the DAO.
     *      The default maximum allowable leverage level is 0, which corresponds to a leverage of up to 10x.
     */
    error ExceedMaxAllowableLeverage();

    /**
     * @dev Throws an error indicating that the maker margin value is not within the allowable range based on the absolute quantity and the specified minimum/maximum take-profit basis points (BPS).
     *      The maker margin must fall within the range calculated based on the absolute quantity of the position and the specified minimum/maximum take-profit basis points (BPS) set by the Oracle Provider.
     *      The default range for the minimum/maximum take-profit basis points is 10% to 1000%.
     */
    error NotAllowableMakerMargin();

    /**
     * @dev Throws an error indicating that the requested position does not exist.
     */
    error NotExistPosition();

    /**
     * @dev Throws an error indicating that an error occurred during the claim position callback.
     */
    error ClaimPositionCallbackError();

    /**
     * @dev Throws an error indicating that the position has already been closed.
     */
    error AlreadyClosedPosition();

    /**
     *@dev Throws an error indicating that the position is not claimable.
     */
    error NotClaimablePosition();

    error OpenPositionDisabled();
    error ClosePositionDisabled();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {PositionMode, LiquidityMode, DisplayMode} from "@chromatic-protocol/contracts/core/interfaces/market/Types.sol";

/**
 * @title IMarketEvents
 */
interface IMarketEvents {
    /**
     * @notice Emitted when the protocol fee rate of the market is changed
     * @param protocolFeeRateOld The previous value of the protocol fee rate
     * @param protocolFeeRateNew The updated value of the protocol fee rate
     */
    event ProtocolFeeRateUpdated(uint16 protocolFeeRateOld, uint16 protocolFeeRateNew);

    /**
     * @notice Emitted when the position mode of the market is changed
     * @param positionModeOld The previous value of the position mode
     * @param positionModeNew The updated value of the position mode
     */
    event PositionModeUpdated(PositionMode positionModeOld, PositionMode positionModeNew);

    /**
     * @notice Emitted when the liquidity mode of the market is changed
     * @param liquidityModeOld The previous value of the liquidity mode
     * @param liquidityModeNew The updated value of the liquidity mode
     */
    event LiquidityModeUpdated(LiquidityMode liquidityModeOld, LiquidityMode liquidityModeNew);

    /**
     * @notice Emitted when the display mode of the market is changed
     * @param displayModeOld The previous value of the display mode
     * @param displayModeNew The updated value of the display mode
     */
    event DisplayModeUpdated(DisplayMode displayModeOld, DisplayMode displayModeNew);

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipt The liquidity receipt.
     */
    event AddLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipts An array of LP receipts.
     */
    event AddLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param clbTokenAmount The amount of CLB tokens claimed.
     * @param receipt The liquidity receipt.
     */
    event ClaimLiquidity(LpReceipt receipt, uint256 indexed clbTokenAmount);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param receipts An array of LP receipts.
     * @param clbTokenAmounts The amount list of CLB tokens claimed.
     */
    event ClaimLiquidityBatch(LpReceipt[] receipts, uint256[] clbTokenAmounts);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipt The liquidity receipt.
     */
    event RemoveLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipts An array of LP receipts.
     */
    event RemoveLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipt The liquidity receipt.
     * @param amount The amount of liquidity withdrawn.
     * @param burnedCLBTokenAmount The amount of burned CLB tokens.
     */
    event WithdrawLiquidity(
        LpReceipt receipt,
        uint256 indexed amount,
        uint256 indexed burnedCLBTokenAmount
    );

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipts An array of LP receipts.
     * @param amounts The amount list of liquidity withdrawn.
     * @param burnedCLBTokenAmounts The amount list of burned CLB tokens.
     */
    event WithdrawLiquidityBatch(
        LpReceipt[] receipts,
        uint256[] amounts,
        uint256[] burnedCLBTokenAmounts
    );

    /**
     * @dev Emitted when a position is opened.
     * @param account The address of the account opening the position.
     * @param position The opened position.
     */
    event OpenPosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is closed.
     * @param account The address of the account closing the position.
     * @param position The closed position.
     */
    event ClosePosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is claimed.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param position The claimed position.
     */
    event ClaimPosition(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        Position position
    );

    /**
     * @dev Emitted when a position is claimed by keeper.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The claimed position.
     */
    event ClaimPositionByKeeper(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );

    /**
     * @dev Emitted when a position is liquidated.
     * @param account The address of the account being liquidated.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The liquidated position.
     */
    event Liquidate(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {PendingPosition, ClosingPosition, PendingLiquidity, ClaimableLiquidity, LiquidityBinStatus} from "@chromatic-protocol/contracts/core/interfaces/market/Types.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IMarketLens
 * @dev The interface for liquidity information retrieval in a market.
 */
interface IMarketLens {
    /**
     * @dev Retrieves the total liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the liquidity amount.
     * @return amount The total liquidity amount for the specified trading fee rate.
     */
    function getBinLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the available (free) liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the available liquidity amount.
     * @return amount The available (free) liquidity amount for the specified trading fee rate.
     */
    function getBinFreeLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the values of a specific trading fee rate's bins in the liquidity pool.
     *      The value of a bin represents the total valuation of the liquidity in the bin.
     * @param tradingFeeRates The list of trading fee rate for which to retrieve the bin value.
     * @return values The value list of the bins for the specified trading fee rates.
     */
    function getBinValues(
        int16[] calldata tradingFeeRates
    ) external view returns (uint256[] memory values);

    /**
     * @dev Retrieves the liquidity receipt with the given receipt ID.
     *      It throws NotExistLpReceipt if the specified receipt ID does not exist.
     * @param receiptId The ID of the liquidity receipt to retrieve.
     * @return receipt The liquidity receipt with the specified ID.
     */
    function getLpReceipt(uint256 receiptId) external view returns (LpReceipt memory);

    /**
     * @dev Retrieves the liquidity receipts with the given receipt IDs.
     *      It throws NotExistLpReceipt if the specified receipt ID does not exist.
     * @param receiptIds The ID list of the liquidity receipt to retrieve.
     * @return receipts The liquidity receipt list with the specified IDs.
     */
    function getLpReceipts(
        uint256[] calldata receiptIds
    ) external view returns (LpReceipt[] memory);

    /**
     * @dev Retrieves the pending liquidity information for a specific trading fee rate from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the pending liquidity.
     * @return pendingLiquidity An instance of PendingLiquidity representing the pending liquidity information.
     */
    function pendingLiquidity(int16 tradingFeeRate) external view returns (PendingLiquidity memory);

    /**
     * @dev Retrieves the pending liquidity information for multiple trading fee rates from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the pending liquidity.
     * @return pendingLiquidityBatch An array of PendingLiquidity instances representing the pending liquidity information for each trading fee rate.
     */
    function pendingLiquidityBatch(
        int16[] calldata tradingFeeRates
    ) external view returns (PendingLiquidity[] memory);

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        int16 tradingFeeRate,
        uint256 oracleVersion
    ) external view returns (ClaimableLiquidity memory);

    /**
     * @dev Retrieves the claimable liquidity information for multiple trading fee rates and a specific oracle version from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidityBatch An array of ClaimableLiquidity instances representing the claimable liquidity information for each trading fee rate.
     */
    function claimableLiquidityBatch(
        int16[] calldata tradingFeeRates,
        uint256 oracleVersion
    ) external view returns (ClaimableLiquidity[] memory);

    /**
     * @dev Retrieves the liquidity bin statuses for the caller's liquidity pool.
     * @return statuses An array of LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses() external view returns (LiquidityBinStatus[] memory);

    /**
     * @dev Retrieves the position with the given position ID.
     *      It throws NotExistPosition if the specified position ID does not exist.
     * @param positionId The ID of the position to retrieve.
     * @return position The position with the specified ID.
     */
    function getPosition(uint256 positionId) external view returns (Position memory);

    /**
     * @dev Retrieves multiple positions by their IDs.
     * @param positionIds The IDs of the positions to retrieve.
     * @return positions An array of retrieved positions.
     */
    function getPositions(
        uint256[] calldata positionIds
    ) external view returns (Position[] memory positions);

    /**
     * @dev Retrieves the pending position information for a specific trading fee rate from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the pending position.
     * @return pendingPosition An instance of PendingPosition representing the pending position information.
     */
    function pendingPosition(int16 tradingFeeRate) external view returns (PendingPosition memory);

    /**
     * @dev Retrieves the pending position information for multiple trading fee rates from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the pending position.
     * @return pendingPositionBatch An array of PendingPosition instances representing the pending position information for each trading fee rate.
     */
    function pendingPositionBatch(
        int16[] calldata tradingFeeRates
    ) external view returns (PendingPosition[] memory);

    /**
     * @dev Retrieves the closing position information for a specific trading fee rate from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the closing position.
     * @return closingPosition An instance of PendingPosition representing the closing position information.
     */
    function closingPosition(int16 tradingFeeRate) external view returns (ClosingPosition memory);

    /**
     * @dev Retrieves the closing position information for multiple trading fee rates from the associated LiquidityPool.
     * @param tradingFeeRates The list of trading fee rates for which to retrieve the closing position.
     * @return pendingPositionBatch An array of PendingPosition instances representing the closing position information for each trading fee rate.
     */
    function closingPositionBatch(
        int16[] calldata tradingFeeRates
    ) external view returns (ClosingPosition[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";

/**
 * @title IMarketLiquidate
 * @dev Interface for liquidating and claiming positions in a market.
 */
interface IMarketLiquidate {
    /**
     * @dev Checks if a position is eligible for liquidation.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for liquidation.
     */
    function checkLiquidation(uint256 positionId) external view returns (bool);

    /**
     * @dev Checks if a position is eligible for liquidation.
     * @param positionId The ID of the position to check.
     * @param oracleVersion The oracle version data for liquidation check.
     * @return A boolean indicating if the position is eligible for liquidation.
     */
    function checkLiquidationWithOracleVersion(
        uint256 positionId,
        IOracleProvider.OracleVersion memory oracleVersion
    ) external view returns (bool);

    /**
     * @dev Liquidates a position.
     * @param positionId The ID of the position to liquidate.
     * @param keeper The address of the keeper performing the liquidation.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function liquidate(uint256 positionId, address keeper, uint256 keeperFee) external;

    /**
     * @dev Checks if a position is eligible for claim.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for claim.
     */
    function checkClaimPosition(uint256 positionId) external view returns (bool);

    /**
     * @dev Claims a closed position on behalf of a keeper.
     * @param positionId The ID of the position to claim.
     * @param keeper The address of the keeper claiming the position.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function claimPosition(uint256 positionId, address keeper, uint256 keeperFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IMarketRemoveLiquidity
 * @dev The interface for removing and withdrawing liquidity in a market.
 */
interface IMarketRemoveLiquidity {
    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param clbTokenAmounts An array of clb token amounts to remove as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata clbTokenAmounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IMarketSettle
 * @dev Interface for market settlement.
 */
interface IMarketSettle {
    /**
     * @notice Executes the settlement process for the Chromatic market.
     * @dev This function is called to settle the market.
     * @param feeRates The feeRate list of liquidity bin to settle.
     */
    function settle(int16[] calldata feeRates) external;

    /**
     * @notice Executes the settlement process for the Chromatic market.
     * @dev This function is called to settle the market.
     */
    function settleAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {PositionMode, LiquidityMode, DisplayMode} from "@chromatic-protocol/contracts/core/interfaces/market/Types.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";

/**
 * @title IMarketState
 * @dev Interface for accessing the state of a market contract.
 */
interface IMarketState {
    /**
     * @dev Returns the factory contract for the market.
     * @return The factory contract.
     */
    function factory() external view returns (IChromaticMarketFactory);

    /**
     * @dev Returns the settlement token of the market.
     * @return The settlement token.
     */
    function settlementToken() external view returns (IERC20Metadata);

    /**
     * @dev Returns the oracle provider contract for the market.
     * @return The oracle provider contract.
     */
    function oracleProvider() external view returns (IOracleProvider);

    /**
     * @dev Returns the CLB token contract for the market.
     * @return The CLB token contract.
     */
    function clbToken() external view returns (ICLBToken);

    /**
     * @dev Returns the vault contract for the market.
     * @return The vault contract.
     */
    function vault() external view returns (IChromaticVault);

    /**
     * @notice Returns the protocol fee rate
     * @return The protocol fee rate for the market
     */
    function protocolFeeRate() external view returns (uint16);

    /**
     * @notice Update the new protocol fee rate
     * @param _protocolFeeRate new protocol fee rate for the market
     */
    function updateProtocolFeeRate(uint16 _protocolFeeRate) external;

    /**
     * @notice Returns the position mode
     * @return The position mode for the market
     */
    function positionMode() external view returns (PositionMode);

    /**
     * @notice Update the new position mode
     * @param _positionMode new position mode for the market
     */
    function updatePositionMode(PositionMode _positionMode) external;

    /**
     * @notice Returns the liquidity mode
     * @return The liquidity mode for the market
     */
    function liquidityMode() external view returns (LiquidityMode);

    /**
     * @notice Update the new liquidity mode
     * @param _liquidityMode new liquidity mode for the market
     */
    function updateLiquidityMode(LiquidityMode _liquidityMode) external;

    /**
     * @notice Returns the display mode
     * @return The display mode for the market
     */
    function displayMode() external view returns (DisplayMode);

    /**
     * @notice Update the new display mode
     * @param _displayMode new display mode for the market
     */
    function updateDisplayMode(DisplayMode _displayMode) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ClosePositionInfo} from "@chromatic-protocol/contracts/core/interfaces/market/Types.sol";

/**
 * @title IMarketTradeClosePosition
 * @dev Interface for closing and claiming positions in a market.
 */
interface IMarketTradeClosePosition {
    /**
     * @dev Closes a position in the market.
     * @param positionId The ID of the position to close.
     * @return The closed position.
     */
    function closePosition(uint256 positionId) external returns (ClosePositionInfo memory);

    /**
     * @dev Claims a closed position in the market.
     * @param positionId The ID of the position to claim.
     * @param recipient The address of the recipient of the claimed position.
     * @param data Additional data for the claim callback.
     */
    function claimPosition(
        uint256 positionId,
        address recipient, // EOA or account contract
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {OpenPositionInfo} from "@chromatic-protocol/contracts/core/interfaces/market/Types.sol";

/**
 * @title IMarketTradeOpenPosition
 * @dev Interface for open positions in a market.
 */
interface IMarketTradeOpenPosition {
    /**
     * @dev Opens a new position in the market.
     * @param qty The quantity of the position.
     * @param takerMargin The margin amount provided by the taker.
     * @param makerMargin The margin amount provided by the maker.
     * @param maxAllowableTradingFee The maximum allowable trading fee for the position.
     * @param data Additional data for the position callback.
     * @return The opened position.
     */
    function openPosition(
        int256 qty,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee,
        bytes calldata data
    ) external returns (OpenPositionInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

bytes4 constant CLAIM_USER = "UC";
bytes4 constant CLAIM_KEEPER = "KC";
bytes4 constant CLAIM_TP = "TP";
bytes4 constant CLAIM_SL = "SL";

enum PositionMode {
    Normal,
    OpenDisabled,
    CloseDisabled,
    Suspended
}

enum LiquidityMode {
    Normal,
    AddDisabled,
    RemoveDisabled,
    Suspended
}

enum DisplayMode {
    Normal,
    Suspended,
    Deprecating,
    Deprecated
}

/**
 * @dev The OpenPositionInfo struct represents a opened trading position.
 * @param id The position identifier
 * @param openVersion The version of the oracle when the position was opened
 * @param qty The quantity of the position
 * @param openTimestamp The timestamp when the position was opened
 * @param takerMargin The amount of collateral that a trader must provide
 * @param makerMargin The margin amount provided by the maker.
 * @param tradingFee The trading fee associated with the position.
 */
struct OpenPositionInfo {
    uint256 id;
    uint256 openVersion;
    int256 qty;
    uint256 openTimestamp;
    uint256 takerMargin;
    uint256 makerMargin;
    uint256 tradingFee;
}

/**
 * @dev The ClosePositionInfo struct represents a closed trading position.
 * @param id The position identifier
 * @param closeVersion The version of the oracle when the position was closed
 * @param closeTimestamp The timestamp when the position was closed
 */
struct ClosePositionInfo {
    uint256 id;
    uint256 closeVersion;
    uint256 closeTimestamp;
}

/**
 * @dev The ClaimPositionInfo struct represents a claimed position information.
 * @param id The position identifier
 * @param entryPrice The entry price of the position
 * @param exitPrice The exit price of the position
 * @param realizedPnl The profit or loss of the claimed position.
 * @param interest The interest paid for the claimed position.
 * @param cause The description of being claimed.
 */
struct ClaimPositionInfo {
    uint256 id;
    uint256 entryPrice;
    uint256 exitPrice;
    int256 realizedPnl;
    uint256 interest;
    bytes4 cause;
}

/**
 * @dev Represents a pending position within the LiquidityBin
 * @param openVersion The oracle version when the position was opened.
 * @param totalQty The total quantity of the pending position.
 * @param totalMakerMargin The total maker margin of the pending position.
 * @param totalTakerMargin The total taker margin of the pending position.
 */
struct PendingPosition {
    uint256 openVersion;
    int256 totalQty;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
}

/**
 * @dev Represents the closing position within an LiquidityBin.
 * @param closeVersion The oracle version when the position was closed.
 * @param totalQty The total quantity of the closing position.
 * @param totalEntryAmount The total entry amount of the closing position.
 * @param totalMakerMargin The total maker margin of the closing position.
 * @param totalTakerMargin The total taker margin of the closing position.
 */
struct ClosingPosition {
    uint256 closeVersion;
    int256 totalQty;
    uint256 totalEntryAmount;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
}

/**
 * @dev A struct representing pending liquidity information.
 * @param oracleVersion The oracle version of pending liqudity.
 * @param mintingTokenAmountRequested The amount of settlement tokens requested for minting.
 * @param burningCLBTokenAmountRequested The amount of CLB tokens requested for burning.
 */
struct PendingLiquidity {
    uint256 oracleVersion;
    uint256 mintingTokenAmountRequested;
    uint256 burningCLBTokenAmountRequested;
}

/**
 * @dev A struct representing claimable liquidity information.
 * @param mintingTokenAmountRequested The amount of settlement tokens requested for minting.
 * @param mintingCLBTokenAmount The actual amount of CLB tokens minted.
 * @param burningCLBTokenAmountRequested The amount of CLB tokens requested for burning.
 * @param burningCLBTokenAmount The actual amount of CLB tokens burned.
 * @param burningTokenAmount The amount of settlement tokens equal in value to the burned CLB tokens.
 */
struct ClaimableLiquidity {
    uint256 mintingTokenAmountRequested;
    uint256 mintingCLBTokenAmount;
    uint256 burningCLBTokenAmountRequested;
    uint256 burningCLBTokenAmount;
    uint256 burningTokenAmount;
}

/**
 * @dev A struct representing status of the liquidity bin.
 * @param liquidity The total liquidity amount in the bin
 * @param freeLiquidity The amount of free liquidity available in the bin.
 * @param binValue The current value of the bin.
 * @param tradingFeeRate The trading fee rate for the liquidity.
 */
struct LiquidityBinStatus {
    uint256 liquidity;
    uint256 freeLiquidity;
    uint256 binValue;
    int16 tradingFeeRate;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title ILendingPool
 * @dev Interface for a lending pool contract.
 */
interface ILendingPool {
    /**
     * @notice Emitted when a flash loan is executed.
     * @param sender The address initiating the flash loan.
     * @param recipient The address receiving the flash loan.
     * @param amount The amount of the flash loan.
     * @param paid The amount paid back after the flash loan.
     * @param paidToTakerPool The amount paid to the taker pool after the flash loan.
     * @param paidToMakerPool The amount paid to the maker pool after the flash loan.
     */
    event FlashLoan(
        address indexed sender,
        address indexed recipient,
        uint256 indexed amount,
        uint256 paid,
        uint256 paidToTakerPool,
        uint256 paidToMakerPool
    );

    /**
     * @notice Executes a flash loan.
     * @param token The address of the token for the flash loan.
     * @param amount The amount of the flash loan.
     * @param recipient The address to receive the flash loan.
     * @param data Additional data for the flash loan.
     */
    function flashLoan(
        address token,
        uint256 amount,
        address recipient,
        bytes calldata data
    ) external;

    /**
     * @notice Retrieves the pending share of earnings for a specific bin (subset) of funds in a market.
     * @param market The address of the market.
     * @param settlementToken The settlement token address.
     * @param binBalance The balance of funds in the bin.
     * @return The pending share of earnings for the specified bin.
     */
    function getPendingBinShare(
        address market,
        address settlementToken,
        uint256 binBalance
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IVault
 * @dev Interface for the Vault contract, responsible for managing positions and liquidity.
 */
interface IVault {
    /**
     * @notice Emitted when a position is opened.
     * @param market The address of the market.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    event OnOpenPosition(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    );

    /**
     * @notice Emitted when a position is claimed.
     * @param market The address of the market.
     * @param positionId The ID of the claimed position.
     * @param recipient The address of the recipient of the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The settlement amount received by the recipient.
     */
    event OnClaimPosition(
        address indexed market,
        uint256 indexed positionId,
        address indexed recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    );

    /**
     * @notice Emitted when liquidity is added to the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity added.
     */
    event OnAddLiquidity(address indexed market, uint256 indexed amount);

    /**
     * @notice Emitted when pending liquidity is settled.
     * @param market The address of the market.
     * @param pendingDeposit The amount of pending deposit being settled.
     * @param pendingWithdrawal The amount of pending withdrawal being settled.
     */
    event OnSettlePendingLiquidity(
        address indexed market,
        uint256 indexed pendingDeposit,
        uint256 indexed pendingWithdrawal
    );

    /**
     * @notice Emitted when liquidity is withdrawn from the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity withdrawn.
     * @param recipient The address of the recipient of the withdrawn liquidity.
     */
    event OnWithdrawLiquidity(
        address indexed market,
        uint256 indexed amount,
        address indexed recipient
    );

    /**
     * @notice Emitted when the keeper fee is transferred.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the keeper fee is transferred for a specific market.
     * @param market The address of the market.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(address indexed market, uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the protocol fee is transferred for a specific position.
     * @param market The address of the market.
     * @param positionId The ID of the position.
     * @param amount The amount of the transferred fee.
     */
    event TransferProtocolFee(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed amount
    );

    /**
     * @notice Called when a position is opened by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    function onOpenPosition(
        address settlementToken,
        uint256 positionId,
        uint256 takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    ) external;

    /**
     * @notice Called when a position is claimed by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the claimed position.
     * @param recipient The address that will receive the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The amount to be settled for the position.
     */
    function onClaimPosition(
        address settlementToken,
        uint256 positionId,
        address recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    ) external;

    /**
     * @notice Called when liquidity is added to the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param amount The amount of liquidity being added.
     */
    function onAddLiquidity(address settlementToken, uint256 amount) external;

    /**
     * @notice Called when pending liquidity is settled in the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param pendingDeposit The amount of pending deposits being settled.
     * @param pendingWithdrawal The amount of pending withdrawals being settled.
     */
    function onSettlePendingLiquidity(
        address settlementToken,
        uint256 pendingDeposit,
        uint256 pendingWithdrawal
    ) external;

    /**
     * @notice Called when liquidity is withdrawn from the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param recipient The address that will receive the withdrawn liquidity.
     * @param amount The amount of liquidity to be withdrawn.
     */
    function onWithdrawLiquidity(
        address settlementToken,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Transfers the keeper fee from the market to the specified keeper.
     * @param settlementToken The settlement token address.
     * @param keeper The address of the keeper to receive the fee.
     * @param fee The amount of the fee to transfer as native token.
     * @param margin The margin amount used for the fee payment.
     * @return usedFee The actual settlement token amount of fee used for the transfer.
     */
    function transferKeeperFee(
        address settlementToken,
        address keeper,
        uint256 fee,
        uint256 margin
    ) external returns (uint256 usedFee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev The BinMargin struct represents the margin information for an LP bin.
 * @param tradingFeeRate The trading fee rate associated with the LP bin
 * @param amount The maker margin amount specified for the LP bin
 */
struct BinMargin {
    uint16 tradingFeeRate;
    uint256 amount;
}

using BinMarginLib for BinMargin global;

/**
 * @title BinMarginLib
 * @dev The BinMarginLib library provides functions to operate on BinMargin structs.
 */
library BinMarginLib {
    using Math for uint256;

    uint256 constant TRADING_FEE_RATE_PRECISION = 10000;

    /**
     * @notice Calculates the trading fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _protocolFeeRate The protocol fee rate for the market
     * @return The trading fee amount
     */
    function tradingFee(
        BinMargin memory self,
        uint16 _protocolFeeRate
    ) internal pure returns (uint256) {
        uint256 _tradingFee = self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION);
        return _tradingFee - _protocolFee(_tradingFee, _protocolFeeRate);
    }

    /**
     * @notice Calculates the protocol fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _protocolFeeRate The protocol fee rate for the market
     * @return The protocol fee amount
     */
    function protocolFee(
        BinMargin memory self,
        uint16 _protocolFeeRate
    ) internal pure returns (uint256) {
        return
            _protocolFee(
                self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION),
                _protocolFeeRate
            );
    }

    function _protocolFee(
        uint256 _tradingFee,
        uint16 _protocolFeeRate
    ) private pure returns (uint256) {
        return _tradingFee.mulDiv(_protocolFeeRate, TRADING_FEE_RATE_PRECISION);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title CLBTokenLib
 * @notice Provides utility functions for working with CLB tokens.
 */
library CLBTokenLib {
    using SignedMath for int256;
    using SafeCast for uint256;

    uint256 private constant DIRECTION_PRECISION = 10 ** 10;
    uint16 private constant MIN_FEE_RATE = 1;

    /**
     * @notice Encode the CLB token ID of ERC1155 token type
     * @dev If `tradingFeeRate` is negative, it adds `DIRECTION_PRECISION` to the absolute fee rate.
     *      Otherwise it returns the fee rate directly.
     * @return id The ID of ERC1155 token
     */
    function encodeId(int16 tradingFeeRate) internal pure returns (uint256) {
        bool long = tradingFeeRate > 0;
        return _encodeId(uint16(long ? tradingFeeRate : -tradingFeeRate), long);
    }

    /**
     * @notice Decode the trading fee rate from the CLB token ID of ERC1155 token type
     * @dev If `id` is greater than or equal to `DIRECTION_PRECISION`,
     *      then it substracts `DIRECTION_PRECISION` from `id`
     *      and returns the negation of the substracted value.
     *      Otherwise it returns `id` directly.
     * @return tradingFeeRate The trading fee rate
     */
    function decodeId(uint256 id) internal pure returns (int16 tradingFeeRate) {
        if (id >= DIRECTION_PRECISION) {
            tradingFeeRate = -int16((id - DIRECTION_PRECISION).toUint16());
        } else {
            tradingFeeRate = int16(id.toUint16());
        }
    }

    /**
     * @notice Retrieves the array of supported trading fee rates.
     * @dev This function returns the array of supported trading fee rates,
     *      ranging from the minimum fee rate to the maximum fee rate with step increments.
     * @return tradingFeeRates The array of supported trading fee rates.
     */
    function tradingFeeRates() internal pure returns (uint16[FEE_RATES_LENGTH] memory) {
        // prettier-ignore
        return [
            MIN_FEE_RATE, 2, 3, 4, 5, 6, 7, 8, 9, // 0.01% ~ 0.09%, step 0.01%
            10, 20, 30, 40, 50, 60, 70, 80, 90, // 0.1% ~ 0.9%, step 0.1%
            100, 200, 300, 400, 500, 600, 700, 800, 900, // 1% ~ 9%, step 1%
            1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000 // 10% ~ 50%, step 5%
        ];
    }

    function feeRateIndex(uint16 feeRate) internal pure returns (uint256) {
        require(feeRate >= MIN_FEE_RATE && feeRate <= 5000, Errors.UNSUPPORTED_TRADING_FEE_RATE);

        if (feeRate < 10) {
            // 0..8
            return feeRate - 1;
        } else if (feeRate < 100) {
            // 9..17
            return (feeRate / 10) + 8;
        } else if (feeRate < 1000) {
            // 18..26
            return (feeRate / 100) + 17;
        } else {
            // 27..35
            return (feeRate / 500) + 25;
        }
    }

    function tokenIds() internal pure returns (uint256[] memory) {
        uint16[FEE_RATES_LENGTH] memory feeRates = tradingFeeRates();

        uint256[] memory ids = new uint256[](FEE_RATES_LENGTH * 2);
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            ids[i] = _encodeId(feeRates[i], true);
            ids[i + FEE_RATES_LENGTH] = _encodeId(feeRates[i], false);

            unchecked {
                ++i;
            }
        }

        return ids;
    }

    function _encodeId(uint16 tradingFeeRate, bool long) private pure returns (uint256 id) {
        id = long ? tradingFeeRate : tradingFeeRate + DIRECTION_PRECISION;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

uint256 constant BPS = 10000;
uint256 constant FEE_RATES_LENGTH = 36;
uint256 constant PRICE_PRECISION = 1e18;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * @title Errors
 * @dev This library provides a set of error codes as string constants for handling exceptions and revert messages in the library.
 */
library Errors {
    /**
     * @dev Error code indicating that there is not enough free liquidity available in liquidity pool when open a new poisition.
     */
    string constant NOT_ENOUGH_FREE_LIQUIDITY = "NEFL";

    /**
     * @dev Error code indicating that the specified amount is too small when add liquidity to each bin.
     */
    string constant TOO_SMALL_AMOUNT = "TSA";

    /**
     * @dev Error code indicating that the provided oracle version is invalid or unsupported.
     */
    string constant INVALID_ORACLE_VERSION = "IOV";

    /**
     * @dev Error code indicating that the specified value exceeds the allowed margin range when claim a position.
     */
    string constant EXCEED_MARGIN_RANGE = "EMR";

    /**
     * @dev Error code indicating that the provided trading fee rate is not supported.
     */
    string constant UNSUPPORTED_TRADING_FEE_RATE = "UTFR";

    /**
     * @dev Error code indicating that the oracle provider is already registered.
     */
    string constant ALREADY_REGISTERED_ORACLE_PROVIDER = "ARO";

    /**
     * @dev Error code indicating that the settlement token is already registered.
     */
    string constant ALREADY_REGISTERED_TOKEN = "ART";

    /**
     * @dev Error code indicating that the settlement token is not registered.
     */
    string constant UNREGISTERED_TOKEN = "URT";

    /**
     * @dev Error code indicating that the interest rate has not been initialized.
     */
    string constant INTEREST_RATE_NOT_INITIALIZED = "IRNI";

    /**
     * @dev Error code indicating that the provided interest rate exceeds the maximum allowed rate.
     */
    string constant INTEREST_RATE_OVERFLOW = "IROF";

    /**
     * @dev Error code indicating that the provided timestamp for an interest rate is in the past.
     */
    string constant INTEREST_RATE_PAST_TIMESTAMP = "IRPT";

    /**
     * @dev Error code indicating that the provided interest rate record cannot be appended to the existing array.
     */
    string constant INTEREST_RATE_NOT_APPENDABLE = "IRNA";

    /**
     * @dev Error code indicating that an interest rate has already been applied and cannot be modified further.
     */
    string constant INTEREST_RATE_ALREADY_APPLIED = "IRAA";

    /**
     * @dev Error code indicating that the position is unsettled.
     */
    string constant UNSETTLED_POSITION = "USP";

    /**
     * @dev Error code indicating that the position quantity is invalid.
     */
    string constant INVALID_POSITION_QTY = "IPQ";

    /**
     * @dev Error code indicating that the oracle price is not positive.
     */
    string constant NOT_POSITIVE_PRICE = "NPP";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title InterestRate
 * @notice Provides functions for managing interest rates.
 * @dev The library allows for the initialization, appending, and removal of interest rate records,
 *      as well as calculating interest based on these records.
 */
library InterestRate {
    using Math for uint256;

    /**
     * @dev Record type
     * @param annualRateBPS Annual interest rate in BPS
     * @param beginTimestamp Timestamp when the interest rate becomes effective
     */
    struct Record {
        uint256 annualRateBPS;
        uint256 beginTimestamp;
    }

    uint256 private constant MAX_RATE_BPS = BPS; // max interest rate is 100%
    uint256 private constant YEAR = 365 * 24 * 3600;

    /**
     * @dev Ensure that the interest rate records have been initialized before certain functions can be called.
     *      It checks whether the length of the Record array is greater than 0.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty (it indicates that the interest rate has not been initialized).
     */
    modifier initialized(Record[] storage self) {
        require(self.length != 0, Errors.INTEREST_RATE_NOT_INITIALIZED);
        _;
    }

    /**
     * @notice Initialize the interest rate records.
     * @param self The stored record array
     * @param initialInterestRate The initial interest rate
     */
    function initialize(Record[] storage self, uint256 initialInterestRate) internal {
        self.push(Record({annualRateBPS: initialInterestRate, beginTimestamp: 0}));
    }

    /**
     * @notice Add a new interest rate record to the array.
     * @dev Annual rate is not greater than the maximum rate and that the begin timestamp is in the future,
     *      and the new record's begin timestamp is greater than the previous record's timestamp.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     *      Throws an error with the code `Errors.INTEREST_RATE_OVERFLOW` if the rate exceed the maximum allowed rate (100%).
     *      Throws an error with the code `Errors.INTEREST_RATE_PAST_TIMESTAMP` if the timestamp is in the past, ensuring that the interest rate period has not already started.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_APPENDABLE` if the timestamp is greater than the last recorded timestamp, ensuring that the new record is appended in chronological order.
     * @param self The stored record array
     * @param annualRateBPS The annual interest rate in BPS
     * @param beginTimestamp Begin timestamp of this record
     */
    function appendRecord(
        Record[] storage self,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) internal initialized(self) {
        require(annualRateBPS <= MAX_RATE_BPS, Errors.INTEREST_RATE_OVERFLOW);
        //slither-disable-next-line timestamp
        require(beginTimestamp > block.timestamp, Errors.INTEREST_RATE_PAST_TIMESTAMP);

        Record memory lastRecord = self[self.length - 1];
        require(beginTimestamp > lastRecord.beginTimestamp, Errors.INTEREST_RATE_NOT_APPENDABLE);

        self.push(Record({annualRateBPS: annualRateBPS, beginTimestamp: beginTimestamp}));
    }

    /**
     * @notice Remove the last interest rate record from the array.
     * @dev The current time must be less than the begin timestamp of the last record.
     *      If the array has only one record, it returns false along with an empty record.
     *      Otherwise, it removes the last record from the array and returns true along with the removed record.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     *      Throws an error with the code `Errors.INTEREST_RATE_ALREADY_APPLIED` if the `beginTimestamp` of the last record is not in the future.
     * @param self The stored record array
     * @return removed Whether the last record is removed
     * @return record The removed record
     */
    function removeLastRecord(
        Record[] storage self
    ) internal initialized(self) returns (bool removed, Record memory record) {
        if (self.length <= 1) {
            // empty
            return (false, Record(0, 0));
        }

        Record memory lastRecord = self[self.length - 1];
        //slither-disable-next-line timestamp
        require(block.timestamp < lastRecord.beginTimestamp, Errors.INTEREST_RATE_ALREADY_APPLIED);

        self.pop();

        return (true, lastRecord);
    }

    /**
     * @notice Find the interest rate record that applies to a given timestamp.
     * @dev It iterates through the array from the end to the beginning
     *      and returns the first record with a begin timestamp less than or equal to the provided timestamp.
     *      Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     * @param self The stored record array
     * @param timestamp Given timestamp
     * @return interestRate The record which is found
     * @return index The index of record
     */
    function findRecordAt(
        Record[] storage self,
        uint256 timestamp
    ) internal view initialized(self) returns (Record memory interestRate, uint256 index) {
        for (uint256 i = self.length; i != 0; ) {
            unchecked {
                index = i - 1;
            }
            interestRate = self[index];

            if (interestRate.beginTimestamp <= timestamp) {
                return (interestRate, index);
            }

            unchecked {
                i--;
            }
        }

        return (self[0], 0); // empty result (this line is not reachable)
    }

    /**
     * @notice Calculate the interest
     * @dev Throws an error with the code `Errors.INTEREST_RATE_NOT_INITIALIZED` if the array is empty.
     * @param self The stored record array
     * @param amount Token amount
     * @param from Begin timestamp (inclusive)
     * @param to End timestamp (exclusive)
     */
    function calculateInterest(
        Record[] storage self,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) internal view initialized(self) returns (uint256) {
        if (from >= to) {
            return 0;
        }

        uint256 interest = 0;

        uint256 endTimestamp = type(uint256).max;
        for (uint256 idx = self.length; idx != 0; ) {
            Record memory record = self[idx - 1];
            if (endTimestamp <= from) {
                break;
            }

            interest += _interest(
                amount,
                record.annualRateBPS,
                Math.min(to, endTimestamp) - Math.max(from, record.beginTimestamp)
            );
            endTimestamp = record.beginTimestamp;

            unchecked {
                idx--;
            }
        }
        return interest;
    }

    function _interest(
        uint256 amount,
        uint256 rateBPS, // annual rate
        uint256 period // in seconds
    ) private pure returns (uint256) {
        return amount.mulDiv(rateBPS * period, BPS * YEAR, Math.Rounding.Up);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";

/**
 * @dev Represents the context information required for LP bin operations.
 * @param oracleProvider The Oracle Provider contract used for price feed
 * @param interestCalculator The Interest Calculator contract used for interest calculations
 * @param vault The Chromatic Vault contract responsible for managing liquidity and margin
 * @param clbToken The CLB token contract that represents LP ownership in the pool
 * @param market The address of market contract
 * @param settlementToken The address of the settlement token used in the market
 * @param tokenPrecision The precision of the settlement token used in the market
 * @param _currentVersionCache Cached instance of the current oracle version
 */
struct LpContext {
    IOracleProvider oracleProvider;
    IInterestCalculator interestCalculator;
    IChromaticVault vault;
    ICLBToken clbToken;
    address market;
    address settlementToken;
    uint256 tokenPrecision;
    IOracleProvider.OracleVersion _currentVersionCache;
}

using LpContextLib for LpContext global;

/**
 * @title LpContextLib
 * @notice Provides functions that operate on the `LpContext` struct
 */
library LpContextLib {
    /**
     * @notice Syncs the oracle version used by the market.
     * @param self The memory instance of `LpContext` struct
     */
    function syncOracleVersion(LpContext memory self) internal {
        self._currentVersionCache = self.oracleProvider.sync();
    }

    /**
     * @notice Retrieves the current oracle version used by the market
     * @dev If the `_currentVersionCache` has been initialized, then returns it.
     *      If not, it calls the `currentVersion` function on the `oracleProvider of the market
     *      to fetch the current version and stores it in the cache,
     *      and then returns the current version.
     * @param self The memory instance of `LpContext` struct
     * @return OracleVersion The current oracle version
     */
    function currentOracleVersion(
        LpContext memory self
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == 0) {
            //slither-disable-next-line calls-loop
            self._currentVersionCache = self.oracleProvider.currentVersion();
        }

        return self._currentVersionCache;
    }

    /**
     * @notice Retrieves the oracle version at a specific version number
     * @dev If the `_currentVersionCache` matches the requested version, then returns it.
     *      Otherwise, it calls the `atVersion` function on the `oracleProvider` of the market
     *      to fetch the desired version.
     * @param self The memory instance of `LpContext` struct
     * @param version The requested version number
     * @return OracleVersion The oracle version at the requested version number
     */
    function oracleVersionAt(
        LpContext memory self,
        uint256 version
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == version) {
            return self._currentVersionCache;
        }
        return self.oracleProvider.atVersion(version);
    }

    /**
     * @notice Calculates the interest accrued for a given amount of settlement tokens
               within a specified time range.
     * @dev This function internally calls the `calculateInterest` function on the `interestCalculator` contract.
     * @param self The memory instance of the `LpContext` struct.
     * @param amount The amount of settlement tokens for which the interest needs to be calculated.
     * @param from The starting timestamp of the time range (inclusive).
     * @param to The ending timestamp of the time range (exclusive).
     * @return The accrued interest as a `uint256` value.
     */
    function calculateInterest(
        LpContext memory self,
        uint256 amount,
        uint256 from,
        uint256 to
    ) internal view returns (uint256) {
        //slither-disable-next-line calls-loop
        return
            amount == 0 || from >= to
                ? 0
                : self.interestCalculator.calculateInterest(self.settlementToken, amount, from, to);
    }

    /**
     * @notice Checks if an oracle version is in the past.
     * @param self The memory instance of the `LpContext` struct.
     * @param oracleVersion The oracle version to check.
     * @return A boolean value indicating whether the oracle version is in the past.
     */
    function isPastVersion(
        LpContext memory self,
        uint256 oracleVersion
    ) internal view returns (bool) {
        return oracleVersion != 0 && oracleVersion < self.currentOracleVersion().version;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";

/**
 * @dev The LpAction enum represents the types of LP actions that can be performed.
 */
enum LpAction {
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY
}

/**
 * @dev The LpReceipt struct represents a receipt of an LP action performed.
 * @param id An identifier for the receipt
 * @param oracleVersion The oracle version associated with the action
 * @param amount The amount involved in the action,
 *        when the action is `ADD_LIQUIDITY`, this value represents the amount of settlement tokens
 *        when the action is `REMOVE_LIQUIDITY`, this value represents the amount of CLB tokens
 * @param recipient The address of the recipient of the action
 * @param action An enumeration representing the type of LP action performed (ADD_LIQUIDITY or REMOVE_LIQUIDITY)
 * @param tradingFeeRate The trading fee rate associated with the LP action
 */
struct LpReceipt {
    uint256 id;
    uint256 oracleVersion;
    uint256 amount;
    address recipient;
    LpAction action;
    int16 tradingFeeRate;
}

using LpReceiptLib for LpReceipt global;

/**
 * @title LpReceiptLib
 * @notice Provides functions that operate on the `LpReceipt` struct
 */
library LpReceiptLib {
    /**
     * @notice Computes the ID of the CLBToken contract based on the trading fee rate.
     * @param self The LpReceipt struct.
     * @return The ID of the CLBToken contract.
     */
    function clbTokenId(LpReceipt memory self) internal pure returns (uint256) {
        return CLBTokenLib.encodeId(self.tradingFeeRate);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";

/**
 * @dev The Position struct represents a trading position.
 * @param id The position identifier
 * @param openVersion The version of the oracle when the position was opened
 * @param closeVersion The version of the oracle when the position was closed
 * @param qty The quantity of the position
 * @param openTimestamp The timestamp when the position was opened
 * @param closeTimestamp The timestamp when the position was closed
 * @param takerMargin The amount of collateral that a trader must provide
 * @param owner The owner of the position, usually it is the account address of trader
 * @param liquidator The liquidator contract address
 * @param _binMargins The bin margins for the position, it represents the amount of collateral for each bin
 * @param _protocolFeeRate The protocol fee rate for the market
 */
struct Position {
    uint256 id;
    uint256 openVersion;
    uint256 closeVersion;
    int256 qty;
    uint256 openTimestamp;
    uint256 closeTimestamp;
    uint256 takerMargin;
    address owner;
    address liquidator;
    uint16 _protocolFeeRate;
    BinMargin[] _binMargins;
}

using PositionLib for Position global;

/**
 * @title PositionLib
 * @notice Provides functions that operate on the `Position` struct
 */
library PositionLib {
    // using Math for uint256;
    // using SafeCast for uint256;
    // using SignedMath for int256;

    /**
     * @notice Calculates the entry price of the position based on the position's open oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's open oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return uint256 The entry price
     */
    function entryPrice(
        Position memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.openVersion);
    }

    /**
     * @notice Calculates the exit price of the position based on the position's close oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's close oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return uint256 The exit price
     */
    function exitPrice(Position memory self, LpContext memory ctx) internal view returns (uint256) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.closeVersion);
    }

    /**
     * @notice Calculates the profit or loss of the position based on the close oracle version and the qty
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return int256 The profit or loss
     */
    function pnl(Position memory self, LpContext memory ctx) internal view returns (int256) {
        return
            self.closeVersion > self.openVersion
                ? PositionUtil.pnl(self.qty, self.entryPrice(ctx), self.exitPrice(ctx))
                : int256(0);
    }

    /**
     * @notice Calculates the total margin required for the makers of the position
     * @dev The maker margin is calculated by summing up the amounts of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return margin The maker margin
     */
    function makerMargin(Position memory self) internal pure returns (uint256 margin) {
        for (uint256 i; i < self._binMargins.length; ) {
            margin += self._binMargins[i].amount;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates the total trading fee for the position
     * @dev The trading fee is calculated by summing up the trading fees of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return fee The trading fee
     */
    function tradingFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].tradingFee(self._protocolFeeRate);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Calculates the total protocol fee for a position.
     * @param self The Position struct representing the position.
     * @return fee The total protocol fee amount.
     */
    function protocolFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].protocolFee(self._protocolFeeRate);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns an array of BinMargin instances
     *         representing the bin margins for the position
     * @param self The memory instance of the `Position` struct
     * @return margins The bin margins for the position
     */
    function binMargins(Position memory self) internal pure returns (BinMargin[] memory margins) {
        margins = self._binMargins;
    }

    /**
     * @notice Sets the `_binMargins` array for the position
     * @param self The memory instance of the `Position` struct
     * @param margins The bin margins for the position
     */
    function setBinMargins(Position memory self, BinMargin[] memory margins) internal pure {
        self._binMargins = margins;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PRICE_PRECISION} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title PositionUtil
 * @notice Provides utility functions for managing positions
 */
library PositionUtil {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;

    /**
     * @notice Returns next oracle version to settle
     * @dev It adds 1 to the `oracleVersion`
     *      and ensures that the `oracleVersion` is greater than 0 using a require statement.
     *      Throws an error with the code `Errors.INVALID_ORACLE_VERSION` if the `oracleVersion` is not valid.
     * @param oracleVersion Input oracle version
     * @return uint256 Next oracle version to settle
     */
    function settleVersion(uint256 oracleVersion) internal pure returns (uint256) {
        require(oracleVersion != 0, Errors.INVALID_ORACLE_VERSION);
        return oracleVersion + 1;
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calls another overloaded `settlePrice` function
     *      with an additional `OracleVersion` parameter,
     *      passing the `currentVersion` obtained from the `provider`
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @return uint256 The calculated price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion
    ) internal view returns (uint256) {
        return settlePrice(provider, oracleVersion, provider.currentVersion());
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calculates the price by considering the `settleVersion`
     *      and the `currentVersion` obtained from the `IOracleProvider`.
     *      It ensures that the settle version is not greater than the current version;
     *      otherwise, it triggers an error with the message `Errors.UNSETTLED_POSITION`.
     *      It retrieves the corresponding `OracleVersion` using `atVersion` from the `IOracleProvider`,
     *      and then calls `oraclePrice` to obtain the price.
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @param currentVersion The current oracle version
     * @return uint256 The calculated entry price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion,
        IOracleProvider.OracleVersion memory currentVersion
    ) internal view returns (uint256) {
        uint256 _settleVersion = settleVersion(oracleVersion);
        require(_settleVersion <= currentVersion.version, Errors.UNSETTLED_POSITION);

        //slither-disable-next-line calls-loop
        IOracleProvider.OracleVersion memory _oracleVersion = _settleVersion ==
            currentVersion.version
            ? currentVersion
            : provider.atVersion(_settleVersion);
        return oraclePrice(_oracleVersion);
    }

    /**
     * @notice Extracts the price value from an `OracleVersion` struct
     * @dev If the price is not positive value, it triggers an error with the message `Errors.NOT_POSITIVE_PRICE`.
     * @param oracleVersion The memory instance of `OracleVersion` struct
     * @return uint256 The price value of `oracleVersion`
     */
    function oraclePrice(
        IOracleProvider.OracleVersion memory oracleVersion
    ) internal pure returns (uint256) {
        require(oracleVersion.price > 0, Errors.NOT_POSITIVE_PRICE);
        return oracleVersion.price.abs();
    }

    /**
     * @notice Calculates the profit or loss (PnL) for a position based on the quantity, entry price, and exit price
     * @dev It first calculates the price difference (`delta`) between the exit price and the entry price.
     *      If the quantity is negative, indicating short position, it adjusts the `delta` to reflect a negative change.
     *      The function then calculates the absolute PnL by multiplying the absolute value of the quantity
     *          with the absolute value of the `delta`, divided by the entry price.
     *      Finally, if `delta` is negative, indicating a loss, the absolute PnL is negated to represent a negative value.
     * @param qty The quantity of the position
     * @param _entryPrice The entry price of the position
     * @param _exitPrice The exit price of the position
     * @return int256 The profit or loss
     */
    function pnl(
        int256 qty, // as token precision
        uint256 _entryPrice,
        uint256 _exitPrice
    ) internal pure returns (int256) {
        if (qty == 0 || _entryPrice == _exitPrice) return 0;

        int256 delta = _exitPrice > _entryPrice
            ? (_exitPrice - _entryPrice).toInt256()
            : -(_entryPrice - _exitPrice).toInt256();
        if (qty < 0) delta *= -1;

        int256 absPnl = qty.abs().mulDiv(delta.abs(), _entryPrice).toInt256();

        return delta < 0 ? -absPnl : absPnl;
    }

    /**
     * @notice Verifies the validity of a position quantity added to the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the added quantity are same or zero.
     *      If the condition is not met, it triggers an error with the message `Errors.INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's pending position
     * @param addedQty The position quantity added
     */
    function checkAddPositionQty(int256 currentQty, int256 addedQty) internal pure {
        require(
            !((currentQty > 0 && addedQty <= 0) || (currentQty < 0 && addedQty >= 0)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Verifies the validity of a position quantity removed from the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the removed quantity are same or zero,
     *      and the absolute removed quantity is not greater than the absolute current quantity.
     *      If the condition is not met, it triggers an error with the message `Errors.INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's position
     * @param removeQty The position quantity removed
     */
    function checkRemovePositionQty(int256 currentQty, int256 removeQty) internal pure {
        require(
            !((currentQty == 0) ||
                (removeQty == 0) ||
                (currentQty > 0 && removeQty > currentQty) ||
                (currentQty < 0 && removeQty < currentQty)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Calculates the transaction amount based on the quantity and price
     * @param qty The quantity of the position
     * @param price The price of the position
     * @return uint256 The transaction amount
     */
    function transactionAmount(int256 qty, uint256 price) internal pure returns (uint256) {
        return qty.abs().mulDiv(price, PRICE_PRECISION);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * @dev The OracleProviderProperties struct represents properties of the oracle provider.
 * @param minTakeProfitBPS The minimum take-profit basis points.
 * @param maxTakeProfitBPS The maximum take-profit basis points.
 * @param leverageLevel The leverage level of the oracle provider.
 */
struct OracleProviderProperties {
    uint32 minTakeProfitBPS;
    uint32 maxTakeProfitBPS;
    uint8 leverageLevel;
}

using OracleProviderPropertiesLib for OracleProviderProperties global;

library OracleProviderPropertiesLib {
    function checkValidLeverageLevel(uint8 leverageLevel) internal pure returns (bool) {
        return leverageLevel <= 3;
    }

    function maxAllowableLeverage(
        OracleProviderProperties memory self
    ) internal pure returns (uint256 leverage) {
        uint8 level = self.leverageLevel;
        assembly {
            switch level
            case 0 {
                leverage := 10
            }
            case 1 {
                leverage := 20
            }
            case 2 {
                leverage := 50
            }
            case 3 {
                leverage := 100
            }
            default {
                leverage := 0
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IOracleProvider is IERC165 {
    /// @dev Error for invalid oracle round
    error InvalidOracleRound();

    /**
     * @dev A singular oracle version with its corresponding data
     * @param version The iterative version
     * @param timestamp the timestamp of the oracle update
     * @param price The oracle price of the corresponding version
     */
    struct OracleVersion {
        uint256 version;
        uint256 timestamp;
        int256 price;
    }

    /**
     * @notice Checks for a new price and updates the internal phase annotation state accordingly
     * @dev `sync` is expected to be called soon after a phase update occurs in the underlying proxy.
     *      Phase updates should be detected using off-chain mechanism and should trigger a `sync` call
     *      This is feasible in the short term due to how infrequent phase updates are, but phase update
     *      and roundCount detection should eventually be implemented at the contract level.
     *      Reverts if there is more than 1 phase to update in a single sync because we currently cannot
     *      determine the startingRoundId for the intermediary phase.
     * @return The current oracle version after sync
     */
    function sync() external returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @return oracleVersion Current oracle version
     */
    function currentVersion() external view returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @param version The version of which to lookup
     * @return oracleVersion Oracle version at version `version`
     */
    function atVersion(uint256 version) external view returns (OracleVersion memory);

    /**
     * @notice Retrieves the description of the Oracle Provider.
     * @return A string representing the description of the Oracle Provider.
     */
    function description() external view returns (string memory);

    /**
     * @notice Retrieves the name of the Oracle Provider.
     * @return A string representing the name of the Oracle Provider.
     */
    function oracleProviderName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {ChromaticLPReceipt, ChromaticLPAction} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {ChromaticLPStorage} from "~/lp/base/ChromaticLPStorage.sol";
import {ValueInfo} from "~/lp/interfaces/IChromaticLPLens.sol";
import {TrimAddress} from "~/lp/libraries/TrimAddress.sol";
import {LPState} from "~/lp/libraries/LPState.sol";
import {LPConfig} from "~/lp/libraries/LPConfig.sol";
import {IChromaticLP} from "~/lp/interfaces/IChromaticLP.sol";
import {IChromaticLPLens} from "~/lp/interfaces/IChromaticLPLens.sol";
import {IChromaticLPLiquidity} from "~/lp/interfaces/IChromaticLPLiquidity.sol";
import {IChromaticLPConfigLens} from "~/lp/interfaces/IChromaticLPConfigLens.sol";
import {IChromaticLPMeta} from "~/lp/interfaces/IChromaticLPMeta.sol";
import {IChromaticLPAdmin} from "~/lp/interfaces/IChromaticLPAdmin.sol";
import {IChromaticLPAutomate} from "~/lp/interfaces/IChromaticLPAutomate.sol";
import {IAutomateLP} from "~/lp/interfaces/IAutomateLP.sol";
import {LPState} from "~/lp/libraries/LPState.sol";
import {LPStateValueLib} from "~/lp/libraries/LPStateValue.sol";
import {LPStateViewLib} from "~/lp/libraries/LPStateView.sol";
import {LPStateSetupLib} from "~/lp/libraries/LPStateSetup.sol";
import {LPConfigLib, LPConfig, AllocationStatus} from "~/lp/libraries/LPConfig.sol";
import {BPS} from "~/lp/libraries/Constants.sol";
import {Errors} from "~/lp/libraries/Errors.sol";

abstract contract ChromaticLPBase is ChromaticLPStorage, IChromaticLP {
    using Math for uint256;
    using LPStateViewLib for LPState;
    using LPStateValueLib for LPState;
    using LPStateSetupLib for LPState;
    using LPConfigLib for LPConfig;

    function _initialize(
        LPMeta memory meta,
        ConfigParam memory config,
        int16[] memory _feeRates,
        uint16[] memory _distributionRates,
        IAutomateLP automate,
        address _logicAddress
    ) internal {
        _setLogicAddress(_logicAddress);
        _setAutomateLP(automate);

        _validateConfig(
            config.utilizationTargetBPS,
            config.rebalanceBPS,
            _feeRates,
            _distributionRates
        );
        if (config.automationFeeReserved > config.minHoldingValueToRebalance) {
            revert InvalidMinHoldingValueToRebalance();
        }

        emit SetLpName(meta.lpName);
        emit SetLpTag(meta.tag);

        s_meta = LPMeta({lpName: meta.lpName, tag: meta.tag});

        s_config = LPConfig({
            utilizationTargetBPS: config.utilizationTargetBPS,
            rebalanceBPS: config.rebalanceBPS,
            rebalanceCheckingInterval: config.rebalanceCheckingInterval,
            automationFeeReserved: config.automationFeeReserved,
            minHoldingValueToRebalance: config.minHoldingValueToRebalance
        });
        s_state.initialize(config.market, _feeRates, _distributionRates);
    }

    function _validateConfig(
        uint16 _utilizationTargetBPS,
        uint16 _rebalanceBPS,
        int16[] memory _feeRates,
        uint16[] memory _distributionRates
    ) private pure {
        if (_utilizationTargetBPS > BPS) revert InvalidUtilizationTarget(_utilizationTargetBPS);
        if (_feeRates.length != _distributionRates.length)
            revert NotMatchDistributionLength(_feeRates.length, _distributionRates.length);

        if (_utilizationTargetBPS <= _rebalanceBPS) revert InvalidRebalanceBPS();
    }

    /**
     * @inheritdoc ERC20
     */
    function name() public view virtual override returns (string memory) {
        return string(abi.encodePacked("ChromaticLP - ", _tokenSymbol(), " - ", _indexName()));
    }

    /**
     * @inheritdoc ERC20
     */
    function symbol() public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "CLP-",
                    TrimAddress.trimAddress(address(s_state.market), 4),
                    "-",
                    bytes(s_meta.tag)[0]
                )
            );
    }

    function _tokenSymbol() internal view returns (string memory) {
        return s_state.settlementToken().symbol();
    }

    function _indexName() internal view returns (string memory) {
        return s_state.market.oracleProvider().description();
    }

    /**
     * @inheritdoc IChromaticLPAutomate
     */
    function checkRebalance() external view returns (bool) {
        if (s_state.holdingValue() < s_config.minHoldingValueToRebalance) {
            return false;
        }
        (uint256 currentUtility, uint256 value) = s_state.utilizationInfo();
        if (value == 0) return false;

        AllocationStatus status = s_config.allocationStatus(currentUtility);

        if (status == AllocationStatus.OverUtilized) {
            // estimate this remove rebalancing is meaningful for paying automationFee
            if (_estimateRebalanceRemoveValue(currentUtility) >= s_config.automationFeeReserved) {
                return true;
            }
        } else if (status == AllocationStatus.UnderUtilized) {
            // check if it could be settled by automation
            if (_estimateRebalanceAddAmount(currentUtility) >= estimateMinAddLiquidityAmount()) {
                return true;
            }
        }
        return false;
    }

    /**
     * @inheritdoc IChromaticLPAutomate
     */
    function checkSettle(uint256 receiptId) external view returns (bool) {
        if (s_state.holdingValue() < s_config.automationFeeReserved) {
            return false;
        }
        return _checkSettle(receiptId);
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function checkSettleByUser(uint256 receiptId) external view returns (bool) {
        return _checkSettle(receiptId);
    }

    function _checkSettle(uint256 receiptId) internal view returns (bool) {
        ChromaticLPReceipt memory receipt = s_state.getReceipt(receiptId);
        if (receipt.needSettle && receipt.oracleVersion < s_state.oracleVersion()) {
            return true;
        }
        return false;
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function utilization() public view override returns (uint16 currentUtility) {
        //slither-disable-next-line unused-return
        (currentUtility, ) = s_state.utilizationInfo();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function totalValue() public view override returns (uint256 value) {
        value = s_state.totalValue();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function valueOfSupply() public view override returns (uint256 value) {
        value = s_state.valueOfSupply();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function valueInfo() public view override returns (ValueInfo memory info) {
        return s_state.valueInfo();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function holdingValue() public view override returns (uint256) {
        return s_state.holdingValue();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function pendingValue() public view override returns (uint256) {
        return s_state.pendingValue();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function holdingClbValue() public view override returns (uint256 value) {
        return s_state.holdingClbValue();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function pendingClbValue() public view override returns (uint256 value) {
        return s_state.pendingClbValue();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function totalClbValue() public view override returns (uint256 value) {
        return s_state.totalClbValue();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function feeRates() external view override returns (int16[] memory) {
        return s_state.feeRates;
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function clbTokenIds() external view override returns (uint256[] memory) {
        return s_state.clbTokenIds;
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function clbTokenBalances() public view override returns (uint256[] memory _clbTokenBalances) {
        return s_state.clbTokenBalances();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function clbTokenValues() public view override returns (uint256[] memory _clbTokenBalances) {
        return s_state.clbTokenValues();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function pendingRemoveClbBalances() public view override returns (uint256[] memory) {
        return s_state.pendingRemoveClbBalances();
    }

    /**
     * @inheritdoc IChromaticLPLens
     */
    function longShortInfo() external view returns (int8) {
        return s_state.longShortInfo();
    }

    /**
     * @inheritdoc IChromaticLPMeta
     */
    function setLpName(string memory newName) external onlyDao {
        emit SetLpName(newName);
        s_meta.lpName = newName;
    }

    /**
     * @inheritdoc IChromaticLPMeta
     */
    function setLpTag(string memory tag) external onlyDao {
        emit SetLpTag(tag);
        s_meta.tag = tag;
    }

    /**
     * @inheritdoc IChromaticLPConfigLens
     */
    function utilizationTargetBPS() external view returns (uint256) {
        return s_config.utilizationTargetBPS;
    }

    /**
     * @inheritdoc IChromaticLPConfigLens
     */
    function rebalanceBPS() external view returns (uint256) {
        return s_config.rebalanceBPS;
    }

    /**
     * @inheritdoc IChromaticLPConfigLens
     */
    function rebalanceCheckingInterval() external view returns (uint256) {
        return s_config.rebalanceCheckingInterval;
    }

    /**
     * @inheritdoc IChromaticLPConfigLens
     */
    function minHoldingValueToRebalance() external view returns (uint256) {
        return s_config.minHoldingValueToRebalance;
    }

    /**
     * @inheritdoc IChromaticLPConfigLens
     */
    function automationFeeReserved() external view returns (uint256) {
        return s_config.automationFeeReserved;
    }

    /**
     * @inheritdoc IChromaticLPConfigLens
     */
    function distributionRates() external view returns (uint16[] memory rates) {
        rates = new uint16[](s_state.binCount());
        for (uint256 i; i < s_state.binCount(); ) {
            rates[i] = s_state.distributionRates[s_state.feeRates[i]];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function estimateMinAddLiquidityAmount() public view returns (uint256) {
        return
            s_config.automationFeeReserved +
            s_config.automationFeeReserved.mulDiv(BPS, BPS - s_config.utilizationTargetBPS);
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function estimateMinRemoveLiquidityAmount() public view returns (uint256) {
        if (holdingValue() == 0 || totalSupply() == 0) {
            return s_config.automationFeeReserved.mulDiv(BPS, BPS - s_config.utilizationTargetBPS);
        } else {
            return s_config.automationFeeReserved.mulDiv(totalSupply(), holdingValue());
        }
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function setSuspendMode(uint8 mode) external onlyDao {
        _setSuspendMode(mode);
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function suspendMode() external view returns (uint8) {
        return _suspendMode();
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function dao() public view override returns (address) {
        return s_state.market.factory().dao();
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function upgradeTo(address newLogicAddress, bytes calldata data) external onlyDao {
        if (!isContract(newLogicAddress)) revert UpgradeFailedNotContractAddress();
        (bool success, ) = newLogicAddress.delegatecall(
            abi.encodeWithSignature("onUpgrade(bytes)", data)
        );
        if (!success) revert UpgradeFailed();
        emit Upgraded(s_logicAddress, newLogicAddress);
        _setLogicAddress(newLogicAddress);
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function logicAddress() external view returns (address) {
        return s_logicAddress;
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IChromaticLiquidityCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticLiquidityCallback.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {IChromaticLP} from "~/lp/interfaces/IChromaticLP.sol";
import {ChromaticLPReceipt, ChromaticLPAction} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {ChromaticLPStorage} from "~/lp/base/ChromaticLPStorage.sol";
import {ValueInfo} from "~/lp/interfaces/IChromaticLPLens.sol";
import {LPState} from "~/lp/libraries/LPState.sol";

import {LPStateValueLib} from "~/lp/libraries/LPStateValue.sol";
import {LPStateViewLib} from "~/lp/libraries/LPStateView.sol";
import {LPStateLogicLib, AddLiquidityParam, RemoveLiquidityParam} from "~/lp/libraries/LPStateLogic.sol";
import {LPConfigLib, LPConfig, AllocationStatus} from "~/lp/libraries/LPConfig.sol";
import {IAutomateLP} from "~/lp/interfaces/IAutomateLP.sol";
import {IChromaticLPCallback} from "~/lp/interfaces/IChromaticLPCallback.sol";
import {REBALANCE_ID} from "~/lp/libraries/LPState.sol";
import {IChromaticLPLogic} from "~/lp/interfaces/IChromaticLPLogic.sol";

import {BPS} from "~/lp/libraries/Constants.sol";
import {Errors} from "~/lp/libraries/Errors.sol";

abstract contract ChromaticLPLogicBase is ChromaticLPStorage, IChromaticLPLogic {
    using Math for uint256;

    using LPStateValueLib for LPState;
    using LPStateViewLib for LPState;
    using LPStateLogicLib for LPState;
    using LPConfigLib for LPConfig;

    bytes32 public version;
    address internal immutable _this;

    /**
     * @title AddLiquidityBatchCallbackData
     * @dev A struct representing callback data for the addLiquidityBatch function in the Chromatic LP contract.
     * @param provider The address of the liquidity provider initiating the addLiquidityBatch.
     * @param liquidityAmount The amount of liquidity added to the LP.
     * @param holdingAmount The remaining holding amount after adding liquidity.
     */
    struct AddLiquidityBatchCallbackData {
        address provider;
        uint256 liquidityAmount;
        uint256 holdingAmount;
    }

    /**
     * @title RemoveLiquidityBatchCallbackData
     * @dev A struct representing callback data for the removeLiquidityBatch function in the Chromatic LP contract.
     * @param provider The address of the liquidity provider initiating the removeLiquidityBatch.
     * @param recipient The address where the LP tokens and settlement tokens are sent after removal.
     * @param lpTokenAmount The amount of LP tokens removed from the LP.
     * @param clbTokenAmounts An array of CLB token amounts corresponding to different fee rates.
     */
    struct RemoveLiquidityBatchCallbackData {
        address provider;
        address recipient;
        uint256 lpTokenAmount;
        uint256[] clbTokenAmounts;
    }

    modifier verifyCallback() virtual {
        if (address(s_state.market) != msg.sender) revert NotMarket();
        _;
    }

    modifier onlyDelegateCall() virtual {
        if (address(this) == _this) revert OnlyDelegateCall();
        _;
    }

    constructor(bytes32 _version) {
        version = _version;
        _this = address(this);
    }

    function _createSettleTask(uint256 receiptId) internal {
        s_task[receiptId] = s_automate;
        s_automate.createSettleTask(receiptId);
    }

    function settleTask(
        uint256 receiptId,
        address feePayee,
        uint256 keeperFee
    ) external /* onlyAutomation */ {
        if (address(s_task[receiptId]) != address(0)) {
            uint256 feeMax = _getMaxPayableFeeInSettlement(receiptId);
            uint256 fee = _payKeeperFee(feeMax, feePayee, keeperFee);
            _settle(receiptId, fee);
        } // TODO else revert
    }

    function _getMaxPayableFeeInSettlement(
        uint256 receiptId
    ) internal view returns (uint256 maxFee) {
        ChromaticLPReceipt memory receipt = s_state.getReceipt(receiptId);
        if (receipt.action == ChromaticLPAction.ADD_LIQUIDITY) {
            maxFee = receipt.amount - receipt.amount.mulDiv(s_config.utilizationTargetBPS, BPS);
        } else {
            uint256 balance = s_state.settlementToken().balanceOf(address(this));
            if (receipt.amount == 0) {
                // case of rebalanceRemove
                maxFee = balance;
            } else {
                maxFee = balance.mulDiv(receipt.amount, totalSupply());
            }
        }
    }

    function _payKeeperFee(
        uint256 maxFeeInSettlementToken,
        address feePayee,
        uint256 keeperFee
    ) internal virtual returns (uint256 feeInSettlementAmount) {
        IKeeperFeePayer payer = IKeeperFeePayer(s_state.market.factory().keeperFeePayer());

        IERC20 token = s_state.settlementToken();
        SafeERC20.safeTransfer(token, address(payer), maxFeeInSettlementToken);

        feeInSettlementAmount = payer.payKeeperFee(address(token), keeperFee, feePayee);
    }

    function _settle(uint256 receiptId, uint256 keeperFee) internal {
        ChromaticLPReceipt memory receipt = s_state.getReceipt(receiptId);

        if (receipt.id <= REBALANCE_ID) revert InvalidReceiptId();
        if (!receipt.needSettle) revert AlreadySettled();
        if (receipt.oracleVersion >= s_state.oracleVersion()) revert OracleVersionError();
        _cancelSettleTask(receiptId);

        if (receipt.action == ChromaticLPAction.ADD_LIQUIDITY) {
            s_state.claimLiquidity(receipt, keeperFee);
        } else if (receipt.action == ChromaticLPAction.REMOVE_LIQUIDITY) {
            s_state.withdrawLiquidity(receipt, keeperFee);
        } else {
            revert UnknownLPAction();
        }
    }

    function _cancelSettleTask(uint256 receiptId) internal /* onlyOwner */ {
        IAutomateLP automate = s_task[receiptId];
        if (address(automate) != address(0)) {
            delete s_task[receiptId];
            automate.cancelSettleTask(receiptId);
        }
    }

    function _calcRemoveClbAmounts(
        uint256 lpTokenAmount
    ) internal view returns (int16[] memory feeRates, uint256[] memory clbTokenAmounts) {
        return s_state.calcRemoveClbAmounts(lpTokenAmount, totalSupply());
    }

    function resolveRebalance() external view virtual returns (bool, bytes memory) {
        revert NotImplementedInLogicContract();
    }

    function rebalance() external virtual {}

    function _addLiquidity(
        int16[] memory feeRates,
        uint256[] memory amounts,
        AddLiquidityParam memory addParam
    )
        internal
        returns (
            ChromaticLPReceipt memory receipt
        )
    {
        // if (amount <= s_config.automationFeeReserved) {
        //     revert TooSmallAmountToAddLiquidity();
        // }
        if (feeRates.length == 0) revert AddableBinNotExist();
        receipt = s_state.addLiquidity(feeRates, amounts, addParam);

        // slither-disable-next-line reentrancy-benign
        _createSettleTask(receipt.id);
    }

    function _removeLiquidity(
        int16[] memory feeRates,
        uint256[] memory clbTokenAmounts,
        RemoveLiquidityParam memory removeParam
    ) internal returns (ChromaticLPReceipt memory receipt) {
        if (feeRates.length == 0) revert RemovableBinNotExist();
        receipt = s_state.removeLiquidity(feeRates, clbTokenAmounts, removeParam);

        // slither-disable-next-line reentrancy-benign
        _createSettleTask(receipt.id);
    }

    /**
     * @dev implementation of IChromaticLiquidityCallback
     */
    function addLiquidityBatchCallback(
        address settlementToken,
        address vault,
        bytes calldata data
    ) external verifyCallback {
        AddLiquidityBatchCallbackData memory callbackData = abi.decode(
            data,
            (AddLiquidityBatchCallbackData)
        );

        if (callbackData.provider != address(this)) {
            //slither-disable-next-line arbitrary-send-erc20
            SafeERC20.safeTransferFrom(
                IERC20(settlementToken),
                callbackData.provider,
                vault,
                callbackData.liquidityAmount
            );
            //slither-disable-next-line arbitrary-send-erc20
            SafeERC20.safeTransferFrom(
                IERC20(settlementToken),
                callbackData.provider,
                address(this),
                callbackData.holdingAmount
            );
        } else {
            SafeERC20.safeTransfer(IERC20(settlementToken), vault, callbackData.liquidityAmount);
        }
    }

    /**
     * @dev implementation of IChromaticLiquidityCallback
     */
    function claimLiquidityBatchCallback(
        uint256[] calldata /* receiptIds */,
        int16[] calldata /* feeRates */,
        uint256[] calldata /* depositedAmounts */,
        uint256[] calldata /* mintedCLBTokenAmounts */,
        bytes calldata data
    ) external verifyCallback {
        (ChromaticLPReceipt memory receipt, uint256 valuOfSupply, uint256 keeperFee) = abi.decode(
            data,
            (ChromaticLPReceipt, uint256, uint256)
        );

        uint256 netAmount = receipt.amount - keeperFee;
        s_state.decreasePendingAdd(netAmount, receipt.pendingLiquidity);

        if (receipt.recipient != address(this)) {
            //slither-disable-next-line incorrect-equality
            uint256 lpTokenMint = valuOfSupply == 0
                ? netAmount
                : netAmount.mulDiv(totalSupply(), valuOfSupply);
            _mint(receipt.recipient, lpTokenMint);
            emit AddLiquiditySettled({
                receiptId: receipt.id,
                provider: receipt.provider,
                recipient: receipt.recipient,
                settlementAdded: netAmount,
                lpTokenAmount: lpTokenMint,
                keeperFee: keeperFee
            });
            if (receipt.provider.code.length > 0) {
                try
                    IChromaticLPCallback(receipt.provider).claimedCallback(
                        receipt.id,
                        netAmount,
                        lpTokenMint,
                        keeperFee
                    )
                {} catch {}
            }
        } else {
            emit RebalanceSettled({receiptId: receipt.id, keeperFee: keeperFee});
        }
    }

    /**
     * @dev implementation of IChromaticLiquidityCallback
     */
    function removeLiquidityBatchCallback(
        address clbToken,
        uint256[] calldata _clbTokenIds,
        bytes calldata data
    ) external verifyCallback {
        RemoveLiquidityBatchCallbackData memory callbackData = abi.decode(
            data,
            (RemoveLiquidityBatchCallbackData)
        );
        IERC1155(clbToken).safeBatchTransferFrom(
            address(this),
            msg.sender, // market
            _clbTokenIds,
            callbackData.clbTokenAmounts,
            bytes("")
        );

        if (callbackData.provider != address(this) && callbackData.lpTokenAmount > 0) {
            //slither-disable-next-line arbitrary-send-erc20
            SafeERC20.safeTransferFrom(
                IERC20(this),
                callbackData.provider,
                address(this),
                callbackData.lpTokenAmount
            );
        }
    }

    /**
     * @dev implementation of IChromaticLiquidityCallback
     */
    function withdrawLiquidityBatchCallback(
        uint256[] calldata /* receiptIds */,
        int16[] calldata /* _feeRates */,
        uint256[] calldata /* withdrawnAmounts */,
        uint256[] calldata /* burnedCLBTokenAmounts */,
        bytes calldata data
    ) external verifyCallback {
        (
            ChromaticLPReceipt memory receipt,
            LpReceipt[] memory lpReceits,
            uint256 valueOfSupply,
            uint256 keeperFee
        ) = abi.decode(data, (ChromaticLPReceipt, LpReceipt[], uint256, uint256));
        s_state.decreasePendingClb(lpReceits);
        // burn and transfer settlementToken

        if (receipt.recipient != address(this)) {
            uint256 totalValueBefore = valueOfSupply + keeperFee;

            uint256 withdrawingMaxAmount = totalValueBefore.mulDiv(receipt.amount, totalSupply());

            uint256 burningAmount;
            uint256 withdrawingAmount;

            require(withdrawingMaxAmount > keeperFee, Errors.WITHDRAWAL_LESS_THAN_AUTOMATION_FEE);

            if (withdrawingMaxAmount - keeperFee > s_state.holdingValue()) {
                withdrawingAmount = s_state.holdingValue();
                // burningAmount: (withdrawingAmount + keeperFee) = receipt.amount: withdrawingMaxAmount
                burningAmount = receipt.amount.mulDiv(
                    withdrawingAmount + keeperFee,
                    withdrawingMaxAmount
                );
            } else {
                withdrawingAmount = withdrawingMaxAmount - keeperFee;
                burningAmount = receipt.amount;
            }

            uint256 remainingAmount = receipt.amount - burningAmount;

            emit RemoveLiquiditySettled({
                receiptId: receipt.id,
                provider: receipt.provider,
                recipient: receipt.recipient,
                burningAmount: burningAmount,
                withdrawnSettlementAmount: withdrawingAmount,
                refundedAmount: remainingAmount,
                keeperFee: keeperFee
            });

            SafeERC20.safeTransfer(s_state.settlementToken(), receipt.recipient, withdrawingAmount);

            // burn LPToken requested
            if (burningAmount > 0) {
                _burn(address(this), burningAmount);
            }
            if (remainingAmount > 0) {
                SafeERC20.safeTransfer(IERC20(this), receipt.recipient, remainingAmount);
            }
            if (receipt.provider.code.length > 0) {
                try
                    IChromaticLPCallback(receipt.provider).withdrawnCallback(
                        receipt.id,
                        burningAmount,
                        withdrawingAmount,
                        remainingAmount,
                        keeperFee
                    )
                {} catch {}
            }
        } else {
            emit RebalanceSettled({receiptId: receipt.id, keeperFee: keeperFee});
        }
    }

    function _rebalance() internal returns (uint256) {
        (uint256 currentUtility, uint256 valueTotal) = s_state.utilizationInfo();
        if (valueTotal == 0) return 0;

        AllocationStatus status = s_config.allocationStatus(currentUtility);

        if (status == AllocationStatus.OverUtilized) {
            return _rebalanceRemoveLiquidity(currentUtility);
        } else if (status == AllocationStatus.UnderUtilized) {
            return _rebalanceAddLiquidity(currentUtility);
        } else {
            return 0;
        }
    }

    function _rebalanceRemoveLiquidity(uint256 currentUtility) private returns (uint256 receiptId) {
        (int16[] memory feeRates, uint256[] memory removeAmounts) = s_state
            .calcRebalanceRemoveAmounts(currentUtility, s_config.utilizationTargetBPS);

        ChromaticLPReceipt memory receipt = _removeLiquidity(
            feeRates,
            removeAmounts,
            RemoveLiquidityParam({amount: 0, provider: address(this), recipient: address(this)})
        );
        //slither-disable-next-line reentrancy-events
        emit RebalanceRemoveLiquidity(receipt.id, receipt.oracleVersion, currentUtility);
        return receipt.id;
    }

    function _rebalanceAddLiquidity(uint256 currentUtility) private returns (uint256 receiptId) {
        uint256 amount = _estimateRebalanceAddAmount(currentUtility);

        uint256 liquidityTarget = (amount - s_config.automationFeeReserved).mulDiv(
            s_config.utilizationTargetBPS,
            BPS
        );
        (int16[] memory feeRates, uint256[] memory amounts, uint256 liquidityAmount) = s_state
            .distributeAmount(liquidityTarget);

        ChromaticLPReceipt memory receipt = _addLiquidity(
            feeRates,
            amounts,
            AddLiquidityParam({
                amount: amount,
                amountMarket: liquidityAmount,
                provider: address(this),
                recipient: address(this)
            })
        );
        //slither-disable-next-line reentrancy-events
        emit RebalanceAddLiquidity(receipt.id, receipt.oracleVersion, amount, currentUtility);
        return receipt.id;
    }

    /**
     * @inheritdoc IChromaticLPLogic
     */
    function onUpgrade(bytes calldata data) external virtual onlyDelegateCall onlyDao {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SuspendMode} from "~/lp/base/SuspendMode.sol";
import {ChromaticLPStorageCore} from "~/lp/base/ChromaticLPStorageCore.sol";
import {LPState} from "~/lp/libraries/LPState.sol";
import {LPStateValueLib} from "~/lp/libraries/LPStateValue.sol";
import {IChromaticLPRegistry} from "~/lp/interfaces/IChromaticLPRegistry.sol";
import {IAutomateLP} from "~/lp/interfaces/IAutomateLP.sol";

import {BPS} from "~/lp/libraries/Constants.sol";

abstract contract ChromaticLPStorage is ChromaticLPStorageCore, ReentrancyGuard, SuspendMode {
    using Math for uint256;
    using LPStateValueLib for LPState;

    uint256[50] __proxyReserved;

    modifier onlyAutomation(uint256 rebalanceOrReceiptId) {
        if (msg.sender != address(s_task[rebalanceOrReceiptId])) revert NotAutomationCalled();
        _;
    }

    modifier onlyDao() virtual {
        if (!_checkDao()) revert OnlyAccessableByDao();
        _;
    }

    mapping(uint256 => IAutomateLP) internal s_task;
    IAutomateLP internal s_automate;

    function _setAutomateLP(IAutomateLP automate) internal virtual {
        s_automate = automate;
    }

    function _estimateRebalanceAddAmount(uint256 currentUtility) internal view returns (uint256) {
        return
            (s_state.holdingValue()).mulDiv(
                (BPS - currentUtility) - (BPS - s_config.utilizationTargetBPS),
                BPS - currentUtility
            );
    }

    function _estimateRebalanceRemoveValue(uint256 currentUtility) internal view returns (uint256) {
        return
            s_state.holdingClbValue().mulDiv(
                currentUtility - s_config.utilizationTargetBPS,
                currentUtility
            );
    }

    function _checkDao() internal view virtual returns (bool) {
        return msg.sender == s_state.market.factory().dao();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";

import {ChromaticLPReceipt, ChromaticLPAction} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {IChromaticLPLens, ValueInfo} from "~/lp/interfaces/IChromaticLPLens.sol";
import {IChromaticLPEvents} from "~/lp/interfaces/IChromaticLPEvents.sol";
import {IChromaticLPErrors} from "~/lp/interfaces/IChromaticLPErrors.sol";
import {LPState} from "~/lp/libraries/LPState.sol";
import {LPConfig} from "~/lp/libraries/LPConfig.sol";
import {BPS} from "~/lp/libraries/Constants.sol";
import {LPStateViewLib} from "~/lp/libraries/LPStateView.sol";

abstract contract ChromaticLPStorageCore is ERC20, IChromaticLPEvents, IChromaticLPErrors {
    using LPStateViewLib for LPState;

    /**
     * @title LPMeta
     * @dev A struct representing metadata information for an LP (Liquidity Provider) in the Chromatic Protocol.
     * @param lpName The name associated with the LP.
     * @param tag A tag or identifier for the LP.
     */
    struct LPMeta {
        string lpName;
        string tag;
    }

    /**
     * @title ConfigParam
     * @dev A struct representing the configuration parameters for an LP (Liquidity Provider) in the Chromatic Protocol.
     * @param market An instance of the IChromaticMarket interface, representing the market associated with the LP.
     * @param utilizationTargetBPS Target utilization rate for the LP, represented in basis points (BPS).
     * @param rebalanceBPS Rebalance basis points, indicating the percentage change that triggers a rebalance.
     * @param rebalanceCheckingInterval Time interval (in seconds) between checks for rebalance conditions.
     * @param automationFeeReserved Amount reserved as automation fee, used for automated operations within the LP.
     * @param minHoldingValueToRebalance The minimum holding value required to trigger rebalance.
     */
    struct ConfigParam {
        IChromaticMarket market;
        uint16 utilizationTargetBPS;
        uint16 rebalanceBPS;
        uint256 rebalanceCheckingInterval;
        uint256 automationFeeReserved;
        uint256 minHoldingValueToRebalance;
    }

    //slither-disable-next-line unused-state
    LPMeta internal s_meta;
    //slither-disable-next-line uninitialized-state
    LPConfig internal s_config;
    LPState internal s_state;
    // locate logic contract address in slot common
    address internal s_logicAddress;

    constructor() ERC20("", "") {}

    /**
     * @inheritdoc ERC20
     */
    function decimals() public view virtual override returns (uint8) {
        return s_state.settlementToken().decimals();
    }

    function _setLogicAddress(address logicAddress) internal {
        s_logicAddress = logicAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IChromaticLPEvents} from "~/lp/interfaces/IChromaticLPEvents.sol";
import {IChromaticLPErrors} from "~/lp/interfaces/IChromaticLPErrors.sol";

/**
 * @title SuspendModeType
 * @dev An enumeration representing the suspension mode of the contract.
 * @param NOT_SUSPENDED The contract is not suspended.
 * @param ADD_SUSPENDED Adding liquidity is suspended.
 * @param ALL_SUSPENDED Both adding and removing liquidity are suspended.
 */
enum SuspendModeType {
    NOT_SUSPENDED,
    ADD_SUSPENDED,
    ALL_SUSPENDED
}

/**
 * @title SuspendMode
 * @dev A contract providing suspension functionality for adding and removing liquidity in Chromatic LP.
 */
abstract contract SuspendMode is IChromaticLPEvents, IChromaticLPErrors {
    // The current suspension mode
    SuspendModeType _mode;

    /**
     * @dev Modifier to check if adding liquidity is enabled.
     */
    modifier addLiquidityEnabled() virtual {
        if (!_checkAddLiquidityEnabled()) revert AddLiquiditySuspended();
        _;
    }

    /**
     * @dev Modifier to check if removing liquidity is enabled.
     */
    modifier removeLiquidityEnabled() virtual {
        if (!_checkRemoveLiquidityEnabled()) revert RemoveLiquiditySuspended();
        _;
    }

    /**
     * @dev Internal function to set the suspension mode.
     * @param mode The new suspension mode.
     */
    function _setSuspendMode(uint8 mode) internal {
        emit SetSuspendMode(uint8(mode));
        _mode = SuspendModeType(mode);
    }

    /**
     * @dev Internal function to check if adding liquidity is enabled based on the current suspension mode.
     * @return Whether adding liquidity is enabled.
     */
    function _checkAddLiquidityEnabled() internal view returns (bool) {
        return _mode < SuspendModeType.ADD_SUSPENDED;
    }

    /**
     * @dev Internal function to check if removing liquidity is enabled based on the current suspension mode.
     * @return Whether removing liquidity is enabled.
     */
    function _checkRemoveLiquidityEnabled() internal view returns (bool) {
        return _mode < SuspendModeType.ALL_SUSPENDED;
    }

    /**
     * @dev Internal function to retrieve the current suspension mode.
     * @return The current suspension mode.
     */
    function _suspendMode() internal view returns (uint8) {
        return uint8(_mode);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IChromaticLiquidityCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticLiquidityCallback.sol";
import {IChromaticLP} from "~/lp/interfaces/IChromaticLP.sol";
import {IChromaticLPAdmin} from "~/lp/interfaces/IChromaticLPAdmin.sol";
import {IChromaticLPLiquidity} from "~/lp/interfaces/IChromaticLPLiquidity.sol";
import {IChromaticLPMeta} from "~/lp/interfaces/IChromaticLPMeta.sol";
import {ChromaticLPBase} from "~/lp/base/ChromaticLPBase.sol";
import {ChromaticLPLogic} from "~/lp/ChromaticLPLogic.sol";
import {ChromaticLPReceipt} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {LPState, REBALANCE_ID} from "~/lp/libraries/LPState.sol";
import {LPStateViewLib} from "~/lp/libraries/LPStateView.sol";
import {BPS} from "~/lp/libraries/Constants.sol";
import {IChromaticLPAutomate} from "~/lp/interfaces/IChromaticLPAutomate.sol";
import {IAutomateLP} from "~/lp/interfaces/IAutomateLP.sol";

contract ChromaticLP is ChromaticLPBase, Proxy, IChromaticLiquidityCallback, IERC1155Receiver {
    using EnumerableSet for EnumerableSet.UintSet;
    using LPStateViewLib for LPState;

    constructor(
        address logicAddress,
        LPMeta memory lpMeta,
        ConfigParam memory config,
        int16[] memory _feeRates,
        uint16[] memory _distributionRates,
        IAutomateLP automate
    ) ChromaticLPBase() {
        _initialize(lpMeta, config, _feeRates, _distributionRates, automate, logicAddress);
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function createRebalanceTask() public onlyDao {
        s_task[REBALANCE_ID] = s_automate;
        s_automate.createRebalanceTask();
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function cancelRebalanceTask() external onlyDao {
        IAutomateLP automate = s_task[REBALANCE_ID];
        delete s_task[REBALANCE_ID];
        automate.cancelRebalanceTask();
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function cancelSettleTask(uint256 /* receiptId */) external onlyDao {
        _fallback();
    }

    /**
     * @dev This is the address to which proxy functions are delegated to
     */
    function _implementation() internal view virtual override returns (address) {
        return s_logicAddress;
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function addLiquidity(
        uint256 amount,
        address /* recipient */
    ) external override addLiquidityEnabled returns (ChromaticLPReceipt memory /* receipt */) {
        if (amount < estimateMinAddLiquidityAmount()) {
            revert TooSmallAmountToAddLiquidity();
        }
        _fallback();
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function removeLiquidity(
        uint256 /* lpTokenAmount */,
        address /* recipient */
    ) external override removeLiquidityEnabled returns (ChromaticLPReceipt memory /* receipt */) {
        // NOTE:
        // if lpTokenAmount is too small then settlement couldn't be completed by automation
        // user should call manually `settle(receiptId)`
        _fallback();
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function settle(uint256 /* receiptId */) external override {
        _fallback();
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function setAutomationFeeReserved(
        uint256 _automationFeeReserved
    ) external override(IChromaticLPAdmin) onlyDao {
        emit SetAutomationFeeReserved(_automationFeeReserved);
        s_config.automationFeeReserved = _automationFeeReserved;
    }

    /**
     * @inheritdoc IChromaticLPAdmin
     */
    function setMinHoldingValueToRebalance(
        uint256 _minHoldingValueToRebalance
    ) external override(IChromaticLPAdmin) onlyDao {
        if (_minHoldingValueToRebalance < s_config.automationFeeReserved) {
            revert InvalidMinHoldingValueToRebalance();
        }
        emit SetMinHoldingValueToRebalance(_minHoldingValueToRebalance);
        s_config.minHoldingValueToRebalance = _minHoldingValueToRebalance;
    }

    /**
     * @inheritdoc IChromaticLPMeta
     */
    function lpName() external view override returns (string memory) {
        return s_meta.lpName;
    }

    /**
     * @inheritdoc IChromaticLPMeta
     */
    function lpTag() external view override returns (string memory) {
        return s_meta.tag;
    }

    /**
     * @inheritdoc IChromaticLP
     */
    function market() external view override returns (address) {
        return address(s_state.market);
    }

    /**
     * @inheritdoc IChromaticLP
     */
    function settlementToken() external view override returns (address) {
        return address(s_state.market.settlementToken());
    }

    /**
     * @inheritdoc IChromaticLP
     */
    function lpToken() external view override returns (address) {
        return address(this);
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function getReceiptIdsOf(
        address owner_
    ) external view override returns (uint256[] memory receiptIds) {
        return s_state.providerReceiptIds[owner_].values();
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function getReceipt(
        uint256 receiptId
    ) external view override returns (ChromaticLPReceipt memory) {
        return s_state.getReceipt(receiptId);
    }

    /**
     * @inheritdoc IChromaticLPLiquidity
     */
    function getMarketReceiptsOf(uint256 receiptId) external view returns (uint256[] memory) {
        return s_state.lpReceiptMap[receiptId];
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function addLiquidityCallback(address, address, bytes calldata) external pure override {
        revert OnlyBatchCall();
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function claimLiquidityCallback(
        uint256 /* receiptId */,
        int16 /* feeRate */,
        uint256 /* depositedAmount */,
        uint256 /* mintedCLBTokenAmount */,
        bytes calldata /* data */
    ) external pure override {
        revert OnlyBatchCall();
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function removeLiquidityCallback(
        address /* clbToken */,
        uint256 /* clbTokenId */,
        bytes calldata /* data */
    ) external pure override {
        revert OnlyBatchCall();
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function withdrawLiquidityCallback(
        uint256 /* receiptId */,
        int16 /* feeRate */,
        uint256 /* withdrawnAmount */,
        uint256 /* burnedCLBTokenAmount */,
        bytes calldata /* data */
    ) external pure override {
        revert OnlyBatchCall();
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function addLiquidityBatchCallback(
        address /* settlementToken */,
        address /* vault */,
        bytes calldata /* data */
    ) external override {
        _fallback();
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function claimLiquidityBatchCallback(
        uint256[] calldata /* receiptIds */,
        int16[] calldata /* feeRates */,
        uint256[] calldata /* depositedAmounts */,
        uint256[] calldata /* mintedCLBTokenAmounts */,
        bytes calldata /* data */
    ) external override {
        _fallback();
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function removeLiquidityBatchCallback(
        address /* clbToken */,
        uint256[] calldata /* clbTokenIds */,
        bytes calldata /* data */
    ) external override {
        _fallback();
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     * @dev not implemented
     */
    function withdrawLiquidityBatchCallback(
        uint256[] calldata /* receiptIds */,
        int16[] calldata /* feeRates */,
        uint256[] calldata /* withdrawnAmounts */,
        uint256[] calldata /* burnedCLBTokenAmounts */,
        bytes calldata /* data */
    ) external override {
        _fallback();
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // ERC165
            interfaceID == this.onERC1155Received.selector ^ this.onERC1155BatchReceived.selector; // IERC1155Receiver
    }

    /**
     * @dev called by automation only
     */
    function rebalance(
        address /* feePayee */,
        uint256 /* keeperFee */
    ) external onlyAutomation(REBALANCE_ID) {
        _fallback();
    }

    /**
     * @dev called by automation only
     */
    function settleTask(
        uint256 receiptId,
        address /* feePayee */,
        uint256 /* keeperFee */
    ) external onlyAutomation(receiptId) {
        _fallback();
    }

    /**
     * @inheritdoc IChromaticLPAutomate
     */
    function setAutomateLP(IAutomateLP automate) external override onlyDao {
        emit SetAutomateLP(address(automate));
        _setAutomateLP(automate);
    }

    /**
     * @inheritdoc IChromaticLPAutomate
     */
    function automateLP() external view override returns (IAutomateLP) {
        return s_automate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

import {ChromaticLPReceipt, ChromaticLPAction} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {IChromaticLP} from "~/lp/interfaces/IChromaticLP.sol";
import {IAutomateLP} from "~/lp/interfaces/IAutomateLP.sol";
import {ChromaticLPLogicBase} from "~/lp/base/ChromaticLPLogicBase.sol";
import {LPState} from "~/lp/libraries/LPState.sol";
import {LPStateViewLib} from "~/lp/libraries/LPStateView.sol";
import {LPStateValueLib} from "~/lp/libraries/LPStateValue.sol";
import {LPConfigLib, LPConfig, AllocationStatus} from "~/lp/libraries/LPConfig.sol";
import {LPStateLogicLib, AddLiquidityParam, RemoveLiquidityParam} from "~/lp/libraries/LPStateLogic.sol";
import {BPS} from "~/lp/libraries/Constants.sol";

contract ChromaticLPLogic is ChromaticLPLogicBase {
    using Math for uint256;
    using LPStateViewLib for LPState;
    using LPStateValueLib for LPState;
    using LPStateLogicLib for LPState;
    using LPConfigLib for LPConfig;

    constructor(bytes32 _version) ChromaticLPLogicBase(_version) {}

    /**
     * @dev implementation of IChromaticLP
     */
    function addLiquidity(
        uint256 amount,
        address recipient
    ) external nonReentrant returns (ChromaticLPReceipt memory receipt) {
        // if (amount <= s_config.automationFeeReserved) {
        //     revert TooSmallAmountToAddLiquidity();
        // }
        uint256 liquidityTarget = (amount - s_config.automationFeeReserved).mulDiv(
            s_config.utilizationTargetBPS,
            BPS
        );

        (int16[] memory feeRates, uint256[] memory amounts, uint256 liquidityAmount) = s_state
            .distributeAmount(liquidityTarget);

        receipt = _addLiquidity(
            feeRates,
            amounts,
            AddLiquidityParam({
                amount: amount,
                amountMarket: liquidityAmount,
                provider: msg.sender,
                recipient: recipient
            })
        );

        //slither-disable-next-line reentrancy-events
        emit AddLiquidity({
            receiptId: receipt.id,
            provider: msg.sender,
            recipient: recipient,
            oracleVersion: receipt.oracleVersion,
            amount: amount
        });
    }

    /**
     * @dev implementation of IChromaticLP
     */
    function removeLiquidity(
        uint256 lpTokenAmount,
        address recipient
    ) external nonReentrant returns (ChromaticLPReceipt memory receipt) {
        if (lpTokenAmount == 0) revert ZeroRemoveLiquidityError();
        (int16[] memory feeRates, uint256[] memory clbTokenAmounts) = _calcRemoveClbAmounts(
            lpTokenAmount
        );

        receipt = _removeLiquidity(
            feeRates,
            clbTokenAmounts,
            RemoveLiquidityParam({
                amount: lpTokenAmount,
                provider: msg.sender,
                recipient: recipient
            })
        );
        //slither-disable-next-line reentrancy-events
        emit RemoveLiquidity({
            receiptId: receipt.id,
            provider: msg.sender,
            recipient: recipient,
            oracleVersion: receipt.oracleVersion,
            lpTokenAmount: lpTokenAmount
        });
    }

    /**
     * @dev implementation of IChromaticLP
     */
    function settle(uint256 receiptId) external nonReentrant {
        _settle(receiptId, 0);
    }

    function cancelSettleTask(uint256 receiptId) external /* onlyOwner */ {
        _cancelSettleTask(receiptId);
    }

    /**
     * @dev implementation of IChromaticLP
     */
    function rebalance(
        address feePayee,
        uint256 keeperFee // native token amount
    ) external nonReentrant {
        (uint256 currentUtility, uint256 valueTotal) = s_state.utilizationInfo();
        if (valueTotal == 0) return;

        AllocationStatus status = s_config.allocationStatus(currentUtility);

        if (status != AllocationStatus.InRange) {
            uint256 balance = s_state.settlementToken().balanceOf(address(this));
            _payKeeperFee(balance, feePayee, keeperFee);
            _rebalance();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IChromaticLP} from "~/lp/interfaces/IChromaticLP.sol";

/**
 * @title IAutomateLP
 * @dev Interface for automating tasks related to liquidity providers (LPs) within a protocol.
 */
interface IAutomateLP {
    /**
     * @dev Emitted when a function is called by an unauthorized address.
     */
    error NotAutomationCalled();

    /**
     * @dev Emitted when attempting to create a rebalance task while one already exists.
     */
    error AlreadyRebalanceTaskExist();

    /**
     * @dev Signifies that the function is only accessible by the owner
     */
    error OnlyAccessableByOwner();

    /**
     * @dev Initiates the creation of a rebalance task for the specified LP (msg.sender).
     */
    function createRebalanceTask() external;

    /**
     * @dev Cancels the existing rebalance task for the specified LP (msg.sender).
     */
    function cancelRebalanceTask() external;

    /**
     * @dev Checks whether a rebalance task is needed for the specified LP.
     * @param lp The address of the liquidity provider.
     * @return upkeepNeeded Indicates whether upkeep is needed.
     * @return performData Additional data required for performing the task.
     */
    function resolveRebalance(
        address lp
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @dev Executes the rebalance task for the specified LP.
     * @param lp The address of the liquidity provider.
     */
    function rebalance(address lp) external;

    /**
     * @dev Initiates the creation of a settle task for a specific receipt ID.
     * @param receiptId The unique identifier of the receipt associated with the task.
     */
    function createSettleTask(uint256 receiptId) external;

    /**
     * @dev Cancels the existing settle task for a specific receipt ID.
     * @param receiptId The unique identifier of the receipt associated with the task.
     */
    function cancelSettleTask(uint256 receiptId) external;

    /**
     * @dev Checks whether a settle task is needed for the specified LP and receipt ID.
     * @param lp The address of the liquidity provider.
     * @param receiptId The unique identifier of the receipt associated with the task.
     * @return upkeepNeeded Indicates whether upkeep is needed.
     * @return performData Additional data required for performing the task.
     */
    function resolveSettle(
        address lp,
        uint256 receiptId
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @dev Executes the settle task for the specified LP and receipt ID.
     * @param lp The address of the liquidity provider.
     * @param receiptId The unique identifier of the receipt associated with the task.
     */
    function settle(address lp, uint256 receiptId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IChromaticLPLiquidity} from "./IChromaticLPLiquidity.sol";
import {IChromaticLPAdmin} from "./IChromaticLPAdmin.sol";
import {IChromaticLPAutomate} from "./IChromaticLPAutomate.sol";
import {IChromaticLPLens} from "./IChromaticLPLens.sol";
import {IChromaticLPMeta} from "./IChromaticLPMeta.sol";
import {IChromaticLPEvents} from "./IChromaticLPEvents.sol";
import {IChromaticLPErrors} from "./IChromaticLPErrors.sol";

/**
 * @title The IChromaticLP interface consolidates several other interfaces, allowing developers to access a wide range of functionalities related to Chromatic Protocol liquidity providers. It includes methods from liquidity management, metadata retrieval, lens queries, administration, event tracking, and error handling.
 */
interface IChromaticLP is
    IChromaticLPLiquidity,
    IChromaticLPLens,
    IChromaticLPMeta,
    IChromaticLPAdmin,
    IChromaticLPAutomate,
    IChromaticLPEvents,
    IChromaticLPErrors
{
    /**
     * @dev Retrieves the address of the market associated with the Chromatic Protocol liquidity provider.
     * @return The address of the market associated with the liquidity provider.
     */
    function market() external view returns (address);

    /**
     * @dev Retrieves the address of the settlement token associated with the Chromatic Protocol liquidity provider.
     * @return The address of the settlement token used in the liquidity provider.
     */
    function settlementToken() external view returns (address);

    /**
     * @dev Retrieves the address of the LP token associated with the Chromatic Protocol liquidity provider.
     * @return The address of the LP (Liquidity Provider) token issued by the liquidity provider.
     */
    function lpToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title The IChromaticLPAdmin interface is designed to facilitate the administration of liquidity provider within the Chromatic Protocol.
 * @author
 * @notice
 */
interface IChromaticLPAdmin {
    /**
     * @dev Initiates the creation of a rebalance task in the liquidity provider.
     * This is allowed for the owner of LP contract to call
     */
    function createRebalanceTask() external;

    /**
     * @dev Cancels the currently active rebalance task in the liquidity provider.
     * This is allowed for the owner of LP contract to call
     */
    function cancelRebalanceTask() external;

    /**
     * @dev Cancels the settle task in the liquidity provider.
     * This is allowed for the owner of LP contract to call
     * @param  receiptId The receipt ID associated with the settle execution.
     */
    function cancelSettleTask(uint256 receiptId) external;

    /**
     * @dev Additional data to be used in the rebalance process.
     * @param _automationFeeReserved The new value for the reserved automation fee.
     */
    function setAutomationFeeReserved(uint256 _automationFeeReserved) external;

    /**
     * @dev Additional data to be used in the rebalance process.
     * @param _minHoldingValueToRebalance The new value for the required minimum amount to trigger rebalance.
     */
    function setMinHoldingValueToRebalance(uint256 _minHoldingValueToRebalance) external;

    /**
     * @dev Retrieves the current suspension mode of the LP.
     * @return The current suspension mode.
     */
    function suspendMode() external view returns (uint8);

    /**
     * @dev Sets the suspension mode for the LP.
     * @param mode The new suspension mode to be set.
     */
    function setSuspendMode(uint8 mode) external;

    /**
     * @dev Returns the address of the DAO.
     * @return The address of the DAO.
     */
    function dao() external view returns (address);

    /**
     * @dev upgrade logic contract to new one.
     */
    function upgradeTo(address logicAddress, bytes calldata data) external;

    /**
     * @dev Returns the address of the logic contract.
     */
    function logicAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAutomateLP} from "~/lp/interfaces/IAutomateLP.sol";

/**
 * @title IChromaticLPAutomate
 * @dev Interface for automating tasks related to Chromatic Liquidity Providers (LPs).
 */
interface IChromaticLPAutomate {
    /**
     * @dev Checks whether a rebalance task is needed.
     * @return A boolean indicating whether a rebalance task is needed.
     */
    function checkRebalance() external view returns (bool);

    /**
     * @dev Initiates a rebalance task, providing fees for the keeper.
     * @param feePayee The address to receive the keeper fees.
     * @param keeperFee The amount of native tokens to be paid as keeper fees.
     */
    function rebalance(address feePayee, uint256 keeperFee) external;

    /**
     * @dev Checks whether a settle task is needed for a specific receipt ID.
     * @param receiptId The unique identifier of the receipt associated with the task.
     * @return A boolean indicating whether a settle task is needed.
     */
    function checkSettle(uint256 receiptId) external view returns (bool);

    /**
     * @dev Initiates a settle task for a specific receipt ID, providing fees for the keeper.
     * @param receiptId The unique identifier of the receipt associated with the task.
     * @param feePayee The address to receive the keeper fees.
     * @param keeperFee The amount of native tokens to be paid as keeper fees.
     */
    function settleTask(uint256 receiptId, address feePayee, uint256 keeperFee) external;

    /**
     * @notice Sets the AutomateLP contract address.
     * @param automate The address of the AutomateLP contract.
     */
    function setAutomateLP(IAutomateLP automate) external;

    /**
     * @notice Gets the current AutomateLP contract address.
     * @return The address of the AutomateLP contract.
     */
    function automateLP() external view returns (IAutomateLP);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IChromaticLPCallback
 * @dev Interface for handling callbacks related to Chromatic LP actions.
 */
interface IChromaticLPCallback {
    /**
     * @dev Callback function triggered after claiming liquidity.
     * @param receiptId The unique identifier of the receipt associated with the action.
     * @param addedLiquidity The amount of liquidity added in settlement token.
     * @param lpTokenMint The amount of LP tokens minted.
     * @param keeperFee The amount of keeper fee paid.
     */
    function claimedCallback(
        uint256 receiptId,
        uint256 addedLiquidity,
        uint256 lpTokenMint,
        uint256 keeperFee
    ) external;

    /**
     * @dev Callback function triggered after withdrawing liquidity.
     * @param receiptId The unique identifier of the receipt associated with the action.
     * @param burnedAmount The amount of LP tokens burned.
     * @param withdrawnAmount The amount of settlement tokens withdrawn.
     * @param refundedAmount The amount of LP tokens refunded.
     * @param keeperFee The amount of keeper fee paid.
     */
    function withdrawnCallback(
        uint256 receiptId,
        uint256 burnedAmount,
        uint256 withdrawnAmount,
        uint256 refundedAmount,
        uint256 keeperFee
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title IChromaticLPConfigLens
 * @dev Interface for viewing the configuration parameters of a Chromatic Protocol liquidity provider.
 */
interface IChromaticLPConfigLens {
    /**
     * @dev Emitted when the automation fee reserved value is updated.
     * @param newValue The new value of the automation fee reserved.
     */
    event SetAutomationFeeReserved(uint256 newValue);

    /**
     * @dev Emitted when the minimum holding value to trigger rebalance is updated.
     * @param newValue The new value of the minimum holding value to rebalance.
     */
    event SetMinHoldingValueToRebalance(uint256 newValue);

    /**
     * @dev Retrieves the target utilization rate in basis points (BPS) for the liquidity provider.
     * @return The target utilization rate in BPS.
     */
    function utilizationTargetBPS() external view returns (uint256);

    /**
     * @dev Retrieves the rebalance basis points (BPS) for the liquidity provider.
     * @return The rebalance BPS.
     */
    function rebalanceBPS() external view returns (uint256);

    /**
     * @dev Retrieves the time interval in seconds between checks for rebalance conditions.
     * @return The rebalance checking interval in seconds.
     */
    function rebalanceCheckingInterval() external view returns (uint256);

    /**
     * @dev Retrieves the amount reserved as automation fee for automated operations within the liquidity provider.
     * @return The automation fee reserved amount.
     */
    function automationFeeReserved() external view returns (uint256);

    /**
     * @dev Retrieves the minimum holding value required to trigger rebalance.
     * @return The minimum holding value to rebalance.
     */
    function minHoldingValueToRebalance() external view returns (uint256);

    /**
     * @dev Retrieves an array of distribution rates associated with different fee rates.
     * @return An array of distribution rates.
     */
    function distributionRates() external view returns (uint16[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title The IChromaticLPErrors interface houses a set of custom errors that developers may encounter when interacting with liquidity providers for the Chromatic Protocol. These errors are designed to provide meaningful feedback about specific issues that may arise during the execution of smart contracts.
 */
interface IChromaticLPErrors {
    /**
     * @dev The invalid target basis points.
     */
    error InvalidUtilizationTarget(uint16 targetBPS);

    /**
     * @dev Signifies that an invalid rebalance basis points value has been encountered.
     */
    error InvalidRebalanceBPS();

    /**
     * @dev Signifies that an invalid minHoldingValueToRebalance value has been encountered.
     */
    error InvalidMinHoldingValueToRebalance();

    /**
     * @dev Thrown when the lengths of the fee array and distribution array do not match.
     * @param feeLength The length of the fee array.
     * @param distributionLength The length of the distribution array.
     */
    error NotMatchDistributionLength(uint256 feeLength, uint256 distributionLength);

    /**
     * @dev Indicates that the operation is not applicable to the market.
     */
    error NotMarket();

    /**
     * @dev Denotes that the function can only be called within a batch call.
     */
    error OnlyBatchCall();

    /**
     * @dev Thrown when an unknown liquidity provider action is encountered
     */
    error UnknownLPAction();

    /**
     * @dev Signifies that the caller is not the owner of the contract
     */
    error NotOwner();

    /**
     * @dev Thrown when the keeper is not called.
     */
    error NotKeeperCalled();

    /**
     * @dev Signifies that the function is only accessible by the DAO
     */
    error OnlyAccessableByDao();

    /**
     * @dev Thrown when an automation call is not made
     */
    error NotAutomationCalled();

    /**
     * @dev Indicates that the functionality is not implemented in the logic contract.
     */
    error NotImplementedInLogicContract();

    /**
     * @dev Throws an error indicating that the amount to add liquidity is too small.
     */
    error TooSmallAmountToAddLiquidity();

    /**
     * @dev Error indicating that adding liquidity is suspended.
     */
    error AddLiquiditySuspended();

    /**
     * @dev Error indicating that removing liquidity is suspended.
     */
    error RemoveLiquiditySuspended();

    /**
     * @dev Error indicating that adding liquidity is not allowed during private mode.
     */
    error AddLiquidityNotAllowed();

    /**
     * @dev Error indicating an attempt to use a zero address.
     */
    error ZeroAddressError();

    /**
     * @dev Error indicating invalid receitp ID.
     */
    error InvalidReceiptId();

    /**
     * @dev Error indicating an invalid oracle version.
     */
    error OracleVersionError();

    /**
     * @dev Error indicating that the action has already been settled.
     */
    error AlreadySettled();

    /**
     * @dev Error indicating that removing zero amount of liquidity is invalid.
     */
    error ZeroRemoveLiquidityError();

    /**
     * @dev Error indicating that upgrading failed.
     */
    error UpgradeFailed();

    /**
     * @dev Error indicating that upgrading failed with a invalid contract address.
     */
    error UpgradeFailedNotContractAddress();

    /**
     * @dev Error indicating that there is no removable liquidity bin
     */
    error RemovableBinNotExist();

    /**
     * @dev Error indicating that there is no addable liquidity bin
     */
    error AddableBinNotExist();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title The IChromaticLPEvents interface declares events that developers can utilize to track and react to different actions within the Chromatic Protocol. These events offer transparency and can be subscribed to for monitoring the state changes of the liquidity providers.
 */
interface IChromaticLPEvents {
    /**
     * @notice Emitted when addLiquidity is performed.
     * @param receiptId Unique identifier for the liquidity addition receipt.
     * @param provider Address of the liquidity provider.
     * @param recipient Address of the recipient.
     * @param oracleVersion  Version of the oracle used.
     * @param amount Amount of liquidity added in the settlement token.
     */
    event AddLiquidity(
        uint256 indexed receiptId,
        address indexed provider,
        address indexed recipient,
        uint256 oracleVersion,
        uint256 amount
    );

    /**
     * @notice Emitted when addLiquidity is settled.
     * @param receiptId Unique identifier for the liquidity addition receipt.
     * @param provider Address of the liquidity provider.
     * @param recipient Address of the recipient.
     * @param settlementAdded Settlement added to the liquidity
     * @param lpTokenAmount Amount of LP tokens issued.
     * @param keeperFee Fee paid to the keeper.
     */
    event AddLiquiditySettled(
        uint256 indexed receiptId,
        address indexed provider,
        address indexed recipient,
        uint256 settlementAdded,
        uint256 lpTokenAmount,
        uint256 keeperFee
    );

    /**
     * @notice Emitted when removeLiquidity is performed.
     * @param receiptId Unique identifier for the liquidity removal receipt.
     * @param provider Address of the liquidity provider.
     * @param recipient Address of the recipient.
     * @param oracleVersion Version of the oracle used.
     * @param lpTokenAmount Amount of LP tokens to be removed.
     */
    event RemoveLiquidity(
        uint256 indexed receiptId,
        address indexed provider,
        address indexed recipient,
        uint256 oracleVersion,
        uint256 lpTokenAmount
    );

    /**
     * @notice Emitted when removeLiquidity is settled.
     * @param receiptId Unique identifier for the settled liquidity removal receipt.
     * @param provider Address of the liquidity provider.
     * @param recipient Address of the recipient.
     * @param burningAmount Amount of LP tokens burned.
     * @param withdrawnSettlementAmount Withdrawn settlement amount.
     * @param refundedAmount Amount refunded to the provider.
     * @param keeperFee Fee paid to the keeper.
     */
    event RemoveLiquiditySettled(
        uint256 indexed receiptId,
        address indexed provider,
        address indexed recipient,
        uint256 burningAmount,
        uint256 withdrawnSettlementAmount,
        uint256 refundedAmount,
        uint256 keeperFee
    );

    /**
     * @notice Emitted when rebalance of adding liquidity is performed.
     * @param receiptId Unique identifier for the rebalance liquidity addition receipt.
     * @param oracleVersion Version of the oracle used.
     * @param amount Amount of liquidity added during rebalance.
     * @param currentUtility Current utility of the liquidity provider.
     */
    event RebalanceAddLiquidity(
        uint256 indexed receiptId,
        uint256 oracleVersion,
        uint256 amount,
        uint256 currentUtility
    );

    /**
     * @notice Emitted when rebalance of removing liquidity is performed.
     * @param receiptId Unique identifier for the rebalance liquidity removal receipt.
     * @param oracleVersion Version of the oracle used.
     * @param currentUtility Current utility of the liquidity pool.
     */
    event RebalanceRemoveLiquidity(
        uint256 indexed receiptId,
        uint256 oracleVersion,
        uint256 currentUtility
    );

    /**
     * @notice Emitted when rebalancing is settled.
     * @param receiptId Unique identifier for the settled rebalance receipt.
     * @param keeperFee Fee paid to the keeper.
     */
    event RebalanceSettled(uint256 indexed receiptId, uint256 keeperFee);

    /**
     * @notice Emitted when the AutomateLP address is set.
     * @param automate The address of the AutomateLP contract.
     */
    event SetAutomateLP(address automate);

    /**
     * @dev Emitted when the suspension mode is set.
     * @param mode The new suspension mode.
     */
    event SetSuspendMode(uint8 mode);

    /**
     * @dev Emitted when the private/public mode is set.
     * @param mode The new private/public mode .
     */
    event SetPrivateMode(bool mode);

    /**
     * @dev Emitted when logic contract of the LP contract is upgraded.
     * @param previousLogic The address of the previous logic.
     * @param newLogic The address of the new logic.
     */
    event Upgraded(address previousLogic, address indexed newLogic);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IChromaticLPConfigLens} from "./IChromaticLPConfigLens.sol";

struct ValueInfo {
    uint256 total;
    uint256 holding;
    uint256 pending;
    uint256 holdingClb;
    uint256 pendingClb;
}

/**
 * @title The IChromaticLPLens interface is designed to offer a lens into the financial and operational aspects of the Chromatic Protocol. Developers can use the functions defined in this interface to retrieve information such as utilization, total value, value breakdowns, fee rates, and token balances.
 */
interface IChromaticLPLens is IChromaticLPConfigLens {
    /**
     * @dev The current utilization of the liquidity provider, represented in basis points (BPS)
     */
    function utilization() external view returns (uint16);

    /**
     * @dev The total value of the liquidity provider
     */
    function totalValue() external view returns (uint256);

    /**
     * @dev The total value of the liquidity provider token supplied.
     */
    function valueOfSupply() external view returns (uint256);

    /**
     * @dev Retrieves the total value of the liquidity provider, including both holding and pending values.
     * @return info A ValueInfo struct containing total, holding, pending, holdingClb, and pendingClb values.
     */
    function valueInfo() external view returns (ValueInfo memory info);

    /**
     * @dev Retrieves the current holding value of the liquidity pool.
     * @return The current holding value in the liquidity provider.
     */
    function holdingValue() external view returns (uint256);

    /**
     * @dev Retrieves the pending value of the liquidity provider.
     * @return pendingValue The pending value in the liquidity pool.
     */
    function pendingValue() external view returns (uint256);

    /**
     * @dev Retrieves the current holding CLB value in the liquidity provider.
     * @return The current holding CLB value in the liquidity provider.
     */
    function holdingClbValue() external view returns (uint256);

    /**
     * @dev Retrieves the pending CLB value in the liquidity provider.
     * @return The pending CLB value in the liquidity provider.
     */
    function pendingClbValue() external view returns (uint256);

    /**
     * @dev Retrieves the total CLB value in the liquidity provider, combining holding and pending CLB values.
     * @return value The total CLB value in the liquidity provider.
     */
    function totalClbValue() external view returns (uint256 value);

    /**
     * @dev Retrieves the fee rates associated with various actions in the liquidity provider.
     * @return An array of fee rates for different actions within the liquidity pool.
     */
    function feeRates() external view returns (int16[] memory);

    /**
     * @dev Retrieves the token IDs of CLB tokens handled in the liquidity provider
     * @return tokenIds An array of CLB token IDs handled in the liquidity provider.
     */
    function clbTokenIds() external view returns (uint256[] memory tokenIds);

    /**
     * @dev Retrieves the balances of CLB tokens held in the liquidity provider.
     * @return balances An array of CLB token balances held in the liquidity provider.
     */
    function clbTokenBalances() external view returns (uint256[] memory balances);

    /**
     * @dev Retrieves the values of CLB tokens held in the liquidity provider.
     * @return values An array of CLB token value held in the liquidity provider.
     */
    function clbTokenValues() external view returns (uint256[] memory values);

    /**
     * @dev An array of pending CLB token balances for removal.
     * Retrieves the pending CLB token balances that are pending removal from the liquidity provider.
     */
    function pendingRemoveClbBalances() external view returns (uint256[] memory pendingBalances);

    /**
     * @dev Retrieves information about the target of liquidity.
     * @return longShortInfo An integer representing long (1), short (-1), or both side(0).
     */
    function longShortInfo() external view returns (int8);

    /**
     * @dev Checks whether a settle is possible by user for a specific receipt ID.
     * @param receiptId The unique identifier of the receipt associated with the task.
     * @return A boolean indicating whether a settle is possible by user.
     */
    function checkSettleByUser(uint256 receiptId) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ChromaticLPReceipt} from "~/lp/libraries/ChromaticLPReceipt.sol";

/**
 * @title The IChromaticLPLiquidity interface provides methods for adding and removing liquidity, settling transactions, and retrieving information about liquidity receipts. Developers can interact with this interface to facilitate liquidity operations in Chromatic Protocol.
 */
interface IChromaticLPLiquidity {
    /**
     * @dev Adds liquidity to the Chromatic Protocol, minting LP tokens for the specified amount and assigning them to the recipient.
     * @param amount The amount of liquidity to add.
     * @param recipient The address of the recipient for the LP tokens.
     * @return ChromaticLPReceipt A data structure representing the receipt of the liquidity addition.
     */
    function addLiquidity(
        uint256 amount,
        address recipient
    ) external returns (ChromaticLPReceipt memory);

    /**
     * @dev Removes liquidity from the Chromatic Protocol, burning the specified amount of LP tokens and transferring the corresponding assets to the recipient.
     * @param lpTokenAmount The amount of LP tokens to remove.
     * @param recipient The address of the recipient for the withdrawn assets.
     */
    function removeLiquidity(
        uint256 lpTokenAmount,
        address recipient
    ) external returns (ChromaticLPReceipt memory);

    /**
     * @dev Initiates the settlement process for a specific liquidity receipt identified by receiptId.
     * @param receiptId The unique identifier of the liquidity receipt to settle.
     */
    function settle(uint256 receiptId) external;

    /**
     * @dev Retrieves the unique identifiers of all liquidity receipts owned by a given address.
     * @param owner The address of the liquidity provider.
     * @return receiptIds An array of unique identifiers for the liquidity receipts owned by the specified address.
     */
    function getReceiptIdsOf(address owner) external view returns (uint256[] memory);

    /**
     * @dev Retrieves detailed information about a specific liquidity receipt identified by id.
     * @param id The unique identifier of the liquidity receipt to retrieve.
     * @return A data structure representing the liquidity receipt.
     */
    function getReceipt(uint256 id) external view returns (ChromaticLPReceipt memory);

    /**
     * @dev Retrieves the receipt ids of market belongs to receiptId of LP.
     * @param receiptId The unique identifier of the liquidity receipt to retrieve.
     * @return A list of market receiptIds of the liquidity receipt of LP.
     */
    function getMarketReceiptsOf(uint256 receiptId) external view returns (uint256[] memory);

    /**
     * @dev Estimates the minimum amount of liquidity that can be added by automation.
     * @return The minimum amount of liquidity in the settlement token that can be added.
     */
    function estimateMinAddLiquidityAmount() external view returns (uint256);

    /**
     * @dev Estimates the minimum amount of liquidity that can be removed by automation.
     * @return The minimum amount of liquidity in the LP token that can be removed.
     */
    function estimateMinRemoveLiquidityAmount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IChromaticLPLogic {
    function version() external view returns (bytes32);

    function onUpgrade(bytes calldata data) external;

    error OnlyDelegateCall();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title The IChromaticLPMeta interface exposes methods that developers can use to obtain metadata information related to Chromatic Protocol liquidity provider. These functions provide details such as the name and tag associated with a liquidity pool.
 */
interface IChromaticLPMeta {
    /**
     * @dev Emitted when the name of the liquidity provider is updated.
     * @param name The new name of the liquidity provider.
     */
    event SetLpName(string name);
    /**
     * @dev Emitted when the tag of the liquidity provider is updated.
     * @param tag The new tag associated with the liquidity provider.
     */
    event SetLpTag(string tag);

    /**
     * @dev Retrieves the name of the Chromatic Protocol liquidity provider.
     * @return The name of the liquidity provider.
     */
    function lpName() external view returns (string memory);

    /**
     * @dev Retrieves the tag associated with the Chromatic Protocol liquidity provider.
     * @return The tag associated with the liquidity provider
     */
    function lpTag() external view returns (string memory);

    /**
     * @dev Sets the name of the Chromatic Protocol liquidity provider.
     * @param newName The new name for the liquidity provider.
     */
    function setLpName(string memory newName) external;

    /**
     * @dev Sets the tag associated with the Chromatic Protocol liquidity provider.
     * @param newTag The new tag for the liquidity provider.
     */
    function setLpTag(string memory newTag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IChromaticLP} from "~/lp/interfaces/IChromaticLP.sol";

/**
 * @title IChromaticLPRegistry
 * @dev An interface for the Chromatic LP (Liquidity Provider) Registry, responsible for registering and unregistering LPs.
 */
interface IChromaticLPRegistry {
    /**
     * @notice Emitted when a Chromatic LP is successfully registered.
     * @param market The address of the associated market.
     * @param lp The address of the registered Chromatic LP.
     */
    event ChromaticLPRegistered(address indexed market, address indexed lp);

    /**
     * @notice Emitted when a Chromatic LP is successfully unregistered.
     * @param market The address of the associated market.
     * @param lp The address of the unregistered Chromatic LP.
     */
    event ChromaticLPUnregistered(address indexed market, address indexed lp);

    /**
     * @notice Error thrown when a function is called by the DAO.
     */
    error OnlyAccessableByDao();

    /**
     * @notice Error thrown when attempting to register an LP that is already registered.
     */
    error AlreadyRegistered();

    /**
     * @notice Error thrown when attempting to unregister an LP that is not registered.
     */
    error NotRegistered();

    /**
     * @notice Registers a new Chromatic LP.
     * @param lp The address of the Chromatic LP contract to be registered.
     */
    function register(IChromaticLP lp) external;

    /**
     * @notice Unregisters an existing Chromatic LP.
     * @param lp The address of the Chromatic LP contract to be unregistered.
     */
    function unregister(IChromaticLP lp) external;

    /**
     * @notice Retrieves the list of all registered Chromatic LP addresses.
     * @return lpAddresses An array of Chromatic LP addresses.
     */
    function lpList() external view returns (address[] memory lpAddresses);

    /**
     * @notice Retrieves the list of Chromatic LP addresses associated with a specific market.
     * @param market The address of the market for which LPs are to be retrieved.
     * @return lpAddresses An array of Chromatic LP addresses associated with the specified market.
     */
    function lpListByMarket(address market) external view returns (address[] memory lpAddresses);

    /**
     * @notice Retrieves the list of Chromatic LP addresses associated with a specific settlement token.
     * @param token The address of the settlement token for which LPs are to be retrieved.
     * @return lpAddresses An array of Chromatic LP addresses associated with the specified settlement token.
     */
    function lpListBySettlementToken(
        address token
    ) external view returns (address[] memory lpAddresses);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev The ChromaticLPAction enum represents the types of LP actions that can be performed.
 */
enum ChromaticLPAction {
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY
}

/**
 * @title ChromaticLPReceipt
 * @dev A struct representing a receipt of a liquidity-related action in the Chromatic Protocol.
 * @param id Unique identifier of the receipt.
 * @param provider Address of the liquidity provider initiating the action.
 * @param recipient Address of the recipient for the liquidity or assets.
 * @param oracleVersion Version of the oracle used for the action.
 * @param amount Amount associated with the liquidity action.
 * @param pendingLiquidity Pending liquidity awaiting settlement.
 * @param action ChromaticLPAction indicating the type of liquidity-related action.
 * @param needSettle bool flag indicating whether settlement is needed
 */
struct ChromaticLPReceipt {
    uint256 id;
    address provider;
    address recipient;
    uint256 oracleVersion;
    uint256 amount;
    uint256 pendingLiquidity;
    ChromaticLPAction action;
    bool needSettle;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/**
 * @dev Basis points constant representing the value 10000.
 */
uint256 constant BPS = 10000;
uint256 constant MIN_ADD_LIQUIDITY_BIN = 1000;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Errors
 * @dev A library containing error messages for the Chromatic Protocol LP.
 */
library Errors {
    /**
     * @dev Error message for withdrawal amount less than the automation fee.
     */
    string constant WITHDRAWAL_LESS_THAN_AUTOMATION_FEE = "WLA";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title LPConfig
 * @dev A struct representing the configuration parameters of an LP (Liquidity Provider) in the Chromatic Protocol.
 * @param utilizationTargetBPS Target utilization rate for the LP, represented in basis points (BPS).
 * @param rebalanceBPS Rebalance basis points, indicating the percentage change that triggers a rebalance.
 * @param rebalanceCheckingInterval Time interval (in seconds) between checks for rebalance conditions.
 * @param automationFeeReserved Amount reserved as automation fee, used for automated operations within the liquidity pool.
 * @param minHoldingValueToRebalance The minimum holding value required to trigger rebalance.
 */
struct LPConfig {
    uint16 utilizationTargetBPS;
    uint16 rebalanceBPS;
    uint256 rebalanceCheckingInterval;
    uint256 automationFeeReserved;
    uint256 minHoldingValueToRebalance;
}

/**
 * @dev The AllocationStatus enum represents different allocation status scenarios within Chromatic Protocol LP
 */
enum AllocationStatus {
    InRange,
    UnderUtilized,
    OverUtilized
}

/**
 * @title LPConfigLib
 * @dev A library providing utility functions for calculating the allocation status of LPs (Liquidity Providers)
 * based on the provided LPConfig parameters and the current utility.
 */
library LPConfigLib {
    /**
     * @dev Calculates the allocation status of an LP.
     * @param lpconfig An instance of the LPConfig struct representing the configuration of the LP.
     * @param currentUtility The current utility of the LP, used for determining the allocation status.
     * @return allocationStatus The allocation status of the LP based on the provided parameters.
     */
    function allocationStatus(
        LPConfig memory lpconfig,
        uint256 currentUtility
    ) internal pure returns (AllocationStatus) {
        if (uint256(lpconfig.utilizationTargetBPS + lpconfig.rebalanceBPS) < currentUtility) {
            return AllocationStatus.OverUtilized;
        } else if (
            uint256(lpconfig.utilizationTargetBPS - lpconfig.rebalanceBPS) > currentUtility
        ) {
            return AllocationStatus.UnderUtilized;
        } else {
            return AllocationStatus.InRange;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {ChromaticLPReceipt} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title LPState
 * @dev A struct representing the state of a liquidity provider in the Chromatic Protocol.
 * @param market Instance of IChromaticMarket representing the associated market.
 * @param feeRates Array of fee rates for different actions within the liquidity pool.
 * @param distributionRates Mapping of fee rates to distribution rates for each action.
 * @param totalRate Total rate representing the sum of fee rates.
 * @param clbTokenIds Array of CLB token IDs associated with the liquidity pool.
 * @param receipts Mapping of receipt IDs to ChromaticLPReceipts.
 * @param lpReceiptMap Mapping of receipt IDs to lpReceiptIds.
 * @param providerReceiptIds Mapping of provider addresses to receipt IDs using EnumerableSet.
 * @param pendingAddLp Amount pending for addition to the liquidity pool in settlement token.
 * @param pendingAddMarket Amount pending for addition to the market in settlement token.
 * @param pendingRemoveClbAmounts Mapping of fee rates to pending amounts for CLB removal.
 * @param receiptId Current receipt ID for generating new receipts.
 */
struct LPState {
    IChromaticMarket market;
    int16[] feeRates;
    mapping(int16 => uint16) distributionRates;
    uint256 totalRate;
    uint256[] clbTokenIds;
    mapping(uint256 => ChromaticLPReceipt) receipts; // receiptId => receipt
    mapping(uint256 => uint256[]) lpReceiptMap; // receiptId => lpReceiptIds
    mapping(address => EnumerableSet.UintSet) providerReceiptIds; // provider => receiptIds
    uint256 pendingAddLp; // in settlement token
    uint256 pendingAddMarket; // in settlement token
    mapping(int16 => uint256) pendingRemoveClbAmounts; // feeRate => pending remove
    uint256 receiptId;
}

uint256 constant REBALANCE_ID = 1;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {LPState} from "~/lp/libraries/LPState.sol";
import {IChromaticLPErrors} from "~/lp/interfaces/IChromaticLPErrors.sol";
import {ChromaticLPReceipt, ChromaticLPAction} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {LPStateViewLib} from "~/lp/libraries/LPStateView.sol";
import {LPStateValueLib} from "~/lp/libraries/LPStateValue.sol";
import {ChromaticLPLogicBase} from "~/lp/base/ChromaticLPLogicBase.sol";
import {Errors} from "~/lp/libraries/Errors.sol";
import {MIN_ADD_LIQUIDITY_BIN} from "~/lp/libraries/Constants.sol";

/**
 * @title AddLiquidityParam
 * @dev Struct representing parameters for adding liquidity to a liquidity provider in the Chromatic Protocol.
 */
struct AddLiquidityParam {
    uint256 amount; // Amount in settlement token to add liquidity in the LP
    uint256 amountMarket; // Amount of adding to market
    address provider; // Address of the liquidity provider
    address recipient; // Address of the recipient
}

/**
 * @title RemoveLiquidityParam
 * @dev Struct representing parameters for removing liquidity from a liquidity provider in the Chromatic Protocol.
 */
struct RemoveLiquidityParam {
    uint256 amount; // LP token requesting to burn
    address provider; // Address of the liquidity provider
    address recipient; // Address of the recipient
}

/**
 * @title LPStateLogicLib
 * @dev A library providing functions for managing the logic and state transitions of an LP (Liquidity Provider) in the Chromatic Protocol.
 */
library LPStateLogicLib {
    using Math for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using LPStateViewLib for LPState;
    using LPStateLogicLib for LPState;
    using LPStateValueLib for LPState;

    /**
     * @dev Retrieves the next receipt ID and increments the receipt ID counter.
     * @param s_state The storage state of the liquidity provider.
     * @return id The next receipt ID.
     */
    function nextReceiptId(LPState storage s_state) internal returns (uint256 id) {
        id = ++s_state.receiptId;
    }

    /**
     * @dev Adds a receipt to the LPState, updating relevant mappings and sets.
     * @param s_state The storage state of the liquidity provider.
     * @param receipt The Chromatic LP Receipt to be added.
     * @param lpReceipts Array of LpReceipts associated with the Chromatic LP Receipt.
     */
    function addReceipt(
        LPState storage s_state,
        ChromaticLPReceipt memory receipt,
        LpReceipt[] memory lpReceipts
    ) internal {
        s_state.receipts[receipt.id] = receipt;
        uint256[] storage lpReceiptIds = s_state.lpReceiptMap[receipt.id];
        for (uint256 i; i < lpReceipts.length; ) {
            //slither-disable-next-line unused-return
            lpReceiptIds.push(lpReceipts[i].id);

            unchecked {
                ++i;
            }
        }

        EnumerableSet.UintSet storage receiptIdSet = s_state.providerReceiptIds[msg.sender];
        //slither-disable-next-line unused-return
        receiptIdSet.add(receipt.id);
    }

    /**
     * @dev Update a receipt settled from the LPState, cleaning up associated mappings and sets.
     * @param s_state The storage state of the liquidity provider.
     * @param receiptId The ID of the Chromatic LP Receipt to be removed.
     */
    function removeReceipt(LPState storage s_state, uint256 receiptId) internal {
        ChromaticLPReceipt storage receipt = s_state.receipts[receiptId];
        receipt.needSettle = false;

        EnumerableSet.UintSet storage receiptIdSet = s_state.providerReceiptIds[receipt.provider];
        //slither-disable-next-line unused-return
        receiptIdSet.remove(receiptId);
    }

    /**
     * @dev Claims liquidity for a given Chromatic LP Receipt, initiating the transfer of LP tokens to the recipient.
     * @param s_state The storage state of the liquidity provider.
     * @param receipt The Chromatic LP Receipt for which liquidity is to be claimed.
     * @param keeperFee The keeper fee associated with the claim.
     */
    function claimLiquidity(
        LPState storage s_state,
        ChromaticLPReceipt memory receipt,
        uint256 keeperFee
    ) internal {
        // pass ChromaticLPReceipt as calldata
        // mint and transfer lp pool token to provider in callback
        // valueOfSupply() : aleady keeperFee excluded
        s_state.decreasePendingAdd(keeperFee, 0);

        s_state.market.claimLiquidityBatch(
            s_state.lpReceiptMap[receipt.id],
            abi.encode(receipt, s_state.valueOfSupply(), keeperFee)
        );

        s_state.removeReceipt(receipt.id);
    }

    /**
     * @dev Initiates the withdrawal of liquidity for a given Chromatic LP Receipt.
     * @param s_state The storage state of the liquidity provider.
     * @param receipt The Chromatic LP Receipt for which liquidity withdrawal is to be initiated.
     * @param keeperFee The keeper fee associated with the withdrawal.
     */
    function withdrawLiquidity(
        LPState storage s_state,
        ChromaticLPReceipt memory receipt,
        uint256 keeperFee
    ) internal {
        // do claim
        // pass ChromaticLPReceipt as calldata
        uint256[] memory receiptIds = s_state.lpReceiptMap[receipt.id];
        LpReceipt[] memory lpReceits = s_state.market.getLpReceipts(receiptIds);

        s_state.market.withdrawLiquidityBatch(
            s_state.lpReceiptMap[receipt.id],
            abi.encode(receipt, lpReceits, s_state.valueOfSupply(), keeperFee) // FIXME
        );

        s_state.removeReceipt(receipt.id);
    }

    /**
     * @dev Distributes a given amount among different fee bins based on their distribution rates.
     * @param s_state The storage state of the liquidity provider.
     * @param amount The total amount to be distributed.
     * @return feeRates An array containing the feeRate of bins.
     * @return amounts An array containing the distributed amounts for each fee bin.
     * @return totalAmount The total amount after distribution.
     */
    function distributeAmount(
        LPState storage s_state,
        uint256 amount
    )
        internal
        view
        returns (int16[] memory feeRates, uint256[] memory amounts, uint256 totalAmount)
    {
        uint256 binCount = s_state.binCount();

        feeRates = new int16[](binCount);
        amounts = new uint256[](binCount);
        uint256 index;
        for (uint256 i = 0; i < binCount; ) {
            amounts[index] = amount.mulDiv(
                s_state.distributionRates[s_state.feeRates[i]],
                s_state.totalRate
            );
            if (amounts[index] > MIN_ADD_LIQUIDITY_BIN) {
                totalAmount += amounts[index];
                feeRates[index] = s_state.feeRates[i];
                unchecked {
                    ++index;
                }
            } else {
                assembly {
                    mstore(amounts, sub(mload(amounts), 1))
                    mstore(feeRates, sub(mload(feeRates), 1))
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Adds liquidity to the liquidity pool and updates the LPState accordingly.
     * @param s_state The storage state of the liquidity provider.
     * @param feeRates An array of fee rates for different actions within the liquidity pool.
     * @param amounts An array of amounts representing the liquidity to be added.
     * @param addParam Parameters for adding liquidity.
     * @return receipt The Chromatic LP Receipt representing the addition of liquidity.
     */
    function addLiquidity(
        LPState storage s_state,
        int16[] memory feeRates,
        uint256[] memory amounts,
        AddLiquidityParam memory addParam
    ) internal returns (ChromaticLPReceipt memory receipt) {
        LpReceipt[] memory lpReceipts = s_state.market.addLiquidityBatch(
            address(this),
            feeRates,
            amounts,
            abi.encode(
                ChromaticLPLogicBase.AddLiquidityBatchCallbackData({
                    provider: addParam.provider,
                    liquidityAmount: addParam.amountMarket,
                    holdingAmount: addParam.amount - addParam.amountMarket
                })
            )
        );

        receipt = ChromaticLPReceipt({
            id: s_state.nextReceiptId(),
            provider: addParam.provider,
            recipient: addParam.recipient,
            oracleVersion: lpReceipts[0].oracleVersion,
            amount: addParam.amount,
            pendingLiquidity: addParam.amountMarket,
            action: ChromaticLPAction.ADD_LIQUIDITY,
            needSettle: true
        });

        s_state.addReceipt(receipt, lpReceipts);
        s_state.increasePendingAdd(addParam.amount, addParam.amountMarket);
    }

    /**
     * @dev Removes liquidity from the liquidity pool and updates the LPState accordingly.
     * @param s_state The storage state of the liquidity provider.
     * @param clbTokenAmounts The amounts of CLB tokens to be removed for each fee bin.
     * @param removeParam Parameters for removing liquidity.
     * @return receipt The Chromatic LP Receipt representing the removal of liquidity.
     */
    function removeLiquidity(
        LPState storage s_state,
        int16[] memory feeRates,
        uint256[] memory clbTokenAmounts,
        RemoveLiquidityParam memory removeParam
    ) internal returns (ChromaticLPReceipt memory receipt) {
        LpReceipt[] memory lpReceipts = s_state.market.removeLiquidityBatch(
            address(this),
            feeRates,
            clbTokenAmounts,
            abi.encode(
                ChromaticLPLogicBase.RemoveLiquidityBatchCallbackData({
                    provider: removeParam.provider,
                    recipient: removeParam.recipient,
                    lpTokenAmount: removeParam.amount,
                    clbTokenAmounts: clbTokenAmounts
                })
            )
        );

        receipt = ChromaticLPReceipt({
            id: s_state.nextReceiptId(),
            provider: removeParam.provider,
            recipient: removeParam.recipient,
            oracleVersion: lpReceipts[0].oracleVersion,
            amount: removeParam.amount,
            pendingLiquidity: 0,
            action: ChromaticLPAction.REMOVE_LIQUIDITY,
            needSettle: true
        });

        s_state.addReceipt(receipt, lpReceipts);
        s_state.increasePendingClb(lpReceipts);
    }

    /**
     * @dev Increases the pending add amounts
     * @param s_state The storage state of the liquidity provider.
     * @param amountToLp pending amount to the lp when addLiquidity called.
     * @param amountToMarket pending addLiquidity amount to market not claimed.
     */
    function increasePendingAdd(
        LPState storage s_state,
        uint256 amountToLp,
        uint256 amountToMarket
    ) internal {
        s_state.pendingAddLp += amountToLp;
        s_state.pendingAddMarket += amountToMarket;
    }

    /**
     * @dev Decreases the pending add amounts.
     * @param amountToLp pending amount to the lp when addLiquidity called.
     * @param amountToMarket pending addLiquidity amount to the market claimed.
     */
    function decreasePendingAdd(
        LPState storage s_state,
        uint256 amountToLp,
        uint256 amountToMarket
    ) internal {
        s_state.pendingAddLp -= amountToLp;
        s_state.pendingAddMarket -= amountToMarket;
    }

    /**
     * @dev Increases the pending CLB amounts based on the given LpReceipts.
     * @param s_state The storage state of the liquidity provider.
     * @param lpReceipts Array of LpReceipts for which pending CLB amounts are to be increased.
     */
    function increasePendingClb(LPState storage s_state, LpReceipt[] memory lpReceipts) internal {
        for (uint256 i; i < lpReceipts.length; ) {
            s_state.pendingRemoveClbAmounts[lpReceipts[i].tradingFeeRate] += lpReceipts[i].amount;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Decreases the pending CLB amounts based on the given LpReceipts.
     * @param s_state The storage state of the liquidity provider.
     * @param lpReceits Array of LpReceipts for which pending CLB amounts are to be decreased.
     */
    function decreasePendingClb(LPState storage s_state, LpReceipt[] memory lpReceits) internal {
        for (uint256 i; i < lpReceits.length; ) {
            LpReceipt memory lpReceit = lpReceits[i];

            s_state.pendingRemoveClbAmounts[lpReceit.tradingFeeRate] -= lpReceit.amount;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Calculates the amounts of pending CLB tokens to be removed
     * based on the given LP token amount and total LP token supply.
     * @param s_state The storage state of the liquidity provider.
     * @param lpTokenAmount The total amount of LP tokens to be removed.
     * @param totalSupply The total supply of LP tokens.
     * @return feeRates An array containing the feeRate of bins.
     * @return removeAmounts An array containing the amounts of pending CLB tokens to be removed for each fee bin.
     */
    function calcRemoveClbAmounts(
        LPState storage s_state,
        uint256 lpTokenAmount,
        uint256 totalSupply
    ) internal view returns (int16[] memory feeRates, uint256[] memory removeAmounts) {
        uint256 binCount = s_state.binCount();
        feeRates = new int16[](binCount);
        removeAmounts = new uint256[](binCount);

        uint256[] memory clbBalances = s_state.clbTokenBalances();
        uint256[] memory pendingClb = s_state.pendingRemoveClbBalances();

        uint256 index;
        for (uint256 i; i < binCount; ) {
            removeAmounts[index] = (clbBalances[i] + pendingClb[i]).mulDiv(
                lpTokenAmount,
                totalSupply,
                Math.Rounding.Up
            );
            if (removeAmounts[index] > clbBalances[i]) {
                removeAmounts[index] = clbBalances[i];
            }
            if (removeAmounts[index] != 0) {
                feeRates[index] = s_state.feeRates[i];
                unchecked {
                    ++index;
                }
            } else {
                // decrease length
                assembly {
                    mstore(removeAmounts, sub(mload(removeAmounts), 1))
                    mstore(feeRates, sub(mload(feeRates), 1))
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function calcRebalanceRemoveAmounts(
        LPState storage s_state,
        uint256 currentUtility,
        uint256 utilizationTargetBPS
    ) internal view returns (int16[] memory feeRates, uint256[] memory removeAmounts) {
        uint256 binCount = s_state.binCount();
        removeAmounts = new uint256[](binCount);
        feeRates = new int16[](binCount);

        uint256[] memory _clbTokenBalances = s_state.clbTokenBalances();
        uint256 index;
        for (uint256 i; i < binCount; ) {
            removeAmounts[index] = _clbTokenBalances[i].mulDiv(
                currentUtility - utilizationTargetBPS,
                currentUtility
            );
            if (removeAmounts[index] == 0) {
                assembly {
                    mstore(removeAmounts, sub(mload(removeAmounts), 1))
                    mstore(feeRates, sub(mload(feeRates), 1))
                }
            } else {
                feeRates[index] = s_state.feeRates[i];
                unchecked {
                    ++index;
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LPState, REBALANCE_ID} from "~/lp/libraries/LPState.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IChromaticLPErrors} from "~/lp/interfaces/IChromaticLPErrors.sol";
import {BPS} from "~/lp/libraries/Constants.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";

/**
 * @title LPStateSetupLib
 * @dev A library providing functions for initializing and setting up the state of an LP (Liquidity Provider) in the Chromatic Protocol.
 */
library LPStateSetupLib {
    /**
     * @dev Initializes the LPState with the provided market, fee rates, and distribution rates.
     * @param s_state The storage state of the liquidity provider.
     * @param market The Chromatic Market interface to be associated with the LPState.
     * @param feeRates The array of fee rates for different bins.
     * @param distributionRates The array of distribution rates corresponding to fee rates.
     */
    function initialize(
        LPState storage s_state,
        IChromaticMarket market,
        int16[] memory feeRates,
        uint16[] memory distributionRates
    ) internal {
        s_state.market = market;
        _setupState(s_state, feeRates, distributionRates);
    }

    /**
     * @dev Sets up the internal state of the LPState with the provided fee rates and distribution rates.
     * @param s_state The storage state of the liquidity provider.
     * @param feeRates The array of fee rates for different bins.
     * @param distributionRates The array of distribution rates corresponding to fee rates.
     */
    function _setupState(
        LPState storage s_state,
        int16[] memory feeRates,
        uint16[] memory distributionRates
    ) private {
        uint256 totalRate;
        for (uint256 i; i < distributionRates.length; ) {
            s_state.distributionRates[feeRates[i]] = distributionRates[i];
            totalRate += distributionRates[i];

            unchecked {
                ++i;
            }
        }
        s_state.totalRate = totalRate;
        s_state.feeRates = feeRates;
        s_state.receiptId = REBALANCE_ID; // reserved 1 for rebalance task id

        _setupClbTokenIds(s_state, feeRates);
    }

    /**
     * @dev Sets up the CLB (Cumulative Loyalty Bonus) token IDs based on the provided fee rates.
     * @param s_state The storage state of the liquidity provider.
     * @param _feeRates The array of fee rates for different bins.
     */
    function _setupClbTokenIds(LPState storage s_state, int16[] memory _feeRates) private {
        s_state.clbTokenIds = new uint256[](_feeRates.length);
        for (uint256 i; i < _feeRates.length; ) {
            s_state.clbTokenIds[i] = CLBTokenLib.encodeId(_feeRates[i]);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {LPState} from "~/lp/libraries/LPState.sol";
import {ValueInfo} from "~/lp/interfaces/IChromaticLPLens.sol";
import {BPS} from "~/lp/libraries/Constants.sol";
import {LPStateViewLib} from "~/lp/libraries/LPStateView.sol";
import {Errors} from "~/lp/libraries/Errors.sol";

/**
 * @title LPStateValueLib
 * @dev A library providing value-related functions for LPState in the Chromatic Protocol.
 */
library LPStateValueLib {
    using LPStateValueLib for LPState;
    using LPStateViewLib for LPState;

    using Math for uint256;

    /**
     * @dev Retrieves the current utility and total value of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return currentUtility The current utility percentage (basis points).
     * @return _totalValue The total value of the LPState.
     */
    function utilizationInfo(
        LPState storage s_state
    ) internal view returns (uint16 currentUtility, uint256 _totalValue) {
        ValueInfo memory value = s_state.valueInfo();
        _totalValue = value.total;
        if (_totalValue == 0) {
            currentUtility = 0;
        } else {
            currentUtility = uint16(uint256(value.total - value.holding).mulDiv(BPS, value.total));
        }
    }

    /**
     * @dev Retrieves the total value of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return value The total value of the LPState.
     */
    function totalValue(LPState storage s_state) internal view returns (uint256 value) {
        value = (s_state.holdingValue() + s_state.pendingValue() + s_state.totalClbValue());
    }

    /**
     * @dev Retrieves the total value of the CLP token.
     * @param s_state The storage state of the liquidity provider.
     * @return value The total value of the CLP token.
     */
    function valueOfSupply(LPState storage s_state) internal view returns (uint256) {
        return s_state.totalValue() - s_state.pendingAdd();
    }

    /**
     * @dev Retrieves the value information of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return info The ValueInfo struct containing total, holding, pending, holdingClb, and pendingClb values.
     */
    function valueInfo(LPState storage s_state) internal view returns (ValueInfo memory info) {
        info = ValueInfo({
            total: 0,
            holding: s_state.holdingValue(),
            pending: s_state.pendingValue(),
            holdingClb: s_state.holdingClbValue(),
            pendingClb: s_state.pendingClbValue()
        });
        info.total = info.holding + info.pending + info.holdingClb + info.pendingClb;
    }

    /**
     * @dev Retrieves the holding value (balance of the settlement token) of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return value The holding value of the LPState.
     */
    function holdingValue(LPState storage s_state) internal view returns (uint256) {
        return s_state.settlementToken().balanceOf(address(this));
    }

    /**
     * @dev Retrieves the pending value (amount pending for addition to the market) of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return value The pending value of the LPState.
     */
    function pendingValue(LPState storage s_state) internal view returns (uint256) {
        return s_state.pendingAddMarket;
    }

    /**
     * @dev Retrieves the pending value (amount pending for addition to the liquidity pool) of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return value The pending value of the LPState.
     */
    function pendingAdd(LPState storage s_state) internal view returns (uint256) {
        return s_state.pendingAddLp;
    }

    /**
     * @dev Retrieves the holding CLB (Cumulative Loyalty Bonus) value of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return value The holding CLB value of the LPState.
     */
    function holdingClbValue(LPState storage s_state) internal view returns (uint256 value) {
        uint256[] memory clbSupplies = s_state.clbTotalSupplies();
        uint256[] memory binValues = s_state.market.getBinValues(s_state.feeRates);
        uint256[] memory clbTokenAmounts = s_state.clbTokenBalances();
        for (uint256 i; i < binValues.length; ) {
            uint256 clbAmount = clbTokenAmounts[i];
            value += (clbAmount == 0 || clbSupplies[i] == 0 || binValues[i] == 0)
                ? 0
                : clbAmount.mulDiv(binValues[i], clbSupplies[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Retrieves the pending CLB (Cumulative Loyalty Bonus) value of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return value The pending CLB value of the LPState.
     */
    function pendingClbValue(LPState storage s_state) internal view returns (uint256 value) {
        uint256[] memory clbSupplies = s_state.clbTotalSupplies();
        uint256[] memory binValues = s_state.market.getBinValues(s_state.feeRates);
        for (uint256 i; i < binValues.length; ) {
            uint256 clbAmount = s_state.pendingRemoveClbAmounts[s_state.feeRates[i]];
            value += (clbAmount == 0 || clbSupplies[i] == 0 || binValues[i] == 0)
                ? 0
                : clbAmount.mulDiv(binValues[i], clbSupplies[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Retrieves the total CLB (Cumulative Loyalty Bonus) value of the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return value The total CLB value of the LPState.
     */
    function totalClbValue(LPState storage s_state) internal view returns (uint256 value) {
        uint256[] memory clbSupplies = s_state.clbTotalSupplies();
        uint256[] memory binValues = s_state.market.getBinValues(s_state.feeRates);
        uint256[] memory clbTokenAmounts = s_state.clbTokenBalances();
        for (uint256 i; i < binValues.length; ) {
            uint256 clbAmount = clbTokenAmounts[i] +
                s_state.pendingRemoveClbAmounts[s_state.feeRates[i]];
            value += (clbAmount == 0 || clbSupplies[i] == 0 || binValues[i] == 0)
                ? 0
                : clbAmount.mulDiv(binValues[i], clbSupplies[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Retrieves the CLB token balances associated with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return _clbTokenBalances The array of CLB token balances.
     */
    function clbTokenBalances(
        LPState storage s_state
    ) internal view returns (uint256[] memory _clbTokenBalances) {
        address[] memory _owners = new address[](s_state.binCount());
        for (uint256 i; i < s_state.binCount(); ) {
            _owners[i] = address(this);
            unchecked {
                ++i;
            }
        }
        _clbTokenBalances = s_state.clbToken().balanceOfBatch(_owners, s_state.clbTokenIds);
    }

    /**
     * @dev Retrieves the CLB token balances associated with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return _clbTokenValues The array of CLB token values.
     */
    function clbTokenValues(
        LPState storage s_state
    ) internal view returns (uint256[] memory _clbTokenValues) {
        _clbTokenValues = new uint256[](s_state.binCount());
        uint256[] memory clbSupplies = s_state.clbTotalSupplies();
        uint256[] memory binValues = s_state.market.getBinValues(s_state.feeRates);
        uint256[] memory clbTokenAmounts = s_state.clbTokenBalances();
        for (uint256 i; i < s_state.binCount(); ) {
            _clbTokenValues[i] = clbSupplies[i] == 0
                ? 0
                : binValues[i].mulDiv(clbTokenAmounts[i], clbSupplies[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Retrieves the total supplies of CLB tokens associated with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return clbTokenTotalSupplies The array of total supplies of CLB tokens.
     */
    function clbTotalSupplies(
        LPState storage s_state
    ) internal view returns (uint256[] memory clbTokenTotalSupplies) {
        clbTokenTotalSupplies = s_state.clbToken().totalSupplyBatch(s_state.clbTokenIds);
    }

    /**
     * @dev Retrieves the pending CLB balances associated with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return pendingBalances The array of pending CLB balances.
     */
    function pendingRemoveClbBalances(
        LPState storage s_state
    ) internal view returns (uint256[] memory pendingBalances) {
        pendingBalances = new uint256[](s_state.binCount());
        for (uint256 i; i < s_state.binCount(); ) {
            pendingBalances[i] = s_state.pendingRemoveClbAmounts[s_state.feeRates[i]];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Retrieves information about the target of liquidity with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return An integer representing long (1), short (-1), or both side(0).
     */
    function longShortInfo(LPState storage s_state) internal view returns (int8) {
        //slither-disable-next-line uninitialized-local
        int8 long; // = 0
        //slither-disable-next-line uninitialized-local
        int8 short; // = 0
        for (uint256 i; i < s_state.binCount(); ) {
            if (s_state.feeRates[i] > 0) long = 1;
            else if (s_state.feeRates[i] < 0) short = -1;
            unchecked {
                ++i;
            }
        }
        return long + short;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ChromaticLPReceipt} from "~/lp/libraries/ChromaticLPReceipt.sol";
import {LPState} from "~/lp/libraries/LPState.sol";

/**
 * @title LPStateViewLib
 * @dev A library providing view functions for querying information from an LPState instance.
 */
library LPStateViewLib {
    using LPStateViewLib for LPState;

    /**
     * @dev Retrieves the settlement token associated with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return IERC20Metadata The settlement token interface.
     */
    function settlementToken(LPState storage s_state) internal view returns (IERC20Metadata) {
        return s_state.market.settlementToken();
    }

    /**
     * @dev Retrieves the CLB token associated with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return ICLBToken The CLB token interface.
     */
    function clbToken(LPState storage s_state) internal view returns (ICLBToken) {
        return s_state.market.clbToken();
    }

    /**
     * @dev Retrieves a specific ChromaticLPReceipt by ID.
     * @param s_state The storage state of the liquidity provider.
     * @param receiptId The ID of the ChromaticLPReceipt to retrieve.
     * @return ChromaticLPReceipt The retrieved ChromaticLPReceipt.
     */
    function getReceipt(
        LPState storage s_state,
        uint256 receiptId
    ) internal view returns (ChromaticLPReceipt memory) {
        return s_state.receipts[receiptId];
    }

    /**
     * @dev Retrieves the number of fee bins in the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return uint256 The number of fee bins.
     */
    function binCount(LPState storage s_state) internal view returns (uint256) {
        return s_state.feeRates.length;
    }

    /**
     * @dev Retrieves the oracle version associated with the LPState.
     * @param s_state The storage state of the liquidity provider.
     * @return uint256 The current oracle version.
     */
    function oracleVersion(LPState storage s_state) internal view returns (uint256) {
        return s_state.market.oracleProvider().currentVersion().version;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title TrimAddress
 * @dev A library providing a function to trim the hexadecimal representation of an address.
 */
library TrimAddress {
    /**
     * @dev Trims the hexadecimal representation of an address to the specified length.
     * @param self The address to be trimmed.
     * @param length The desired length of the trimmed address.
     * @return converted The trimmed address as a bytes array.
     */
    function trimAddress(
        address self,
        uint8 length
    ) internal pure returns (bytes memory converted) {
        converted = new bytes(length);
        bytes memory _base = "0123456789abcdef";
        uint160 value = uint160(self);

        value = value >> (4 * (39 - length));
        for (uint256 i = 0; i < length; ) {
            value = value >> 4;
            converted[length - i - 1] = _base[uint8(value % 16)];
            unchecked {
                ++i;
            }
        }
    }
}