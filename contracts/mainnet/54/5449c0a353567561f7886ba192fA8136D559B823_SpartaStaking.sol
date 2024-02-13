// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessControlHolder
 * @notice Interface created to store reference to the access control.
 */
interface IAccessControlHolder {
    /**
     * @notice Function returns reference to IAccessControl.
     * @return IAccessControl reference to access control.
     */
    function acl() external view returns (IAccessControl);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IContractsRepostiory {
    error ContractDoesNotExist();
    error OnlyRepositoryOnwer();

    function getContract(bytes32 contractId) external view returns (address);

    function tryGetContract(bytes32 contractId) external view returns (address);

    function setContract(bytes32 contractId, address contractAddress) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title IWithFees.
 * @notice This interface describes the functions for managing fees in a contract.
 */
interface IWithFees {
    error OnlyFeesManagerAccess();
    error OnlyWithFees();
    error ETHTransferFailed();

    /**
     * @notice Function returns the treasury address where fees are collected.
     * @return The address of the treasury .
     */
    function treasury() external view returns (address);

    /**
     * @notice Function returns the value of the fees.
     * @return uint256 Amount of fees to pay.
     */
    function fees() external view returns (uint256);

    /**
     * @notice Function transfers the collected fees to the treasury address.
     */
    function transfer() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface ISpartaStaking {
    error RewardBalanceTooSmall();
    error BeforeStakingStart();
    error AfterStakingFinish();
    error TokensAlreadyClaimed();
    error RoundDoesNotExist();
    error BeforeReleaseTime();
    error NotValidUnlockTimestamp();
    error ToEarlyToWithdrawReward();
    error StartNotValid();
    error MinimalUnstakingPeriod();
    error CannotUnstake();
    error CurrentImplementation();

    struct TokensToClaim {
        bool taken;
        uint256 release;
        uint256 value;
    }

    event Staked(address indexed wallet, uint256 value);
    event Unstaked(
        address indexed wallet,
        uint256 tokensAmount,
        uint256 tokensToClaim,
        uint256 duration
    );
    event TokensClaimed(
        address indexed wallet,
        uint256 indexed roundId,
        uint256 tokensToClaimid
    );
    event RewardTaken(address indexed wallet, uint256 amount);

    event Initialized(
        uint256 start,
        uint256 duration,
        uint256 reward,
        uint256 unlockTokensTimestamp
    );

    event MovedToNextImplementation(
        address indexed by,
        uint256 balance,
        uint256 reward
    );

    function finishAt() external view returns (uint256);

    function stake(uint256 amount) external;

    function stakeAs(address wallet, uint256 amount) external;

    function unlockTokens(address to, uint256 amount) external;

    function unlockTokensTimestamp() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IStakedSparta} from "../tokens/interfaces/IStakedSparta.sol";
import {ISpartaStaking} from "./interfaces/ISpartaStaking.sol";
import {ToInitialize} from "../ToInitialize.sol";
import {WithFees} from "../WithFees.sol";
import {ZeroAddressGuard} from "../ZeroAddressGuard.sol";
import {ZeroAmountGuard} from "../ZeroAmountGuard.sol";
import {IAccessControl, IAccessControlHolder} from "../IAccessControlHolder.sol";
import {IContractsRepostiory} from "../IContractsRepostiory.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpartaStaking is
    ISpartaStaking,
    ToInitialize,
    Ownable,
    WithFees,
    ZeroAddressGuard,
    ZeroAmountGuard
{
    using SafeERC20 for IERC20;

    uint256 constant UNLOCK_TIMESTAMP_MINIMUM_DIFF = 30 days;
    uint256 constant MINIML_UNSTAKING_PERIOD = 10 days;
    bytes32 constant SPARTA_STAKING_CONTRACT_ID = keccak256("SPARTA_STAKING");

    IERC20 public immutable sparta;
    IStakedSparta public immutable stakedSparta;
    IContractsRepostiory public immutable contractsRepository;
    uint256 public totalSupply;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;
    uint256 public start;
    uint256 public updatedAt;
    uint256 public duration;
    uint256 public override unlockTokensTimestamp;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userTokensToClaimCounter;
    mapping(address => mapping(uint256 => TokensToClaim))
        public userTokensToClaim;

    modifier isOngoing() {
        if (block.timestamp < start) {
            revert BeforeStakingStart();
        }
        if (finishAt() < block.timestamp) {
            revert AfterStakingFinish();
        }
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        _;
    }

    modifier canUstake(uint256 amount, uint256 duration_) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (amount > balanceOf[msg.sender]) {
            revert CannotUnstake();
        }
        if (duration_ < MINIML_UNSTAKING_PERIOD) {
            revert MinimalUnstakingPeriod();
        }
        _;
    }

    constructor(
        IERC20 sparta_,
        IStakedSparta stakedSparta_,
        IAccessControl acl_,
        IContractsRepostiory contractRepository_,
        address treasury_,
        uint256 fees_
    ) Ownable() WithFees(acl_, treasury_, fees_) {
        sparta = sparta_;
        stakedSparta = stakedSparta_;
        contractsRepository = contractRepository_;
    }

    function stake(uint256 _amount) external {
        stakeAs(msg.sender, _amount);
    }

    function initialize(
        uint256 amount_,
        uint256 start_,
        uint256 duration_,
        uint256 unlockTokensTimestamp_
    )
        external
        notInitialized
        onlyOwner
        notZeroAmount(amount_)
        notZeroAmount(duration_)
    {
        if (sparta.balanceOf(address(this)) < amount_) {
            revert RewardBalanceTooSmall();
        }
        if (block.timestamp > start_) {
            revert StartNotValid();
        }
        if (
            start_ + duration_ + UNLOCK_TIMESTAMP_MINIMUM_DIFF >
            unlockTokensTimestamp_
        ) {
            revert NotValidUnlockTimestamp();
        }

        duration = duration_;
        start = start_;
        rewardRate = amount_ / duration_;
        updatedAt = block.timestamp;

        unlockTokensTimestamp = unlockTokensTimestamp_;
        initialized = true;

        emit Initialized(start_, duration_, amount_, unlockTokensTimestamp_);
    }

    function withdrawTokensToClaimFromRounds(
        uint256[] calldata rounds
    ) external {
        uint256 roundsLength = rounds.length;
        for (uint roundIndex = 0; roundIndex < roundsLength; ) {
            withdrawTokensToClaim(rounds[roundIndex]);
            unchecked {
                ++roundIndex;
            }
        }
    }

    function unlockTokens(
        address to,
        uint256 amount
    )
        external
        isInitialized
        notZeroAddress(to)
        notZeroAmount(amount)
        onlyOwner
    {
        if (block.timestamp < unlockTokensTimestamp) {
            revert ToEarlyToWithdrawReward();
        }
        sparta.safeTransfer(to, amount);
    }

    function moveToNextSpartaStaking()
        external
        updateReward(msg.sender)
        isInitialized
    {
        ISpartaStaking current = currentImplementation();

        uint256 balance = balanceOf[msg.sender];
        if (balance == 0) {
            revert ZeroAmount();
        }
        balanceOf[msg.sender] = 0;
        stakedSparta.burnFrom(msg.sender, balance);
        totalSupply -= balance;
        sparta.forceApprove(address(current), balance);
        current.stakeAs(msg.sender, balance);

        emit MovedToNextImplementation(msg.sender, balance, 0);
    }

    function moveToNextSpartaStakingWithReward()
        external
        isInitialized
        updateReward(msg.sender)
    {
        ISpartaStaking current = currentImplementation();
        uint256 balance = balanceOf[msg.sender];
        uint256 reward = rewards[msg.sender];
        uint256 total = balance + reward;
        stakedSparta.burnFrom(msg.sender, balance);

        if (total == 0) {
            revert ZeroAmount();
        }

        balanceOf[msg.sender] = 0;
        rewards[msg.sender] = 0;
        totalSupply -= balance;
        sparta.forceApprove(address(current), total);
        current.stakeAs(msg.sender, total);

        emit MovedToNextImplementation(msg.sender, balance, reward);
    }

    function toEnd() external view returns (uint256) {
        return block.timestamp >= finishAt() ? 0 : finishAt() - block.timestamp;
    }

    function totalLocked(address wallet) external view returns (uint256) {
        return totalPendingToClaim(wallet) + earned(wallet) + balanceOf[wallet];
    }

    function getUserAllocations(
        address _wallet
    ) external view returns (TokensToClaim[] memory) {
        uint256 counter = userTokensToClaimCounter[_wallet];
        TokensToClaim[] memory toClaims = new TokensToClaim[](counter);

        for (uint256 i = 0; i < counter; ) {
            toClaims[i] = userTokensToClaim[_wallet][i];
            unchecked {
                ++i;
            }
        }

        return toClaims;
    }

    function unstake(
        uint256 amount,
        uint256 after_
    )
        public
        payable
        onlyWithFees
        isInitialized
        canUstake(amount, after_)
        updateReward(msg.sender)
    {
        uint256 round = userTokensToClaimCounter[msg.sender];
        uint256 tokensToWidthdraw = calculateWithFee(amount, after_);
        uint256 releaseTime = after_ + block.timestamp;
        uint256 spartaFees = amount - tokensToWidthdraw;

        userTokensToClaim[msg.sender][round] = TokensToClaim(
            false,
            releaseTime,
            tokensToWidthdraw
        );

        ++userTokensToClaimCounter[msg.sender];
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        if (spartaFees > 0) {
            sparta.transfer(treasury, spartaFees);
        }

        stakedSparta.burnFrom(msg.sender, amount);

        emit Unstaked(msg.sender, amount, tokensToWidthdraw, releaseTime);
    }

    function stakeAs(
        address wallet,
        uint256 amount
    )
        public
        isInitialized
        isOngoing
        notZeroAddress(wallet)
        updateReward(wallet)
    {
        sparta.safeTransferFrom(msg.sender, address(this), amount);

        balanceOf[wallet] += amount;
        totalSupply += amount;
        stakedSparta.mintTo(wallet, amount);

        emit Staked(wallet, amount);
    }

    function getReward()
        public
        payable
        isInitialized
        onlyWithFees
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        if (reward == 0) {
            revert ZeroAmount();
        }

        sparta.safeTransfer(msg.sender, reward);
        rewards[msg.sender] = 0;

        emit RewardTaken(msg.sender, reward);
    }

    function withdrawTokensToClaim(uint256 round) public payable onlyWithFees {
        TokensToClaim storage tokensToClaim = userTokensToClaim[msg.sender][
            round
        ];
        if (tokensToClaim.release == 0) {
            revert RoundDoesNotExist();
        }
        if (block.timestamp < tokensToClaim.release) {
            revert BeforeReleaseTime();
        }
        if (tokensToClaim.taken) {
            revert TokensAlreadyClaimed();
        }
        sparta.safeTransfer(msg.sender, tokensToClaim.value);

        tokensToClaim.taken = true;

        emit TokensClaimed(msg.sender, tokensToClaim.value, round);
    }

    function finishAt() public view override returns (uint256) {
        return start + duration;
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0 || block.timestamp < start) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt(), block.timestamp);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function totalPendingToClaim(address wallet) public view returns (uint256) {
        uint256 toClaim = 0;
        uint256 rounds = userTokensToClaimCounter[wallet];
        for (uint256 roundIndex = 0; roundIndex < rounds; ) {
            TokensToClaim memory tokensToClaim = userTokensToClaim[wallet][
                roundIndex
            ];
            if (!tokensToClaim.taken) {
                toClaim += tokensToClaim.value;
            }
            unchecked {
                ++roundIndex;
            }
        }
        return toClaim;
    }

