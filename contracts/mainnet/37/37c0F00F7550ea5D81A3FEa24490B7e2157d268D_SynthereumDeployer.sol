// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
 * ```
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {AccessControlEnumerable} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControlEnumerable {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {IVaultMigration} from './IVaultMigration.sol';

/**
 * @title Provides interface for Public vault
 */
interface IVault is IVaultMigration {
  event Deposit(
    address indexed sender,
    address indexed recipient,
    uint256 netCollateralDeposited,
    uint256 lpTokensOut,
    uint256 rate,
    uint256 discountedRate
  );

  event Withdraw(
    address indexed sender,
    address indexed recipient,
    uint256 lpTokensBurned,
    uint256 netCollateralOut,
    uint256 rate
  );

  event LPActivated(uint256 collateralAmount, uint128 overCollateralization);

  event Donation(address indexed sender, uint256 collateralAmount);

  /**
   * @notice Initialize vault as per OZ Clones pattern
   * @param _lpTokenName name of the LP token representing a share in the vault
   * @param _lpTokenSymbol symbol of the LP token representing a share in the vault
   * @param _pool address of MultiLP pool the vault interacts with
   * @param _overCollateralization over collateral requirement of the vault position in the pool
   * @param _finder The synthereum finder
   */
  function initialize(
    string memory _lpTokenName,
    string memory _lpTokenSymbol,
    address _pool,
    uint128 _overCollateralization,
    ISynthereumFinder _finder
  ) external;

  /**
   * @notice Deposits collateral into the vault
   * @param collateralAmount amount of collateral units
   * @param recipient address receiving the LP token
   * @return lpTokensOut amount of LP tokens received as output
   */
  function deposit(uint256 collateralAmount, address recipient)
    external
    returns (uint256 lpTokensOut);

  /**
   * @notice Withdraw collateral from vault
   * @param lpTokensAmount amount of LP token units
   * @param recipient address receiving the collateral
   * @return collateralOut amount of collateral received
   */
  function withdraw(uint256 lpTokensAmount, address recipient)
    external
    returns (uint256 collateralOut);

  /**
   * @notice Deposits collateral into the vault as a form of donation (no LP token minted)
   * @notice that will be split among existing LPs
   */
  function donate(uint256 collateralAmount) external;

  /**
   * @notice Return current LP vault rate against collateral
   * @return rate Vault rate
   */
  function getRate() external view returns (uint256 rate);

  /**
   * @notice Return current LP vault discounted rate against collateral
   * @return rate Vault rate
   * @return discountedRate Vault discounted rate
   * @return maxCollateralDiscounted max amount of collateral units at discount
   */
  function getDiscountedRate()
    external
    view
    returns (
      uint256 rate,
      uint256 discountedRate,
      uint256 maxCollateralDiscounted
    );

  /**
   * @notice Return the vault version
   * @param version version of the vault
   */
  function getVersion() external view returns (uint256 version);

  /**
   * @notice Return the vault reference pool
   * @param poolAddress address of the pool
   */
  function getPool() external view returns (address poolAddress);

  /**
   * @notice Return the vault collateral token
   * @param collateral collateral token
   */
  function getPoolCollateral() external view returns (address collateral);

  /**
   * @notice Return the vault overcollateralization factor
   * @param overcollateral overcollateralization factor
   */
  function getOvercollateralization()
    external
    view
    returns (uint128 overcollateral);

  /**
   * @notice Return the vault reference pool max spread
   * @param maxSpreadLong max spread for buying
   * @param maxSpreadShort max spread for selling
   */
  function getSpread()
    external
    view
    returns (uint256 maxSpreadLong, uint256 maxSpreadShort);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Provides interface that need to be supported by a public vault during a pool migration
 */
interface IVaultMigration {
  /**
   * @notice Sets an address to be reference pool the vault is using
   * @notice Only vault registry can call this method
   * @param newPool address of the pool
   */
  function setReferencePool(address newPool) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IVault} from './IVault.sol';

/**
 * @title Provides interface for Public vault factory
 */
interface IVaultFactory {
  /**
   * @notice Deploy a public vault
   * @param _lpTokenName name of the LP token representing a share in the vault
   * @param _lpTokenSymbol symbol of the LP token representing a share in the vault
   * @param _pool address of MultiLP pool the vault interacts with
   * @param _overCollateralization over collateral requirement of the vault position in the pool
   * @return vault Deployed vault
   */
  function createVault(
    string memory _lpTokenName,
    string memory _lpTokenSymbol,
    address _pool,
    uint128 _overCollateralization
  ) external returns (IVault vault);

  /**
   * @notice Encodes the initialise call with its parameters
   * @param encodedParams Abi encoded parameters
   * @return encodedCall Bytes encoding of initialise call
   */
  function encodeInitialiseCall(bytes memory encodedParams)
    external
    view
    returns (bytes memory encodedCall);

  /**
   * @notice Returns the address of deployed vault implementation
   * @return implementation deployed vault implementation
   */
  function vaultImplementation() external view returns (address implementation);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {ISynthereumDeployer} from './interfaces/IDeployer.sol';
import {ISynthereumFactoryVersioning} from './interfaces/IFactoryVersioning.sol';
import {ISynthereumRegistry} from './registries/interfaces/IRegistry.sol';
import {ISynthereumManager} from './interfaces/IManager.sol';
import {IDeploymentSignature} from './interfaces/IDeploymentSignature.sol';
import {IMigrationSignature} from './interfaces/IMigrationSignature.sol';
import {ISynthereumDeployment} from '../common/interfaces/IDeployment.sol';
import {SynthereumInterfaces} from './Constants.sol';
import {IAccessControlEnumerable} from '../../@openzeppelin/contracts/access/IAccessControlEnumerable.sol';
import {SynthereumInterfaces, FactoryInterfaces} from './Constants.sol';
import {SynthereumPoolMigrationFrom} from '../synthereum-pool/common/migration/PoolMigrationFrom.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {ReentrancyGuard} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {AccessControlEnumerable} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {IVaultFactory} from '../multiLP-vaults/interfaces/IVaultFactory.sol';
import {IVault} from '../multiLP-vaults/interfaces/IVault.sol';
import {IPublicVaultRegistry} from './registries/interfaces/IPublicVaultRegistry.sol';

contract SynthereumDeployer is
  ISynthereumDeployer,
  ReentrancyGuard,
  AccessControlEnumerable
{
  using Address for address;

  bytes32 private constant ADMIN_ROLE = 0x00;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 private constant MINTER_ROLE = keccak256('Minter');

  bytes32 private constant BURNER_ROLE = keccak256('Burner');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // State variables
  //----------------------------------------

  ISynthereumFinder public immutable synthereumFinder;

  //----------------------------------------
  // Events
  //----------------------------------------

  event PoolDeployed(uint8 indexed poolVersion, address indexed newPool);

  event PoolMigrated(
    address indexed migratedPool,
    uint8 indexed poolVersion,
    address indexed newPool
  );

  event SelfMintingDerivativeDeployed(
    uint8 indexed selfMintingDerivativeVersion,
    address indexed selfMintingDerivative
  );

  event FixedRateDeployed(
    uint8 indexed fixedRateVersion,
    address indexed fixedRate
  );

  event PoolRemoved(address pool);

  event SelfMintingDerivativeRemoved(address selfMintingDerivative);

  event FixedRateRemoved(address fixedRate);

  event PublicVaultDeployed(address vault, address pool);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the SynthereumDeployer contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Maintainer roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Deploy a new pool
   * @param _poolVersion Version of the pool contract to create
   * @param _poolParamsData Input params of pool constructor
   * @return pool Pool contract deployed
   */
  function deployPool(uint8 _poolVersion, bytes calldata _poolParamsData)
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment pool)
  {
    pool = _deployPool(getFactoryVersioning(), _poolVersion, _poolParamsData);
    checkDeployment(pool, _poolVersion);
    setSyntheticTokenRoles(pool);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    poolRegistry.register(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      _poolVersion,
      address(pool)
    );
    emit PoolDeployed(_poolVersion, address(pool));
  }

  /**
   * @notice Migrate storage of an existing pool to e new deployed one
   * @param _migrationPool Pool from which migrate storage
   * @param _poolVersion Version of the pool contract to create
   * @param _migrationParamsData Input params of migration (if needed)
   * @return pool Pool contract created with the storage of the migrated one
   */
  function migratePool(
    SynthereumPoolMigrationFrom _migrationPool,
    uint8 _poolVersion,
    bytes calldata _migrationParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment pool)
  {
    ISynthereumDeployment oldPool;
    (oldPool, pool) = _migratePool(
      getFactoryVersioning(),
      _poolVersion,
      _migrationParamsData
    );
    require(
      address(_migrationPool) == address(oldPool),
      'Wrong migration pool'
    );
    checkDeployment(pool, _poolVersion);
    removeSyntheticTokenRoles(oldPool);
    setSyntheticTokenRoles(pool);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    poolRegistry.register(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      _poolVersion,
      address(pool)
    );
    poolRegistry.unregister(
      oldPool.syntheticTokenSymbol(),
      oldPool.collateralToken(),
      oldPool.version(),
      address(oldPool)
    );
    getPublicVaultRegistry().migrateVaults(address(oldPool), address(pool));

    emit PoolMigrated(address(_migrationPool), _poolVersion, address(pool));
    emit PoolRemoved(address(oldPool));
  }

  /**
   * @notice Remove from the registry an existing pool
   * @param _pool Pool to remove
   */
  function removePool(ISynthereumDeployment _pool)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    _checkMissingRoles(_pool);
    ISynthereumRegistry poolRegistry = getPoolRegistry();
    address pool = address(_pool);
    poolRegistry.unregister(
      _pool.syntheticTokenSymbol(),
      _pool.collateralToken(),
      _pool.version(),
      pool
    );
    emit PoolRemoved(pool);
  }

  /**
   * @notice Deploy a new self minting derivative contract
   * @param _selfMintingDerVersion Version of the self minting derivative contract
   * @param _selfMintingDerParamsData Input params of self minting derivative constructor
   * @return selfMintingDerivative Self minting derivative contract deployed
   */
  function deploySelfMintingDerivative(
    uint8 _selfMintingDerVersion,
    bytes calldata _selfMintingDerParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment selfMintingDerivative)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    selfMintingDerivative = _deploySelfMintingDerivative(
      factoryVersioning,
      _selfMintingDerVersion,
      _selfMintingDerParamsData
    );
    checkDeployment(selfMintingDerivative, _selfMintingDerVersion);
    address tokenCurrency = address(selfMintingDerivative.syntheticToken());
    modifySyntheticTokenRoles(
      tokenCurrency,
      address(selfMintingDerivative),
      true
    );
    ISynthereumRegistry selfMintingRegistry = getSelfMintingRegistry();
    selfMintingRegistry.register(
      selfMintingDerivative.syntheticTokenSymbol(),
      selfMintingDerivative.collateralToken(),
      _selfMintingDerVersion,
      address(selfMintingDerivative)
    );
    emit SelfMintingDerivativeDeployed(
      _selfMintingDerVersion,
      address(selfMintingDerivative)
    );
  }

  /**
   * @notice Remove from the registry an existing self-minting derivativ contract
   * @param _selfMintingDerivative Self-minting derivative to remove
   */
  function removeSelfMintingDerivative(
    ISynthereumDeployment _selfMintingDerivative
  ) external override onlyMaintainer nonReentrant {
    _checkMissingRoles(_selfMintingDerivative);
    ISynthereumRegistry selfMintingRegistry = getSelfMintingRegistry();
    address selfMintingDerivative = address(_selfMintingDerivative);
    selfMintingRegistry.unregister(
      _selfMintingDerivative.syntheticTokenSymbol(),
      _selfMintingDerivative.collateralToken(),
      _selfMintingDerivative.version(),
      selfMintingDerivative
    );
    emit SelfMintingDerivativeRemoved(selfMintingDerivative);
  }

  /**
   * @notice Deploy a fixed rate wrapper
   * @param _fixedRateVersion Version of the fixed rate wrapper contract
   * @param _fixedRateParamsData Input params of the fixed rate wrapper constructor
   * @return fixedRate FixedRate wrapper deployed
   */

  function deployFixedRate(
    uint8 _fixedRateVersion,
    bytes calldata _fixedRateParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumDeployment fixedRate)
  {
    fixedRate = _deployFixedRate(
      getFactoryVersioning(),
      _fixedRateVersion,
      _fixedRateParamsData
    );
    checkDeployment(fixedRate, _fixedRateVersion);
    setSyntheticTokenRoles(fixedRate);
    ISynthereumRegistry fixedRateRegistry = getFixedRateRegistry();
    fixedRateRegistry.register(
      fixedRate.syntheticTokenSymbol(),
      fixedRate.collateralToken(),
      _fixedRateVersion,
      address(fixedRate)
    );
    emit FixedRateDeployed(_fixedRateVersion, address(fixedRate));
  }

  /**
   * @notice Remove from the registry a fixed rate wrapper
   * @param _fixedRate Fixed-rate to remove
   */
  function removeFixedRate(ISynthereumDeployment _fixedRate)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    _checkMissingRoles(_fixedRate);
    ISynthereumRegistry fixedRateRegistry = getFixedRateRegistry();
    address fixedRate = address(_fixedRate);
    fixedRateRegistry.unregister(
      _fixedRate.syntheticTokenSymbol(),
      _fixedRate.collateralToken(),
      _fixedRate.version(),
      fixedRate
    );
    emit FixedRateRemoved(fixedRate);
  }

  /**
   * @notice Deploy a public vault
   * @param _lpTokenName name of the LP token representing a share in the vault
   * @param _lpTokenSymbol symbol of the LP token representing a share in the vault
   * @param _pool address of MultiLP pool the vault interacts with
   * @param _overCollateralization over collateral requirement of the vault position in the pool
   * @return vault Deployed vault
   */
  function deployPublicVault(
    string memory _lpTokenName,
    string memory _lpTokenSymbol,
    address _pool,
    uint128 _overCollateralization
  ) external override onlyMaintainer nonReentrant returns (IVault vault) {
    IVaultFactory vaultFactory = IVaultFactory(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.VaultFactory
      )
    );

    vault = vaultFactory.createVault(
      _lpTokenName,
      _lpTokenSymbol,
      _pool,
      _overCollateralization
    );

    // register vault
    IPublicVaultRegistry vaultRegistry = IPublicVaultRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.VaultRegistry
      )
    );

    vaultRegistry.registerVault(_pool, address(vault));

    emit PublicVaultDeployed(address(vault), _pool);
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  /**
   * @notice Deploys a pool contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _poolVersion Version of pool contract to deploy
   * @param _poolParamsData Input parameters of constructor of the pool
   * @return pool Pool deployed
   */
  function _deployPool(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _poolVersion,
    bytes memory _poolParamsData
  ) internal returns (ISynthereumDeployment pool) {
    address poolFactory = _factoryVersioning.getFactoryVersion(
      FactoryInterfaces.PoolFactory,
      _poolVersion
    );
    bytes memory poolDeploymentResult = poolFactory.functionCall(
      abi.encodePacked(getDeploymentSignature(poolFactory), _poolParamsData),
      'Wrong pool deployment'
    );
    pool = ISynthereumDeployment(abi.decode(poolDeploymentResult, (address)));
  }

  /**
   * @notice Migrate a pool contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _poolVersion Version of pool contract to create
   * @param _migrationParamsData Input params of migration (if needed)
   * @return oldPool Pool from which the storage is migrated
   * @return newPool New pool created
   */
  function _migratePool(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _poolVersion,
    bytes memory _migrationParamsData
  )
    internal
    returns (ISynthereumDeployment oldPool, ISynthereumDeployment newPool)
  {
    address poolFactory = _factoryVersioning.getFactoryVersion(
      FactoryInterfaces.PoolFactory,
      _poolVersion
    );
    bytes memory poolDeploymentResult = poolFactory.functionCall(
      abi.encodePacked(
        getMigrationSignature(poolFactory),
        _migrationParamsData
      ),
      'Wrong pool migration'
    );
    (oldPool, newPool) = abi.decode(
      poolDeploymentResult,
      (ISynthereumDeployment, ISynthereumDeployment)
    );
  }

  /**
   * @notice Deploys a self minting derivative contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _selfMintingDerVersion Version of self minting derivate contract to deploy
   * @param _selfMintingDerParamsData Input parameters of constructor of self minting derivative
   * @return selfMintingDerivative Self minting derivative deployed
   */
  function _deploySelfMintingDerivative(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _selfMintingDerVersion,
    bytes calldata _selfMintingDerParamsData
  ) internal returns (ISynthereumDeployment selfMintingDerivative) {
    address selfMintingDerFactory = _factoryVersioning.getFactoryVersion(
      FactoryInterfaces.SelfMintingFactory,
      _selfMintingDerVersion
    );
    bytes memory selfMintingDerDeploymentResult = selfMintingDerFactory
      .functionCall(
      abi.encodePacked(
        getDeploymentSignature(selfMintingDerFactory),
        _selfMintingDerParamsData
      ),
      'Wrong self-minting derivative deployment'
    );
    selfMintingDerivative = ISynthereumDeployment(
      abi.decode(selfMintingDerDeploymentResult, (address))
    );
  }

  /**
   * @notice Deploys a fixed rate wrapper contract of a particular version
   * @param _factoryVersioning factory versioning contract
   * @param _fixedRateVersion Version of the fixed rate wrapper contract to deploy
   * @param _fixedRateParamsData Input parameters of constructor of the fixed rate wrapper
   * @return fixedRate Fixed rate wrapper deployed
   */

  function _deployFixedRate(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _fixedRateVersion,
    bytes memory _fixedRateParamsData
  ) internal returns (ISynthereumDeployment fixedRate) {
    address fixedRateFactory = _factoryVersioning.getFactoryVersion(
      FactoryInterfaces.FixedRateFactory,
      _fixedRateVersion
    );
    bytes memory fixedRateDeploymentResult = fixedRateFactory.functionCall(
      abi.encodePacked(
        getDeploymentSignature(fixedRateFactory),
        _fixedRateParamsData
      ),
      'Wrong fixed rate deployment'
    );
    fixedRate = ISynthereumDeployment(
      abi.decode(fixedRateDeploymentResult, (address))
    );
  }

  /**
   * @notice Sets roles of the synthetic token contract to a pool or a fixed rate wrapper
   * @param _financialContract Pool or fixed rate wrapper contract
   */
  function setSyntheticTokenRoles(ISynthereumDeployment _financialContract)
    internal
  {
    address financialContract = address(_financialContract);
    IAccessControlEnumerable tokenCurrency = IAccessControlEnumerable(
      address(_financialContract.syntheticToken())
    );
    if (
      !tokenCurrency.hasRole(MINTER_ROLE, financialContract) ||
      !tokenCurrency.hasRole(BURNER_ROLE, financialContract)
    ) {
      modifySyntheticTokenRoles(
        address(tokenCurrency),
        financialContract,
        true
      );
    }
  }

  /**
   * @notice Remove roles of the synthetic token contract from a pool
   * @param _financialContract Pool contract
   */
  function removeSyntheticTokenRoles(ISynthereumDeployment _financialContract)
    internal
  {
    IAccessControlEnumerable tokenCurrency = IAccessControlEnumerable(
      address(_financialContract.syntheticToken())
    );
    modifySyntheticTokenRoles(
      address(tokenCurrency),
      address(_financialContract),
      false
    );
  }

  /**
   * @notice Grants minter and burner role of syntehtic token to derivative
   * @param _tokenCurrency Address of the token contract
   * @param _contractAddr Address of the pool or self-minting derivative
   * @param _isAdd True if adding roles, false if removing
   */
  function modifySyntheticTokenRoles(
    address _tokenCurrency,
    address _contractAddr,
    bool _isAdd
  ) internal {
    ISynthereumManager manager = getManager();
    address[] memory contracts = new address[](2);
    bytes32[] memory roles = new bytes32[](2);
    address[] memory accounts = new address[](2);
    contracts[0] = _tokenCurrency;
    contracts[1] = _tokenCurrency;
    roles[0] = MINTER_ROLE;
    roles[1] = BURNER_ROLE;
    accounts[0] = _contractAddr;
    accounts[1] = _contractAddr;
    _isAdd
      ? manager.grantSynthereumRole(contracts, roles, accounts)
      : manager.revokeSynthereumRole(contracts, roles, accounts);
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------

  /**
   * @notice Get factory versioning contract from the finder
   * @return factoryVersioning Factory versioning contract
   */
  function getFactoryVersioning()
    internal
    view
    returns (ISynthereumFactoryVersioning factoryVersioning)
  {
    factoryVersioning = ISynthereumFactoryVersioning(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.FactoryVersioning
      )
    );
  }

  /**
   * @notice Get pool registry contract from the finder
   * @return poolRegistry Registry of pools
   */
  function getPoolRegistry()
    internal
    view
    returns (ISynthereumRegistry poolRegistry)
  {
    poolRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.PoolRegistry
      )
    );
  }

  /**
   * @notice Get self minting registry contract from the finder
   * @return selfMintingRegistry Registry of self-minting derivatives
   */
  function getSelfMintingRegistry()
    internal
    view
    returns (ISynthereumRegistry selfMintingRegistry)
  {
    selfMintingRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.SelfMintingRegistry
      )
    );
  }

  /**
   * @notice Get fixed rate registry contract from the finder
   * @return fixedRateRegistry Registry of fixed rate contract
   */
  function getFixedRateRegistry()
    internal
    view
    returns (ISynthereumRegistry fixedRateRegistry)
  {
    fixedRateRegistry = ISynthereumRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.FixedRateRegistry
      )
    );
  }

  /**
   * @notice Get public-vault registry contract from the finder
   * @return publicVaultRegistry Registry of public vault contract
   */
  function getPublicVaultRegistry()
    internal
    view
    returns (IPublicVaultRegistry publicVaultRegistry)
  {
    publicVaultRegistry = IPublicVaultRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.VaultRegistry
      )
    );
  }

  /**
   * @notice Get manager contract from the finder
   * @return manager Synthereum manager
   */
  function getManager() internal view returns (ISynthereumManager manager) {
    manager = ISynthereumManager(
      synthereumFinder.getImplementationAddress(SynthereumInterfaces.Manager)
    );
  }

  /**
   * @notice Get signature of function to deploy a contract
   * @param _factory Factory contract
   * @return signature Signature of deployment function of the factory
   */
  function getDeploymentSignature(address _factory)
    internal
    view
    returns (bytes4 signature)
  {
    signature = IDeploymentSignature(_factory).deploymentSignature();
  }

  /**
   * @notice Get signature of function to migrate a pool
   * @param _factory Factory contract
   * @return signature Signature of migration function of the factory
   */
  function getMigrationSignature(address _factory)
    internal
    view
    returns (bytes4 signature)
  {
    signature = IMigrationSignature(_factory).migrationSignature();
  }

  /**
   * @notice Check correct finder and version of the deployed pool or self-minting derivative
   * @param _financialContract Contract pool or self-minting derivative or fixed-rate to check
   * @param _version Pool or self-minting derivative version to check
   */
  function checkDeployment(
    ISynthereumDeployment _financialContract,
    uint8 _version
  ) internal view {
    require(
      _financialContract.synthereumFinder() == synthereumFinder,
      'Wrong finder in deployment'
    );
    require(
      _financialContract.version() == _version,
      'Wrong version in deployment'
    );
  }

  /**
   * @notice Check removing contract has not minter and burner roles of the synth tokens
   * @param _financialContract Contract pool or self-minting derivative or fixed-rate to check
   */
  function _checkMissingRoles(ISynthereumDeployment _financialContract)
    internal
    view
  {
    address financialContract = address(_financialContract);
    IAccessControlEnumerable tokenCurrency = IAccessControlEnumerable(
      address(_financialContract.syntheticToken())
    );
    require(
      !tokenCurrency.hasRole(MINTER_ROLE, financialContract),
      'Contract has minter role'
    );
    require(
      !tokenCurrency.hasRole(BURNER_ROLE, financialContract),
      'Contract has burner role'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumDeployment} from '../../common/interfaces/IDeployment.sol';
import {SynthereumPoolMigrationFrom} from '../../synthereum-pool/common/migration/PoolMigrationFrom.sol';
import {IVault} from '../../multiLP-vaults/interfaces/IVault.sol';

/**
 * @title Provides interface with functions of Synthereum deployer
 */
interface ISynthereumDeployer {
  /**
   * @notice Deploy a new pool
   * @param _poolVersion Version of the pool contract
   * @param _poolParamsData Input params of pool constructor
   * @return pool Pool contract deployed
   */
  function deployPool(uint8 _poolVersion, bytes calldata _poolParamsData)
    external
    returns (ISynthereumDeployment pool);

  /**
   * @notice Migrate storage of an existing pool to e new deployed one
   * @param _migrationPool Pool from which migrate storage
   * @param _poolVersion Version of the pool contract to create
   * @param _migrationParamsData Input params of migration (if needed)
   * @return pool Pool contract deployed
   */
  function migratePool(
    SynthereumPoolMigrationFrom _migrationPool,
    uint8 _poolVersion,
    bytes calldata _migrationParamsData
  ) external returns (ISynthereumDeployment pool);

  /**
   * @notice Remove from the registry an existing pool
   * @param _pool Pool to remove
   */
  function removePool(ISynthereumDeployment _pool) external;

  /**
   * @notice Deploy a new self minting derivative contract
   * @param _selfMintingDerVersion Version of the self minting derivative contract
   * @param _selfMintingDerParamsData Input params of self minting derivative constructor
   * @return selfMintingDerivative Self minting derivative contract deployed
   */
  function deploySelfMintingDerivative(
    uint8 _selfMintingDerVersion,
    bytes calldata _selfMintingDerParamsData
  ) external returns (ISynthereumDeployment selfMintingDerivative);

  /**
   * @notice Remove from the registry an existing self-minting derivativ contract
   * @param _selfMintingDerivative Self-minting derivative to remove
   */
  function removeSelfMintingDerivative(
    ISynthereumDeployment _selfMintingDerivative
  ) external;

  /**
   * @notice Deploy a new fixed rate wrapper contract
   * @param _fixedRateVersion Version of the fixed rate wrapper contract
   * @param _fixedRateParamsData Input params of fixed rate wrapper constructor
   * @return fixedRate Fixed rate wrapper contract deployed
   */
  function deployFixedRate(
    uint8 _fixedRateVersion,
    bytes calldata _fixedRateParamsData
  ) external returns (ISynthereumDeployment fixedRate);

  /**
   * @notice Remove from the registry a fixed rate wrapper
   * @param _fixedRate Fixed-rate to remove
   */
  function removeFixedRate(ISynthereumDeployment _fixedRate) external;

  /**
   * @notice Deploy a public vault
   * @param _lpTokenName name of the LP token representing a share in the vault
   * @param _lpTokenSymbol symbol of the LP token representing a share in the vault
   * @param _pool address of MultiLP pool the vault interacts with
   * @param _overCollateralization over collateral requirement of the vault position in the pool
   * @return vault Deployed vault
   */
  function deployPublicVault(
    string memory _lpTokenName,
    string memory _lpTokenSymbol,
    address _pool,
    uint128 _overCollateralization
  ) external returns (IVault vault);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external;

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version) external;

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    returns (address factory);

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfFactoryVersions(bytes32 factoryType)
    external
    view
    returns (uint8 numberOfVersions);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Provides interface with functions of SynthereumRegistry
 */

interface ISynthereumRegistry {
  /**
   * @notice Allow the deployer to register an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to register
   * @param collateralToken Collateral ERC20 token of the element to register
   * @param version Version of the element to register
   * @param element Address of the element to register
   */
  function register(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Allow the deployer to unregister an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to unregister
   * @param collateralToken Collateral ERC20 token of the element to unregister
   * @param version Version of the element  to unregister
   * @param element Address of the element  to unregister
   */
  function unregister(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Returns if a particular element exists or not
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @param element Contract of the element to check
   * @return isElementDeployed Returns true if a particular element exists, otherwise false
   */
  function isDeployed(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external view returns (bool isElementDeployed);

  /**
   * @notice Returns all the elements with partcular symbol, collateral and version
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @return List of all elements
   */
  function getElements(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version
  ) external view returns (address[] memory);

  /**
   * @notice Returns all the synthetic token symbol used
   * @return List of all synthetic token symbol
   */
  function getSyntheticTokens() external view returns (string[] memory);

  /**
   * @notice Returns all the versions used
   * @return List of all versions
   */
  function getVersions() external view returns (uint8[] memory);

  /**
   * @notice Returns all the collaterals used
   * @return List of all collaterals
   */
  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IEmergencyShutdown} from '../../common/interfaces/IEmergencyShutdown.sol';
import {ISynthereumLendingSwitch} from '../../synthereum-pool/common/interfaces/ILendingSwitch.sol';

interface ISynthereumManager {
  /**
   * @notice Allow to add roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which give the grant
   */
  function grantSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to revoke roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which revoke the grant
   */
  function revokeSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to renounce roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   */
  function renounceSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles
  ) external;

  /**
   * @notice Allow to call emergency shutdown in a pool or self-minting derivative
   * @param contracts Contracts to shutdown
   */
  function emergencyShutdown(IEmergencyShutdown[] calldata contracts) external;

  /**
   * @notice Set new lending protocol for a list of pool
   * @param lendingIds Name of the new lending modules of the pools
   * @param bearingTokens Tokens of the lending mosule to be used for intersts accrual in the pools
   */
  function switchLendingModule(
    ISynthereumLendingSwitch[] calldata pools,
    string[] calldata lendingIds,
    address[] calldata bearingTokens
  ) external;

  /**
   * @notice Upgrades implementation logic for a set of vault (proxies) to the one stored in vault factory
   * @param vaults List of vaults
   * @param params List of encoded params to use for initialisation (leave empty to skip initialisation)
   */
  function upgradePublicVault(address[] memory vaults, bytes[] memory params)
    external;

  /**
   * @notice Upgrades admin address for a set of vault (proxies)
   * @param vaults List of vaults
   * @param admins List of new admins
   */
  function changePublicVaultAdmin(
    address[] memory vaults,
    address[] memory admins
  ) external;

  /**
   * @notice Retrieves address of the proxy implementation contract
   * @return address of implementer
   */
  function getCurrentVaultImplementation(address vaultProxy)
    external
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides signature of function for deployment
 */
interface IDeploymentSignature {
  /**
   * @notice Returns the bytes4 signature of the function used for the deployment of a contract in a factory
   * @return signature returns signature of the deployment function
   */
  function deploymentSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides signature of function for migration
 */
interface IMigrationSignature {
  /**
   * @notice Returns the bytes4 signature of the function used for the migration of a contract in a factory
   * @return signature returns signature of the migration function
   */
  function migrationSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumDeployment {
  /**
   * @notice Get Synthereum finder of the pool/self-minting derivative
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return contractVersion Returns the version of this pool/self-minting derivative
   */
  function version() external view returns (uint8 contractVersion);

  /**
   * @notice Get the collateral token of this pool/self-minting derivative
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool/self-minting derivative
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant VaultRegistry = 'VaultRegistry';
  bytes32 public constant StakingLPVaultRegistry = 'StakingLPVaultRegistry';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
  bytes32 public constant CommissionReceiver = 'CommissionReceiver';
  bytes32 public constant BuybackProgramReceiver = 'BuybackProgramReceiver';
  bytes32 public constant LendingRewardsReceiver = 'LendingRewardsReceiver';
  bytes32 public constant StakingRewardsReceiver = 'StakingRewardsReceiver';
  bytes32 public constant JarvisToken = 'JarvisToken';
  bytes32 public constant DebtTokenFactory = 'DebtTokenFactory';
  bytes32 public constant VaultFactory = 'VaultFactory';
  bytes32 public constant StakingLPVaultFactory = 'StakingLPVaultFactory';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant StakedJarvisToken = 'StakedJarvisToken';
  bytes32 public constant StakingLPVaultData = 'StakingLPVaultData';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant CrossChainBridge = 'CrossChainBridge';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {SynthereumPoolMigration} from './PoolMigration.sol';

/**
 * @title Abstract contract inherit by pools for moving storage from one pool to another
 */
abstract contract SynthereumPoolMigrationFrom is SynthereumPoolMigration {
  /**
   * @notice Migrate storage from this pool resetting and cleaning data
   * @notice This can be called only by a pool factory
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Pool storage encoded in bytes
   */
  function migrateStorage()
    external
    virtual
    onlyPoolFactory
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    )
  {
    _modifyStorageFrom();
    (poolVersion, price, storageBytes) = _encodeStorage();
    _cleanStorage();
  }

  /**
   * @notice Transfer all bearing tokens to another address
   * @notice Only the lending manager can call the function
   * @param _recipient Address receving bearing amount
   * @return migrationAmount Total balance of the pool in bearing tokens before migration
   */
  function migrateTotalFunds(address _recipient)
    external
    virtual
    returns (uint256 migrationAmount);

  /**
   * @notice Function to implement for modifying storage before the encoding
   */
  function _modifyStorageFrom() internal virtual;

  /**
   * @notice Function to implement for cleaning and resetting the storage to the initial state
   */
  function _cleanStorage() internal virtual;

  /**
   * @notice Function to implement for encoding storage in bytes
   * @return poolVersion Version of the pool
   * @return price Actual price of the pair
   * @return storageBytes Pool storage encoded in bytes
   */
  function _encodeStorage()
    internal
    view
    virtual
    returns (
      uint8 poolVersion,
      uint256 price,
      bytes memory storageBytes
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Interface of PublicVaultRegistry
 */

interface IPublicVaultRegistry {
  /**
   * @notice Allow the deployer to map a vault to a pool
   * @param pool Address of the pool
   * @param vault Address of the vault
   */
  function registerVault(address pool, address vault) external;

  /**
   * @notice To unregister a vault
   * @notice Only a registered pool can call this one to remove its own registered vaults
   * @param vault Address of the vault to unregister
   */
  function removeVault(address vault) external;

  /**
   * @notice Allow to move vaults from an old pool to a new pool
   * @notice Only deployer can call this function
   * @param oldPool Address of the old pool
   * @param newPool Address of the new pool
   */
  function migrateVaults(address oldPool, address newPool) external;

  /**
   * @notice Returns all the vaults associated to a pool
   * @param pool Pool address
   * @return List of all vaults registered to the pool
   */
  function getVaults(address pool) external view returns (address[] memory);

  /**
   * @notice Checks if an address is a registered vault
   * @param vault Vault address
   * @return Boolean
   */
  function isVaultSupported(address vault) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {SynthereumFactoryAccess} from '../../../common/libs/FactoryAccess.sol';

/**
 * @title Abstract contract inherited by pools for moving storage from one pool to another
 */
contract SynthereumPoolMigration {
  ISynthereumFinder internal finder;

  modifier onlyPoolFactory() {
    SynthereumFactoryAccess._onlyPoolFactory(finder);
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumFactoryVersioning} from '../../core/interfaces/IFactoryVersioning.sol';
import {SynthereumInterfaces, FactoryInterfaces} from '../../core/Constants.sol';

/** @title Library to use for controlling the access of a functions from the factories
 */
library SynthereumFactoryAccess {
  /**
   *@notice Revert if caller is not a Pool factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactory(ISynthereumFinder _finder) internal view {

      ISynthereumFactoryVersioning factoryVersioning
     = ISynthereumFactoryVersioning(
      _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
    );
    uint8 numberOfPoolFactories = factoryVersioning.numberOfFactoryVersions(
      FactoryInterfaces.PoolFactory
    );
    require(
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfPoolFactories,
        FactoryInterfaces.PoolFactory
      ),
      'Not allowed'
    );
  }

  /**
   * @notice Revert if caller is not a Pool factory or a Fixed rate factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactoryOrFixedRateFactory(ISynthereumFinder _finder)
    internal
    view
  {

      ISynthereumFactoryVersioning factoryVersioning
     = ISynthereumFactoryVersioning(
      _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
    );
    uint8 numberOfPoolFactories = factoryVersioning.numberOfFactoryVersions(
      FactoryInterfaces.PoolFactory
    );
    uint8 numberOfFixedRateFactories = factoryVersioning
      .numberOfFactoryVersions(FactoryInterfaces.FixedRateFactory);
    bool isPoolFactory = _checkSenderIsFactory(
      factoryVersioning,
      numberOfPoolFactories,
      FactoryInterfaces.PoolFactory
    );
    if (isPoolFactory) {
      return;
    }
    bool isFixedRateFactory = _checkSenderIsFactory(
      factoryVersioning,
      numberOfFixedRateFactories,
      FactoryInterfaces.FixedRateFactory
    );
    if (isFixedRateFactory) {
      return;
    }
    revert('Sender must be a Pool or FixedRate factory');
  }

  /**
   * @notice Check if sender is a factory
   * @param _factoryVersioning SynthereumFactoryVersioning contract
   * @param _numberOfFactories Total number of versions of a factory type
   * @param _factoryKind Type of the factory
   * @return isFactory True if sender is a factory, otherwise false
   */
  function _checkSenderIsFactory(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _numberOfFactories,
    bytes32 _factoryKind
  ) private view returns (bool isFactory) {
    uint8 counterFactory;
    for (uint8 i = 0; counterFactory < _numberOfFactories; i++) {
      try _factoryVersioning.getFactoryVersion(_factoryKind, i) returns (
        address factory
      ) {
        if (msg.sender == factory) {
          isFactory = true;
          break;
        } else {
          counterFactory++;
          if (counterFactory == _numberOfFactories) {
            isFactory = false;
          }
        }
      } catch {}
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IEmergencyShutdown {
  /**
   * @notice Shutdown the pool or self-minting-derivative in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    returns (uint256 timestamp, uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Pool interface for making lending manager interacting with the pool
 */
interface ISynthereumLendingSwitch {
  /**
  * @notice Set new lending protocol for this pool
  * @notice This can be called only by the maintainer
  * @param _lendingId Name of the new lending module
  * @param _bearingToken Token of the lending mosule to be used for intersts accrual
            (used only if the lending manager doesn't automatically find the one associated to the collateral fo this pool)
  */
  function switchLendingModule(
    string calldata _lendingId,
    address _bearingToken
  ) external;
}