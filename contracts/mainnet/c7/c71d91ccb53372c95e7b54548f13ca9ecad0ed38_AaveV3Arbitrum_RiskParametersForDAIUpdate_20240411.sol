// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Bridge role
   * @return The id of the Bridge role
   */
  function BRIDGE_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an address as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableAToken} from './IInitializableAToken.sol';

/**
 * @title IAToken
 * @author Aave
 * @notice Defines the basic interface for an AToken.
 */
interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The scaled amount being transferred
   * @param index The next liquidity index of the reserve
   */
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @notice Mints `amount` aTokens to `user`
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted aTokens
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @notice Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @dev In some instances, the mint event could be emitted from a burn transaction
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the aTokens will be burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The next liquidity index of the reserve
   */
  function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index) external;

  /**
   * @notice Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   */
  function transferOnLiquidation(address from, address to, uint256 value) external;

  /**
   * @notice Transfers the underlying asset to `target`.
   * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the underlying
   * @param amount The amount getting transferred
   */
  function transferUnderlyingTo(address target, uint256 amount) external;

  /**
   * @notice Handles the underlying received by the aToken after the transfer has been completed.
   * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
   * transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
   * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
   * @param user The user executing the repayment
   * @param onBehalfOf The address of the user who will get his debt reduced/removed
   * @param amount The amount getting repaid
   */
  function handleRepayment(address user, address onBehalfOf, uint256 amount) external;

  /**
   * @notice Allow passing a signed message to approve spending
   * @dev implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
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
   * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
   * @return Address of the Aave treasury
   */
  function RESERVE_TREASURY_ADDRESS() external view returns (address);

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the nonce for owner.
   * @param owner The address of the owner
   * @return The nonce of the owner
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IAaveIncentivesController
 * @author Aave
 * @notice Defines the basic interface for an Aave Incentives Controller.
 * @dev It only contains one single function, needed as a hook on aToken and debtToken transfers.
 */
interface IAaveIncentivesController {
  /**
   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
   * @dev The units of `totalSupply` and `userBalance` should be the same.
   * @param user The address of the user whose asset balance has changed
   * @param totalSupply The total supply of the asset prior to user balance change
   * @param userBalance The previous user balance prior to balance change
   */
  function handleAction(address user, uint256 totalSupply, uint256 userBalance) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPriceOracleGetter} from './IPriceOracleGetter.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IAaveOracle
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IAaveOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IReserveInterestRateStrategy} from './IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IDefaultInterestRateStrategy
 * @author Aave
 * @notice Defines the basic interface of the DefaultReserveInterestRateStrategy
 */
interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
  /**
   * @notice Returns the usage ratio at which the pool aims to obtain most competitive borrow rates.
   * @return The optimal usage ratio, expressed in ray.
   */
  function OPTIMAL_USAGE_RATIO() external view returns (uint256);

  /**
   * @notice Returns the optimal stable to total debt ratio of the reserve.
   * @return The optimal stable to total debt ratio, expressed in ray.
   */
  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @notice Returns the excess usage ratio above the optimal.
   * @dev It's always equal to 1-optimal usage ratio (added as constant for gas optimizations)
   * @return The max excess usage ratio, expressed in ray.
   */
  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

  /**
   * @notice Returns the excess stable debt ratio above the optimal.
   * @dev It's always equal to 1-optimal stable to total debt ratio (added as constant for gas optimizations)
   * @return The max excess stable to total debt ratio, expressed in ray.
   */
  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @notice Returns the address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the variable rate slope below optimal usage ratio
   * @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The variable rate slope, expressed in ray
   */
  function getVariableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the variable rate slope above optimal usage ratio
   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The variable rate slope, expressed in ray
   */
  function getVariableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope below optimal usage ratio
   * @dev It's the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The stable rate slope, expressed in ray
   */
  function getStableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope above optimal usage ratio
   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The stable rate slope, expressed in ray
   */
  function getStableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate excess offset
   * @dev It's an additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
   * @return The stable rate excess offset, expressed in ray
   */
  function getStableRateExcessOffset() external view returns (uint256);

  /**
   * @notice Returns the base stable borrow rate
   * @return The base stable borrow rate, expressed in ray
   */
  function getBaseStableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the base variable borrow rate
   * @return The base variable borrow rate, expressed in ray
   */
  function getBaseVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the maximum variable borrow rate
   * @return The maximum variable borrow rate, expressed in ray
   */
  function getMaxVariableBorrowRate() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';
import {IPool} from './IPool.sol';

/**
 * @title IInitializableAToken
 * @author Aave
 * @notice Interface for the initialize function on AToken
 */
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals The decimals of the underlying
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the aToken
   * @param pool The pool contract that is initializing this contract
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   */
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   */
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   */
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   */
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   */
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   */
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   */
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   */
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   */
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   */
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   */
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   */
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @notice Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   * @return The backed amount
   */
  function backUnbacked(address asset, uint256 amount, uint256 fee) external returns (uint256);

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   */
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   */
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   */
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   */
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   */
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   */
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   */
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   */
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   */
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   */
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://docs.aave.com/developers/
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://docs.aave.com/developers/
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   */
  function getUserAccountData(
    address user
  )
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   */
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   */
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   */
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   */
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(
    address asset
  ) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(
    address user
  ) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
   * "dynamic" variable index based on time, current stored index and virtual rate at the current
   * moment (approx. a borrower would get if opening a position). This means that is always used in
   * combination with variable debt supply/balances.
   * If using this function externally, consider that is possible to have an increasing normalized
   * variable debt that is not equivalent to how the variable debt index would be updated in storage
   * (e.g. only updates with non-zero variable debt supply)
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   */
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   */
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   */
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(address token, address to, uint256 amount) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   */
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   */
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   */
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   */
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   */
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   */
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   */
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   */
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ConfiguratorInputTypes} from '../protocol/libraries/types/ConfiguratorInputTypes.sol';

/**
 * @title IPoolConfigurator
 * @author Aave
 * @notice Defines the basic interface for a Pool configurator.
 */
