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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {LibWarp} from '../libraries/LibWarp.sol';
import {LibStarVault} from '../libraries/LibStarVault.sol';
import {Stream} from '../libraries/Stream.sol';
import {LibUniV2Like} from '../libraries/LibUniV2Like.sol';
import {IUniswapV2Pair} from '../interfaces/external/IUniswapV2Pair.sol';
import {IWarpLink} from '../interfaces/IWarpLink.sol';
import {LibUniV3Like} from '../libraries/LibUniV3Like.sol';
import {IUniV3Callback} from '../interfaces/IUniV3Callback.sol';
import {IUniswapV3Pool} from '../interfaces/external/IUniswapV3Pool.sol';
import {LibCurve} from '../libraries/LibCurve.sol';
import {IPermit2} from '../interfaces/external/IPermit2.sol';
import {IAllowanceTransfer} from '../interfaces/external/IAllowanceTransfer.sol';
import {PermitParams} from '../libraries/PermitParams.sol';
import {IStargateRouter} from '../interfaces/external/IStargateRouter.sol';
import {IStargateReceiver} from '../interfaces/external/IStargateReceiver.sol';
import {IStargateComposer} from '../interfaces/external/IStargateComposer.sol';

abstract contract WarpLinkCommandTypes {
  uint256 internal constant COMMAND_TYPE_WRAP = 1;
  uint256 internal constant COMMAND_TYPE_UNWRAP = 2;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT_SINGLE = 3;
  uint256 internal constant COMMAND_TYPE_SPLIT = 4;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT = 5;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT_SINGLE = 6;
  uint256 internal constant COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT = 7;
  uint256 internal constant COMMAND_TYPE_WARP_CURVE_EXACT_INPUT_SINGLE = 8;
  uint256 internal constant COMMAND_TYPE_JUMP_STARGATE = 9;
}

