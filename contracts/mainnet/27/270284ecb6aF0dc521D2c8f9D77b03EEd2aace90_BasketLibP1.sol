// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20PermitUpgradeable.sol";

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
interface IERC20PermitUpgradeable {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToUintMap storage map, uint256 key, string memory errorMessage) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/Fixed.sol";
import "./IMain.sol";
import "./IRewardable.sol";

// Not used directly in the IAsset interface, but used by many consumers to save stack space
struct Price {
    uint192 low; // {UoA/tok}
    uint192 high; // {UoA/tok}
}

/**
 * @title IAsset
 * @notice Supertype. Any token that interacts with our system must be wrapped in an asset,
 * whether it is used as RToken backing or not. Any token that can report a price in the UoA
 * is eligible to be an asset.
 */
interface IAsset is IRewardable {
    /// Refresh saved price
    /// The Reserve protocol calls this at least once per transaction, before relying on
    /// the Asset's other functions.
    /// @dev Called immediately after deployment, before use
    function refresh() external;

    /// Should not revert
    /// low should be nonzero if the asset could be worth selling
    /// @return low {UoA/tok} The lower end of the price estimate
    /// @return high {UoA/tok} The upper end of the price estimate
    function price() external view returns (uint192 low, uint192 high);

    /// Should not revert
    /// lotLow should be nonzero when the asset might be worth selling
    /// @dev Deprecated. Phased out in 3.1.0, but left on interface for backwards compatibility
    /// @return lotLow {UoA/tok} The lower end of the lot price estimate
    /// @return lotHigh {UoA/tok} The upper end of the lot price estimate
    function lotPrice() external view returns (uint192 lotLow, uint192 lotHigh);

    /// @return {tok} The balance of the ERC20 in whole tokens
    function bal(address account) external view returns (uint192);

    /// @return The ERC20 contract of the token with decimals() available
    function erc20() external view returns (IERC20Metadata);

    /// @return The number of decimals in the ERC20; just for gas optimization
    function erc20Decimals() external view returns (uint8);

    /// @return If the asset is an instance of ICollateral or not
    function isCollateral() external view returns (bool);

    /// @return {UoA} The max trade volume, in UoA
    function maxTradeVolume() external view returns (uint192);

    /// @return {s} The timestamp of the last refresh() that saved prices
    function lastSave() external view returns (uint48);
}

// Used only in Testing. Strictly speaking an Asset does not need to adhere to this interface
interface TestIAsset is IAsset {
    /// @return The address of the chainlink feed
    function chainlinkFeed() external view returns (AggregatorV3Interface);

    /// {1} The max % deviation allowed by the oracle
    function oracleError() external view returns (uint192);

    /// @return {s} Seconds that an oracle value is considered valid
    function oracleTimeout() external view returns (uint48);

    /// @return {s} The maximum of all oracle timeouts on the plugin
    function maxOracleTimeout() external view returns (uint48);

    /// @return {s} Seconds that the price() should decay over, after stale price
    function priceTimeout() external view returns (uint48);

    /// @return {UoA/tok} The last saved low price
    function savedLowPrice() external view returns (uint192);

    /// @return {UoA/tok} The last saved high price
    function savedHighPrice() external view returns (uint192);
}

/// CollateralStatus must obey a linear ordering. That is:
/// - being DISABLED is worse than being IFFY, or SOUND
/// - being IFFY is worse than being SOUND.
enum CollateralStatus {
    SOUND,
    IFFY, // When a peg is not holding or a chainlink feed is stale
    DISABLED // When the collateral has completely defaulted
}

/// Upgrade-safe maximum operator for CollateralStatus
library CollateralStatusComparator {
    /// @return Whether a is worse than b
    function worseThan(CollateralStatus a, CollateralStatus b) internal pure returns (bool) {
        return uint256(a) > uint256(b);
    }
}

/**
 * @title ICollateral
 * @notice A subtype of Asset that consists of the tokens eligible to back the RToken.
 */
interface ICollateral is IAsset {
    /// Emitted whenever the collateral status is changed
    /// @param newStatus The old CollateralStatus
    /// @param newStatus The updated CollateralStatus
    event CollateralStatusChanged(
        CollateralStatus indexed oldStatus,
        CollateralStatus indexed newStatus
    );

    /// @dev refresh()
    /// Refresh exchange rates and update default status.
    /// VERY IMPORTANT: In any valid implemntation, status() MUST become DISABLED in refresh() if
    /// refPerTok() has ever decreased since last call.

    /// @return The canonical name of this collateral's target unit.
    function targetName() external view returns (bytes32);

    /// @return The status of this collateral asset. (Is it defaulting? Might it soon?)
    function status() external view returns (CollateralStatus);

    // ==== Exchange Rates ====

    /// @return {ref/tok} Quantity of whole reference units per whole collateral tokens
    function refPerTok() external view returns (uint192);

    /// @return {target/ref} Quantity of whole target units per whole reference unit in the peg
    function targetPerRef() external view returns (uint192);
}

// Used only in Testing. Strictly speaking a Collateral does not need to adhere to this interface
interface TestICollateral is TestIAsset, ICollateral {
    /// @return The epoch timestamp when the collateral will default from IFFY to DISABLED
    function whenDefault() external view returns (uint256);

    /// @return The amount of time a collateral must be in IFFY status until being DISABLED
    function delayUntilDefault() external view returns (uint48);

    /// @return The underlying refPerTok, likely not included in all collaterals however.
    function underlyingRefPerTok() external view returns (uint192);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAsset.sol";
import "./IComponent.sol";

/// A serialization of the AssetRegistry to be passed around in the P1 impl for gas optimization
struct Registry {
    IERC20[] erc20s;
    IAsset[] assets;
}

/**
 * @title IAssetRegistry
 * @notice The AssetRegistry is in charge of maintaining the ERC20 tokens eligible
 *   to be handled by the rest of the system. If an asset is in the registry, this means:
 *      1. Its ERC20 contract has been vetted
 *      2. The asset is the only asset for that ERC20
 *      3. The asset can be priced in the UoA, usually via an oracle
 */
interface IAssetRegistry is IComponent {
    /// Emitted when an asset is added to the registry
    /// @param erc20 The ERC20 contract for the asset
    /// @param asset The asset contract added to the registry
    event AssetRegistered(IERC20 indexed erc20, IAsset indexed asset);

    /// Emitted when an asset is removed from the registry
    /// @param erc20 The ERC20 contract for the asset
    /// @param asset The asset contract removed from the registry
    event AssetUnregistered(IERC20 indexed erc20, IAsset indexed asset);

    // Initialization
    function init(IMain main_, IAsset[] memory assets_) external;

    /// Fully refresh all asset state
    /// @custom:refresher
    function refresh() external;

    /// Register `asset`
    /// If either the erc20 address or the asset was already registered, fail
    /// @return true if the erc20 address was not already registered.
    /// @custom:governance
    function register(IAsset asset) external returns (bool);

    /// Register `asset` if and only if its erc20 address is already registered.
    /// If the erc20 address was not registered, revert.
    /// @return swapped If the asset was swapped for a previously-registered asset
    /// @custom:governance
    function swapRegistered(IAsset asset) external returns (bool swapped);

    /// Unregister an asset, requiring that it is already registered
    /// @custom:governance
    function unregister(IAsset asset) external;

    /// @return {s} The timestamp of the last refresh
    function lastRefresh() external view returns (uint48);

    /// @return The corresponding asset for ERC20, or reverts if not registered
    function toAsset(IERC20 erc20) external view returns (IAsset);

    /// @return The corresponding collateral, or reverts if unregistered or not collateral
    function toColl(IERC20 erc20) external view returns (ICollateral);

    /// @return If the ERC20 is registered
    function isRegistered(IERC20 erc20) external view returns (bool);

    /// @return A list of all registered ERC20s
    function erc20s() external view returns (IERC20[] memory);

    /// @return reg The list of registered ERC20s and Assets, in the same order
    function getRegistry() external view returns (Registry memory reg);

    /// @return The number of registered ERC20s
    function size() external view returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAssetRegistry.sol";
import "./IBasketHandler.sol";
import "./IComponent.sol";
import "./IRToken.sol";
import "./IStRSR.sol";
import "./ITrading.sol";

/// Memory struct for RecollateralizationLibP1 + RTokenAsset
/// Struct purposes:
///   1. Configure trading
///   2. Stay under stack limit with fewer vars
///   3. Cache information such as component addresses and basket quantities, to save on gas
struct TradingContext {
    BasketRange basketsHeld; // {BU}
    // basketsHeld.top is the number of partial baskets units held
    // basketsHeld.bottom is the number of full basket units held

    // Components
    IBasketHandler bh;
    IAssetRegistry ar;
    IStRSR stRSR;
    IERC20 rsr;
    IRToken rToken;
    // Gov Vars
    uint192 minTradeVolume; // {UoA}
    uint192 maxTradeSlippage; // {1}
    // Cached values
    uint192[] quantities; // {tok/BU} basket quantities
    uint192[] bals; // {tok} balances in BackingManager + out on trades
}

/**
 * @title IBackingManager
 * @notice The BackingManager handles changes in the ERC20 balances that back an RToken.
 *   - It computes which trades to perform, if any, and initiates these trades with the Broker.
 *     - rebalance()
 *   - If already collateralized, excess assets are transferred to RevenueTraders.
 *     - forwardRevenue(IERC20[] calldata erc20s)
 */
interface IBackingManager is IComponent, ITrading {
    /// Emitted when the trading delay is changed
    /// @param oldVal The old trading delay
    /// @param newVal The new trading delay
    event TradingDelaySet(uint48 oldVal, uint48 newVal);

    /// Emitted when the backing buffer is changed
    /// @param oldVal The old backing buffer
    /// @param newVal The new backing buffer
    event BackingBufferSet(uint192 oldVal, uint192 newVal);

    // Initialization
    function init(
        IMain main_,
        uint48 tradingDelay_,
        uint192 backingBuffer_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) external;

    // Give RToken max allowance over a registered token
    /// @custom:refresher
    /// @custom:interaction
    function grantRTokenAllowance(IERC20) external;

    /// Apply the overall backing policy using the specified TradeKind, taking a haircut if unable
    /// @param kind TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    /// @custom:interaction RCEI
    function rebalance(TradeKind kind) external;

    /// Forward revenue to RevenueTraders; reverts if not fully collateralized
    /// @param erc20s The tokens to forward
    /// @custom:interaction RCEI
    function forwardRevenue(IERC20[] calldata erc20s) external;

    /// Structs for trading
    /// @param basketsHeld The number of baskets held by the BackingManager
    /// @return ctx The TradingContext
    /// @return reg Contents of AssetRegistry.getRegistry()
    function tradingContext(BasketRange memory basketsHeld)
        external
        view
        returns (TradingContext memory ctx, Registry memory reg);
}

interface TestIBackingManager is IBackingManager, TestITrading {
    function tradingDelay() external view returns (uint48);

    function backingBuffer() external view returns (uint192);

    function setTradingDelay(uint48 val) external;

