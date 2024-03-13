// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/Governable.sol";

/// @title DataStore
/// @notice General purpose storage contract
/// @dev Access is restricted to governance
contract DataStore is Governable {
    uint256 private constant swV = 1000101;

    // Key-value stores
    mapping(bytes32 => uint256) public uintValues;
    mapping(bytes32 => int256) public intValues;
    mapping(bytes32 => address) public addressValues;
    mapping(bytes32 => bytes32) public dataValues;
    mapping(bytes32 => bool) public boolValues;
    mapping(bytes32 => string) public stringValues;

    constructor() Governable() {}

    /// @param key The key for the record
    /// @param value value to store
    /// @param overwrite Overwrites existing value if set to true
    function setUint(string calldata key, uint256 value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || uintValues[hash] == 0) {
            uintValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getUint(string calldata key) external view returns (uint256) {
        return uintValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value value to store
    /// @param overwrite Overwrites existing value if set to true
    function setInt(string calldata key, int256 value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || intValues[hash] == 0) {
            intValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getInt(string calldata key) external view returns (int256) {
        return intValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value address to store
    /// @param overwrite Overwrites existing value if set to true
    function setAddress(string calldata key, address value, bool overwrite) external onlyGov returns (bool) {
        bytes32 hash = getHash(key);
        if (overwrite || addressValues[hash] == address(0)) {
            addressValues[hash] = value;
            return true;
        }
        return false;
    }

    /// @param key The key for the record
    function getAddress(string calldata key) external view returns (address) {
        return addressValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value byte value to store
    function setData(string calldata key, bytes32 value) external onlyGov returns (bool) {
        dataValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getData(string calldata key) external view returns (bytes32) {
        return dataValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value value to store (true / false)
    function setBool(string calldata key, bool value) external onlyGov returns (bool) {
        boolValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getBool(string calldata key) external view returns (bool) {
        return boolValues[getHash(key)];
    }

    /// @param key The key for the record
    /// @param value string to store
    function setString(string calldata key, string calldata value) external onlyGov returns (bool) {
        stringValues[getHash(key)] = value;
        return true;
    }

    /// @param key The key for the record
    function getString(string calldata key) external view returns (string memory) {
        return stringValues[getHash(key)];
    }

    /// @param key string to hash
    function getHash(string memory key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../utils/Roles.sol";

/// @title PoolStore
/// @notice Persistent storage for Pool.sol
contract PoolStore is Roles {
    uint256 private constant swV = 1000101;
    // Libraries
    using SafeERC20 for IERC20;

    // Constants
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant MAX_POOL_WITHDRAWAL_FEE = 500; // in bps = 5%

    // State variables
    uint256 public feeShare = 500;
    uint256 public bufferPayoutPeriod = 7 days;

    mapping(address => uint256) private clpSupply; // asset => clp supply
    mapping(address => uint256) private balances; // asset => balance
    mapping(address => mapping(address => uint256)) private userClpBalances; // asset => account => clp amount

    mapping(address => uint256) private bufferBalances; // asset => balance
    mapping(address => uint256) private lastPaid; // asset => timestamp

    mapping(address => uint256) private withdrawalFees; // asset => bps

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Set pool fee
    /// @dev Only callable by governance
    /// @param bps fee share in bps
    function setFeeShare(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, "!bps");
        feeShare = bps;
    }

    /// @notice Set buffer payout period
    /// @dev Only callable by governance
    /// @param period Buffer payout period in seconds, default is 7 days (604800 seconds)
    function setBufferPayoutPeriod(uint256 period) external onlyGov {
        require(period > 0, "!period");
        bufferPayoutPeriod = period;
    }

    /// @notice Set pool withdrawal fee
    /// @dev Only callable by governance
    /// @param asset Pool asset, e.g. address(0) for ETH
    /// @param bps Withdrawal fee in bps
    function setWithdrawalFee(address asset, uint256 bps) external onlyGov {
        require(bps <= MAX_POOL_WITHDRAWAL_FEE, "!pool-withdrawal-fee");
        withdrawalFees[asset] = bps;
    }

    /// @notice Increments pool balance
    /// @dev Only callable by other protocol contracts
    function incrementBalance(address asset, uint256 amount) external onlyContract {
        balances[asset] += amount;
    }

    /// @notice Decrements pool balance
    /// @dev Only callable by other protocol contracts
    function decrementBalance(address asset, uint256 amount) external onlyContract {
        balances[asset] = balances[asset] <= amount ? 0 : balances[asset] - amount;
    }

    /// @notice Increments buffer balance
    /// @dev Only callable by other protocol contracts
    function incrementBufferBalance(address asset, uint256 amount) external onlyContract {
        bufferBalances[asset] += amount;
    }

    /// @notice Decrements buffer balance
    /// @dev Only callable by other protocol contracts
    function decrementBufferBalance(address asset, uint256 amount) external onlyContract {
        bufferBalances[asset] = bufferBalances[asset] <= amount ? 0 : bufferBalances[asset] - amount;
    }

    /// @notice Updates `lastPaid`
    /// @dev Only callable by other protocol contracts
    function setLastPaid(address asset, uint256 timestamp) external onlyContract {
        lastPaid[asset] = timestamp;
    }

    /// @notice Increments `clpSupply` and `userClpBalances`
    /// @dev Only callable by other protocol contracts
    function incrementUserClpBalance(address asset, address user, uint256 amount) external onlyContract {
        clpSupply[asset] += amount;

        unchecked {
            // Overflow not possible: balance + amount is at most clpSupply + amount, which is checked above.
            userClpBalances[asset][user] += amount;
        }
    }

    /// @notice Decrements `clpSupply` and `userClpBalances`
    /// @dev Only callable by other protocol contracts
    function decrementUserClpBalance(address asset, address user, uint256 amount) external onlyContract {
        clpSupply[asset] = clpSupply[asset] <= amount ? 0 : clpSupply[asset] - amount;

        userClpBalances[asset][user] =
            userClpBalances[asset][user] <= amount ? 0 : userClpBalances[asset][user] - amount;
    }

    /// @notice Returns withdrawal fee of `asset` from pool
    function getWithdrawalFee(address asset) external view returns (uint256) {
        return withdrawalFees[asset];
    }

    /// @notice Returns the sum of buffer and pool balance of `asset`
    function getAvailable(address asset) external view returns (uint256) {
        return balances[asset] + bufferBalances[asset];
    }

    /// @notice Returns amount of `asset` in pool
    function getBalance(address asset) external view returns (uint256) {
        return balances[asset];
    }

    /// @notice Returns amount of `asset` in buffer
    function getBufferBalance(address asset) external view returns (uint256) {
        return bufferBalances[asset];
    }

    /// @notice Returns pool balances of `_assets`
    function getBalances(address[] calldata _assets) external view returns (uint256[] memory) {
        uint256 length = _assets.length;
        uint256[] memory _balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = balances[_assets[i]];
        }

        return _balances;
    }

    /// @notice Returns buffer balances of `_assets`
    function getBufferBalances(address[] calldata _assets) external view returns (uint256[] memory) {
        uint256 length = _assets.length;
        uint256[] memory _balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = bufferBalances[_assets[i]];
        }

        return _balances;
    }

    /// @notice Returns last time pool was paid
    function getLastPaid(address asset) external view returns (uint256) {
        return lastPaid[asset];
    }

    /// @notice Returns `_assets` balance of `account`
    function getUserBalances(address[] calldata _assets, address account) external view returns (uint256[] memory) {
        uint256 length = _assets.length;
        uint256[] memory _balances = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = getUserBalance(_assets[i], account);
        }

        return _balances;
    }

    /// @notice Returns `asset` balance of `account`
    function getUserBalance(address asset, address account) public view returns (uint256) {
        if (clpSupply[asset] == 0) return 0;
        return (userClpBalances[asset][account] * balances[asset]) / clpSupply[asset];
    }

    /// @notice Returns total amount of CLP for `asset`
    function getClpSupply(address asset) public view returns (uint256) {
        return clpSupply[asset];
    }

    /// @notice Returns amount of CLP of `account` for `asset`
    function getUserClpBalance(address asset, address account) public view returns (uint256) {
        return userClpBalances[asset][account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/Roles.sol";

/// @title PositionStore
/// @notice Persistent storage for Positions.sol
contract PositionStore is Roles {
    uint256 private constant swV = 1000101;
    // Libraries
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Position struct
    struct Position {
        address user; // User that submitted the position
        address asset; // Asset address, e.g. address(0) for ETH
        string market; // Market this position was submitted on
        bool isLong; // Wether the position is long or short
        uint256 size; // The position's size (margin * leverage)
        uint256 margin; // Collateral tied to this position. In wei
        int256 fundingTracker; // Market funding rate tracker
        uint256 price; // The position's average execution price
        uint256 timestamp; // Time at which the position was created
    }

    // Constants
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant MAX_KEEPER_FEE_SHARE = 2000; // 20%

    // State variables
    uint256 public removeMarginBuffer = 1000;
    uint256 public keeperFeeShare = 500;

    // Mappings
    mapping(address => mapping(string => uint256)) private OI; // open interest. market => asset => amount
    mapping(address => mapping(string => uint256)) private OILong; // open interest. market => asset => amount
    mapping(address => mapping(string => uint256)) private OIShort; // open interest. market => asset => amount]

    mapping(bytes32 => Position) private positions; // key = asset,user,market
    EnumerableSet.Bytes32Set private positionKeys; // [position keys..]
    mapping(address => EnumerableSet.Bytes32Set) private positionKeysForUser; // user => [position keys..]

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Updates `removeMarginBuffer`
    /// @dev Only callable by governance
    /// @param bps new `removeMarginBuffer` in bps
    function setRemoveMarginBuffer(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, "!bps");
        removeMarginBuffer = bps;
    }

    /// @notice Sets keeper fee share
    /// @dev Only callable by governance
    /// @param bps new `keeperFeeShare` in bps
    function setKeeperFeeShare(uint256 bps) external onlyGov {
        require(bps <= MAX_KEEPER_FEE_SHARE, "!keeper-fee-share");
        keeperFeeShare = bps;
    }

    /// @notice Adds new position or updates exisiting one
    /// @dev Only callable by other protocol contracts
    /// @param position Position to add/update
    function addOrUpdate(Position memory position) external onlyContract {
        bytes32 key = _getPositionKey(position.user, position.asset, position.market);
        positions[key] = position;
        positionKeysForUser[position.user].add(key);
        positionKeys.add(key);
    }

    /// @notice Removes position
    /// @dev Only callable by other protocol contracts
    function remove(address user, address asset, string calldata market) external onlyContract {
        bytes32 key = _getPositionKey(user, asset, market);
        positionKeysForUser[user].remove(key);
        positionKeys.remove(key);
        delete positions[key];
    }

    /// @notice Increments open interest
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Positions.increasePosition
    function incrementOI(address asset, string calldata market, uint256 amount, bool isLong) external onlyContract {
        OI[asset][market] += amount;
        if (isLong) {
            OILong[asset][market] = OILong[asset][market] + amount;
        } else {
            OIShort[asset][market] += amount;
        }
    }

    /// @notice Decrements open interest
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked whenever a position is closed or decreased
    function decrementOI(address asset, string calldata market, uint256 amount, bool isLong) external onlyContract {
        OI[asset][market] = OI[asset][market] <= amount ? 0 : OI[asset][market] - amount;
        if (isLong) {
            OILong[asset][market] = OILong[asset][market] <= amount ? 0 : OILong[asset][market] - amount;
        } else {
            OIShort[asset][market] = OIShort[asset][market] <= amount ? 0 : OIShort[asset][market] - amount;
        }
    }

    /// @notice Returns open interest of `asset` and `market`
    function getOI(address asset, string calldata market) external view returns (uint256) {
        return OI[asset][market];
    }

    /// @notice Returns open interest of long positions
    function getOILong(address asset, string calldata market) external view returns (uint256) {
        return OILong[asset][market];
    }

    /// @notice Returns open interest of short positions
    function getOIShort(address asset, string calldata market) external view returns (uint256) {
        return OIShort[asset][market];
    }

    /// @notice Returns position of `user`
    /// @param asset Base asset of position
    /// @param market Market this position was submitted on
    function getPosition(address user, address asset, string memory market) public view returns (Position memory) {
        bytes32 key = _getPositionKey(user, asset, market);
        return positions[key];
    }

    /// @notice Returns positions of `users`
    /// @param assets Base assets of positions
    /// @param markets Markets of positions
    function getPositions(address[] calldata users, address[] calldata assets, string[] calldata markets)
        external
        view
        returns (Position[] memory)
    {
        uint256 length = users.length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = getPosition(users[i], assets[i], markets[i]);
        }

        return _positions;
    }

    /// @notice Returns positions
    /// @param keys Position keys
    function getPositions(bytes32[] calldata keys) external view returns (Position[] memory) {
        uint256 length = keys.length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[keys[i]];
        }

        return _positions;
    }

    /// @notice Returns number of positions
    function getPositionCount() external view returns (uint256) {
        return positionKeys.length();
    }

    /// @notice Returns `length` amount of positions starting from `offset`
    function getPositions(uint256 length, uint256 offset) external view returns (Position[] memory) {
        uint256 _length = positionKeys.length();
        if (length > _length) length = _length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = offset; i < length + offset; i++) {
            _positions[i] = positions[positionKeys.at(i)];
        }

        return _positions;
    }

    /// @notice Returns all positions of `user`
    function getUserPositions(address user) external view returns (Position[] memory) {
        uint256 length = positionKeysForUser[user].length();
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[positionKeysForUser[user].at(i)];
        }

        return _positions;
    }

    /// @dev Returns position key by hashing (user, asset, market)
    function _getPositionKey(address user, address asset, string memory market) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, asset, market));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataStore.sol";
import "./PoolStore.sol";
import "./PositionStore.sol";

import "../utils/Roles.sol";

/// @title RiskStore
/// @notice Implementation of risk mitigation measures such as maximum open interest and maximum pool drawdown
contract RiskStore is Roles {
    uint256 private constant swV = 1000101;
    // Constants
    uint256 public constant BPS_DIVIDER = 10000;

    mapping(string => mapping(address => uint256)) private maxOI; // market => asset => amount

    // Pool Risk Measures
    uint256 public poolHourlyDecay = 416; // bps = 4.16% hourly, disappears after 24 hours
    mapping(address => int256) private poolProfitTracker; // asset => amount (amortized)
    mapping(address => uint256) private poolProfitLimit; // asset => bps
    mapping(address => uint256) private poolLastChecked; // asset => timestamp

    // Contracts
    DataStore public DS;

    /// @dev Initialize DataStore address
    constructor(RoleStore rs, DataStore ds) Roles(rs) {
        DS = ds;
    }

    /// @notice Set maximum open interest
    /// @notice Once current open interest exceeds this value, orders are no longer accepted
    /// @dev Only callable by governance
    /// @param market Market to set, e.g. "ETH-USD"
    /// @param asset Address of base asset, e.g. address(0) for ETH
    /// @param amount Max open interest to set
    function setMaxOI(string calldata market, address asset, uint256 amount) external onlyGov {
        require(amount > 0, "!amount");
        maxOI[market][asset] = amount;
    }

    /// @notice Set hourly pool decay
    /// @dev Only callable by governance
    /// @param bps Hourly pool decay in bps
    function setPoolHourlyDecay(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, "!bps");
        poolHourlyDecay = bps;
    }

    /// @notice Set pool profit limit of `asset`
    /// @dev Only callable by governance
    /// @param asset Address of asset, e.g. address(0) for ETH
    /// @param bps Pool profit limit in bps
    function setPoolProfitLimit(address asset, uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, "!bps");
        poolProfitLimit[asset] = bps;
    }

    /// @notice Measures the net loss of a pool over time
    /// @notice Reverts if time-weighted drawdown is higher than the allowed profit limit
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Positions.decreasePosition
    function checkPoolDrawdown(address asset, int256 pnl) external onlyContract {
        // Get available amount of `asset` in the pool (pool balance + buffer balance)
        uint256 poolAvailable = PoolStore(DS.getAddress("PoolStore")).getAvailable(asset);

        // Get profit tracker, pnl > 0 means trader win
        int256 profitTracker = getPoolProfitTracker(asset) + pnl;
        // get profit limit of pool
        uint256 profitLimit = poolProfitLimit[asset];

        // update storage vars
        poolProfitTracker[asset] = profitTracker;
        poolLastChecked[asset] = block.timestamp;

        // return if profit limit or profit tracker is zero / less than zero
        if (profitLimit == 0 || profitTracker <= 0) return;

        // revert if profitTracker > profitLimit * available funds
        require(uint256(profitTracker) < (profitLimit * poolAvailable) / BPS_DIVIDER, "!pool-risk");
    }

    /// @notice Checks if maximum open interest is reached
    /// @param market Market to check, e.g. "ETH-USD"
    /// @param asset Address of base asset, e.g. address(0) for ETH
    function checkMaxOI(address asset, string calldata market, uint256 size) external view {
        uint256 openInterest = PositionStore(DS.getAddress("PositionStore")).getOI(asset, market);
        uint256 _maxOI = maxOI[market][asset];
        if (_maxOI > 0 && openInterest + size > _maxOI) revert("!max-oi");
    }

    /// @notice Get maximum open interest of `market`
    /// @param market Market to check, e.g. "ETH-USD"
    /// @param asset Address of base asset, e.g. address(0) for ETH
    function getMaxOI(string calldata market, address asset) external view returns (uint256) {
        return maxOI[market][asset];
    }

    /// @notice Returns pool profit tracker of `asset`
    /// @dev Amortized every hour by 4.16% unless otherwise set
    function getPoolProfitTracker(address asset) public view returns (int256) {
        int256 profitTracker = poolProfitTracker[asset];
        uint256 lastCheckedHourId = poolLastChecked[asset] / (1 hours);
        uint256 currentHourId = block.timestamp / (1 hours);

        if (currentHourId > lastCheckedHourId) {
            // hours passed since last check
            uint256 hoursPassed = currentHourId - lastCheckedHourId;
            if (hoursPassed >= BPS_DIVIDER / poolHourlyDecay) {
                profitTracker = 0;
            } else {
                // reduce profit tracker by `poolHourlyDecay` for every hour that passed since last check
                for (uint256 i = 0; i < hoursPassed; i++) {
                    profitTracker *= (int256(BPS_DIVIDER) - int256(poolHourlyDecay)) / int256(BPS_DIVIDER);
                }
            }
        }

        return profitTracker;
    }

    /// @notice Returns pool profit limit of `asset`
    function getPoolProfitLimit(address asset) external view returns (uint256) {
        return poolProfitLimit[asset];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/Governable.sol";

/**
 * @title  RoleStore
 * @notice Role-based access control mechanism. Governance can grant and
 *         revoke roles dynamically via {grantRole} and {revokeRole}
 */
contract RoleStore is Governable {
    uint256 private constant swV = 1000101;
    // Libraries
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Set of roles
    EnumerableSet.Bytes32Set internal roles;

    // Role -> address
    mapping(bytes32 => EnumerableSet.AddressSet) internal roleMembers;

    constructor() Governable() {}

    /// @notice Grants `role` to `account`
    /// @dev Only callable by governance
    function grantRole(address account, bytes32 role) external onlyGov {
        // add role if not already present
        if (!roles.contains(role)) roles.add(role);

        require(roleMembers[role].add(account));
    }

    /// @notice Revokes `role` from `account`
    /// @dev Only callable by governance
    function revokeRole(address account, bytes32 role) external onlyGov {
        require(roleMembers[role].remove(account));

        // Remove role if it has no longer any members
        if (roleMembers[role].length() == 0) {
            roles.remove(role);
        }
    }

    /// @notice Returns `true` if `account` has been granted `role`
    function hasRole(address account, bytes32 role) external view returns (bool) {
        return roleMembers[role].contains(account);
    }

    /// @notice Returns number of roles
    function getRoleCount() external view returns (uint256) {
        return roles.length();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Governable
/// @notice Basic access control mechanism, gov has access to certain functions
contract Governable {
    uint256 private constant swV = 1000101;
    address public gov;

    event SetGov(address prevGov, address nextGov);

    /// @dev Initializes the contract setting the deployer address as governance
    constructor() {
        _setGov(msg.sender);
    }

    /// @dev Reverts if called by any account other than gov
    modifier onlyGov() {
        require(msg.sender == gov, "!gov");
        _;
    }

    /// @notice Sets a new governance address
    /// @dev Only callable by governance
    function setGov(address _gov) external onlyGov {
        _setGov(_gov);
    }

    /// @notice Sets a new governance address
    /// @dev Internal function without access restriction
    function _setGov(address _gov) internal {
        address prevGov = gov;
        gov = _gov;
        emit SetGov(prevGov, _gov);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Governable.sol";
import "../stores/RoleStore.sol";

/// @title Roles
/// @notice Role-based access control mechanism via onlyContract modifier
contract Roles is Governable {
    uint256 private constant swV = 1000101;

    bytes32 public constant CONTRACT = keccak256("CONTRACT");

    RoleStore public roleStore;

    /// @dev Initializes roleStore address
    constructor(RoleStore rs) Governable() {
        roleStore = rs;
    }

    /// @dev Reverts if caller address has not the contract role
    modifier onlyContract() {
        require(roleStore.hasRole(msg.sender, CONTRACT), "!contract-role");
        _;
    }
}