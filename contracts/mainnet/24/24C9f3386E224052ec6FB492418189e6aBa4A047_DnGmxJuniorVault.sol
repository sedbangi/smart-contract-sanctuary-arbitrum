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
  function handleAction(
    address user,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
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
  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

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
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

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
  function handleRepayment(
    address user,
    address onBehalfOf,
    uint256 amount
  ) external;

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
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;
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

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';
import {IPool} from './IPool.sol';

/**
 * @title IInitializableDebtToken
 * @author Aave
 * @notice Interface for the initialize function common between debt tokens
 */
interface IInitializableDebtToken {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param incentivesController The address of the incentives controller for this aToken
   * @param debtTokenDecimals The decimals of the debt token
   * @param debtTokenName The name of the debt token
   * @param debtTokenSymbol The symbol of the debt token
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the debt token.
   * @param pool The pool contract that is initializing this contract
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
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
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external returns (uint256);

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
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

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
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

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
  function getUserAccountData(address user)
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
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   */
  function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

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
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;

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
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
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

/**
 * @title IPriceOracle
 * @author Aave
 * @notice Defines the basic interface for a Price oracle.
 */
interface IPriceOracle {
  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint256);

  /**
   * @notice Set the price of the asset
   * @param asset The address of the asset
   * @param price The price of the asset
   */
  function setAssetPrice(address asset, uint256 price) external;
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableDebtToken} from './IInitializableDebtToken.sol';

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 */
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
  /**
   * @notice Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return True if the previous balance of the user is 0, false otherwise
   * @return The scaled total debt of the reserve
   */
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool, uint256);

  /**
   * @notice Burns user variable debt
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the debt will be burned
   * @param amount The amount getting burned
   * @param index The variable debt index of the reserve
   * @return The scaled total debt of the reserve
   */
  function burn(
    address from,
    uint256 amount,
    uint256 index
  ) external returns (uint256);

  /**
   * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FLASHLOAN_ENABLED_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
  uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

  uint256 internal constant MAX_VALID_LTV = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 internal constant MAX_VALID_DECIMALS = 255;
  uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
  uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
  uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
  uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
  uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
  uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
  uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

  uint256 public constant DEBT_CEILING_DECIMALS = 2;
  uint16 public constant MAX_RESERVES_COUNT = 128;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   */
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   */
  function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   */
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold)
    internal
    pure
  {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

    self.data =
      (self.data & LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   */
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   */
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
    internal
    pure
  {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

    self.data =
      (self.data & LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   */
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   */
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
    internal
    pure
  {
    require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   */
  function getDecimals(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   */
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @notice Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   */
  function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   */
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   */
  function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Sets the paused state of the reserve
   * @param self The reserve configuration
   * @param paused The paused state
   */
  function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
    self.data =
      (self.data & PAUSED_MASK) |
      (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the paused state of the reserve
   * @param self The reserve configuration
   * @return The paused state
   */
  function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~PAUSED_MASK) != 0;
  }

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
   * amount will be accumulated in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @param borrowable True if the asset is borrowable
   */
  function setBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self, bool borrowable)
    internal
    pure
  {
    self.data =
      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
      (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowable in isolation flag for the reserve.
   * @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
   * isolated collateral is accounted for in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @return The borrowable in isolation flag
   */
  function getBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
  }

  /**
   * @notice Sets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @param siloed True if the asset is siloed
   */
  function setSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self, bool siloed)
    internal
    pure
  {
    self.data =
      (self.data & SILOED_BORROWING_MASK) |
      (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @return The siloed borrowing flag
   */
  function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~SILOED_BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   */
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
    internal
    pure
  {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   */
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   */
  function setStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   */
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   */
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
    internal
    pure
  {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

    self.data =
      (self.data & RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @notice Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   */
  function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   */
  function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap)
    internal
    pure
  {
    require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   */
  function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   */
  function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap)
    internal
    pure
  {
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   */
  function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the debt ceiling in isolation mode for the asset
   * @param self The reserve configuration
   * @param ceiling The maximum debt ceiling for the asset
   */
  function setDebtCeiling(DataTypes.ReserveConfigurationMap memory self, uint256 ceiling)
    internal
    pure
  {
    require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);

    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
   * @param self The reserve configuration
   * @return The debt ceiling (0 = isolation mode disabled)
   */
  function getDebtCeiling(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation protocol fee of the reserve
   * @param self The reserve configuration
   * @param liquidationProtocolFee The liquidation protocol fee
   */
  function setLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 liquidationProtocolFee
  ) internal pure {
    require(
      liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
      Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
    );

    self.data =
      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
      (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation protocol fee
   * @param self The reserve configuration
   * @return The liquidation protocol fee
   */
  function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return
      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
  }

  /**
   * @notice Sets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @param unbackedMintCap The unbacked mint cap
   */
  function setUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 unbackedMintCap
  ) internal pure {
    require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);

    self.data =
      (self.data & UNBACKED_MINT_CAP_MASK) |
      (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @return The unbacked mint cap
   */
  function getUnbackedMintCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the eMode asset category
   * @param self The reserve configuration
   * @param category The asset category when the user selects the eMode
   */
  function setEModeCategory(DataTypes.ReserveConfigurationMap memory self, uint256 category)
    internal
    pure
  {
    require(category <= MAX_VALID_EMODE_CATEGORY, Errors.INVALID_EMODE_CATEGORY);

    self.data = (self.data & EMODE_CATEGORY_MASK) | (category << EMODE_CATEGORY_START_BIT_POSITION);
  }

  /**
   * @dev Gets the eMode asset category
   * @param self The reserve configuration
   * @return The eMode category for the asset
   */
  function getEModeCategory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
  }

  /**
   * @notice Sets the flashloanable flag for the reserve
   * @param self The reserve configuration
   * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
   */
  function setFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self, bool flashLoanEnabled)
    internal
    pure
  {
    self.data =
      (self.data & FLASHLOAN_ENABLED_MASK) |
      (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the flashloanable flag for the reserve
   * @param self The reserve configuration
   * @return The flashloanable flag
   */
  function getFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing active
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   * @return The state flag representing stableRateBorrowing enabled
   * @return The state flag representing paused
   */
  function getFlags(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0,
      (dataLocal & ~PAUSED_MASK) != 0
    );
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   * @return The state param representing eMode category
   */
  function getParams(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
      (dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
    );
  }

  /**
   * @notice Gets the caps parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing borrow cap
   * @return The state param representing supply cap.
   */
  function getCaps(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
    );
  }
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
  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
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
    //bit 62-63: reserved
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

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface IEACAggregatorProxy {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IRewardsDistributor} from './IRewardsDistributor.sol';
import {ITransferStrategyBase} from './ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from '../../misc/interfaces/IEACAggregatorProxy.sol';
import {RewardsDataTypes} from '../libraries/RewardsDataTypes.sol';

/**
 * @title IRewardsController
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsController is IRewardsDistributor {
  /**
   * @dev Emitted when a new address is whitelisted as claimer of rewards on behalf of a user
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @dev Emitted when rewards are claimed
   * @param user The address of the user rewards has been claimed on behalf of
   * @param reward The address of the token reward is claimed
   * @param to The address of the receiver of the rewards
   * @param claimer The address of the claimer
   * @param amount The amount of rewards claimed
   */
  event RewardsClaimed(
    address indexed user,
    address indexed reward,
    address indexed to,
    address claimer,
    uint256 amount
  );

  /**
   * @dev Emitted when a transfer strategy is installed for the reward distribution
   * @param reward The address of the token reward
   * @param transferStrategy The address of TransferStrategy contract
   */
  event TransferStrategyInstalled(address indexed reward, address indexed transferStrategy);

  /**
   * @dev Emitted when the reward oracle is updated
   * @param reward The address of the token reward
   * @param rewardOracle The address of oracle
   */
  event RewardOracleUpdated(address indexed reward, address indexed rewardOracle);

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
   * @param reward The address of the reward token
   * @param transferStrategy The address of the TransferStrategy logic contract
   */
  function setTransferStrategy(address reward, ITransferStrategyBase transferStrategy) external;

  /**
   * @dev Sets an Aave Oracle contract to enforce rewards with a source of value.
   * @notice At the moment of reward configuration, the Incentives Controller performs
   * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
   * This check is enforced for integrators to be able to show incentives at
   * the current Aave UI without the need to setup an external price registry
   * @param reward The address of the reward to set the price aggregator
   * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
   */
  function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle) external;

  /**
   * @dev Get the price aggregator oracle address
   * @param reward The address of the reward
   * @return The price oracle of the reward
   */
  function getRewardOracle(address reward) external view returns (address);

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
   * @param reward The address of the reward
   * @return The address of the TransferStrategy contract
   */
  function getTransferStrategy(address reward) external view returns (address);

  /**
   * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
   * @param config The assets configuration input, the list of structs contains the following fields:
   *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
   *   uint256 totalSupply: The total supply of the asset to incentivize
   *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
   *   address asset: The asset address to incentivize
   *   address reward: The reward token address
   *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
   *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
   *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
   */
  function configureAssets(RewardsDataTypes.RewardsConfigInput[] memory config) external;

  /**
   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
   * @dev The units of `totalSupply` and `userBalance` should be the same.
   * @param user The address of the user whose asset balance has changed
   * @param totalSupply The total supply of the asset prior to user balance change
   * @param userBalance The previous user balance prior to balance change
   **/
  function handleAction(
    address user,
    uint256 totalSupply,
    uint256 userBalance
  ) external;

  /**
   * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
   * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsToSelf(
    address[] calldata assets,
    uint256 amount,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

  /**
   * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IRewardsDistributor
 * @author Aave
 * @notice Defines the basic interface for a Rewards Distributor.
 */
interface IRewardsDistributor {
  /**
   * @dev Emitted when the configuration of the rewards of an asset is updated.
   * @param asset The address of the incentivized asset
   * @param reward The address of the reward token
   * @param oldEmission The old emissions per second value of the reward distribution
   * @param newEmission The new emissions per second value of the reward distribution
   * @param oldDistributionEnd The old end timestamp of the reward distribution
   * @param newDistributionEnd The new end timestamp of the reward distribution
   * @param assetIndex The index of the asset distribution
   */
  event AssetConfigUpdated(
    address indexed asset,
    address indexed reward,
    uint256 oldEmission,
    uint256 newEmission,
    uint256 oldDistributionEnd,
    uint256 newDistributionEnd,
    uint256 assetIndex
  );

  /**
   * @dev Emitted when rewards of an asset are accrued on behalf of a user.
   * @param asset The address of the incentivized asset
   * @param reward The address of the reward token
   * @param user The address of the user that rewards are accrued on behalf of
   * @param assetIndex The index of the asset distribution
   * @param userIndex The index of the asset distribution on behalf of the user
   * @param rewardsAccrued The amount of rewards accrued
   */
  event Accrued(
    address indexed asset,
    address indexed reward,
    address indexed user,
    uint256 assetIndex,
    uint256 userIndex,
    uint256 rewardsAccrued
  );

  /**
   * @dev Sets the end date for the distribution
   * @param asset The asset to incentivize
   * @param reward The reward token that incentives the asset
   * @param newDistributionEnd The end date of the incentivization, in unix time format
   **/
  function setDistributionEnd(
    address asset,
    address reward,
    uint32 newDistributionEnd
  ) external;

  /**
   * @dev Sets the emission per second of a set of reward distributions
   * @param asset The asset is being incentivized
   * @param rewards List of reward addresses are being distributed
   * @param newEmissionsPerSecond List of new reward emissions per second
   */
  function setEmissionPerSecond(
    address asset,
    address[] calldata rewards,
    uint88[] calldata newEmissionsPerSecond
  ) external;

  /**
   * @dev Gets the end date for the distribution
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The timestamp with the end of the distribution, in unix time format
   **/
  function getDistributionEnd(address asset, address reward) external view returns (uint256);

  /**
   * @dev Returns the index of a user on a reward distribution
   * @param user Address of the user
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The current user asset index, not including new distributions
   **/
  function getUserAssetIndex(
    address user,
    address asset,
    address reward
  ) external view returns (uint256);

  /**
   * @dev Returns the configuration of the distribution reward for a certain asset
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The index of the asset distribution
   * @return The emission per second of the reward distribution
   * @return The timestamp of the last update of the index
   * @return The timestamp of the distribution end
   **/
  function getRewardsData(address asset, address reward)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  /**
   * @dev Calculates the next value of an specific distribution index, with validations.
   * @param asset The incentivized asset
   * @param reward The reward token of the incentivized asset
   * @return The old index of the asset distribution
   * @return The new index of the asset distribution
   **/
  function getAssetIndex(address asset, address reward) external view returns (uint256, uint256);

  /**
   * @dev Returns the list of available reward token addresses of an incentivized asset
   * @param asset The incentivized asset
   * @return List of rewards addresses of the input asset
   **/
  function getRewardsByAsset(address asset) external view returns (address[] memory);

  /**
   * @dev Returns the list of available reward addresses
   * @return List of rewards supported in this contract
   **/
  function getRewardsList() external view returns (address[] memory);

  /**
   * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return Unclaimed rewards, not including new distributions
   **/
  function getUserAccruedRewards(address user, address reward) external view returns (uint256);

  /**
   * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
   * @param assets List of incentivized assets to check eligible distributions
   * @param user The address of the user
   * @param reward The address of the reward token
   * @return The rewards amount
   **/
  function getUserRewards(
    address[] calldata assets,
    address user,
    address reward
  ) external view returns (uint256);

  /**
   * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
   * @param assets List of incentivized assets to check eligible distributions
   * @param user The address of the user
   * @return The list of reward addresses
   * @return The list of unclaimed amount of rewards
   **/
  function getAllUserRewards(address[] calldata assets, address user)
    external
    view
    returns (address[] memory, uint256[] memory);

  /**
   * @dev Returns the decimals of an asset to calculate the distribution delta
   * @param asset The address to retrieve decimals
   * @return The decimals of an underlying asset
   */
  function getAssetDecimals(address asset) external view returns (uint8);

  /**
   * @dev Returns the address of the emission manager
   * @return The address of the EmissionManager
   */
  function EMISSION_MANAGER() external view returns (address);

  /**
   * @dev Returns the address of the emission manager.
   * Deprecated: This getter is maintained for compatibility purposes. Use the `EMISSION_MANAGER()` function instead.
   * @return The address of the EmissionManager
   */
  function getEmissionManager() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface ITransferStrategyBase {
  event EmergencyWithdrawal(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Perform custom transfer logic via delegate call from source contract to a TransferStrategy implementation
   * @param to Account to transfer rewards
   * @param reward Address of the reward token
   * @param amount Amount to transfer to the "to" address parameter
   * @return Returns true bool if transfer logic succeeds
   */
  function performTransfer(
    address to,
    address reward,
    uint256 amount
  ) external returns (bool);

  /**
   * @return Returns the address of the Incentives Controller
   */
  function getIncentivesController() external view returns (address);

  /**
   * @return Returns the address of the Rewards admin
   */
  function getRewardsAdmin() external view returns (address);

  /**
   * @dev Perform an emergency token withdrawal only callable by the Rewards admin
   * @param token Address of the token to withdraw funds from this contract
   * @param to Address of the recipient of the withdrawal
   * @param amount Amount of the withdrawal
   */
  function emergencyWithdrawal(
    address token,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {ITransferStrategyBase} from '../interfaces/ITransferStrategyBase.sol';
import {IEACAggregatorProxy} from '../../misc/interfaces/IEACAggregatorProxy.sol';

library RewardsDataTypes {
  struct RewardsConfigInput {
    uint88 emissionPerSecond;
    uint256 totalSupply;
    uint32 distributionEnd;
    address asset;
    address reward;
    ITransferStrategyBase transferStrategy;
    IEACAggregatorProxy rewardOracle;
  }

  struct UserAssetBalance {
    address asset;
    uint256 userBalance;
    uint256 totalSupply;
  }

  struct UserData {
    // Liquidity index of the reward distribution for the user
    uint104 index;
    // Amount of accrued rewards for the user since last user index update
    uint128 accrued;
  }

  struct RewardData {
    // Liquidity index of the reward distribution
    uint104 index;
    // Amount of reward tokens distributed per second
    uint88 emissionPerSecond;
    // Timestamp of the last reward index update
    uint32 lastUpdateTimestamp;
    // The end of the distribution of rewards (in seconds)
    uint32 distributionEnd;
    // Map of user addresses and their rewards data (userAddress => userData)
    mapping(address => UserData) usersData;
  }

  struct AssetData {
    // Map of reward token addresses and their data (rewardTokenAddress => rewardData)
    mapping(address => RewardData) rewards;
    // List of reward token addresses for the asset
    mapping(uint128 => address) availableRewards;
    // Count of reward tokens for the asset
    uint128 availableRewardsCount;
    // Number of decimals of the asset
    uint8 decimals;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            r = 255;
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) r -= 1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {SwapMath} from './SwapMath.sol';
import {SafeCast} from './SafeCast.sol';
import {TickMath} from './TickMath.sol';
import {TickBitmap} from './TickBitmap.sol';
import {BitMath} from './BitMath.sol';

import {IUniswapV3Pool} from '../interfaces/IUniswapV3Pool.sol';

/// @title Library for simulating swaps.
/// @notice By fully replicating the swap logic, we can make a static call to get a quote.
library Simulate {
    using SafeCast for uint256;

    struct Cache {
        // price at the beginning of the swap
        uint160 sqrtPriceX96Start;
        // tick at the beginning of the swap
        int24 tickStart;
        // liquidity at the beginning of the swap
        uint128 liquidityStart;
        // the lp fee of the pool
        uint24 fee;
        // the tick spacing of the pool
        int24 tickSpacing;
    }

    struct State {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the current liquidity in range
        uint128 liquidity;
    }

    // copied from UniswapV3Pool to avoid pragma issues associated with importing it
    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    function simulateSwap(
        IUniswapV3Pool pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) internal view returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, 'AS');

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();

        require(
            zeroForOne
                ? sqrtPriceLimitX96 < sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            'SPL'
        );

        Cache memory cache = Cache({
            sqrtPriceX96Start: sqrtPriceX96,
            tickStart: tick,
            liquidityStart: pool.liquidity(),
            fee: pool.fee(),
            tickSpacing: pool.tickSpacing()
        });

        bool exactInput = amountSpecified > 0;

        State memory state = State({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: cache.sqrtPriceX96Start,
            tick: cache.tickStart,
            liquidity: cache.liquidityStart
        });

        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = nextInitializedTickWithinOneWord(
                pool.tickBitmap,
                state.tick,
                cache.tickSpacing,
                zeroForOne
            );

            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                cache.fee
            );

            if (exactInput) {
                unchecked {
                    state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                }
                state.amountCalculated -= step.amountOut.toInt256();
            } else {
                unchecked {
                    state.amountSpecifiedRemaining += step.amountOut.toInt256();
                }
                state.amountCalculated += (step.amountIn + step.feeAmount).toInt256();
            }

            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                if (step.initialized) {
                    (, int128 liquidityNet, , , , , , ) = pool.ticks(step.tickNext);
                    unchecked {
                        if (zeroForOne) liquidityNet = -liquidityNet;
                    }

                    state.liquidity = liquidityNet < 0
                        ? state.liquidity - uint128(-liquidityNet)
                        : state.liquidity + uint128(liquidityNet);
                }

                unchecked {
                    state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
    }

    // This function replicates TickBitmap, but accepts a function pointer argument.
    // It's private because it's messy, and shouldn't be re-used.
    function nextInitializedTickWithinOneWord(
        function(int16) external view returns (uint256) self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) private view returns (int24 next, bool initialized) {
        unchecked {
            int24 compressed = tick / tickSpacing;
            if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

            if (lte) {
                (int16 wordPos, uint8 bitPos) = TickBitmap.position(compressed);
                // all the 1s at or to the right of the current bitPos
                uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
                uint256 masked = self(wordPos) & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                    : (compressed - int24(uint24(bitPos))) * tickSpacing;
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                (int16 wordPos, uint8 bitPos) = TickBitmap.position(compressed + 1);
                // all the 1s at or to the left of the bitPos
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = self(wordPos) & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                    : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from './SafeCast.sol';

import {FullMath} from './FullMath.sol';
import {UnsafeMath} from './UnsafeMath.sol';
import {FixedPoint96} from './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            unchecked {
                uint256 product;
                if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                    uint256 denominator = numerator1 + product;
                    if (denominator >= numerator1)
                        // always fits in 160 bits
                        return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
                }
            }
            // denominator is checked for overflow
            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96) + amount));
        } else {
            unchecked {
                uint256 product;
                // if the product overflows, we know the denominator underflows
                // in addition, we must check that the denominator does not underflow
                require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
                uint256 denominator = numerator1 - product;
                return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
            }
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION) / liquidity
                    : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            return (uint256(sqrtPX96) + quotient).toUint160();
        } else {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                    : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
            );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            unchecked {
                return uint160(sqrtPX96 - quotient);
            }
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
            uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

            require(sqrtRatioAX96 > 0);

            return
                roundUp
                    ? UnsafeMath.divRoundingUp(
                        FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                        sqrtRatioAX96
                    )
                    : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                roundUp
                    ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                    : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {FullMath} from './FullMath.sol';
import {SqrtPriceMath} from './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        unchecked {
            bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
            bool exactIn = amountRemaining >= 0;

            if (exactIn) {
                uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
                amountIn = zeroForOne
                    ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
                if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
                else
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        amountRemainingLessFee,
                        zeroForOne
                    );
            } else {
                amountOut = zeroForOne
                    ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
                if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
                else
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        uint256(-amountRemaining),
                        zeroForOne
                    );
            }

            bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

            // get the input/output amounts
            if (zeroForOne) {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
            } else {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
            }

            // cap the output amount to not exceed the remaining output amount
            if (!exactIn && amountOut > uint256(-amountRemaining)) {
                amountOut = uint256(-amountRemaining);
            }

            if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
                // we didn't reach the target, so take the remainder of the maximum input as fee
                feeAmount = uint256(amountRemaining) - amountIn;
            } else {
                feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BitMath} from './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) internal pure returns (int16 wordPos, uint8 bitPos) {
        unchecked {
            wordPos = int16(tick >> 8);
            bitPos = uint8(int8(tick % 256));
        }
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        unchecked {
            require(tick % tickSpacing == 0); // ensure that the tick is spaced
            (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
            uint256 mask = 1 << bitPos;
            self[wordPos] ^= mask;
        }
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        unchecked {
            int24 compressed = tick / tickSpacing;
            if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

            if (lte) {
                (int16 wordPos, uint8 bitPos) = position(compressed);
                // all the 1s at or to the right of the current bitPos
                uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
                uint256 masked = self[wordPos] & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                    : (compressed - int24(uint24(bitPos))) * tickSpacing;
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                (int16 wordPos, uint8 bitPos) = position(compressed + 1);
                // all the 1s at or to the left of the bitPos
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = self[wordPos] & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                    : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './PoolAddress.sol';

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return verifyCallback(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolAddress.PoolKey memory poolKey)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(msg.sender == address(pool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { ERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';

import { FixedPointMathLib } from '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';

import { IERC4626 } from '../interfaces/IERC4626.sol';

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Copied and modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626Upgradeable is IERC4626, ERC20Upgradeable {
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               STATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    address public asset;

    // these gaps are added to allow adding new variables without shifting down inheritance chain
    uint256[50] private __gaps;

    /* solhint-disable func-name-mixedcase */
    function __ERC4626Upgradeable_init(address _asset, string memory _name, string memory _symbol) internal {
        __ERC20_init(_name, _symbol);
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, 'ZERO_SHARES');

        // Need to transfer before minting or ERC777s could reenter.
        IERC20Metadata(asset).safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        IERC20Metadata(asset).safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender); // Saves gas for limited approvals.

            if (allowed != type(uint256).max) _approve(owner, msg.sender, allowed - shares);
        }

        beforeWithdraw(assets, shares, receiver);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        IERC20Metadata(asset).safeTransfer(receiver, assets);
    }

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender); // Saves gas for limited approvals.

            if (allowed != type(uint256).max) _approve(owner, msg.sender, allowed - shares);
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, 'ZERO_ASSETS');

        beforeWithdraw(assets, shares, receiver);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        IERC20Metadata(asset).safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() public view virtual returns (uint256);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    /* solhint-disable no-empty-blocks */
    function beforeWithdraw(uint256 assets, uint256 shares, address receiver) internal virtual {}

    /* solhint-disable no-empty-blocks */
    function afterDeposit(uint256 assets, uint256 shares, address receiver) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBalancerVault {
    event FlashLoan(address indexed recipient, address indexed token, uint256 amount, uint256 feeAmount);

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGlpManager {
    function glp() external view returns (address);

    function gov() external view returns (address);

    function cooldownDuration() external returns (uint256);

    function lastAddedAt(address _account) external returns (uint256);

    function setCooldownDuration(uint256 _cooldownDuration) external;

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function getAums() external view returns (uint256[] memory);

    function vault() external view returns (address);

    function getAumInUsdg(bool maximise) external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function getGlobalShortAveragePrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardRouterV2 {
    event StakeGmx(address account, address token, uint256 amount);
    event UnstakeGmx(address account, address token, uint256 amount);

    event StakeGlp(address account, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);

    function stakedGmxTracker() external view returns (address);

    function gmx() external view returns (address);

    function esGmx() external view returns (address);

    function glpVester() external view returns (address);

    function glpManager() external view returns (address);

    function batchStakeGmxForAccount(address[] memory _accounts, uint256[] memory _amounts) external;

    function stakeGmxForAccount(address _account, uint256 _amount) external;

    function stakeGmx(uint256 _amount) external;

    function stakeEsGmx(uint256 _amount) external;

    function unstakeGmx(uint256 _amount) external;

    function unstakeEsGmx(uint256 _amount) external;

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external returns (uint256);

    function claim() external;

    function claimEsGmx() external;

    function claimFees() external;

    function compound() external;

    function compoundForAccount(address _account) external;

    function handleRewards(
        bool shouldClaimGmx,
        bool shouldStakeGmx,
        bool shouldClaimEsGmx,
        bool shouldStakeEsGmx,
        bool shouldStakeMultiplierPoints,
        bool shouldClaimWeth,
        bool shouldConvertWethToEth
    ) external;

    function batchCompoundForAccounts(address[] memory _accounts) external;

    function signalTransfer(address _receiver) external;

    function acceptTransfer(address _sender) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';

interface ISglpExtended is IERC20 {
    function glp() external view returns (address);

    function glpManager() external view returns (address);

    function feeGlpTracker() external view returns (address);

    function stakedGlpTracker() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {
    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(address _token, address _receiver) external returns (uint256);

    function sellUSDG(address _token, address _receiver) external returns (uint256);

    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(address _account) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(address _account) external view returns (uint256);

    function transferredCumulativeRewards(address _account) external view returns (uint256);

    function cumulativeRewardDeductions(address _account) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;

    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);

    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw() external;

    function claim() external returns (uint256);

    function balances(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBorrower {
    function harvestFees() external;

    function getUsdcBorrowed() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IVariableDebtToken } from '@aave/core-v3/contracts/interfaces/IVariableDebtToken.sol';

interface IDebtToken is IVariableDebtToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

import { IERC4626 } from './IERC4626.sol';

pragma solidity ^0.8.0;

interface IDnGmxBatchingManager {
    error NoUsdcBalance();

    error CallerNotVault();
    error CallerNotKeeper();

    error InvalidInput(uint256 errorCode);
    error InsufficientShares(uint256 balance);

    error DepositCapBreached();
    error TargetAssetCapBreached(uint256 totalAssetsDeposited, uint256 depositAmount, uint256 targetAssetCap);

    event DepositToken(
        uint256 indexed round,
        address indexed token,
        address indexed receiver,
        uint256 amount,
        uint256 glpStaked
    );

    event ParamsV1Updated(address indexed rewardsHarvestingRouter, address weth);
    event KeeperUpdated(address newKeeper);
    event ThresholdsUpdated(uint256 newSlippageThresholdGmx, uint256 minUsdcConversionAmount);

    event BatchStake(uint256 indexed round, uint256 userUsdcAmount, uint256 userGlpAmount);
    event SharesClaimed(address indexed from, address indexed receiver, uint256 claimAmount);
    event BatchDeposit(uint256 indexed round, uint256 userUsdcAmount, uint256 userGlpAmount, uint256 userShareAmount);

    event ClaimedAndRedeemed(address indexed claimer, address indexed receiver, uint256 shares, uint256 assetsReceived);
    event DepositCapUpdated(uint256 newDepositCap);
    event TargetAssetCapUpdated(uint256 newTargeAssetCap);
    event PartialBatchDeposit(uint256 indexed round, uint256 partialGlpAmount, uint256 partialShareAmount);

    struct UserDeposit {
        uint256 round;
        uint128 usdcBalance;
        uint128 unclaimedShares;
    }
    struct RoundDeposit {
        uint128 totalUsdc;
        uint128 totalShares;
    }

    function executeBatch(uint128 usdcAmountToConvert) external;

    function currentRound() external view returns (uint256);

    function claim(address receiver, uint256 amount) external;

    function roundUsdcBalance() external view returns (uint256);

    function roundGlpStaked() external view returns (uint256);

    function usdcBalance(address account) external view returns (uint256 balance);

    function dnGmxJuniorVaultGlpBalance() external view returns (uint256 balance);

    function unclaimedShares(address account) external view returns (uint256 shares);

    function roundDeposits(uint256 round) external view returns (RoundDeposit memory);

    function depositUsdc(uint256 amount, address receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IRewardsController } from '@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol';
import { IPoolAddressesProvider } from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import { IPool } from '@aave/core-v3/contracts/interfaces/IPool.sol';
import { IPriceOracle } from '@aave/core-v3/contracts/interfaces/IPriceOracle.sol';
import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import { IERC4626 } from './IERC4626.sol';
import { IBorrower } from './IBorrower.sol';
import { IBalancerVault } from './balancer/IBalancerVault.sol';
import { IDnGmxTraderHedgeStrategy } from './IDnGmxTraderHedgeStrategy.sol';

interface IDnGmxJuniorVault is IERC4626, IBorrower {
    error InvalidWithdrawFeeBps();
    error InvalidSlippageThresholdSwapBtc();
    error InvalidSlippageThresholdSwapEth();
    error InvalidSlippageThresholdGmx();
    error InvalidRebalanceTimeThreshold();
    error InvalidRebalanceDeltaThresholdBps();
    error InvalidRebalanceHfThresholdBps();
    error InvalidTargetHealthFactor();

    error InvalidRebalance();
    error DepositCapExceeded();
    error OnlyKeeperAllowed(address msgSender, address authorisedKeeperAddress);
    error OnlyTraderHedgeStrategyAllowed(address msgSender, address authorisedKeeperAddress);
    error NotDnGmxSeniorVault();
    error NotBalancerVault();

    error ArraysLengthMismatch();
    error FlashloanNotInitiated();
    error TooMuchSlippage(uint netSlippage, uint assets);

    error InvalidFeeRecipient();
    error InvalidFeeBps();

    error InvalidTraderOIHedges(int128 btcTraderOIHedge, int128 ethTraderOIHedge);

    event Rebalanced();
    event AllowancesGranted();

    event DnGmxSeniorVaultUpdated(address _dnGmxSeniorVault);
    event KeeperUpdated(address _newKeeper);
    event FeeParamsUpdated(uint256 feeBps, address _newFeeRecipient);
    event WithdrawFeeUpdated(uint256 _withdrawFeeBps);
    event FeesWithdrawn(uint256 feeAmount);

    event DepositCapUpdated(uint256 _newDepositCap);

    event AdminParamsUpdated(
        address newKeeper,
        address dnGmxSeniorVault,
        uint256 newDepositCap,
        address batchingManager,
        uint16 withdrawFeeBps
    );
    event ThresholdsUpdated(
        uint16 slippageThresholdSwapBtcBps,
        uint16 slippageThresholdSwapEthBps,
        uint16 slippageThresholdGmxBps,
        uint128 usdcConversionThreshold,
        uint128 wethConversionThreshold,
        uint128 hedgeUsdcAmountThreshold,
        uint128 partialBtcHedgeUsdcAmountThreshold,
        uint128 partialEthHedgeUsdcAmountThreshold
    );

    event ParamsV1Updated(
        uint128 rebalanceProfitUsdcAmountThreshold,
        IDnGmxTraderHedgeStrategy dnGmxTraderHedgeStrategy
    );
    event RebalanceParamsUpdated(
        uint32 rebalanceTimeThreshold,
        uint16 rebalanceDeltaThresholdBps,
        uint16 rebalanceHfThresholdBps
    );

    event HedgeParamsUpdated(
        IBalancerVault vault,
        ISwapRouter swapRouter,
        uint256 targetHealthFactor,
        IRewardsController aaveRewardsController,
        IPool pool,
        IPriceOracle oracle
    );

    event EsGmxVested(uint256 amount);

    event EsGmxStaked(uint256 amount);

    event GmxClaimed(uint256 amount);

    event TraderOIHedgesUpdated(int256 btcTraderOIHedge, int256 ethTraderOIHedge);

    event AssetSlippage(address indexed user, uint slippage);

    function harvestFees() external;

    function depositCap() external view returns (uint256);

    function getPriceX128() external view returns (uint256);

    function getVaultMarketValue() external view returns (int256);

    function getMarketValue(uint256 assetAmount) external view returns (uint256 marketValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IBorrower } from './IBorrower.sol';
import { IERC4626 } from './IERC4626.sol';

interface IDnGmxSeniorVault is IERC4626 {
    error InvalidMaxUtilizationBps();

    error CallerNotBorrower();

    error InvalidCapUpdate();
    error InvalidBorrowAmount();
    error InvalidBorrowerAddress();

    error DepositCapExceeded();
    error MaxUtilizationBreached();

    event AllowancesGranted();
    event DepositCapUpdated(uint256 _newDepositCap);
    event BorrowCapUpdated(address vault, uint256 newCap);

    event LeveragePoolUpdated(IBorrower leveragePool);
    event DnGmxJuniorVaultUpdated(IBorrower dnGmxJuniorVault);
    event MaxUtilizationBpsUpdated(uint256 maxUtilizationBps);

    event FeeStrategyUpdated(
        uint128 optimalUtilizationRate,
        uint128 baseVariableBorrowRate,
        uint128 variableRateSlope1,
        uint128 variableRateSlope2
    );

    // eventType - 0 = start of txn | 1 = end of txn
    event VaultState(uint256 indexed eventType, uint256 juniorVaultAusdc, uint256 seniorVaultAusdc);

    function borrow(uint256 amount) external;

    function repay(uint256 amount) external;

    function depositCap() external view returns (uint256);

    function getPriceX128() external view returns (uint256);

    function getEthRewardsSplitRate() external returns (uint256);

    function getVaultMarketValue() external view returns (uint256);

    function availableBorrow(address borrower) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

pragma solidity ^0.8.9;

interface IDnGmxTraderHedgeStrategy {
    function overrideTraderOIHedges(int128 btcTraderOIHedge, int128 ethTraderOIHedge) external;

    function setTraderOIHedgeBps(uint16 _traderOIHedgeBps) external;

    function setTraderOIHedges() external;

    function btcTraderOIHedge() external view returns (int128);

    function ethTraderOIHedge() external view returns (int128);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';

interface IERC4626 is IERC20Upgradeable {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IVault } from '../interfaces/gmx/IVault.sol';
import { IGlpManager } from '../interfaces/gmx/IGlpManager.sol';
import { IRewardTracker } from '../interfaces/gmx/IRewardTracker.sol';
import { IRewardRouterV2 } from '../interfaces/gmx/IRewardRouterV2.sol';

import { IDebtToken } from '../interfaces/IDebtToken.sol';
import { IPool } from '@aave/core-v3/contracts/interfaces/IPool.sol';
import { IAToken } from '@aave/core-v3/contracts/interfaces/IAToken.sol';
import { IPriceOracle } from '@aave/core-v3/contracts/interfaces/IPriceOracle.sol';
import { DataTypes } from '@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol';
import { IPoolAddressesProvider } from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import { IRewardsController } from '@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol';
import { ReserveConfiguration } from '@aave/core-v3/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';

import { IBalancerVault } from '../interfaces/balancer/IBalancerVault.sol';

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';

import { IDnGmxJuniorVault } from '../interfaces/IDnGmxJuniorVault.sol';
import { IDnGmxSeniorVault } from '../interfaces/IDnGmxSeniorVault.sol';
import { IDnGmxBatchingManager } from '../interfaces/IDnGmxBatchingManager.sol';
import { IDnGmxTraderHedgeStrategy } from '../interfaces/IDnGmxTraderHedgeStrategy.sol';

import { SafeCast } from '../libraries/SafeCast.sol';
import { FeeSplitStrategy } from '../libraries/FeeSplitStrategy.sol';
import { SignedFixedPointMathLib } from '../libraries/SignedFixedPointMathLib.sol';
import { QuoterLib } from '../libraries/QuoterLib.sol';
import { SwapPath } from '../libraries/SwapPath.sol';

import { FixedPointMathLib } from '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';

import { Simulate } from '@uniswap/v3-core/contracts/libraries/Simulate.sol';
import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

/**
 * @title Helper library for junior vault
 * @dev junior vault delegates calls to this library for logic
 * @author RageTrade
 */

library DnGmxJuniorVaultManager {
    event RewardsHarvested(
        uint256 wethHarvested,
        uint256 esGmxStaked,
        uint256 juniorVaultWeth,
        uint256 seniorVaultWeth,
        uint256 juniorVaultGlp,
        uint256 seniorVaultAUsdc
    );

    event ProtocolFeeAccrued(uint256 fees);

    event GlpSwapped(uint256 glpQuantity, uint256 usdcQuantity, bool fromGlpToUsdc);

    event TokenSwapped(address indexed fromToken, address indexed toToken, uint256 fromQuantity, uint256 toQuantity);

    event VaultState(
        uint256 indexed eventType,
        uint256 btcBorrows,
        uint256 ethBorrows,
        uint256 btcPoolAmount,
        uint256 ethPoolAmount,
        int256 btcTraderOIHedge,
        int256 ethTraderOIHedge,
        uint256 glpPrice,
        uint256 glpBalance,
        uint256 totalAssets,
        int256 dnUsdcDeposited,
        uint256 unhedgedGlpInUsdc,
        uint256 juniorVaultAusdc,
        uint256 seniorVaultAusdc
    );

    using DnGmxJuniorVaultManager for State;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    using FixedPointMathLib for uint256;
    using SafeCast for uint256;
    using SignedFixedPointMathLib for int256;

    uint256 internal constant MAX_BPS = 10_000;

    uint256 internal constant PRICE_PRECISION = 1e30;
    uint256 internal constant VARIABLE_INTEREST_MODE = 2;

    struct Tokens {
        IERC20Metadata weth;
        IERC20Metadata wbtc;
        IERC20Metadata sGlp;
        IERC20Metadata usdc;
    }

    // prettier-ignore
    struct State {
        // core protocol roles
        address keeper;
        address feeRecipient;

        // accounting
        // amount of usdc deposited by junior tranche into AAVE
        int256 dnUsdcDeposited;
        // amount of asset which is in usdc (due to borrow limits / availability issue some glp might remain unhedged)
        uint256 unhedgedGlpInUsdc;
        // health factor to be targetted on AAVE
        uint256 targetHealthFactor;

        // accumulators
        // protocol fee taken from ETH rewards
        uint256 protocolFee;
        // protocol fee taken from esGMX rewards
        uint256 protocolEsGmx;
        // senior tranche part of eth rewards which is not converted to usdc
        uint256 seniorVaultWethRewards;

        // locks
        // true if a flashloan has been initiated by the vault
        bool hasFlashloaned;
        // ensures that the rebalance can be run only after certain intervals
        uint48 lastRebalanceTS;

        // fees
        // protocol fees charged on the eth and esGmx rewards
        uint16 feeBps;
        // fees on the withdrawn assets
        uint16 withdrawFeeBps;
        // fee tier for uniswap path
        uint24 feeTierWethWbtcPool;

        // thresholds
        uint256 depositCap;

        // slippage threshold on asset conversion into glp
        uint16 slippageThresholdGmxBps; // bps
        // slippage threshold on btc swap on uniswap
        uint16 slippageThresholdSwapBtcBps; // bps
        // slippage threshold on eth swap on uniswap
        uint16 slippageThresholdSwapEthBps; // bps
        // health factor treshold below which rebalance can be called
        uint16 rebalanceHfThresholdBps; // bps
        // time threshold beyond which on top of last rebalance, rebalance can be called
        uint32 rebalanceTimeThreshold; // seconds between rebalance
        // difference between current and optimal amounts beyond which rebalance can be called
        uint16 rebalanceDeltaThresholdBps; // bps
        // eth amount of weth rewards accrued beyond which they can be compounded
        uint128 wethConversionThreshold; // eth amount

        // usdc amount beyond which usdc can be converted to assets
        uint128 usdcConversionThreshold; // usdc amount
        // usdc value of token hedges below which hedges are not taken
        uint128 hedgeUsdcAmountThreshold; // usdc amount

        // usdc amount of btc hedge beyond which partial hedges are taken over multiple rebalances
        uint128 partialBtcHedgeUsdcAmountThreshold; // usdc amount
        // usdc amount of eth hedge beyond which partial hedges are taken over multiple rebalances
        uint128 partialEthHedgeUsdcAmountThreshold; // usdc amount

        // token addrs
        IERC20 fsGlp;
        IERC20Metadata glp;
        IERC20Metadata usdc;
        IERC20Metadata weth;
        IERC20Metadata wbtc;

        // aave protocol addrs
        // lending pool for liqudity market
        IPool pool;
        // aave interest bearing usdc
        IAToken aUsdc;
        // variable-rate debt accruing btc
        IDebtToken vWbtc;
        // variable-rate debt accruing eth
        IDebtToken vWeth;
        // cannocial oracle used by aave
        IPriceOracle oracle;
        // rewards controller to claim any emissions (for future use)
        IRewardsController aaveRewardsController;
        // immutable address provider to obtain various addresses
        IPoolAddressesProvider poolAddressProvider;

        // gmx protocol addrs
        // core gmx vault
        IVault gmxVault;
        // staked gmx
        IRewardTracker sGmx;
        // glp manager (for giving assets allowance and fetching AUM)
        IGlpManager glpManager;
        // old rewardRouter for all actions except minting and burning glp
        IRewardRouterV2 rewardRouter;
        // new rewardRouter to be used for mintAndStakeGlp and unstakeAndRedeem
        // ref: https://medium.com/@gmx.io/gmx-deployment-updates-nov-2022-16572314874d
        IRewardRouterV2 mintBurnRewardRouter;

        // other external protocols
        // uniswap swap router for token swaps
        ISwapRouter swapRouter;
        // balancer vault for flashloans
        IBalancerVault balancerVault;

        // core protocol addrs
        // senior tranche address
        IDnGmxSeniorVault dnGmxSeniorVault;
        // batching manager address !!! Deprecated !!!
        IDnGmxBatchingManager batchingManager;

        // switch to select route
        bool useDirectConversionBurn;
        bool useDirectConversionMint;

        // !!! STORAGE EXTENSIONS !!! (reduced gaps by no. of slots added here)
        uint128 btcPoolAmount;
        uint128 ethPoolAmount;

        int128 btcTraderOIHedge;
        int128 ethTraderOIHedge;

        IDnGmxTraderHedgeStrategy dnGmxTraderHedgeStrategy;

        uint128 rebalanceProfitUsdcAmountThreshold;

        // gaps for extending struct (if required during upgrade)
        uint256[46] __gaps;
    }

    /// @notice stakes the rewards from the staked Glp and claims WETH to buy glp
    /// @notice also update protocolEsGmx fees which can be vested and claimed
    /// @notice divides the fees between senior and junior tranches based on senior tranche util
    /// @notice for junior tranche weth is deposited to batching manager which handles conversion to sGLP
    /// @notice for senior tranche weth is converted into usdc and deposited on AAVE which increases the borrowed amount
    function harvestFees(State storage state) public {
        uint256 sGmxHarvested;
        {
            address esGmx = state.rewardRouter.esGmx();
            IRewardTracker sGmx = IRewardTracker(state.rewardRouter.stakedGmxTracker());

            // existing staked gmx balance
            uint256 sGmxPrevBalance = sGmx.depositBalances(address(this), esGmx);

            // handles claiming and staking of esGMX, staking of multiplier points and claim of WETH rewards on GMX
            state.rewardRouter.handleRewards({
                shouldClaimGmx: false,
                shouldStakeGmx: false,
                shouldClaimEsGmx: true,
                shouldStakeEsGmx: true,
                shouldStakeMultiplierPoints: true,
                shouldClaimWeth: true,
                shouldConvertWethToEth: false
            });

            // harvested staked gmx
            sGmxHarvested = sGmx.depositBalances(address(this), esGmx) - sGmxPrevBalance;
        }
        // protocol esGMX fees
        state.protocolEsGmx += sGmxHarvested.mulDivDown(state.feeBps, MAX_BPS);

        // total weth harvested which is not compounded
        // its possible that this is accumulated value over multiple rebalance if in all of those it was below threshold
        uint256 wethHarvested = state.weth.balanceOf(address(this)) - state.protocolFee - state.seniorVaultWethRewards;

        if (wethHarvested > state.wethConversionThreshold) {
            // weth harvested > conversion threshold
            uint256 protocolFeeHarvested = (wethHarvested * state.feeBps) / MAX_BPS;
            // protocol fee incremented
            state.protocolFee += protocolFeeHarvested;
            emit ProtocolFeeAccrued(protocolFeeHarvested);

            // protocol fee to be kept in weth
            // remaining amount needs to be compounded
            uint256 wethToCompound = wethHarvested - protocolFeeHarvested;

            // share of the wethToCompound that belongs to senior tranche
            uint256 dnGmxSeniorVaultWethShare = state.dnGmxSeniorVault.getEthRewardsSplitRate().mulDivDown(
                wethToCompound,
                FeeSplitStrategy.RATE_PRECISION
            );
            // share of the wethToCompound that belongs to junior tranche
            uint256 dnGmxWethShare = wethToCompound - dnGmxSeniorVaultWethShare;

            // total senior tranche weth which is not compounded
            uint256 _seniorVaultWethRewards = state.seniorVaultWethRewards + dnGmxSeniorVaultWethShare;

            uint256 glpReceived;
            {
                // converts junior tranche share of weth into glp using batching manager
                // we need to use batching manager since there is a cooldown period on sGLP
                // if deposited directly for next 15mins withdrawals would fail
                uint256 price = state.gmxVault.getMinPrice(address(state.weth));

                uint256 usdgAmount = dnGmxWethShare.mulDivDown(
                    price * (MAX_BPS - state.slippageThresholdGmxBps),
                    PRICE_PRECISION * MAX_BPS
                );

                // deposits weth into batching manager which handles the conversion into glp
                // can be taken back through batch execution
                glpReceived = _stakeGlp(state, address(state.weth), dnGmxWethShare, usdgAmount);
            }

            if (_seniorVaultWethRewards > state.wethConversionThreshold) {
                // converts senior tranche share of weth into usdc and deposit into AAVE
                // Deposit aave vault share to AAVE in usdc
                uint256 minUsdcAmount = _getTokenPriceInUsdc(state, state.weth).mulDivDown(
                    _seniorVaultWethRewards * (MAX_BPS - state.slippageThresholdSwapEthBps),
                    MAX_BPS * PRICE_PRECISION
                );
                // swaps weth into usdc
                (uint256 aaveUsdcAmount, ) = state._swapToken(
                    address(state.weth),
                    _seniorVaultWethRewards,
                    minUsdcAmount
                );

                // supplies usdc into AAVE
                state._executeSupply(address(state.usdc), aaveUsdcAmount);

                // resets senior tranche rewards
                state.seniorVaultWethRewards = 0;

                emit RewardsHarvested(
                    wethHarvested,
                    sGmxHarvested,
                    dnGmxWethShare,
                    dnGmxSeniorVaultWethShare,
                    glpReceived,
                    aaveUsdcAmount
                );
            } else {
                state.seniorVaultWethRewards = _seniorVaultWethRewards;
                emit RewardsHarvested(
                    wethHarvested,
                    sGmxHarvested,
                    dnGmxWethShare,
                    dnGmxSeniorVaultWethShare,
                    glpReceived,
                    0
                );
            }
        } else {
            emit RewardsHarvested(wethHarvested, sGmxHarvested, 0, 0, 0, 0);
        }
    }

    /* ##################################################################
                            REBALANCE HELPERS
    ################################################################## */

    ///@notice rebalances pnl on AAVE against the sGLP assets
    ///@param state set of all state variables of vault
    ///@param borrowValue value of the borrowed assets(ETH + BTC) from AAVE in USDC
    function rebalanceProfit(State storage state, uint256 borrowValue) external {
        return _rebalanceProfit(state, borrowValue);
    }

    ///@notice rebalances pnl on AAVE against the sGLP assets
    ///@dev converts assets into usdc and deposits to AAVE if profit on GMX and loss on AAVE
    ///@dev withdraws usdc from aave and converts to GLP if loss on GMX and profits on AAVE
    ///@param state set of all state variables of vault
    ///@param borrowValue value of the borrowed assets(ETH + BTC) from AAVE in USDC
    function _rebalanceProfit(State storage state, uint256 borrowValue) private {
        int256 borrowVal = borrowValue.toInt256();

        if (borrowVal > state.dnUsdcDeposited) {
            uint256 diff = uint256(borrowVal - state.dnUsdcDeposited);
            if (diff < state.rebalanceProfitUsdcAmountThreshold && !_isValidRebalanceHF(state)) return;
            // If glp goes up - there is profit on GMX and loss on AAVE
            // So convert some glp to usdc and deposit to AAVE
            state.dnUsdcDeposited += _convertAssetToAUsdc(state, diff).toInt256();
        } else if (borrowVal < state.dnUsdcDeposited) {
            uint256 diff = uint256(state.dnUsdcDeposited - borrowVal);
            if (diff < state.rebalanceProfitUsdcAmountThreshold) return;
            // If glp goes down - there is profit on AAVE and loss on GMX
            // So withdraw some aave usdc and convert to glp
            _convertAUsdcToAsset(state, diff);
            state.dnUsdcDeposited = borrowVal;
        }
    }

    ///@notice rebalances the assets borrowed from AAVE to hedge ETH and BTC underlying the assets
    ///@param state set of all state variables of vault
    ///@param optimalBtcBorrow optimal btc amount to hedge sGLP btc underlying completely
    ///@param currentBtcBorrow current btc amount borrowed from AAVE
    ///@param optimalEthBorrow optimal eth amount to hedge sGLP btc underlying completely
    ///@param currentEthBorrow current eth amount borrowed from AAVE
    function rebalanceBorrow(
        State storage state,
        uint256 optimalBtcBorrow,
        uint256 currentBtcBorrow,
        uint256 optimalEthBorrow,
        uint256 currentEthBorrow
    ) external {
        return _rebalanceBorrow(state, optimalBtcBorrow, currentBtcBorrow, optimalEthBorrow, currentEthBorrow);
    }

    ///@notice rebalances the assets borrowed from AAVE to hedge ETH and BTC underlying the assets
    ///@param state set of all state variables of vault
    ///@param optimalBtcBorrow optimal btc amount to hedge sGLP btc underlying completely
    ///@param currentBtcBorrow current btc amount borrowed from AAVE
    ///@param optimalEthBorrow optimal eth amount to hedge sGLP btc underlying completely
    ///@param currentEthBorrow current eth amount borrowed from AAVE
    function _rebalanceBorrow(
        State storage state,
        uint256 optimalBtcBorrow,
        uint256 currentBtcBorrow,
        uint256 optimalEthBorrow,
        uint256 currentEthBorrow
    ) private {
        address[] memory assets;
        uint256[] memory amounts;

        // calculate the token/usdc amount to be flashloaned from balancer
        (uint256 btcTokenAmount, uint256 btcUsdcAmount, bool repayDebtBtc) = _flashloanAmounts(
            state,
            address(state.wbtc),
            optimalBtcBorrow,
            currentBtcBorrow
        );
        (uint256 ethTokenAmount, uint256 ethUsdcAmount, bool repayDebtEth) = _flashloanAmounts(
            state,
            address(state.weth),
            optimalEthBorrow,
            currentEthBorrow
        );

        // no swap needs to happen if the amount to hedge < threshold
        if (btcUsdcAmount < state.hedgeUsdcAmountThreshold) {
            btcTokenAmount = 0;
            btcUsdcAmount = 0;
        }
        if (ethUsdcAmount < state.hedgeUsdcAmountThreshold) {
            ethTokenAmount = 0;
            ethUsdcAmount = 0;
        }

        // get asset amount basis increase/decrease of token amounts
        uint256 btcAssetAmount = repayDebtBtc ? btcUsdcAmount : btcTokenAmount;
        uint256 ethAssetAmount = repayDebtEth ? ethUsdcAmount : ethTokenAmount;

        // If both eth and btc swap amounts are not beyond the threshold then no flashloan needs to be executed | case 1
        if (btcAssetAmount == 0 && ethAssetAmount == 0) return;

        if (repayDebtBtc && repayDebtEth) {
            // case where both the token assets are USDC
            // only one entry required which is combined asset amount for both tokens
            assets = new address[](1);
            amounts = new uint256[](1);

            assets[0] = address(state.usdc);
            amounts[0] = (btcAssetAmount + ethAssetAmount);
        } else if (btcAssetAmount == 0 || ethAssetAmount == 0) {
            // Exactly one would be true since case-1 excluded (both false) | case-2
            // One token amount = 0 and other token amount > 0
            // only one entry required for the non-zero amount token
            assets = new address[](1);
            amounts = new uint256[](1);

            if (btcAssetAmount != 0) {
                assets[0] = (repayDebtBtc ? address(state.usdc) : address(state.wbtc));
                amounts[0] = btcAssetAmount;
            } else {
                assets[0] = (repayDebtEth ? address(state.usdc) : address(state.weth));
                amounts[0] = ethAssetAmount;
            }
        } else {
            // Both are true | case-3
            assets = new address[](2);
            amounts = new uint256[](2);

            assets[0] = repayDebtBtc ? address(state.usdc) : address(state.wbtc);

            assets[1] = repayDebtEth ? address(state.usdc) : address(state.weth);

            // ensure that assets and amount tuples are in sorted order of addresses
            // (required for balancer flashloans)
            if (assets[0] > assets[1]) {
                // if the order is descending
                // switch the order for assets tupe
                // assign amounts in opposite order
                address tempAsset = assets[0];
                assets[0] = assets[1];
                assets[1] = tempAsset;

                amounts[0] = ethAssetAmount;

                amounts[1] = btcAssetAmount;
            } else {
                // if the order is ascending
                // assign amount in same order
                amounts[0] = btcAssetAmount;

                amounts[1] = ethAssetAmount;
            }
        }
        // execute the flashloan
        _executeFlashloan(
            state,
            assets,
            amounts,
            btcTokenAmount,
            btcUsdcAmount,
            ethTokenAmount,
            ethUsdcAmount,
            repayDebtBtc,
            repayDebtEth
        );
    }

    ///@notice returns the optimal borrow amounts based on a swap threshold
    ///@dev if the swap amount is less than threshold then that is returned
    ///@dev if the swap amount is greater than threshold then threshold amount is returned
    ///@param state set of all state variables of vault
    ///@param token ETH / BTC token
    ///@param optimalTokenBorrow optimal btc amount to hedge sGLP btc underlying completely
    ///@param currentTokenBorrow current btc amount borrowed from AAVE
    ///@return optimalPartialTokenBorrow optimal token hedge if threshold is breached
    ///@return isPartialTokenHedge true if partial hedge needs to be executed for token
    function _getOptimalPartialBorrows(
        State storage state,
        IERC20Metadata token,
        uint256 optimalTokenBorrow,
        uint256 currentTokenBorrow
    ) internal view returns (uint256 optimalPartialTokenBorrow, bool isPartialTokenHedge) {
        // checks if token hedge needs to be increased or decreased
        bool isOptimalHigher = optimalTokenBorrow > currentTokenBorrow;
        // difference = amount of swap to be done for complete hedge
        uint256 diff = isOptimalHigher
            ? optimalTokenBorrow - currentTokenBorrow
            : currentTokenBorrow - optimalTokenBorrow;

        // get the correct threshold basis the token
        uint256 threshold = address(token) == address(state.wbtc)
            ? state.partialBtcHedgeUsdcAmountThreshold
            : state.partialEthHedgeUsdcAmountThreshold;

        // convert usdc threshold into token amount threshold
        uint256 tokenThreshold = threshold.mulDivDown(PRICE_PRECISION, _getTokenPriceInUsdc(state, token));

        if (diff > tokenThreshold) {
            // amount to swap > threshold
            // swap only the threshold amount in this rebalance (partial hedge)
            optimalPartialTokenBorrow = isOptimalHigher
                ? currentTokenBorrow + tokenThreshold
                : currentTokenBorrow - tokenThreshold;
            isPartialTokenHedge = true;
        } else {
            // amount to swap < threshold
            // swap the full amount in this rebalance (complete hedge)
            optimalPartialTokenBorrow = optimalTokenBorrow;
        }
    }

    function _getOptimalBorrowsFinal(
        State storage state,
        uint256 currentBtcBorrow,
        uint256 currentEthBorrow,
        uint256 glpDeposited,
        bool[2] memory conditions // (isPartialAllowed, useUpdatedPoolAmounts)
    )
        internal
        view
        returns (
            uint256 optimalBtcBorrow,
            uint256 optimalEthBorrow,
            uint256 targetDnGmxSeniorVaultAmount,
            uint256 optimalUncappedEthBorrow,
            bool isPartialHedge
        )
    {
        // optimal btc and eth borrows
        // calculated basis the underlying token weights in glp

        (optimalBtcBorrow, optimalEthBorrow) = _getOptimalBorrows({
            state: state,
            glpDeposited: glpDeposited,
            withUpdatedPoolAmounts: conditions[1]
        });

        if (conditions[0] /*isPartialHedge*/) {
            // if partial hedges are allowed (i.e. rebalance call and not deposit/withdraw)
            // check if swap amounts>threshold then basis that do a partial hedge
            bool isPartialBtcHedge;
            bool isPartialEthHedge;
            // get optimal borrows basis hedge thresholds
            (optimalBtcBorrow, isPartialBtcHedge) = _getOptimalPartialBorrows(
                state,
                state.wbtc,
                optimalBtcBorrow,
                currentBtcBorrow
            );
            (optimalEthBorrow, isPartialEthHedge) = _getOptimalPartialBorrows(
                state,
                state.weth,
                optimalEthBorrow,
                currentEthBorrow
            );
            // if some token is partially hedged then set that this rebalance is partial
            // lastRebalanceTime not updated in this case so a rebalance can be called again
            isPartialHedge = isPartialBtcHedge || isPartialEthHedge;
        }

        // calculate usdc value of optimal borrows
        uint256 optimalBorrowValue = _getBorrowValue(state, optimalBtcBorrow, optimalEthBorrow);

        // get liquidation threshold of usdc on AAVE
        uint256 usdcLiquidationThreshold = _getLiquidationThreshold(state, address(state.usdc));

        // Settle net change in market value and deposit/withdraw collateral tokens
        // Vault market value is just the collateral value since profit has been settled
        // AAVE target health factor = (usdc supply value * usdc liquidation threshold)/borrow value
        // whatever tokens we borrow from AAVE (ETH/BTC) we sell for usdc and deposit that usdc into AAVE
        // assuming 0 slippage borrow value of tokens = usdc deposit value (this leads to very small variation in hf)
        // usdc supply value = usdc borrowed from senior tranche + borrow value
        // replacing usdc supply value formula above in AAVE target health factor formula
        // we can derive usdc amount to borrow from senior tranche i.e. targetDnGmxSeniorVaultAmount
        targetDnGmxSeniorVaultAmount = (state.targetHealthFactor - usdcLiquidationThreshold).mulDivDown(
            optimalBorrowValue,
            usdcLiquidationThreshold
        );

        // current usdc borrowed from senior tranche
        uint256 currentDnGmxSeniorVaultAmount = _getUsdcBorrowed(state);

        if (targetDnGmxSeniorVaultAmount > currentDnGmxSeniorVaultAmount) {
            // case where we need to borrow more usdc
            // To get more usdc from senior tranche, so usdc is borrowed first and then hedge is updated on AAVE
            {
                uint256 amountToBorrow = targetDnGmxSeniorVaultAmount - currentDnGmxSeniorVaultAmount;
                uint256 availableBorrow = state.dnGmxSeniorVault.availableBorrow(address(this));
                if (amountToBorrow > availableBorrow) {
                    // if amount to borrow > available borrow amount
                    // we won't be able to hedge glp completely
                    // convert some glp into usdc to keep the vault delta neutral
                    // hedge the btc/eth of remaining amount
                    optimalUncappedEthBorrow = optimalEthBorrow;

                    // optimal btc and eth borrows basis the hedged part of glp
                    (optimalBtcBorrow, optimalEthBorrow) = _getOptimalCappedBorrows(
                        state,
                        currentDnGmxSeniorVaultAmount + availableBorrow,
                        usdcLiquidationThreshold
                    );
                }
            }
        }

        return (
            optimalBtcBorrow,
            optimalEthBorrow,
            targetDnGmxSeniorVaultAmount,
            optimalUncappedEthBorrow,
            isPartialHedge
        );
    }

    ///@notice rebalances btc and eth hedges according to underlying glp token weights
    ///@notice updates the borrowed amount from senior tranche basis the target health factor
    ///@notice if the amount of swap for a token > theshold then a partial hedge is taken and remaining is taken separately
    ///@notice if the amount of swap for a token < threshold complete hedge is taken
    ///@notice in case there is not enough money in senior tranche then relevant amount of glp is converted into usdc
    ///@dev to be called after settle profits only (since vaultMarketValue if after settlement of profits)
    ///@param state set of all state variables of vault
    ///@param currentBtcBorrow The amount of USDC collateral token deposited to LB Protocol
    ///@param currentEthBorrow The market value of ETH/BTC part in sGLP
    ///@param glpDeposited amount of glp deposited into the vault
    ///@param isPartialAllowed true if partial hedge is allowed
    ///@return isPartialHedge true if partial hedge is executed
    function rebalanceHedge(
        State storage state,
        uint256 currentBtcBorrow,
        uint256 currentEthBorrow,
        uint256 glpDeposited,
        bool isPartialAllowed
    ) external returns (bool isPartialHedge) {
        {
            uint256 optimalBtcBorrow;
            uint256 optimalEthBorrow;
            uint256 targetDnGmxSeniorVaultAmount;
            uint256 currentDnGmxSeniorVaultAmount;
            uint256 optimalUncappedEthBorrow;
            (
                optimalBtcBorrow,
                optimalEthBorrow,
                targetDnGmxSeniorVaultAmount,
                optimalUncappedEthBorrow,
                isPartialHedge
            ) = _getOptimalBorrowsFinal(
                state,
                currentBtcBorrow,
                currentEthBorrow,
                glpDeposited,
                [isPartialAllowed, false]
            );
            // current usdc borrowed from senior tranche
            currentDnGmxSeniorVaultAmount = _getUsdcBorrowed(state);
            if (targetDnGmxSeniorVaultAmount > currentDnGmxSeniorVaultAmount) {
                // case where we need to borrow more usdc
                // To get more usdc from senior tranche, so usdc is borrowed first and then hedge is updated on AAVE
                {
                    uint256 amountToBorrow = targetDnGmxSeniorVaultAmount - currentDnGmxSeniorVaultAmount;
                    uint256 availableBorrow = state.dnGmxSeniorVault.availableBorrow(address(this));

                    if (amountToBorrow > availableBorrow) {
                        // if amount to borrow > available borrow amount
                        // we won't be able to hedge glp completely
                        // convert some glp into usdc to keep the vault delta neutral
                        // hedge the btc/eth of remaining amount

                        // rebalance the unhedged glp (increase/decrease basis the capped optimal token hedges)
                        _rebalanceUnhedgedGlp(state, optimalUncappedEthBorrow, optimalEthBorrow);

                        if (availableBorrow > 0) {
                            // borrow whatever is available since required > available
                            state.dnGmxSeniorVault.borrow(availableBorrow);
                        }
                    } else {
                        //No unhedged glp remaining so just pass same value in capped and uncapped (should convert back any ausdc back to sglp)
                        _rebalanceUnhedgedGlp(state, optimalEthBorrow, optimalEthBorrow);

                        // Take from LB Vault
                        state.dnGmxSeniorVault.borrow(targetDnGmxSeniorVaultAmount - currentDnGmxSeniorVaultAmount);
                    }
                }

                // Rebalance Position
                // Executes a flashloan from balancer and btc/eth borrow updates on AAVE
                _rebalanceBorrow(state, optimalBtcBorrow, currentBtcBorrow, optimalEthBorrow, currentEthBorrow);
            } else {
                //No unhedged glp remaining so just pass same value in capped and uncapped (should convert back any ausdc back to sglp)
                _rebalanceUnhedgedGlp(state, optimalEthBorrow, optimalEthBorrow);

                // Executes a flashloan from balancer and btc/eth borrow updates on AAVE
                // To repay usdc to senior tranche so update the hedges on AAVE first
                // then remove usdc to pay back to senior tranche
                _rebalanceBorrow(state, optimalBtcBorrow, currentBtcBorrow, optimalEthBorrow, currentEthBorrow);
                uint256 totalCurrentBorrowValue;
                {
                    (uint256 currentBtc, uint256 currentEth) = _getCurrentBorrows(state);
                    totalCurrentBorrowValue = _getBorrowValue(state, currentBtc, currentEth);
                }
                _rebalanceProfit(state, totalCurrentBorrowValue);
                // Deposit to LB Vault

                state.dnGmxSeniorVault.repay(currentDnGmxSeniorVaultAmount - targetDnGmxSeniorVaultAmount);
            }
        }
    }

    ///@notice withdraws LP tokens from gauge, sells LP token for usdc
    ///@param state set of all state variables of vault
    ///@param usdcAmountDesired amount of USDC desired
    ///@return usdcAmountOut usdc amount returned by gmx
    function _convertAssetToAUsdc(
        State storage state,
        uint256 usdcAmountDesired
    ) internal returns (uint256 usdcAmountOut) {
        ///@dev if usdcAmountDesired < 10, then there is precision issue in gmx contracts while redeeming for usdg

        if (usdcAmountDesired < state.usdcConversionThreshold) return 0;
        address _usdc = address(state.usdc);

        // calculate the minimum required amount basis the set slippage param
        // uses current usdc max price from GMX and adds slippage on top

        // calculate the amount of glp to be converted to get the desired usdc amount
        uint256 glpAmountInput = usdcAmountDesired.mulDivDown(PRICE_PRECISION, _getGlpPriceInUsdc(state, false));

        if (state.useDirectConversionBurn) {
            uint256 minUsdcOut = usdcAmountDesired.mulDivDown((MAX_BPS - state.slippageThresholdGmxBps), MAX_BPS);

            usdcAmountOut = state.mintBurnRewardRouter.unstakeAndRedeemGlp(
                _usdc,
                glpAmountInput,
                minUsdcOut,
                address(this)
            );

            emit GlpSwapped(glpAmountInput, usdcAmountOut, true);

            _executeSupply(state, _usdc, usdcAmountOut);
        } else {
            uint256 ethPriceInUsdc = _getTokenPriceInUsdc(state, state.weth);

            uint256 minEthOut = (usdcAmountDesired.mulDivDown((MAX_BPS - state.slippageThresholdGmxBps), MAX_BPS))
                .mulDivDown(PRICE_PRECISION, ethPriceInUsdc);

            uint256 ethAmountOut = state.mintBurnRewardRouter.unstakeAndRedeemGlp(
                address(state.weth),
                glpAmountInput,
                minEthOut,
                address(this)
            );

            uint256 minUsdcAmount = ethPriceInUsdc.mulDivDown(
                ethAmountOut * (MAX_BPS - state.slippageThresholdSwapEthBps),
                MAX_BPS * PRICE_PRECISION
            );

            (usdcAmountOut, ) = _swapToken(state, address(state.weth), ethAmountOut, minUsdcAmount);

            emit GlpSwapped(glpAmountInput, usdcAmountOut, true);

            _executeSupply(state, _usdc, usdcAmountOut);
        }
    }

    ///@notice sells usdc for LP tokens and then stakes LP tokens
    ///@param state set of all state variables of vault
    ///@param amount amount of usdc
    function _convertAUsdcToAsset(State storage state, uint256 amount) internal {
        _executeWithdraw(state, address(state.usdc), amount, address(this));

        if (state.useDirectConversionMint) {
            uint256 price = state.gmxVault.getMinPrice(address(state.usdc));

            // USDG has 18 decimals and usdc has 6 decimals => 18-6 = 12
            uint256 usdgAmount = amount.mulDivDown(
                price * (MAX_BPS - state.slippageThresholdGmxBps) * 1e12,
                PRICE_PRECISION * MAX_BPS
            );

            // conversion of token into glp using batching manager
            // batching manager handles the conversion due to the cooldown
            // glp transferred to the vault on batch execution

            uint256 glpReceived = _stakeGlp(state, address(state.usdc), amount, usdgAmount);

            emit GlpSwapped(glpReceived, amount, false);
        } else {
            uint256 minWethOut = amount.mulDivDown(
                PRICE_PRECISION * (MAX_BPS - state.slippageThresholdSwapEthBps),
                _getTokenPriceInUsdc(state, state.weth) * MAX_BPS
            );

            (, uint256 wethReceived) = state._swapUSDC(false, address(state.weth), minWethOut, amount);

            uint256 price = state.gmxVault.getMinPrice(address(state.weth));

            // USDG has 18 decimals and weth has 18 decimals => 18-18 = 0
            uint256 usdgAmount = wethReceived.mulDivDown(
                price * (MAX_BPS - state.slippageThresholdGmxBps),
                PRICE_PRECISION * MAX_BPS
            );

            // conversion of token into glp using batching manager
            // batching manager handles the conversion due to the cooldown
            // glp transferred to the vault on batch execution

            uint256 glpReceived = _stakeGlp(state, address(state.weth), wethReceived, usdgAmount);

            emit GlpSwapped(glpReceived, amount, false);
        }
    }

    function _stakeGlp(
        State storage state,
        address token,
        uint256 amount,
        uint256 minUSDG
    ) internal returns (uint256 glpStaked) {
        // will revert if notional output is less than minUSDG
        glpStaked = state.mintBurnRewardRouter.mintAndStakeGlp(token, amount, minUSDG, 0);
    }

    ///@notice rebalances unhedged glp amount
    ///@notice converts some glp into usdc if there is lesser amount of usdc to back the hedges than required
    ///@notice converts some usdc into glp if some part of the unhedged glp can be hedged
    ///@notice used when there is not enough usdc available in senior tranche
    ///@param state set of all state variables of vault
    ///@param uncappedTokenHedge token hedge if there was no asset cap
    ///@param cappedTokenHedge token hedge if given there is limited about of assets available in senior tranche
    function _rebalanceUnhedgedGlp(State storage state, uint256 uncappedTokenHedge, uint256 cappedTokenHedge) private {
        // early return if optimal amounts are zero
        if (uncappedTokenHedge == 0) return;

        // part of glp assets to be kept unhedged
        // calculated basis the uncapped amount (assumes unlimited borrow availability)
        // and capped amount (basis available borrow)

        // uncappedTokenHedge is required to hedge totalAssets
        // cappedTokenHedge can be taken basis available borrow
        // so basis what % if hedge cannot be taken, same % of glp is converted to usdc
        uint256 targetUnhedgedGlp = _totalGlp(state, false).mulDivDown(
            uncappedTokenHedge - cappedTokenHedge,
            uncappedTokenHedge
        );

        // usdc value of unhedged glp assets
        uint256 targetUnhedgedGlpUsdcAmount = targetUnhedgedGlp.mulDivDown(
            _getGlpPriceInUsdc(state, false),
            PRICE_PRECISION
        );

        if (targetUnhedgedGlpUsdcAmount > state.unhedgedGlpInUsdc) {
            // if target unhedged amount > current unhedged amount
            // convert glp to aUSDC
            uint256 glpToUsdcAmount = targetUnhedgedGlpUsdcAmount - state.unhedgedGlpInUsdc;
            state.unhedgedGlpInUsdc += _convertAssetToAUsdc(state, glpToUsdcAmount);
        } else if (targetUnhedgedGlpUsdcAmount < state.unhedgedGlpInUsdc) {
            // if target unhedged amount < current unhedged amount
            // convert aUSDC to glp
            uint256 usdcToGlpAmount = state.unhedgedGlpInUsdc - targetUnhedgedGlpUsdcAmount;
            state.unhedgedGlpInUsdc -= usdcToGlpAmount;
            _convertAUsdcToAsset(state, usdcToGlpAmount);
        }
    }

    /* ##################################################################
                            FLASHLOAN RECEIVER
    ################################################################## */

    ///@notice flashloan receiver for balance vault
    ///@notice receives flashloaned tokens(WETH or WBTC or USDC) from balancer, swaps on uniswap and borrows/repays on AAVE
    ///@dev only allows balancer vault to call this
    ///@dev only runs when _hasFlashloaned is set to true (prevents someone else from initiating flashloan to vault)
    ///@param tokens list of tokens flashloaned
    ///@param amounts amounts of token flashloans in same order
    ///@param feeAmounts amounts of fee/premium charged for flashloan
    ///@param userData data passed to balancer for flashloan (includes token amounts, token usdc value and swap direction)
    function receiveFlashLoan(
        State storage state,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        // Decode user data containing btc/eth token & usdc amount
        // RepayDebt true means we need to reduce token hedge else we need to increase hedge
        (
            uint256 btcTokenAmount,
            uint256 btcUsdcAmount,
            uint256 ethTokenAmount,
            uint256 ethUsdcAmount,
            bool repayDebtBtc,
            bool repayDebtEth
        ) = abi.decode(userData, (uint256, uint256, uint256, uint256, bool, bool));

        // Asset premium charged for taking the flashloan from balancer
        uint256 btcAssetPremium;
        uint256 ethAssetPremium;

        // adjust asset amounts for premiums (zero for balancer at the time of dev)
        if (repayDebtBtc && repayDebtEth) {
            // Both token amounts are non zero
            // The assets are same (usdc only)
            // Here amounts[0] should be equal to btcTokenAmount+ethTokenAmount
            // Total premium on USDC is divided on a prorata basis for btc and eth usdc amounts
            btcAssetPremium = feeAmounts[0].mulDivDown(btcUsdcAmount, amounts[0]);

            ethAssetPremium = (feeAmounts[0] - btcAssetPremium);
        } else if (btcTokenAmount != 0 && ethTokenAmount != 0) {
            // Both token amounts are non zero
            // The assets are different (either usdc/btc, usdc/eth, btc/eth)
            // Here amounts[0] should be equal to btcTokenAmount and amounts[1] should be equal to ethTokenAmount
            bool btcFirst = false;

            // Checks if btc or eth is first since they are sorted basis token address when taking flashloan
            if (repayDebtBtc ? tokens[0] == state.usdc : tokens[0] == state.wbtc) btcFirst = true;

            // Premiums are assigned basis the token amount orders
            btcAssetPremium = feeAmounts[btcFirst ? 0 : 1];
            ethAssetPremium = feeAmounts[btcFirst ? 1 : 0];
        } else {
            // One of the token amounts is zero
            // The asset for non zero token can be both token or usdc
            // Premium is assigned to the non-zero amount token
            if (btcTokenAmount != 0) btcAssetPremium = feeAmounts[0];
            else ethAssetPremium = feeAmounts[0];
        }

        // Execute the token swap (usdc to token / token to usdc) and repay the debt
        if (btcTokenAmount > 0)
            _executeOperationToken(
                state,
                address(state.wbtc),
                btcTokenAmount,
                btcUsdcAmount,
                btcAssetPremium,
                repayDebtBtc
            );
        if (ethTokenAmount > 0)
            _executeOperationToken(
                state,
                address(state.weth),
                ethTokenAmount,
                ethUsdcAmount,
                ethAssetPremium,
                repayDebtEth
            );
    }

    /* ##################################################################
                            AAVE HELPERS
    ################################################################## */

    ///@notice executes borrow of "token" of "amount" quantity to AAVE at variable interest rate
    ///@param state set of all state variables of vault
    ///@param token address of token to borrow
    ///@param amount amount of token to borrow
    function _executeBorrow(State storage state, address token, uint256 amount) internal {
        state.pool.borrow(token, amount, VARIABLE_INTEREST_MODE, 0, address(this));
    }

    ///@notice executes repay of "token" of "amount" quantity to AAVE at variable interest rate
    ///@param state set of all state variables of vault
    ///@param token address of token to borrow
    ///@param amount amount of token to borrow
    function _executeRepay(State storage state, address token, uint256 amount) internal {
        state.pool.repay(token, amount, VARIABLE_INTEREST_MODE, address(this));
    }

    ///@notice executes supply of "token" of "amount" quantity to AAVE
    ///@param state set of all state variables of vault
    ///@param token address of token to borrow
    ///@param amount amount of token to borrow
    function _executeSupply(State storage state, address token, uint256 amount) internal {
        state.pool.supply(token, amount, address(this), 0);
    }

    ///@notice executes withdraw of "token" of "amount" quantity to AAVE
    ///@param state set of all state variables of vault
    ///@param token address of token to borrow
    ///@param amount amount of token to borrow
    ///@param receiver address to which withdrawn tokens should be sent
    function _executeWithdraw(State storage state, address token, uint256 amount, address receiver) internal {
        state.pool.withdraw(token, amount, receiver);
    }

    ///@notice returns liquidation threshold of the selected asset's AAVE pool
    ///@param state set of all state variables of vault
    ///@param asset address of asset to check liquidation threshold for
    function _getLiquidationThreshold(State storage state, address asset) private view returns (uint256) {
        DataTypes.ReserveConfigurationMap memory config = state.pool.getConfiguration(asset);
        (, uint256 liquidationThreshold, , , , ) = config.getParams();

        return liquidationThreshold;
    }

    /* ##################################################################
                            BALANCER HELPERS
    ################################################################## */

    ///@notice executes flashloan from balancer
    ///@dev assets should be ordered in ascending order of addresses
    ///@param assets list of token addresses
    ///@param amounts amount of tokens to be flashloaned in same order as assets
    ///@param _btcTokenAmount token amount of btc token by which hedge amount should be increased (if repayDebt false) or decreased (if repayDebt true)
    ///@param _btcUsdcAmount usdc value of btc token considering swap slippage. Minimum amount (if repayDebt false) or maximum amount (if repayDebt true)
    ///@param _ethTokenAmount token amount of eth token by which hedge amount should be increased (if repayDebt false) or decreased (if repayDebt true)
    ///@param _ethUsdcAmount usdc value of eth token considering swap slippage. Minimum amount (if repayDebt false) or maximum amount (if repayDebt true)
    ///@param _repayDebtBtc repay debt for btc token
    ///@param _repayDebtEth repay debt for eth token
    function _executeFlashloan(
        State storage state,
        address[] memory assets,
        uint256[] memory amounts,
        uint256 _btcTokenAmount,
        uint256 _btcUsdcAmount,
        uint256 _ethTokenAmount,
        uint256 _ethUsdcAmount,
        bool _repayDebtBtc,
        bool _repayDebtEth
    ) internal {
        if (assets.length != amounts.length) revert IDnGmxJuniorVault.ArraysLengthMismatch();

        // to ensure that only vault originated flashloans should be able to work with receive flashloan
        state.hasFlashloaned = true;

        state.balancerVault.flashLoan(
            address(this),
            assets,
            amounts,
            abi.encode(_btcTokenAmount, _btcUsdcAmount, _ethTokenAmount, _ethUsdcAmount, _repayDebtBtc, _repayDebtEth)
        );

        // receive flashloan has passed so the variable can be made false again
        state.hasFlashloaned = false;
    }

    ///@notice executes relevant token hedge update on receiving the flashloan from Balancer
    ///@dev if "repayDebt = true" then usdc flashloaned, swapped for token, repay token debt, withdraw usdc from AAVE and pay back usdc with premium
    ///@dev if "repayDebt = false" then token flashloaned, swapped for usdc, supply usdc, borrow tokens from AAVE and pay back tokens with premium
    ///@param token address of token to increase/decrease hedge by
    ///@param tokenAmount amount of tokens to swap
    ///@param usdcAmount if "repayDebt = false" then = minimum amount of usdc | if "repayDebt = true" then = maximum amount of usdc
    ///@param premium additional tokens/usdc to be repaid to balancer to cover flashloan fees
    ///@param repayDebt true if token hedge needs to be reduced
    function _executeOperationToken(
        State storage state,
        address token,
        uint256 tokenAmount,
        uint256 usdcAmount,
        uint256 premium,
        bool repayDebt
    ) internal {
        if (!repayDebt) {
            // increase token hedge amount
            // add premium to token amount (to be paid back to balancer)
            uint256 amountWithPremium = tokenAmount + premium;

            // swap token to usdc
            (uint256 usdcReceived, ) = state._swapToken(token, tokenAmount, usdcAmount);

            // supply received usdc to AAVE
            state._executeSupply(address(state.usdc), usdcReceived);

            // borrow amount with premium amount of tokens from AAVE
            state._executeBorrow(token, amountWithPremium);

            // increase junior tranche usdc deposits by usdc received
            state.dnUsdcDeposited += usdcReceived.toInt256();

            // transfer token amount borrowed with premium back to balancer pool
            IERC20(token).transfer(address(state.balancerVault), amountWithPremium);
        } else {
            // decrease token hedge amount
            // usdcAmount = amount flashloaned from balancer
            // usdcPaid = amount paid for receiving given token amount
            // usdcAmount-usdcPaid = amount of usdc remaining after the swap
            // so we just need to withdraw usdcPaid to transfer usdcAmount

            // swap usdc amount to token
            (uint256 usdcPaid, uint256 tokensReceived) = state._swapUSDC(true, token, tokenAmount, usdcAmount);

            // amount of usdc that got charged for the token required
            uint256 amountWithPremium = usdcPaid + premium;

            // reduce delta neutral usdc amount by amount with premium
            state.dnUsdcDeposited -= amountWithPremium.toInt256();

            // repay token debt on AAVE
            state._executeRepay(token, tokensReceived);

            // withdraw amount with premium supplied to AAVE
            state._executeWithdraw(address(state.usdc), amountWithPremium, address(this));

            // transfer usdc amount flashloaned + premium back to balancer
            state.usdc.transfer(address(state.balancerVault), usdcAmount + premium);
        }
    }

    /* ##################################################################
                            VIEW FUNCTIONS
    ################################################################## */

    ///@notice returns the usdc amount borrowed by junior tranche from senior tranche
    ///@param state set of all state variables of vault
    ///@return usdcAmount amount of usdc borrowed by junior tranche
    function _getUsdcBorrowed(State storage state) private view returns (uint256 usdcAmount) {
        // all the aave interest goes to senior tranche
        // so, usdc borrowed from senior tranche =
        // total aUSDC balance - (usdc deposited by delta neutral vault into AAVE) - (unhedged amount of glp in usdc)
        return
            uint256(
                state.aUsdc.balanceOf(address(this)).toInt256() -
                    state.dnUsdcDeposited -
                    state.unhedgedGlpInUsdc.toInt256()
            );
    }

    ///@notice returns the total assets deposited to the vault (in glp amount)
    ///@param state set of all state variables of vault
    ///@return total asset amount (glp + usdc (in glp terms))
    function totalAssets(State storage state) external view returns (uint256) {
        return _totalAssets(state, false);
    }

    ///@notice returns the total assets deposited to the vault (in glp amount)
    ///@param state set of all state variables of vault
    ///@param maximize true for maximizing the total assets value and false to minimize
    ///@return total asset amount (glp + usdc (in glp terms))
    function totalAssets(State storage state, bool maximize) external view returns (uint256) {
        return _totalAssets(state, maximize);
    }

    ///@notice returns the total assets deposited to the vault (in glp amount)
    ///@param state set of all state variables of vault
    ///@param maximize true for maximizing the total assets value and false to minimize
    ///@return total asset amount (glp + usdc (in glp terms))
    function _totalAssets(State storage state, bool maximize) private view returns (uint256) {
        // usdc deposited by junior tranche (can be negative)
        int256 dnUsdcDeposited = state.dnUsdcDeposited;

        // calculate current borrow amounts
        (uint256 currentBtc, uint256 currentEth) = _getCurrentBorrows(state);
        // total borrow value is the value of ETH and BTC required to be paid off
        uint256 totalCurrentBorrowValue = _getBorrowValue(state, currentBtc, currentEth);
        uint256 aaveProfitGlp;
        uint256 aaveLossGlp;
        {
            // convert it into two uints basis the sign
            uint256 aaveProfit = dnUsdcDeposited > int256(0) ? uint256(dnUsdcDeposited) : 0;
            uint256 aaveLoss = dnUsdcDeposited < int256(0)
                ? uint256(-dnUsdcDeposited) + totalCurrentBorrowValue
                : totalCurrentBorrowValue;

            if (aaveProfit > aaveLoss) {
                aaveProfitGlp = (aaveProfit - aaveLoss).mulDivDown(
                    PRICE_PRECISION,
                    _getGlpPriceInUsdc(state, !maximize)
                );
                if (!maximize)
                    aaveProfitGlp = aaveProfitGlp.mulDivDown(MAX_BPS - state.slippageThresholdGmxBps, MAX_BPS);
                aaveLossGlp = 0;
            } else {
                aaveLossGlp = (aaveLoss - aaveProfit).mulDivDown(PRICE_PRECISION, _getGlpPriceInUsdc(state, maximize));
                if (!maximize) aaveLossGlp = aaveLossGlp.mulDivDown(MAX_BPS + state.slippageThresholdGmxBps, MAX_BPS);
                aaveProfitGlp = 0;
            }
        }

        // total assets considers 3 parts
        // part1: glp balance in vault
        // part2: usdc balance in vault (unhedged glp)
        // part3: pnl on AAVE (i.e. aaveProfitGlp - aaveLossGlp)
        return _totalGlp(state, maximize) + aaveProfitGlp - aaveLossGlp;
    }

    ///@notice returns the total assets deposited to the vault (in glp amount)
    ///@param state set of all state variables of vault
    ///@param maximize true for maximizing the total assets value and false to minimize
    ///@return total asset amount (glp + usdc (in glp terms))
    function totalGlp(State storage state, bool maximize) external view returns (uint256) {
        return _totalGlp(state, maximize);
    }

    function _totalGlp(State storage state, bool maximize) private view returns (uint256) {
        // convert usdc amount into glp amount
        // unhedged glp is kept in usdc so there would be conversion slippage on that
        uint256 unhedgedGlp = (state.unhedgedGlpInUsdc).mulDivDown(
            PRICE_PRECISION,
            _getGlpPriceInUsdc(state, !maximize)
        );

        // if we need to minimize then add additional slippage
        if (!maximize) unhedgedGlp = unhedgedGlp.mulDivDown(MAX_BPS - state.slippageThresholdGmxBps, MAX_BPS);

        // total assets considers 3 parts
        // part1: glp balance in vault
        // part2: usdc balance in vault (unhedged glp)
        return state.fsGlp.balanceOf(address(this)) + unhedgedGlp;
    }

    ///@notice returns if the rebalance is valid basis last rebalance time and rebalanceTimeThreshold
    ///@param state set of all state variables of vault
    ///@return true if the rebalance is valid basis time threshold
    /* solhint-disable not-rely-on-time */
    function isValidRebalanceTime(State storage state) external view returns (bool) {
        // check if rebalanceTimeThreshold has passed since last rebalance time
        return (block.timestamp - state.lastRebalanceTS) > state.rebalanceTimeThreshold;
    }

    ///@notice returns if the rebalance is valid basis health factor on AAVE
    ///@notice returns true if current health factor < threshold
    ///@param state set of all state variables of vault
    ///@return true if the rebalance is valid basis AAVE health factor
    function isValidRebalanceHF(State storage state) external view returns (bool) {
        return _isValidRebalanceHF(state);
    }

    function _isValidRebalanceHF(State storage state) private view returns (bool) {
        // check if health factor on AAVE is below rebalanceHfThreshold
        (, , , , , uint256 healthFactor) = state.pool.getUserAccountData(address(this));

        return healthFactor < (uint256(state.rebalanceHfThresholdBps) * 1e14);
    }

    ///@notice returns if the rebalance is valid basis the difference between the current and optimal hedges of tokens(ETH/BTC)
    ///@param state set of all state variables of vault
    ///@return true if the rebalance is valid basis diffeence (current and optimal) threshold
    function isValidRebalanceDeviation(State storage state) external view returns (bool) {
        (uint128 optimalBtcPoolAmount, uint128 optimalEthPoolAmount) = _getPoolAmounts(state);

        uint128 currentBtcPoolAmount = state.btcPoolAmount;
        uint128 currentEthPoolAmount = state.ethPoolAmount;

        return
            !(_isWithinAllowedDelta(state, optimalBtcPoolAmount, currentBtcPoolAmount) &&
                _isWithinAllowedDelta(state, optimalEthPoolAmount, currentEthPoolAmount));
    }

    function isValidRebalanceDueToChangeInHedges(State storage state) external view returns (bool) {
        return _isValidRebalanceDueToChangeInHedges(state);
    }

    function _isValidRebalanceDueToChangeInHedges(State storage state) private view returns (bool) {
        (int128 currentBtcTraderOIHedge, int128 currentEthTraderOIHedge) = _getTraderOIHedgeAmounts(state);
        return
            !(currentBtcTraderOIHedge == state.btcTraderOIHedge && currentEthTraderOIHedge == state.ethTraderOIHedge);
    }

    function getTraderOIHedgeAmounts(
        State storage state
    ) external view returns (int128 currentBtcTraderOIHedge, int128 currentEthTraderOIHedge) {
        return _getTraderOIHedgeAmounts(state);
    }

    function _getTraderOIHedgeAmounts(
        State storage state
    ) private view returns (int128 currentBtcTraderOIHedge, int128 currentEthTraderOIHedge) {
        currentBtcTraderOIHedge = state.dnGmxTraderHedgeStrategy.btcTraderOIHedge();
        currentEthTraderOIHedge = state.dnGmxTraderHedgeStrategy.ethTraderOIHedge();
    }

    function getPoolAmounts(State storage state) external view returns (uint128 btcPoolAmount, uint128 ethPoolAmount) {
        return _getPoolAmounts(state);
    }

    function _getPoolAmounts(State storage state) private view returns (uint128 btcPoolAmount, uint128 ethPoolAmount) {
        btcPoolAmount = uint128(state.gmxVault.poolAmounts(address(state.wbtc)));
        ethPoolAmount = uint128(state.gmxVault.poolAmounts(address(state.weth)));
    }

    ///@notice returns the price of given token basis AAVE oracle
    ///@param state set of all state variables of vault
    ///@param token the token for which price is expected
    ///@return token price in usd
    function getTokenPrice(State storage state, IERC20Metadata token) external view returns (uint256) {
        return _getTokenPrice(state, token);
    }

    ///@notice returns the price of given token basis AAVE oracle
    ///@param state set of all state variables of vault
    ///@param token the token for which price is expected
    ///@return token price in usd
    function _getTokenPrice(State storage state, IERC20Metadata token) private view returns (uint256) {
        uint256 decimals = token.decimals();

        // AAVE oracle
        uint256 price = state.oracle.getAssetPrice(address(token));

        // @dev aave returns from same source as chainlink (which is 8 decimals)
        return price.mulDivDown(PRICE_PRECISION, 10 ** (decimals + 2));
    }

    ///@notice returns the price of glp token
    ///@param state set of all state variables of vault
    ///@param maximize true to get maximum price and false to get minimum
    ///@return glp price in usd
    function getGlpPrice(State storage state, bool maximize) external view returns (uint256) {
        return _getGlpPrice(state, maximize);
    }

    ///@notice returns the price of glp token
    ///@param state set of all state variables of vault
    ///@param maximize true to get maximum price and false to get minimum
    ///@return glp price in usd
    function _getGlpPrice(State storage state, bool maximize) private view returns (uint256) {
        uint256 aum = state.glpManager.getAum(maximize);
        uint256 totalSupply = state.glp.totalSupply();

        // price per glp token = (total AUM / total supply)
        return aum.mulDivDown(PRICE_PRECISION, totalSupply * 1e24);
    }

    ///@notice returns the price of glp token in usdc
    ///@param state set of all state variables of vault
    ///@param maximize true to get maximum price and false to get minimum
    ///@return glp price in usdc
    function getGlpPriceInUsdc(State storage state, bool maximize) external view returns (uint256) {
        return _getGlpPriceInUsdc(state, maximize);
    }

    ///@notice returns the price of glp token in usdc
    ///@param state set of all state variables of vault
    ///@param maximize true to get maximum price and false to get minimum
    ///@return glp price in usdc
    function _getGlpPriceInUsdc(State storage state, bool maximize) private view returns (uint256) {
        uint256 aum = state.glpManager.getAum(maximize);
        uint256 totalSupply = state.glp.totalSupply();

        // @dev aave returns from same source as chainlink (which is 8 decimals)
        uint256 quotePrice = state.oracle.getAssetPrice(address(state.usdc));

        // price per glp token = (total AUM / total supply)
        // scaling factor = 30(aum) -18(totalSupply) -8(quotePrice) +18(glp) -6(usdc) = 16
        return aum.mulDivDown(PRICE_PRECISION, totalSupply * quotePrice * 1e16);
    }

    ///@notice returns the price of given token in USDC using AAVE oracle
    ///@param state set of all state variables of vault
    ///@param token the token for which price is expected
    ///@return scaledPrice token price in usdc
    function getTokenPriceInUsdc(
        State storage state,
        IERC20Metadata token
    ) external view returns (uint256 scaledPrice) {
        return _getTokenPriceInUsdc(state, token);
    }

    ///@notice returns the price of given token in USDC using AAVE oracle
    ///@param state set of all state variables of vault
    ///@param token the token for which price is expected
    ///@return scaledPrice token price in usdc
    function _getTokenPriceInUsdc(
        State storage state,
        IERC20Metadata token
    ) internal view returns (uint256 scaledPrice) {
        uint256 decimals = token.decimals();
        uint256 price = state.oracle.getAssetPrice(address(token));

        // @dev aave returns from same source as chainlink (which is 8 decimals)
        uint256 quotePrice = state.oracle.getAssetPrice(address(state.usdc));

        // token price / usdc price
        scaledPrice = price.mulDivDown(PRICE_PRECISION, quotePrice * 10 ** (decimals - 6));
    }

    ///@notice returns liquidation threshold of the selected asset's AAVE pool
    ///@param state set of all state variables of vault
    ///@param asset address of asset to check liquidation threshold for
    ///@return liquidation threshold
    function getLiquidationThreshold(State storage state, address asset) external view returns (uint256) {
        return _getLiquidationThreshold(state, asset);
    }

    ///@notice returns the borrow value for a given amount of tokens
    ///@param state set of all state variables of vault
    ///@param btcAmount amount of btc
    ///@param ethAmount amount of eth
    ///@return borrowValue value of the given token amounts
    function getBorrowValue(
        State storage state,
        uint256 btcAmount,
        uint256 ethAmount
    ) external view returns (uint256 borrowValue) {
        return _getBorrowValue(state, btcAmount, ethAmount);
    }

    ///@notice returns the borrow value for a given amount of tokens
    ///@param state set of all state variables of vault
    ///@param btcAmount amount of btc
    ///@param ethAmount amount of eth
    ///@return borrowValue value of the given token amounts
    function _getBorrowValue(
        State storage state,
        uint256 btcAmount,
        uint256 ethAmount
    ) private view returns (uint256 borrowValue) {
        borrowValue =
            btcAmount.mulDivDown(_getTokenPrice(state, state.wbtc), PRICE_PRECISION) +
            ethAmount.mulDivDown(_getTokenPrice(state, state.weth), PRICE_PRECISION);
        borrowValue = borrowValue.mulDivDown(PRICE_PRECISION, _getTokenPrice(state, state.usdc));
    }

    function getSlippageAdjustedAssets(
        State storage state,
        uint256 assets,
        bool isDeposit
    ) external view returns (uint256) {
        return _getSlippageAdjustedAssets(state, assets, isDeposit);
    }

    function _getSlippageAdjustedAssets(
        State storage state,
        uint256 assets,
        bool isDeposit
    ) private view returns (uint256) {
        // get change in borrow positions to calculate amount to swap on uniswap
        (int256 netBtcBorrowChange, int256 netEthBorrowChange) = _getNetPositionChange(state, assets, isDeposit);

        uint256 dollarsLostDueToSlippage = _quoteSwapSlippageLoss(state, netBtcBorrowChange, netEthBorrowChange);

        // netSlippage returned is in glp (asset) terms
        uint256 glpPrice = _getGlpPriceInUsdc(state, false);
        uint256 netSlippage = dollarsLostDueToSlippage.mulDivUp(PRICE_PRECISION, glpPrice);

        // subtract slippage from assets, and calculate shares basis that slippage adjusted asset amount
        if (netSlippage >= assets) revert IDnGmxJuniorVault.TooMuchSlippage(netSlippage, assets);
        assets -= netSlippage;

        return assets;
    }

    function getNetPositionChange(
        State storage state,
        uint256 assetAmount,
        bool isDeposit
    ) external view returns (int256, int256) {
        return _getNetPositionChange(state, assetAmount, isDeposit);
    }

    function _getNetPositionChange(
        State storage state,
        uint256 assetAmount,
        bool isDeposit
    ) private view returns (int256 netBtcBorrowChange, int256 netEthBorrowChange) {
        // get current borrows
        (uint256 currentBtcBorrow, uint256 currentEthBorrow) = _getCurrentBorrows(state);

        // calculate new total assets basis assetAmount
        uint256 total = _totalGlp(state, true);
        uint256 totalAssetsAfter = isDeposit ? total + assetAmount : total - assetAmount;

        // get optimal borrows accounting for incoming glp deposit
        (uint256 optimalBtcBorrow, uint256 optimalEthBorrow, , , ) = _getOptimalBorrowsFinal(
            state,
            currentBtcBorrow,
            currentEthBorrow,
            totalAssetsAfter,
            [false, false]
        );

        // calculate the diff, i.e token amounts to be swapped on uniswap
        // if optimal > current, swapping token to usdc
        // if optimal < current, swapping usdc to token
        netBtcBorrowChange = optimalBtcBorrow.toInt256() - currentBtcBorrow.toInt256();
        netEthBorrowChange = optimalEthBorrow.toInt256() - currentEthBorrow.toInt256();
    }

    function quoteSwapSlippageLoss(
        State storage state,
        int256 btcAmount,
        int256 ethAmount
    ) external view returns (uint256) {
        return _quoteSwapSlippageLoss(state, btcAmount, ethAmount);
    }

    function _calculateSwapLoss(
        int256 tokenAmount,
        int256 otherTokenAmount,
        uint256 tokenPrice,
        uint256 otherTokenPrice
    ) internal pure returns (uint256) {
        uint256 dollarsPaid;
        uint256 dollarsReceived;
        if (tokenAmount > 0) {
            dollarsPaid = uint256(tokenAmount).mulDivUp(tokenPrice, PRICE_PRECISION);
            dollarsReceived = uint256(-otherTokenAmount).mulDivDown(otherTokenPrice, PRICE_PRECISION);
        } else if (tokenAmount < 0) {
            dollarsPaid = uint256(otherTokenAmount).mulDivUp(otherTokenPrice, PRICE_PRECISION);
            dollarsReceived = uint256(-tokenAmount).mulDivDown(tokenPrice, PRICE_PRECISION);
        }
        return (dollarsPaid > dollarsReceived) ? uint256(dollarsPaid - dollarsReceived) : 0;
    }

    /// @notice returns the amount of glp to be charged as slippage loss
    /// @param state set of all state variables of vault
    /// @param btcAmountInBtcSwap if positive btc sell amount else if negative btc buy amount
    /// @param ethAmountInEthSwap if positive eth sell amount else if negative eth buy amount
    function _quoteSwapSlippageLoss(
        State storage state,
        int256 btcAmountInBtcSwap,
        int256 ethAmountInEthSwap
    ) internal view returns (uint256 dollarsLostDueToSlippage) {
        (int256 usdcAmountInBtcSwap, int256 usdcAmountInEthSwap) = QuoterLib.quoteCombinedSwap(
            btcAmountInBtcSwap,
            ethAmountInEthSwap,
            SwapPath.generate({
                tokenIn: state.wbtc,
                feeIn: state.feeTierWethWbtcPool,
                tokenIntermediate: state.weth,
                feeOut: 500,
                tokenOut: state.usdc,
                isExactIn: true
            }),
            SwapPath.generate({ tokenIn: state.weth, fee: 500, tokenOut: state.usdc, isExactIn: true })
        );

        uint256 btcPrice = _getTokenPriceInUsdc(state, state.wbtc);
        uint256 ethPrice = _getTokenPriceInUsdc(state, state.weth);
        uint256 usdcPrice = _getTokenPriceInUsdc(state, state.usdc);

        return
            _calculateSwapLoss(btcAmountInBtcSwap, usdcAmountInBtcSwap, btcPrice, usdcPrice) +
            _calculateSwapLoss(ethAmountInEthSwap, usdcAmountInEthSwap, ethPrice, usdcPrice);
    }

    ///@notice returns the amount of flashloan for a given token
    ///@notice if token amount needs to be increased then usdcAmount is minimum amount
    ///@notice if token amount needs to be decreased then usdcAmount is maximum amount
    ///@param state set of all state variables of vault
    ///@param token address of token
    ///@param optimalBorrow optimal token borrow to completely hedge sGlp
    ///@param currentBorrow curret token borrow from AAVE
    ///@return tokenAmount amount of tokens to be swapped
    ///@return usdcAmount minimum/maximum amount of usdc basis swap direction
    ///@return repayDebt true then reduce token hedge, false then increase token hedge
    function flashloanAmounts(
        State storage state,
        address token,
        uint256 optimalBorrow,
        uint256 currentBorrow
    ) external view returns (uint256 tokenAmount, uint256 usdcAmount, bool repayDebt) {
        return _flashloanAmounts(state, token, optimalBorrow, currentBorrow);
    }

    ///@notice returns the amount of flashloan for a given token
    ///@notice if token amount needs to be increased then usdcAmount is minimum amount
    ///@notice if token amount needs to be decreased then usdcAmount is maximum amount
    ///@param state set of all state variables of vault
    ///@param token address of token
    ///@param optimalBorrow optimal token borrow to completely hedge sGlp
    ///@param currentBorrow curret token borrow from AAVE
    ///@return tokenAmount amount of tokens to be swapped
    ///@return usdcAmount minimum/maximum amount of usdc basis swap direction
    ///@return repayDebt true then reduce token hedge, false then increase token hedge
    function _flashloanAmounts(
        State storage state,
        address token,
        uint256 optimalBorrow,
        uint256 currentBorrow
    ) private view returns (uint256 tokenAmount, uint256 usdcAmount, bool repayDebt) {
        uint256 slippageThresholdSwap = token == address(state.wbtc)
            ? state.slippageThresholdSwapBtcBps
            : state.slippageThresholdSwapEthBps;
        // check the delta between optimal position and actual position in token terms
        // take that position using swap
        // To Increase
        if (optimalBorrow > currentBorrow) {
            tokenAmount = optimalBorrow - currentBorrow;
            // To swap with the amount in specified hence usdcAmount should be the min amount out
            usdcAmount = _getTokenPriceInUsdc(state, IERC20Metadata(token)).mulDivDown(
                tokenAmount * (MAX_BPS - slippageThresholdSwap),
                MAX_BPS * PRICE_PRECISION
            );

            repayDebt = false;
            // Flash loan ETH/BTC from AAVE
            // In callback: Sell loan for USDC and repay debt
        } else {
            // To Decrease
            tokenAmount = (currentBorrow - optimalBorrow);
            // To swap with amount out specified hence usdcAmount should be the max amount in
            usdcAmount = _getTokenPriceInUsdc(state, IERC20Metadata(token)).mulDivDown(
                tokenAmount * (MAX_BPS + slippageThresholdSwap),
                MAX_BPS * PRICE_PRECISION
            );

            repayDebt = true;
            // In callback: Swap to ETH/BTC and deposit to AAVE
            // Send back some aUSDC to LB vault
        }
    }

    ///@notice returns the amount of current borrows of btc and eth token from AAVE
    ///@param state set of all state variables of vault
    ///@return currentBtcBorrow amount of btc currently borrowed from AAVE
    ///@return currentEthBorrow amount of eth currently borrowed from AAVE
    function getCurrentBorrows(
        State storage state
    ) external view returns (uint256 currentBtcBorrow, uint256 currentEthBorrow) {
        return _getCurrentBorrows(state);
    }

    ///@notice returns the amount of current borrows of btc and eth token from AAVE
    ///@param state set of all state variables of vault
    ///@return currentBtcBorrow amount of btc currently borrowed from AAVE
    ///@return currentEthBorrow amount of eth currently borrowed from AAVE
    function _getCurrentBorrows(
        State storage state
    ) private view returns (uint256 currentBtcBorrow, uint256 currentEthBorrow) {
        return (state.vWbtc.balanceOf(address(this)), state.vWeth.balanceOf(address(this)));
    }

    ///@notice returns optimal borrows for BTC and ETH respectively basis glpDeposited amount and stored pool amount
    ///@param state set of all state variables of vault
    ///@param glpDeposited amount of glp for which optimal borrow needs to be calculated
    ///@return optimalBtcBorrow optimal amount of btc borrowed from AAVE
    ///@return optimalEthBorrow optimal amount of eth borrowed from AAVE
    function getOptimalBorrows(
        State storage state,
        uint256 glpDeposited,
        bool withUpdatedPoolAmounts
    ) external view returns (uint256 optimalBtcBorrow, uint256 optimalEthBorrow) {
        return _getOptimalBorrows(state, glpDeposited, withUpdatedPoolAmounts);
    }

    ///@notice returns optimal borrows for BTC and ETH respectively basis glpDeposited amount and stored pool amount
    ///@param state set of all state variables of vault
    ///@param glpDeposited amount of glp for which optimal borrow needs to be calculated
    ///@return optimalBtcBorrow optimal amount of btc borrowed from AAVE
    ///@return optimalEthBorrow optimal amount of eth borrowed from AAVE
    function _getOptimalBorrows(
        State storage state,
        uint256 glpDeposited,
        bool withUpdatedPoolAmounts
    ) private view returns (uint256 optimalBtcBorrow, uint256 optimalEthBorrow) {
        // optimalBtcBorrow = _getTokenReservesInGlp(state, address(state.wbtc), glpDeposited, withUpdatedPoolAmounts);
        // optimalEthBorrow = _getTokenReservesInGlp(state, address(state.weth), glpDeposited, withUpdatedPoolAmounts);

        optimalBtcBorrow = 0;
        optimalEthBorrow = 0;
    }

    ///@notice returns optimal borrows for BTC and ETH respectively basis available borrow amount
    ///@param state set of all state variables of vault
    ///@param availableBorrowAmount available borrow amount from senior vault
    ///@param usdcLiquidationThreshold the usdc liquidation threshold on AAVE
    ///@return optimalBtcBorrow optimal amount of btc borrowed from AAVE
    ///@return optimalEthBorrow optimal amount of eth borrowed from AAVE
    function getOptimalCappedBorrows(
        State storage state,
        uint256 availableBorrowAmount,
        uint256 usdcLiquidationThreshold
    ) external view returns (uint256 optimalBtcBorrow, uint256 optimalEthBorrow) {
        return _getOptimalCappedBorrows(state, availableBorrowAmount, usdcLiquidationThreshold);
    }

    ///@notice returns optimal borrows for BTC and ETH respectively basis available borrow amount
    ///@param state set of all state variables of vault
    ///@param availableBorrowAmount available borrow amount from senior vault
    ///@param usdcLiquidationThreshold the usdc liquidation threshold on AAVE
    ///@return optimalBtcBorrow optimal amount of btc borrowed from AAVE
    ///@return optimalEthBorrow optimal amount of eth borrowed from AAVE
    function _getOptimalCappedBorrows(
        State storage state,
        uint256 availableBorrowAmount,
        uint256 usdcLiquidationThreshold
    ) private view returns (uint256 optimalBtcBorrow, uint256 optimalEthBorrow) {
        // The value of max possible value of ETH+BTC borrow
        // calculated basis available borrow amount, liqudation threshold and target health factor
        // AAVE target health factor = (usdc supply value * usdc liquidation threshold)/borrow value
        // whatever tokens we borrow from AAVE (ETH/BTC) we sell for usdc and deposit that usdc into AAVE
        // assuming 0 slippage borrow value of tokens = usdc deposit value (this leads to very small variation in hf)
        // usdc supply value = usdc borrowed from senior tranche + borrow value
        // replacing usdc supply value formula above in AAVE target health factor formula
        // we can replace usdc borrowed from senior tranche with available borrow amount
        // we can derive max borrow value of tokens possible i.e. maxBorrowValue
        uint256 maxBorrowValue = availableBorrowAmount.mulDivDown(
            usdcLiquidationThreshold,
            state.targetHealthFactor - usdcLiquidationThreshold
        );

        uint256 btcWeight;
        uint256 ethWeight;

        // get eth and btc price in usdc
        uint256 btcPrice = _getTokenPriceInUsdc(state, state.wbtc);
        uint256 ethPrice = _getTokenPriceInUsdc(state, state.weth);

        {
            int128 btcTokenTraderOIHedge = state.btcTraderOIHedge;
            int128 ethTokenTraderOIHedge = state.ethTraderOIHedge;

            uint256 btcPoolAmount = state.btcPoolAmount;
            uint256 ethPoolAmount = state.ethPoolAmount;

            // token reserve is the amount we short
            // tokenTraderOIHedge if >0 then we need to go long because of OI hence less short (i.e. subtract if value +ve)
            // tokenTraderOIHedge if <0 then we need to go short because of OI hence more long (i.e. add if value -ve)
            uint256 btcTokenReserve = btcTokenTraderOIHedge > 0
                ? btcPoolAmount - uint256(int256(btcTokenTraderOIHedge))
                : btcPoolAmount + uint256(int256(-btcTokenTraderOIHedge));

            uint256 ethTokenReserve = ethTokenTraderOIHedge > 0
                ? ethPoolAmount - uint256(int256(ethTokenTraderOIHedge))
                : ethPoolAmount + uint256(int256(-ethTokenTraderOIHedge));

            // calculate the borrow value of eth & btc using their weights
            btcWeight = btcTokenReserve.mulDivDown(btcPrice, PRICE_PRECISION);
            ethWeight = ethTokenReserve.mulDivDown(ethPrice, PRICE_PRECISION);
        }

        // get token amounts from usdc amount
        // total borrow should be divided basis the token weights
        // using that we can calculate the borrow value for each token
        // dividing that with token prices we can calculate the optimal token borrow amounts
        optimalBtcBorrow = maxBorrowValue.mulDivDown(btcWeight * PRICE_PRECISION, (btcWeight + ethWeight) * btcPrice);
        optimalEthBorrow = maxBorrowValue.mulDivDown(ethWeight * PRICE_PRECISION, (btcWeight + ethWeight) * ethPrice);
    }

    ///@notice returns token amount underlying glp amount deposited and stored pool amount
    ///@param state set of all state variables of vault
    ///@param token address of token
    ///@param glpDeposited amount of glp for which underlying token amount is being calculated
    ///@return amount of tokens of the supplied address underlying the given amount of glp
    function getTokenReservesInGlp(
        State storage state,
        address token,
        uint256 glpDeposited,
        bool withUpdatedPoolAmounts
    ) external view returns (uint256) {
        return _getTokenReservesInGlp(state, token, glpDeposited, withUpdatedPoolAmounts);
    }

    ///@notice returns token amount underlying glp amount deposited and stored pool amount
    ///@param state set of all state variables of vault
    ///@param token address of token
    ///@param glpDeposited amount of glp for which underlying token amount is being calculated
    ///@return amount of tokens of the supplied address underlying the given amount of glp
    function _getTokenReservesInGlp(
        State storage state,
        address token,
        uint256 glpDeposited,
        bool withUpdatedPoolAmounts
    ) private view returns (uint256) {
        uint256 poolAmount = withUpdatedPoolAmounts
            ? state.gmxVault.poolAmounts(token)
            : (token == address(state.wbtc) ? state.btcPoolAmount : state.ethPoolAmount);

        uint256 totalSupply = state.glp.totalSupply();

        int128 tokenTraderOIHedge = token == address(state.wbtc) ? state.btcTraderOIHedge : state.ethTraderOIHedge;

        // token reserve is the amount we short
        // tokenTraderOIHedge if >0 then we need to go long because of OI hence less short (i.e. subtract if value +ve)
        // tokenTraderOIHedge if <0 then we need to go short because of OI hence more long (i.e. add if value -ve)
        uint256 tokenReserve = tokenTraderOIHedge > 0
            ? poolAmount - uint256(int256(tokenTraderOIHedge))
            : poolAmount + uint256(int256(-tokenTraderOIHedge));

        return tokenReserve.mulDivDown(glpDeposited, totalSupply);
    }

    ///@notice returns token amount underlying glp amount deposited
    ///@param state set of all state variables of vault
    ///@param optimalBorrow optimal borrow amount basis glp deposits
    ///@param currentBorrow current borrow amount from AAVE
    ///@return true if the difference is below allowed threshold else false
    function isWithinAllowedDelta(
        State storage state,
        uint256 optimalBorrow,
        uint256 currentBorrow
    ) external view returns (bool) {
        return _isWithinAllowedDelta(state, optimalBorrow, currentBorrow);
    }

    ///@notice returns token amount underlying glp amount deposited
    ///@param state set of all state variables of vault
    ///@param optimalBorrow optimal borrow amount basis glp deposits
    ///@param currentBorrow current borrow amount from AAVE
    ///@return true if the difference is below allowed threshold else false
    function _isWithinAllowedDelta(
        State storage state,
        uint256 optimalBorrow,
        uint256 currentBorrow
    ) private view returns (bool) {
        // calcualte the absolute difference between the optimal and current borrows
        // optimal borrow is what we should borrow from AAVE
        // curret borrow is what is already borrowed from AAVE
        uint256 diff = optimalBorrow > currentBorrow ? optimalBorrow - currentBorrow : currentBorrow - optimalBorrow;

        // if absolute diff < threshold return true
        // if absolute diff > threshold return false
        return diff <= uint256(state.rebalanceDeltaThresholdBps).mulDivDown(currentBorrow, MAX_BPS);
    }

    // ISwapRouter internal constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    ///@notice swaps token into usdc
    ///@param state set of all state variables of vault
    ///@param token address of token
    ///@param tokenAmount token amount to be sold
    ///@param minUsdcAmount minimum amount of usdc required
    ///@return usdcReceived amount of usdc received on swap
    ///@return tokensUsed amount of tokens paid for swap
    function _swapToken(
        State storage state,
        address token,
        uint256 tokenAmount,
        uint256 minUsdcAmount
    ) internal returns (uint256 usdcReceived, uint256 tokensUsed) {
        ISwapRouter swapRouter = state.swapRouter;

        // path of the token swap
        bytes memory path = token == address(state.weth)
            ? SwapPath.generate({ tokenIn: state.weth, fee: 500, tokenOut: state.usdc, isExactIn: true })
            : SwapPath.generate({
                tokenIn: state.wbtc,
                feeIn: state.feeTierWethWbtcPool,
                tokenIntermediate: state.weth,
                feeOut: 500,
                tokenOut: state.usdc,
                isExactIn: true
            });

        // executes the swap on uniswap pool
        // exact input swap to convert exact amount of tokens into usdc
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: tokenAmount,
            amountOutMinimum: minUsdcAmount
        });

        // since exact input swap tokens used = token amount passed
        tokensUsed = tokenAmount;
        usdcReceived = swapRouter.exactInput(params);

        emit TokenSwapped(token, address(state.usdc), tokenAmount, usdcReceived);
    }

    ///@notice swaps usdc into token
    ///@param state set of all state variables of vault
    ///@param isExactOut whether swap is exactOut
    ///@param token address of token
    ///@param tokenAmount token amount to be bought
    ///@param usdcAmount maximum amount of usdc that can be sold
    ///@return usdcPaid amount of usdc paid for swap
    ///@return tokensReceived amount of tokens received on swap
    function _swapUSDC(
        State storage state,
        bool isExactOut,
        address token,
        uint256 tokenAmount,
        uint256 usdcAmount
    ) internal returns (uint256 usdcPaid, uint256 tokensReceived) {
        ISwapRouter swapRouter = state.swapRouter;

        bytes memory path = token == address(state.weth)
            ? SwapPath.generate({ tokenIn: state.usdc, fee: 500, tokenOut: state.weth, isExactIn: !isExactOut })
            : SwapPath.generate({
                tokenIn: state.usdc,
                feeIn: 500,
                tokenIntermediate: state.weth,
                feeOut: state.feeTierWethWbtcPool,
                tokenOut: state.wbtc,
                isExactIn: !isExactOut
            });

        if (isExactOut) {
            ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: tokenAmount,
                amountInMaximum: usdcAmount
            });

            // since exact output swap tokensReceived = tokenAmount passed
            tokensReceived = tokenAmount;
            usdcPaid = swapRouter.exactOutput(params);

            emit TokenSwapped(address(state.usdc), token, usdcPaid, tokensReceived);
        } else {
            // executes the swap on uniswap pool
            // exact input swap to convert exact amount of tokens into usdc
            ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: usdcAmount,
                amountOutMinimum: tokenAmount
            });

            tokensReceived = swapRouter.exactInput(params);
            usdcPaid = usdcAmount;

            emit TokenSwapped(address(state.usdc), token, usdcPaid, tokensReceived);
        }
    }

    function emitVaultState(State storage state, uint256 eventType) external {
        (uint256 currentBtc, uint256 currentEth) = _getCurrentBorrows(state);

        uint256 ts = state.glp.totalSupply();
        uint256 bal = state.fsGlp.balanceOf(address(this));

        emit VaultState(
            eventType,
            currentBtc,
            currentEth,
            (state.btcPoolAmount * bal) / ts,
            (state.ethPoolAmount * bal) / ts,
            (state.btcTraderOIHedge * bal.toInt256()) / ts.toInt256(),
            (state.ethTraderOIHedge * bal.toInt256()) / ts.toInt256(),
            _getGlpPriceInUsdc(state, false),
            bal,
            _totalAssets(state, false),
            state.dnUsdcDeposited,
            state.unhedgedGlpInUsdc,
            state.aUsdc.balanceOf(address(this)),
            state.aUsdc.balanceOf(address(state.dnGmxSeniorVault))
        );
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity >=0.8.0;

import { FullMath } from '@uniswap/v3-core/contracts/libraries/FullMath.sol';

/**
 * @title FeeSplitStrategy library
 * @notice Implements the calculation of the eth reward split depending on the utilization of reserve
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * @author adapted from https://github.com/aave/protocol-v2/blob/6f57232358af0fd41d9dcf9309d7a8c0b9aa3912/contracts/protocol/lendingpool/DefaultReserveInterestRateStrategy.sol
 **/

library FeeSplitStrategy {
    using FullMath for uint128;
    using FullMath for uint256;

    uint256 internal constant RATE_PRECISION = 1e30;

    struct Info {
        /**
         * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
         * Expressed in ray
         **/
        uint128 optimalUtilizationRate;
        // Base variable borrow rate when Utilization rate = 0. Expressed in ray
        uint128 baseVariableBorrowRate;
        // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint128 variableRateSlope1;
        // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint128 variableRateSlope2;
    }

    function getMaxVariableBorrowRate(Info storage feeStrategyInfo) internal view returns (uint256) {
        return
            feeStrategyInfo.baseVariableBorrowRate +
            feeStrategyInfo.variableRateSlope1 +
            feeStrategyInfo.variableRateSlope2;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
     * New protocol implementation uses the new calculateInterestRates() interface
     * @param availableLiquidity The liquidity available in the corresponding aToken
     * @param usedLiquidity The total borrowed from the reserve at a variable rate
     **/
    function calculateFeeSplit(
        Info storage feeStrategy,
        uint256 availableLiquidity,
        uint256 usedLiquidity
    ) internal view returns (uint256 feeSplitRate) {
        uint256 utilizationRate = usedLiquidity == 0
            ? 0
            : usedLiquidity.mulDiv(RATE_PRECISION, availableLiquidity + usedLiquidity);

        uint256 excessUtilizationRate = RATE_PRECISION - feeStrategy.optimalUtilizationRate;

        if (utilizationRate > feeStrategy.optimalUtilizationRate) {
            uint256 excessUtilizationRateRatio = (utilizationRate - feeStrategy.optimalUtilizationRate).mulDiv(
                RATE_PRECISION,
                excessUtilizationRate
            );

            feeSplitRate =
                feeStrategy.baseVariableBorrowRate +
                feeStrategy.variableRateSlope1 +
                feeStrategy.variableRateSlope2.mulDiv(excessUtilizationRateRatio, RATE_PRECISION);
        } else {
            feeSplitRate =
                feeStrategy.baseVariableBorrowRate +
                utilizationRate.mulDiv(feeStrategy.variableRateSlope1, feeStrategy.optimalUtilizationRate);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import { TickMath } from '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import { IUniswapV3SwapCallback } from '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

import { Path } from '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import { PoolAddress } from '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import { CallbackValidation } from '@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol';

import { Simulate } from './Simulate.sol';

/// @title Provides quotes for swaps
/// @notice Allows getting the expected amount out or amount in for a given swap without executing the swap
/// @dev These functions are not gas efficient and should _not_ be called on chain. Instead, optimistically execute
/// the swap and check the amounts in the callback.
library QuoterLib {
    using Path for bytes;
    using SafeCast for uint256;
    using Simulate for IUniswapV3Pool;

    address constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    function _getPool(address tokenA, address tokenB, uint24 fee) internal pure returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    function _decodeFirstPool(
        bytes memory path,
        bool exactIn
    ) internal pure returns (IUniswapV3Pool pool, bool zeroForOne) {
        (address tokenA, address tokenB, uint24 fee) = path.decodeFirstPool();
        pool = _getPool(tokenA, tokenB, fee);
        zeroForOne = exactIn == (tokenA < tokenB);
    }

    function _quoteExactInputSingle(
        IUniswapV3Pool pool,
        bool zeroForOne,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        Simulate.State memory swapState
    ) internal view returns (uint256 amountOut) {
        (int256 amount0, int256 amount1) = pool.simulateSwap(
            zeroForOne,
            amountIn.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : sqrtPriceLimitX96,
            swapState
        );
        return zeroForOne ? uint256(-amount1) : uint256(-amount0);
    }

    function _quoteExactInput(
        bytes memory path,
        uint256 amountIn,
        Simulate.State[] memory swapStates
    ) internal view returns (uint256[] memory amounts, Simulate.State[] memory swapStatesEnd) {
        uint256 i = path.numPools();
        amounts = new uint256[](i + 1);
        if (swapStates.length == 0) {
            swapStates = new Simulate.State[](i);
        }
        amounts[i] = amountIn;
        while (true) {
            (IUniswapV3Pool pool, bool zeroForOne) = _decodeFirstPool(path, true);

            // the outputs of prior swaps become the inputs to subsequent ones
            --i;
            amounts[i] = _quoteExactInputSingle(pool, zeroForOne, amounts[i + 1], 0, swapStates[i]);

            // decide whether to continue or terminate
            if (i > 0) {
                path = path.skipToken();
            } else {
                break;
            }
        }
        return (amounts, swapStates);
    }

    function _quoteExactOutputSingle(
        IUniswapV3Pool pool,
        bool zeroForOne,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96,
        Simulate.State memory swapState
    ) internal view returns (uint256 amountIn) {
        (int256 amount0, int256 amount1) = pool.simulateSwap(
            zeroForOne,
            -amountOut.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : sqrtPriceLimitX96,
            swapState
        );
        return zeroForOne ? uint256(amount0) : uint256(amount1);
    }

    function _quoteExactOutput(
        bytes memory path,
        uint256 amountOut,
        Simulate.State[] memory swapStates
    ) internal view returns (uint256[] memory amounts, Simulate.State[] memory swapStatesEnd) {
        uint256 i = path.numPools();
        amounts = new uint256[](i + 1);
        if (swapStates.length == 0) {
            swapStates = new Simulate.State[](i);
        }
        amounts[i] = amountOut;
        while (true) {
            (IUniswapV3Pool pool, bool zeroForOne) = _decodeFirstPool(path, false);

            // the inputs of prior swaps become the outputs of subsequent ones
            --i;
            amounts[i] = _quoteExactOutputSingle(pool, zeroForOne, amounts[i + 1], 0, swapStates[i]);

            // decide whether to continue or terminate
            if (i > 0) {
                path = path.skipToken();
            } else {
                break;
            }
        }
        return (amounts, swapStates);
    }

    function _getQuote(
        int256 tokenAmount,
        bytes memory swapPath,
        Simulate.State[] memory swapStates
    ) internal view returns (int256, int256, Simulate.State[] memory) {
        if (tokenAmount > 0) {
            // swap wbtc to usdc
            (uint256[] memory otherTokenAmounts, Simulate.State[] memory swapStatesEnd) = _quoteExactInput(
                swapPath,
                uint256(tokenAmount),
                swapStates
            );
            return (-int256(otherTokenAmounts[0]), int256(otherTokenAmounts[1]), swapStatesEnd); // pool looses usdc hence negative
        } else if (tokenAmount < 0) {
            // swap usdc to wbtc
            (uint256[] memory otherTokenAmounts, Simulate.State[] memory swapStatesEnd) = _quoteExactOutput(
                swapPath,
                uint256(-tokenAmount),
                swapStates
            );
            return (int256(otherTokenAmounts[0]), -int256(otherTokenAmounts[1]), swapStatesEnd); // pool gains usdc hence positive
        } else {
            return (0, 0, swapStates);
        }
    }

    function _quoteCombinedSwap(
        int256 btcAmountInBtcSwap,
        int256 ethAmountInEthSwap,
        bytes memory btcSellPath,
        bytes memory ethSellPath
    ) internal view returns (int256 usdcAmountInBtcSwap, int256 usdcAmountInEthSwap) {
        // btc swap
        int256 ethAmountInBtcSwap;
        Simulate.State[] memory swapStates;
        (usdcAmountInBtcSwap, ethAmountInBtcSwap, swapStates) = _getQuote(
            btcAmountInBtcSwap,
            btcSellPath, // WBTC_TO_USDC(state),
            swapStates
        );

        // ensure btcAmountInBtcSwap and usdcAmountInBtcSwap are of opposite sign when they are both non-zero
        assert(
            btcAmountInBtcSwap == 0 || usdcAmountInBtcSwap == 0 || btcAmountInBtcSwap > 0 != usdcAmountInBtcSwap > 0
        );

        // eth swap (also accounting for price change in btc swap)
        Simulate.State[] memory swapStates2 = new Simulate.State[](1);
        if (ethAmountInBtcSwap != 0) {
            swapStates2[0] = swapStates[0];
        }
        (usdcAmountInEthSwap, , ) = _getQuote(
            ethAmountInEthSwap,
            ethSellPath, // WETH_TO_USDC(state),
            swapStates2
        );

        // ensure ethAmountInEthSwap and usdcAmountInEthSwap are of opposite sign when they are both non-zero
        assert(
            ethAmountInEthSwap == 0 || usdcAmountInEthSwap == 0 || ethAmountInEthSwap > 0 != usdcAmountInEthSwap > 0
        );
    }

    function quoteCombinedSwap(
        int256 btcAmountInBtcSwap,
        int256 ethAmountInEthSwap,
        bytes memory btcSellPath,
        bytes memory ethSellPath
    ) external view returns (int256 usdcAmountInBtcSwap, int256 usdcAmountInEthSwap) {
        return _quoteCombinedSwap(btcAmountInBtcSwap, ethAmountInEthSwap, btcSellPath, ethSellPath);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title safe casting methods
/// @notice contains methods for safely casting between types
/// @author adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol

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
 */
library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        unchecked {
            /* solhint-disable reason-string */
            require((z = uint128(y)) == y);
        }
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toInt128(int256 y) internal pure returns (int128 z) {
        unchecked {
            /* solhint-disable reason-string */
            require((z = int128(y)) == y);
        }
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        unchecked {
            require(y < 2 ** 255, 'Overflow');
            z = int256(y);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { FixedPointMathLib } from '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import { SignedMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SignedMathUpgradeable.sol';

library SignedFixedPointMathLib {
    function sign(int256 a) internal pure returns (int256) {
        return a < 0 ? -1 : int256(1);
    }

    function mulDivDown(int256 x, uint256 y, uint256 denominator) internal pure returns (int256 z) {
        int256 _sign = sign(x);
        z = _sign * int256(FixedPointMathLib.mulDivDown(SignedMathUpgradeable.abs(x), y, denominator));
        if (_sign < 0) {
            z--;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import { SwapMath } from '@uniswap/v3-core/contracts/libraries/SwapMath.sol';
import { SafeCast } from '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import { TickMath } from '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import { TickBitmap } from '@uniswap/v3-core/contracts/libraries/TickBitmap.sol';
import { BitMath } from '@uniswap/v3-core/contracts/libraries/BitMath.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Library for simulating swaps.
/// @notice By fully replicating the swap logic, we can make a static call to get a quote.
library Simulate {
    using SafeCast for uint256;

    struct Cache {
        // the lp fee of the pool
        uint24 fee;
        // the tick spacing of the pool
        int24 tickSpacing;
    }

    struct State {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the current liquidity in range
        uint128 liquidity;
    }

    // copied from UniswapV3Pool to avoid pragma issues associated with importing it
    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    function simulateSwap(
        IUniswapV3Pool pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) internal view returns (int256 amount0, int256 amount1) {
        State memory state;
        return simulateSwap(pool, zeroForOne, amountSpecified, sqrtPriceLimitX96, state);
    }

    function simulateSwap(
        IUniswapV3Pool pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        State memory state
    ) internal view returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, 'AS');

        if (state.sqrtPriceX96 == 0) {
            (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
            state.sqrtPriceX96 = sqrtPriceX96;
            state.tick = tick;
            state.liquidity = pool.liquidity();
        }

        require(
            zeroForOne
                ? sqrtPriceLimitX96 < state.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > state.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            'SPL'
        );

        Cache memory cache = Cache({ fee: pool.fee(), tickSpacing: pool.tickSpacing() });

        bool exactInput = amountSpecified > 0;

        state.amountSpecifiedRemaining = amountSpecified;
        state.amountCalculated = 0;

        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = nextInitializedTickWithinOneWord(
                pool.tickBitmap,
                state.tick,
                cache.tickSpacing,
                zeroForOne
            );

            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                cache.fee
            );

            if (exactInput) {
                unchecked {
                    state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                }
                state.amountCalculated -= step.amountOut.toInt256();
            } else {
                unchecked {
                    state.amountSpecifiedRemaining += step.amountOut.toInt256();
                }
                state.amountCalculated += (step.amountIn + step.feeAmount).toInt256();
            }

            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                if (step.initialized) {
                    (, int128 liquidityNet, , , , , , ) = pool.ticks(step.tickNext);
                    unchecked {
                        if (zeroForOne) liquidityNet = -liquidityNet;
                    }

                    state.liquidity = liquidityNet < 0
                        ? state.liquidity - uint128(-liquidityNet)
                        : state.liquidity + uint128(liquidityNet);
                }

                unchecked {
                    state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
    }

    // This function replicates TickBitmap, but accepts a function pointer argument.
    // It's private because it's messy, and shouldn't be re-used.
    function nextInitializedTickWithinOneWord(
        function(int16) external view returns (uint256) self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) private view returns (int24 next, bool initialized) {
        unchecked {
            int24 compressed = tick / tickSpacing;
            if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

            if (lte) {
                (int16 wordPos, uint8 bitPos) = TickBitmap.position(compressed);
                // all the 1s at or to the right of the current bitPos
                uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
                uint256 masked = self(wordPos) & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                    : (compressed - int24(uint24(bitPos))) * tickSpacing;
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                (int16 wordPos, uint8 bitPos) = TickBitmap.position(compressed + 1);
                // all the 1s at or to the left of the bitPos
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = self(wordPos) & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                    : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20Metadata } from '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';

library SwapPath {
    function generate(
        IERC20Metadata tokenIn,
        uint24 fee,
        IERC20Metadata tokenOut,
        bool isExactIn
    ) internal pure returns (bytes memory) {
        if (isExactIn) {
            return abi.encodePacked(tokenIn, fee, tokenOut);
        } else {
            return abi.encodePacked(tokenOut, fee, tokenIn);
        }
    }

    function generate(
        IERC20Metadata tokenIn,
        uint24 feeIn,
        IERC20Metadata tokenIntermediate,
        uint24 feeOut,
        IERC20Metadata tokenOut,
        bool isExactIn
    ) internal pure returns (bytes memory) {
        if (isExactIn) {
            return abi.encodePacked(tokenIn, feeIn, tokenIntermediate, feeOut, tokenOut);
        } else {
            return abi.encodePacked(tokenOut, feeOut, tokenIntermediate, feeIn, tokenIn);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { IAToken } from '@aave/core-v3/contracts/interfaces/IAToken.sol';
import { IPool } from '@aave/core-v3/contracts/interfaces/IPool.sol';
import { IPoolAddressesProvider } from '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import { IPriceOracle } from '@aave/core-v3/contracts/interfaces/IPriceOracle.sol';
import { IRewardsController } from '@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol';
import { WadRayMath } from '@aave/core-v3/contracts/protocol/libraries/math/WadRayMath.sol';

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import { FixedPointMathLib } from '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';

import { FullMath } from '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import { ISwapRouter } from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

import { IBalancerVault } from '../interfaces/balancer/IBalancerVault.sol';
import { IDnGmxSeniorVault } from '../interfaces/IDnGmxSeniorVault.sol';
import { IDnGmxJuniorVault, IERC4626 } from '../interfaces/IDnGmxJuniorVault.sol';
import { IDebtToken } from '../interfaces/IDebtToken.sol';
import { IGlpManager } from '../interfaces/gmx/IGlpManager.sol';
import { ISglpExtended } from '../interfaces/gmx/ISglpExtended.sol';
import { IRewardRouterV2 } from '../interfaces/gmx/IRewardRouterV2.sol';
import { IRewardTracker } from '../interfaces/gmx/IRewardTracker.sol';
import { IVault } from '../interfaces/gmx/IVault.sol';
import { IVester } from '../interfaces/gmx/IVester.sol';
import { IDnGmxTraderHedgeStrategy } from '../interfaces/IDnGmxTraderHedgeStrategy.sol';

import { DnGmxJuniorVaultManager } from '../libraries/DnGmxJuniorVaultManager.sol';
import { SafeCast } from '../libraries/SafeCast.sol';

import { ERC4626Upgradeable } from '../ERC4626/ERC4626Upgradeable.sol';

/**
 * @title Delta Neutral GMX Junior Tranche contract
 * @notice Implements the handling of junior tranche which maintains hedges for btc and eth
 * basis the target weights on GMX
 * @notice It is upgradable contract (via TransparentUpgradeableProxy proxy owned by ProxyAdmin)
 * @author RageTrade
 **/
contract DnGmxJuniorVault is IDnGmxJuniorVault, ERC4626Upgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeCast for uint256;
    using FullMath for uint256;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20Metadata;
    using FixedPointMathLib for uint256;

    using DnGmxJuniorVaultManager for DnGmxJuniorVaultManager.State;

    uint256 internal constant MAX_BPS = 10_000;
    uint256 internal constant PRICE_PRECISION = 1e30;

    DnGmxJuniorVaultManager.State internal state;

    // these gaps are added to allow adding new variables without shifting down inheritance chain
    uint256[50] private __gaps;

    modifier onlyKeeper() {
        if (msg.sender != state.keeper) revert OnlyKeeperAllowed(msg.sender, state.keeper);
        _;
    }

    modifier whenFlashloaned() {
        if (!state.hasFlashloaned) revert FlashloanNotInitiated();
        _;
    }

    modifier onlyBalancerVault() {
        if (msg.sender != address(state.balancerVault)) revert NotBalancerVault();
        _;
    }

    /* ##################################################################
                                SYSTEM FUNCTIONS
    ################################################################## */

    /// @notice initializer
    /// @param _name name of vault share token
    /// @param _symbol symbol of vault share token
    /// @param _swapRouter uniswap swap router address
    /// @param _rewardRouter gmx reward router address
    /// @param _tokens addresses of tokens used
    /// @param _poolAddressesProvider add
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _swapRouter,
        address _rewardRouter,
        address _mintBurnRewardRouter,
        DnGmxJuniorVaultManager.Tokens calldata _tokens,
        IPoolAddressesProvider _poolAddressesProvider
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC4626Upgradeable_init(address(_tokens.sGlp), _name, _symbol);

        state.weth = _tokens.weth;
        state.wbtc = _tokens.wbtc;
        state.usdc = _tokens.usdc;

        state.swapRouter = ISwapRouter(_swapRouter);
        state.rewardRouter = IRewardRouterV2(_rewardRouter);
        state.mintBurnRewardRouter = IRewardRouterV2(_mintBurnRewardRouter);

        state.poolAddressProvider = _poolAddressesProvider;

        state.glp = IERC20Metadata(ISglpExtended(asset).glp());
        state.glpManager = IGlpManager(IRewardRouterV2(_mintBurnRewardRouter).glpManager());
        state.fsGlp = IERC20(ISglpExtended(asset).stakedGlpTracker());

        state.gmxVault = IVault(state.glpManager.vault());

        state.pool = IPool(state.poolAddressProvider.getPool());
        state.oracle = IPriceOracle(state.poolAddressProvider.getPriceOracle());

        state.aUsdc = IAToken(state.pool.getReserveData(address(state.usdc)).aTokenAddress);

        state.vWbtc = IDebtToken(state.pool.getReserveData(address(state.wbtc)).variableDebtTokenAddress);
        state.vWeth = IDebtToken(state.pool.getReserveData(address(state.weth)).variableDebtTokenAddress);
    }

    /* ##################################################################
                                ADMIN FUNCTIONS
    ################################################################## */

    /// @notice grants allowances for tokens to relevant external contracts
    /// @dev to be called once the vault is deployed
    function grantAllowances() external onlyOwner {
        address aavePool = address(state.pool);
        address swapRouter = address(state.swapRouter);

        // allowance to aave pool for wbtc for repay and supply
        state.wbtc.approve(aavePool, type(uint256).max);
        // allowance to uniswap swap router for wbtc for swap
        state.wbtc.approve(swapRouter, type(uint256).max);

        // allowance to aave pool for weth for repay and supply
        state.weth.approve(aavePool, type(uint256).max);
        // allowance to uniswap swap router for weth for swap
        state.weth.approve(swapRouter, type(uint256).max);
        // allowance to batching manager for weth
        state.weth.approve(address(state.glpManager), type(uint256).max);

        // allowance to aave pool for usdc for supply
        state.usdc.approve(aavePool, type(uint256).max);
        // allowance to swap router for usdc for swap
        state.usdc.approve(address(swapRouter), type(uint256).max);
        // allowance to batching manager for usdc deposits when rebalancing profits
        state.usdc.approve(address(state.glpManager), type(uint256).max);

        // allowance to aave pool for aUSDC transfers to senior tranche
        state.aUsdc.approve(address(state.dnGmxSeniorVault), type(uint256).max);

        // allowance for sGLP to glpManager
        IERC20Metadata(asset).approve(address(state.glpManager), type(uint256).max);

        emit AllowancesGranted();
    }

    function setRouters(address rewardRouter, address mintBurnRewardRouter) external onlyOwner {
        // state.rewardRouter = IRewardRouterV2(0x159854e14A862Df9E39E1D128b8e5F70B4A3cE9B);
        // state.mintBurnRewardRouter = IRewardRouterV2(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);

        state.rewardRouter = IRewardRouterV2(rewardRouter);
        state.mintBurnRewardRouter = IRewardRouterV2(mintBurnRewardRouter);
    }

    /// @notice set admin paramters
    /// @param newKeeper keeper address
    /// @param dnGmxSeniorVault senior vault address
    /// @param newDepositCap deposit cap
    /// @param withdrawFeeBps fees bps on withdrawals and redeems
    function setAdminParams(
        address newKeeper,
        address dnGmxSeniorVault,
        uint256 newDepositCap,
        uint16 withdrawFeeBps,
        uint24 feeTierWethWbtcPool
    ) external onlyOwner {
        if (withdrawFeeBps > MAX_BPS) revert InvalidWithdrawFeeBps();

        state.keeper = newKeeper;
        state.depositCap = newDepositCap;
        state.withdrawFeeBps = withdrawFeeBps;
        state.feeTierWethWbtcPool = feeTierWethWbtcPool;

        state.dnGmxSeniorVault = IDnGmxSeniorVault(dnGmxSeniorVault);

        emit AdminParamsUpdated(newKeeper, dnGmxSeniorVault, newDepositCap, address(0), withdrawFeeBps);
    }

    /// @notice set thresholds
    /// @param slippageThresholdSwapBtcBps (BPS) slippage threshold on btc swaps
    /// @param slippageThresholdSwapEthBps (BPS) slippage threshold on eth swaps
    /// @param slippageThresholdGmxBps (BPS) slippage threshold on sGlp mint and redeem
    /// @param usdcConversionThreshold (usdc amount) threshold amount for conversion of usdc into sGlp
    /// @param wethConversionThreshold (weth amount) threshold amount for weth fees to be compounded into sGlp
    /// @param hedgeUsdcAmountThreshold (usdc amount) threshold amount below which ETH/BTC hedges are not executed
    /// @param partialBtcHedgeUsdcAmountThreshold (usdc amount) threshold amount above which BTC hedge is not fully taken (gets executed in blocks over multiple rebalances)
    /// @param partialEthHedgeUsdcAmountThreshold (usdc amount) threshold amount above which ETH hedge is not fully taken (gets executed in blocks over multiple rebalances)
    function setThresholds(
        uint16 slippageThresholdSwapBtcBps,
        uint16 slippageThresholdSwapEthBps,
        uint16 slippageThresholdGmxBps,
        uint128 usdcConversionThreshold,
        uint128 wethConversionThreshold,
        uint128 hedgeUsdcAmountThreshold,
        uint128 partialBtcHedgeUsdcAmountThreshold,
        uint128 partialEthHedgeUsdcAmountThreshold
    ) external onlyOwner {
        if (slippageThresholdSwapBtcBps > MAX_BPS) revert InvalidSlippageThresholdSwapBtc();
        if (slippageThresholdSwapEthBps > MAX_BPS) revert InvalidSlippageThresholdSwapEth();
        if (slippageThresholdGmxBps > MAX_BPS) revert InvalidSlippageThresholdGmx();

        state.slippageThresholdSwapBtcBps = slippageThresholdSwapBtcBps;
        state.slippageThresholdSwapEthBps = slippageThresholdSwapEthBps;
        state.slippageThresholdGmxBps = slippageThresholdGmxBps;
        state.usdcConversionThreshold = usdcConversionThreshold;
        state.wethConversionThreshold = wethConversionThreshold;
        state.hedgeUsdcAmountThreshold = hedgeUsdcAmountThreshold;
        state.partialBtcHedgeUsdcAmountThreshold = partialBtcHedgeUsdcAmountThreshold;
        state.partialEthHedgeUsdcAmountThreshold = partialEthHedgeUsdcAmountThreshold;

        emit ThresholdsUpdated(
            slippageThresholdSwapBtcBps,
            slippageThresholdSwapEthBps,
            slippageThresholdGmxBps,
            usdcConversionThreshold,
            wethConversionThreshold,
            hedgeUsdcAmountThreshold,
            partialBtcHedgeUsdcAmountThreshold,
            partialEthHedgeUsdcAmountThreshold
        );
    }

    /// @notice set thresholds
    /// @param rebalanceProfitUsdcAmountThreshold (BPS) slippage threshold on btc swaps
    /// @param dnGmxTraderHedgeStrategy (BPS) slippage threshold on btc swaps
    function setParamsV1(
        uint128 rebalanceProfitUsdcAmountThreshold,
        IDnGmxTraderHedgeStrategy dnGmxTraderHedgeStrategy
    ) external onlyOwner {
        state.rebalanceProfitUsdcAmountThreshold = rebalanceProfitUsdcAmountThreshold;
        state.dnGmxTraderHedgeStrategy = dnGmxTraderHedgeStrategy;

        emit ParamsV1Updated(rebalanceProfitUsdcAmountThreshold, dnGmxTraderHedgeStrategy);
    }

    /// @notice set rebalance paramters
    /// @param rebalanceTimeThreshold (seconds) minimum time difference required between two rebalance calls
    /// @dev a partial rebalance (rebalance where partial hedge gets taken) does not count.
    /// @dev setHedgeParams should already have been called.
    /// @param rebalanceDeltaThresholdBps (BPS) threshold difference between optimal and current token hedges for triggering a rebalance
    /// @param rebalanceHfThresholdBps (BPS) threshold amount of health factor on AAVE below which a rebalance is triggered
    function setRebalanceParams(
        uint32 rebalanceTimeThreshold,
        uint16 rebalanceDeltaThresholdBps,
        uint16 rebalanceHfThresholdBps
    ) external onlyOwner {
        if (rebalanceTimeThreshold > 3 days) revert InvalidRebalanceTimeThreshold();
        if (rebalanceDeltaThresholdBps > MAX_BPS) revert InvalidRebalanceDeltaThresholdBps();
        if (rebalanceHfThresholdBps < MAX_BPS || rebalanceHfThresholdBps > state.targetHealthFactor)
            revert InvalidRebalanceHfThresholdBps();

        state.rebalanceTimeThreshold = rebalanceTimeThreshold;
        state.rebalanceDeltaThresholdBps = rebalanceDeltaThresholdBps;
        state.rebalanceHfThresholdBps = rebalanceHfThresholdBps;

        emit RebalanceParamsUpdated(rebalanceTimeThreshold, rebalanceDeltaThresholdBps, rebalanceHfThresholdBps);
    }

    /// @notice set hedge parameters
    /// @param vault balancer vault for ETH and BTC flashloans
    /// @param swapRouter uniswap swap router for swapping ETH/BTC to USDC and viceversa
    /// @param targetHealthFactor health factor to target on AAVE after every rebalance
    /// @param aaveRewardsController AAVE rewards controller for handling additional reward distribution on AAVE
    function setHedgeParams(
        IBalancerVault vault,
        ISwapRouter swapRouter,
        uint256 targetHealthFactor,
        IRewardsController aaveRewardsController
    ) external onlyOwner {
        if (targetHealthFactor > 20_000) revert InvalidTargetHealthFactor();

        state.balancerVault = vault;
        state.swapRouter = swapRouter;
        state.targetHealthFactor = targetHealthFactor;
        state.aaveRewardsController = aaveRewardsController;

        // update aave pool and oracle if their addresses have updated
        IPoolAddressesProvider poolAddressProvider = state.poolAddressProvider;
        IPool pool = IPool(poolAddressProvider.getPool());
        state.pool = pool;
        IPriceOracle oracle = IPriceOracle(poolAddressProvider.getPriceOracle());
        state.oracle = oracle;

        emit HedgeParamsUpdated(vault, swapRouter, targetHealthFactor, aaveRewardsController, pool, oracle);
    }

    /// @notice set GMX parameters
    /// @param _glpManager GMX glp manager
    function setGmxParams(IGlpManager _glpManager) external onlyOwner {
        state.glpManager = _glpManager;
    }

    function setDirectConversion(bool _useDirectConversionBurn, bool _useDirectConversionMint) external onlyOwner {
        state.useDirectConversionBurn = _useDirectConversionBurn;
        state.useDirectConversionMint = _useDirectConversionMint;
    }

    /// @notice pause deposit, mint, withdraw and redeem
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause deposit, mint, withdraw and redeem
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice sets feeBps and feeRecipient
    /// @param _feeBps the part of eth rewards earned from GMX earned deducted as protocol fees
    /// @param _feeRecipient recipient address for protocol fees and protocol esGmx
    function setFeeParams(uint16 _feeBps, address _feeRecipient) external onlyOwner {
        if (state.feeRecipient != _feeRecipient) {
            state.feeRecipient = _feeRecipient;
        } else revert InvalidFeeRecipient();

        if (_feeBps > 3000) revert InvalidFeeBps();
        state.feeBps = _feeBps;

        emit FeeParamsUpdated(_feeBps, _feeRecipient);
    }

    /// @notice withdraw accumulated WETH fees
    function withdrawFees() external {
        uint256 amount = state.protocolFee;
        state.protocolFee = 0;
        state.weth.transfer(state.feeRecipient, amount);
        emit FeesWithdrawn(amount);
    }

    /// @notice unstakes and vest protocol esGmx to convert it to Gmx
    function unstakeAndVestEsGmx() external onlyOwner {
        // unstakes the protocol esGMX and starts vesting it
        // this encumbers some glp deposits
        // can stop vesting to enable glp withdraws
        uint256 amount = state.protocolEsGmx;

        state.rewardRouter.unstakeEsGmx(amount);
        IVester(state.rewardRouter.glpVester()).deposit(amount);

        emit EsGmxVested(amount);

        state.protocolEsGmx = 0;
    }

    /// @notice claims vested gmx tokens (i.e. stops vesting esGmx so that the relevant glp amount is unlocked)
    /// @dev when esGmx is vested some GlP tokens are locked on a pro-rata basis, in case that leads to issue in withdrawal this function can be called
    function stopVestAndStakeEsGmx() external onlyOwner {
        // stops vesting and stakes the remaining esGMX
        // this enables glp withdraws
        IVester(state.rewardRouter.glpVester()).withdraw();
        uint256 esGmxWithdrawn = IERC20(state.rewardRouter.esGmx()).balanceOf(address(this));
        state.rewardRouter.stakeEsGmx(esGmxWithdrawn);

        emit EsGmxStaked(esGmxWithdrawn);

        state.protocolEsGmx += esGmxWithdrawn;
    }

    /// @notice claims vested gmx tokens to feeRecipient
    /// @dev vested esGmx gets converted to GMX every second, so whatever amount is vested gets claimed
    function claimVestedGmx() external onlyOwner {
        // stops vesting and stakes the remaining esGMX
        // this can be used in case glp withdraws are hampered
        uint256 gmxClaimed = IVester(state.rewardRouter.glpVester()).claim();

        emit GmxClaimed(gmxClaimed);

        //Transfer all of the gmx received to fee recipient
        IERC20Metadata(state.rewardRouter.gmx()).safeTransfer(state.feeRecipient, gmxClaimed);
    }

    function rebalanceProfit() external onlyOwner {
        (uint256 currentBtc, uint256 currentEth) = state.getCurrentBorrows();
        uint256 totalCurrentBorrowValue = state.getBorrowValue(currentBtc, currentEth); // = total position value of current btc and eth position

        // rebalance profit
        state.rebalanceProfit(totalCurrentBorrowValue);
    }

    function harvestFees() external {
        state.harvestFees();
    }

    /* ##################################################################
                                KEEPER FUNCTIONS
    ################################################################## */
    /// @notice checks if the rebalance can be run (3 thresholds - time, hedge deviation and AAVE HF )
    function isValidRebalance() public view returns (bool) {
        return
            state.isValidRebalanceHF() ||
            state.isValidRebalanceTime() ||
            state.isValidRebalanceDeviation() ||
            state.isValidRebalanceDueToChangeInHedges();
    }

    /* solhint-disable not-rely-on-time */
    /// @notice harvests glp rewards & rebalances the hedge positions, profits on AAVE and Gmx.
    /// @notice run only if valid rebalance is true
    function rebalance() external onlyKeeper {
        if (!isValidRebalance()) revert InvalidRebalance();

        emit Rebalanced();

        (int128 currentBtcTraderOIHedge, int128 currentEthTraderOIHedge) = state.getTraderOIHedgeAmounts();
        state.btcTraderOIHedge = currentBtcTraderOIHedge;
        state.ethTraderOIHedge = currentEthTraderOIHedge;

        (uint256 currentBtc, uint256 currentEth) = state.getCurrentBorrows();
        uint256 totalCurrentBorrowValue = state.getBorrowValue(currentBtc, currentEth); // = total position value of current btc and eth position

        _emitVaultState(0);

        // harvest fees
        state.harvestFees();

        // rebalance profit
        state.rebalanceProfit(totalCurrentBorrowValue);

        // calculate current btc and eth positions in GLP
        // get the position value and calculate the collateral needed to borrow that
        // transfer collateral from LB vault to DN vault
        bool isPartialHedge = state.rebalanceHedge(currentBtc, currentEth, state.totalGlp(false), true);

        if (isPartialHedge) {
            state.lastRebalanceTS = 0; // if partial hedge is happening due to delta threshold breach, next rebalance should still go through
            if (!paused()) _pause(); // pause the contracts to prevent users from taking the slippage for updating overall hedges instead of incremental hedges
        } else {
            state.lastRebalanceTS = uint48(block.timestamp); // once partial hedge is completed the lastRebalanceTS gets updated
            if (paused()) _unpause(); // since hedges are optimal now, vault can be unpaused to handle deposits and withdraws
        }

        (currentBtc, currentEth) = state.getCurrentBorrows();

        _emitVaultState(1);
    }

    function repay() external onlyOwner {
        state.dnGmxSeniorVault.repay(getUsdcBorrowed());
    }

    /* ##################################################################
                                USER FUNCTIONS
    ################################################################## */
    /// @notice deposits sGlp token and returns vault shares
    /// @param amount amount of sGlp (asset) tokens to deposit
    /// @param to receiver address for share allocation
    /// @return shares amount of shares allocated for deposit
    function deposit(
        uint256 amount,
        address to
    ) public virtual override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256 shares) {
        _rebalanceBeforeShareAllocation();
        (, uint slippage) = _previewDeposit(amount);
        emit AssetSlippage(to, slippage);
        shares = super.deposit(amount, to);
        _emitVaultState(1);
    }

    /// @notice mints "shares" amount of vault shares and pull relevant amount of sGlp tokens
    /// @param shares amount of vault shares to mint
    /// @param to receiver address for share allocation
    /// @return amount amount of sGlp tokens required for given number of shares
    function mint(
        uint256 shares,
        address to
    ) public virtual override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256 amount) {
        _rebalanceBeforeShareAllocation();
        (, uint slippage) = _previewMint(shares);
        emit AssetSlippage(to, slippage);
        amount = super.mint(shares, to);
        _emitVaultState(1);
    }

    ///@notice withdraws "assets" amount of sGlp tokens and burns relevant amount of vault shares
    ///@notice deducts some assets for the remaining shareholders to cover the cost of opening and closing of hedge
    ///@param assets amount of assets to withdraw
    ///@param receiver receiver address for the assets
    ///@param owner owner address of the shares to be burnt
    ///@return shares number of shares burnt
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256 shares) {
        _rebalanceBeforeShareAllocation();
        (, uint slippage) = _previewWithdraw(assets);
        emit AssetSlippage(owner, slippage);
        shares = super.withdraw(assets, receiver, owner);
        _emitVaultState(1);
    }

    ///@notice burns "shares" amount of vault shares and withdraws relevant amount of sGlp tokens
    ///@notice deducts some assets for the remaining shareholders to cover the cost of opening and closing of hedge
    ///@param shares amount of shares to redeem
    ///@param receiver receiver address for the assets
    ///@param owner owner address of the shares to be burnt
    ///@return assets number of assets sent
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override(IERC4626, ERC4626Upgradeable) whenNotPaused returns (uint256 assets) {
        _rebalanceBeforeShareAllocation();
        (, uint slippage) = _previewRedeem(shares);
        emit AssetSlippage(owner, slippage);
        assets = super.redeem(shares, receiver, owner);
        _emitVaultState(1);
    }

    /* ##################################################################
                            FLASHLOAN RECEIVER
    ################################################################## */

    ///@notice flashloan receiver for balance vault
    ///@notice receives flashloaned tokens(WETH or WBTC or USDC) from balancer, swaps on uniswap and borrows/repays on AAVE
    ///@dev only allows balancer vault to call this
    ///@dev only runs when _hasFlashloaned is set to true (prevents someone else from initiating flashloan to vault)
    ///@param tokens list of tokens flashloaned
    ///@param amounts amounts of token flashloans in same order
    ///@param feeAmounts amounts of fee/premium charged for flashloan
    ///@param userData data passed to balancer for flashloan (includes token amounts, token usdc value and swap direction)
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external onlyBalancerVault whenFlashloaned {
        state.receiveFlashLoan(tokens, amounts, feeAmounts, userData);
    }

    /* ##################################################################
                                VIEW FUNCTIONS
    ################################################################## */

    ///@notice gives total asset tokens available in vault
    ///@dev some unhedged part of glp might be converted to USDC (its value in GLP is added to total glp assets)
    function totalAssets() public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return state.totalAssets();
    }

    ///@notice returns price of glp token
    ///@param maximize specifies aum used is minimum(false) or maximum(true)
    ///@return price of glp token in PRICE_PRECISION
    function getPrice(bool maximize) public view returns (uint256) {
        uint256 aum = state.glpManager.getAum(maximize);
        uint256 totalSupply = state.glp.totalSupply();

        return aum.mulDivDown(PRICE_PRECISION, totalSupply * 1e24);
    }

    ///@notice returns price of glp token
    ///@return price of glp token in X128
    function getPriceX128() public view returns (uint256) {
        uint256 aum = state.glpManager.getAum(false);
        uint256 totalSupply = state.glp.totalSupply();

        return aum.mulDiv(1 << 128, totalSupply * 1e24);
    }

    ///@notice returns the minimum market value of "assetAmount" of asset (sGlp) tokens
    ///@dev uses minimum price i.e. minimum AUM of glp tokens
    ///@param assetAmount amount of sGlp tokens
    ///@return marketValue of given amount of glp assets
    function getMarketValue(uint256 assetAmount) public view returns (uint256 marketValue) {
        marketValue = assetAmount.mulDivDown(state.getGlpPriceInUsdc(false), PRICE_PRECISION);
    }

    ///@notice returns vault market value (USD terms & 6 decimals) basis glp and usdc tokens in vault
    ///@dev Part 1. adds value of glp tokens basis minimum glp aum from gmx
    ///@dev Part 2. adds value of junior vault usdc deposit in AAVE (swap outputs + unhedged GLP)
    ///@dev Part 3. subtracts value of WETH & WBTC borrows from AAVE
    ///@return vaultMarketValue : market value of vault assets
    function getVaultMarketValue() public view returns (int256 vaultMarketValue) {
        (uint256 currentBtc, uint256 currentEth) = state.getCurrentBorrows();
        uint256 totalCurrentBorrowValue = state.getBorrowValue(currentBtc, currentEth);
        uint256 glpBalance = state.fsGlp.balanceOf(address(this));
        vaultMarketValue = ((getMarketValue(glpBalance).toInt256() +
            state.dnUsdcDeposited +
            state.unhedgedGlpInUsdc.toInt256()) - totalCurrentBorrowValue.toInt256());
    }

    /// @notice returns total amount of usdc borrowed from senior vault
    /// @dev all aUSDC yield from AAVE goes to the senior vault
    /// @dev deducts junior vault usdc (swapped + unhedged glp) from overall balance
    /// @return usdcAmount borrowed from senior tranche
    function getUsdcBorrowed() public view returns (uint256 usdcAmount) {
        return
            uint256(
                state.aUsdc.balanceOf(address(this)).toInt256() -
                    state.dnUsdcDeposited -
                    state.unhedgedGlpInUsdc.toInt256()
            );
    }

    /// @notice returns maximum amount of shares that a user can deposit
    /// @return maximum asset amount
    function maxDeposit(address) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        uint256 _depositCap = state.depositCap;
        uint256 _totalAssets = state.totalAssets(true);
        return _depositCap > _totalAssets ? _depositCap - _totalAssets : 0;
    }

    /// @notice returns maximum amount of shares that can be minted for a given user
    /// @param receiver address of the user
    /// @return maximum share amount
    function maxMint(address receiver) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        return convertToShares(maxDeposit(receiver));
    }

    /// @notice converts asset amount to share amount
    /// @param assets asset amount to convert to shares
    /// @return share amount corresponding to given asset amount
    function convertToShares(uint256 assets) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, state.totalAssets(true));
    }

    /// @notice converts share amount to asset amount
    /// @param shares asset amount to convert to assets
    /// @return asset amount corresponding to given share amount
    function convertToAssets(uint256 shares) public view override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(state.totalAssets(false), supply);
    }

    /// @notice preview function for using assets to mint shares
    /// @param assets number of assets to be deposited
    /// @return shares that would be minted to the user
    function previewDeposit(
        uint256 assets
    ) public view virtual override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        (uint shares, ) = _previewDeposit(assets);
        return shares;
    }

    /// @notice preview function for using assets to mint shares
    /// @param assets number of assets to be deposited
    /// @return shares that would be minted to the user
    /// @return slippage assets adjustment due to slippage
    function _previewDeposit(uint256 assets) internal view returns (uint256, uint256) {
        uint256 netAssets = state.getSlippageAdjustedAssets({ assets: assets, isDeposit: true });
        return (convertToShares(netAssets), assets - netAssets);
    }

    /// @notice preview function for minting of shares
    /// @param shares number of shares to mint
    /// @return assets that would be taken from the user
    function previewMint(uint256 shares) public view virtual override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        (uint assets, ) = _previewMint(shares);
        return assets;
    }

    /// @notice preview function for minting of shares
    /// @param shares number of shares to mint
    /// @return assets that would be taken from the user
    /// @return slippage assets adjustment due to slippage
    function _previewMint(uint256 shares) internal view virtual returns (uint256, uint256) {
        uint256 supply = totalSupply();

        if (supply == 0) return (shares, 0);

        uint256 assets = convertToAssets(shares);
        uint256 netAssets = state.getSlippageAdjustedAssets({ assets: assets, isDeposit: true });

        uint256 slippageInAssetTerms = assets - netAssets;

        return (assets + slippageInAssetTerms, slippageInAssetTerms);
    }

    /// @notice preview function for withdrawal of assets
    /// @param assets that would be given to the user
    /// @return shares that would be burnt
    function previewWithdraw(
        uint256 assets
    ) public view virtual override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        (uint _assets, ) = _previewWithdraw(assets);
        return _assets;
    }

    /// @notice preview function for withdrawal of assets
    /// @param assets that would be given to the user
    /// @return shares that would be burnt
    /// @return slippage assets adjustment due to slippage
    function _previewWithdraw(uint256 assets) internal view virtual returns (uint256, uint256) {
        uint256 supply = totalSupply();

        if (supply == 0) return (assets, 0);

        uint256 netAssets = state.getSlippageAdjustedAssets({ assets: assets, isDeposit: false });

        return (
            netAssets.mulDivUp(supply * MAX_BPS, state.totalAssets(false) * (MAX_BPS - state.withdrawFeeBps)),
            assets - netAssets
        );
    }

    /// @notice preview function for redeeming shares
    /// @param shares that would be taken from the user
    /// @return assets that user would get
    function previewRedeem(
        uint256 shares
    ) public view virtual override(IERC4626, ERC4626Upgradeable) returns (uint256) {
        (uint assets, ) = _previewRedeem(shares);
        return assets;
    }

    /// @notice preview function for redeeming shares
    /// @param shares that would be taken from the user
    /// @return assets that user would get
    /// @return slippage assets adjustment due to slippage
    function _previewRedeem(uint256 shares) internal view virtual returns (uint256, uint256) {
        uint256 supply = totalSupply();

        if (supply == 0) return (shares, 0);

        uint256 assets = convertToAssets(shares);
        uint256 netAssets = state.getSlippageAdjustedAssets({ assets: assets, isDeposit: false });

        return (netAssets.mulDivDown(MAX_BPS - state.withdrawFeeBps, MAX_BPS), assets - netAssets);
    }

    /// @notice returns deposit cap in terms of asset tokens
    function depositCap() external view returns (uint256) {
        return state.depositCap;
    }

    /// @notice returns current borrows for BTC and ETH respectively
    /// @return currentBtcBorrow amount of btc borrowed from AAVE
    /// @return currentEthBorrow amount of eth borrowed from AAVE
    function getCurrentBorrows() external view returns (uint256 currentBtcBorrow, uint256 currentEthBorrow) {
        return state.getCurrentBorrows();
    }

    /// @notice returns optimal borrows for BTC and ETH respectively basis glpDeposited amount
    /// @param glpDeposited amount of glp for which optimal borrow needs to be calculated
    /// @return optimalBtcBorrow optimal amount of btc borrowed from AAVE
    /// @return optimalEthBorrow optimal amount of eth borrowed from AAVE
    function getOptimalBorrows(
        uint256 glpDeposited,
        bool withUpdatedPoolAmounts
    ) external view returns (uint256 optimalBtcBorrow, uint256 optimalEthBorrow) {
        return state.getOptimalBorrows(glpDeposited, withUpdatedPoolAmounts);
    }

    /// @notice returns junior vault share of usdc deposited to AAVE
    function dnUsdcDeposited() external view returns (int256) {
        return state.dnUsdcDeposited;
    }

    function getAdminParams()
        external
        view
        returns (
            address keeper,
            IDnGmxSeniorVault dnGmxSeniorVault,
            uint256 depositCap_,
            uint16 withdrawFeeBps,
            uint24 feeTierWethWbtcPool
        )
    {
        return (
            state.keeper,
            state.dnGmxSeniorVault,
            state.depositCap,
            state.withdrawFeeBps,
            state.feeTierWethWbtcPool
        );
    }

    function getThresholds()
        external
        view
        returns (
            uint16 slippageThresholdSwapBtcBps,
            uint16 slippageThresholdSwapEthBps,
            uint16 slippageThresholdGmxBps,
            uint128 usdcConversionThreshold,
            uint128 wethConversionThreshold,
            uint128 hedgeUsdcAmountThreshold,
            uint128 partialBtcHedgeUsdcAmountThreshold,
            uint128 partialEthHedgeUsdcAmountThreshold
        )
    {
        return (
            state.slippageThresholdSwapBtcBps,
            state.slippageThresholdSwapEthBps,
            state.slippageThresholdGmxBps,
            state.usdcConversionThreshold,
            state.wethConversionThreshold,
            state.hedgeUsdcAmountThreshold,
            state.partialBtcHedgeUsdcAmountThreshold,
            state.partialEthHedgeUsdcAmountThreshold
        );
    }

    function getRebalanceParams()
        external
        view
        returns (uint32 rebalanceTimeThreshold, uint16 rebalanceDeltaThresholdBps, uint16 rebalanceHfThresholdBps)
    {
        return (state.rebalanceTimeThreshold, state.rebalanceDeltaThresholdBps, state.rebalanceHfThresholdBps);
    }

    function getHedgeParams()
        external
        view
        returns (
            IBalancerVault balancerVault,
            ISwapRouter swapRouter,
            uint256 targetHealthFactor,
            IRewardsController aaveRewardsController
        )
    {
        return (state.balancerVault, state.swapRouter, state.targetHealthFactor, state.aaveRewardsController);
    }

    /* ##################################################################
                            INTERNAL FUNCTIONS
    ################################################################## */

    function _emitVaultState(uint256 eventType) internal {
        state.emitVaultState(eventType);
    }

    /*
        DEPOSIT/WITHDRAW HELPERS
    */

    /// @notice harvests fees and rebalances profits before deposits and withdrawals
    /// @dev called first on any deposit/withdrawals
    function _rebalanceBeforeShareAllocation() internal {
        (uint256 currentBtc, uint256 currentEth) = state.getCurrentBorrows();
        uint256 totalCurrentBorrowValue = state.getBorrowValue(currentBtc, currentEth); // = total position value of current btc and eth position

        _emitVaultState(0);

        // harvest fees
        state.harvestFees();

        // rebalance profit
        state.rebalanceProfit(totalCurrentBorrowValue);
    }

    function beforeWithdraw(uint256 assets, uint256, address) internal override {
        (uint256 currentBtc, uint256 currentEth) = state.getCurrentBorrows();

        //rebalance of hedge based on assets after withdraw (before withdraw assets - withdrawn assets)
        state.rebalanceHedge(currentBtc, currentEth, state.totalGlp(false) - assets, false);
    }

    function afterDeposit(uint256, uint256, address) internal override {
        if (totalAssets() > state.depositCap) revert DepositCapExceeded();
        (uint256 currentBtc, uint256 currentEth) = state.getCurrentBorrows();

        //rebalance of hedge based on assets after deposit (after deposit assets)
        state.rebalanceHedge(currentBtc, currentEth, state.totalGlp(false), false);
    }
}