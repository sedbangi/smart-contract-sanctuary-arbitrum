// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";

/// @title StvAccount
/// @notice Contract which is cloned and deployed for every stv created by a `manager` through `Vault` contract
contract StvAccount {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the operator contract
    address private immutable OPERATOR;
    /// @notice info of the stv
    IVault.StvInfo public stvInfo;
    /// @notice balances of the stv
    IVault.StvBalance public stvBalance;
    /// @notice info of the investors who deposited into the stv
    mapping(address => IVault.InvestorInfo) public investorInfo;
    /// @notice array of investors
    address[] public investors;
    /// @notice total received after opening a spot position
    mapping(address => uint256) public totalTradeTokenReceivedAfterOpen;
    /// @notice total tradeToken used for closing a spot position
    mapping(address => uint256) public totalTradeTokenUsedForClose;

    /*//////////////////////////////////////////////////////////////
                       CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator) {
        OPERATOR = _operator;
    }

    modifier onlyVault() {
        address vault = IOperator(OPERATOR).getAddress("VAULT");
        if (msg.sender != vault) revert Errors.NoAccess();
        _;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice function to execute trades on different ddexes
    /// @dev can only be called by a plugin
    /// @param adapter address of the contract
    /// @param data calldata
    function execute(address adapter, bytes calldata data, uint256 ethToSend) external payable returns (bytes memory) {
        bool isPlugin = IOperator(OPERATOR).getPlugin(msg.sender);
        if (!isPlugin) revert Errors.NoAccess();
        (bool success, bytes memory returnData) = adapter.call{value: ethToSend}(data);
        if (!success) revert Errors.CallFailed(returnData);
        return returnData;
    }

    /// @notice updates the state `stvInfo`
    /// @dev can only be called by the `Vault` contract
    /// @param stv StvInfo
    function createStv(IVault.StvInfo memory stv) external onlyVault {
        stvInfo = stv;
    }

    /// @notice updates `totalRaised` and the `investorInfo`
    /// @dev can only be called by the `Vault` contract
    /// @param investorAccount address of the investor's Account contract
    /// @param amount amount deposited into the stv
    /// @param isFirstDeposit bool to check if its the first time deposit by the investor
    function deposit(address investorAccount, uint96 amount, bool isFirstDeposit) external onlyVault {
        if (isFirstDeposit) investors.push(investorAccount);
        stvBalance.totalRaised += amount;
        investorInfo[investorAccount].depositAmount += amount;
    }

    /// @notice updates `status` of the stv
    /// @dev can only be called by the `Vault` contract
    function liquidate() external onlyVault {
        stvInfo.status = IVault.StvStatus.LIQUIDATED;
    }

    /// @notice updates state according to increase or decrease trade
    /// @dev can only be called by the `Vault` contract
    /// @param amount amount of tokens used to increase/decrease position
    /// @param tradeToken address of the token used for spot execution
    /// @param totalReceived tokens received after the position is executed
    /// @param isOpen bool to check if its an increase or a decrease trade
    function execute(uint256 amount, address tradeToken, uint256 totalReceived, bool isOpen) external onlyVault {
        if (isOpen) {
            stvInfo.status = IVault.StvStatus.OPEN;
            if (tradeToken != address(0)) totalTradeTokenReceivedAfterOpen[tradeToken] += totalReceived;
        } else {
            if (tradeToken != address(0)) totalTradeTokenUsedForClose[tradeToken] += amount;
        }
    }

    /// @notice transfers all the tokens to the respective investors
    /// @dev can only be called by the `Vault` contract
    /// @param totalRemainingAfterDistribute amount of tokens remaining after the stv is closed
    /// @param mFee manager fees
    /// @param pFee performance fees
    function distribute(uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee) external onlyVault {
        address defaultStableCoin = IOperator(OPERATOR).getAddress("DEFAULTSTABLECOIN");

        stvInfo.status = IVault.StvStatus.DISTRIBUTED;
        stvBalance.totalRemainingAfterDistribute = totalRemainingAfterDistribute;

        if (mFee > 0 || pFee > 0) {
            IVault.StvInfo memory stv = stvInfo;
            address managerAccount = IOperator(OPERATOR).getTraderAccount(stv.manager);
            address treasury = IOperator(OPERATOR).getAddress("TREASURY");
            IERC20(defaultStableCoin).safeTransfer(managerAccount, mFee);
            IERC20(defaultStableCoin).safeTransfer(treasury, pFee);
        }

        uint256 maxDistributeIndex = IOperator(OPERATOR).getMaxDistributeIndex();
        _distribute(false, 0, maxDistributeIndex);
    }

    /// @notice called if `distribute` runs out of gas
    /// @dev can only be called by the `Vault` contract
    /// @param isCancel bool to check if the stv is cancelled or closed
    /// @param indexFrom starting index to transfer the tokens to the investors
    /// @param indexTo ending index to transfer the tokens to the investors
    function distributeOut(bool isCancel, uint256 indexFrom, uint256 indexTo) external onlyVault {
        _distribute(isCancel, indexFrom, indexTo);
    }

    /// @notice updates `status` of the stv
    /// @dev can only be called by the `Vault` contract
    /// @param status status of the stv
    function updateStatus(IVault.StvStatus status) external onlyVault {
        stvInfo.status = status;
    }

    /// @notice cancels the stv and transfers the tokens back to the investors
    /// @dev can only be called by the `Vault` contract
    function cancel() external onlyVault {
        stvInfo.endTime = 0;

        uint256 maxDistributeIndex = IOperator(OPERATOR).getMaxDistributeIndex();
        _distribute(true, 0, maxDistributeIndex);
    }

    /// @notice get the claimableAmount after the stv is closed
    /// @dev can only be called by the `Vault` contract
    /// @param investorAccount address of the investor's Account contract
    function getClaimableAmountAfterDistribute(address investorAccount)
        external
        view
        returns (uint96 claimableAmount)
    {
        return _getClaimableAmountAfterDistribute(investorAccount);
    }

    /// @notice Get all the addresses invested in this stv
    function getInvestors() public view returns (address[] memory) {
        return investors;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _getClaimableAmountAfterDistribute(address investorAccount)
        internal
        view
        returns (uint96 claimableAmount)
    {
        IVault.InvestorInfo memory _investorInfo = investorInfo[investorAccount];
        IVault.StvBalance memory _stvBalance = stvBalance;

        if (stvInfo.status == IVault.StvStatus.DISTRIBUTED && !_investorInfo.claimed) {
            claimableAmount =
                (_stvBalance.totalRemainingAfterDistribute * _investorInfo.depositAmount) / _stvBalance.totalRaised;
        } else {
            claimableAmount = 0;
        }
    }

    function _distribute(bool isCancel, uint256 indexFrom, uint256 indexTo) internal {
        uint256 maxDistributeIndex = IOperator(OPERATOR).getMaxDistributeIndex();
        if (indexTo - indexFrom > maxDistributeIndex) revert Errors.AboveMaxDistributeIndex();

        address[] memory _investors = investors;
        if (indexTo == maxDistributeIndex && maxDistributeIndex > _investors.length) indexTo = _investors.length;

        address defaultStableCoin = IOperator(OPERATOR).getAddress("DEFAULTSTABLECOIN");
        uint256 i = indexFrom;

        if (isCancel) {
            for (; i < indexTo;) {
                address investorAccount = _investors[i];
                IVault.InvestorInfo memory _investorInfo = investorInfo[investorAccount];
                uint256 transferAmount = _investorInfo.depositAmount;

                investorInfo[investorAccount].depositAmount = 0;
                IERC20(defaultStableCoin).safeTransfer(investorAccount, transferAmount);
                unchecked {
                    ++i;
                }
            }
        } else {
            for (; i < indexTo;) {
                address investorAccount = _investors[i];
                uint96 claimableAmount = _getClaimableAmountAfterDistribute(investorAccount);
                if (investorInfo[investorAccount].claimed) continue;

                investorInfo[investorAccount].claimed = true;
                investorInfo[investorAccount].depositAmount = 0;
                investorInfo[investorAccount].claimedAmount = claimableAmount;
                IERC20(defaultStableCoin).safeTransfer(investorAccount, claimableAmount);
                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();
    error AboveMaxDistributeIndex();
    error BelowMinStvDepositAmount();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();
    error WrongRewardClaimToken();

    // Subscriptions
    error NotASubscriber();
    error AlreadySubscribed();
    error MoreThanLimit();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVault {
    /// @notice Enum to describe the trading status of the vault
    /// @dev NOT_OPENED - Not open
    /// @dev OPEN - opened position
    /// @dev CANCELLED_WITH_ZERO_RAISE - cancelled without any raise
    /// @dev CANCELLED_WITH_NO_FILL - cancelled with raise but not opening a position
    /// @dev CANCELLED_BY_MANAGER - cancelled by the manager after raising
    /// @dev DISTRIBUTED - distributed fees
    /// @dev LIQUIDATED - liquidated position
    enum StvStatus {
        NOT_OPENED,
        OPEN,
        CANCELLED_WITH_ZERO_RAISE,
        CANCELLED_WITH_NO_FILL,
        CANCELLED_BY_MANAGER,
        DISTRIBUTED,
        LIQUIDATED
    }

    struct StvInfo {
        address stvId;
        uint40 endTime;
        StvStatus status;
        address manager;
        uint96 capacityOfStv;
    }

    struct StvBalance {
        uint96 totalRaised;
        uint96 totalRemainingAfterDistribute;
    }

    struct InvestorInfo {
        uint96 depositAmount;
        uint96 claimedAmount;
        bool claimed;
    }

    function getQ() external view returns (address);
    function maxFundraisingPeriod() external view returns (uint40);
    function distributeOut(address stvId, bool isCancel, uint256 indexFrom, uint256 indexTo) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOperator {
    function getMaxDistributeIndex() external view returns (uint256);
    function getAddress(string calldata adapter) external view returns (address);
    function getAddresses(string[] calldata adapters) external view returns (address[] memory);
    function getTraderAccount(address trader) external view returns (address);
    function getPlugin(address plugin) external view returns (bool);
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory);
    function setAddress(string calldata adapter, address addr) external;
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external;
    function setPlugin(address plugin, bool isPlugin) external;
    function setPlugins(address[] calldata plugins, bool[] calldata isPlugin) external;
    function setTraderAccount(address trader, address account) external;
    function getAllSubscribers(address manager) external view returns (address[] memory);
    function getIsSubscriber(address manager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96);
    function setSubscribe(address manager, address subscriber, uint96 maxLimit) external;
    function setUnsubscribe(address manager, address subscriber) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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