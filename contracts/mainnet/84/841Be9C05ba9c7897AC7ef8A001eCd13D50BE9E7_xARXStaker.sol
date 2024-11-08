// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IXARXStaker {
    function deposit(uint256 amount) external returns (bool);

    function withdraw(uint256 amount) external returns (bool);

    function emergencyWithdraw() external returns (bool);

    function pendingRewards(
        address account
    ) external view returns (IERC20Metadata[] memory tokens, uint256[] memory rewardAmounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./interfaces/IXARXStaker.sol";

contract xARXStaker is Ownable, ReentrancyGuard, IXARXStaker {
    using SafeERC20 for IERC20Metadata;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        mapping(IERC20Metadata => uint256) rewardDebts; // Reward debts for each rewardToken
    }

    struct Reward {
        uint256 accTokenPerShare;
        uint256 PRECISION_FACTOR;
        uint256 rewardPerSec;
    }

    // The staked token
    IERC20Metadata public stakedToken;
    // List of reward tokens
    IERC20Metadata[] public rewardTokensList;

    mapping(IERC20Metadata => Reward) public rewardTokens;

    // The block time of the last pool update
    uint256 public lastRewardTime;

    // Whether it is initialized
    bool public isInitialized;

    // The block time when Reward mining ends.
    uint256 public endTime;

    // The block time when Reward mining starts.
    uint256 public startTime;

    // The address that should receive deposit fee
    address treasury;

    // The fee that is associated with a deposit
    uint256 depositFee = 100;

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndTimes(uint256 startTime, uint256 endTime);
    event NewRewardPerSec(uint256 rewardPerSec);
    event RewardsStop(uint256 blockNumber);
    event TokenRecovery(address indexed token, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // ================================ STATE TRANSISTIONS =============================== //

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerSec: reward per sec (in rewardToken)
     * @param _startTime: start time
     * @param _endTime: end time
     */
    function initialize(
        IERC20Metadata _stakedToken,
        IERC20Metadata[] memory _rewardTokens,
        uint256[] memory _rewardsPerSec,
        uint256 _startTime,
        uint256 _endTime,
        address _treasury
    ) external returns (bool) {
        require(!isInitialized, "Already initialized");
        require(msg.sender == owner(), "Not an owner");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;

        _addRewardTokens(_rewardTokens, _rewardsPerSec);

        startTime = _startTime;
        endTime = _endTime;
        treasury = _treasury;

        // Set the lastRewardTime as the startTime
        lastRewardTime = startTime;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_treasury);
        return true;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to stake
     */
    function deposit(uint256 _amount) external override nonReentrant returns (bool) {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            IERC20Metadata rewardToken;
            Reward memory rewardInfo;
            uint256 rewardCount = rewardTokensList.length;

            for (uint256 i = 0; i < rewardCount; ) {
                rewardToken = rewardTokensList[i];
                rewardInfo = rewardTokens[rewardToken];

                uint256 pending = (user.amount * rewardInfo.accTokenPerShare) /
                    rewardInfo.PRECISION_FACTOR -
                    user.rewardDebts[rewardToken];

                if (pending > 0) {
                    if (pending > rewardToken.balanceOf(address(this)) && rewardToken.balanceOf(address(this)) > 0) {
                        rewardToken.safeTransfer(address(msg.sender), rewardToken.balanceOf(address(this)));
                    } else if (pending <= rewardToken.balanceOf(address(this))) {
                        rewardToken.safeTransfer(address(msg.sender), pending);
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        if (_amount > 0) {
            stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 feeAmount = _amount / depositFee;
            _amount = _amount - feeAmount;
            user.amount = user.amount + _amount;
            stakedToken.safeTransfer(treasury, feeAmount);
        }

        for (uint256 i = 0; i < rewardTokensList.length; i++) {
            user.rewardDebts[rewardTokensList[i]] =
                (user.amount * rewardTokens[rewardTokensList[i]].accTokenPerShare) /
                rewardTokens[rewardTokensList[i]].PRECISION_FACTOR;
        }

        emit Deposit(msg.sender, _amount);
        return true;
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw
     */
    function withdraw(uint256 _amount) external override nonReentrant returns (bool) {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        IERC20Metadata rewardToken;
        Reward memory rewardInfo;
        uint256 rewardCount = rewardTokensList.length;
        uint256 rewardTokenBalance;

        for (uint256 i = 0; i < rewardCount; ) {
            rewardToken = rewardTokensList[i];
            rewardInfo = rewardTokens[rewardToken];

            uint256 pending = (user.amount * rewardInfo.accTokenPerShare) /
                rewardInfo.PRECISION_FACTOR -
                user.rewardDebts[rewardToken];

            if (pending > 0) {
                rewardTokenBalance = rewardToken.balanceOf(address(this));

                if (pending > rewardTokenBalance && rewardTokenBalance > 0) {
                    rewardToken.safeTransfer(address(msg.sender), rewardTokenBalance);
                } else if (pending <= rewardTokenBalance) {
                    rewardToken.safeTransfer(address(msg.sender), pending);
                }
            }

            unchecked {
                ++i;
            }
        }

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            stakedToken.safeTransfer(address(msg.sender), _amount);
        }

        for (uint256 i = 0; i < rewardTokensList.length; i++) {
            user.rewardDebts[rewardTokensList[i]] =
                (user.amount * rewardTokens[rewardTokensList[i]].accTokenPerShare) /
                rewardTokens[rewardTokensList[i]].PRECISION_FACTOR;
        }

        emit Withdraw(msg.sender, _amount);
        return true;
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external override nonReentrant returns (bool) {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;

        for (uint256 i = 0; i < rewardTokensList.length; i++) {
            user.rewardDebts[rewardTokensList[i]] = 0;
        }

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
        return true;
    }

    // ================================ VIEW =============================== //

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending rewards for a given user
     */
    function pendingRewards(
        address _user
    ) external view returns (IERC20Metadata[] memory tokens, uint256[] memory rewardAmounts) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        uint256 rewardCount = rewardTokensList.length;
        tokens = new IERC20Metadata[](rewardCount);
        rewardAmounts = new uint256[](rewardCount);

        IERC20Metadata rewardToken;
        Reward memory rewardInfo;

        for (uint256 i = 0; i < rewardCount; i++) {
            rewardToken = rewardTokensList[i];
            rewardInfo = rewardTokens[rewardToken];
            tokens[i] = rewardToken;

            if (block.timestamp > lastRewardTime && stakedTokenSupply != 0) {
                uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp);

                uint256 reward_ = multiplier * rewardInfo.rewardPerSec;
                uint256 adjustedTokenPerShare = rewardInfo.accTokenPerShare +
                    (reward_ * rewardInfo.PRECISION_FACTOR) /
                    stakedTokenSupply;

                rewardAmounts[i] =
                    (user.amount * adjustedTokenPerShare) /
                    rewardInfo.PRECISION_FACTOR -
                    user.rewardDebts[rewardToken];
            } else {
                rewardAmounts[i] =
                    (user.amount * rewardInfo.accTokenPerShare) /
                    rewardInfo.PRECISION_FACTOR -
                    user.rewardDebts[rewardToken];
            }
        }
    }

    function getRewardTokens() external view returns (IERC20Metadata[] memory tokens, Reward[] memory rewardInfo) {
        uint256 rewardCount = rewardTokensList.length;
        tokens = new IERC20Metadata[](rewardCount);
        rewardInfo = new Reward[](rewardCount);

        for (uint256 i = 0; i < rewardCount; i++) {
            tokens[i] = rewardTokensList[i];
            rewardInfo[i] = rewardTokens[tokens[i]];
        }
    }

    // ================================ ADMIN =============================== //

    function addRewardTokens(
        IERC20Metadata[] memory _rewardTokens,
        uint256[] memory _rewardsPerSec
    ) external onlyOwner {
        _addRewardTokens(_rewardTokens, _rewardsPerSec);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256[] memory _amounts) external onlyOwner returns (bool) {
        require(_amounts.length == rewardTokensList.length, "Length of amountsList is not correct");
        for (uint256 i = 0; i < rewardTokensList.length; i++) {
            rewardTokensList[i].safeTransfer(address(msg.sender), _amounts[i]);
        }
        return true;
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyOwner returns (bool) {
        require(_token != address(stakedToken), "Operations: Cannot recover staked token");

        for (uint256 i = 0; i < rewardTokensList.length; i++) {
            address _rewardToken = address(rewardTokensList[i]);
            require(_token != address(_rewardToken), "Operations: Cannot recover reward token");
        }

        uint256 balance = IERC20Metadata(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20Metadata(_token).safeTransfer(address(msg.sender), balance);

        emit TokenRecovery(_token, balance);
        return true;
    }

    /*
     * @notce update the treasury's address
     * @param _treasury: New address that should receive treasury fees
     */
    function setTreasury(address _treasury) external onlyOwner returns (bool) {
        require(_treasury != address(0), "Address cannot be null");
        require(_treasury != treasury, "Address provided is the same as current");
        treasury = _treasury;
        return true;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner returns (bool) {
        endTime = block.timestamp;
        return true;
    }

    /*
     * @notice Update reward per sec
     * @dev Only callable by owner.
     * @param _index: rewardToken's number on the list
     * @param _rewardPerSec: the reward per sec
     */
    function updateRewardPerSec(uint256 _index, uint256 _rewardPerSec) external onlyOwner returns (bool) {
        rewardTokens[rewardTokensList[_index]].rewardPerSec = _rewardPerSec;
        emit NewRewardPerSec(_rewardPerSec);
        return true;
    }

    /**
     * @notice It allows the owner to update start and end times
     * @dev This function is only callable by owner.
     * @param _startTime: the new start time
     * @param _endTime: the new end time
     */
    function updateStartAndEndTimes(uint256 _startTime, uint256 _endTime) external onlyOwner returns (bool) {
        require(block.timestamp < startTime, "Pool has started");
        require(_startTime < _endTime, "New startTime must be lower than new endTime");
        require(block.timestamp < _startTime, "New startTime must be higher than current time");

        startTime = _startTime;
        endTime = _endTime;

        // Set the lastRewardTime as the startTime
        lastRewardTime = startTime;

        emit NewStartAndEndTimes(_startTime, _endTime);
        return true;
    }

    // ================================ INTERNAL =============================== //

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardTime, block.timestamp);

        for (uint256 i = 0; i < rewardTokensList.length; i++) {
            uint256 reward_ = multiplier * rewardTokens[rewardTokensList[i]].rewardPerSec;
            rewardTokens[rewardTokensList[i]].accTokenPerShare +=
                (reward_ * rewardTokens[rewardTokensList[i]].PRECISION_FACTOR) /
                stakedTokenSupply;
        }

        lastRewardTime = block.timestamp;
    }

    function _addRewardTokens(IERC20Metadata[] memory _rewardTokens, uint256[] memory _rewardsPerSec) internal {
        require(_rewardsPerSec.length == _rewardTokens.length, "Length of RewardList is not correct");

        uint256 rewardCount = _rewardTokens.length;

        for (uint256 i = 0; i < rewardCount; ) {
            uint256 decimalsRewardToken = uint256(_rewardTokens[i].decimals());
            require(decimalsRewardToken < 30, "Must be less than 30");
            uint256 PRECISION_FACTOR = uint256(10 ** (uint256(30) - decimalsRewardToken));
            rewardTokensList.push(_rewardTokens[i]);
            rewardTokens[_rewardTokens[i]].PRECISION_FACTOR = PRECISION_FACTOR;
            rewardTokens[_rewardTokens[i]].rewardPerSec = _rewardsPerSec[i];

            unchecked {
                ++i;
            }
        }
    }

    /*
     * @notice Return reward multiplier over the given _from to _to .
     * @param _from: time to start
     * @param _to: time to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= endTime) {
            return _to - _from;
        } else if (_from >= endTime) {
            return 0;
        } else {
            return endTime - _from;
        }
    }
}