interface IPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   */
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing is enabled, false otherwise
   */
  event ReserveBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when flashloans are enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if flashloans are enabled, false otherwise
   */
  event ReserveFlashLoaning(address indexed asset, bool enabled);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   */
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled or disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing is enabled, false otherwise
   */
  event ReserveStableRateBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when a reserve is activated or deactivated
   * @param asset The address of the underlying asset of the reserve
   * @param active True if reserve is active, false otherwise
   */
  event ReserveActive(address indexed asset, bool active);

  /**
   * @dev Emitted when a reserve is frozen or unfrozen
   * @param asset The address of the underlying asset of the reserve
   * @param frozen True if reserve is frozen, false otherwise
   */
  event ReserveFrozen(address indexed asset, bool frozen);

  /**
   * @dev Emitted when a reserve is paused or unpaused
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if reserve is paused, false otherwise
   */
  event ReservePaused(address indexed asset, bool paused);

  /**
   * @dev Emitted when a reserve is dropped.
   * @param asset The address of the underlying asset of the reserve
   */
  event ReserveDropped(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldReserveFactor The old reserve factor, expressed in bps
   * @param newReserveFactor The new reserve factor, expressed in bps
   */
  event ReserveFactorChanged(
    address indexed asset,
    uint256 oldReserveFactor,
    uint256 newReserveFactor
  );

  /**
   * @dev Emitted when the borrow cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldBorrowCap The old borrow cap
   * @param newBorrowCap The new borrow cap
   */
  event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

  /**
   * @dev Emitted when the supply cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldSupplyCap The old supply cap
   * @param newSupplyCap The new supply cap
   */
  event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

  /**
   * @dev Emitted when the liquidation protocol fee of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldFee The old liquidation protocol fee, expressed in bps
   * @param newFee The new liquidation protocol fee, expressed in bps
   */
  event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

  /**
   * @dev Emitted when the unbacked mint cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldUnbackedMintCap The old unbacked mint cap
   * @param newUnbackedMintCap The new unbacked mint cap
   */
  event UnbackedMintCapChanged(
    address indexed asset,
    uint256 oldUnbackedMintCap,
    uint256 newUnbackedMintCap
  );

  /**
   * @dev Emitted when the category of an asset in eMode is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldCategoryId The old eMode asset category
   * @param newCategoryId The new eMode asset category
   */
  event EModeAssetCategoryChanged(address indexed asset, uint8 oldCategoryId, uint8 newCategoryId);

  /**
   * @dev Emitted when a new eMode category is added.
   * @param categoryId The new eMode category id
   * @param ltv The ltv for the asset category in eMode
   * @param liquidationThreshold The liquidationThreshold for the asset category in eMode
   * @param liquidationBonus The liquidationBonus for the asset category in eMode
   * @param oracle The optional address of the price oracle specific for this category
   * @param label A human readable identifier for the category
   */
  event EModeCategoryAdded(
    uint8 indexed categoryId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    address oracle,
    string label
  );

  /**
   * @dev Emitted when a reserve interest strategy contract is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldStrategy The address of the old interest strategy contract
   * @param newStrategy The address of the new interest strategy contract
   */
  event ReserveInterestRateStrategyChanged(
    address indexed asset,
    address oldStrategy,
    address newStrategy
  );

  /**
   * @dev Emitted when an aToken implementation is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   */
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   */
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   */
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the debt ceiling of an asset is set.
   * @param asset The address of the underlying asset of the reserve
   * @param oldDebtCeiling The old debt ceiling
   * @param newDebtCeiling The new debt ceiling
   */
  event DebtCeilingChanged(address indexed asset, uint256 oldDebtCeiling, uint256 newDebtCeiling);

  /**
   * @dev Emitted when the the siloed borrowing state for an asset is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldState The old siloed borrowing state
   * @param newState The new siloed borrowing state
   */
  event SiloedBorrowingChanged(address indexed asset, bool oldState, bool newState);

  /**
   * @dev Emitted when the bridge protocol fee is updated.
   * @param oldBridgeProtocolFee The old protocol fee, expressed in bps
   * @param newBridgeProtocolFee The new protocol fee, expressed in bps
   */
  event BridgeProtocolFeeUpdated(uint256 oldBridgeProtocolFee, uint256 newBridgeProtocolFee);

  /**
   * @dev Emitted when the total premium on flashloans is updated.
   * @param oldFlashloanPremiumTotal The old premium, expressed in bps
   * @param newFlashloanPremiumTotal The new premium, expressed in bps
   */
  event FlashloanPremiumTotalUpdated(
    uint128 oldFlashloanPremiumTotal,
    uint128 newFlashloanPremiumTotal
  );

  /**
   * @dev Emitted when the part of the premium that goes to protocol is updated.
   * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
   * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
   */
  event FlashloanPremiumToProtocolUpdated(
    uint128 oldFlashloanPremiumToProtocol,
    uint128 newFlashloanPremiumToProtocol
  );

  /**
   * @dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the reserve is borrowable in isolation, false otherwise
   */
  event BorrowableInIsolationChanged(address asset, bool borrowable);

  /**
   * @notice Initializes multiple reserves.
   * @param input The array of initialization parameters
   */
  function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

  /**
   * @dev Updates the aToken implementation for the reserve.
   * @param input The aToken update parameters
   */
  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input) external;

  /**
   * @notice Updates the stable debt token implementation for the reserve.
   * @param input The stableDebtToken update parameters
   */
  function updateStableDebtToken(
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) external;

  /**
   * @notice Updates the variable debt token implementation for the asset.
   * @param input The variableDebtToken update parameters
   */
  function updateVariableDebtToken(
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) external;

  /**
   * @notice Configures borrowing on a reserve.
   * @dev Can only be disabled (set to false) if stable borrowing is disabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing needs to be enabled, false otherwise
   */
  function setReserveBorrowing(address asset, bool enabled) external;

  /**
   * @notice Configures the reserve collateralization parameters.
   * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
   * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   */
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @notice Enable or disable stable rate borrowing on a reserve.
   * @dev Can only be enabled (set to true) if borrowing is enabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing needs to be enabled, false otherwise
   */
  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  /**
   * @notice Enable or disable flashloans on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if flashloans need to be enabled, false otherwise
   */
  function setReserveFlashLoaning(address asset, bool enabled) external;

  /**
   * @notice Activate or deactivate a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param active True if the reserve needs to be active, false otherwise
   */
  function setReserveActive(address asset, bool active) external;

  /**
   * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
   * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
   * @param asset The address of the underlying asset of the reserve
   * @param freeze True if the reserve needs to be frozen, false otherwise
   */
  function setReserveFreeze(address asset, bool freeze) external;

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
   * borrowed amount will be accumulated in the isolated collateral's total debt exposure
   * @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the asset should be borrowable in isolation, false otherwise
   */
  function setBorrowableInIsolation(address asset, bool borrowable) external;

  /**
   * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
   * swap interest rate, liquidate, atoken transfers).
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if pausing the reserve, false if unpausing
   */
  function setReservePause(address asset, bool paused) external;

  /**
   * @notice Updates the reserve factor of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newReserveFactor The new reserve factor of the reserve
   */
  function setReserveFactor(address asset, uint256 newReserveFactor) external;

  /**
   * @notice Sets the interest rate strategy of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newRateStrategyAddress The address of the new interest strategy contract
   */
  function setReserveInterestRateStrategyAddress(
    address asset,
    address newRateStrategyAddress
  ) external;

  /**
   * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
   * are suspended.
   * @param paused True if protocol needs to be paused, false otherwise
   */
  function setPoolPause(bool paused) external;

  /**
   * @notice Updates the borrow cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newBorrowCap The new borrow cap of the reserve
   */
  function setBorrowCap(address asset, uint256 newBorrowCap) external;

  /**
   * @notice Updates the supply cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newSupplyCap The new supply cap of the reserve
   */
  function setSupplyCap(address asset, uint256 newSupplyCap) external;

  /**
   * @notice Updates the liquidation protocol fee of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
   */
  function setLiquidationProtocolFee(address asset, uint256 newFee) external;

  /**
   * @notice Updates the unbacked mint cap of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newUnbackedMintCap The new unbacked mint cap of the reserve
   */
  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap) external;

  /**
   * @notice Assign an efficiency mode (eMode) category to asset.
   * @param asset The address of the underlying asset of the reserve
   * @param newCategoryId The new category id of the asset
   */
  function setAssetEModeCategory(address asset, uint8 newCategoryId) external;

  /**
   * @notice Adds a new efficiency mode (eMode) category.
   * @dev If zero is provided as oracle address, the default asset oracles will be used to compute the overall debt and
   * overcollateralization of the users using this category.
   * @dev The new ltv and liquidation threshold must be greater than the base
   * ltvs and liquidation thresholds of all assets within the eMode category
   * @param categoryId The id of the category to be configured
   * @param ltv The ltv associated with the category
   * @param liquidationThreshold The liquidation threshold associated with the category
   * @param liquidationBonus The liquidation bonus associated with the category
   * @param oracle The oracle associated with the category
   * @param label A label identifying the category
   */
  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
    address oracle,
    string calldata label
  ) external;

  /**
   * @notice Drops a reserve entirely.
   * @param asset The address of the reserve to drop
   */
  function dropReserve(address asset) external;

  /**
   * @notice Updates the bridge fee collected by the protocol reserves.
   * @param newBridgeProtocolFee The part of the fee sent to the protocol treasury, expressed in bps
   */
  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external;

  /**
   * @notice Updates the total flash loan premium.
   * Total flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra balance
   * - A part is collected by the protocol reserves
   * @dev Expressed in bps
   * @dev The premium is calculated on the total amount borrowed
   * @param newFlashloanPremiumTotal The total flashloan premium
   */
  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal) external;

  /**
   * @notice Updates the flash loan premium collected by protocol reserves
   * @dev Expressed in bps
   * @dev The premium to protocol is calculated on the total flashloan premium
   * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
   */
  function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol) external;

  /**
   * @notice Sets the debt ceiling for an asset.
   * @param newDebtCeiling The new debt ceiling
   */
  function setDebtCeiling(address asset, uint256 newDebtCeiling) external;

  /**
   * @notice Sets siloed borrowing for an asset
   * @param siloed The new siloed borrowing state
   */
  function setSiloedBorrowing(address asset, bool siloed) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IPoolDataProvider
 * @author Aave
 * @notice Defines the basic interface of a PoolDataProvider
 */
