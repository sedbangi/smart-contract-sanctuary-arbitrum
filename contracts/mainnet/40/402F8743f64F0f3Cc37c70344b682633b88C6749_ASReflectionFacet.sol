// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// look for the Diamond.sol in the hardhat-deploy/solc_0.8/Diamond.sol
library ASLib {
    error CannotApproveFromZeroAddress();
    error CannotApproveToZeroAddress();
    error CannotTransferFromZeroAddress();
    error CannotTransferToZeroAddress();
    error AmountCannotBeZero();
    error AddressIsExcludedFromFees();
    error AlreadyExcluded(address who);
    error AlreadyIncluded(address who);
    error AmountIsLessThan(uint256 actual, uint256 expected);
    error CannotRecognizeAddressesInExcludedList(address from, address to);

    struct Supply {
        uint256 rSupply;
        uint256 tSupply;
    }

    struct Values {
        RValues r;
        TValues t;
    }

    struct RValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
    }

    struct TValues {
        uint256 tTransferAmount;
        uint256 tFee;
    }

    bytes32 constant AUTOREFLECTIVE_STAKING_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage.autoreflective_staking");
    
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");

    string public constant NAME_PREFIX = "Locus Staking";
    string public constant SYMBOL_PREFIX = "st";

    struct ReferenceTypes {
        mapping (address => uint256) rOwned;
        mapping (address => uint256) tOwned;
        mapping (address => mapping (address => uint256)) allowance;
        EnumerableSet.AddressSet excluded;
    }

    struct Primitives {
        address token;
        uint256 tTotal;
        uint256 rTotal;
        uint256 tFeeTotal;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalStaked;
    }

    struct Storage {
        Primitives p;
        ReferenceTypes rt;
    }

    function get() internal pure returns (Storage storage s) {
        bytes32 position = AUTOREFLECTIVE_STAKING_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../../facetsFramework/diamondBase/facets/BaseFacet.sol";
import "./interfaces/IASReflectionFacet.sol";
import "./interfaces/IASReflectionLoupeFacet.sol";
import "./interfaces/IASEip20Facet.sol";
import "../ASLib.sol";

contract ASReflectionFacet is IASReflectionFacet, BaseFacet {
    using EnumerableSet for EnumerableSet.AddressSet;

    function _mintTo(
        address who,
        uint256 tAmount
    ) external override internalOnly {
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        ASLib.Values memory values = IASReflectionLoupeFacet(address(this))
            ._getValues(tAmount);

        rt.tOwned[address(this)] -= tAmount;
        rt.rOwned[address(this)] -= values.r.rAmount;
        if (rt.excluded.contains(who)) {
            rt.tOwned[who] += values.t.tTransferAmount;
            rt.rOwned[who] += values.r.rTransferAmount;
        } else {
            rt.rOwned[who] += values.r.rTransferAmount;
        }
        _reflectFee(values.r.rFee, values.t.tFee);
        ASLib.get().p.totalStaked += values.t.tTransferAmount;
        IASEip20Facet(address(this))._emitTransferEvent(
            address(0),
            who,
            values.t.tTransferAmount
        );
    }

    function _burnFrom(
        address who,
        uint256 tAmount
    ) external override internalOnly {
        ASLib.Values memory values = IASReflectionLoupeFacet(address(this))
            ._getValues(tAmount);
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        if (rt.excluded.contains(who)) {
            rt.tOwned[who] -= tAmount;
            rt.rOwned[who] -= values.r.rAmount;
            rt.tOwned[address(this)] += tAmount;
            rt.rOwned[address(this)] += values.r.rAmount;
        } else {
            rt.rOwned[who] -= values.r.rTransferAmount;
            rt.rOwned[address(this)] += values.r.rAmount;
            rt.tOwned[address(this)] += values.t.tTransferAmount;
        }
        _reflectFee(values.r.rFee, values.t.tFee);
        
        ASLib.get().p.totalStaked -= values.t.tTransferAmount;
        
        IASEip20Facet(address(this))._emitTransferEvent(
            who,
            address(0),
            values.t.tTransferAmount
        );
    }

    function _updateTotalReflection() external override internalOnly {
        ASLib.Primitives storage p = ASLib.get().p;
        p.rTotal = type(uint256).max - (type(uint256).max % p.tTotal);
    }

    function excludeAccount(address account) external override delegatedOnly {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.OWNER_ROLE);
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        if (!rt.excluded.add(account)) revert ASLib.AlreadyExcluded(account);
        if (rt.rOwned[account] > 0) {
            rt.tOwned[account] = IASReflectionLoupeFacet(address(this))
                .tokenFromReflection(rt.rOwned[account]);
            emit AddressStatus(account, true);
        }
    }

    function includeAccount(address account) external override delegatedOnly {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.OWNER_ROLE);
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        if (!rt.excluded.remove(account)) revert ASLib.AlreadyIncluded(account);
        rt.tOwned[account] = 0;
        emit AddressStatus(account, false);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) external override internalOnly {
        ASLib.Values memory values = IASReflectionLoupeFacet(address(this))
            ._getValues(tAmount);
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        rt.rOwned[sender] -= values.r.rAmount;
        rt.rOwned[recipient] += values.r.rTransferAmount;
        _reflectFee(values.r.rFee, values.t.tFee);
        IASEip20Facet(address(this))._emitTransferEvent(
            sender,
            recipient,
            values.t.tTransferAmount
        );
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) external override internalOnly {
        ASLib.Values memory values = IASReflectionLoupeFacet(address(this))
            ._getValues(tAmount);
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        rt.rOwned[sender] -= values.r.rAmount;
        rt.tOwned[recipient] += values.t.tTransferAmount;
        rt.rOwned[recipient] += values.r.rTransferAmount;
        _reflectFee(values.r.rFee, values.t.tFee);
        IASEip20Facet(address(this))._emitTransferEvent(
            sender,
            recipient,
            values.t.tTransferAmount
        );
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) external override internalOnly {
        ASLib.Values memory values = IASReflectionLoupeFacet(address(this))
            ._getValues(tAmount);
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        rt.tOwned[sender] -= tAmount;
        rt.rOwned[sender] -= values.r.rAmount;
        rt.rOwned[recipient] += values.r.rTransferAmount;
        _reflectFee(values.r.rFee, values.t.tFee);
        IASEip20Facet(address(this))._emitTransferEvent(
            sender,
            recipient,
            values.t.tTransferAmount
        );
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) external override internalOnly {
        ASLib.Values memory values = IASReflectionLoupeFacet(address(this))
            ._getValues(tAmount);
        ASLib.ReferenceTypes storage rt = ASLib.get().rt;
        rt.tOwned[sender] -= tAmount;
        rt.rOwned[sender] -= values.r.rAmount;
        rt.tOwned[recipient] += values.t.tTransferAmount;
        rt.rOwned[recipient] += values.r.rTransferAmount;
        _reflectFee(values.r.rFee, values.t.tFee);
        IASEip20Facet(address(this))._emitTransferEvent(
            sender,
            recipient,
            values.t.tTransferAmount
        );
    }

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        ASLib.Primitives storage p = ASLib.get().p;
        p.rTotal -= rFee;
        p.tFeeTotal += tFee;
        emit FeeReflected(tFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IASEip20Facet is IERC20Metadata {
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    function _emitTransferEvent(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IASReflectionFacet {
    event FeeReflected(uint256 indexed amount);
    event AddressStatus(address indexed who, bool indexed isExcluded);

    function _burnFrom(address who, uint256 tAmount) external;

    function _mintTo(address who, uint256 tAmount) external;

    function excludeAccount(address account) external;

    function includeAccount(address account) external;

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) external;

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) external;

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) external;

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) external;

    function _updateTotalReflection() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../../ASLib.sol";