    function currentImplementation() public view returns (ISpartaStaking) {
        address spartaStakingAddress = contractsRepository.getContract(
            SPARTA_STAKING_CONTRACT_ID
        );

        if (spartaStakingAddress == address(this)) {
            revert CurrentImplementation();
        }

        return SpartaStaking(spartaStakingAddress);
    }

    function calculateWithFee(
        uint256 input,
        uint256 _duration
    ) public pure returns (uint256) {
        uint256 saturatedDuration = _duration > 110 days ? 110 days : _duration;
        uint256 feesNominator = ((110 days - saturatedDuration) * 500) / 1 days;
        uint256 feesOnAmount = (input * feesNominator) / 100000;
        return input - feesOnAmount;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

contract ToInitialize {
    error AlreadyInitialized();
    error NotInitialized();

    bool internal initialized;

    modifier isInitialized() {
        _isInitialized();
        _;
    }

    function _isInitialized() internal view {
        if (!initialized) {
            revert NotInitialized();
        }
    }

    modifier notInitialized() {
        if (initialized) {
            revert AlreadyInitialized();
        }
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakedSparta is IERC20 {
    function mintTo(address to, uint256 amount) external;

    function burnFrom(address wallet, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IAccessControlHolder, IAccessControl} from "./IAccessControlHolder.sol";
import {IWithFees} from "./IWithFees.sol";

/**
 * @title WithFees
 * @notice This contract is responsible for managing, calculating and transferring fees.
 */
contract WithFees is IAccessControlHolder, IWithFees {
    address public immutable override treasury;
    uint256 public immutable override fees;
    IAccessControl public immutable override acl;
    bytes32 public constant FEES_MANAGER = keccak256("FEES_MANAGER");

    /**
     * @notice Modifier to allow only function calls that are accompanied by the required fee.
     * @dev Function reverts with OnlyWithFees error, if the value is smaller than expected.
     */
    modifier onlyWithFees() {
        if (fees != msg.value) {
            revert OnlyWithFees();
        }
        _;
    }

    /**
     * @notice Modifier to allow only accounts with FEES_MANAGER role.
     * @dev Reverts with OnlyFeesManagerAccess error, if the sender does not have the role.
     */
    modifier onlyFeesManagerAccess() {
        if (!acl.hasRole(FEES_MANAGER, msg.sender)) {
            revert OnlyFeesManagerAccess();
        }
        _;
    }

    constructor(IAccessControl acl_, address treasury_, uint256 value_) {
        acl = acl_;
        treasury = treasury_;
        fees = value_;
    }

    /**
     * @notice Transfers the balance of the contract to the treasury.
     * @dev  Only accessible by an account with the FEES_MANAGER role.
     */
    function transfer() external onlyFeesManagerAccess {
        (bool sent, ) = treasury.call{value: address(this).balance}("");
        if (!sent) {
            revert ETHTransferFailed();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAddressGuard.
 * @notice This contract is responsible for ensuring that a given address is not a zero address.
 */

contract ZeroAddressGuard {
    error ZeroAddress();

    /**
     * @notice Modifier to make a function callable only when the provided address is non-zero.
     * @dev If the address is a zero address, the function reverts with ZeroAddress error.
     * @param _addr Address to be checked..
     */
    modifier notZeroAddress(address _addr) {
        _ensureIsNotZeroAddress(_addr);
        _;
    }

    /// @notice Checks if a given address is a zero address and reverts if it is.
    /// @param _addr Address to be checked.
    /// @dev If the address is a zero address, the function reverts with ZeroAddress error.
    /**
     * @notice Checks if a given address is a zero address and reverts if it is.
     * @dev     .
     * @param   _addr  .
     */
    function _ensureIsNotZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAmountGuard
 * @notice This contract provides a modifier to guard against zero values in a transaction.
 */
contract ZeroAmountGuard {
    error ZeroAmount();

    /**
     * @notice Modifier ensures the amount provided is not zero.
     * param _amount The amount to check.
     * @dev If the amount is zero, the function reverts with a ZeroAmount error.
     */
    modifier notZeroAmount(uint256 _amount) {
        _ensureIsNotZero(_amount);
        _;
    }

    /**
     * @notice Function verifies that the given amount is not zero.
     * @param _amount The amount to check.
     */
    function _ensureIsNotZero(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert ZeroAmount();
        }
    }
}