    function setBackingBuffer(uint192 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Fixed.sol";
import "./IAsset.sol";
import "./IComponent.sol";

struct BasketRange {
    uint192 bottom; // {BU}
    uint192 top; // {BU}
}

/**
 * @title IBasketHandler
 * @notice The BasketHandler aims to maintain a reference basket of constant target unit amounts.
 * When a collateral token defaults, a new reference basket of equal target units is set.
 * When _all_ collateral tokens default for a target unit, only then is the basket allowed to fall
 *   in terms of target unit amounts. The basket is considered defaulted in this case.
 */
interface IBasketHandler is IComponent {
    /// Emitted when the prime basket is set
    /// @param erc20s The collateral tokens for the prime basket
    /// @param targetAmts {target/BU} A list of quantities of target unit per basket unit
    /// @param targetNames Each collateral token's targetName
    event PrimeBasketSet(IERC20[] erc20s, uint192[] targetAmts, bytes32[] targetNames);

    /// Emitted when the reference basket is set
    /// @param nonce {basketNonce} The basket nonce
    /// @param erc20s The list of collateral tokens in the reference basket
    /// @param refAmts {ref/BU} The reference amounts of the basket collateral tokens
    /// @param disabled True when the list of erc20s + refAmts may not be correct
    event BasketSet(uint256 indexed nonce, IERC20[] erc20s, uint192[] refAmts, bool disabled);

    /// Emitted when a backup config is set for a target unit
    /// @param targetName The name of the target unit as a bytes32
    /// @param max The max number to use from `erc20s`
    /// @param erc20s The set of backup collateral tokens
    event BackupConfigSet(bytes32 indexed targetName, uint256 max, IERC20[] erc20s);

    /// Emitted when the warmup period is changed
    /// @param oldVal The old warmup period
    /// @param newVal The new warmup period
    event WarmupPeriodSet(uint48 oldVal, uint48 newVal);

    /// Emitted when the status of a basket has changed
    /// @param oldStatus The previous basket status
    /// @param newStatus The new basket status
    event BasketStatusChanged(CollateralStatus oldStatus, CollateralStatus newStatus);

    /// Emitted when the last basket nonce available for redemption is changed
    /// @param oldVal The old value of lastCollateralized
    /// @param newVal The new value of lastCollateralized
    event LastCollateralizedChanged(uint48 oldVal, uint48 newVal);

    // Initialization
    function init(
        IMain main_,
        uint48 warmupPeriod_,
        bool reweightable_
    ) external;

    /// Set the prime basket
    /// For an index RToken (reweightable = true), use forceSetPrimeBasket to skip normalization
    /// @param erc20s The collateral tokens for the new prime basket
    /// @param targetAmts The target amounts (in) {target/BU} for the new prime basket
    ///                   required range: 1e9 values; absolute range irrelevant.
    /// @custom:governance
    function setPrimeBasket(IERC20[] calldata erc20s, uint192[] calldata targetAmts) external;

    /// Set the prime basket without normalizing targetAmts by the UoA of the current basket
    /// Works the same as setPrimeBasket for non-index RTokens (reweightable = false)
    /// @param erc20s The collateral tokens for the new prime basket
    /// @param targetAmts The target amounts (in) {target/BU} for the new prime basket
    ///                   required range: 1e9 values; absolute range irrelevant.
    /// @custom:governance
    function forceSetPrimeBasket(IERC20[] calldata erc20s, uint192[] calldata targetAmts) external;

    /// Set the backup configuration for a given target
    /// @param targetName The name of the target as a bytes32
    /// @param max The maximum number of collateral tokens to use from this target
    ///            Required range: 1-255
    /// @param erc20s A list of ordered backup collateral tokens
    /// @custom:governance
    function setBackupConfig(
        bytes32 targetName,
        uint256 max,
        IERC20[] calldata erc20s
    ) external;

    /// Default the basket in order to schedule a basket refresh
    /// @custom:protected
    function disableBasket() external;

    /// Governance-controlled setter to cause a basket switch explicitly
    /// @custom:governance
    /// @custom:interaction
    function refreshBasket() external;

    /// Track basket status and collateralization changes
    /// @custom:refresher
    function trackStatus() external;

    /// @return If the BackingManager has sufficient collateral to redeem the entire RToken supply
    function fullyCollateralized() external view returns (bool);

    /// @return status The worst CollateralStatus of all collateral in the basket
    function status() external view returns (CollateralStatus status);

    /// @return If the basket is ready to issue and trade
    function isReady() external view returns (bool);

    /// @param erc20 The ERC20 token contract for the asset
    /// @return {tok/BU} The whole token quantity of token in the reference basket
    /// Returns 0 if erc20 is not registered or not in the basket
    /// Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    /// Otherwise, returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantity(IERC20 erc20) external view returns (uint192);

    /// Like quantity(), but unsafe because it DOES NOT CONFIRM THAT THE ASSET IS CORRECT
    /// @param erc20 The ERC20 token contract for the asset
    /// @param asset The registered asset plugin contract for the erc20
    /// @return {tok/BU} The whole token quantity of token in the reference basket
    /// Returns 0 if erc20 is not registered or not in the basket
    /// Returns FIX_MAX (in lieu of +infinity) if Collateral.refPerTok() is 0.
    /// Otherwise, returns (token's basket.refAmts / token's Collateral.refPerTok())
    function quantityUnsafe(IERC20 erc20, IAsset asset) external view returns (uint192);

    /// @param amount {BU}
    /// @return erc20s The addresses of the ERC20 tokens in the reference basket
    /// @return quantities {qTok} The quantity of each ERC20 token to issue `amount` baskets
    function quote(uint192 amount, RoundingMode rounding)
        external
        view
        returns (address[] memory erc20s, uint256[] memory quantities);

    /// Return the redemption value of `amount` BUs for a linear combination of historical baskets
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities that must add up to FIX_ONE
    /// @param amount {BU}
    /// @return erc20s The backing collateral erc20s
    /// @return quantities {qTok} ERC20 token quantities equal to `amount` BUs
    function quoteCustomRedemption(
        uint48[] memory basketNonces,
        uint192[] memory portions,
        uint192 amount
    ) external view returns (address[] memory erc20s, uint256[] memory quantities);

    /// @return top {BU} The number of partial basket units: e.g max(coll.map((c) => c.balAsBUs())
    ///         bottom {BU} The number of whole basket units held by the account
    function basketsHeldBy(address account) external view returns (BasketRange memory);

    /// Should not revert
    /// low should be nonzero when BUs are worth selling
    /// @return low {UoA/BU} The lower end of the price estimate
    /// @return high {UoA/BU} The upper end of the price estimate
    function price() external view returns (uint192 low, uint192 high);

    /// Should not revert
    /// lotLow should be nonzero if a BU could be worth selling
    /// @dev Deprecated. Phased out in 3.1.0, but left on interface for backwards compatibility
    /// @return lotLow {UoA/tok} The lower end of the lot price estimate
    /// @return lotHigh {UoA/tok} The upper end of the lot price estimate
    function lotPrice() external view returns (uint192 lotLow, uint192 lotHigh);

    /// @return timestamp The timestamp at which the basket was last set
    function timestamp() external view returns (uint48);

    /// @return The current basket nonce, regardless of status
    function nonce() external view returns (uint48);
}

interface TestIBasketHandler is IBasketHandler {
    function lastCollateralized() external view returns (uint48);

    function warmupPeriod() external view returns (uint48);

    function setWarmupPeriod(uint48 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IAsset.sol";
import "./IComponent.sol";
import "./IGnosis.sol";
import "./ITrade.sol";

enum TradeKind {
    DUTCH_AUCTION,
    BATCH_AUCTION
}

/// Cache of all prices for a pair to prevent re-lookup
struct TradePrices {
    uint192 sellLow; // {UoA/sellTok} can be 0
    uint192 sellHigh; // {UoA/sellTok} should not be 0
    uint192 buyLow; // {UoA/buyTok} should not be 0
    uint192 buyHigh; // {UoA/buyTok} should not be 0 or FIX_MAX
}

/// The data format that describes a request for trade with the Broker
struct TradeRequest {
    IAsset sell;
    IAsset buy;
    uint256 sellAmount; // {qSellTok}
    uint256 minBuyAmount; // {qBuyTok}
}

/**
 * @title IBroker
 * @notice The Broker deploys oneshot Trade contracts for Traders and monitors
 *   the continued proper functioning of trading platforms.
 */
interface IBroker is IComponent {
    event GnosisSet(IGnosis oldVal, IGnosis newVal);
    event BatchTradeImplementationSet(ITrade oldVal, ITrade newVal);
    event DutchTradeImplementationSet(ITrade oldVal, ITrade newVal);
    event BatchAuctionLengthSet(uint48 oldVal, uint48 newVal);
    event DutchAuctionLengthSet(uint48 oldVal, uint48 newVal);
    event BatchTradeDisabledSet(bool prevVal, bool newVal);
    event DutchTradeDisabledSet(IERC20Metadata indexed erc20, bool prevVal, bool newVal);

    // Initialization
    function init(
        IMain main_,
        IGnosis gnosis_,
        ITrade batchTradeImplemention_,
        uint48 batchAuctionLength_,
        ITrade dutchTradeImplemention_,
        uint48 dutchAuctionLength_
    ) external;

    /// Request a trade from the broker
    /// @dev Requires setting an allowance in advance
    /// @custom:interaction
    function openTrade(
        TradeKind kind,
        TradeRequest memory req,
        TradePrices memory prices
    ) external returns (ITrade);

    /// Only callable by one of the trading contracts the broker deploys
    function reportViolation() external;

    function batchTradeDisabled() external view returns (bool);

    function dutchTradeDisabled(IERC20Metadata erc20) external view returns (bool);
}

interface TestIBroker is IBroker {
    function gnosis() external view returns (IGnosis);

    function batchTradeImplementation() external view returns (ITrade);

    function dutchTradeImplementation() external view returns (ITrade);

    function batchAuctionLength() external view returns (uint48);

    function dutchAuctionLength() external view returns (uint48);

    function setGnosis(IGnosis newGnosis) external;

    function setBatchTradeImplementation(ITrade newTradeImplementation) external;

    function setBatchAuctionLength(uint48 newAuctionLength) external;

    function setDutchTradeImplementation(ITrade newTradeImplementation) external;

    function setDutchAuctionLength(uint48 newAuctionLength) external;

    function enableBatchTrade() external;

    function enableDutchTrade(IERC20Metadata erc20) external;

    // only present on pre-3.0.0 Brokers; used by EasyAuction regression test
    function disabled() external view returns (bool);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./IMain.sol";
import "./IVersioned.sol";

/**
 * @title IComponent
 * @notice A Component is the central building block of all our system contracts. Components
 *   contain important state that must be migrated during upgrades, and they delegate
 *   their ownership to Main's owner.
 */
interface IComponent is IVersioned {
    function main() external view returns (IMain);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IComponent.sol";

uint256 constant MAX_DISTRIBUTION = 1e4; // 10,000
uint8 constant MAX_DESTINATIONS = 100; // maximum number of RevenueShare destinations

struct RevenueShare {
    uint16 rTokenDist; // {revShare} A value between [0, 10,000]
    uint16 rsrDist; // {revShare} A value between [0, 10,000]
}

/// Assumes no more than 100 independent distributions.
struct RevenueTotals {
    uint24 rTokenTotal; // {revShare}
    uint24 rsrTotal; // {revShare}
}

/**
 * @title IDistributor
 * @notice The Distributor Component maintains a revenue distribution table that dictates
 *   how to divide revenue across the Furnace, StRSR, and any other destinations.
 */
interface IDistributor is IComponent {
    /// Emitted when a distribution is set
    /// @param dest The address set to receive the distribution
    /// @param rTokenDist The distribution of RToken that should go to `dest`
    /// @param rsrDist The distribution of RSR that should go to `dest`
    event DistributionSet(address indexed dest, uint16 rTokenDist, uint16 rsrDist);

    /// Emitted when revenue is distributed
    /// @param erc20 The token being distributed, either RSR or the RToken itself
    /// @param source The address providing the revenue
    /// @param amount The amount of the revenue
    event RevenueDistributed(IERC20 indexed erc20, address indexed source, uint256 amount);

    // Initialization
    function init(IMain main_, RevenueShare memory dist) external;

    /// @custom:governance
    function setDistribution(address dest, RevenueShare memory share) external;

    /// Distribute the `erc20` token across all revenue destinations
    /// Only callable by RevenueTraders
    /// @custom:protected
    function distribute(IERC20 erc20, uint256 amount) external;

    /// @return revTotals The total of all  destinations
    function totals() external view returns (RevenueTotals memory revTotals);
}

interface TestIDistributor is IDistributor {
    // solhint-disable-next-line func-name-mixedcase
    function FURNACE() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function ST_RSR() external view returns (address);

    /// @return rTokenDist The RToken distribution for the address
    /// @return rsrDist The RSR distribution for the address
    function distribution(address) external view returns (uint16 rTokenDist, uint16 rsrDist);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "../libraries/Fixed.sol";
import "./IComponent.sol";

/**
 * @title IFurnace
 * @notice A helper contract to burn RTokens slowly and permisionlessly.
 */
interface IFurnace is IComponent {
    // Initialization
    function init(IMain main_, uint192 ratio_) external;

    /// Emitted when the melting ratio is changed
    /// @param oldRatio The old ratio
    /// @param newRatio The new ratio
    event RatioSet(uint192 oldRatio, uint192 newRatio);

    function ratio() external view returns (uint192);

    ///    Needed value range: [0, 1], granularity 1e-9
    /// @custom:governance
    function setRatio(uint192) external;

    /// Performs any RToken melting that has vested since the last payout.
    /// @custom:refresher
    function melt() external;
}

interface TestIFurnace is IFurnace {
    function lastPayout() external view returns (uint256);

    function lastPayoutBal() external view returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct GnosisAuctionData {
    IERC20 auctioningToken;
    IERC20 biddingToken;
    uint256 orderCancellationEndDate;
    uint256 auctionEndDate;
    bytes32 initialAuctionOrder;
    uint256 minimumBiddingAmountPerOrder;
    uint256 interimSumBidAmount;
    bytes32 interimOrder;
    bytes32 clearingPriceOrder;
    uint96 volumeClearingPriceOrder;
    bool minFundingThresholdNotReached;
    bool isAtomicClosureAllowed;
    uint256 feeNumerator;
    uint256 minFundingThreshold;
}

/// The relevant portion of the interface of the live Gnosis EasyAuction contract
/// https://github.com/gnosis/ido-contracts/blob/main/contracts/EasyAuction.sol
interface IGnosis {
    function initiateAuction(
        IERC20 auctioningToken,
        IERC20 biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 auctionedSellAmount,
        uint96 minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256 auctionId);

    function auctionData(uint256 auctionId) external view returns (GnosisAuctionData memory);

    /// @param auctionId The external auction id
    /// @dev See here for decoding: https://git.io/JMang
    /// @return encodedOrder The order, encoded in a bytes 32
    function settleAuction(uint256 auctionId) external returns (bytes32 encodedOrder);

    /// @return The numerator over a 1000-valued denominator
    function feeNumerator() external returns (uint256);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAssetRegistry.sol";
import "./IBasketHandler.sol";
import "./IBackingManager.sol";
import "./IBroker.sol";
import "./IDistributor.sol";
import "./IFurnace.sol";
import "./IGnosis.sol";
import "./IRToken.sol";
import "./IRevenueTrader.sol";
import "./IStRSR.sol";
import "./ITrading.sol";
import "./IVersioned.sol";

// === Auth roles ===

bytes32 constant OWNER = bytes32(bytes("OWNER"));
bytes32 constant SHORT_FREEZER = bytes32(bytes("SHORT_FREEZER"));
bytes32 constant LONG_FREEZER = bytes32(bytes("LONG_FREEZER"));
bytes32 constant PAUSER = bytes32(bytes("PAUSER"));

/**
 * Main is a central hub that maintains a list of Component contracts.
 *
 * Components:
 *   - perform a specific function
 *   - defer auth to Main
 *   - usually (but not always) contain sizeable state that require a proxy
 */
struct Components {
    // Definitely need proxy
    IRToken rToken;
    IStRSR stRSR;
    IAssetRegistry assetRegistry;
    IBasketHandler basketHandler;
    IBackingManager backingManager;
    IDistributor distributor;
    IFurnace furnace;
    IBroker broker;
    IRevenueTrader rsrTrader;
    IRevenueTrader rTokenTrader;
}

interface IAuth is IAccessControlUpgradeable {
    /// Emitted when `unfreezeAt` is changed
    /// @param oldVal The old value of `unfreezeAt`
    /// @param newVal The new value of `unfreezeAt`
    event UnfreezeAtSet(uint48 oldVal, uint48 newVal);

    /// Emitted when the short freeze duration governance param is changed
    /// @param oldDuration The old short freeze duration
    /// @param newDuration The new short freeze duration
    event ShortFreezeDurationSet(uint48 oldDuration, uint48 newDuration);

    /// Emitted when the long freeze duration governance param is changed
    /// @param oldDuration The old long freeze duration
    /// @param newDuration The new long freeze duration
    event LongFreezeDurationSet(uint48 oldDuration, uint48 newDuration);

    /// Emitted when the system is paused or unpaused for trading
    /// @param oldVal The old value of `tradingPaused`
    /// @param newVal The new value of `tradingPaused`
    event TradingPausedSet(bool oldVal, bool newVal);

    /// Emitted when the system is paused or unpaused for issuance
    /// @param oldVal The old value of `issuancePaused`
    /// @param newVal The new value of `issuancePaused`
    event IssuancePausedSet(bool oldVal, bool newVal);

    /**
     * Trading Paused: Disable everything except for OWNER actions, RToken.issue, RToken.redeem,
     * StRSR.stake, and StRSR.payoutRewards
     * Issuance Paused: Disable RToken.issue
     * Frozen: Disable everything except for OWNER actions + StRSR.stake (for governance)
     */

    function tradingPausedOrFrozen() external view returns (bool);

    function issuancePausedOrFrozen() external view returns (bool);

    function frozen() external view returns (bool);

    function shortFreeze() external view returns (uint48);

    function longFreeze() external view returns (uint48);

    // ====

    // onlyRole(OWNER)
    function freezeForever() external;

    // onlyRole(SHORT_FREEZER)
    function freezeShort() external;

    // onlyRole(LONG_FREEZER)
    function freezeLong() external;

    // onlyRole(OWNER)
    function unfreeze() external;

    function pauseTrading() external;

    function unpauseTrading() external;

    function pauseIssuance() external;

    function unpauseIssuance() external;
}

interface IComponentRegistry {
    // === Component setters/getters ===

    event RTokenSet(IRToken indexed oldVal, IRToken indexed newVal);

    function rToken() external view returns (IRToken);

    event StRSRSet(IStRSR oldVal, IStRSR newVal);

    function stRSR() external view returns (IStRSR);

    event AssetRegistrySet(IAssetRegistry oldVal, IAssetRegistry newVal);

    function assetRegistry() external view returns (IAssetRegistry);

    event BasketHandlerSet(IBasketHandler oldVal, IBasketHandler newVal);

    function basketHandler() external view returns (IBasketHandler);

    event BackingManagerSet(IBackingManager oldVal, IBackingManager newVal);

    function backingManager() external view returns (IBackingManager);

    event DistributorSet(IDistributor oldVal, IDistributor newVal);

    function distributor() external view returns (IDistributor);

    event RSRTraderSet(IRevenueTrader oldVal, IRevenueTrader newVal);

    function rsrTrader() external view returns (IRevenueTrader);

    event RTokenTraderSet(IRevenueTrader oldVal, IRevenueTrader newVal);

    function rTokenTrader() external view returns (IRevenueTrader);

    event FurnaceSet(IFurnace oldVal, IFurnace newVal);

    function furnace() external view returns (IFurnace);

    event BrokerSet(IBroker oldVal, IBroker newVal);

    function broker() external view returns (IBroker);
}

/**
 * @title IMain
 * @notice The central hub for the entire system. Maintains components and an owner singleton role
 */
interface IMain is IVersioned, IAuth, IComponentRegistry {
    function poke() external; // not used in p1

    // === Initialization ===

    event MainInitialized();

    function init(
        Components memory components,
        IERC20 rsr_,
        uint48 shortFreeze_,
        uint48 longFreeze_
    ) external;

    function rsr() external view returns (IERC20);
}

interface TestIMain is IMain {
    /// @custom:governance
    function setShortFreeze(uint48) external;

    /// @custom:governance
    function setLongFreeze(uint48) external;

    function shortFreeze() external view returns (uint48);

    function longFreeze() external view returns (uint48);

    function longFreezes(address account) external view returns (uint256);

    function tradingPaused() external view returns (bool);

    function issuancePaused() external view returns (bool);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./IComponent.sol";
import "./ITrading.sol";

/**
 * @title IRevenueTrader
 * @notice The RevenueTrader is an extension of the trading mixin that trades all
 *   assets at its address for a single target asset. There are two runtime instances
 *   of the RevenueTrader, 1 for RToken and 1 for RSR.
 */
interface IRevenueTrader is IComponent, ITrading {
    // Initialization
    function init(
        IMain main_,
        IERC20 tokenToBuy_,
        uint192 maxTradeSlippage_,
        uint192 minTradeVolume_
    ) external;

    /// Distribute tokenToBuy to its destinations
    /// @dev Special-case of manageTokens()
    /// @custom:interaction
    function distributeTokenToBuy() external;

    /// Return registered ERC20s to the BackingManager if distribution for tokenToBuy is 0
    /// @custom:interaction
    function returnTokens(IERC20[] memory erc20s) external;

    /// Process some number of tokens
    /// If the tokenToBuy is included in erc20s, RevenueTrader will distribute it at end of the tx
    /// @param erc20s The ERC20s to manage; can be tokenToBuy or anything registered
    /// @param kinds The kinds of auctions to launch: DUTCH_AUCTION | BATCH_AUCTION
    /// @custom:interaction
    function manageTokens(IERC20[] memory erc20s, TradeKind[] memory kinds) external;

    function tokenToBuy() external view returns (IERC20);
}

// solhint-disable-next-line no-empty-blocks
interface TestIRevenueTrader is IRevenueTrader, TestITrading {

}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IRewardable
 * @notice A simple interface mixin to support claiming of rewards.
 */
interface IRewardable {
    /// Emitted whenever a reward token balance is claimed
    /// @param erc20 The ERC20 of the reward token
    /// @param amount {qTok}
    event RewardsClaimed(IERC20 indexed erc20, uint256 amount);

    /// Claim rewards earned by holding a balance of the ERC20 token
    /// Must emit `RewardsClaimed` for each token rewards are claimed for
    /// @custom:interaction
    function claimRewards() external;
}

/**
 * @title IRewardableComponent
 * @notice A simple interface mixin to support claiming of rewards.
 */
interface IRewardableComponent is IRewardable {
    /// Claim rewards for a single ERC20
    /// Must emit `RewardsClaimed` for each token rewards are claimed for
    /// @custom:interaction
    function claimRewardsSingle(IERC20 erc20) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Fixed.sol";
import "../libraries/Throttle.sol";
import "./IComponent.sol";

/**
 * @title IRToken
 * @notice An RToken is an ERC20 that is permissionlessly issuable/redeemable and tracks an
 *   exchange rate against a single unit: baskets, or {BU} in our type notation.
 */
interface IRToken is IComponent, IERC20MetadataUpgradeable, IERC20PermitUpgradeable {
    /// Emitted when an issuance of RToken occurs, whether it occurs via slow minting or not
    /// @param issuer The address holding collateral tokens
    /// @param recipient The address of the recipient of the RTokens
    /// @param amount The quantity of RToken being issued
    /// @param baskets The corresponding number of baskets
    event Issuance(
        address indexed issuer,
        address indexed recipient,
        uint256 amount,
        uint192 baskets
    );

    /// Emitted when a redemption of RToken occurs
    /// @param redeemer The address holding RToken
    /// @param recipient The address of the account receiving the backing collateral tokens
    /// @param amount The quantity of RToken being redeemed
    /// @param baskets The corresponding number of baskets
    /// @param amount {qRTok} The amount of RTokens canceled
    event Redemption(
        address indexed redeemer,
        address indexed recipient,
        uint256 amount,
        uint192 baskets
    );

    /// Emitted when the number of baskets needed changes
    /// @param oldBasketsNeeded Previous number of baskets units needed
    /// @param newBasketsNeeded New number of basket units needed
    event BasketsNeededChanged(uint192 oldBasketsNeeded, uint192 newBasketsNeeded);

    /// Emitted when RToken is melted, i.e the RToken supply is decreased but basketsNeeded is not
    /// @param amount {qRTok}
    event Melted(uint256 amount);

    /// Emitted when issuance SupplyThrottle params are set
    event IssuanceThrottleSet(ThrottleLib.Params oldVal, ThrottleLib.Params newVal);

    /// Emitted when redemption SupplyThrottle params are set
    event RedemptionThrottleSet(ThrottleLib.Params oldVal, ThrottleLib.Params newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        string memory mandate_,
        ThrottleLib.Params calldata issuanceThrottleParams,
        ThrottleLib.Params calldata redemptionThrottleParams
    ) external;

    /// Issue an RToken with basket collateral
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    function issue(uint256 amount) external;

    /// Issue an RToken with basket collateral, to a particular recipient
    /// @param recipient The address to receive the issued RTokens
    /// @param amount {qRTok} The quantity of RToken to issue
    /// @custom:interaction
    function issueTo(address recipient, uint256 amount) external;

    /// Redeem RToken for basket collateral
    /// @dev Use redeemCustom for non-current baskets
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction
    function redeem(uint256 amount) external;

    /// Redeem RToken for basket collateral to a particular recipient
    /// @dev Use redeemCustom for non-current baskets
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @custom:interaction
    function redeemTo(address recipient, uint256 amount) external;

    /// Redeem RToken for a linear combination of historical baskets, to a particular recipient
    /// @dev Allows partial redemptions up to the minAmounts
    /// @param recipient The address to receive the backing collateral tokens
    /// @param amount {qRTok} The quantity {qRToken} of RToken to redeem
    /// @param basketNonces An array of basket nonces to do redemption from
    /// @param portions {1} An array of Fix quantities that must add up to FIX_ONE
    /// @param expectedERC20sOut An array of ERC20s expected out
    /// @param minAmounts {qTok} The minimum ERC20 quantities the caller should receive
    /// @custom:interaction
    function redeemCustom(
        address recipient,
        uint256 amount,
        uint48[] memory basketNonces,
        uint192[] memory portions,
        address[] memory expectedERC20sOut,
        uint256[] memory minAmounts
    ) external;

    /// Mint an amount of RToken equivalent to baskets BUs, scaling basketsNeeded up
    /// Callable only by BackingManager
    /// @param baskets {BU} The number of baskets to mint RToken for
    /// @custom:protected
    function mint(uint192 baskets) external;

    /// Melt a quantity of RToken from the caller's account
    /// @param amount {qRTok} The amount to be melted
    /// @custom:protected
    function melt(uint256 amount) external;

    /// Burn an amount of RToken from caller's account and scale basketsNeeded down
    /// Callable only by BackingManager
    /// @custom:protected
    function dissolve(uint256 amount) external;

    /// Set the number of baskets needed directly, callable only by the BackingManager
    /// @param basketsNeeded {BU} The number of baskets to target
    ///                      needed range: pretty interesting
    /// @custom:protected
    function setBasketsNeeded(uint192 basketsNeeded) external;

    /// @return {BU} How many baskets are being targeted
    function basketsNeeded() external view returns (uint192);

    /// @return {qRTok} The maximum issuance that can be performed in the current block
    function issuanceAvailable() external view returns (uint256);

    /// @return {qRTok} The maximum redemption that can be performed in the current block
    function redemptionAvailable() external view returns (uint256);
}

interface TestIRToken is IRToken {
    function setIssuanceThrottleParams(ThrottleLib.Params calldata) external;

    function setRedemptionThrottleParams(ThrottleLib.Params calldata) external;

    function issuanceThrottleParams() external view returns (ThrottleLib.Params memory);

    function redemptionThrottleParams() external view returns (ThrottleLib.Params memory);

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);

    function monetizeDonations(IERC20) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "../libraries/Fixed.sol";
import "./IComponent.sol";

/**
 * @title IStRSR
 * @notice An ERC20 token representing shares of the RSR over-collateralization pool.
 *
 * StRSR permits the BackingManager to take RSR in times of need. In return, the BackingManager
 * benefits the StRSR pool with RSR rewards purchased with a portion of its revenue.
 *
 * In the absence of collateral default or losses due to slippage, StRSR should have a
 * monotonically increasing exchange rate with respect to RSR, meaning that over time
 * StRSR is redeemable for more RSR. It is non-rebasing.
 */
interface IStRSR is IERC20MetadataUpgradeable, IERC20PermitUpgradeable, IComponent {
    /// Emitted when RSR is staked
    /// @param era The era at time of staking
    /// @param staker The address of the staker
    /// @param rsrAmount {qRSR} How much RSR was staked
    /// @param stRSRAmount {qStRSR} How much stRSR was minted by this staking
    event Staked(
        uint256 indexed era,
        address indexed staker,
        uint256 rsrAmount,
        uint256 stRSRAmount
    );

    /// Emitted when an unstaking is started
    /// @param draftId The id of the draft.
    /// @param draftEra The era of the draft.
    /// @param staker The address of the unstaker
    ///   The triple (staker, draftEra, draftId) is a unique ID
    /// @param rsrAmount {qRSR} How much RSR this unstaking will be worth, absent seizures
    /// @param stRSRAmount {qStRSR} How much stRSR was burned by this unstaking
    event UnstakingStarted(
        uint256 indexed draftId,
        uint256 indexed draftEra,
        address indexed staker,
        uint256 rsrAmount,
        uint256 stRSRAmount,
        uint256 availableAt
    );

    /// Emitted when RSR is unstaked
    /// @param firstId The beginning of the range of draft IDs withdrawn in this transaction
    /// @param endId The end of range of draft IDs withdrawn in this transaction
    ///   (ID i was withdrawn if firstId <= i < endId)
    /// @param draftEra The era of the draft.
    ///   The triple (staker, draftEra, id) is a unique ID among drafts
    /// @param staker The address of the unstaker

    /// @param rsrAmount {qRSR} How much RSR this unstaking was worth
    event UnstakingCompleted(
        uint256 indexed firstId,
        uint256 indexed endId,
        uint256 draftEra,
        address indexed staker,
        uint256 rsrAmount
    );

    /// Emitted when RSR unstaking is cancelled
    /// @param firstId The beginning of the range of draft IDs withdrawn in this transaction
    /// @param endId The end of range of draft IDs withdrawn in this transaction
    ///   (ID i was withdrawn if firstId <= i < endId)
    /// @param draftEra The era of the draft.
    ///   The triple (staker, draftEra, id) is a unique ID among drafts
    /// @param staker The address of the unstaker

    /// @param rsrAmount {qRSR} How much RSR this unstaking was worth
    event UnstakingCancelled(
        uint256 indexed firstId,
        uint256 indexed endId,
        uint256 draftEra,
        address indexed staker,
        uint256 rsrAmount
    );

    /// Emitted whenever the exchange rate changes
    event ExchangeRateSet(uint192 oldVal, uint192 newVal);

    /// Emitted whenever RSR are paids out
    event RewardsPaid(uint256 rsrAmt);

    /// Emitted if all the RSR in the staking pool is seized and all balances are reset to zero.
    event AllBalancesReset(uint256 indexed newEra);
    /// Emitted if all the RSR in the unstakin pool is seized, and all ongoing unstaking is voided.
    event AllUnstakingReset(uint256 indexed newEra);

    event UnstakingDelaySet(uint48 oldVal, uint48 newVal);
    event RewardRatioSet(uint192 oldVal, uint192 newVal);
    event WithdrawalLeakSet(uint192 oldVal, uint192 newVal);

    // Initialization
    function init(
        IMain main_,
        string memory name_,
        string memory symbol_,
        uint48 unstakingDelay_,
        uint192 rewardRatio_,
        uint192 withdrawalLeak_
    ) external;

    /// Gather and payout rewards from rsrTrader
    /// @custom:interaction
    function payoutRewards() external;

    /// Stakes an RSR `amount` on the corresponding RToken to earn yield and over-collateralized
    /// the system
    /// @param amount {qRSR}
    /// @custom:interaction
    function stake(uint256 amount) external;

    /// Begins a delayed unstaking for `amount` stRSR
    /// @param amount {qStRSR}
    /// @custom:interaction
    function unstake(uint256 amount) external;

    /// Complete delayed unstaking for the account, up to (but not including!) `endId`
    /// @custom:interaction
    function withdraw(address account, uint256 endId) external;

    /// Cancel unstaking for the account, up to (but not including!) `endId`
    /// @custom:interaction
    function cancelUnstake(uint256 endId) external;

    /// Seize RSR, only callable by main.backingManager()
    /// @custom:protected
    function seizeRSR(uint256 amount) external;

    /// Reset all stakes and advance era
    /// @custom:governance
    function resetStakes() external;

    /// Return the maximum valid value of endId such that withdraw(endId) should immediately work
    function endIdForWithdraw(address account) external view returns (uint256 endId);

    /// @return {qRSR/qStRSR} The exchange rate between RSR and StRSR
    function exchangeRate() external view returns (uint192);
}

interface TestIStRSR is IStRSR {
    function rewardRatio() external view returns (uint192);

    function setRewardRatio(uint192) external;

    function unstakingDelay() external view returns (uint48);

    function setUnstakingDelay(uint48) external;

    function withdrawalLeak() external view returns (uint192);

    function setWithdrawalLeak(uint192) external;

    function increaseAllowance(address, uint256) external returns (bool);

    function decreaseAllowance(address, uint256) external returns (bool);

    /// @return {qStRSR/qRSR} The exchange rate between StRSR and RSR
    function exchangeRate() external view returns (uint192);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IBroker.sol";
import "./IVersioned.sol";

enum TradeStatus {
    NOT_STARTED, // before init()
    OPEN, // after init() and before settle()
    CLOSED, // after settle()
    // === Intermediate-tx state ===
    PENDING // during init() or settle() (reentrancy protection)
}

/**
 * Simple generalized trading interface for all Trade contracts to obey
 *
 * Usage: if (canSettle()) settle()
 */
interface ITrade is IVersioned {
    /// Complete the trade and transfer tokens back to the origin trader
    /// @return soldAmt {qSellTok} The quantity of tokens sold
    /// @return boughtAmt {qBuyTok} The quantity of tokens bought
    function settle() external returns (uint256 soldAmt, uint256 boughtAmt);

    function sell() external view returns (IERC20Metadata);

    function buy() external view returns (IERC20Metadata);

    /// @return {tok} The sell amount of the trade, in whole tokens
    function sellAmount() external view returns (uint192);

    /// @return The timestamp at which the trade is projected to become settle-able
    function endTime() external view returns (uint48);

    /// @return True if the trade can be settled
    /// @dev Should be guaranteed to be true eventually as an invariant
    function canSettle() external view returns (bool);

    /// @return TradeKind.DUTCH_AUCTION or TradeKind.BATCH_AUCTION
    // solhint-disable-next-line func-name-mixedcase
    function KIND() external view returns (TradeKind);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Fixed.sol";
import "./IComponent.sol";
import "./ITrade.sol";
import "./IRewardable.sol";

/**
 * @title ITrading
 * @notice Common events and refresher function for all Trading contracts
 */
interface ITrading is IComponent, IRewardableComponent {
    event MaxTradeSlippageSet(uint192 oldVal, uint192 newVal);
    event MinTradeVolumeSet(uint192 oldVal, uint192 newVal);

    /// Emitted when a trade is started
    /// @param trade The one-time-use trade contract that was just deployed
    /// @param sell The token to sell
    /// @param buy The token to buy
    /// @param sellAmount {qSellTok} The quantity of the selling token
    /// @param minBuyAmount {qBuyTok} The minimum quantity of the buying token to accept
    event TradeStarted(
        ITrade indexed trade,
        IERC20 indexed sell,
        IERC20 indexed buy,
        uint256 sellAmount,
        uint256 minBuyAmount
    );

    /// Emitted after a trade ends
    /// @param trade The one-time-use trade contract
    /// @param sell The token to sell
    /// @param buy The token to buy
    /// @param sellAmount {qSellTok} The quantity of the token sold
    /// @param buyAmount {qBuyTok} The quantity of the token bought
    event TradeSettled(
        ITrade indexed trade,
        IERC20 indexed sell,
        IERC20 indexed buy,
        uint256 sellAmount,
        uint256 buyAmount
    );

    /// Settle a single trade, expected to be used with multicall for efficient mass settlement
    /// @param sell The sell token in the trade
    /// @return The trade settled
    /// @custom:refresher
    function settleTrade(IERC20 sell) external returns (ITrade);

    /// @return {%} The maximum trade slippage acceptable
    function maxTradeSlippage() external view returns (uint192);

    /// @return {UoA} The minimum trade volume in UoA, applies to all assets
    function minTradeVolume() external view returns (uint192);

    /// @return The ongoing trade for a sell token, or the zero address
    function trades(IERC20 sell) external view returns (ITrade);

    /// @return The number of ongoing trades open
    function tradesOpen() external view returns (uint48);

    /// @return The number of total trades ever opened
    function tradesNonce() external view returns (uint256);
}

interface TestITrading is ITrading {
    /// @custom:governance
    function setMaxTradeSlippage(uint192 val) external;

    /// @custom:governance
    function setMinTradeVolume(uint192 val) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

interface IVersioned {
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: BlueOak-1.0.0
// solhint-disable func-name-mixedcase func-visibility
// slither-disable-start divide-before-multiply
pragma solidity ^0.8.19;

/// @title FixedPoint, a fixed-point arithmetic library defining the custom type uint192
/// @author Matt Elder <[email protected]> and the Reserve Team <https://reserve.org>

/** The logical type `uint192 ` is a 192 bit value, representing an 18-decimal Fixed-point
    fractional value.  This is what's described in the Solidity documentation as
    "fixed192x18" -- a value represented by 192 bits, that makes 18 digits available to
    the right of the decimal point.

    The range of values that uint192 can represent is about [-1.7e20, 1.7e20].
    Unless a function explicitly says otherwise, it will fail on overflow.
    To be clear, the following should hold:
    toFix(0) == 0
    toFix(1) == 1e18
*/

// Analysis notes:
//   Every function should revert iff its result is out of bounds.
//   Unless otherwise noted, when a rounding mode is given, that mode is applied to
//     a single division that may happen as the last step in the computation.
//   Unless otherwise noted, when a rounding mode is *not* given but is needed, it's FLOOR.
//   For each, we comment:
//   - @return is the value expressed  in "value space", where uint192(1e18) "is" 1.0
//   - as-ints: is the value expressed in "implementation space", where uint192(1e18) "is" 1e18
//   The "@return" expression is suitable for actually using the library
//   The "as-ints" expression is suitable for testing

// A uint value passed to this library was out of bounds for uint192 operations
error UIntOutOfBounds();
bytes32 constant UIntOutofBoundsHash = keccak256(abi.encodeWithSignature("UIntOutOfBounds()"));

// Used by P1 implementation for easier casting
uint256 constant FIX_ONE_256 = 1e18;
uint8 constant FIX_DECIMALS = 18;

// If a particular uint192 is represented by the uint192 n, then the uint192 represents the
// value n/FIX_SCALE.
uint64 constant FIX_SCALE = 1e18;

// FIX_SCALE Squared:
uint128 constant FIX_SCALE_SQ = 1e36;

// The largest integer that can be converted to uint192 .
// This is a bit bigger than 3.1e39
uint192 constant FIX_MAX_INT = type(uint192).max / FIX_SCALE;

uint192 constant FIX_ZERO = 0; // The uint192 representation of zero.
uint192 constant FIX_ONE = FIX_SCALE; // The uint192 representation of one.
uint192 constant FIX_MAX = type(uint192).max; // The largest uint192. (Not an integer!)
uint192 constant FIX_MIN = 0; // The smallest uint192.

/// An enum that describes a rounding approach for converting to ints
enum RoundingMode {
    FLOOR, // Round towards zero
    ROUND, // Round to the nearest int
    CEIL // Round away from zero
}

RoundingMode constant FLOOR = RoundingMode.FLOOR;
RoundingMode constant ROUND = RoundingMode.ROUND;
RoundingMode constant CEIL = RoundingMode.CEIL;

/* @dev Solidity 0.8.x only allows you to change one of type or size per type conversion.
   Thus, all the tedious-looking double conversions like uint256(uint256 (foo))
   See: https://docs.soliditylang.org/en/v0.8.17/080-breaking-changes.html#new-restrictions
 */

/// Explicitly convert a uint256 to a uint192. Revert if the input is out of bounds.
function _safeWrap(uint256 x) pure returns (uint192) {
    if (FIX_MAX < x) revert UIntOutOfBounds();
    return uint192(x);
}

/// Convert a uint to its Fix representation.
/// @return x
// as-ints: x * 1e18
function toFix(uint256 x) pure returns (uint192) {
    return _safeWrap(x * FIX_SCALE);
}

/// Convert a uint to its fixed-point representation, and left-shift its value `shiftLeft`
/// decimal digits.
/// @return x * 10**shiftLeft
// as-ints: x * 10**(shiftLeft + 18)
function shiftl_toFix(uint256 x, int8 shiftLeft) pure returns (uint192) {
    return shiftl_toFix(x, shiftLeft, FLOOR);
}

/// @return x * 10**shiftLeft
// as-ints: x * 10**(shiftLeft + 18)
function shiftl_toFix(
    uint256 x,
    int8 shiftLeft,
    RoundingMode rounding
) pure returns (uint192) {
    // conditions for avoiding overflow
    if (x == 0) return 0;
    if (shiftLeft <= -96) return (rounding == CEIL ? 1 : 0); // 0 < uint.max / 10**77 < 0.5
    if (40 <= shiftLeft) revert UIntOutOfBounds(); // 10**56 < FIX_MAX < 10**57

    shiftLeft += 18;

    uint256 coeff = 10**abs(shiftLeft);
    uint256 shifted = (shiftLeft >= 0) ? x * coeff : _divrnd(x, coeff, rounding);

    return _safeWrap(shifted);
}

/// Divide a uint by a uint192, yielding a uint192
/// This may also fail if the result is MIN_uint192! not fixing this for optimization's sake.
/// @return x / y
// as-ints: x * 1e36 / y
function divFix(uint256 x, uint192 y) pure returns (uint192) {
    // If we didn't have to worry about overflow, we'd just do `return x * 1e36 / _y`
    // If it's safe to do this operation the easy way, do it:
    if (x < uint256(type(uint256).max / FIX_SCALE_SQ)) {
        return _safeWrap(uint256(x * FIX_SCALE_SQ) / y);
    } else {
        return _safeWrap(mulDiv256(x, FIX_SCALE_SQ, y));
    }
}

/// Divide a uint by a uint, yielding a  uint192
/// @return x / y
// as-ints: x * 1e18 / y
function divuu(uint256 x, uint256 y) pure returns (uint192) {
    return _safeWrap(mulDiv256(FIX_SCALE, x, y));
}

/// @return min(x,y)
// as-ints: min(x,y)
function fixMin(uint192 x, uint192 y) pure returns (uint192) {
    return x < y ? x : y;
}

/// @return max(x,y)
// as-ints: max(x,y)
function fixMax(uint192 x, uint192 y) pure returns (uint192) {
    return x > y ? x : y;
}

/// @return absoluteValue(x,y)
// as-ints: absoluteValue(x,y)
function abs(int256 x) pure returns (uint256) {
    return x < 0 ? uint256(-x) : uint256(x);
}

/// Divide two uints, returning a uint, using rounding mode `rounding`.
/// @return numerator / divisor
// as-ints: numerator / divisor
function _divrnd(
    uint256 numerator,
    uint256 divisor,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = numerator / divisor;

    if (rounding == FLOOR) return result;

    if (rounding == ROUND) {
        if (numerator % divisor > (divisor - 1) / 2) {
            result++;
        }
    } else {
        if (numerator % divisor > 0) {
            result++;
        }
    }

    return result;
}

library FixLib {
    /// Again, all arithmetic functions fail if and only if the result is out of bounds.

    /// Convert this fixed-point value to a uint. Round towards zero if needed.
    /// @return x
    // as-ints: x / 1e18
    function toUint(uint192 x) internal pure returns (uint136) {
        return toUint(x, FLOOR);
    }

    /// Convert this uint192 to a uint
    /// @return x
    // as-ints: x / 1e18 with rounding
    function toUint(uint192 x, RoundingMode rounding) internal pure returns (uint136) {
        return uint136(_divrnd(uint256(x), FIX_SCALE, rounding));
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// (Similar to a bitshift but in base 10)
    /// @return x * 10**decimals
    // as-ints: x * 10**decimals
    function shiftl(uint192 x, int8 decimals) internal pure returns (uint192) {
        return shiftl(x, decimals, FLOOR);
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// (Similar to a bitshift but in base 10)
    /// @return x * 10**decimals
    // as-ints: x * 10**decimals
    function shiftl(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // Handle overflow cases
        if (x == 0) return 0;
        if (decimals <= -59) return (rounding == CEIL ? 1 : 0); // 59, because 1e58 > 2**192
        if (58 <= decimals) revert UIntOutOfBounds(); // 58, because x * 1e58 > 2 ** 192 if x != 0

        uint256 coeff = uint256(10**abs(decimals));
        return _safeWrap(decimals >= 0 ? x * coeff : _divrnd(x, coeff, rounding));
    }

    /// Add a uint192 to this uint192
    /// @return x + y
    // as-ints: x + y
    function plus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x + y;
    }

    /// Add a uint to this uint192
    /// @return x + y
    // as-ints: x + y*1e18
    function plusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x + y * FIX_SCALE);
    }

    /// Subtract a uint192 from this uint192
    /// @return x - y
    // as-ints: x - y
    function minus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x - y;
    }

    /// Subtract a uint from this uint192
    /// @return x - y
    // as-ints: x - y*1e18
    function minusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(uint256(x) - uint256(y * FIX_SCALE));
    }

    /// Multiply this uint192 by a uint192
    /// Round truncated values to the nearest available value. 5e-19 rounds away from zero.
    /// @return x * y
    // as-ints: x * y/1e18  [division using ROUND, not FLOOR]
    function mul(uint192 x, uint192 y) internal pure returns (uint192) {
        return mul(x, y, ROUND);
    }

    /// Multiply this uint192 by a uint192
    /// @return x * y
    // as-ints: x * y/1e18
    function mul(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(uint256(x) * uint256(y), FIX_SCALE, rounding));
    }

    /// Multiply this uint192 by a uint
    /// @return x * y
    // as-ints: x * y
    function mulu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x * y);
    }

    /// Divide this uint192 by a uint192
    /// @return x / y
    // as-ints: x * 1e18 / y
    function div(uint192 x, uint192 y) internal pure returns (uint192) {
        return div(x, y, FLOOR);
    }

    /// Divide this uint192 by a uint192
    /// @return x / y
    // as-ints: x * 1e18 / y
    function div(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // Multiply-in FIX_SCALE before dividing by y to preserve precision.
        return _safeWrap(_divrnd(uint256(x) * FIX_SCALE, y, rounding));
    }

    /// Divide this uint192 by a uint
    /// @return x / y
    // as-ints: x / y
    function divu(uint192 x, uint256 y) internal pure returns (uint192) {
        return divu(x, y, FLOOR);
    }

    /// Divide this uint192 by a uint
    /// @return x / y
    // as-ints: x / y
    function divu(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(x, y, rounding));
    }

    uint64 constant FIX_HALF = uint64(FIX_SCALE) / 2;

    /// Raise this uint192 to a nonnegative integer power. Requires that x_ <= FIX_ONE
    /// Gas cost is O(lg(y)), precision is +- 1e-18.
    /// @return x_ ** y
    // as-ints: x_ ** y / 1e18**(y-1)    <- technically correct for y = 0. :D
    function powu(uint192 x_, uint48 y) internal pure returns (uint192) {
        require(x_ <= FIX_ONE);
        if (y == 1) return x_;
        if (x_ == FIX_ONE || y == 0) return FIX_ONE;
        uint256 x = uint256(x_) * FIX_SCALE; // x is D36
        uint256 result = FIX_SCALE_SQ; // result is D36
        while (true) {
            if (y & 1 == 1) result = (result * x + FIX_SCALE_SQ / 2) / FIX_SCALE_SQ;
            if (y <= 1) break;
            y = (y >> 1);
            x = (x * x + FIX_SCALE_SQ / 2) / FIX_SCALE_SQ;
        }
        return _safeWrap(result / FIX_SCALE);
    }

    /// Comparison operators...
    function lt(uint192 x, uint192 y) internal pure returns (bool) {
        return x < y;
    }

    function lte(uint192 x, uint192 y) internal pure returns (bool) {
        return x <= y;
    }

    function gt(uint192 x, uint192 y) internal pure returns (bool) {
        return x > y;
    }

    function gte(uint192 x, uint192 y) internal pure returns (bool) {
        return x >= y;
    }

    function eq(uint192 x, uint192 y) internal pure returns (bool) {
        return x == y;
    }

    function neq(uint192 x, uint192 y) internal pure returns (bool) {
        return x != y;
    }

    /// Return whether or not this uint192 is less than epsilon away from y.
    /// @return |x - y| < epsilon
    // as-ints: |x - y| < epsilon
    function near(
        uint192 x,
        uint192 y,
        uint192 epsilon
    ) internal pure returns (bool) {
        uint192 diff = x <= y ? y - x : x - y;
        return diff < epsilon;
    }

    // ================ Chained Operations ================
    // The operation foo_bar() always means:
    //   Do foo() followed by bar(), and overflow only if the _end_ result doesn't fit in an uint192

    /// Shift this uint192 left by `decimals` digits, and convert to a uint
    /// @return x * 10**decimals
    // as-ints: x * 10**(decimals - 18)
    function shiftl_toUint(uint192 x, int8 decimals) internal pure returns (uint256) {
        return shiftl_toUint(x, decimals, FLOOR);
    }

    /// Shift this uint192 left by `decimals` digits, and convert to a uint.
    /// @return x * 10**decimals
    // as-ints: x * 10**(decimals - 18)
    function shiftl_toUint(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        // Handle overflow cases
        if (x == 0) return 0; // always computable, no matter what decimals is
        if (decimals <= -42) return (rounding == CEIL ? 1 : 0);
        if (96 <= decimals) revert UIntOutOfBounds();

        decimals -= 18; // shift so that toUint happens at the same time.

        uint256 coeff = uint256(10**abs(decimals));
        return decimals >= 0 ? uint256(x * coeff) : uint256(_divrnd(x, coeff, rounding));
    }

    /// Multiply this uint192 by a uint, and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e18
    function mulu_toUint(uint192 x, uint256 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE);
    }

    /// Multiply this uint192 by a uint, and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e18
    function mulu_toUint(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE, rounding);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e36
    function mul_toUint(uint192 x, uint192 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint
    /// @return x * y
    // as-ints: x * y / 1e36
    function mul_toUint(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ, rounding);
    }

    /// Compute x * y / z avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint192) {
        return muluDivu(x, y, z, FLOOR);
    }

    /// Compute x * y / z, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }

    /// Compute x * y / z on Fixes, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z
    ) internal pure returns (uint192) {
        return mulDiv(x, y, z, FLOOR);
    }

    /// Compute x * y / z on Fixes, avoiding intermediate overflow
    /// @dev Only use if you need to avoid overflow; costlier than x * y / z
    /// @return x * y / z
    // as-ints: x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }

    // === safe*() ===

    /// Multiply two fixes, rounding up to FIX_MAX and down to 0
    /// @param a First param to multiply
    /// @param b Second param to multiply
    function safeMul(
        uint192 a,
        uint192 b,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // untestable:
        //      a will never = 0 here because of the check in _price()
        if (a == 0 || b == 0) return 0;
        // untestable:
        //      a = FIX_MAX iff b = 0
        if (a == FIX_MAX || b == FIX_MAX) return FIX_MAX;

        // return FIX_MAX instead of throwing overflow errors.
        unchecked {
            // p and mul *are* Fix values, so have 18 decimals (D18)
            uint256 rawDelta = uint256(b) * a; // {D36} = {D18} * {D18}
            // if we overflowed, then return FIX_MAX
            if (rawDelta / b != a) return FIX_MAX;
            uint256 shiftDelta = rawDelta;

            // add in rounding
            if (rounding == RoundingMode.ROUND) shiftDelta += (FIX_ONE / 2);
            else if (rounding == RoundingMode.CEIL) shiftDelta += FIX_ONE - 1;

            // untestable (here there be dragons):
            // (below explanation is for the ROUND case, but it extends to the FLOOR/CEIL too)
            //          A)  shiftDelta = rawDelta + (FIX_ONE / 2)
            //      shiftDelta overflows if:
            //          B)  shiftDelta = MAX_UINT256 - FIX_ONE/2 + 1
            //              rawDelta + (FIX_ONE/2) = MAX_UINT256 - FIX_ONE/2 + 1
            //              b * a = MAX_UINT256 - FIX_ONE + 1
            //      therefore shiftDelta overflows if:
            //          C)  b = (MAX_UINT256 - FIX_ONE + 1) / a
            //      MAX_UINT256 ~= 1e77 , FIX_MAX ~= 6e57 (6e20 difference in magnitude)
            //      a <= 1e21 (MAX_TARGET_AMT)
            //      a must be between 1e19 & 1e20 in order for b in (C) to be uint192,
            //      but a would have to be < 1e18 in order for (A) to overflow
            if (shiftDelta < rawDelta) return FIX_MAX;

            // return FIX_MAX if return result would truncate
            if (shiftDelta / FIX_ONE > FIX_MAX) return FIX_MAX;

            // return _div(rawDelta, FIX_ONE, rounding)
            return uint192(shiftDelta / FIX_ONE); // {D18} = {D36} / {D18}
        }
    }

    /// Divide two fixes, rounding up to FIX_MAX and down to 0
    /// @param a Numerator
    /// @param b Denominator
    function safeDiv(
        uint192 a,
        uint192 b,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        if (a == 0) return 0;
        if (b == 0) return FIX_MAX;

        uint256 raw = _divrnd(FIX_ONE_256 * a, uint256(b), rounding);
        if (raw >= FIX_MAX) return FIX_MAX;
        return uint192(raw); // don't need _safeWrap
    }

    /// Multiplies two fixes and divide by a third
    /// @param a First to multiply
    /// @param b Second to multiply
    /// @param c Denominator
    function safeMulDiv(
        uint192 a,
        uint192 b,
        uint192 c,
        RoundingMode rounding
    ) internal pure returns (uint192 result) {
        if (a == 0 || b == 0) return 0;
        if (a == FIX_MAX || b == FIX_MAX || c == 0) return FIX_MAX;

        uint256 result_256;
        unchecked {
            (uint256 hi, uint256 lo) = fullMul(a, b);
            if (hi >= c) return FIX_MAX;
            uint256 mm = mulmod(a, b, c);
            if (mm > lo) hi -= 1;
            lo -= mm;
            uint256 pow2 = c & (0 - c);

            uint256 c_256 = uint256(c);
            // Warning: Should not access c below this line

            c_256 /= pow2;
            lo /= pow2;
            lo += hi * ((0 - pow2) / pow2 + 1);
            uint256 r = 1;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            r *= 2 - c_256 * r;
            result_256 = lo * r;

            // Apply rounding
            if (rounding == CEIL) {
                if (mm > 0) result_256 += 1;
            } else if (rounding == ROUND) {
                if (mm > ((c_256 - 1) / 2)) result_256 += 1;
            }
        }

        if (result_256 >= FIX_MAX) return FIX_MAX;
        return uint192(result_256);
    }
}

// ================ a couple pure-uint helpers================
// as-ints comments are omitted here, because they're the same as @return statements, because
// these are all pure uint functions

/// Return (x*y/z), avoiding intermediate overflow.
//  Adapted from sources:
//    https://medium.com/coinmonks/4db014e080b1, https://medium.com/wicketh/afa55870a65
//    and quite a few of the other excellent "Mathemagic" posts from https://medium.com/wicketh
/// @dev Only use if you need to avoid overflow; costlier than x * y / z
/// @return result x * y / z
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z
) pure returns (uint256 result) {
    unchecked {
        (uint256 hi, uint256 lo) = fullMul(x, y);
        if (hi >= z) revert UIntOutOfBounds();
        uint256 mm = mulmod(x, y, z);
        if (mm > lo) hi -= 1;
        lo -= mm;
        uint256 pow2 = z & (0 - z);
        z /= pow2;
        lo /= pow2;
        lo += hi * ((0 - pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        result = lo * r;
    }
}

/// Return (x*y/z), avoiding intermediate overflow.
/// @dev Only use if you need to avoid overflow; costlier than x * y / z
/// @return x * y / z
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = mulDiv256(x, y, z);
    if (rounding == FLOOR) return result;

    uint256 mm = mulmod(x, y, z);
    if (rounding == CEIL) {
        if (mm > 0) result += 1;
    } else {
        if (mm > ((z - 1) / 2)) result += 1; // z should be z-1
    }
    return result;
}

/// Return (x*y) as a "virtual uint512" (lo, hi), representing (hi*2**256 + lo)
///   Adapted from sources:
///   https://medium.com/wicketh/27650fec525d, https://medium.com/coinmonks/4db014e080b1
/// @dev Intended to be internal to this library
/// @return hi (hi, lo) satisfies  hi*(2**256) + lo == x * y
/// @return lo (paired with `hi`)
function fullMul(uint256 x, uint256 y) pure returns (uint256 hi, uint256 lo) {
    unchecked {
        uint256 mm = mulmod(x, y, uint256(0) - uint256(1));
        lo = x * y;
        hi = mm - lo;
        if (mm < lo) hi -= 1;
    }
}
// slither-disable-end divide-before-multiply

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "./Fixed.sol";

uint48 constant ONE_HOUR = 3600; // {seconds/hour}

/**
 * @title ThrottleLib
 * A library that implements a usage throttle that can be used to ensure net issuance
 * or net redemption for an RToken never exceeds some bounds per unit time (hour).
 *
 * It is expected for the RToken to use this library with two instances, one for issuance
 * and one for redemption. Issuance causes the available redemption amount to increase, and
 * visa versa.
 */
library ThrottleLib {
    using FixLib for uint192;

    struct Params {
        uint256 amtRate; // {qRTok/hour} a quantity of RToken hourly; cannot be 0
        uint192 pctRate; // {1/hour} a fraction of RToken hourly; can be 0
    }

    struct Throttle {
        // === Gov params ===
        Params params;
        // === Cache ===
        uint48 lastTimestamp; // {seconds}
        uint256 lastAvailable; // {qRTok}
    }

    /// Reverts if usage amount exceeds available amount
    /// @param supply {qRTok} Total RToken supply beforehand
    /// @param amount {qRTok} Amount of RToken to use. Should be negative for the issuance
    ///   throttle during redemption and for the redemption throttle during issuance.
    function useAvailable(
        Throttle storage throttle,
        uint256 supply,
        int256 amount
    ) internal {
        // untestable: amtRate will always be greater > 0 due to previous validations
        if (throttle.params.amtRate == 0 && throttle.params.pctRate == 0) return;

        // Calculate hourly limit
        uint256 limit = hourlyLimit(throttle, supply); // {qRTok}

        // Calculate available amount before supply change
        uint256 available = currentlyAvailable(throttle, limit);

        // Update throttle.timestamp if available amount changed or at limit
        if (available != throttle.lastAvailable || available == limit) {
            throttle.lastTimestamp = uint48(block.timestamp);
        }

        // Update throttle.lastAvailable
        if (amount > 0) {
            require(uint256(amount) <= available, "supply change throttled");
            available -= uint256(amount);
            // untestable: the final else statement, amount will never be 0
        } else if (amount < 0) {
            available += uint256(-amount);
        }
        throttle.lastAvailable = available;
    }

    /// @param limit {qRTok/hour} The hourly limit
    /// @return available {qRTok} Amount currently available for consumption
    function currentlyAvailable(Throttle storage throttle, uint256 limit)
        internal
        view
        returns (uint256 available)
    {
        uint48 delta = uint48(block.timestamp) - throttle.lastTimestamp; // {seconds}
        available = throttle.lastAvailable + (limit * delta) / ONE_HOUR;
        if (available > limit) available = limit;
    }

    /// @return limit {qRTok} The hourly limit
    function hourlyLimit(Throttle storage throttle, uint256 supply)
        internal
        view
        returns (uint256 limit)
    {
        Params storage params = throttle.params;

        // Calculate hourly limit as: max(params.amtRate, supply.mul(params.pctRate))
        limit = (supply * params.pctRate) / FIX_ONE_256; // {qRTok}
        if (params.amtRate > limit) limit = params.amtRate;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "../../interfaces/IAssetRegistry.sol";
import "../../libraries/Fixed.sol";

// A "valid collateral array" is a IERC20[] array without rtoken/rsr/stRSR/zero address/duplicates

// A BackupConfig value is valid if erc20s is a valid collateral array
struct BackupConfig {
    uint256 max; // Maximum number of backup collateral erc20s to use in a basket
    IERC20[] erc20s; // Ordered list of backup collateral ERC20s
}

// What does a BasketConfig value mean?
//
// erc20s, targetAmts, and targetNames should be interpreted together.
// targetAmts[erc20] is the quantity of target units of erc20 that one BU should hold
// targetNames[erc20] is the name of erc20's target unit
// and then backups[tgt] is the BackupConfig to use for the target unit named tgt
//
// For any valid BasketConfig value:
//     erc20s == keys(targetAmts) == keys(targetNames)
//     if name is in values(targetNames), then backups[name] is a valid BackupConfig
//     erc20s is a valid collateral array
//
// In the meantime, treat erc20s as the canonical set of keys for the target* maps
struct BasketConfig {
    // The collateral erc20s in the prime (explicitly governance-set) basket
    IERC20[] erc20s;
    // Amount of target units per basket for each prime collateral token. {target/BU}
    mapping(IERC20 => uint192) targetAmts;
    // Cached view of the target unit for each erc20 upon setup
    mapping(IERC20 => bytes32) targetNames;
    // Backup configurations, per target name.
    mapping(bytes32 => BackupConfig) backups;
}

/// The type of BasketHandler.basket.
/// Defines a basket unit (BU) in terms of reference amounts of underlying tokens
// Logically, basket is just a mapping of erc20 addresses to ref-unit amounts.
//
// A Basket is valid if erc20s is a valid collateral array and erc20s == keys(refAmts)
struct Basket {
    IERC20[] erc20s; // enumerated keys for refAmts
    mapping(IERC20 => uint192) refAmts; // {ref/BU}
}

/**
 * @title BasketLibP1
 * @notice A helper library that implements a `nextBasket()` function for selecting a reference
 *   basket from the current basket config in combination with collateral statuses/exchange rates.
 */
library BasketLibP1 {
    using BasketLibP1 for Basket;
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using FixLib for uint192;

    // === Basket Algebra ===

    /// Set self to a fresh, empty basket
    // self'.erc20s = [] (empty list)
    // self'.refAmts = {} (empty map)
    function empty(Basket storage self) internal {
        uint256 length = self.erc20s.length;
        for (uint256 i = 0; i < length; ++i) self.refAmts[self.erc20s[i]] = FIX_ZERO;
        delete self.erc20s;
    }

    /// Set `self` equal to `other`
    function setFrom(Basket storage self, Basket storage other) internal {
        empty(self);
        uint256 length = other.erc20s.length;
        for (uint256 i = 0; i < length; ++i) {
            IERC20 _erc20 = other.erc20s[i]; // gas-saver
            self.erc20s.push(_erc20);
            self.refAmts[_erc20] = other.refAmts[_erc20];
        }
    }

    /// Add `weight` to the refAmount of collateral token `tok` in the basket `self`
    // self'.refAmts[tok] = self.refAmts[tok] + weight
    // self'.erc20s is keys(self'.refAmts)
    function add(
        Basket storage self,
        IERC20 tok,
        uint192 weight
    ) internal {
        // untestable:
        //      Both calls to .add() use a weight that has been CEIL rounded in the
        //      Fixed library div function, so weight will never be 0 here.
        //      Additionally, setPrimeBasket() enforces prime-basket tokens must have a weight > 0.
        if (weight == FIX_ZERO) return;
        if (self.refAmts[tok].eq(FIX_ZERO)) {
            self.erc20s.push(tok);
            self.refAmts[tok] = weight;
        } else {
            self.refAmts[tok] = self.refAmts[tok].plus(weight);
        }
    }

    // === Basket Selection ===

    /* nextBasket() computes basket' from three inputs:
       - the basket configuration (config: BasketConfig)
       - the function (isGood: erc20 -> bool), implemented here by goodCollateral()
       - the function (targetPerRef: erc20 -> Fix) implemented by the Collateral plugin

       ==== Definitions ====

       We use e:IERC20 to mean any erc20 token address, and tgt:bytes32 to mean any target name

       // targetWeight(b, e) is the target-unit weight of token e in basket b
       Let targetWeight(b, e) = b.refAmt[e] * targetPerRef(e)

       // backups(tgt) is the list of sound backup tokens we plan to use for target `tgt`.
       Let backups(tgt) = config.backups[tgt].erc20s
                          .filter(isGood)
                          .takeUpTo(config.backups[tgt].max)

       Let primeWt(e) = if e in config.erc20s and isGood(e)
                        then config.targetAmts[e]
                        else 0
       Let backupWt(e) = if e in backups(tgt)
                         then unsoundPrimeWt(tgt) / len(Backups(tgt))
                         else 0
       Let unsoundPrimeWt(tgt) = sum(config.targetAmts[e]
                                     for e in config.erc20s
                                     where config.targetNames[e] == tgt and !isGood(e))

       ==== The correctness condition ====

       If unsoundPrimeWt(tgt) > 0 and len(backups(tgt)) == 0 for some tgt, then return false.
       Else, return true and targetWeight(basket', e) == primeWt(e) + backupWt(e) for all e.

       ==== Higher-level desideratum ====

       The resulting total target weights should equal the configured target weight. Formally:

       let configTargetWeight(tgt) = sum(config.targetAmts[e]
                                         for e in config.erc20s
                                         where targetNames[e] == tgt)

       let targetWeightSum(b, tgt) = sum(targetWeight(b, e)
                                         for e in config.erc20s
                                         where targetNames[e] == tgt)

       Given all that, if nextBasket() returns true, then for all tgt,
           targetWeightSum(basket', tgt) == configTargetWeight(tgt)
    */

    /// Select next reference basket from basket config
    /// Works in-place on `newBasket`
    /// @param targetNames Scratch space for computation; initial value unused
    /// @param newBasket Scratch space for computation; initial value unused
    /// @param config The current basket configuration
    /// @return success result; i.e newBasket can be expected to contain a valid reference basket
    function nextBasket(
        Basket storage newBasket,
        EnumerableSet.Bytes32Set storage targetNames,
        BasketConfig storage config,
        IAssetRegistry assetRegistry
    ) external returns (bool) {
        // targetNames := {}
        while (targetNames.length() > 0) {
            targetNames.remove(targetNames.at(targetNames.length() - 1));
        }

        // newBasket := {}
        newBasket.empty();

        // targetNames = set(values(config.targetNames))
        // (and this stays true; targetNames is not touched again in this function)
        for (uint256 i = 0; i < config.erc20s.length; ++i) {
            targetNames.add(config.targetNames[config.erc20s[i]]);
        }
        uint256 targetsLength = targetNames.length();

        // "good" collateral is collateral with any status() other than DISABLED
        // goodWeights and totalWeights are in index-correspondence with targetNames
        // As such, they're each interepreted as a map from target name -> target weight

        // {target/BU} total target weight of good, prime collateral with target i
        // goodWeights := {}
        uint192[] memory goodWeights = new uint192[](targetsLength);

        // {target/BU} total target weight of all prime collateral with target i
        // totalWeights := {}
        uint192[] memory totalWeights = new uint192[](targetsLength);

        // For each prime collateral token:
        for (uint256 i = 0; i < config.erc20s.length; ++i) {
            // Find collateral's targetName index
            uint256 targetIndex;
            IERC20 _erc20 = config.erc20s[i]; // gas-saver
            for (targetIndex = 0; targetIndex < targetsLength; ++targetIndex) {
                if (targetNames.at(targetIndex) == config.targetNames[_erc20]) break;
            }
            assert(targetIndex < targetsLength);
            // now, targetNames[targetIndex] == config.targetNames[erc20]

            // Set basket weights for good, prime collateral,
            // and accumulate the values of goodWeights and targetWeights
            uint192 targetWeight = config.targetAmts[_erc20];
            totalWeights[targetIndex] = totalWeights[targetIndex].plus(targetWeight);

            if (
                goodCollateral(config.targetNames[_erc20], _erc20, assetRegistry) &&
                targetWeight.gt(FIX_ZERO)
            ) {
                goodWeights[targetIndex] = goodWeights[targetIndex].plus(targetWeight);
                newBasket.add(
                    _erc20,
                    targetWeight.div(
                        // this div is safe: targetPerRef() > 0: goodCollateral check
                        assetRegistry.toColl(_erc20).targetPerRef(),
                        CEIL
                    )
                );
            }
        }

        // Analysis: at this point:
        // for all tgt in target names,
        //   totalWeights(tgt)
        //   = sum(config.targetAmts[e] for e in config.erc20s where targetNames[e] == tgt), and
        //   goodWeights(tgt)
        //   = sum(primeWt(e) for e in config.erc20s where targetNames[e] == tgt)
        // for all e in config.erc20s,
        //   targetWeight(newBasket, e)
        //   = sum(primeWt(e) if goodCollateral(e), else 0)

        // For each tgt in target names, if we still need more weight for tgt then try to add the
        // backup basket for tgt to make up that weight:
        for (uint256 i = 0; i < targetsLength; ++i) {
            if (totalWeights[i].lte(goodWeights[i])) continue; // Don't need any backup weight
            bytes32 _targetName = targetNames.at(i);

            // "tgt" = targetNames[i]
            // Now, unsoundPrimeWt(tgt) > 0

            uint256 size = 0; // backup basket size
            BackupConfig storage backup = config.backups[_targetName];

            // Find the backup basket size: min(backup.max, # of good backup collateral)
            for (uint256 j = 0; j < backup.erc20s.length && size < backup.max; ++j) {
                if (goodCollateral(_targetName, backup.erc20s[j], assetRegistry)) size++;
            }

            // Now, size = len(backups(tgt)). If empty, fail.
            if (size == 0) return false;

            // Set backup basket weights...
            uint256 assigned = 0;

            // Loop: for erc20 in backups(tgt)...
            for (uint256 j = 0; j < backup.erc20s.length && assigned < size; ++j) {
                if (goodCollateral(_targetName, backup.erc20s[j], assetRegistry)) {
                    uint192 backupWeight = totalWeights[i].minus(goodWeights[i]).div(
                        // this div is safe: targetPerRef > 0: goodCollateral check
                        assetRegistry.toColl(backup.erc20s[j]).targetPerRef().mulu(size),
                        CEIL
                    );

                    // Across this .add(), targetWeight(newBasket',erc20)
                    // = targetWeight(newBasket,erc20) + unsoundPrimeWt(tgt) / len(backups(tgt))
                    BasketLibP1.add(newBasket, backup.erc20s[j], backupWeight);
                    assigned++;
                }
            }
            // Here, targetWeight(newBasket, e) = primeWt(e) + backupWt(e) for all e targeting tgt
        }
        // Now we've looped through all values of tgt, so for all e,
        //   targetWeight(newBasket, e) = primeWt(e) + backupWt(e)

        return newBasket.erc20s.length > 0;
    }

    // === Private ===

    /// Good collateral is registered, collateral, SOUND, has the expected targetName,
    /// has nonzero targetPerRef() and refPerTok(), and is not a system token or 0 addr
    function goodCollateral(
        bytes32 targetName,
        IERC20 erc20,
        IAssetRegistry assetRegistry
    ) private view returns (bool) {
        // untestable:
        //      ERC20 is not address(0), validated when setting prime/backup baskets
        if (address(erc20) == address(0)) return false;
        // P1 gas optimization
        // We do not need to check that the ERC20 is not a system token
        // BasketHandlerP1.requireValidCollArray() has been run on all ERC20s already

        try assetRegistry.toColl(erc20) returns (ICollateral coll) {
            return
                targetName == coll.targetName() &&
                coll.status() == CollateralStatus.SOUND &&
                coll.refPerTok() > 0 &&
                coll.targetPerRef() > 0;
        } catch {
            return false;
        }
    }

    // === Contract-size savers ===

    /// Require that erc20s and targetAmts preserve the current config targets
    /// @param _targetAmts Scratch space for computation; assumed to be empty
    function requireConstantConfigTargets(
        IAssetRegistry assetRegistry,
        BasketConfig storage config,
        EnumerableMap.Bytes32ToUintMap storage _targetAmts,
        IERC20[] calldata erc20s,
        uint192[] calldata targetAmts
    ) external {
        // Populate _targetAmts mapping with old basket config
        uint256 len = config.erc20s.length;
        for (uint256 i = 0; i < len; ++i) {
            IERC20 erc20 = config.erc20s[i];
            bytes32 targetName = config.targetNames[erc20];
            (bool contains, uint256 amt) = _targetAmts.tryGet(targetName);
            _targetAmts.set(
                targetName,
                contains ? amt + config.targetAmts[erc20] : config.targetAmts[erc20]
            );
        }

        // Require new basket is exactly equal to old basket, in terms of target amounts
        len = erc20s.length;
        for (uint256 i = 0; i < len; ++i) {
            bytes32 targetName = assetRegistry.toColl(erc20s[i]).targetName();
            (bool contains, uint256 amt) = _targetAmts.tryGet(targetName);
            require(contains && amt >= targetAmts[i], "new target weights");
            if (amt > targetAmts[i]) _targetAmts.set(targetName, amt - targetAmts[i]);
            else _targetAmts.remove(targetName);
        }
        require(_targetAmts.length() == 0, "missing target weights");
    }

    /// Normalize the target amounts to maintain constant UoA value with the current config
    /// @param price {UoA/BU} Price of the reference basket (point estimate)
    /// @return newTargetAmts {target/BU} The new target amounts for the normalized basket
    function normalizeByPrice(
        IAssetRegistry assetRegistry,
        IERC20[] calldata erc20s,
        uint192[] calldata targetAmts,
        uint192 price
    ) external view returns (uint192[] memory newTargetAmts) {
        uint256 len = erc20s.length; // assumes erc20s.length == targetAmts.length

        // Rounding in this function should always be in favor of RToken holders

        // Compute would-be new price
        uint192 newPrice; // {UoA/BU}
        for (uint256 i = 0; i < len; ++i) {
            ICollateral coll = assetRegistry.toColl(erc20s[i]); // reverts if unregistered
            require(coll.status() == CollateralStatus.SOUND, "unsound new collateral");

            (uint192 low, uint192 high) = coll.price(); // {UoA/tok}
            require(low > 0 && high < FIX_MAX, "invalid price");

            // {UoA/BU} += {target/BU} * {UoA/tok} / ({target/ref} * {ref/tok})
            newPrice += targetAmts[i].mulDiv(
                (low + high) / 2,
                coll.targetPerRef().mul(coll.refPerTok(), CEIL),
                FLOOR
            ); // revert on overflow
        }

        // Scale targetAmts by the price ratio
        newTargetAmts = new uint192[](len);
        for (uint256 i = 0; i < len; ++i) {
            // {target/BU} = {target/BU} * {UoA/BU} / {UoA/BU}
            newTargetAmts[i] = targetAmts[i].mulDiv(price, newPrice, CEIL);
        }
    }
}