interface IPoolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  /**
   * @notice Returns the address for the PoolAddressesProvider contract.
   * @return The address for the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the list of the existing reserves in the pool.
   * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
   * @return The list of reserves, pairs of symbols and addresses
   */
  function getAllReservesTokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the list of the existing ATokens in the pool.
   * @return The list of ATokens, pairs of symbols and addresses
   */
  function getAllATokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the configuration data of the reserve
   * @dev Not returning borrow and supply caps for compatibility, nor pause flag
   * @param asset The address of the underlying asset of the reserve
   * @return decimals The number of decimals of the reserve
   * @return ltv The ltv of the reserve
   * @return liquidationThreshold The liquidationThreshold of the reserve
   * @return liquidationBonus The liquidationBonus of the reserve
   * @return reserveFactor The reserveFactor of the reserve
   * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
   * @return borrowingEnabled True if borrowing is enabled, false otherwise
   * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
   * @return isActive True if it is active, false otherwise
   * @return isFrozen True if it is frozen, false otherwise
   */
  function getReserveConfigurationData(
    address asset
  )
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  /**
   * @notice Returns the efficiency mode category of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The eMode id of the reserve
   */
  function getReserveEModeCategory(address asset) external view returns (uint256);

  /**
   * @notice Returns the caps parameters of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return borrowCap The borrow cap of the reserve
   * @return supplyCap The supply cap of the reserve
   */
  function getReserveCaps(
    address asset
  ) external view returns (uint256 borrowCap, uint256 supplyCap);

  /**
   * @notice Returns if the pool is paused
   * @param asset The address of the underlying asset of the reserve
   * @return isPaused True if the pool is paused, false otherwise
   */
  function getPaused(address asset) external view returns (bool isPaused);

  /**
   * @notice Returns the siloed borrowing flag
   * @param asset The address of the underlying asset of the reserve
   * @return True if the asset is siloed for borrowing
   */
  function getSiloedBorrowing(address asset) external view returns (bool);

  /**
   * @notice Returns the protocol fee on the liquidation bonus
   * @param asset The address of the underlying asset of the reserve
   * @return The protocol fee on liquidation
   */
  function getLiquidationProtocolFee(address asset) external view returns (uint256);

  /**
   * @notice Returns the unbacked mint cap of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The unbacked mint cap of the reserve
   */
  function getUnbackedMintCap(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The debt ceiling of the reserve
   */
  function getDebtCeiling(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling decimals
   * @return The debt ceiling decimals
   */
  function getDebtCeilingDecimals() external pure returns (uint256);

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   */
  function getReserveData(
    address asset
  )
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   */
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   */
  function getTotalDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the user data in a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param user The address of the user
   * @return currentATokenBalance The current AToken balance of the user
   * @return currentStableDebt The current stable debt of the user
   * @return currentVariableDebt The current variable debt of the user
   * @return principalStableDebt The principal stable debt of the user
   * @return scaledVariableDebt The scaled variable debt of the user
   * @return stableBorrowRate The stable borrow rate of the user
   * @return liquidityRate The liquidity rate of the reserve
   * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
   * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
   *         otherwise
   */
  function getUserReserveData(
    address asset,
    address user
  )
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  /**
   * @notice Returns the token addresses of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return aTokenAddress The AToken address of the reserve
   * @return stableDebtTokenAddress The StableDebtToken address of the reserve
   * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
   */
  function getReserveTokensAddresses(
    address asset
  )
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  /**
   * @notice Returns the address of the Interest Rate strategy
   * @param asset The address of the underlying asset of the reserve
   * @return irStrategyAddress The address of the Interest Rate strategy
   */
  function getInterestRateStrategyAddress(
    address asset
  ) external view returns (address irStrategyAddress);

  /**
   * @notice Returns whether the reserve has FlashLoans enabled or disabled
   * @param asset The address of the underlying asset of the reserve
   * @return True if FlashLoans are enabled, false otherwise
   */
  function getFlashLoanEnabled(address asset) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 */
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   */
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   */
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IReserveInterestRateStrategy
 * @author Aave
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
  /**
   * @notice Calculates the interest rates depending on the reserve's state and configurations
   * @param params The parameters needed to calculate interest rates
   * @return liquidityRate The liquidity rate expressed in rays
   * @return stableBorrowRate The stable borrow rate expressed in rays
   * @return variableBorrowRate The variable borrow rate expressed in rays
   */
  function calculateInterestRates(
    DataTypes.CalculateInterestRatesParams memory params
  ) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IScaledBalanceToken
 * @author Aave
 * @notice Defines the basic interface for a scaled-balance token.
 */
interface IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted tokens
   * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
   * @param index The next liquidity index of the reserve
   */
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @dev Emitted after the burn action
   * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
   * @param from The address from which the tokens will be burned
   * @param target The address that will receive the underlying, if any
   * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
   * @param index The next liquidity index of the reserve
   */
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @notice Returns the scaled balance of the user.
   * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
   * at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   */
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled total supply
   */
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
   * @return The scaled total supply
   */
  function scaledTotalSupply() external view returns (uint256);

  /**
   * @notice Returns last index interest was accrued to the user's balance
   * @param user The address of the user
   * @return The last index interest was accrued to the user's balance, expressed in ray
   */
  function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
  string public constant CALLER_NOT_ATOKEN = '11'; // 'The caller of the function is not an AToken'
  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
  string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = '54'; // 'Claimable rights over underlying not zero (aToken supply or accruedToTreasury)'
  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
  string public constant USER_IN_ISOLATION_MODE_OR_LTV_ZERO = '62'; // 'User is in isolation mode or ltv is zero'
  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
  string public constant FLASHLOAN_DISABLED = '91'; // FlashLoaning for this asset is disabled
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   */
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   */
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   */
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   */
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   */
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   */
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62: siloed borrowing enabled
    //bit 63: flashloaning enabled
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {Errors} from 'aave-v3-core/contracts/protocol/libraries/helpers/Errors.sol';
import {ConfiguratorInputTypes} from 'aave-v3-core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IAToken} from 'aave-v3-core/contracts/interfaces/IAToken.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from 'aave-v3-core/contracts/interfaces/IPoolConfigurator.sol';
import {IPriceOracleGetter} from 'aave-v3-core/contracts/interfaces/IPriceOracleGetter.sol';
import {IAaveOracle} from 'aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import {IACLManager as BasicIACLManager} from 'aave-v3-core/contracts/interfaces/IACLManager.sol';
import {IPoolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';
import {IDefaultInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {IPoolDataProvider as IAaveProtocolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';
import {AggregatorInterface} from 'aave-v3-core/contracts/dependencies/chainlink/AggregatorInterface.sol';

interface IACLManager is BasicIACLManager {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

  function renounceRole(bytes32 role, address account) external;

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;
}

// AUTOGENERATED - MANUALLY CHANGES WILL BE REVERTED BY THE GENERATOR
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager} from './AaveV3.sol';
import {ICollector} from './common/ICollector.sol';

library AaveV3Arbitrum {
  // https://arbiscan.io/address/0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  // https://arbiscan.io/address/0x794a61358D6845594F94dc1DB02A252b5b4814aD
  IPool internal constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  // https://arbiscan.io/address/0x03e8C5Cd5E194659b16456bb43Dd5D38886FE541
  address internal constant POOL_IMPL = 0x03e8C5Cd5E194659b16456bb43Dd5D38886FE541;

  // https://arbiscan.io/address/0x8145eddDf43f50276641b55bd3AD95944510021E
  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

  // https://arbiscan.io/address/0x04a8D477eE202aDCE1682F5902e1160455205b12
  address internal constant POOL_CONFIGURATOR_IMPL = 0x04a8D477eE202aDCE1682F5902e1160455205b12;

  // https://arbiscan.io/address/0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7
  IAaveOracle internal constant ORACLE = IAaveOracle(0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7);

  // https://arbiscan.io/address/0x7A9ff54A6eE4a21223036890bB8c4ea2D62c686b
  address internal constant PRICE_ORACLE_SENTINEL = 0x7A9ff54A6eE4a21223036890bB8c4ea2D62c686b;

  // https://arbiscan.io/address/0x6b4E260b765B3cA1514e618C0215A6B7839fF93e
  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x6b4E260b765B3cA1514e618C0215A6B7839fF93e);

  // https://arbiscan.io/address/0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B
  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

  // https://arbiscan.io/address/0xFF1137243698CaA18EE364Cc966CF0e02A4e6327
  address internal constant ACL_ADMIN = 0xFF1137243698CaA18EE364Cc966CF0e02A4e6327;

  // https://arbiscan.io/address/0x053D55f9B5AF8694c503EB288a1B7E552f590710
  ICollector internal constant COLLECTOR = ICollector(0x053D55f9B5AF8694c503EB288a1B7E552f590710);

  // https://arbiscan.io/address/0x929EC64c34a17401F460460D4B9390518E5B473e
  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  // https://arbiscan.io/address/0x1Be1798b70aEe431c2986f7ff48d9D1fa350786a
  address internal constant DEFAULT_A_TOKEN_IMPL_REV_2 = 0x1Be1798b70aEe431c2986f7ff48d9D1fa350786a;

  // https://arbiscan.io/address/0x5E76E98E0963EcDC6A065d1435F84065b7523f39
  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_2 =
    0x5E76E98E0963EcDC6A065d1435F84065b7523f39;

  // https://arbiscan.io/address/0xCB7113D3d572613BbFCeCf80d1341cFFE2A92C00
  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_3 =
    0xCB7113D3d572613BbFCeCf80d1341cFFE2A92C00;

  // https://arbiscan.io/address/0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73
  address internal constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  // https://arbiscan.io/address/0xADf86b537eF08591c2777E144322E8b0Ca7E82a7
  address internal constant CAPS_PLUS_RISK_STEWARD = 0xADf86b537eF08591c2777E144322E8b0Ca7E82a7;

  // https://arbiscan.io/address/0xe59470B3BE3293534603487E00A44C72f2CD466d
  address internal constant FREEZING_STEWARD = 0xe59470B3BE3293534603487E00A44C72f2CD466d;

  // https://arbiscan.io/address/0x9E8e9D6b0D24216F59043db68BDda1620892f549
  address internal constant DEBT_SWAP_ADAPTER = 0x9E8e9D6b0D24216F59043db68BDda1620892f549;

  // https://arbiscan.io/address/0x9abADECD08572e0eA5aF4d47A9C7984a5AA503dC
  address internal constant L2_ENCODER = 0x9abADECD08572e0eA5aF4d47A9C7984a5AA503dC;

  // https://arbiscan.io/address/0xc5de989E0D1BF605d19478Fdd32Aa827a10b464f
  address internal constant CONFIG_ENGINE = 0xc5de989E0D1BF605d19478Fdd32Aa827a10b464f;

  // https://arbiscan.io/address/0x770ef9f4fe897e59daCc474EF11238303F9552b6
  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x770ef9f4fe897e59daCc474EF11238303F9552b6;

  // https://arbiscan.io/address/0xcC47c4Fe1F7f29ff31A8b62197023aC8553C7896
  address internal constant RATES_FACTORY = 0xcC47c4Fe1F7f29ff31A8b62197023aC8553C7896;

  // https://arbiscan.io/address/0x28201C152DC5B69A86FA54FCfd21bcA4C0eff3BA
  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x28201C152DC5B69A86FA54FCfd21bcA4C0eff3BA;

  // https://arbiscan.io/address/0x411D79b8cC43384FDE66CaBf9b6a17180c842511
  address internal constant STATIC_A_TOKEN_FACTORY = 0x411D79b8cC43384FDE66CaBf9b6a17180c842511;

  // https://arbiscan.io/address/0xF3C3F14dd7BDb7E03e6EBc3bc5Ffc6D66De12251
  address internal constant SWAP_COLLATERAL_ADAPTER = 0xF3C3F14dd7BDb7E03e6EBc3bc5Ffc6D66De12251;

  // https://arbiscan.io/address/0xDA67AF3403555Ce0AE3ffC22fDb7354458277358
  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xDA67AF3403555Ce0AE3ffC22fDb7354458277358;

  // https://arbiscan.io/address/0x145dE30c929a065582da84Cf96F88460dB9745A7
  address internal constant UI_POOL_DATA_PROVIDER = 0x145dE30c929a065582da84Cf96F88460dB9745A7;

  // https://arbiscan.io/address/0xBc790382B3686abffE4be14A030A96aC6154023a
  address internal constant WALLET_BALANCE_PROVIDER = 0xBc790382B3686abffE4be14A030A96aC6154023a;

  // https://arbiscan.io/address/0xecD4bd3121F9FD604ffaC631bF6d41ec12f1fafb
  address internal constant WETH_GATEWAY = 0xecD4bd3121F9FD604ffaC631bF6d41ec12f1fafb;

  // https://arbiscan.io/address/0x5598BbFA2f4fE8151f45bBA0a3edE1b54B51a0a9
  address internal constant WITHDRAW_SWAP_ADAPTER = 0x5598BbFA2f4fE8151f45bBA0a3edE1b54B51a0a9;
}

library AaveV3ArbitrumAssets {
  // https://arbiscan.io/address/0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
  address internal constant DAI_UNDERLYING = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

  uint8 internal constant DAI_DECIMALS = 18;

  // https://arbiscan.io/address/0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE
  address internal constant DAI_A_TOKEN = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

  // https://arbiscan.io/address/0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
  address internal constant DAI_V_TOKEN = 0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC;

  // https://arbiscan.io/address/0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B
  address internal constant DAI_S_TOKEN = 0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B;

  // https://arbiscan.io/address/0x4a838a3Dac6633bB1fd932B6f356DecFCAf7803D
  address internal constant DAI_ORACLE = 0x4a838a3Dac6633bB1fd932B6f356DecFCAf7803D;

  // https://arbiscan.io/address/0xa8C12113DB50549A1E36FD25982C88B69A0007E0
  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xa8C12113DB50549A1E36FD25982C88B69A0007E0;

  // https://arbiscan.io/address/0xc91c5297d7E161aCC74b482aAfCc75B85cc0bfeD
  address internal constant DAI_STATA_TOKEN = 0xc91c5297d7E161aCC74b482aAfCc75B85cc0bfeD;

  // https://arbiscan.io/address/0xf97f4df75117a78c1A5a0DBb814Af92458539FB4
  address internal constant LINK_UNDERLYING = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;

  uint8 internal constant LINK_DECIMALS = 18;

  // https://arbiscan.io/address/0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530
  address internal constant LINK_A_TOKEN = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

  // https://arbiscan.io/address/0x953A573793604aF8d41F306FEb8274190dB4aE0e
  address internal constant LINK_V_TOKEN = 0x953A573793604aF8d41F306FEb8274190dB4aE0e;

  // https://arbiscan.io/address/0x89D976629b7055ff1ca02b927BA3e020F22A44e4
  address internal constant LINK_S_TOKEN = 0x89D976629b7055ff1ca02b927BA3e020F22A44e4;

  // https://arbiscan.io/address/0x86E53CF1B870786351Da77A57575e79CB55812CB
  address internal constant LINK_ORACLE = 0x86E53CF1B870786351Da77A57575e79CB55812CB;

  // https://arbiscan.io/address/0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f
  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f;

  // https://arbiscan.io/address/0x27dE098EF2772386cBCf1a4c8BEb886368b7F9a9
  address internal constant LINK_STATA_TOKEN = 0x27dE098EF2772386cBCf1a4c8BEb886368b7F9a9;

  // https://arbiscan.io/address/0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
  address internal constant USDC_UNDERLYING = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

  uint8 internal constant USDC_DECIMALS = 6;

  // https://arbiscan.io/address/0x625E7708f30cA75bfd92586e17077590C60eb4cD
  address internal constant USDC_A_TOKEN = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

  // https://arbiscan.io/address/0xFCCf3cAbbe80101232d343252614b6A3eE81C989
  address internal constant USDC_V_TOKEN = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  // https://arbiscan.io/address/0x307ffe186F84a3bc2613D1eA417A5737D69A7007
  address internal constant USDC_S_TOKEN = 0x307ffe186F84a3bc2613D1eA417A5737D69A7007;

  // https://arbiscan.io/address/0xDe25a88F87FEd9F8999fAbF6729dCB121893623C
  address internal constant USDC_ORACLE = 0xDe25a88F87FEd9F8999fAbF6729dCB121893623C;

  // https://arbiscan.io/address/0xc7b53C7d24164FB78F57Ea3b5d056bD2E541013d
  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xc7b53C7d24164FB78F57Ea3b5d056bD2E541013d;

  // https://arbiscan.io/address/0x0Bc9E52051f553E75550CA22C196bf132c52Cf0B
  address internal constant USDC_STATA_TOKEN = 0x0Bc9E52051f553E75550CA22C196bf132c52Cf0B;

  // https://arbiscan.io/address/0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f
  address internal constant WBTC_UNDERLYING = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

  uint8 internal constant WBTC_DECIMALS = 8;

  // https://arbiscan.io/address/0x078f358208685046a11C85e8ad32895DED33A249
  address internal constant WBTC_A_TOKEN = 0x078f358208685046a11C85e8ad32895DED33A249;

  // https://arbiscan.io/address/0x92b42c66840C7AD907b4BF74879FF3eF7c529473
  address internal constant WBTC_V_TOKEN = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;

  // https://arbiscan.io/address/0x633b207Dd676331c413D4C013a6294B0FE47cD0e
  address internal constant WBTC_S_TOKEN = 0x633b207Dd676331c413D4C013a6294B0FE47cD0e;

  // https://arbiscan.io/address/0x6ce185860a4963106506C203335A2910413708e9
  address internal constant WBTC_ORACLE = 0x6ce185860a4963106506C203335A2910413708e9;

  // https://arbiscan.io/address/0x8F183Ee74C790CB558232a141099b316D6C8Ba6E
  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x8F183Ee74C790CB558232a141099b316D6C8Ba6E;

  // https://arbiscan.io/address/0x32B95Fbe04e5a51cF99FeeF4e57Cf7e3FC9c5A93
  address internal constant WBTC_STATA_TOKEN = 0x32B95Fbe04e5a51cF99FeeF4e57Cf7e3FC9c5A93;

  // https://arbiscan.io/address/0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
  address internal constant WETH_UNDERLYING = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

  uint8 internal constant WETH_DECIMALS = 18;

  // https://arbiscan.io/address/0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8
  address internal constant WETH_A_TOKEN = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;

  // https://arbiscan.io/address/0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
  address internal constant WETH_V_TOKEN = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;

  // https://arbiscan.io/address/0xD8Ad37849950903571df17049516a5CD4cbE55F6
  address internal constant WETH_S_TOKEN = 0xD8Ad37849950903571df17049516a5CD4cbE55F6;

  // https://arbiscan.io/address/0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
  address internal constant WETH_ORACLE = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

  // https://arbiscan.io/address/0xd56eE97960b1b2953e751151Fd84888cF3F3b521
  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0xd56eE97960b1b2953e751151Fd84888cF3F3b521;

  // https://arbiscan.io/address/0x352F3475716261dCC991Bd5F2aF973eB3D0F5878
  address internal constant WETH_STATA_TOKEN = 0x352F3475716261dCC991Bd5F2aF973eB3D0F5878;

  // https://arbiscan.io/address/0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9
  address internal constant USDT_UNDERLYING = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

  uint8 internal constant USDT_DECIMALS = 6;

  // https://arbiscan.io/address/0x6ab707Aca953eDAeFBc4fD23bA73294241490620
  address internal constant USDT_A_TOKEN = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;

  // https://arbiscan.io/address/0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
  address internal constant USDT_V_TOKEN = 0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7;

  // https://arbiscan.io/address/0x70eFfc565DB6EEf7B927610155602d31b670e802
  address internal constant USDT_S_TOKEN = 0x70eFfc565DB6EEf7B927610155602d31b670e802;

  // https://arbiscan.io/address/0x84dC1C52D7C340AA54B4e8799FBB31C3D28E67aD
  address internal constant USDT_ORACLE = 0x84dC1C52D7C340AA54B4e8799FBB31C3D28E67aD;

  // https://arbiscan.io/address/0xa8C12113DB50549A1E36FD25982C88B69A0007E0
  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0xa8C12113DB50549A1E36FD25982C88B69A0007E0;

  // https://arbiscan.io/address/0xb165a74407fE1e519d6bCbDeC1Ed3202B35a4140
  address internal constant USDT_STATA_TOKEN = 0xb165a74407fE1e519d6bCbDeC1Ed3202B35a4140;

  // https://arbiscan.io/address/0xba5DdD1f9d7F570dc94a51479a000E3BCE967196
  address internal constant AAVE_UNDERLYING = 0xba5DdD1f9d7F570dc94a51479a000E3BCE967196;

  uint8 internal constant AAVE_DECIMALS = 18;

  // https://arbiscan.io/address/0xf329e36C7bF6E5E86ce2150875a84Ce77f477375
  address internal constant AAVE_A_TOKEN = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;

  // https://arbiscan.io/address/0xE80761Ea617F66F96274eA5e8c37f03960ecC679
  address internal constant AAVE_V_TOKEN = 0xE80761Ea617F66F96274eA5e8c37f03960ecC679;

  // https://arbiscan.io/address/0xfAeF6A702D15428E588d4C0614AEFb4348D83D48
  address internal constant AAVE_S_TOKEN = 0xfAeF6A702D15428E588d4C0614AEFb4348D83D48;

  // https://arbiscan.io/address/0xaD1d5344AaDE45F43E596773Bcc4c423EAbdD034
  address internal constant AAVE_ORACLE = 0xaD1d5344AaDE45F43E596773Bcc4c423EAbdD034;

  // https://arbiscan.io/address/0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f
  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f;

  // https://arbiscan.io/address/0x1C0c8EcED17aE093b3C1a1a8fFeBE2E9513a9346
  address internal constant AAVE_STATA_TOKEN = 0x1C0c8EcED17aE093b3C1a1a8fFeBE2E9513a9346;

  // https://arbiscan.io/address/0xD22a58f79e9481D1a88e00c343885A588b34b68B
  address internal constant EURS_UNDERLYING = 0xD22a58f79e9481D1a88e00c343885A588b34b68B;

  uint8 internal constant EURS_DECIMALS = 2;

  // https://arbiscan.io/address/0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97
  address internal constant EURS_A_TOKEN = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  // https://arbiscan.io/address/0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
  address internal constant EURS_V_TOKEN = 0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;

  // https://arbiscan.io/address/0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E
  address internal constant EURS_S_TOKEN = 0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E;

  // https://arbiscan.io/address/0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84
  address internal constant EURS_ORACLE = 0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84;

  // https://arbiscan.io/address/0xb96c569Ceb49440731DdD5D8c5E6DA3538f1CBF1
  address internal constant EURS_INTEREST_RATE_STRATEGY =
    0xb96c569Ceb49440731DdD5D8c5E6DA3538f1CBF1;

  // https://arbiscan.io/address/0x9a40747BE51185A416B181789B671E78a8d045dD
  address internal constant EURS_STATA_TOKEN = 0x9a40747BE51185A416B181789B671E78a8d045dD;

  // https://arbiscan.io/address/0x5979D7b546E38E414F7E9822514be443A4800529
  address internal constant wstETH_UNDERLYING = 0x5979D7b546E38E414F7E9822514be443A4800529;

  uint8 internal constant wstETH_DECIMALS = 18;

  // https://arbiscan.io/address/0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf
  address internal constant wstETH_A_TOKEN = 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf;

  // https://arbiscan.io/address/0x77CA01483f379E58174739308945f044e1a764dc
  address internal constant wstETH_V_TOKEN = 0x77CA01483f379E58174739308945f044e1a764dc;

  // https://arbiscan.io/address/0x08Cb71192985E936C7Cd166A8b268035e400c3c3
  address internal constant wstETH_S_TOKEN = 0x08Cb71192985E936C7Cd166A8b268035e400c3c3;

  // https://arbiscan.io/address/0x87fE1503beFBF98C35c7526B0c488d950F822C0F
  address internal constant wstETH_ORACLE = 0x87fE1503beFBF98C35c7526B0c488d950F822C0F;

  // https://arbiscan.io/address/0x4b8D3277d49E114C8F2D6E0B2eD310e29226fe16
  address internal constant wstETH_INTEREST_RATE_STRATEGY =
    0x4b8D3277d49E114C8F2D6E0B2eD310e29226fe16;

  // https://arbiscan.io/address/0x7775d4Ae4Dbb79a624fB96AAcDB8Ca74F671c0DF
  address internal constant wstETH_STATA_TOKEN = 0x7775d4Ae4Dbb79a624fB96AAcDB8Ca74F671c0DF;

  // https://arbiscan.io/address/0x3F56e0c36d275367b8C502090EDF38289b3dEa0d
  address internal constant MAI_UNDERLYING = 0x3F56e0c36d275367b8C502090EDF38289b3dEa0d;

  uint8 internal constant MAI_DECIMALS = 18;

  // https://arbiscan.io/address/0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA
  address internal constant MAI_A_TOKEN = 0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA;

  // https://arbiscan.io/address/0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907
  address internal constant MAI_V_TOKEN = 0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907;

  // https://arbiscan.io/address/0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841
  address internal constant MAI_S_TOKEN = 0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841;

  // https://arbiscan.io/address/0x7a7cE08a1057723CCEDeA2462407427Ae33FFEb2
  address internal constant MAI_ORACLE = 0x7a7cE08a1057723CCEDeA2462407427Ae33FFEb2;

  // https://arbiscan.io/address/0x7448ABeD12d8538efC115af4a417e3d1367180fc
  address internal constant MAI_INTEREST_RATE_STRATEGY = 0x7448ABeD12d8538efC115af4a417e3d1367180fc;

  // https://arbiscan.io/address/0xB4a0a2692D82301703B27082Cda45B083F68CAcE
  address internal constant MAI_STATA_TOKEN = 0xB4a0a2692D82301703B27082Cda45B083F68CAcE;

  // https://arbiscan.io/address/0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8
  address internal constant rETH_UNDERLYING = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;

  uint8 internal constant rETH_DECIMALS = 18;

  // https://arbiscan.io/address/0x8Eb270e296023E9D92081fdF967dDd7878724424
  address internal constant rETH_A_TOKEN = 0x8Eb270e296023E9D92081fdF967dDd7878724424;

  // https://arbiscan.io/address/0xCE186F6Cccb0c955445bb9d10C59caE488Fea559
  address internal constant rETH_V_TOKEN = 0xCE186F6Cccb0c955445bb9d10C59caE488Fea559;

  // https://arbiscan.io/address/0x3EF10DFf4928279c004308EbADc4Db8B7620d6fc
  address internal constant rETH_S_TOKEN = 0x3EF10DFf4928279c004308EbADc4Db8B7620d6fc;

  // https://arbiscan.io/address/0x256f33FC0110B1297f78f48524631D30B752480D
  address internal constant rETH_ORACLE = 0x256f33FC0110B1297f78f48524631D30B752480D;

  // https://arbiscan.io/address/0xC82dF96432346cFb632473eB619Db3B8AC280234
  address internal constant rETH_INTEREST_RATE_STRATEGY =
    0xC82dF96432346cFb632473eB619Db3B8AC280234;

  // https://arbiscan.io/address/0x68235105d6d33A19369D24b746cb7481FB2b34fd
  address internal constant rETH_STATA_TOKEN = 0x68235105d6d33A19369D24b746cb7481FB2b34fd;

  // https://arbiscan.io/address/0x93b346b6BC2548dA6A1E7d98E9a421B42541425b
  address internal constant LUSD_UNDERLYING = 0x93b346b6BC2548dA6A1E7d98E9a421B42541425b;

  uint8 internal constant LUSD_DECIMALS = 18;

  // https://arbiscan.io/address/0x8ffDf2DE812095b1D19CB146E4c004587C0A0692
  address internal constant LUSD_A_TOKEN = 0x8ffDf2DE812095b1D19CB146E4c004587C0A0692;

  // https://arbiscan.io/address/0xA8669021776Bc142DfcA87c21b4A52595bCbB40a
  address internal constant LUSD_V_TOKEN = 0xA8669021776Bc142DfcA87c21b4A52595bCbB40a;

  // https://arbiscan.io/address/0xa5e408678469d23efDB7694b1B0A85BB0669e8bd
  address internal constant LUSD_S_TOKEN = 0xa5e408678469d23efDB7694b1B0A85BB0669e8bd;

  // https://arbiscan.io/address/0x341B110bDF665A20F0D5f84A92FcAF5EbeEBC629
  address internal constant LUSD_ORACLE = 0x341B110bDF665A20F0D5f84A92FcAF5EbeEBC629;

  // https://arbiscan.io/address/0xaEc90D2516c79F8Ae7165574a41EC4dF2631b36f
  address internal constant LUSD_INTEREST_RATE_STRATEGY =
    0xaEc90D2516c79F8Ae7165574a41EC4dF2631b36f;

  // https://arbiscan.io/address/0xDbB6314b5b07E63B7101844c0346309B79f8C20A
  address internal constant LUSD_STATA_TOKEN = 0xDbB6314b5b07E63B7101844c0346309B79f8C20A;

  // https://arbiscan.io/address/0xaf88d065e77c8cC2239327C5EDb3A432268e5831
  address internal constant USDCn_UNDERLYING = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

  uint8 internal constant USDCn_DECIMALS = 6;

  // https://arbiscan.io/address/0x724dc807b04555b71ed48a6896b6F41593b8C637
  address internal constant USDCn_A_TOKEN = 0x724dc807b04555b71ed48a6896b6F41593b8C637;

  // https://arbiscan.io/address/0xf611aEb5013fD2c0511c9CD55c7dc5C1140741A6
  address internal constant USDCn_V_TOKEN = 0xf611aEb5013fD2c0511c9CD55c7dc5C1140741A6;

  // https://arbiscan.io/address/0xDC1fad70953Bb3918592b6fCc374fe05F5811B6a
  address internal constant USDCn_S_TOKEN = 0xDC1fad70953Bb3918592b6fCc374fe05F5811B6a;

  // https://arbiscan.io/address/0xDe25a88F87FEd9F8999fAbF6729dCB121893623C
  address internal constant USDCn_ORACLE = 0xDe25a88F87FEd9F8999fAbF6729dCB121893623C;

  // https://arbiscan.io/address/0x48AF11111764E710fcDcE2750db848C63edab57B
  address internal constant USDCn_INTEREST_RATE_STRATEGY =
    0x48AF11111764E710fcDcE2750db848C63edab57B;

  // https://arbiscan.io/address/0x7CFaDFD5645B50bE87d546f42699d863648251ad
  address internal constant USDCn_STATA_TOKEN = 0x7CFaDFD5645B50bE87d546f42699d863648251ad;

  // https://arbiscan.io/address/0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F
  address internal constant FRAX_UNDERLYING = 0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F;

  uint8 internal constant FRAX_DECIMALS = 18;

  // https://arbiscan.io/address/0x38d693cE1dF5AaDF7bC62595A37D667aD57922e5
  address internal constant FRAX_A_TOKEN = 0x38d693cE1dF5AaDF7bC62595A37D667aD57922e5;

  // https://arbiscan.io/address/0x5D557B07776D12967914379C71a1310e917C7555
  address internal constant FRAX_V_TOKEN = 0x5D557B07776D12967914379C71a1310e917C7555;

  // https://arbiscan.io/address/0x8a9FdE6925a839F6B1932d16B36aC026F8d3FbdB
  address internal constant FRAX_S_TOKEN = 0x8a9FdE6925a839F6B1932d16B36aC026F8d3FbdB;

  // https://arbiscan.io/address/0x06919EB75Bd6BA817D38CC70C1CA588ac7a01C10
  address internal constant FRAX_ORACLE = 0x06919EB75Bd6BA817D38CC70C1CA588ac7a01C10;

  // https://arbiscan.io/address/0xa8C12113DB50549A1E36FD25982C88B69A0007E0
  address internal constant FRAX_INTEREST_RATE_STRATEGY =
    0xa8C12113DB50549A1E36FD25982C88B69A0007E0;

  // https://arbiscan.io/address/0x89AEc2023f89E26Dbb7eaa7a98fe3996f9d112A8
  address internal constant FRAX_STATA_TOKEN = 0x89AEc2023f89E26Dbb7eaa7a98fe3996f9d112A8;

  // https://arbiscan.io/address/0x912CE59144191C1204E64559FE8253a0e49E6548
  address internal constant ARB_UNDERLYING = 0x912CE59144191C1204E64559FE8253a0e49E6548;

  uint8 internal constant ARB_DECIMALS = 18;

  // https://arbiscan.io/address/0x6533afac2E7BCCB20dca161449A13A32D391fb00
  address internal constant ARB_A_TOKEN = 0x6533afac2E7BCCB20dca161449A13A32D391fb00;

  // https://arbiscan.io/address/0x44705f578135cC5d703b4c9c122528C73Eb87145
  address internal constant ARB_V_TOKEN = 0x44705f578135cC5d703b4c9c122528C73Eb87145;

  // https://arbiscan.io/address/0x6B4b37618D85Db2a7b469983C888040F7F05Ea3D
  address internal constant ARB_S_TOKEN = 0x6B4b37618D85Db2a7b469983C888040F7F05Ea3D;

  // https://arbiscan.io/address/0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6
  address internal constant ARB_ORACLE = 0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6;

  // https://arbiscan.io/address/0xD87974E8ED49AB16d5053ba793F4e17078Be0426
  address internal constant ARB_INTEREST_RATE_STRATEGY = 0xD87974E8ED49AB16d5053ba793F4e17078Be0426;

  // https://arbiscan.io/address/0x9b5637d7952BC9fa2D693aAE51f3103760Bf2693
  address internal constant ARB_STATA_TOKEN = 0x9b5637d7952BC9fa2D693aAE51f3103760Bf2693;

  // https://arbiscan.io/address/0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe
  address internal constant weETH_UNDERLYING = 0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe;

  uint8 internal constant weETH_DECIMALS = 18;

  // https://arbiscan.io/address/0x8437d7C167dFB82ED4Cb79CD44B7a32A1dd95c77
  address internal constant weETH_A_TOKEN = 0x8437d7C167dFB82ED4Cb79CD44B7a32A1dd95c77;

  // https://arbiscan.io/address/0x3ca5FA07689F266e907439aFd1fBB59c44fe12f6
  address internal constant weETH_V_TOKEN = 0x3ca5FA07689F266e907439aFd1fBB59c44fe12f6;

  // https://arbiscan.io/address/0x40B4BAEcc69B882e8804f9286b12228C27F8c9BF
  address internal constant weETH_S_TOKEN = 0x40B4BAEcc69B882e8804f9286b12228C27F8c9BF;

  // https://arbiscan.io/address/0x517276B5972C4Db7E88B9F76Ee500E888a2D73C3
  address internal constant weETH_ORACLE = 0x517276B5972C4Db7E88B9F76Ee500E888a2D73C3;

  // https://arbiscan.io/address/0x0fc12Ad84210695dE8C0D5D8B6f720C37cEaB02f
  address internal constant weETH_INTEREST_RATE_STRATEGY =
    0x0fc12Ad84210695dE8C0D5D8B6f720C37cEaB02f;
}

library AaveV3ArbitrumEModes {
  uint8 internal constant NONE = 0;

  uint8 internal constant STABLECOINS = 1;

  uint8 internal constant ETH_CORRELATED = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title ICollector
 * @notice Defines the interface of the Collector contract
 * @author Aave
 **/
interface ICollector {
  struct Stream {
    uint256 deposit;
    uint256 ratePerSecond;
    uint256 remainingBalance;
    uint256 startTime;
    uint256 stopTime;
    address recipient;
    address sender;
    address tokenAddress;
    bool isEntity;
  }

  /** @notice Emitted when the funds admin changes
   * @param fundsAdmin The new funds admin.
   **/
  event NewFundsAdmin(address indexed fundsAdmin);

  /** @notice Emitted when the new stream is created
   * @param streamId The identifier of the stream.
   * @param sender The address of the collector.
   * @param recipient The address towards which the money is streamed.
   * @param deposit The amount of money to be streamed.
   * @param tokenAddress The ERC20 token to use as streaming currency.
   * @param startTime The unix timestamp for when the stream starts.
   * @param stopTime The unix timestamp for when the stream stops.
   **/
  event CreateStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  );

  /**
   * @notice Emmitted when withdraw happens from the contract to the recipient's account.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param recipient The address towards which the money is streamed.
   * @param amount The amount of tokens to withdraw.
   */
  event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

  /**
   * @notice Emmitted when the stream is canceled.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param sender The address of the collector.
   * @param recipient The address towards which the money is streamed.
   * @param senderBalance The sender's balance at the moment of cancelling.
   * @param recipientBalance The recipient's balance at the moment of cancelling.
   */
  event CancelStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 senderBalance,
    uint256 recipientBalance
  );

  /** @notice Returns the mock ETH reference address
   * @return address The address
   **/
  function ETH_MOCK_ADDRESS() external pure returns (address);

  /** @notice Initializes the contracts
   * @param fundsAdmin Funds admin address
   * @param nextStreamId StreamId to set, applied if greater than 0
   **/
  function initialize(address fundsAdmin, uint256 nextStreamId) external;

  /**
   * @notice Return the funds admin, only entity to be able to interact with this contract (controller of reserve)
   * @return address The address of the funds admin
   **/
  function getFundsAdmin() external view returns (address);

  /**
   * @notice Returns the available funds for the given stream id and address.
   * @param streamId The id of the stream for which to query the balance.
   * @param who The address for which to query the balance.
   * @notice Returns the total funds allocated to `who` as uint256.
   */
  function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

  /**
   * @dev Function for the funds admin to give ERC20 allowance to other parties
   * @param token The address of the token to give allowance from
   * @param recipient Allowance's recipient
   * @param amount Allowance to approve
   **/
  function approve(
    //IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Function for the funds admin to transfer ERC20 tokens to other parties
   * @param token The address of the token to transfer
   * @param recipient Transfer's recipient
   * @param amount Amount to transfer
   **/
  function transfer(
    //IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer the ownership of the funds administrator role.
          This function should only be callable by the current funds administrator.
   * @param admin The address of the new funds administrator
   */
  function setFundsAdmin(address admin) external;

  /**
   * @notice Creates a new stream funded by this contracts itself and paid towards `recipient`.
   * @param recipient The address towards which the money is streamed.
   * @param deposit The amount of money to be streamed.
   * @param tokenAddress The ERC20 token to use as streaming currency.
   * @param startTime The unix timestamp for when the stream starts.
   * @param stopTime The unix timestamp for when the stream stops.
   * @return streamId the uint256 id of the newly created stream.
   */
  function createStream(
    address recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  ) external returns (uint256 streamId);

  /**
   * @notice Returns the stream with all its properties.
   * @dev Throws if the id does not point to a valid stream.
   * @param streamId The id of the stream to query.
   * @notice Returns the stream object.
   */
  function getStream(
    uint256 streamId
  )
    external
    view
    returns (
      address sender,
      address recipient,
      uint256 deposit,
      address tokenAddress,
      uint256 startTime,
      uint256 stopTime,
      uint256 remainingBalance,
      uint256 ratePerSecond
    );

  /**
   * @notice Withdraws from the contract to the recipient's account.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param amount The amount of tokens to withdraw.
   * @return bool Returns true if successful.
   */
  function withdrawFromStream(uint256 streamId, uint256 amount) external returns (bool);

  /**
   * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
   * @param streamId The id of the stream to cancel.
   * @return bool Returns true if successful.
   */
  function cancelStream(uint256 streamId) external returns (bool);

  /**
   * @notice Returns the next available stream id
   * @return nextStreamId Returns the stream id.
   */
  function getNextStreamId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: call to non-contract');
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
pragma solidity ^0.8.0;

import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {IAaveV3ConfigEngine as IEngine} from './IAaveV3ConfigEngine.sol';
import {IV3RateStrategyFactory as Rates} from './IV3RateStrategyFactory.sol';
import {EngineFlags} from './EngineFlags.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 configs update.
 * - !!!IMPORTANT!!! This payload inheriting AaveV3Payload MUST BE STATELESS always
 * - Assumes this contract has the right permissions
 * - Connected to a IAaveV3ConfigEngine engine contact, which abstract the complexities of
 *   interaction with the Aave protocol.
 * - At the moment covering:
 *   - Listings of new assets on the pool.
 *   - Listings of new assets on the pool with custom token impl.
 *   - Updates of caps (supply cap, borrow cap).
 *   - Updates of price feeds
 *   - Updates of interest rate strategies
 *   - Updates of borrow parameters (flashloanable, stableRateModeEnabled, borrowableInIsolation, withSiloedBorrowing, reserveFactor)
 *   - Updates of collateral parameters (ltv, liq threshold, liq bonus, liq protocol fee, debt ceiling)
 *   - Updates of emode category parameters (ltv, liq threshold, liq bonus, price source, label)
 *   - Updates of emode category of assets (e-mode id)
 * @author BGD Labs
 */
abstract contract AaveV3Payload {
  using Address for address;

  IEngine public immutable CONFIG_ENGINE;

  constructor(IEngine engine) {
    CONFIG_ENGINE = engine;
  }

  /// @dev to be overridden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overridden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    IEngine.EModeCategoryUpdate[] memory eModeCategories = eModeCategoriesUpdates();
    IEngine.Listing[] memory listings = newListings();
    IEngine.ListingWithCustomImpl[] memory listingsCustom = newListingsCustom();
    IEngine.CollateralUpdate[] memory collaterals = collateralsUpdates();
    IEngine.BorrowUpdate[] memory borrows = borrowsUpdates();
    IEngine.RateStrategyUpdate[] memory rates = rateStrategiesUpdates();
    IEngine.PriceFeedUpdate[] memory priceFeeds = priceFeedsUpdates();
    IEngine.AssetEModeUpdate[] memory assetsEMode = assetsEModeUpdates();
    IEngine.CapsUpdate[] memory caps = capsUpdates();

    if (eModeCategories.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateEModeCategories.selector, eModeCategories)
      );
    }

    if (listings.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.listAssets.selector, getPoolContext(), listings)
      );
    }

    if (listingsCustom.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(
          CONFIG_ENGINE.listAssetsCustom.selector,
          getPoolContext(),
          listingsCustom
        )
      );
    }

    if (borrows.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateBorrowSide.selector, borrows)
      );
    }

    if (collaterals.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateCollateralSide.selector, collaterals)
      );
    }

    if (rates.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateRateStrategies.selector, rates)
      );
    }

    if (priceFeeds.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updatePriceFeeds.selector, priceFeeds)
      );
    }

    if (assetsEMode.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateAssetsEMode.selector, assetsEMode)
      );
    }

    if (caps.length != 0) {
      address(CONFIG_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(CONFIG_ENGINE.updateCaps.selector, caps)
      );
    }

    _postExecute();
  }

  /** @dev Converts basis points to RAY units
   * e.g. 10_00 (10.00%) will return 100000000000000000000000000
   */
  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * WadRayMath.RAY) / 10_000;
  }

  /// @dev to be defined in the child with a list of new assets to list
  function newListings() public view virtual returns (IEngine.Listing[] memory) {}

  /// @dev to be defined in the child with a list of new assets to list (with custom a/v/s tokens implementations)
  function newListingsCustom()
    public
    view
    virtual
    returns (IEngine.ListingWithCustomImpl[] memory)
  {}

  /// @dev to be defined in the child with a list of caps to update
  function capsUpdates() public view virtual returns (IEngine.CapsUpdate[] memory) {}

  /// @dev to be defined in the child with a list of collaterals' params to update
  function collateralsUpdates() public view virtual returns (IEngine.CollateralUpdate[] memory) {}

  /// @dev to be defined in the child with a list of borrows' params to update
  function borrowsUpdates() public view virtual returns (IEngine.BorrowUpdate[] memory) {}

  /// @dev to be defined in the child with a list of priceFeeds to update
  function priceFeedsUpdates() public view virtual returns (IEngine.PriceFeedUpdate[] memory) {}

  /// @dev to be defined in the child with a list of eMode categories to update
  function eModeCategoriesUpdates()
    public
    view
    virtual
    returns (IEngine.EModeCategoryUpdate[] memory)
  {}

  /// @dev to be defined in the child with a list of assets for which eMode categories to update
  function assetsEModeUpdates() public view virtual returns (IEngine.AssetEModeUpdate[] memory) {}

  /// @dev to be defined in the child with a list of set of parameters of rate strategies
  function rateStrategiesUpdates()
    public
    view
    virtual
    returns (IEngine.RateStrategyUpdate[] memory)
  {}

  /// @dev the lack of support for immutable strings kinds of forces for this
  /// Besides that, it can actually be useful being able to change the naming, but remote
  function getPoolContext() public view virtual returns (IEngine.PoolContext memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Arbitrum} from 'aave-address-book/AaveV3Arbitrum.sol';