contract WarpLink is IWarpLink, IStargateReceiver, WarpLinkCommandTypes {
  using SafeERC20 for IERC20;
  using Stream for uint256;

  struct WarpUniV2LikeWarpSingleParams {
    address tokenOut;
    address pool;
    bool zeroForOne; // tokenIn < tokenOut
    uint16 poolFeeBps;
  }

  struct WarpUniV2LikeExactInputParams {
    // NOTE: Excluding the first token
    address[] tokens;
    address[] pools;
    uint16[] poolFeesBps;
  }

  struct WarpUniV3LikeExactInputSingleParams {
    address tokenOut;
    address pool;
    bool zeroForOne; // tokenIn < tokenOut
    uint16 poolFeeBps;
  }

  struct WarpCurveExactInputSingleParams {
    address tokenOut;
    address pool;
    uint8 tokenIndexIn;
    uint8 tokenIndexOut;
    uint8 kind;
    bool underlying;
  }

  struct JumpStargateParams {
    uint16 dstChainId;
    uint256 srcPoolId;
    uint256 dstPoolId;
    uint256 dstGasForCall;
    bytes payload;
  }

  struct TransientState {
    address paramPartner;
    uint16 paramFeeBps;
    address paramRecipient;
    uint256 paramAmountOut;
    uint16 paramSlippageBps;
    uint256 amount;
    address payer;
    address token;
    /**
     * 0 or 1
     */
    uint256 jumped;
    /**
     * The amount of native value not spent. The native value starts off as
     * `msg.value - params.amount` and is decreased by spending money on jumps.
     *
     * Any leftover native value is returned to `msg.sender`
     */
    uint256 nativeValueRemaining;
  }

  function processSplit(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    uint256 parts = stream.readUint8();
    uint256 amountRemaining = t.amount;
    uint256 amountOutSum;

    if (parts < 2) {
      revert NotEnoughParts();
    }

    // Store the token out for the previous part to ensure every part has the same output token
    address firstPartTokenOut;
    address firstPartPayerOut;

    for (uint256 partIndex; partIndex < parts; ) {
      // TODO: Unchecked?
      // For the last part, use the remaining amount. Else read the % from the stream
      uint256 partAmount = partIndex < parts - 1
        ? (t.amount * stream.readUint16()) / 10_000
        : amountRemaining;

      if (partAmount > amountRemaining) {
        revert InsufficientAmountRemaining();
      }

      amountRemaining -= partAmount;

      TransientState memory tPart;

      tPart.amount = partAmount;
      tPart.payer = t.payer;
      tPart.token = t.token;

      tPart = engageInternal(stream, tPart);

      if (tPart.jumped == 1) {
        revert IllegalJumpInSplit();
      }

      if (partIndex == 0) {
        firstPartPayerOut = tPart.payer;
        firstPartTokenOut = tPart.token;
      } else {
        if (tPart.token != firstPartTokenOut) {
          revert InconsistentPartTokenOut();
        }

        if (tPart.payer != firstPartPayerOut) {
          revert InconsistentPartPayerOut();
        }
      }

      // NOTE: Checked
      amountOutSum += tPart.amount;

      unchecked {
        partIndex++;
      }
    }

    t.payer = firstPartPayerOut;
    t.token = firstPartTokenOut;
    t.amount = amountOutSum;

    return t;
  }

  /**
   * Wrap ETH into WETH using the WETH contract
   *
   * The ETH must already be in this contract
   *
   * The next token will be WETH, with the amount and payer unchanged
   */
  function processWrap(TransientState memory t) internal returns (TransientState memory) {
    LibWarp.State storage s = LibWarp.state();

    if (t.token != address(0)) {
      revert UnexpectedTokenForWrap();
    }

    if (t.payer != address(this)) {
      // It's not possible to move a user's ETH
      revert UnexpectedPayerForWrap();
    }

    t.token = address(s.weth);

    s.weth.deposit{value: t.amount}();

    return t;
  }

  /**
   * Unwrap WETH into ETH using the WETH contract
   *
   * The payer can be the sender or this contract. After this operation, the
   * token will be ETH (0) and the amount will be unchanged. The next payer
   * will be this contract.
   */
  function processUnwrap(TransientState memory t) internal returns (TransientState memory) {
    LibWarp.State storage s = LibWarp.state();

    if (t.token != address(s.weth)) {
      revert UnexpectedTokenForUnwrap();
    }

    address prevPayer = t.payer;
    bool shouldMoveTokensFirst = prevPayer != address(this);

    if (shouldMoveTokensFirst) {
      t.payer = address(this);
    }

    t.token = address(0);

    if (shouldMoveTokensFirst) {
      s.permit2.transferFrom(prevPayer, address(this), (uint160)(t.amount), address(s.weth));
    }

    s.weth.withdraw(t.amount);

    return t;
  }

  /**
   * Warp a single token in a Uniswap V2-like pool
   *
   * Since the pool is not trusted, the amount out is checked before
   * and after the swap to ensure the correct amount was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *   - tokenOut (address)
   *   - pool (address)
   *   - zeroForOne (0 or 1, uint8)
   *   - poolFeeBps (uint16)
   */
  function processWarpUniV2LikeExactInputSingle(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    if (t.token == address(0)) {
      revert NativeTokenNotSupported();
    }

    WarpUniV2LikeWarpSingleParams memory params;

    params.tokenOut = stream.readAddress();
    params.pool = stream.readAddress();
    params.zeroForOne = stream.readUint8() == 1;
    params.poolFeeBps = stream.readUint16();

    if (t.payer == address(this)) {
      // Transfer tokens to the pool
      IERC20(t.token).safeTransfer(params.pool, t.amount);
    } else {
      // Transfer tokens from the sender to the pool
      LibWarp.state().permit2.transferFrom(t.payer, params.pool, (uint160)(t.amount), t.token);

      // Update the payer to this contract
      t.payer = address(this);
    }

    (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(params.pool).getReserves();

    if (!params.zeroForOne) {
      // Token in > token out
      (reserveIn, reserveOut) = (reserveOut, reserveIn);
    }

    unchecked {
      // For 30 bps, multiply by 997
      uint256 feeFactor = 10_000 - params.poolFeeBps;

      t.amount =
        ((t.amount * feeFactor) * reserveOut) /
        ((reserveIn * 10_000) + (t.amount * feeFactor));
    }

    // NOTE: This check can be avoided if the factory is trusted
    uint256 balancePrev = IERC20(params.tokenOut).balanceOf(address(this));

    IUniswapV2Pair(params.pool).swap(
      params.zeroForOne ? 0 : t.amount,
      params.zeroForOne ? t.amount : 0,
      address(this),
      ''
    );

    uint256 balanceNext = IERC20(params.tokenOut).balanceOf(address(this));

    if (balanceNext < balancePrev || balanceNext < balancePrev + t.amount) {
      revert InsufficientTokensDelivered();
    }

    t.token = params.tokenOut;

    return t;
  }

  /**
   * Warp multiple tokens in a series of Uniswap V2-like pools
   *
   * Since the pools are not trusted, the balance of `params.tokenOut` is checked
   * before the first swap and after the last swap to ensure the correct amount
   * was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the last swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - pool length (uint8)
   *  - tokens (address 0, address 1, address pool length - 1) excluding the first
   *  - pools (address 0, address 1, address pool length - 1)
   *  - pool fees (uint16 0, uint16 1, uint16 pool length - 1)
   */
  function processWarpUniV2LikeExactInput(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpUniV2LikeExactInputParams memory params;

    uint256 poolLength = stream.readUint8();

    params.tokens = new address[](poolLength + 1);

    // The params will contain all tokens including the first to remain compatible
    // with the LibUniV2Like library's getAmountsOut function
    params.tokens[0] = t.token;

    for (uint256 index; index < poolLength; ) {
      params.tokens[index + 1] = stream.readAddress();

      unchecked {
        index++;
      }
    }

    params.pools = stream.readAddresses(poolLength);
    params.poolFeesBps = stream.readUint16s(poolLength);

    uint256 tokenOutBalancePrev = IERC20(params.tokens[poolLength]).balanceOf(address(this));

    uint256[] memory amounts = LibUniV2Like.getAmountsOut(
      params.poolFeesBps,
      t.amount,
      params.tokens,
      params.pools
    );

    if (t.payer == address(this)) {
      // Transfer tokens from this contract to the first pool
      IERC20(t.token).safeTransfer(params.pools[0], t.amount);
    } else {
      // Transfer tokens from the sender to the first pool
      LibWarp.state().permit2.transferFrom(t.payer, params.pools[0], (uint160)(t.amount), t.token);

      // Update the payer to this contract
      t.payer = address(this);
    }

    // Same as UniV2Like
    for (uint index; index < poolLength; ) {
      uint256 indexPlusOne = index + 1;
      bool zeroForOne = params.tokens[index] < params.tokens[indexPlusOne] ? true : false;
      address to = index < params.tokens.length - 2 ? params.pools[indexPlusOne] : address(this);

      IUniswapV2Pair(params.pools[index]).swap(
        zeroForOne ? 0 : amounts[indexPlusOne],
        zeroForOne ? amounts[indexPlusOne] : 0,
        to,
        ''
      );

      unchecked {
        index++;
      }
    }

    uint256 nextTokenOutBalance = IERC20(params.tokens[poolLength]).balanceOf(address(this));

    t.amount = amounts[amounts.length - 1];

    if (
      // TOOD: Is this overflow check necessary?
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + t.amount
    ) {
      revert InsufficientTokensDelivered();
    }

    t.token = params.tokens[poolLength];

    return t;
  }

  /**
   * Warp a single token in a Uniswap V3-like pool
   *
   * Since the pool is not trusted, the amount out is checked before
   * and after the swap to ensure the correct amount was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - tokenOut (address)
   *  - pool (address)
   */
  function processWarpUniV3LikeExactInputSingle(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpUniV3LikeExactInputSingleParams memory params;

    params.tokenOut = stream.readAddress();
    params.pool = stream.readAddress();

    if (t.token == address(0)) {
      revert NativeTokenNotSupported();
    }

    // NOTE: The pool is untrusted
    uint256 balancePrev = IERC20(params.tokenOut).balanceOf(address(this));

    bool zeroForOne = t.token < params.tokenOut;

    LibUniV3Like.beforeCallback(
      LibUniV3Like.CallbackState({payer: t.payer, token: t.token, amount: t.amount})
    );

    if (zeroForOne) {
      (, int256 amountOutSigned) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(t.amount),
        LibUniV3Like.MIN_SQRT_RATIO,
        ''
      );

      t.amount = uint256(-amountOutSigned);
    } else {
      (int256 amountOutSigned, ) = IUniswapV3Pool(params.pool).swap(
        address(this),
        zeroForOne,
        int256(t.amount),
        LibUniV3Like.MAX_SQRT_RATIO,
        ''
      );

      t.amount = uint256(-amountOutSigned);
    }

    LibUniV3Like.afterCallback();

    uint256 balanceNext = IERC20(params.tokenOut).balanceOf(address(this));

    if (balanceNext < balancePrev || balanceNext < balancePrev + t.amount) {
      revert InsufficientTokensDelivered();
    }

    t.token = params.tokenOut;

    // TODO: Compare check-and-set vs set
    t.payer = address(this);

    return t;
  }

  /**
   * Warp multiple tokens in a series of Uniswap V3-like pools
   *
   * Since the pools are not trusted, the balance of `params.tokenOut` is checked
   * before the first swap and after the last swap to ensure the correct amount
   * was delivered.
   *
   * The payer can be the sender or this contract. The token must not be ETH (0).
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the last swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - pool length (uint8)
   *  - tokens (address 0, address 1, address pool length - 1) excluding the first
   *  - pools (address 0, address 1, address pool length - 1)
   */
  function processWarpUniV3LikeExactInput(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpUniV2LikeExactInputParams memory params;

    uint256 poolLength = stream.readUint8();

    // The first token is not included
    params.tokens = stream.readAddresses(poolLength);
    params.pools = stream.readAddresses(poolLength);

    address lastToken = params.tokens[poolLength - 1];

    uint256 tokenOutBalancePrev = IERC20(lastToken).balanceOf(address(this));

    for (uint index; index < poolLength; ) {
      address tokenIn = index == 0 ? t.token : params.tokens[index - 1]; // TOOD: unchecked
      t.token = params.tokens[index];
      bool zeroForOne = tokenIn < t.token;

      LibUniV3Like.beforeCallback(
        LibUniV3Like.CallbackState({payer: t.payer, token: tokenIn, amount: t.amount})
      );

      if (index == 0) {
        // Update the payer to this contract
        // TODO: Compare check-and-set vs set
        t.payer = address(this);
      }

      address pool = params.pools[index];

      if (zeroForOne) {
        (, int256 amountOutSigned) = IUniswapV3Pool(pool).swap(
          address(this),
          zeroForOne,
          int256(t.amount),
          LibUniV3Like.MIN_SQRT_RATIO,
          ''
        );

        t.amount = uint256(-amountOutSigned);
      } else {
        (int256 amountOutSigned, ) = IUniswapV3Pool(pool).swap(
          address(this),
          zeroForOne,
          int256(t.amount),
          LibUniV3Like.MAX_SQRT_RATIO,
          ''
        );

        t.amount = uint256(-amountOutSigned);
      }

      LibUniV3Like.afterCallback();

      unchecked {
        index++;
      }
    }

    uint256 nextTokenOutBalance = IERC20(t.token).balanceOf(address(this));

    if (
      // TOOD: Is this overflow check necessary?
      nextTokenOutBalance < tokenOutBalancePrev ||
      nextTokenOutBalance < tokenOutBalancePrev + t.amount
    ) {
      revert InsufficientTokensDelivered();
    }

    return t;
  }

  /**
   * Warp a single token in a Curve-like pool
   *
   * Since the pool is not trusted, the amount out is checked before
   * and after the swap to ensure the correct amount was delivered.
   *
   * The payer can be the sender or this contract. The token may be ETH (0)
   *
   * After this operation, the token will be `params.tokenOut` and the amount will
   * be the output of the swap. The next payer will be this contract.
   *
   * Params are read from the stream as:
   *  - tokenOut (address)
   *  - pool (address)
   */
  function processWarpCurveExactInputSingle(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    WarpCurveExactInputSingleParams memory params;

    params.tokenOut = stream.readAddress();
    params.pool = stream.readAddress();
    params.tokenIndexIn = stream.readUint8();
    params.tokenIndexOut = stream.readUint8();
    params.kind = stream.readUint8();
    params.underlying = stream.readUint8() == 1;

    // NOTE: The pool is untrusted
    bool isFromEth = t.token == address(0);
    bool isToEth = params.tokenOut == address(0);

    if (t.payer != address(this)) {
      // Transfer tokens from the sender to this contract
      LibWarp.state().permit2.transferFrom(t.payer, address(this), (uint160)(t.amount), t.token);

      // Update the payer to this contract
      t.payer = address(this);
    }

    uint256 balancePrev = isToEth
      ? address(this).balance
      : IERC20(params.tokenOut).balanceOf(address(this));

    if (!isFromEth) {
      // TODO: Is this necessary to support USDT?
      IERC20(t.token).forceApprove(params.pool, t.amount);
    }

    LibCurve.exchange({
      kind: params.kind,
      underlying: params.underlying,
      pool: params.pool,
      eth: isFromEth ? t.amount : 0,
      i: params.tokenIndexIn,
      j: params.tokenIndexOut,
      dx: t.amount,
      // NOTE: There is no need to set a min out since the balance will be verified
      min_dy: 0
    });

    uint256 balanceNext = isToEth
      ? address(this).balance
      : IERC20(params.tokenOut).balanceOf(address(this));

    t.token = params.tokenOut;
    t.amount = balanceNext - balancePrev;

    return t;
  }

  /**
   * Cross-chain callback from Stargate
   *
   * The tokens have already been received by this contract, `t.payer` is set to this contract
   * before `sgReceive` is called by the router.
   *
   * The `_nonce` field is not checked since it's assumed that LayerZero will not deliver the
   * same message more than once.
   *
   * The Stargate composer is trusted, meaning `_token` and `amountLD` is not verified. Should the
   * Stargate composer be compromised, an attacker can drain this contract.
   *
   * If the payload can not be decoded, tokens are left in this contract.
   * If execution runs out of gas, tokens are left in this contract.
   *
   * If an error occurs during engage, such as insufficient output amount, tokens are refunded
   * to the recipient.
   *
   * See https://stargateprotocol.gitbook.io/stargate/interfaces/evm-solidity-interfaces/istargatereceiver.sol
   */
  function sgReceive(
    uint16, // _srcChainId
    bytes memory _srcAddress,
    uint256, // _nonce
    address _token,
    uint256 amountLD,
    bytes memory payload
  ) external {
    if (msg.sender != address(LibWarp.state().stargateComposer)) {
      revert InvalidSgReceiverSender();
    }

    // NOTE: Addresses cannot be decode from bytes using `abi.decode`
    // From https://ethereum.stackexchange.com/a/50528
    address srcAddress;

    assembly {
      srcAddress := mload(add(_srcAddress, 20))
    }

    if (srcAddress != address(this)) {
      // NOTE: This assumes that this contract is deployed at the same address on every chain
      revert InvalidSgReceiveSrcAddress();
    }

    Params memory params = abi.decode(payload, (Params));

    try
      IWarpLink(this).warpLinkEngage(
        Params({
          partner: params.partner,
          feeBps: params.feeBps,
          slippageBps: params.slippageBps,
          recipient: params.recipient,
          tokenIn: _token,
          tokenOut: params.tokenOut,
          amountIn: amountLD,
          amountOut: params.amountOut,
          deadline: params.deadline,
          commands: params.commands
        }),
        PermitParams({nonce: 0, signature: ''})
      )
    {} catch {
      // Refund tokens to the recipient
      IERC20(_token).safeTransfer(params.recipient, amountLD);
    }
  }

  /**
   * Jump to another chain using the Stargate bridge
   *
   * The token must not be ETH (0)
   *
   * After this operation, the token will be unchanged and `t.amount` will
   * be how much was sent. `t.jumped` will be set to `1` to indicate
   * that no more commands should be run
   *
   * The user may construct a command where `srcPoolId` is not for `t.token`. This is harmless
   * because only `t.token` can be moved by Stargate.
   *
   * This command must not run inside of a split.
   *
   * A bridge fee must be paid in the native token. This fee is determined with
   * `IStargateRouter.quoteLayerZeroFee`
   *
   * The value for `t.token` remains the same and is not chained.
   *
   * Params are read from the stream as:
   *   - dstChainId (uint16)
   *   - srcPoolId (uint8)
   *   - dstPoolId (uint8)
   */
  function processJumpStargate(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    if (t.token == address(0)) {
      // NOTE: There is a WETH pool
      revert NativeTokenNotSupported();
    }

    // TODO: Does this use the same gas than (a, b, c,) = (stream.read, ...)?
    JumpStargateParams memory params;
    params.dstChainId = stream.readUint16();
    params.srcPoolId = stream.readUint8();
    params.dstPoolId = stream.readUint8();
    params.dstGasForCall = stream.readUint32();
    params.payload = stream.readBytes();

    // If the tokens are being delivered directly to the recipient without a second
    // WarpLink engage, the fee is charged on this chain
    if (params.payload.length == 0) {
      // NOTE: It is not possible to know how many tokens were delivered. Therfore positive slippage
      // is never charged
      t.amount = LibStarVault.calculateAndRegisterFee(
        t.paramPartner,
        t.token,
        t.paramFeeBps,
        t.amount,
        t.amount
      );
    }

    // Enforce minimum amount/max slippage
    if (t.amount < LibWarp.applySlippage(t.paramAmountOut, t.paramSlippageBps)) {
      revert InsufficientOutputAmount();
    }

    IStargateComposer stargateComposer = LibWarp.state().stargateComposer;

    if (t.token != address(0)) {
      if (t.payer != address(this)) {
        // Transfer tokens from the sender to this contract
        LibWarp.state().permit2.transferFrom(t.payer, address(this), (uint160)(t.amount), t.token);

        // Update the payer to this contract
        t.payer = address(this);
      }

      // Allow Stargate to transfer the tokens. When there is a payload, the composer is used, else the router
      IERC20(t.token).forceApprove(
        params.payload.length == 0 ? stargateComposer.stargateRouter() : address(stargateComposer),
        t.amount
      );
    }

    t.jumped = 1;

    // Swap on the composer if there is a payload, else the router
    IStargateRouter(
      params.payload.length == 0 ? stargateComposer.stargateRouter() : address(stargateComposer)
    ).swap{value: t.nativeValueRemaining}({
      _dstChainId: params.dstChainId,
      _srcPoolId: params.srcPoolId,
      _dstPoolId: params.dstPoolId,
      //  NOTE: There is no guarantee that `msg.sender` can handle receiving tokens/ETH
      _refundAddress: payable(address(this)),
      _amountLD: t.amount,
      // Max 5% slippage
      _minAmountLD: (t.amount * 95) / 100,
      _lzTxParams: IStargateRouter.lzTxObj({
        dstGasForCall: params.dstGasForCall,
        dstNativeAmount: 0,
        dstNativeAddr: ''
      }),
      // NOTE: This assumes the contract is deployed at the same address on every chain.
      // If this is not the case, a new param needs to be added with the next WarpLink address
      _to: abi.encodePacked(params.payload.length > 0 ? address(this) : t.paramRecipient),
      _payload: params.payload
    });

    t.nativeValueRemaining = 0;

    return t;
  }

  function engageInternal(
    uint256 stream,
    TransientState memory t
  ) internal returns (TransientState memory) {
    uint256 commandCount = stream.readUint8();

    // TODO: End of stream check?
    for (uint256 commandIndex; commandIndex < commandCount; commandIndex++) {
      // TODO: Unchecked?
      uint256 commandType = stream.readUint8();

      if (commandType == COMMAND_TYPE_WRAP) {
        t = processWrap(t);
      } else if (commandType == COMMAND_TYPE_UNWRAP) {
        t = processUnwrap(t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT_SINGLE) {
        t = processWarpUniV2LikeExactInputSingle(stream, t);
      } else if (commandType == COMMAND_TYPE_SPLIT) {
        t = processSplit(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V2_LIKE_EXACT_INPUT) {
        t = processWarpUniV2LikeExactInput(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT_SINGLE) {
        t = processWarpUniV3LikeExactInputSingle(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_UNI_V3_LIKE_EXACT_INPUT) {
        t = processWarpUniV3LikeExactInput(stream, t);
      } else if (commandType == COMMAND_TYPE_WARP_CURVE_EXACT_INPUT_SINGLE) {
        t = processWarpCurveExactInputSingle(stream, t);
      } else if (commandType == COMMAND_TYPE_JUMP_STARGATE) {
        if (commandIndex != commandCount - 1) {
          revert JumpMustBeLastCommand();
        }

        t = processJumpStargate(stream, t);
      } else {
        revert UnhandledCommand();
      }
    }

    return t;
  }

  function warpLinkEngage(Params memory params, PermitParams calldata permit) external payable {
    if (block.timestamp > params.deadline) {
      revert DeadlineExpired();
    }

    TransientState memory t;
    t.paramPartner = params.partner;
    t.paramFeeBps = params.feeBps;
    t.paramSlippageBps = params.slippageBps;
    t.paramRecipient = params.recipient;
    t.paramAmountOut = params.amountOut;
    t.paramSlippageBps = params.slippageBps;
    t.amount = params.amountIn;
    t.token = params.tokenIn;

    if (params.tokenIn == address(0)) {
      if (msg.value < params.amountIn) {
        revert InsufficientEthValue();
      }

      t.nativeValueRemaining = msg.value - params.amountIn;

      // The ETH has already been moved to this contract
      t.payer = address(this);
    } else {
      // Tokens will initially moved from the sender
      t.payer = msg.sender;

      t.nativeValueRemaining = msg.value;

      // Permit tokens / set allowance
      // The signature is omitted when `warpLinkEngage` is called from `sgReceive`
      if (permit.signature.length > 0) {
        LibWarp.state().permit2.permit(
          msg.sender,
          IAllowanceTransfer.PermitSingle({
            details: IAllowanceTransfer.PermitDetails({
              token: params.tokenIn,
              amount: (uint160)(params.amountIn),
              expiration: (uint48)(params.deadline),
              nonce: (uint48)(permit.nonce)
            }),
            spender: address(this),
            sigDeadline: (uint256)(params.deadline)
          }),
          permit.signature
        );
      }
    }

    uint256 stream = Stream.createStream(params.commands);

    t = engageInternal(stream, t);

    uint256 amountOut = t.amount;
    address tokenOut = t.token;

    if (tokenOut != params.tokenOut) {
      revert UnexpectedTokenOut();
    }

    // Enforce minimum amount/max slippage
    if (amountOut < LibWarp.applySlippage(params.amountOut, params.slippageBps)) {
      revert InsufficientOutputAmount();
    }

    if (t.nativeValueRemaining > 0) {
      // TODO: Is this the correct recipient?
      payable(msg.sender).transfer(t.nativeValueRemaining);
    }

    if (t.jumped == 1) {
      // The coins have jumped away from this chain. Fees were collected before the jump
      return;
    }

    // Collect fees
    amountOut = LibStarVault.calculateAndRegisterFee(
      params.partner,
      params.tokenOut,
      params.feeBps,
      params.amountOut,
      amountOut
    );

    if (amountOut == 0) {
      revert InsufficientOutputAmount();
    }

    // Deliver tokens
    if (tokenOut == address(0)) {
      payable(params.recipient).transfer(amountOut);
    } else {
      IERC20(tokenOut).safeTransfer(params.recipient, amountOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEIP712} from './IEIP712.sol';

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer is IEIP712 {
  /// @notice Thrown when an allowance on a token has expired.
  /// @param deadline The timestamp at which the allowed amount is no longer valid
  error AllowanceExpired(uint256 deadline);

  /// @notice Thrown when an allowance on a token has been depleted.
  /// @param amount The maximum amount allowed
  error InsufficientAllowance(uint256 amount);

  /// @notice Thrown when too many nonces are invalidated.
  error ExcessiveInvalidation();

  /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
  event NonceInvalidation(
    address indexed owner,
    address indexed token,
    address indexed spender,
    uint48 newNonce,
    uint48 oldNonce
  );

  /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
  event Approval(
    address indexed owner,
    address indexed token,
    address indexed spender,
    uint160 amount,
    uint48 expiration
  );

  /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
  event Permit(
    address indexed owner,
    address indexed token,
    address indexed spender,
    uint160 amount,
    uint48 expiration,
    uint48 nonce
  );

  /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
  event Lockdown(address indexed owner, address token, address spender);

  /// @notice The permit data for a token
  struct PermitDetails {
    // ERC20 token address
    address token;
    // the maximum amount allowed to spend
    uint160 amount;
    // timestamp at which a spender's token allowances become invalid
    uint48 expiration;
    // an incrementing value indexed per owner,token,and spender for each signature
    uint48 nonce;
  }

  /// @notice The permit message signed for a single token allownce
  struct PermitSingle {
    // the permit data for a single token alownce
    PermitDetails details;
    // address permissioned on the allowed tokens
    address spender;
    // deadline on the permit signature
    uint256 sigDeadline;
  }

  /// @notice The permit message signed for multiple token allowances
  struct PermitBatch {
    // the permit data for multiple token allowances
    PermitDetails[] details;
    // address permissioned on the allowed tokens
    address spender;
    // deadline on the permit signature
    uint256 sigDeadline;
  }

  /// @notice The saved permissions
  /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
  /// @dev Setting amount to type(uint160).max sets an unlimited approval
  struct PackedAllowance {
    // amount allowed
    uint160 amount;
    // permission expiry
    uint48 expiration;
    // an incrementing value indexed per owner,token,and spender for each signature
    uint48 nonce;
  }

  /// @notice A token spender pair.
  struct TokenSpenderPair {
    // the token the spender is approved
    address token;
    // the spender address
    address spender;
  }

  /// @notice Details for a token transfer.
  struct AllowanceTransferDetails {
    // the owner of the token
    address from;
    // the recipient of the token
    address to;
    // the amount of the token
    uint160 amount;
    // the token to be transferred
    address token;
  }

  /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
  /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
  /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
  function allowance(
    address user,
    address token,
    address spender
  ) external view returns (uint160 amount, uint48 expiration, uint48 nonce);

  /// @notice Approves the spender to use up to amount of the specified token up until the expiration
  /// @param token The token to approve
  /// @param spender The spender address to approve
  /// @param amount The approved amount of the token
  /// @param expiration The timestamp at which the approval is no longer valid
  /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
  /// @dev Setting amount to type(uint160).max sets an unlimited approval
  function approve(address token, address spender, uint160 amount, uint48 expiration) external;

  /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
  /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
  /// @param owner The owner of the tokens being approved
  /// @param permitSingle Data signed over by the owner specifying the terms of approval
  /// @param signature The owner's signature over the permit data
  function permit(
    address owner,
    PermitSingle memory permitSingle,
    bytes calldata signature
  ) external;

  /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
  /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
  /// @param owner The owner of the tokens being approved
  /// @param permitBatch Data signed over by the owner specifying the terms of approval
  /// @param signature The owner's signature over the permit data
  function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

  /// @notice Transfer approved tokens from one address to another
  /// @param from The address to transfer from
  /// @param to The address of the recipient
  /// @param amount The amount of the token to transfer
  /// @param token The token address to transfer
  /// @dev Requires the from address to have approved at least the desired amount
  /// of tokens to msg.sender.
  function transferFrom(address from, address to, uint160 amount, address token) external;

  /// @notice Transfer approved tokens in a batch
  /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
  /// @dev Requires the from addresses to have approved at least the desired amount
  /// of tokens to msg.sender.
  function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

  /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
  /// by batch revoking approvals
  /// @param approvals Array of approvals to revoke.
  function lockdown(TokenSpenderPair[] calldata approvals) external;

  /// @notice Invalidate nonces for a given (token, spender) pair
  /// @param token The token to invalidate nonces for
  /// @param spender The spender to invalidate nonces for
  /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
  /// @dev Can't invalidate more than 2**16 nonces per transaction.
  function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Kind 1
// Example v0.2.4 tripool (stables)
// See https://etherscan.io/address/0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
interface ICurvePoolKind1 {
  function coins(uint256 index) external view returns (address);

  function base_coins(uint256 index) external view returns (address);

  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;

  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;
}

// Kind 2
// Example v0.2.8, Stableswap, v0.2.5 Curve GUSD Metapool
// See https://etherscan.io/address/0xdc24316b9ae028f1497c275eb9192a3ea0f67022
interface ICurvePoolKind2 {
  function coins(uint256 index) external view returns (address);

  function base_coins(uint256 index) external view returns (address);

  // 0x3df02124
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function exchange_underlying(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);
}

// Kind 3
// Example v0.3.0, "# EUR/3crv pool where 3crv is _second_, not first"
// See https://etherscan.io/address/0x5D0F47B32fDd343BfA74cE221808e2abE4A53827
// NOTE: This contract has an `exchange_underlying` with a receiver also
interface ICurvePoolKind3 {
  function coins(uint256 index) external view returns (address);

  function underlying_coins(uint256 index) external view returns (address);

  function exchange(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function exchange_underlying(
    uint256 i,
    uint256 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEIP712 {
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISignatureTransfer} from './ISignatureTransfer.sol';
import {IAllowanceTransfer} from './IAllowanceTransfer.sol';

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
interface IPermit2 is ISignatureTransfer, IAllowanceTransfer {
  // IPermit2 unifies the two interfaces so users have maximal flexibility with their approval.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEIP712} from './IEIP712.sol';

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer is IEIP712 {
  /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
  /// @param maxAmount The maximum amount a spender can request to transfer
  error InvalidAmount(uint256 maxAmount);

  /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
  /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
  error LengthMismatch();

  /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
  event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

  /// @notice The token and amount details for a transfer signed in the permit transfer signature
  struct TokenPermissions {
    // ERC20 token address
    address token;
    // the maximum amount that can be spent
    uint256 amount;
  }

  /// @notice The signed permit message for a single token transfer
  struct PermitTransferFrom {
    TokenPermissions permitted;
    // a unique value for every token owner's signature to prevent signature replays
    uint256 nonce;
    // deadline on the permit signature
    uint256 deadline;
  }

  /// @notice Specifies the recipient address and amount for batched transfers.
  /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
  /// @dev Reverts if the requested amount is greater than the permitted signed amount.
  struct SignatureTransferDetails {
    // recipient address
    address to;
    // spender requested amount
    uint256 requestedAmount;
  }

  /// @notice Used to reconstruct the signed permit message for multiple token transfers
  /// @dev Do not need to pass in spender address as it is required that it is msg.sender
  /// @dev Note that a user still signs over a spender address
  struct PermitBatchTransferFrom {
    // the tokens and corresponding amounts permitted for a transfer
    TokenPermissions[] permitted;
    // a unique value for every token owner's signature to prevent signature replays
    uint256 nonce;
    // deadline on the permit signature
    uint256 deadline;
  }

  /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
  /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
  /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
  /// @dev It returns a uint256 bitmap
  /// @dev The index, or wordPosition is capped at type(uint248).max
  function nonceBitmap(address, uint256) external view returns (uint256);

  /// @notice Transfers a token using a signed permit message
  /// @dev Reverts if the requested amount is greater than the permitted signed amount
  /// @param permit The permit data signed over by the owner
  /// @param owner The owner of the tokens to transfer
  /// @param transferDetails The spender's requested transfer details for the permitted token
  /// @param signature The signature to verify
  function permitTransferFrom(
    PermitTransferFrom memory permit,
    SignatureTransferDetails calldata transferDetails,
    address owner,
    bytes calldata signature
  ) external;

  /// @notice Transfers a token using a signed permit message
  /// @notice Includes extra data provided by the caller to verify signature over
  /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
  /// @dev Reverts if the requested amount is greater than the permitted signed amount
  /// @param permit The permit data signed over by the owner
  /// @param owner The owner of the tokens to transfer
  /// @param transferDetails The spender's requested transfer details for the permitted token
  /// @param witness Extra data to include when checking the user signature
  /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
  /// @param signature The signature to verify
  function permitWitnessTransferFrom(
    PermitTransferFrom memory permit,
    SignatureTransferDetails calldata transferDetails,
    address owner,
    bytes32 witness,
    string calldata witnessTypeString,
    bytes calldata signature
  ) external;

  /// @notice Transfers multiple tokens using a signed permit message
  /// @param permit The permit data signed over by the owner
  /// @param owner The owner of the tokens to transfer
  /// @param transferDetails Specifies the recipient and requested amount for the token transfer
  /// @param signature The signature to verify
  function permitTransferFrom(
    PermitBatchTransferFrom memory permit,
    SignatureTransferDetails[] calldata transferDetails,
    address owner,
    bytes calldata signature
  ) external;

  /// @notice Transfers multiple tokens using a signed permit message
  /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
  /// @notice Includes extra data provided by the caller to verify signature over
  /// @param permit The permit data signed over by the owner
  /// @param owner The owner of the tokens to transfer
  /// @param transferDetails Specifies the recipient and requested amount for the token transfer
  /// @param witness Extra data to include when checking the user signature
  /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
  /// @param signature The signature to verify
  function permitWitnessTransferFrom(
    PermitBatchTransferFrom memory permit,
    SignatureTransferDetails[] calldata transferDetails,
    address owner,
    bytes32 witness,
    string calldata witnessTypeString,
    bytes calldata signature
  ) external;

  /// @notice Invalidates the bits specified in mask for the bitmap at the word position
  /// @dev The wordPos is maxed at type(uint248).max
  /// @param wordPos A number to index the nonceBitmap at
  /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
  function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: BUSL-1.1
import {IStargateRouter} from './IStargateRouter.sol';

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IStargateComposer is IStargateRouter {
  function stargateRouter() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.6;

interface IStargateReceiver {
  function sgReceive(
    uint16 _srcChainId, // the remote chainId sending the tokens
    bytes memory _srcAddress, // the remote Bridge address
    uint256 _nonce,
    address _token, // the token contract on the local chain
    uint256 amountLD, // the qty of local _token contract tokens
    bytes memory payload
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IStargateRouter {
  struct lzTxObj {
    uint256 dstGasForCall;
    uint256 dstNativeAmount;
    bytes dstNativeAddr;
  }

  function swap(
    uint16 _dstChainId,
    uint256 _srcPoolId,
    uint256 _dstPoolId,
    address payable _refundAddress,
    uint256 _amountLD,
    uint256 _minAmountLD,
    lzTxObj memory _lzTxParams,
    bytes calldata _to,
    bytes calldata _payload
  ) external payable;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  function getReserves()
    external
    view
    returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV3Pool {
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function liquidity() external view returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniV3Callback {
  error CallbackInactive();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {PermitParams} from '../libraries/PermitParams.sol';

interface IWarpLink {
  error UnhandledCommand();
  error InsufficientEthValue();
  error InsufficientOutputAmount();
  error InsufficientTokensDelivered();
  error UnexpectedTokenForWrap();
  error UnexpectedTokenForUnwrap();
  error UnexpectedTokenOut();
  error InsufficientAmountRemaining();
  error NotEnoughParts();
  error InconsistentPartTokenOut();
  error InconsistentPartPayerOut();
  error UnexpectedPayerForWrap();
  error NativeTokenNotSupported();
  error DeadlineExpired();
  error IllegalJumpInSplit();
  error JumpMustBeLastCommand();
  error InvalidSgReceiverSender();
  error InvalidSgReceiveSrcAddress();

  struct Params {
    address partner;
    uint16 feeBps;
    /**
     * How much below `amountOut` the user will accept
     */
    uint16 slippageBps;
    address recipient;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    /**
     * The amount the user was quoted
     */
    uint256 amountOut;
    uint48 deadline;
    bytes commands;
  }

  function warpLinkEngage(Params memory params, PermitParams calldata permit) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ICurvePoolKind1, ICurvePoolKind2, ICurvePoolKind3} from '../interfaces/external/ICurvePool.sol';

library LibCurve {
  error UnhandledPoolKind();

  function exchange(
    uint8 kind,
    bool underlying,
    address pool,
    uint256 eth,
    uint8 i,
    uint8 j,
    uint256 dx,
    uint256 min_dy
  ) internal {
    if (kind == 1) {
      if (underlying) {
        ICurvePoolKind1(pool).exchange_underlying{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      } else {
        ICurvePoolKind1(pool).exchange{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      }
    } else if (kind == 2) {
      if (underlying) {
        ICurvePoolKind2(pool).exchange_underlying{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      } else {
        ICurvePoolKind2(pool).exchange{value: eth}(
          int128(uint128(i)),
          int128(uint128(j)),
          dx,
          min_dy
        );
      }
    } else if (kind == 3) {
      if (underlying) {
        ICurvePoolKind3(pool).exchange_underlying{value: eth}(uint256(i), uint256(j), dx, min_dy);
      } else {
        ICurvePoolKind3(pool).exchange{value: eth}(uint256(i), uint256(j), dx, min_dy);
      }
    } else {
      revert UnhandledPoolKind();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

library LibStarVault {
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * The swap fee is over the maximum allowed
   */
  error FeeTooHigh(uint256 maxFeeBps);

  event CollectedFee(
    address indexed partner,
    address indexed token,
    uint256 partnerFee,
    uint256 diamondFee
  );

  struct State {
    /**
     * Set of partner balances. An address is added when the partner is first credited
     */
    EnumerableSet.AddressSet partners;
    /**
     * Set of tokens a partner has ever received fees in. The ETH token address zero is not included.
     * Tokens are not removed from this set when a partner withdraws.
     * Mapping: Partner -> token set
     */
    mapping(address => EnumerableSet.AddressSet) partnerTokens;
    /**
     * Token balances per partner
     * Mapping: Partner -> token -> balance
     */
    mapping(address => mapping(address => uint256)) partnerBalances;
    /**
     * Total balances per token for all partners.
     * Mapping: token -> balance
     */
    mapping(address => uint256) partnerBalancesTotal;
  }

  uint256 private constant MAX_FEE_BPS = 2_000;

  function state() internal pure returns (State storage s) {
    bytes32 storagePosition = keccak256('diamond.storage.LibStarVault');

    assembly {
      s.slot := storagePosition
    }
  }

  /**
   * By using a library function we ensure that the storage used by the library is whichever contract
   * is calling this function
   */
  function registerCollectedFee(
    address partner,
    address token,
    uint256 partnerFee,
    uint256 diamondFee
  ) internal {
    State storage s = state();

    if (token != address(0)) {
      s.partnerTokens[partner].add(token);
    }

    s.partners.add(partner);

    unchecked {
      s.partnerBalances[partner][token] += partnerFee;
      s.partnerBalancesTotal[token] += partnerFee;
    }

    emit CollectedFee(partner, token, partnerFee, diamondFee);
  }

  function calculateAndRegisterFee(
    address partner,
    address token,
    uint256 feeBps,
    uint256 amountOutQuoted,
    uint256 amountOutActual
  ) internal returns (uint256 amountOutUser_) {
    if (feeBps > MAX_FEE_BPS) {
      revert FeeTooHigh(MAX_FEE_BPS);
    }

    unchecked {
      uint256 feeTotal;
      uint256 feeBasis = amountOutActual;

      if (amountOutActual > amountOutQuoted) {
        // Positive slippage
        feeTotal = amountOutActual - amountOutQuoted;

        // Change the fee basis for use below
        feeBasis = amountOutQuoted;
      }

      // Fee taken from actual
      feeTotal += (feeBasis * feeBps) / 10_000;

      // If a partner is set, split the fee in half
      uint256 feePartner = partner == address(0) ? 0 : (feeTotal * 50) / 100;
      uint256 feeDiamond = feeTotal - feePartner;

      if (feeDiamond > 0) {
        registerCollectedFee(partner, token, feePartner, feeDiamond);
      }

      return amountOutActual - feeTotal;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IUniswapV2Pair} from 'contracts/interfaces/external/IUniswapV2Pair.sol';

library LibUniV2Like {
  function getAmountsOut(
    uint16[] memory poolFeesBps,
    uint256 amountIn,
    address[] memory tokens,
    address[] memory pools
  ) internal view returns (uint256[] memory amounts) {
    uint256 poolLength = pools.length;

    amounts = new uint256[](tokens.length);
    amounts[0] = amountIn;

    for (uint256 index; index < poolLength; ) {
      address token0 = tokens[index];
      address token1 = tokens[index + 1];

      // For 30 bps, multiply by 9970
      uint256 feeFactor = 10_000 - poolFeesBps[index];

      (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pools[index]).getReserves();

      if (token0 > token1) {
        (reserveIn, reserveOut) = (reserveOut, reserveIn);
      }

      unchecked {
        amountIn =
          ((amountIn * feeFactor) * reserveOut) /
          ((reserveIn * 10_000) + (amountIn * feeFactor));
      }

      // Recycling `amountIn`
      amounts[index + 1] = amountIn;

      unchecked {
        index++;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibUniV3Like {
  error CallbackAlreadyActive();
  error CallbackStillActive();

  bytes32 constant DIAMOND_STORAGE_SLOT = keccak256('diamond.storage.LibUniV3Like');

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739 + 1;

  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;

  struct CallbackState {
    uint256 amount;
    address payer;
    address token;
  }

  struct State {
    // TODO: Does this help by using `MSTORE8`?
    uint8 isActive;
    /**
     * Transient storage variable used in the callback
     */
    CallbackState callback;
  }

  function state() internal pure returns (State storage s) {
    bytes32 slot = DIAMOND_STORAGE_SLOT;

    assembly {
      s.slot := slot
    }
  }

  function beforeCallback(CallbackState memory callback) internal {
    if (state().isActive == 1) {
      revert CallbackAlreadyActive();
    }

    state().isActive = 1;
    state().callback = callback;
  }

  function afterCallback() internal view {
    if (state().isActive == 1) {
      // The field is expected to be zeroed out by the callback
      revert CallbackStillActive();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IWETH} from '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import {IPermit2} from '../interfaces/external/IPermit2.sol';
import {IStargateComposer} from '../interfaces/external/IStargateComposer.sol';

library LibWarp {
  bytes32 constant DIAMOND_STORAGE_SLOT = keccak256('diamond.storage.LibWarp');

  struct State {
    IWETH weth;
    IPermit2 permit2;
    IStargateComposer stargateComposer;
  }

  function state() internal pure returns (State storage s) {
    bytes32 slot = DIAMOND_STORAGE_SLOT;

    assembly {
      s.slot := slot
    }
  }

  function applySlippage(uint256 amount, uint16 slippage) internal pure returns (uint256) {
    return (amount * (10_000 - slippage)) / 10_000;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct PermitParams {
  uint256 nonce;
  bytes signature;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * Stream reader
 *
 * Note that the stream position is always behind by one as per the
 * original implementation
 *
 * See https://github.com/sushiswap/sushiswap/blob/master/protocols/route-processor/contracts/InputStream.sol
 */
library Stream {
  function createStream(bytes memory data) internal pure returns (uint256 stream) {
    assembly {
      // Get a pointer to the next free memory
      stream := mload(0x40)

      // Move the free memory pointer forward by 64 bytes, since
      // this function will store 2 words (64 bytes) to memory.
      mstore(0x40, add(stream, 64))

      // Store a pointer to the data in the first word of the stream
      mstore(stream, data)

      // Store a pointer to the end of the data in the second word of the stream
      let length := mload(data)
      mstore(add(stream, 32), add(data, length))
    }
  }

  function isNotEmpty(uint256 stream) internal pure returns (bool) {
    uint256 pos;
    uint256 finish;
    assembly {
      pos := mload(stream)
      finish := mload(add(stream, 32))
    }
    return pos < finish;
  }

  function readUint8(uint256 stream) internal pure returns (uint8 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 1)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint16(uint256 stream) internal pure returns (uint16 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 2)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint24(uint256 stream) internal pure returns (uint24 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 3)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint32(uint256 stream) internal pure returns (uint32 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 4)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint48(uint256 stream) internal pure returns (uint48 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 6)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint160(uint256 stream) internal pure returns (uint160 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 20)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readUint256(uint256 stream) internal pure returns (uint256 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 32)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readBytes32(uint256 stream) internal pure returns (bytes32 res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 32)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readAddress(uint256 stream) internal pure returns (address res) {
    assembly {
      let pos := mload(stream)
      pos := add(pos, 20)
      res := mload(pos)
      mstore(stream, pos)
    }
  }

  function readBytes(uint256 stream) internal pure returns (bytes memory res) {
    assembly {
      let pos := mload(stream)
      res := add(pos, 32)
      let length := mload(res)
      mstore(stream, add(res, length))
    }
  }

  function readAddresses(
    uint256 stream,
    uint256 count
  ) internal pure returns (address[] memory res) {
    res = new address[](count);

    for (uint256 index; index < count; ) {
      res[index] = readAddress(stream);

      unchecked {
        index++;
      }
    }
  }

  function readUint16s(uint256 stream, uint256 count) internal pure returns (uint16[] memory res) {
    res = new uint16[](count);

    for (uint256 index; index < count; ) {
      res[index] = readUint16(stream);

      unchecked {
        index++;
      }
    }
  }
}