interface IASReflectionLoupeFacet {
    function isExcluded(address account) external view returns (bool);

    function reflectionFromToken(
        uint256 tAmount,
        bool addTransferFee
    ) external view returns (uint256);

    function tokenFromReflection(
        uint256 rAmount
    ) external view returns (uint256);

    function _getValues(
        uint256 tAmount
    ) external view returns (ASLib.Values memory);

    function _getTValues(
        uint256 tAmount
    ) external view returns (ASLib.TValues memory);

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) external view returns (ASLib.RValues memory);

    function _getRate() external view returns (uint256);

    function _getCurrentSupply() external view returns (ASLib.Supply memory);

    function getPrimitives() external view returns (ASLib.Primitives memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/PausabilityLib.sol";
import "../libraries/InitializerLib.sol";
import "../libraries/RolesManagementLib.sol";

abstract contract BaseFacet is Initializable {
    error DelegatedCallsOnly();
    
    /// @dev An address of the actual contract instance. The original address as part of the context.
    address internal immutable __self = address(this);

    function enforceDelegatedOnly() internal view {
        if (address(this) == __self || !InitializerLib.get().initialized) {
            revert DelegatedCallsOnly();
        }
    }

    /// @dev The body of the modifier is copied into a faucet sources, so to make a small gas
    /// optimization - the modifier uses an internal function call.
    modifier delegatedOnly {
        enforceDelegatedOnly();
        _;
    }

    modifier internalOnly {
        RolesManagementLib.enforceSenderRole(RolesManagementLib.INTERNAL_ROLE);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library InitializerLib {
    error AlreadyInitialized();
    error NotImplemented();

    bytes32 constant INITIALIZER_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage.locus.initializer");

    struct Storage {
        bool initialized;
    }

    function get() internal pure returns (Storage storage s) {
        bytes32 position = INITIALIZER_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function reset() internal {
        get().initialized = false;
    }

    function initialize() internal {
        if (get().initialized) {
            revert AlreadyInitialized();
        } else {
            get().initialized = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library PausabilityLib {
    error OnlyWhenNotPaused();
    
    bytes32 constant PAUSABILITY_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage.locus.pausability");

    struct Storage {
        bool paused;
    }

    function get() internal pure returns (Storage storage s) {
        bytes32 position = PAUSABILITY_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RolesManagementLib {
    event RoleSet(address who, bytes32 role, bool isGrantedOrRevoked);

    error HasNoRole(address who, bytes32 role);
    error HasNoRoles(address who, bytes32[] roles);

    bytes32 constant ROLES_MANAGEMENT_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage.locus.roles");

    // roles to check with EOA
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');

    // A special role - must not be removed.
    bytes32 public constant INTERNAL_ROLE = keccak256('INTERNAL_ROLE');

    // roles to check with smart-contracts
    bytes32 public constant ALLOWED_TOKEN_ROLE = keccak256('ALLOWED_TOKEN_ROLE');

    struct Storage {
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    function get() internal pure returns (Storage storage s) {
        bytes32 position = ROLES_MANAGEMENT_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function enforceRole(address who, bytes32 role) internal view {
        if (role == INTERNAL_ROLE) {
            if (who != address(this)) {
                revert HasNoRole(who, INTERNAL_ROLE);
            }
        } else if (!get().roles[role][who]) {
            revert HasNoRole(who, role);
        }
        
    }

    function hasRole(address who, bytes32 role) internal view returns(bool) {
        return get().roles[role][who];
    }

    function enforceSenderRole(bytes32 role) internal view {
        enforceRole(msg.sender, role);
    }

    function grantRole(address who, bytes32 role) internal {
        get().roles[role][who] = true; 
        emit RoleSet(who, role, true);
    }

    function revokeRole(address who, bytes32 role) internal {
        get().roles[role][who] = false; 
        emit RoleSet(who, role, false);
    }

    function enforceEitherOfRoles(address who, bytes32[] memory roles) internal view {
        bool result;
        for (uint256 i = 0; i < roles.length; i++) {
            if (roles[i] == INTERNAL_ROLE) {
                result = result || who == address(this);
            } else {
                result = result || get().roles[roles[i]][who];
            }
        }
        if (!result) {
            revert HasNoRoles(who, roles);
        }
    }

    function enforceSenderEitherOfRoles(bytes32[] memory roles) internal view {
        enforceEitherOfRoles(msg.sender, roles);
    }
}