import './AaveV3Payload.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 (compatible with 3.0.0) listing on v3 Arbitrum.
 * @author BGD Labs
 */
abstract contract AaveV3PayloadArbitrum is AaveV3Payload(IEngine(AaveV3Arbitrum.CONFIG_ENGINE)) {
  function getPoolContext() public pure override returns (IEngine.PoolContext memory) {
    return IEngine.PoolContext({networkName: 'Arbitrum', networkAbbreviation: 'Arb'});
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library EngineFlags {
  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `type(uint256).max - 42` will never be used, which seems reasonable
  uint256 internal constant KEEP_CURRENT = type(uint256).max - 42;

  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `KEEP_CURRENT_STRING` will never be used, which seems reasonable
  string internal constant KEEP_CURRENT_STRING = 'KEEP_CURRENT_STRING';

  /// @dev magic value to be used as flag to keep unchanged any current configuration
  /// Strongly assumes that the value `0x0000000000000000000000000000000000000050` will never be used, which seems reasonable
  address internal constant KEEP_CURRENT_ADDRESS =
    address(0x0000000000000000000000000000000000000050);

  /// @dev value to be used as flag for bool value true
  uint256 internal constant ENABLED = 1;

  /// @dev value to be used as flag for bool value false
  uint256 internal constant DISABLED = 0;

  /// @dev converts flag ENABLED DISABLED to bool
  function toBool(uint256 flag) internal pure returns (bool) {
    require(flag == 0 || flag == 1, 'INVALID_CONVERSION_TO_BOOL');
    return flag == 1;
  }

  /// @dev converts bool to ENABLED DISABLED flags
  function fromBool(bool isTrue) internal pure returns (uint256) {
    return isTrue ? ENABLED : DISABLED;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IPool, IPoolConfigurator, IAaveOracle} from 'aave-address-book/AaveV3.sol';
import {IV3RateStrategyFactory} from './IV3RateStrategyFactory.sol';

/// @dev Examples here assume the usage of the `AaveV3Payload` base contracts
/// contained in this same repository
interface IAaveV3ConfigEngine {
  struct Basic {
    string assetSymbol;
    TokenImplementations implementations;
  }

  struct EngineLibraries {
    address listingEngine;
    address eModeEngine;
    address borrowEngine;
    address collateralEngine;
    address priceFeedEngine;
    address rateEngine;
    address capsEngine;
  }

  struct EngineConstants {
    IPool pool;
    IPoolConfigurator poolConfigurator;
    IV3RateStrategyFactory ratesStrategyFactory;
    IAaveOracle oracle;
    address rewardsController;
    address collector;
  }

  /**
   * @dev Required for naming of a/v/s tokens
   * Example (mock):
   * PoolContext({
   *   networkName: 'Polygon',
   *   networkAbbreviation: 'Pol'
   * })
   */
  struct PoolContext {
    string networkName;
    string networkAbbreviation;
  }

  /**
   * @dev Example (mock):
   * Listing({
   *   asset: 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
   *   assetSymbol: 'AAVE',
   *   priceFeed: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9,
   *   rateStrategyParams: Rates.RateStrategyParams({
   *     optimalUsageRatio: _bpsToRay(80_00),
   *     baseVariableBorrowRate: _bpsToRay(25), // 0.25%
   *     variableRateSlope1: _bpsToRay(3_00),
   *     variableRateSlope2: _bpsToRay(75_00),
   *     stableRateSlope1: _bpsToRay(3_00),
   *     stableRateSlope2: _bpsToRay(75_00),
   *     baseStableRateOffset: _bpsToRay(2_00),
   *     stableRateExcessOffset: _bpsToRay(3_00),
   *     optimalStableToTotalDebtRatio: _bpsToRay(30_00)
   *   }),
   *   enabledToBorrow: EngineFlags.ENABLED,
   *   flashloanable: EngineFlags.ENABLED,
   *   stableRateModeEnabled: EngineFlags.DISABLED,
   *   borrowableInIsolation: EngineFlags.ENABLED,
   *   withSiloedBorrowing:, EngineFlags.DISABLED,
   *   ltv: 70_50, // 70.5%
   *   liqThreshold: 76_00, // 76%
   *   liqBonus: 5_00, // 5%
   *   reserveFactor: 10_00, // 10%
   *   supplyCap: 100_000, // 100k AAVE
   *   borrowCap: 60_000, // 60k AAVE
   *   debtCeiling: 100_000, // 100k USD
   *   liqProtocolFee: 10_00, // 10%
   *   eModeCategory: 0, // No category
   * }
   */
  struct Listing {
    address asset;
    string assetSymbol;
    address priceFeed;
    IV3RateStrategyFactory.RateStrategyParams rateStrategyParams; // Mandatory, no matter if enabled for borrowing or not
    uint256 enabledToBorrow;
    uint256 stableRateModeEnabled; // Only considered is enabledToBorrow == EngineFlags.ENABLED (true)
    uint256 borrowableInIsolation; // Only considered is enabledToBorrow == EngineFlags.ENABLED (true)
    uint256 withSiloedBorrowing; // Only considered if enabledToBorrow == EngineFlags.ENABLED (true)
    uint256 flashloanable; // Independent from enabled to borrow: an asset can be flashloanble and not enabled to borrow
    uint256 ltv; // Only considered if liqThreshold > 0
    uint256 liqThreshold; // If `0`, the asset will not be enabled as collateral
    uint256 liqBonus; // Only considered if liqThreshold > 0
    uint256 reserveFactor; // Only considered if enabledToBorrow == EngineFlags.ENABLED (true)
    uint256 supplyCap; // If passing any value distinct to EngineFlags.KEEP_CURRENT, always configured
    uint256 borrowCap; // If passing any value distinct to EngineFlags.KEEP_CURRENT, always configured
    uint256 debtCeiling; // Only considered if liqThreshold > 0
    uint256 liqProtocolFee; // Only considered if liqThreshold > 0
    uint8 eModeCategory; // If `O`, no eMode category will be set
  }

  struct RepackedListings {
    address[] ids;
    Basic[] basics;
    BorrowUpdate[] borrowsUpdates;
    CollateralUpdate[] collateralsUpdates;
    PriceFeedUpdate[] priceFeedsUpdates;
    AssetEModeUpdate[] assetsEModeUpdates;
    CapsUpdate[] capsUpdates;
    IV3RateStrategyFactory.RateStrategyParams[] rates;
  }

  struct TokenImplementations {
    address aToken;
    address vToken;
    address sToken;
  }

  struct ListingWithCustomImpl {
    Listing base;
    TokenImplementations implementations;
  }

  /**
   * @dev Example (mock):
   * CapsUpdate({
   *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
   *   supplyCap: 1_000_000,
   *   borrowCap: EngineFlags.KEEP_CURRENT
   * }
   */
  struct CapsUpdate {
    address asset;
    uint256 supplyCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
    uint256 borrowCap; // Pass any value, of EngineFlags.KEEP_CURRENT to keep it as it is
  }

  /**
   * @dev Example (mock):
   * PriceFeedUpdate({
   *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
   *   priceFeed: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9
   * })
   */
  struct PriceFeedUpdate {
    address asset;
    address priceFeed;
  }

  /**
   * @dev Example (mock):
   * CollateralUpdate({
   *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
   *   ltv: 60_00,
   *   liqThreshold: 70_00,
   *   liqBonus: EngineFlags.KEEP_CURRENT,
   *   debtCeiling: EngineFlags.KEEP_CURRENT,
   *   liqProtocolFee: 7_00
   * })
   */
  struct CollateralUpdate {
    address asset;
    uint256 ltv;
    uint256 liqThreshold;
    uint256 liqBonus;
    uint256 debtCeiling;
    uint256 liqProtocolFee;
  }

  /**
   * @dev Example (mock):
   * BorrowUpdate({
   *   asset: AaveV3EthereumAssets.AAVE_UNDERLYING,
   *   enabledToBorrow: EngineFlags.ENABLED,
   *   flashloanable: EngineFlags.KEEP_CURRENT,
   *   stableRateModeEnabled: EngineFlags.KEEP_CURRENT,
   *   borrowableInIsolation: EngineFlags.KEEP_CURRENT,
   *   withSiloedBorrowing: EngineFlags.KEEP_CURRENT,
   *   reserveFactor: 15_00, // 15%
   * })
   */
  struct BorrowUpdate {
    address asset;
    uint256 enabledToBorrow;
    uint256 flashloanable;
    uint256 stableRateModeEnabled;
    uint256 borrowableInIsolation;
    uint256 withSiloedBorrowing;
    uint256 reserveFactor;
  }

  /**
   * @dev Example (mock):
   * AssetEModeUpdate({
   *   asset: AaveV3EthereumAssets.rETH_UNDERLYING,
   *   eModeCategory: 1, // ETH correlated
   * })
   */
  struct AssetEModeUpdate {
    address asset;
    uint8 eModeCategory;
  }

  /**
   * @dev Example (mock):
   * EModeCategoryUpdate({
   *   eModeCategory: 1, // ETH correlated
   *   ltv: 60_00,
   *   liqThreshold: 70_00,
   *   liqBonus: EngineFlags.KEEP_CURRENT,
   *   priceSource: EngineFlags.KEEP_CURRENT_ADDRESS,
   *   label: EngineFlags.KEEP_CURRENT_STRING
   * })
   */
  struct EModeCategoryUpdate {
    uint8 eModeCategory;
    uint256 ltv;
    uint256 liqThreshold;
    uint256 liqBonus;
    address priceSource;
    string label;
  }

  /**
   * @dev Example (mock):
   * RateStrategyUpdate({
   *   asset: AaveV3OptimismAssets.USDT_UNDERLYING,
   *   params: Rates.RateStrategyParams({
   *     optimalUsageRatio: _bpsToRay(80_00),
   *     baseVariableBorrowRate: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     variableRateSlope2: _bpsToRay(75_00),
   *     stableRateSlope1: EngineFlags.KEEP_CURRENT,
   *     stableRateSlope2: _bpsToRay(75_00),
   *     baseStableRateOffset: EngineFlags.KEEP_CURRENT,
   *     stableRateExcessOffset: EngineFlags.KEEP_CURRENT,
   *     optimalStableToTotalDebtRatio: EngineFlags.KEEP_CURRENT
   *   })
   * })
   */
  struct RateStrategyUpdate {
    address asset;
    IV3RateStrategyFactory.RateStrategyParams params;
  }

  /**
   * @notice Performs full listing of the assets, in the Aave pool configured in this engine instance
   * @param context `PoolContext` struct, effectively meta-data for naming of a/v/s tokens.
   *   More information on the documentation of the struct.
   * @param listings `Listing[]` list of declarative configs for every aspect of the asset listings.
   *   More information on the documentation of the struct.
   */
  function listAssets(PoolContext memory context, Listing[] memory listings) external;

  /**
   * @notice Performs full listings of assets, in the Aave pool configured in this engine instance
   * @dev This function allows more customization, specifically enables to set custom implementations
   *   for a/v/s tokens.
   *   IMPORTANT. Use it only if understanding the internals of the Aave v3 protocol
   * @param context `PoolContext` struct, effectively meta-data for naming of a/v/s tokens.
   *   More information on the documentation of the struct.
   * @param listings `ListingWithCustomImpl[]` list of declarative configs for every aspect of the asset listings.
   */
  function listAssetsCustom(
    PoolContext memory context,
    ListingWithCustomImpl[] memory listings
  ) external;

  /**
   * @notice Performs an update of the caps (supply, borrow) of the assets, in the Aave pool configured in this engine instance
   * @param updates `CapsUpdate[]` list of declarative updates containing the new caps
   *   More information on the documentation of the struct.
   */
  function updateCaps(CapsUpdate[] memory updates) external;

  /**
   * @notice Performs an update on the rate strategy params of the assets, in the Aave pool configured in this engine instance
   * @dev The engine itself manages if a new rate strategy needs to be deployed or if an existing one can be re-used
   * @param updates `RateStrategyUpdate[]` list of declarative updates containing the new rate strategy params
   *   More information on the documentation of the struct.
   */
  function updateRateStrategies(RateStrategyUpdate[] memory updates) external;

  /**
   * @notice Performs an update of the collateral-related params of the assets, in the Aave pool configured in this engine instance
   * @param updates `CollateralUpdate[]` list of declarative updates containing the new parameters
   *   More information on the documentation of the struct.
   */
  function updateCollateralSide(CollateralUpdate[] memory updates) external;

  /**
   * @notice Performs an update of the price feed of the assets, in the Aave pool configured in this engine instance
   * @param updates `PriceFeedUpdate[]` list of declarative updates containing the new parameters
   *   More information on the documentation of the struct.
   */
  function updatePriceFeeds(PriceFeedUpdate[] memory updates) external;

  /**
   * @notice Performs an update of the borrow-related params of the assets, in the Aave pool configured in this engine instance
   * @param updates `BorrowUpdate[]` list of declarative updates containing the new parameters
   *   More information on the documentation of the struct.
   */
  function updateBorrowSide(BorrowUpdate[] memory updates) external;

  /**
   * @notice Performs an update of the e-mode categories, in the Aave pool configured in this engine instance
   * @param updates `EModeCategoryUpdate[]` list of declarative updates containing the new parameters
   *   More information on the documentation of the struct.
   */
  function updateEModeCategories(EModeCategoryUpdate[] memory updates) external;

  /**
   * @notice Performs an update of the e-mode category of the assets, in the Aave pool configured in this engine instance
   * @param updates `AssetEModeUpdate[]` list of declarative updates containing the new parameters
   *   More information on the documentation of the struct.
   */
  function updateAssetsEMode(AssetEModeUpdate[] calldata updates) external;

  function RATE_STRATEGY_FACTORY() external view returns (IV3RateStrategyFactory);

  function POOL() external view returns (IPool);

  function POOL_CONFIGURATOR() external view returns (IPoolConfigurator);

  function ORACLE() external view returns (IAaveOracle);

  function ATOKEN_IMPL() external view returns (address);

  function VTOKEN_IMPL() external view returns (address);

  function STOKEN_IMPL() external view returns (address);

  function REWARDS_CONTROLLER() external view returns (address);

  function COLLECTOR() external view returns (address);

  function BORROW_ENGINE() external view returns (address);

  function CAPS_ENGINE() external view returns (address);

  function COLLATERAL_ENGINE() external view returns (address);

  function EMODE_ENGINE() external view returns (address);

  function LISTING_ENGINE() external view returns (address);

  function PRICE_FEED_ENGINE() external view returns (address);

  function RATE_ENGINE() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from 'aave-address-book/AaveV3.sol';
import {IDefaultInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol';

interface IV3RateStrategyFactory {
  event RateStrategyCreated(
    address indexed strategy,
    bytes32 indexed hashedParam,
    RateStrategyParams params
  );

  /// @dev same parameters and the ones received on the constructor of DefaultReserveInterestRateStrategy
  /// in practise defining the strategy itself
  struct RateStrategyParams {
    uint256 optimalUsageRatio;
    uint256 baseVariableBorrowRate;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
    uint256 baseStableRateOffset;
    uint256 stableRateExcessOffset;
    uint256 optimalStableToTotalDebtRatio;
  }

  /**
   * @notice Create new rate strategies from a list of parameters
   * @dev If a strategy with exactly the same `RateStrategyParams` already exists, no creation happens but
   *  its address is returned
   * @param params `RateStrategyParams[]` list of parameters for multiple strategies
   * @return address[] list of strategies
   */
  function createStrategies(RateStrategyParams[] memory params) external returns (address[] memory);

  /**
   * @notice Returns the identifier of a rate strategy from its parameters
   * @param params `RateStrategyParams` the parameters of the rate strategy
   * @return bytes32 the keccak256 hash generated from the `RateStrategyParams` parameters
   *   to be used as identifier of the rate strategy on the factory
   */
  function strategyHashFromParams(RateStrategyParams memory params) external pure returns (bytes32);

  /**
   * @notice Returns all the strategies registered in the factory
   * @return address[] list of strategies
   */
  function getAllStrategies() external view returns (address[] memory);

  /**
   * @notice Returns the a strategy added, given its parameters.
   * @dev Only if the strategy is registered in the factory.
   * @param params `RateStrategyParams` the parameters of the rate strategy
   * @return address the address of the strategy
   */
  function getStrategyByParams(RateStrategyParams memory params) external view returns (address);

  /**
   * @notice From an asset in the Aave v3 pool, returns exclusively its parameters
   * @param asset The address of the asset
   * @return RateStrategyParams The parameters or the strategy, or empty RateStrategyParams struct
   */
  function getStrategyDataOfAsset(address asset) external view returns (RateStrategyParams memory);

  /**
   * @notice From a rate strategy address, returns its parameters
   * @param strategy The address of the rate strategy
   * @return RateStrategyParams Struct with the parameters of the strategy
   */
  function getStrategyData(
    IDefaultInterestRateStrategy strategy
  ) external view returns (RateStrategyParams memory);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3ArbitrumAssets} from 'aave-address-book/AaveV3Arbitrum.sol';
import {AaveV3PayloadArbitrum} from 'aave-helpers/v3-config-engine/AaveV3PayloadArbitrum.sol';
import {EngineFlags} from 'aave-helpers/v3-config-engine/EngineFlags.sol';
import {IAaveV3ConfigEngine} from 'aave-helpers/v3-config-engine/IAaveV3ConfigEngine.sol';
/**
 * @title Risk Parameters for DAI Update
 * @author Aave Chan Initiative
 * - Snapshot: https://snapshot.org/#/aave.eth/proposal/0x9f024edf6b8ebe1177503fbed3ceb6b5847cc0cae0e9269132c39b223db30023
 * - Discussion: https://governance.aave.com/t/arfc-risk-parameters-for-dai-update/17211
 */
contract AaveV3Arbitrum_RiskParametersForDAIUpdate_20240411 is AaveV3PayloadArbitrum {
  function collateralsUpdates()
    public
    pure
    override
    returns (IAaveV3ConfigEngine.CollateralUpdate[] memory)
  {
    IAaveV3ConfigEngine.CollateralUpdate[]
      memory collateralUpdate = new IAaveV3ConfigEngine.CollateralUpdate[](1);

    collateralUpdate[0] = IAaveV3ConfigEngine.CollateralUpdate({
      asset: AaveV3ArbitrumAssets.DAI_UNDERLYING,
      ltv: 63_00,
      liqThreshold: 77_00,
      liqBonus: EngineFlags.KEEP_CURRENT,
      debtCeiling: EngineFlags.KEEP_CURRENT,
      liqProtocolFee: EngineFlags.KEEP_CURRENT
    });

    return collateralUpdate;
  }
}