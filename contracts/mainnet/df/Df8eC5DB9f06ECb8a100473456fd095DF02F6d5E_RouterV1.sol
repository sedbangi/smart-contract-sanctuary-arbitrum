// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
library EnumerableSetUpgradeable {
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
pragma solidity 0.8.17;

interface IJuniorVault {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function assetDecimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function getConfig(bytes32 configKey) external view returns (bytes32);

    function setConfig(bytes32 configKey, bytes32 value) external;

    function asset() external view returns (address assetTokenAddress);

    function depositToken() external view returns (address depositTokenAddress);

    function totalAssets() external view returns (uint256 totalManagedAssets);

    function balanceOf(address owner) external view returns (uint256);

    function leverage(
        uint256 totalBorrows,
        uint256 juniorPrice,
        uint256 seniorPrice
    ) external view returns (uint256);

    function deposit(uint256 assets, uint256 shares, address receiver) external returns (uint256);

    function withdraw(
        address caller,
        address owner,
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);

    function collectMuxRewards(address owner) external;

    function transferFrom(address from, address to, uint256 shares) external;

    function transferIn(uint256 assets) external;

    function transferOut(uint256 assets) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IRewardController {
    function rewardToken() external view returns (address);

    function claimableJuniorRewards(address account) external returns (uint256);

    function claimableSeniorRewards(address account) external returns (uint256);

    function claimSeniorRewardsFor(address account, address receiver) external returns (uint256);

    function claimJuniorRewardsFor(address account, address receiver) external returns (uint256);

    function updateRewards(address account) external;

    function notifyRewards(
        address[] memory rewardTokens,
        uint256[] memory rewardAmounts,
        uint256 utilizedAmount
    ) external;

    function migrateSeniorRewardFor(address from, address to) external;

    function migrateJuniorRewardFor(address from, address to) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../router/Type.sol";

interface IRouterV1 {
    // =============================================== Configs ===============================================

    function getConfig(bytes32 configKey) external view returns (bytes32);

    // =============================================== Views ===============================================

    function getUserStates(address account) external view returns (UserState memory userState);

    function getPendingUsersCount() external view returns (uint256);

    function getUserOrderTime(address account) external view returns (uint32 placeOrderTime);

    function getLastPendingUserOrderTime() external view returns (uint32 placeOrderTime);

    function getPendingUsers(uint256 begin, uint256 count) external view returns (address[] memory);

    function juniorLeverage(
        uint256 seniorPrice,
        uint256 juniorPrice
    ) external view returns (uint256 leverage);

    function pendingJuniorShares() external view returns (uint256);

    function pendingJuniorAssets() external view returns (uint256);

    function pendingSeniorShares() external view returns (uint256);

    function pendingBorrowAssets() external view returns (uint256);

    function pendingSeniorAssets() external view returns (uint256);

    function pendingRefundAssets() external view returns (uint256);

    function pendingJuniorDeposits() external view returns (uint256);

    function juniorNavPerShare(
        uint256 seniorPrice,
        uint256 juniorPrice
    ) external view returns (uint256);

    function isJuniorBalanced(
        uint256 seniorPrice,
        uint256 juniorPrice
    ) external view returns (bool isBalanced, bool isRebalancing);

    function claimableJuniorRewards(address account) external returns (uint256);

    function claimableSeniorRewards(address account) external returns (uint256);

    // =============================================== Actions ===============================================

    // Idle => DepositJunior => Idle
    function depositJunior(uint256 assets) external;

    // Idle => WithdrawJunior => Idle
    function withdrawJunior(uint256 shares) external;

    function depositSenior(uint256 amount) external;

    // Idle => WithdrawSenior => RefundJunior => Idle
    function withdrawSenior(uint256 amount, bool acceptPenalty) external;

    // Idle => BuyJunior / SellJunior => Idle
    function rebalance(uint256 seniorPrice, uint256 juniorPrice) external;

    // Idle => SellJunior => Idle
    function liquidate(uint256 seniorPrice, uint256 juniorPrice) external;

    // Idle => BuyJunior => Idle
    function refundJunior() external;

    function updateRewards() external;

    function cancelPendingOperation() external;

    function claimJuniorRewards() external returns (uint256);

    function claimSeniorRewards() external returns (uint256);

    function isLiquidated() external view returns (bool);

    function migrateJunior(address to) external;

    function migrateSenior(address to) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface ISeniorVault {
    enum LockType {
        None,
        SoftLock,
        HardLock
    }

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function assetDecimals() external view returns (uint8);

    function getConfig(bytes32 configKey) external view returns (bytes32);

    function setConfig(bytes32 configKey, bytes32 value) external;

    function asset() external view returns (address);

    function depositToken() external view returns (address);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function borrowable(address receiver) external view returns (uint256 assets);

    function balanceOf(address account) external view returns (uint256);

    function borrows(address account) external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256 shares);

    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    function timelock(address owner) external view returns (uint256 unlockTime);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function withdraw(
        address caller,
        address owner,
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);

    function borrow(uint256 assets) external;

    function repay(uint256 assets) external;

    function transferFrom(address from, address to, uint256 shares) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IMuxLiquidityCallback {
    struct LiquidityOrder {
        uint64 id;
        address account;
        uint96 rawAmount; // erc20.decimals
        uint8 assetId;
        bool isAdding;
        uint32 placeOrderTime; // 1e0
    }

    function beforeFillLiquidityOrder(
        LiquidityOrder calldata order, // the order to be filled
        uint96 assetPrice, // the price of asset used in add / remove liquidity
        uint96 mlpPrice, // the price of mlp
        uint96 currentAssetValue, // the param used to calculate fee for liquidity
        uint96 targetAssetValue // the param used to calculate fee for liquidity
    ) external returns (bool);

    function afterFillLiquidityOrder(
        LiquidityOrder calldata order, // the order to be filled
        uint256 outAmount, // the output amount of the order (that is: mlp output amount for adding and asset output amount for removing)
        uint96 assetPrice, // the price of asset used in add / remove liquidity
        uint96 mlpPrice, // the price of mlp
        uint96 currentAssetValue, // the param used to calculate fee for liquidity
        uint96 targetAssetValue // the param used to calculate fee for liquidity
    ) external;

    function afterCancelLiquidityOrder(LiquidityOrder calldata order) external; // the order to be filled
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IMuxLiquidityPool {
    struct Asset {
        // slot
        // assets with the same symbol in different chains are the same asset. they shares the same muxToken. so debts of the same symbol
        // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
        // different chains are the same.
        // since muxToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
        // symbol can be different (ex: "USDT", "USDT.e" and "fUSDT").
        bytes32 symbol;
        // slot
        address tokenAddress; // erc20.address
        uint8 id;
        uint8 decimals; // erc20.decimals
        uint56 flags; // a bitset of ASSET_*
        uint24 _flagsPadding;
        // slot
        uint32 initialMarginRate; // 1e5
        uint32 maintenanceMarginRate; // 1e5
        uint32 minProfitRate; // 1e5
        uint32 minProfitTime; // 1e0
        uint32 positionFeeRate; // 1e5
        // note: 96 bits remaining
        // slot
        address referenceOracle;
        uint32 referenceDeviation; // 1e5
        uint8 referenceOracleType;
        uint32 halfSpread; // 1e5
        // note: 24 bits remaining
        // slot
        uint96 credit;
        uint128 _reserved2;
        // slot
        uint96 collectedFee;
        uint32 liquidationFeeRate; // 1e5
        uint96 spotLiquidity;
        // note: 32 bits remaining
        // slot
        uint96 maxLongPositionSize;
        uint96 totalLongPosition;
        // note: 64 bits remaining
        // slot
        uint96 averageLongPrice;
        uint96 maxShortPositionSize;
        // note: 64 bits remaining
        // slot
        uint96 totalShortPosition;
        uint96 averageShortPrice;
        // note: 64 bits remaining
        // slot, less used
        address muxTokenAddress; // muxToken.address. all stable coins share the same muxTokenAddress
        uint32 spotWeight; // 1e0
        uint32 longFundingBaseRate8H; // 1e5
        uint32 longFundingLimitRate8H; // 1e5
        // slot
        uint128 longCumulativeFundingRate; // Σ_t fundingRate_t
        uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t
    }

    function getAssetInfo(uint8 assetId) external view returns (Asset memory);

    function getAllAssetInfo() external view returns (Asset[] memory);

    function getLiquidityPoolStorage()
        external
        view
        returns (
            // [0] shortFundingBaseRate8H
            // [1] shortFundingLimitRate8H
            // [2] lastFundingTime
            // [3] fundingInterval
            // [4] liquidityBaseFeeRate
            // [5] liquidityDynamicFeeRate
            // [6] sequence. note: will be 0 after 0xffffffff
            // [7] strictStableDeviation
            uint32[8] memory u32s,
            // [0] mlpPriceLowerBound
            // [1] mlpPriceUpperBound
            uint96[2] memory u96s
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IMuxOrderBook {
    event CallbackError(string reason);

    function nextOrderId() external view returns (uint64);

    /**
     * @notice Liquidity Order can be filled after this time in seconds.
     */
    function liquidityLockPeriod() external view returns (uint32);

    /**
     * @notice Cancel an Order by orderId.
     */
    function cancelOrder(uint64 orderId) external;

    /**
     * @notice Add/remove liquidity. called by Liquidity Provider.
     *
     *         Can be filled after liquidityLockPeriod seconds.
     * @param  assetId   asset.id that added/removed to.
     * @param  rawAmount asset token amount. decimals = erc20.decimals.
     * @param  isAdding  true for add liquidity, false for remove liquidity.
     */
    function placeLiquidityOrder(
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    ) external payable;

    function setCallbackWhitelist(address caller, bool enable) external;

    function fillLiquidityOrder(
        uint64 orderId,
        uint96 assetPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external;

    function getOrder(uint64 orderId) external view returns (bytes32[3] memory, bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IMuxRewardRouter {
    function mlp() external view returns (address);

    function mcb() external view returns (address);

    function mux() external view returns (address);

    function weth() external view returns (address);

    // fmlp
    function mlpFeeTracker() external view returns (address);

    // smlp
    function mlpMuxTracker() external view returns (address);

    // vester
    function mlpVester() external view returns (address);

    function claimableRewards(
        address account
    )
        external
        returns (
            uint256 mlpFeeAmount,
            uint256 mlpMuxAmount,
            uint256 veFeeAmount,
            uint256 veMuxAmount,
            uint256 mcbAmount
        );

    function claimAll() external;

    function stakeMlp(uint256 _amount) external returns (uint256);

    function unstakeMlp(uint256 _amount) external returns (uint256);

    function depositToMlpVester(uint256 amount) external;

    function withdrawFromMlpVester() external;

    function mlpLockAmount(address account, uint256 amount) external view returns (uint256);

    function reservedMlpAmount(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IMuxVester {
    function deposit(uint256 _amount) external;

    function claim() external returns (uint256);

    function withdraw() external;

    function balanceOf(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getPairAmount(address _account, uint256 _esAmount) external view returns (uint256);

    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);

    function getMaxVestableAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../interfaces/mux/IMuxLiquidityPool.sol";

library LibAsset {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    uint56 constant ASSET_IS_STABLE = 0x00000000000001; // is a usdt, usdc, ...
    uint56 constant ASSET_CAN_ADD_REMOVE_LIQUIDITY = 0x00000000000002; // can call addLiquidity and removeLiquidity with this token
    uint56 constant ASSET_IS_TRADABLE = 0x00000000000100; // allowed to be assetId
    uint56 constant ASSET_IS_OPENABLE = 0x00000000010000; // can open position
    uint56 constant ASSET_IS_SHORTABLE = 0x00000001000000; // allow shorting this asset
    uint56 constant ASSET_USE_STABLE_TOKEN_FOR_PROFIT = 0x00000100000000; // take profit will get stable coin
    uint56 constant ASSET_IS_ENABLED = 0x00010000000000; // allowed to be assetId and collateralId
    uint56 constant ASSET_IS_STRICT_STABLE = 0x01000000000000; // assetPrice is always 1 unless volatility exceeds strictStableDeviation

    function toWad(
        IMuxLiquidityPool.Asset memory token,
        uint256 rawAmount
    ) internal pure returns (uint256) {
        return (rawAmount * (10 ** (18 - token.decimals)));
    }

    function toRaw(
        IMuxLiquidityPool.Asset memory token,
        uint96 wadAmount
    ) internal pure returns (uint256) {
        return uint256(wadAmount) / 10 ** (18 - token.decimals);
    }

    // is a usdt, usdc, ...
    function isStable(IMuxLiquidityPool.Asset memory asset) internal pure returns (bool) {
        return (asset.flags & ASSET_IS_STABLE) != 0;
    }

    // can call addLiquidity and removeLiquidity with this token
    function canAddRemoveLiquidity(
        IMuxLiquidityPool.Asset memory asset
    ) internal pure returns (bool) {
        return (asset.flags & ASSET_CAN_ADD_REMOVE_LIQUIDITY) != 0;
    }

    // allowed to be assetId
    function isTradable(IMuxLiquidityPool.Asset memory asset) internal pure returns (bool) {
        return (asset.flags & ASSET_IS_TRADABLE) != 0;
    }

    // can open position
    function isOpenable(IMuxLiquidityPool.Asset memory asset) internal pure returns (bool) {
        return (asset.flags & ASSET_IS_OPENABLE) != 0;
    }

    // allow shorting this asset
    function isShortable(IMuxLiquidityPool.Asset memory asset) internal pure returns (bool) {
        return (asset.flags & ASSET_IS_SHORTABLE) != 0;
    }

    // take profit will get stable coin
    function useStableTokenForProfit(
        IMuxLiquidityPool.Asset memory asset
    ) internal pure returns (bool) {
        return (asset.flags & ASSET_USE_STABLE_TOKEN_FOR_PROFIT) != 0;
    }

    // allowed to be assetId and collateralId
    function isEnabled(IMuxLiquidityPool.Asset memory asset) internal pure returns (bool) {
        return (asset.flags & ASSET_IS_ENABLED) != 0;
    }

    // assetPrice is always 1 unless volatility exceeds strictStableDeviation
    function isStrictStable(IMuxLiquidityPool.Asset memory asset) internal pure returns (bool) {
        return (asset.flags & ASSET_IS_STRICT_STABLE) != 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./LibTypeCast.sol";

struct ConfigSet {
    mapping(bytes32 => bytes32) values;
}

library LibConfigSet {
    using LibTypeCast for bytes32;
    using LibTypeCast for address;
    using LibTypeCast for uint256;
    using LibTypeCast for bool;

    event SetValue(bytes32 key, bytes32 value);
    error InvalidAddress(bytes32 key);

    // ================================== single functions ======================================
    function setBytes32(ConfigSet storage store, bytes32 key, bytes32 value) internal {
        store.values[key] = value;
        emit SetValue(key, value);
    }

    function getBytes32(ConfigSet storage store, bytes32 key) internal view returns (bytes32) {
        return store.values[key];
    }

    function getUint256(ConfigSet storage store, bytes32 key) internal view returns (uint256) {
        return store.values[key].toUint256();
    }

    function getAddress(ConfigSet storage store, bytes32 key) internal view returns (address) {
        return store.values[key].toAddress();
    }

    function mustGetAddress(ConfigSet storage store, bytes32 key) internal view returns (address) {
        address a = getAddress(store, key);
        if (a == address(0)) {
            revert InvalidAddress(key);
        }
        return a;
    }

    function getBoolean(ConfigSet storage store, bytes32 key) internal view returns (bool) {
        return store.values[key].toBoolean();
    }

    function toBytes32(address a) internal pure returns (bytes32) {
        return bytes32(bytes20(a));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

bytes32 constant WETH_TOKEN = keccak256("WETH_TOKEN");
bytes32 constant SMLP_TOKEN = keccak256("SMLP_TOKEN");
bytes32 constant MUX_TOKEN = keccak256("MUX_TOKEN");
bytes32 constant MCB_TOKEN = keccak256("MCB_TOKEN");
bytes32 constant MLP_TOKEN = keccak256("MLP_TOKEN");

// ======================================== JuniorVault ========================================
bytes32 constant MUX_REWARD_ROUTER = keccak256("MUX_REWARD_ROUTER");
bytes32 constant MUX_LIQUIDITY_POOL = keccak256("MUX_LIQUIDITY_POOL");
bytes32 constant ASSET_SUPPLY_CAP = keccak256("ASSET_SUPPLY_CAP");

// ======================================== SeniorVault ========================================
bytes32 constant LOCK_TYPE = keccak256("LOCK_TYPE");
bytes32 constant LOCK_PERIOD = keccak256("LOCK_PERIOD");
bytes32 constant LOCK_PENALTY_RATE = keccak256("LOCK_PENALTY_RATE");
bytes32 constant LOCK_PENALTY_RECIPIENT = keccak256("LOCK_PENALTY_RECIPIENT");
bytes32 constant MAX_BORROWS = keccak256("MAX_BORROWS");
// bytes32 constant ASSET_SUPPLY_CAP = keccak256("ASSET_SUPPLY_CAP");

// ======================================== Router ========================================
bytes32 constant TARGET_LEVERAGE = keccak256("TARGET_LEVERAGE");
bytes32 constant REBALANCE_THRESHOLD = keccak256("REBALANCE_THRESHOLD");
bytes32 constant REBALANCE_THRESHOLD_USD = keccak256("REBALANCE_THRESHOLD_USD");
// bytes32 constant MUX_LIQUIDITY_POOL = keccak256("MUX_LIQUIDITY_POOL");
bytes32 constant LIQUIDATION_LEVERAGE = keccak256("LIQUIDATION_LEVERAGE"); // 10%
bytes32 constant MUX_ORDER_BOOK = keccak256("MUX_ORDER_BOOK");

// ======================================== ROLES ========================================
bytes32 constant DEFAULT_ADMIN = 0;
bytes32 constant HANDLER_ROLE = keccak256("HANDLER_ROLE");
bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

//==================
uint256 constant ONE = 1e18;

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../interfaces/mux/IMuxLiquidityPool.sol";

interface IChainlink {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface IChainlinkV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
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

interface IChainlinkV2V3 is IChainlink, IChainlinkV3 {}

enum SpreadType {
    Ask,
    Bid
}

enum ReferenceOracleType {
    None,
    Chainlink
}

library LibReferenceOracle {
    uint56 constant ASSET_IS_STRICT_STABLE = 0x01000000000000; // assetPrice is always 1 unless volatility exceeds strictStableDeviation

    // indicate that the asset price is too far away from reference oracle
    event AssetPriceOutOfRange(
        uint8 assetId,
        uint96 price,
        uint96 referencePrice,
        uint32 deviation
    );

    /**
     * @dev Check oracle parameters before set.
     */
    function checkParameters(
        ReferenceOracleType referenceOracleType,
        address referenceOracle,
        uint32 referenceDeviation
    ) internal view {
        require(referenceDeviation <= 1e5, "D>1"); // %deviation > 100%
        if (referenceOracleType == ReferenceOracleType.Chainlink) {
            IChainlinkV2V3 o = IChainlinkV2V3(referenceOracle);
            require(o.decimals() == 8, "!D8"); // we only support decimals = 8
            require(o.latestAnswer() > 0, "P=0"); // oracle Price <= 0
        }
    }

    /**
     * @dev Truncate price if the error is too large.
     */
    function checkPrice(
        IMuxLiquidityPool.Asset memory asset,
        uint96 price,
        uint32 strictStableDeviation
    ) internal view returns (uint96) {
        require(price != 0, "P=0"); // broker price = 0

        // truncate price if the error is too large
        if (ReferenceOracleType(asset.referenceOracleType) == ReferenceOracleType.Chainlink) {
            uint96 ref = _readChainlink(asset.referenceOracle);
            price = _truncatePrice(asset, price, ref);
        }

        // strict stable dampener
        if (isStrictStable(asset)) {
            uint256 delta = price > 1e18 ? price - 1e18 : 1e18 - price;
            uint256 dampener = uint256(strictStableDeviation) * 1e13; // 1e5 => 1e18
            if (delta <= dampener) {
                price = 1e18;
            }
        }

        return price;
    }

    function isStrictStable(IMuxLiquidityPool.Asset memory asset) internal pure returns (bool) {
        return (asset.flags & ASSET_IS_STRICT_STABLE) != 0;
    }

    /**
     * @dev check price and add spread, where spreadType should be:
     *
     *      subAccount.isLong   openPosition   closePosition   addLiquidity   removeLiquidity
     *      long                ask            bid
     *      short               bid            ask
     *      N/A                                                bid            ask
     */
    function checkPriceWithSpread(
        IMuxLiquidityPool.Asset memory asset,
        uint96 price,
        uint32 strictStableDeviation,
        SpreadType spreadType
    ) internal view returns (uint96) {
        price = checkPrice(asset, price, strictStableDeviation);
        price = _addSpread(asset, price, spreadType);
        return price;
    }

    function _readChainlink(address referenceOracle) internal view returns (uint96) {
        int256 ref = IChainlinkV2V3(referenceOracle).latestAnswer();
        require(ref > 0, "P=0"); // oracle Price <= 0
        ref *= 1e10; // decimals 8 => 18
        return safeUint96(uint256(ref));
    }

    function _truncatePrice(
        IMuxLiquidityPool.Asset memory asset,
        uint96 price,
        uint96 ref
    ) private pure returns (uint96) {
        if (asset.referenceDeviation == 0) {
            return ref;
        }
        uint256 deviation = (uint256(ref) * asset.referenceDeviation) / 1e5;
        uint96 bound = safeUint96(uint256(ref) - deviation);
        if (price < bound) {
            price = bound;
        }
        bound = safeUint96(uint256(ref) + deviation);
        if (price > bound) {
            price = bound;
        }
        return price;
    }

    function _addSpread(
        IMuxLiquidityPool.Asset memory asset,
        uint96 price,
        SpreadType spreadType
    ) private pure returns (uint96) {
        if (asset.halfSpread == 0) {
            return price;
        }
        uint96 halfSpread = safeUint96((uint256(price) * asset.halfSpread) / 1e5);
        if (spreadType == SpreadType.Bid) {
            require(price > halfSpread, "P=0"); // Price - halfSpread = 0. impossible
            return price - halfSpread;
        } else {
            return price + halfSpread;
        }
    }

    function safeUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "O96"); // uint96 Overflow
        return uint96(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

library LibTypeCast {
    bytes32 private constant ADDRESS_GUARD_MASK =
        0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;

    function toAddress(bytes32 v) internal pure returns (address) {
        require(v & ADDRESS_GUARD_MASK == 0, "LibTypeCast::INVALID");
        return address(bytes20(v));
    }

    function toBytes32(address v) internal pure returns (bytes32) {
        return bytes32(bytes20(v));
    }

    function toUint256(bytes32 v) internal pure returns (uint256) {
        return uint256(v);
    }

    function toBytes32(uint256 v) internal pure returns (bytes32) {
        return bytes32(v);
    }

    function toBoolean(bytes32 v) internal pure returns (bool) {
        uint256 n = toUint256(v);
        require(n == 0 || n == 1, "LibTypeCast::INVALID");
        return n == 1;
    }

    function toBytes32(bool v) internal pure returns (bytes32) {
        return toBytes32(v ? 1 : 0);
    }

    function toUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "LibTypeCast::OVERFLOW");
        return uint96(n);
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "LibTypeCast::OVERFLOW");
        return uint32(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

library LibUniswap {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event UniswapCall(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    function swap(
        ISwapRouter swapRouter,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut, bool success) {
        // path of the token swap
        bytes memory path = encodePath(tokenIn, tokenOut, 500);
        // executes the swap on uniswap pool
        IERC20Upgradeable(tokenIn).safeTransfer(address(swapRouter), amountIn);
        // exact input swap to convert exact amount of tokens into usdc
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut
        });
        // since exact input swap tokens used = token amount passed
        try swapRouter.exactInput(params) returns (uint256 _amountOut) {
            amountOut = _amountOut;
            success = true;
        } catch {
            success = false;
        }
        emit UniswapCall(tokenIn, tokenOut, amountIn, amountOut);
    }

    function encodePath(
        address tokenIn,
        address tokenOut,
        uint24 slippage
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(tokenIn, slippage, tokenOut);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/mux/IMuxRewardRouter.sol";
import "../interfaces/mux/IMuxLiquidityPool.sol";
import "../interfaces/mux/IMuxOrderBook.sol";
import "../interfaces/mux/IMuxVester.sol";

import "../libraries/LibDefines.sol";
import "../libraries/LibAsset.sol";
import "../libraries/LibConfigSet.sol";
import "../libraries/LibTypeCast.sol";
import "../libraries/LibReferenceOracle.sol";

library MuxAdapter {
    using LibAsset for IMuxLiquidityPool.Asset;
    using LibTypeCast for uint256;
    using LibConfigSet for ConfigSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct LiquidityPoolConfig {
        uint32 strictStableDeviation;
        uint32 liquidityBaseFeeRate;
        uint32 liquidityDynamicFeeRate;
    }

    event CollectRewards(uint256 wethAmount, uint256 mcbAmount);
    event AdjustVesting(
        uint256 vestedMlpAmount,
        uint256 vestedMuxAmount,
        uint256 requiredMlpAmount,
        uint256 totalMlpAmount,
        uint256 toVestMuxAmount
    );

    function pendingRewards(
        ConfigSet storage set
    ) internal returns (uint256 wethAmount, uint256 mcbAmount) {
        IMuxRewardRouter muxRewardRouter = IMuxRewardRouter(set.mustGetAddress(MUX_REWARD_ROUTER));
        (wethAmount, , , , mcbAmount) = muxRewardRouter.claimableRewards(address(this));
    }

    function collectMuxRewards(ConfigSet storage set, address receiver) internal {
        require(receiver != address(0), "MuxAdapter::INVALID_RECEIVER");
        IMuxRewardRouter muxRewardRouter = IMuxRewardRouter(set.mustGetAddress(MUX_REWARD_ROUTER));
        IERC20Upgradeable mcbToken = IERC20Upgradeable(set.mustGetAddress(MCB_TOKEN));
        IERC20Upgradeable wethToken = IERC20Upgradeable(set.mustGetAddress(WETH_TOKEN));
        address vester = muxRewardRouter.mlpVester();
        require(vester != address(0), "MuxAdapter::INVALID_VESTER");
        (uint256 wethAmount, , , , uint256 mcbAmount) = muxRewardRouter.claimableRewards(
            address(this)
        );
        muxRewardRouter.claimAll();
        if (wethAmount > 0) {
            wethToken.safeTransfer(receiver, wethAmount);
        }
        if (mcbAmount > 0) {
            mcbToken.safeTransfer(receiver, mcbAmount);
        }
        emit CollectRewards(wethAmount, mcbAmount);
    }

    function stake(ConfigSet storage set, uint256 amount) internal {
        // stake
        if (amount > 0) {
            IMuxRewardRouter muxRewardRouter = IMuxRewardRouter(
                set.mustGetAddress(MUX_REWARD_ROUTER)
            );
            IERC20Upgradeable mlpToken = IERC20Upgradeable(set.mustGetAddress(MLP_TOKEN));
            address mlpFeeTracker = muxRewardRouter.mlpFeeTracker();
            mlpToken.approve(address(mlpFeeTracker), amount);
            muxRewardRouter.stakeMlp(amount);
        }
    }

    function unstake(ConfigSet storage set, uint256 amount) internal {
        if (amount > 0) {
            IMuxRewardRouter muxRewardRouter = IMuxRewardRouter(
                set.mustGetAddress(MUX_REWARD_ROUTER)
            );
            IERC20Upgradeable sMlpToken = IERC20Upgradeable(set.mustGetAddress(SMLP_TOKEN));
            // vest => smlp
            if (muxRewardRouter.reservedMlpAmount(address(this)) > 0) {
                muxRewardRouter.withdrawFromMlpVester();
            }
            // smlp => mlp
            sMlpToken.approve(muxRewardRouter.mlpFeeTracker(), amount);
            muxRewardRouter.unstakeMlp(amount);
        }
    }

    function adjustVesting(ConfigSet storage set) internal {
        IMuxRewardRouter muxRewardRouter = IMuxRewardRouter(set.mustGetAddress(MUX_REWARD_ROUTER));
        IERC20Upgradeable muxToken = IERC20Upgradeable(set.mustGetAddress(MUX_TOKEN));
        IERC20Upgradeable sMlpToken = IERC20Upgradeable(set.mustGetAddress(SMLP_TOKEN));
        IMuxVester vester = IMuxVester(muxRewardRouter.mlpVester());
        require(address(vester) != address(0), "MuxAdapter::INVALID_VESTER");
        uint256 muxAmount = muxToken.balanceOf(address(this));
        if (muxAmount == 0) {
            return;
        }
        uint256 vestedMlpAmount = vester.pairAmounts(address(this));
        uint256 vestedMuxAmount = vester.balanceOf(address(this));
        uint256 requiredMlpAmount = vester.getPairAmount(
            address(this),
            muxAmount + vestedMuxAmount
        );
        uint256 mlpAmount = sMlpToken.balanceOf(address(this)) + vestedMlpAmount;
        uint256 toVestMuxAmount;
        if (mlpAmount >= requiredMlpAmount) {
            toVestMuxAmount = muxAmount;
        } else {
            uint256 rate = (mlpAmount * ONE) / requiredMlpAmount;
            toVestMuxAmount = (muxAmount * rate) / ONE;
            if (toVestMuxAmount > vestedMuxAmount) {
                toVestMuxAmount = toVestMuxAmount - vestedMuxAmount;
            } else {
                toVestMuxAmount = 0;
            }
        }
        if (toVestMuxAmount > 0) {
            muxToken.approve(address(vester), toVestMuxAmount);
            muxRewardRouter.depositToMlpVester(toVestMuxAmount);
        }
        emit AdjustVesting(
            vestedMlpAmount,
            vestedMuxAmount,
            requiredMlpAmount,
            mlpAmount,
            toVestMuxAmount
        );
    }

    function retrieveMuxAssetId(
        ConfigSet storage set,
        address token
    ) internal view returns (uint8) {
        require(token != address(0), "AdapterImp::INVALID_TOKEN");
        IMuxLiquidityPool liquidityPool = IMuxLiquidityPool(set.mustGetAddress(MUX_LIQUIDITY_POOL));
        IMuxLiquidityPool.Asset[] memory assets = liquidityPool.getAllAssetInfo();
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].tokenAddress == token) {
                return assets[i].id;
            }
        }
        revert("MuxAdapter::UNSUPPORTED_ASSET");
    }

    function getPlaceOrderTime(
        ConfigSet storage set,
        uint64 orderId
    ) internal view returns (uint32 placeOrderTime) {
        IMuxOrderBook muxOrderBook = IMuxOrderBook(set.mustGetAddress(MUX_ORDER_BOOK));
        (bytes32[3] memory orderData, bool exists) = muxOrderBook.getOrder(orderId);
        if (exists) {
            placeOrderTime = uint32(bytes4(orderData[1] << 160));
        }
    }

    function cancelOrder(ConfigSet storage set, uint64 orderId) internal returns (bool success) {
        IMuxOrderBook muxOrderBook = IMuxOrderBook(set.mustGetAddress(MUX_ORDER_BOOK));
        try muxOrderBook.cancelOrder(orderId) {
            success = true;
        } catch {
            success = false;
        }
    }

    function placeAddOrder(
        ConfigSet storage set,
        address seniorToken,
        uint256 usdAmount
    ) internal returns (uint64 orderId) {
        IMuxOrderBook muxOrderBook = IMuxOrderBook(set.mustGetAddress(MUX_ORDER_BOOK));
        orderId = muxOrderBook.nextOrderId();
        IERC20Upgradeable(seniorToken).approve(address(muxOrderBook), usdAmount);
        muxOrderBook.placeLiquidityOrder(
            retrieveMuxAssetId(set, seniorToken),
            uint96(usdAmount),
            true
        );
    }

    function placeRemoveOrder(
        ConfigSet storage set,
        address juniorToken,
        address seniorToken,
        uint256 amount
    ) internal returns (uint64 orderId) {
        IMuxOrderBook muxOrderBook = IMuxOrderBook(set.mustGetAddress(MUX_ORDER_BOOK));
        orderId = muxOrderBook.nextOrderId();
        IERC20Upgradeable(juniorToken).approve(address(muxOrderBook), amount);
        muxOrderBook.placeLiquidityOrder(
            retrieveMuxAssetId(set, seniorToken),
            uint96(amount),
            false
        );
    }

    function checkMlpPriceBound(
        ConfigSet storage set,
        uint256 mlpPrice
    ) internal view returns (bool isValid) {
        IMuxLiquidityPool muxLiquidityPool = IMuxLiquidityPool(
            set.mustGetAddress(MUX_LIQUIDITY_POOL)
        );
        (, uint96[2] memory bounds) = muxLiquidityPool.getLiquidityPoolStorage();
        uint256 minPrice = bounds[0];
        uint256 maxPrice = bounds[1];
        isValid = mlpPrice >= minPrice && mlpPrice <= maxPrice;
    }

    // mlp => usd, calc mlp
    function estimateMaxIn(
        ConfigSet storage set,
        uint256 minAmountOut
    ) internal view returns (uint256 maxJuniorIn) {
        // estimated mlp = out * tokenPrice / mlpPrice / (1 - feeRate)
        // feeRate = dynamic + base
        IMuxLiquidityPool muxLiquidityPool = IMuxLiquidityPool(
            set.mustGetAddress(MUX_LIQUIDITY_POOL)
        );
        (uint32[8] memory u32s, uint96[2] memory bounds) = muxLiquidityPool
            .getLiquidityPoolStorage();
        uint256 maxFeeRate = u32s[4] + u32s[5];
        uint256 minPrice = bounds[0];
        maxJuniorIn = (((minAmountOut * ONE) / minPrice) * 1e5) / (1e5 - maxFeeRate);
    }

    function estimateAssetMaxValue(
        ConfigSet storage set,
        uint256 asset
    ) internal view returns (uint256 maxAssetValue) {
        IMuxLiquidityPool muxLiquidityPool = IMuxLiquidityPool(
            set.mustGetAddress(MUX_LIQUIDITY_POOL)
        );
        (, uint96[2] memory bounds) = muxLiquidityPool.getLiquidityPoolStorage();
        uint256 maxPrice = bounds[1];
        maxAssetValue = (asset * maxPrice) / ONE;
    }

    function estimateExactOut(
        ConfigSet storage set,
        uint8 seniorAssetId,
        uint256 juniorAmount,
        uint96 seniorPrice,
        uint96 juniorPrice,
        uint96 currentSeniorValue,
        uint96 targetSeniorValue
    ) internal view returns (uint256 outAmount) {
        IMuxLiquidityPool muxLiquidityPool = IMuxLiquidityPool(
            set.mustGetAddress(MUX_LIQUIDITY_POOL)
        );
        IMuxLiquidityPool.Asset memory seniorAsset = muxLiquidityPool.getAssetInfo(seniorAssetId);
        LiquidityPoolConfig memory config = getLiquidityPoolConfig(muxLiquidityPool);
        require(seniorAsset.isEnabled(), "AdapterImp::DISABLED_ASSET"); // the token is temporarily not ENAbled
        require(seniorAsset.canAddRemoveLiquidity(), "AdapterImp::FORBIDDEN_ASSET"); // the Token cannot be Used to add Liquidity
        seniorPrice = LibReferenceOracle.checkPriceWithSpread(
            seniorAsset,
            seniorPrice,
            config.strictStableDeviation,
            SpreadType.Ask
        );
        // token amount
        uint96 wadAmount = ((uint256(juniorAmount) * uint256(juniorPrice)) / uint256(seniorPrice))
            .toUint96();
        // fee
        uint32 mlpFeeRate = liquidityFeeRate(
            currentSeniorValue,
            targetSeniorValue,
            true,
            ((uint256(wadAmount) * seniorPrice) / 1e18).toUint96(),
            config.liquidityBaseFeeRate,
            config.liquidityDynamicFeeRate
        );
        wadAmount -= ((uint256(wadAmount) * mlpFeeRate) / 1e5).toUint96(); // -fee
        outAmount = seniorAsset.toRaw(wadAmount);
    }

    function estimateMlpExactOut(
        ConfigSet storage set,
        uint8 seniorAssetId,
        uint256 seniorAmount,
        uint96 seniorPrice,
        uint96 juniorPrice,
        uint96 currentSeniorValue,
        uint96 targetSeniorValue
    ) internal view returns (uint256 outAmount) {
        IMuxLiquidityPool muxLiquidityPool = IMuxLiquidityPool(
            set.mustGetAddress(MUX_LIQUIDITY_POOL)
        );
        IMuxLiquidityPool.Asset memory seniorAsset = muxLiquidityPool.getAssetInfo(seniorAssetId);
        LiquidityPoolConfig memory config = getLiquidityPoolConfig(muxLiquidityPool);
        require(seniorAsset.isEnabled(), "AdapterImp::DISABLED_ASSET"); // the token is temporarily not ENAbled
        require(seniorAsset.canAddRemoveLiquidity(), "AdapterImp::FORBIDDEN_ASSET"); // the Token cannot be Used to add Liquidity
        seniorPrice = LibReferenceOracle.checkPriceWithSpread(
            seniorAsset,
            seniorPrice,
            config.strictStableDeviation,
            SpreadType.Bid
        );
        // token amount
        uint96 wadAmount = seniorAsset.toWad(seniorAmount).toUint96();
        // fee
        uint32 mlpFeeRate = liquidityFeeRate(
            currentSeniorValue,
            targetSeniorValue,
            true,
            ((uint256(wadAmount) * seniorPrice) / 1e18).toUint96(),
            config.liquidityBaseFeeRate,
            config.liquidityDynamicFeeRate
        );
        wadAmount -= ((uint256(wadAmount) * mlpFeeRate) / 1e5).toUint96(); // -fee
        outAmount = ((uint256(wadAmount) * uint256(seniorPrice)) / uint256(juniorPrice)).toUint96();
    }

    function getLiquidityPoolConfig(
        IMuxLiquidityPool muxLiquidityPool
    ) internal view returns (LiquidityPoolConfig memory config) {
        (uint32[8] memory u32s, ) = muxLiquidityPool.getLiquidityPoolStorage();
        config.strictStableDeviation = u32s[7];
        config.liquidityBaseFeeRate = u32s[4];
        config.liquidityDynamicFeeRate = u32s[5];
    }

    function liquidityFeeRate(
        uint96 currentAssetValue,
        uint96 targetAssetValue,
        bool isAdd,
        uint96 deltaValue,
        uint32 baseFeeRate, // 1e5
        uint32 dynamicFeeRate // 1e5
    ) internal pure returns (uint32) {
        uint96 newAssetValue;
        if (isAdd) {
            newAssetValue = currentAssetValue + deltaValue;
        } else {
            require(currentAssetValue >= deltaValue, "AdapterImp::INSUFFICIENT_LIQUIDITY");
            newAssetValue = currentAssetValue - deltaValue;
        }
        // | x - target |
        uint96 oldDiff = currentAssetValue > targetAssetValue
            ? currentAssetValue - targetAssetValue
            : targetAssetValue - currentAssetValue;
        uint96 newDiff = newAssetValue > targetAssetValue
            ? newAssetValue - targetAssetValue
            : targetAssetValue - newAssetValue;
        if (targetAssetValue == 0) {
            // avoid division by 0
            return baseFeeRate;
        } else if (newDiff < oldDiff) {
            // improves
            uint32 rebate = ((uint256(dynamicFeeRate) * uint256(oldDiff)) /
                uint256(targetAssetValue)).toUint32();
            return baseFeeRate > rebate ? baseFeeRate - rebate : 0;
        } else {
            // worsen
            uint96 avgDiff = (oldDiff + newDiff) / 2;
            avgDiff = uint96(MathUpgradeable.min(avgDiff, targetAssetValue));
            uint32 dynamic = ((uint256(dynamicFeeRate) * uint256(avgDiff)) /
                uint256(targetAssetValue)).toUint32();
            return baseFeeRate + dynamic;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/LibConfigSet.sol";
import "../libraries/LibUniswap.sol";
import "../mux/MuxAdapter.sol";

import "./RouterUtilImp.sol";
import "./Type.sol";
import "./RouterJuniorImp.sol";
import "./RouterSeniorImp.sol";
import "./RouterRebalanceImp.sol";
import "./RouterRewardImp.sol";
import "./RouterStatesImp.sol";

library RouterImp {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using LibConfigSet for ConfigSet;
    using LibTypeCast for bytes32;

    using MuxAdapter for ConfigSet;
    using RouterUtilImp for RouterStateStore;
    using RouterJuniorImp for RouterStateStore;
    using RouterSeniorImp for RouterStateStore;
    using RouterRewardImp for RouterStateStore;
    using RouterStatesImp for RouterStateStore;
    using RouterRebalanceImp for RouterStateStore;

    event Liquidate(uint256 balance);
    event LiquidateInterrupted();

    function initialize(
        RouterStateStore storage store,
        address seniorVault,
        address juniorVault,
        address rewardController
    ) public {
        require(seniorVault != address(0), "RouterImp::INVALID_ADDRESS");
        require(juniorVault != address(0), "RouterImp::INVALID_ADDRESS");
        require(rewardController != address(0), "RouterImp::INVALID_ADDRESS");
        // skip 0
        store.seniorVault = ISeniorVault(seniorVault);
        store.juniorVault = IJuniorVault(juniorVault);
        store.rewardController = IRewardController(rewardController);
    }

    function depositJunior(RouterStateStore storage store, address account, uint256 assets) public {
        store.depositJunior(account, assets);
    }

    function withdrawJunior(
        RouterStateStore storage store,
        address account,
        uint256 shares
    ) public {
        store.withdrawJunior(account, shares);
    }

    function depositSenior(RouterStateStore storage store, address account, uint256 assets) public {
        store.depositSenior(account, assets);
    }

    function withdrawSenior(
        RouterStateStore storage store,
        address account,
        uint256 shares,
        bool acceptPenalty
    ) public {
        store.withdrawSenior(account, shares, acceptPenalty);
    }

    function refundJunior(RouterStateStore storage store) public {
        store.refundJunior(store.pendingRefundAssets);
    }

    // =============================================== Rebalance ===============================================
    function juniorNavPerShare(
        RouterStateStore storage store,
        uint256 seniorPrice,
        uint256 juniorPrice
    ) internal view returns (uint256) {
        uint256 juniorTotalShares = store.juniorTotalSupply();
        uint256 juniorTotalValues = store.juniorTotalAssets() * juniorPrice;
        uint256 juniorTotalBorrows = store.toJuniorUnit(store.seniorBorrows()) * seniorPrice;
        if (juniorTotalValues > juniorTotalBorrows) {
            return (juniorTotalValues - juniorTotalBorrows) / juniorTotalShares;
        } else {
            return 0;
        }
    }

    function juniorLeverage(
        RouterStateStore storage store,
        uint256 seniorPrice,
        uint256 juniorPrice
    ) internal view returns (uint256 leverage) {
        require(juniorPrice != 0, "RouterImp::INVALID_PRICE");
        require(seniorPrice != 0, "RouterImp::INVALID_PRICE");
        uint256 juniorTotalBorrows = store.toJuniorUnit(store.seniorBorrows()) * seniorPrice;
        if (juniorTotalBorrows == 0) {
            return ONE;
        }
        uint256 juniorTotalValue = store.juniorTotalAssets() * juniorPrice;
        if (juniorTotalValue <= juniorTotalBorrows) {
            return type(uint256).max; // should be liquidated
        }
        uint256 principle = juniorTotalValue - juniorTotalBorrows;
        return juniorTotalValue / (principle / ONE);
    }

    function isRebalancing(RouterStateStore storage store) internal view returns (bool) {
        return store.isRebalancing();
    }

    function isJuniorBalanced(
        RouterStateStore storage store,
        uint256 seniorPrice,
        uint256 juniorPrice
    ) public view returns (bool isBalanced, bool isBorrow, uint256 delta) {
        uint256 targetLeverage = store.config.getUint256(TARGET_LEVERAGE);
        require(targetLeverage > ONE, "RouterImp::INVALID_LEVERAGE");
        uint256 assetUsd = (store.juniorTotalAssets() * juniorPrice) / ONE;
        uint256 borrowUsd = (store.toJuniorUnit(store.seniorBorrows()) * seniorPrice) / ONE;
        if (assetUsd > borrowUsd) {
            uint256 threshold = store.config.getUint256(REBALANCE_THRESHOLD);
            uint256 thresholdUsd = store.config.getUint256(REBALANCE_THRESHOLD_USD);
            uint256 principleUsd = assetUsd - borrowUsd;
            uint256 targetBorrowUsd = (principleUsd * (targetLeverage - ONE)) / ONE;
            isBorrow = targetBorrowUsd >= borrowUsd;
            uint256 deltaUsd = isBorrow ? targetBorrowUsd - borrowUsd : borrowUsd - targetBorrowUsd;
            delta = store.toSeniorUnit((deltaUsd * ONE) / seniorPrice);
            if (delta >= thresholdUsd && ((deltaUsd * ONE) / principleUsd) >= threshold) {
                isBalanced = false;
            } else {
                isBalanced = true;
            }
        } else {
            // wait for liquidation, not rebalanced
            isBalanced = true;
            isBorrow = false;
            delta = 0;
        }
    }

    function updateRewards(RouterStateStore storage store) public {
        store.updateRewards(address(0));
    }

    function updateRewards(RouterStateStore storage store, address account) public {
        store.updateRewards(account);
    }

    function rebalance(
        RouterStateStore storage store,
        uint256 seniorPrice,
        uint256 juniorPrice
    ) public {
        require(!store.isRebalancing(), "RouterImp::INPROGRESS");
        (bool isBalanced, bool isBorrow, uint256 delta) = isJuniorBalanced(
            store,
            seniorPrice,
            juniorPrice
        );
        require(!isBalanced, "RouterImp::BALANCED");
        require(store.config.checkMlpPriceBound(juniorPrice), "RouterImp::PRICE_OUT_OF_BOUNDS");
        // decimal 18 => decimals of senior asset
        if (isBorrow) {
            uint256 borrowable = store.seniorVault.borrowable(address(this));
            if (borrowable > store.pendingSeniorAssets) {
                borrowable -= store.pendingSeniorAssets;
            } else {
                borrowable = 0;
            }
            uint256 toBorrow = MathUpgradeable.min(borrowable, delta);
            // add a threshold to toBorrow
            // avoid to buy too small amount juniors
            store.buyJunior(toBorrow);
        } else {
            // to wad
            uint256 assets = store.config.estimateMaxIn(store.toJuniorUnit(delta));
            store.sellJunior(assets);
        }
    }

    function liquidate(
        RouterStateStore storage store,
        uint256 seniorPrice,
        uint256 juniorPrice
    ) public {
        require(store.config.checkMlpPriceBound(juniorPrice), "RouterImp::PRICE_OUT_OF_BOUNDS");
        uint256 leverage = juniorLeverage(store, seniorPrice, juniorPrice);
        uint256 maxLeverage = store.config.getUint256(LIQUIDATION_LEVERAGE);
        require(leverage > maxLeverage, "RouterImp::NOT_LIQUIDATABLE");
        if (cancelAllPendingOperations(store)) {
            store.isLiquidated = true;
            uint256 totalBalance = store.juniorVault.totalAssets();
            store.sellJunior(totalBalance);
            emit Liquidate(totalBalance);
        } else {
            emit LiquidateInterrupted();
        }
    }

    // =============================================== Callbacks ===============================================
    function onOrderFilled(
        RouterStateStore storage store,
        MuxOrderContext memory context,
        uint256 amountOut
    ) public {
        address account = store.pendingOrders[context.orderId];
        UserState storage state = store.users[account];
        if (state.status == UserStatus.DepositJunior) {
            store.onDepositJuniorSuccess(context, account, amountOut);
        } else if (state.status == UserStatus.WithdrawJunior) {
            store.onWithdrawJuniorSuccess(context, account, amountOut);
        } else if (state.status == UserStatus.WithdrawSenior) {
            store.onWithdrawSeniorSuccess(context, account, amountOut);
        } else if (state.status == UserStatus.BuyJunior) {
            store.onBuyJuniorSuccess(context, amountOut);
        } else if (state.status == UserStatus.SellJunior) {
            store.onSellJuniorSuccess(context, amountOut);
        } else if (state.status == UserStatus.RefundJunior) {
            store.onRefundJuniorSuccess(context, amountOut);
        } else {
            revert("ImpRouter::INVALID_STATUS");
        }
    }

    function onOrderCancelled(RouterStateStore storage store, uint64 orderId) public {
        address account = store.pendingOrders[orderId];
        cancelPendingStates(store, account);
    }

    function getPendingUserCount(RouterStateStore storage store) internal view returns (uint256) {
        return store.pendingUsers.length();
    }

    function getPendingUsers(
        RouterStateStore storage store,
        uint256 begin,
        uint256 count
    ) internal view returns (address[] memory users) {
        count = MathUpgradeable.min(count, store.pendingUsers.length() - begin);
        users = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            users[i] = store.pendingUsers.at(i + begin);
        }
    }

    function getUserOrderTime(
        RouterStateStore storage store,
        uint64 orderId
    ) external view returns (uint32 placeOrderTime) {
        return store.config.getPlaceOrderTime(orderId);
    }

    function cancelAllPendingOperations(RouterStateStore storage store) internal returns (bool) {
        uint256 count = getPendingUserCount(store);
        uint64[] memory orderIds = new uint64[](count);
        for (uint256 i = 0; i < count; i++) {
            orderIds[i] = store.users[store.pendingUsers.at(i)].orderId;
        }
        for (uint256 i = 0; i < orderIds.length; i++) {
            if (orderIds[i] != 0) {
                bool success = store.config.cancelOrder(orderIds[i]);
                if (!success) {
                    return false;
                }
            }
        }
        return true;
    }

    function cancelPendingOperation(RouterStateStore storage store, address account) internal {
        UserState memory userState = store.users[msg.sender];
        require(userState.status != UserStatus.Idle, "RouterV1::INPROPER_STATUS");
        if (userState.orderId != 0) {
            store.config.cancelOrder(userState.orderId);
        } else {
            cancelPendingStates(store, account);
        }
    }

    function cancelPendingStates(RouterStateStore storage store, address account) internal {
        UserState storage state = store.users[account];
        if (state.status == UserStatus.DepositJunior) {
            store.onDepositJuniorFailed(account);
        } else if (state.status == UserStatus.WithdrawJunior) {
            store.onWithdrawJuniorFailed(account);
        } else if (state.status == UserStatus.WithdrawSenior) {
            store.onWithdrawSeniorFailed(account);
        } else if (state.status == UserStatus.BuyJunior) {
            store.onBuyJuniorFailed();
        } else if (state.status == UserStatus.SellJunior) {
            store.onSellJuniorFailed();
        } else if (state.status == UserStatus.RefundJunior) {
            store.onRefundJuniorFailed();
        } else {
            revert("ImpRouter::INVALID_STATUS");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../libraries/LibConfigSet.sol";
import "../libraries/LibUniswap.sol";
import "../mux/MuxAdapter.sol";

import "./RouterUtilImp.sol";
import "./RouterStatesImp.sol";
import "./RouterRewardImp.sol";
import "./Type.sol";

library RouterJuniorImp {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibConfigSet for ConfigSet;
    using LibTypeCast for bytes32;
    using MuxAdapter for ConfigSet;
    using RouterUtilImp for RouterStateStore;
    using RouterStatesImp for RouterStateStore;
    using RouterRewardImp for RouterStateStore;

    event DepositJunior(address indexed account, uint256 juniorAssetsToDeposit);
    event HandleDepositJunior(address indexed account, uint256 juniorAssetsToDeposit);
    event DepositJuniorSuccess(
        address indexed account,
        uint256 juniorAssetsToDeposit,
        uint256 juniorAssetsBought,
        uint256 juniorSharesToMint
    );
    event DepositJuniorFailed(address indexed account, uint256 juniorAssetsToDeposit);

    event WithdrawJunior(
        address indexed account,
        uint256 juniorSharesToWithdraw,
        uint256 juniorAssetsToWithdraw
    );
    event HandleWithdrawJunior(
        address indexed account,
        uint256 juniorSharesToWithdraw,
        uint256 juniorAssetsToWithdraw,
        uint256 seniorAssetsToRepay,
        uint256 juniorAssetsToRemove
    );
    event WithdrawJuniorSuccess(
        address indexed account,
        uint256 seniorAssetsBought,
        uint256 seniorAssetsToRepay,
        uint256 juniorAssetsRemains,
        uint256 seniorAssetsRemains
    );
    event WithdrawJuniorFailed(
        address indexed account,
        uint256 juniorSharesToWithdraw,
        uint256 juniorAssetsToWithdraw
    );

    function depositJunior(
        RouterStateStore storage store,
        address account,
        uint256 juniorAssetsToDeposit
    ) public {
        require(juniorAssetsToDeposit > 0, "RouterJuniorImp::ZERO_AMOUNT");

        uint256 assetSupplyCap = store.juniorVault.getConfig(ASSET_SUPPLY_CAP).toUint256();
        if (assetSupplyCap > 0) {
            IMuxLiquidityPool muxLiquidityPool = IMuxLiquidityPool(
                store.config.mustGetAddress(MUX_LIQUIDITY_POOL)
            );
            (, uint96[2] memory bounds) = muxLiquidityPool.getLiquidityPoolStorage();
            uint256 maxPrice = bounds[1];
            uint256 juniorNetValue = (store.juniorTotalAssets() * maxPrice) /
                ONE -
                store.toJuniorUnit(store.seniorBorrows());
            uint256 juniorValueToDeposit = (juniorAssetsToDeposit * maxPrice) / ONE; // USD
            require(
                juniorValueToDeposit + juniorNetValue + store.pendingJuniorDeposits <=
                    assetSupplyCap,
                "RouterJuniorImp::EXCEEDS_SUPPLY_CAP"
            );
        }

        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransferFrom(
            account,
            address(this),
            juniorAssetsToDeposit
        );
        store.setDepositJuniorStatus(account, juniorAssetsToDeposit);
        uint64 orderId = store.config.placeAddOrder(store.seniorVault.depositToken(), 0);
        store.setOrderId(account, orderId);
        emit DepositJunior(account, juniorAssetsToDeposit);
    }

    function onDepositJuniorSuccess(
        RouterStateStore storage store,
        MuxOrderContext memory context,
        address account,
        uint256 juniorAssetsBought
    ) public {
        // now the mechinism is retrieving junior price from a 0-amount order
        require(juniorAssetsBought == 0, "RouterJuniorImp::INVALID_AMOUNT_OUT");
        uint256 juniorAssetsToDeposit = store.getDepositJuniorStatus(account);
        // test supply cap
        uint256 seniorValueBorrows = (store.toJuniorUnit(store.seniorBorrows()) *
            context.seniorPrice); // USD
        uint256 juniorNetValue = store.juniorTotalAssets() *
            context.juniorPrice -
            seniorValueBorrows;

        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
            address(store.juniorVault),
            juniorAssetsToDeposit
        );
        uint256 juniorSharesToMint = convertToShares(
            store.juniorVault.totalSupply(),
            juniorNetValue / context.juniorPrice,
            juniorAssetsToDeposit
        );
        store.juniorVault.deposit(juniorAssetsToDeposit, juniorSharesToMint, account);
        store.cleanDepositJuniorStatus(account);
        emit DepositJuniorSuccess(
            account,
            juniorAssetsToDeposit,
            juniorAssetsBought,
            juniorSharesToMint
        );
    }

    function convertToShares(
        uint256 totalSupply,
        uint256 totalAssets,
        uint256 assets
    ) internal pure returns (uint256) {
        return assets.mulDiv(totalSupply + 1, totalAssets + 1, MathUpgradeable.Rounding.Down);
    }

    // @notice Return the junior assets to user if failed.
    function onDepositJuniorFailed(RouterStateStore storage store, address account) public {
        uint256 juniorAssetsToDeposit = store.getDepositJuniorStatus(account);
        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
            account,
            juniorAssetsToDeposit
        );
        store.cleanDepositJuniorStatus(account);
        emit DepositJuniorFailed(account, juniorAssetsToDeposit);
    }

    // =============================================== Withdraw Junior ===============================================
    function withdrawJunior(
        RouterStateStore storage store,
        address account,
        uint256 juniorSharesToWithdraw
    ) public {
        require(juniorSharesToWithdraw > 0, "RouterJuniorImp::ZERO_AMOUNT");
        require(
            juniorSharesToWithdraw <= store.juniorVault.balanceOf(account),
            "RouterJuniorImp::EXCEEDS_REDEEMABLE"
        );
        uint256 borrows = store.seniorBorrows();
        uint256 juniorTotalSupply = store.juniorTotalSupply();
        uint256 seniorAssetsToRepay = juniorTotalSupply != 0
            ? ((borrows * juniorSharesToWithdraw) / juniorTotalSupply)
            : borrows;
        uint256 juniorAssetsToRemove = store.config.estimateMaxIn(
            store.toJuniorUnit(seniorAssetsToRepay)
        );
        uint256 juniorAssetsToWithdraw = store.juniorVault.withdraw(
            account,
            account,
            juniorSharesToWithdraw,
            address(this)
        );
        require(juniorAssetsToWithdraw >= seniorAssetsToRepay, "ImpRouter::UNSAFE");

        uint64 orderId = store.config.placeRemoveOrder(
            store.juniorVault.depositToken(),
            store.seniorVault.depositToken(),
            juniorAssetsToRemove
        );
        store.setOrderId(account, orderId);
        store.setWithdrawJuniorStatus(
            account,
            juniorSharesToWithdraw,
            juniorAssetsToWithdraw,
            seniorAssetsToRepay,
            juniorAssetsToRemove
        );
        // the status of ticket should be init
        emit WithdrawJunior(account, juniorSharesToWithdraw, juniorAssetsToWithdraw);
    }

    function onWithdrawJuniorSuccess(
        RouterStateStore storage store,
        MuxOrderContext memory,
        address account,
        uint256 seniorAssetsBought // senior token
    ) public {
        (
            ,
            uint256 juniorAssetsToWithdraw,
            uint256 seniorAssetsToRepay,
            uint256 juniorAssetsToRemove
        ) = store.getWithdrawJuniorStatus(account);

        uint256 seniorAssetsBorrowed = store.seniorBorrows();
        seniorAssetsToRepay = MathUpgradeable.min(seniorAssetsToRepay, seniorAssetsBorrowed);
        require(seniorAssetsBought >= seniorAssetsToRepay, "ImpJunior::INSUFFICIENT_REPAYMENT");
        uint256 juniorAssetsRemains = juniorAssetsToWithdraw - juniorAssetsToRemove;

        // repay
        if (seniorAssetsToRepay > 0) {
            IERC20Upgradeable(store.seniorVault.depositToken()).safeTransfer(
                address(store.seniorVault),
                seniorAssetsToRepay
            );
            store.seniorVault.repay(seniorAssetsToRepay);
        }
        // senior => user
        uint256 seniorAssetsRemains = seniorAssetsBought - seniorAssetsToRepay;
        if (seniorAssetsRemains > 0) {
            IERC20Upgradeable(store.seniorVault.depositToken()).safeTransfer(
                account,
                seniorAssetsRemains
            );
        }
        // junior => user
        if (juniorAssetsRemains > 0) {
            IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
                account,
                juniorAssetsRemains
            );
        }
        store.cleanWithdrawJuniorStatus(account);
        emit WithdrawJuniorSuccess(
            account,
            seniorAssetsBought,
            seniorAssetsToRepay,
            juniorAssetsRemains,
            seniorAssetsRemains
        );
    }

    function onWithdrawJuniorFailed(RouterStateStore storage store, address account) public {
        (uint256 juniorSharesToWithdraw, uint256 juniorAssetsToWithdraw, , ) = store
            .getWithdrawJuniorStatus(account);
        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
            address(store.juniorVault),
            juniorAssetsToWithdraw
        );
        store.juniorVault.transferIn(juniorAssetsToWithdraw);
        store.juniorVault.deposit(juniorAssetsToWithdraw, juniorSharesToWithdraw, account);
        store.cleanWithdrawJuniorStatus(account);
        emit WithdrawJuniorFailed(account, juniorSharesToWithdraw, juniorAssetsToWithdraw);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/LibConfigSet.sol";
import "../libraries/LibUniswap.sol";
import "../mux/MuxAdapter.sol";

import "./RouterUtilImp.sol";
import "./RouterStatesImp.sol";
import "./RouterStatesImp.sol";
import "./RouterRewardImp.sol";
import "./Type.sol";

library RouterRebalanceImp {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibConfigSet for ConfigSet;
    using LibTypeCast for bytes32;
    using MuxAdapter for ConfigSet;
    using RouterUtilImp for RouterStateStore;
    using RouterStatesImp for RouterStateStore;
    using RouterRewardImp for RouterStateStore;

    event BuyJunior(uint256 seniorAssetToSpend, uint64 orderId);
    event BuyJuniorSuccess(
        uint256 seniorAssetsSpent,
        uint256 juniorAssetsBought,
        uint256 juniorPrice
    );
    event BuyJuniorFailed(uint256 seniorAssetToSpend);

    event SellJunior(uint256 juniorAssetsToSpend, uint256 orderId);
    event SellJuniorSuccess(
        uint256 juniorAssetsSpent,
        uint256 seniorAssetsBought,
        uint256 seniorAssetsOverflow,
        uint256 juniorPrice
    );
    event SellJuniorFailed(uint256 juniorAssetsToSpend);

    event RefundJunior(uint256 seniorAssetToSpend, uint64 orderId);
    event RefundJuniorSuccess(
        uint256 seniorAssetsSpent,
        uint256 juniorAssetsBought,
        uint256 juniorPrice
    );
    event RefundJuniorFailed(uint256 seniorAssetToSpend);

    // ==================================== Buy Junior ============================================
    function buyJunior(RouterStateStore storage store, uint256 seniorAssetToSpend) internal {
        require(seniorAssetToSpend > 0, "RouterJuniorImp::ZERO_AMOUNT");
        store.seniorVault.borrow(seniorAssetToSpend);
        store.setBuyJuniorStatus(seniorAssetToSpend);
        uint64 orderId = store.config.placeAddOrder(
            store.seniorVault.depositToken(),
            seniorAssetToSpend
        );
        store.setOrderId(address(0), orderId);
        emit BuyJunior(seniorAssetToSpend, orderId);
    }

    function onBuyJuniorSuccess(
        RouterStateStore storage store,
        MuxOrderContext memory context,
        uint256 juniorAssetsBought
    ) public {
        uint256 seniorAssetsSpent = store.getBuyJuniorStatus();
        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
            address(store.juniorVault),
            juniorAssetsBought
        );
        store.juniorVault.transferIn(juniorAssetsBought);
        store.cleanBuyJuniorStatus();

        emit BuyJuniorSuccess(seniorAssetsSpent, juniorAssetsBought, context.juniorPrice);
    }

    function onBuyJuniorFailed(RouterStateStore storage store) public {
        store.cleanOrderId(address(0));
        uint256 seniorAssetsSpent = store.getBuyJuniorStatus();
        emit BuyJuniorFailed(seniorAssetsSpent);
    }

    // ==================================== Sell Junior ============================================
    function sellJunior(RouterStateStore storage store, uint256 juniorAssetsToSpend) public {
        require(juniorAssetsToSpend > 0, "RouterJuniorImp::ZERO_AMOUNT");
        store.juniorVault.transferOut(juniorAssetsToSpend);
        uint64 orderId = store.config.placeRemoveOrder(
            store.juniorVault.depositToken(),
            store.seniorVault.depositToken(),
            juniorAssetsToSpend
        );
        store.setOrderId(address(0), orderId);
        store.setSellJuniorStatus(juniorAssetsToSpend);
        emit SellJunior(juniorAssetsToSpend, orderId);
    }

    function onSellJuniorSuccess(
        RouterStateStore storage store,
        MuxOrderContext memory context,
        uint256 seniorAssetsBought
    ) public {
        uint256 juniorAssetsSpent = store.getSellJuniorStatus();
        uint256 seniorAssetsBorrrowed = store.seniorBorrows();
        uint256 seniorAssetsToRepay = MathUpgradeable.min(
            seniorAssetsBought,
            seniorAssetsBorrrowed
        );
        IERC20Upgradeable(store.seniorVault.depositToken()).safeTransfer(
            address(store.seniorVault),
            seniorAssetsToRepay
        );
        store.seniorVault.repay(seniorAssetsToRepay);
        store.cleanSellJuniorStatus();
        // 3. return the remaining over total debts to junior.
        //    only the last junior or liquidation will have overflows.
        uint256 seniorAssetsOverflow = seniorAssetsBought - seniorAssetsToRepay;
        if (seniorAssetsOverflow > 0) {
            store.pendingRefundAssets += seniorAssetsOverflow;
        }
        if (store.isLiquidated) {
            store.isLiquidated = false;
        }
        emit SellJuniorSuccess(
            juniorAssetsSpent,
            seniorAssetsToRepay,
            seniorAssetsOverflow,
            context.juniorPrice
        );
    }

    function onSellJuniorFailed(RouterStateStore storage store) public {
        uint256 juniorAssetsSpent = store.getSellJuniorStatus();
        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
            address(store.juniorVault),
            juniorAssetsSpent
        );
        store.juniorVault.transferIn(juniorAssetsSpent);
        store.cleanSellJuniorStatus();
        emit SellJuniorFailed(juniorAssetsSpent);
    }

    // refund
    function refundJunior(RouterStateStore storage store, uint256 seniorAssetToSpend) internal {
        require(seniorAssetToSpend > 0, "RouterJuniorImp::ZERO_AMOUNT");
        store.setRefundJuniorStatus(seniorAssetToSpend);
        uint64 orderId = store.config.placeAddOrder(
            store.seniorVault.depositToken(),
            seniorAssetToSpend
        );
        store.setOrderId(address(0), orderId);
        emit RefundJunior(seniorAssetToSpend, orderId);
    }

    function onRefundJuniorSuccess(
        RouterStateStore storage store,
        MuxOrderContext memory context,
        uint256 juniorAssetsBought
    ) public {
        uint256 seniorAssetsSpent = store.getRefundJuniorStatus();
        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
            address(store.juniorVault),
            juniorAssetsBought
        );
        store.juniorVault.transferIn(juniorAssetsBought);
        store.cleanRefundJuniorStatus();
        emit RefundJuniorSuccess(seniorAssetsSpent, juniorAssetsBought, context.juniorPrice);
    }

    function onRefundJuniorFailed(RouterStateStore storage store) public {
        store.cleanOrderId(address(0));
        uint256 seniorAssetsSpent = store.getRefundJuniorStatus();
        emit RefundJuniorFailed(seniorAssetsSpent);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/mux/IMuxRewardRouter.sol";
import "./Type.sol";
import "./RouterUtilImp.sol";

library RouterRewardImp {
    using RouterUtilImp for RouterStateStore;
    using LibConfigSet for ConfigSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event UpdateRewards(address[] rewardTokens, uint256[] rewardAmounts, uint256 utilized);

    function updateRewards(RouterStateStore storage store, address account) internal {
        //  function updateRewards(RouterStateStore storage states) internal {
        IMuxRewardRouter muxRewardRouter = IMuxRewardRouter(
            store.config.mustGetAddress(MUX_REWARD_ROUTER)
        );
        store.juniorVault.collectMuxRewards(address(this));
        address[] memory rewardTokens = new address[](2);
        rewardTokens[0] = muxRewardRouter.weth();
        rewardTokens[1] = muxRewardRouter.mcb();
        uint256[] memory rewardAmounts = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            rewardAmounts[i] = IERC20Upgradeable(rewardTokens[i]).balanceOf(address(this));
            IERC20Upgradeable(rewardTokens[i]).safeTransfer(
                address(store.rewardController),
                rewardAmounts[i]
            );
        }
        uint256 utilized = store.seniorVault.borrows(address(this));
        store.rewardController.notifyRewards(rewardTokens, rewardAmounts, utilized);
        store.rewardController.updateRewards(account);

        emit UpdateRewards(rewardTokens, rewardAmounts, utilized);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/LibConfigSet.sol";
import "../libraries/LibUniswap.sol";
import "../mux/MuxAdapter.sol";

import "./RouterUtilImp.sol";
import "./RouterStatesImp.sol";
import "./RouterRebalanceImp.sol";
import "./RouterRewardImp.sol";
import "./Type.sol";

library RouterSeniorImp {
    using RouterUtilImp for RouterStateStore;
    using RouterRewardImp for RouterStateStore;
    using RouterStatesImp for RouterStateStore;
    using RouterRebalanceImp for RouterStateStore;
    using MuxAdapter for ConfigSet;
    using LibConfigSet for ConfigSet;
    using LibTypeCast for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event DepositSenior(address indexed account, uint256 seniorAssetsToDeposit);

    event WithdrawSenior(address indexed account, uint256 seniorSharesToWithdraw);
    event WithdrawSeniorDelayed(
        address indexed account,
        uint256 seniorSharesToWithdraw,
        uint256 seniorAssetsToWithdraw,
        uint256 seniorAssetsWithdrawable
    );
    event HandleWithdrawSenior(
        address indexed account,
        uint256 seniorSharesToWithdraw,
        uint256 seniorAssetsToWithdraw,
        uint256 juniorAssetsToRemove,
        uint256 seniorAssetsWithdrawable
    );
    event WithdrawSeniorSuccess(
        address indexed account,
        uint256 seniorSharesToWithdraw,
        uint256 seniorAssetsToWithdraw,
        uint256 juniorAssetsToRemove,
        uint256 seniorAssetsWithdrawable,
        uint256 seniorAssetsToRepay,
        uint256 seniorAssetsOverflow
    );
    event WithdrawSeniorFailed(
        address indexed account,
        uint256 seniorSharesToWithdraw,
        uint256 seniorAssetsToWithdraw,
        uint256 juniorAssetsToRemove,
        uint256 seniorAssetsWithdrawable
    );

    // =============================================== Deposit Senior ===============================================
    function depositSenior(
        RouterStateStore storage store,
        address account,
        uint256 seniorAssetsToDeposit
    ) public {
        require(seniorAssetsToDeposit > 0, "RouterSeniorImp::ZERO_AMOUNT");
        IERC20Upgradeable(store.seniorVault.depositToken()).safeTransferFrom(
            account,
            address(store.seniorVault),
            seniorAssetsToDeposit
        );
        store.seniorVault.deposit(seniorAssetsToDeposit, account);
        emit DepositSenior(account, seniorAssetsToDeposit);
    }

    // =============================================== Withdraw Senior ===============================================
    function checkTimelock(
        RouterStateStore storage store,
        address account,
        bool acceptPenalty
    ) internal view {
        bool isLocked = store.seniorVault.timelock(account) >= block.timestamp;
        require(!isLocked || (isLocked && acceptPenalty), "RouterSeniorImp::LOCKED");
    }

    function withdrawSenior(
        RouterStateStore storage store,
        address account,
        uint256 seniorSharesToWithdraw, // assets
        bool acceptPenalty
    ) public {
        checkTimelock(store, account, acceptPenalty);
        require(
            seniorSharesToWithdraw <= store.seniorVault.balanceOf(account),
            "RouterSeniorImp::EXCEEDS_BALANCE"
        );
        // withdraw
        uint256 seniorAssetsToWithdraw = store.seniorVault.convertToAssets(seniorSharesToWithdraw);
        uint256 seniorAssetsWithdrawable = store.seniorVault.totalAssets() >
            store.pendingSeniorAssets
            ? store.seniorVault.totalAssets() - store.pendingSeniorAssets
            : 0;

        if (seniorAssetsToWithdraw <= seniorAssetsWithdrawable) {
            store.seniorVault.withdraw(msg.sender, account, seniorSharesToWithdraw, account);
            emit WithdrawSenior(account, seniorSharesToWithdraw);
        } else {
            uint256 juniorAssetsToRemove = store.config.estimateMaxIn(
                store.toJuniorUnit(seniorAssetsToWithdraw - seniorAssetsWithdrawable)
            );
            store.juniorVault.transferOut(juniorAssetsToRemove);
            uint64 orderId = store.config.placeRemoveOrder(
                store.juniorVault.depositToken(),
                store.seniorVault.depositToken(),
                juniorAssetsToRemove
            );
            store.setOrderId(account, orderId);
            store.setWithdrawSeniorStatus(
                account,
                seniorSharesToWithdraw,
                seniorAssetsToWithdraw,
                juniorAssetsToRemove,
                seniorAssetsWithdrawable
            );
            emit WithdrawSeniorDelayed(
                account,
                seniorSharesToWithdraw,
                seniorAssetsToWithdraw,
                seniorAssetsWithdrawable
            );
        }
    }

    function onWithdrawSeniorSuccess(
        RouterStateStore storage store,
        MuxOrderContext memory,
        address account,
        uint256 seniorAssetsBought
    ) public {
        (
            uint256 seniorSharesToWithdraw,
            uint256 seniorAssetsToWithdraw,
            uint256 juniorAssetsToRemove,
            uint256 seniorAssetsWithdrawable
        ) = store.getWithdrawSeniorStatus(account);
        require(
            seniorAssetsBought + seniorAssetsWithdrawable >= seniorAssetsToWithdraw,
            "RouterSeniorImp::INSUFFICIENT_REPAYMENT"
        );
        uint256 seniorAssetsBorrrowed = store.seniorBorrows();
        uint256 seniorAssetsToRepay = MathUpgradeable.min(
            seniorAssetsBought,
            seniorAssetsBorrrowed
        );
        IERC20Upgradeable(store.seniorVault.depositToken()).safeTransfer(
            address(store.seniorVault),
            seniorAssetsToRepay
        );
        store.seniorVault.repay(seniorAssetsToRepay);
        store.seniorVault.withdraw(account, account, seniorSharesToWithdraw, account);
        store.cleanWithdrawSeniorStatus(account);
        uint256 seniorAssetsOverflow = seniorAssetsBought - seniorAssetsToRepay;
        if (seniorAssetsOverflow > 0) {
            store.pendingRefundAssets += seniorAssetsOverflow;
        }

        emit WithdrawSeniorSuccess(
            account,
            seniorSharesToWithdraw,
            seniorAssetsToWithdraw,
            juniorAssetsToRemove,
            seniorAssetsWithdrawable,
            seniorAssetsToRepay,
            seniorAssetsOverflow
        );
    }

    function onWithdrawSeniorFailed(RouterStateStore storage store, address account) public {
        (
            uint256 seniorSharesToWithdraw,
            uint256 seniorAssetsToWithdraw,
            uint256 juniorAssetsToRemove,
            uint256 seniorAssetsWithdrawable
        ) = store.getWithdrawSeniorStatus(account);
        IERC20Upgradeable(store.juniorVault.depositToken()).safeTransfer(
            address(store.juniorVault),
            juniorAssetsToRemove
        );
        store.juniorVault.transferIn(juniorAssetsToRemove);
        store.cleanWithdrawSeniorStatus(account);
        emit WithdrawSeniorFailed(
            account,
            seniorSharesToWithdraw,
            seniorAssetsToWithdraw,
            juniorAssetsToRemove,
            seniorAssetsWithdrawable
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./Type.sol";

library RouterStatesImp {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // UserStatus.DepositJunior
    // store.users[account].stateValues[0] // The amount of mlp (1e18) that user want to depost (*)
    // eg: A wants to deposit 10 mlp. then
    //     store.users[account].stateValues[0] will be 10 mlp.

    // UserStatus.WithdrawJunior
    // store.users[account].stateValues[0] // The amount of junior share that user want to withdraw (*)
    // store.users[account].stateValues[1] // The amount of junior asset (mlp) to withdraw
    // store.users[account].stateValues[2] // The amount of usdc to repay to seniorVault
    // store.users[account].stateValues[3] // The amount of mlp to sell to repay to seniorVault
    // eg: B wants to withdraw 10 junior shares, totalAsset = 20, totalSupply = 20, totalDebt = 5, mlpPrice = $1 then
    //     store.users[account].stateValues[0] = 10 shares
    //     store.users[account].stateValues[1] = totalAsset * share / totalSupply = 20 * 10 / 20 = 10 mlp
    //     store.users[account].stateValues[2] = totalDebt * share / totalSupply = 5 * 10 / 20 = 2.5 usdc
    //     store.users[account].stateValues[3] = 2.5 / mlpPrice = 2.5 mlp (need to sell 2.5 mlp for 2.5 usdc to repay debts)

    // UserStatus.WithdrawSenior
    // store.users[account].stateValues[0] // The amount of senior share that user want to withdraw (*)
    // store.users[account].stateValues[1] // The amount of senior asset (usdc) to withdraw
    // store.users[account].stateValues[2] // The amount of junior asset (mlp) to sell to repay seniorVault
    // store.users[account].stateValues[3] // The amount of senior asset (usdc) reservs for withdraw
    // eg: C wants to withdraw 10 senior shares, totalAsset = 5, totalSupply = 20, mlpPrice = $1 then
    //     store.users[account].stateValues[0] = 10 shares
    //     store.users[account].stateValues[1] = 10 usdc
    //     store.users[account].stateValues[2] = 5 usdc (now we have 5 usdc and we need another 5 usdc for C to withdraw)
    //     store.users[account].stateValues[3] = 5 usdc (5 usdc is reserved, if next user want to withdraw 5 usdc, he has to wait)

    function juniorTotalSupply(RouterStateStore storage store) internal view returns (uint256) {
        // withdrawJunior +pending
        return store.juniorVault.totalSupply() + store.pendingJuniorShares;
    }

    function juniorTotalAssets(RouterStateStore storage store) internal view returns (uint256) {
        // withdrawJunior +pending
        // withdrawSenior +pending
        return store.juniorVault.totalAssets() + store.pendingJuniorAssets;
    }

    function seniorTotalAssets(RouterStateStore storage store) internal view returns (uint256) {
        return store.seniorVault.totalAssets() - store.pendingSeniorAssets;
    }

    function seniorTotalSupply(RouterStateStore storage store) internal view returns (uint256) {
        return store.seniorVault.totalSupply();
    }

    function setOrderId(RouterStateStore storage store, address account, uint64 orderId) internal {
        store.users[account].orderId = orderId;
        store.pendingOrders[orderId] = account;
        require(store.pendingUsers.add(account), "RouterStatesImp::FAILED_TO_ADD_USER");
    }

    function cleanOrderId(RouterStateStore storage store, address account) internal {
        delete store.pendingOrders[store.users[account].orderId];
        store.users[account].orderId = 0;
        require(store.pendingUsers.remove(account), "RouterStatesImp::FAILED_TO_REMOVE_USER");
    }

    function cleanStates(RouterStateStore storage store, address account) internal {
        store.users[account].status = UserStatus.Idle;
        store.users[account].stateValues[0] = 0;
        for (uint256 i = 0; i < STATE_VALUES_COUNT; i++) {
            store.users[account].stateValues[i] = 0;
        }
    }

    // Idle => DepositJunior
    function getDepositJuniorStatus(
        RouterStateStore storage store,
        address account
    ) internal view returns (uint256 juniorAssets) {
        juniorAssets = store.users[account].stateValues[0];
    }

    function setDepositJuniorStatus(
        RouterStateStore storage store,
        address account,
        uint256 juniorAssets
    ) internal {
        store.users[account].status = UserStatus.DepositJunior;
        store.users[account].stateValues[0] = juniorAssets;
        store.pendingJuniorDeposits += juniorAssets;
    }

    function cleanDepositJuniorStatus(RouterStateStore storage store, address account) internal {
        uint256 juniorAssets = getDepositJuniorStatus(store, account);
        store.pendingJuniorDeposits -= juniorAssets;
        cleanStates(store, account);
        cleanOrderId(store, account);
    }

    // Idle => withdrawJunior
    function getWithdrawJuniorStatus(
        RouterStateStore storage store,
        address account
    )
        internal
        view
        returns (
            uint256 juniorShares,
            uint256 juniorAssets,
            uint256 seniorRepays,
            uint256 juniorRemovals
        )
    {
        juniorShares = store.users[account].stateValues[0];
        juniorAssets = store.users[account].stateValues[1];
        seniorRepays = store.users[account].stateValues[2];
        juniorRemovals = store.users[account].stateValues[3];
    }

    function setWithdrawJuniorStatus(
        RouterStateStore storage store,
        address account,
        uint256 shares,
        uint256 assets,
        uint256 repays,
        uint256 removals
    ) internal {
        if (store.users[account].stateValues[0] != shares) {
            store.pendingJuniorShares += (shares - store.users[account].stateValues[0]);
            store.users[account].stateValues[0] = shares;
        }
        if (store.users[account].stateValues[1] != assets) {
            store.pendingJuniorAssets += (assets - store.users[account].stateValues[1]);
            store.users[account].stateValues[1] = assets;
        }
        store.users[account].stateValues[2] = repays;
        store.users[account].stateValues[3] = removals;
        store.users[account].status = UserStatus.WithdrawJunior;
    }

    function cleanWithdrawJuniorStatus(RouterStateStore storage store, address account) internal {
        (uint256 shares, uint256 assets, , ) = getWithdrawJuniorStatus(store, account);
        store.pendingJuniorShares -= shares;
        store.pendingJuniorAssets -= assets;
        cleanStates(store, account);
        cleanOrderId(store, account);
    }

    // Idle => withdrawJunior
    function getWithdrawSeniorStatus(
        RouterStateStore storage store,
        address account
    ) internal view returns (uint256 shares, uint256 assets, uint256 removals, uint256 reserves) {
        shares = store.users[account].stateValues[0];
        assets = store.users[account].stateValues[1];
        removals = store.users[account].stateValues[2];
        reserves = store.users[account].stateValues[3];
    }

    function setWithdrawSeniorStatus(
        RouterStateStore storage store,
        address account,
        uint256 shares,
        uint256 assets,
        uint256 removals,
        uint256 reserves
    ) internal {
        if (store.users[account].stateValues[0] != shares) {
            store.pendingSeniorShares += (shares - store.users[account].stateValues[0]);
            store.users[account].stateValues[0] = shares;
        }
        store.users[account].stateValues[1] = assets;
        if (store.users[account].stateValues[2] != removals) {
            store.pendingJuniorAssets += (removals - store.users[account].stateValues[2]);
            store.users[account].stateValues[2] = removals;
        }
        if (store.users[account].stateValues[3] != reserves) {
            store.pendingSeniorAssets += (reserves - store.users[account].stateValues[3]);
            store.users[account].stateValues[3] = reserves;
        }
        store.users[account].status = UserStatus.WithdrawSenior;
    }

    function cleanWithdrawSeniorStatus(RouterStateStore storage store, address account) internal {
        (uint256 shares, , uint256 removals, uint256 reserves) = getWithdrawSeniorStatus(
            store,
            account
        );
        store.pendingSeniorShares -= shares;
        store.pendingJuniorAssets -= removals;
        store.pendingSeniorAssets -= reserves;
        cleanStates(store, account);
        cleanOrderId(store, account);
    }

    // rebalance - buy
    function getBuyJuniorStatus(
        RouterStateStore storage store
    ) internal view returns (uint256 depositAssets) {
        depositAssets = store.users[address(0)].stateValues[0];
    }

    function setBuyJuniorStatus(RouterStateStore storage store, uint256 assets) internal {
        store.users[address(0)].status = UserStatus.BuyJunior;
        store.users[address(0)].stateValues[0] = assets;
        store.pendingBorrowAssets += assets;
    }

    function cleanBuyJuniorStatus(RouterStateStore storage store) internal {
        require(
            store.users[address(0)].status == UserStatus.BuyJunior,
            "RouterAccountImp::INVALID_STATUS"
        );
        uint256 assets = getBuyJuniorStatus(store);
        store.pendingBorrowAssets -= assets;
        cleanStates(store, address(0));
        cleanOrderId(store, address(0));
    }

    // rebalance - sell
    function getSellJuniorStatus(
        RouterStateStore storage store
    ) internal view returns (uint256 assets) {
        assets = store.users[address(0)].stateValues[0];
    }

    function setSellJuniorStatus(RouterStateStore storage store, uint256 assets) internal {
        store.users[address(0)].status = UserStatus.SellJunior;
        store.users[address(0)].stateValues[0] = assets;
    }

    function cleanSellJuniorStatus(RouterStateStore storage store) internal {
        require(
            store.users[address(0)].status == UserStatus.SellJunior,
            "RouterAccountImp::INVALID_STATUS"
        );
        cleanStates(store, address(0));
        cleanOrderId(store, address(0));
    }

    function isRebalancing(RouterStateStore storage store) internal view returns (bool) {
        return
            store.users[address(0)].status == UserStatus.SellJunior ||
            store.users[address(0)].status == UserStatus.BuyJunior;
    }

    // rebalance - refund
    function getRefundJuniorStatus(
        RouterStateStore storage store
    ) internal view returns (uint256 assets) {
        assets = store.users[address(0)].stateValues[0];
    }

    function setRefundJuniorStatus(RouterStateStore storage store, uint256 assets) internal {
        store.users[address(0)].status = UserStatus.RefundJunior;
        store.users[address(0)].stateValues[0] = assets;
    }

    function cleanRefundJuniorStatus(RouterStateStore storage store) internal {
        require(
            store.users[address(0)].status == UserStatus.RefundJunior,
            "RouterAccountImp::INVALID_STATUS"
        );
        uint256 assets = getRefundJuniorStatus(store);
        store.pendingRefundAssets -= assets;
        cleanStates(store, address(0));
        cleanOrderId(store, address(0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./Type.sol";

contract RouterStore {
    RouterStateStore internal _store;
    bytes32[20] private _reserves;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "./Type.sol";

library RouterUtilImp {
    function toJuniorUnit(
        RouterStateStore storage store,
        uint256 seniorUnitAmount
    ) internal view returns (uint256 juniorUnitAmount) {
        juniorUnitAmount =
            seniorUnitAmount *
            (10 ** (store.juniorVault.assetDecimals() - store.seniorVault.assetDecimals()));
    }

    function toSeniorUnit(
        RouterStateStore storage store,
        uint256 juniorUnitAmount
    ) internal view returns (uint256 seniorUnitAmount) {
        seniorUnitAmount =
            juniorUnitAmount /
            (10 ** (store.juniorVault.assetDecimals() - store.seniorVault.assetDecimals()));
    }

    function seniorBorrows(
        RouterStateStore storage store
    ) internal view returns (uint256 seniorBorrowsAmount) {
        seniorBorrowsAmount = store.seniorVault.borrows(address(this)) - store.pendingBorrowAssets;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/mux/IMuxLiquidityCallback.sol";
import "../interfaces/IRouterV1.sol";
import "../libraries/LibConfigSet.sol";
import "./RouterStore.sol";
import "./RouterImp.sol";

contract RouterV1 is
    RouterStore,
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    IRouterV1
{
    using RouterImp for RouterStateStore;
    using LibConfigSet for ConfigSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    modifier notPending() {
        require(_store.users[msg.sender].status == UserStatus.Idle, "RouterV1::INPROPER_STATUS");
        require(_store.users[address(0)].status == UserStatus.Idle, "RouterV1::INPROPER_STATUS");
        require(_store.pendingRefundAssets == 0, "RouterV1::HAS_REFUND_ASSETS");
        require(_store.pendingUsers.length() == 0, "RouterV1::PENDING_USERS");
        _;
    }

    modifier notLiquidated() {
        require(!_store.isLiquidated, "RouterV1::LIQUIDATED");
        _;
    }

    function initialize(
        address seniorVault,
        address juniorVault,
        address rewardController
    ) external initializer {
        __AccessControlEnumerable_init();
        _store.initialize(seniorVault, juniorVault, rewardController);
        _grantRole(DEFAULT_ADMIN, msg.sender);
    }

    // =============================================== Whitelist ===============================================

    modifier onlyWhitelisted() {
        require(_store.whitelist[msg.sender], "JuniorVault::ONLY_WHITELISTED");
        _;
    }

    function setWhitelist(address account, bool enable) external {
        require(
            hasRole(CONFIG_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN, msg.sender),
            "JuniorVault::ONLY_AUTHRIZED_ROLE"
        );
        _store.whitelist[account] = enable;
    }

    // =============================================== Configs ===============================================
    function getConfig(bytes32 configKey) external view returns (bytes32) {
        return _store.config.getBytes32(configKey);
    }

    function setConfig(bytes32 configKey, bytes32 value) external {
        require(
            hasRole(CONFIG_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN, msg.sender),
            "JuniorVault::ONLY_AUTHRIZED_ROLE"
        );
        _store.config.setBytes32(configKey, value);
    }

    // =============================================== Views ===============================================
    function getUserStates(address account) external view returns (UserState memory userState) {
        return _store.users[account];
    }

    function getPendingUsersCount() external view returns (uint256) {
        return _store.pendingUsers.length();
    }

    function getUserOrderTime(address account) external view returns (uint32 placeOrderTime) {
        uint64 orderId = _store.users[account].orderId;
        if (_store.users[account].orderId != 0) {
            placeOrderTime = _store.getUserOrderTime(orderId);
        } else {
            placeOrderTime = 0;
        }
    }

    function getLastPendingUserOrderTime() external view returns (uint32 placeOrderTime) {
        uint256 count = _store.pendingUsers.length();
        if (count == 0) {
            placeOrderTime = 0;
        } else {
            address account = _store.pendingUsers.at(count - 1);
            uint64 orderId = _store.users[account].orderId;
            if (_store.users[account].orderId != 0) {
                placeOrderTime = _store.getUserOrderTime(orderId);
            } else {
                placeOrderTime = 0;
            }
        }
    }

    function getPendingUsers(
        uint256 begin,
        uint256 count
    ) external view returns (address[] memory) {
        return _store.getPendingUsers(begin, count);
    }

    function juniorLeverage(
        uint256 seniorPrice,
        uint256 juniorPrice
    ) external view returns (uint256 leverage) {
        leverage = _store.juniorLeverage(seniorPrice, juniorPrice);
    }

    function pendingJuniorShares() external view returns (uint256) {
        return _store.pendingJuniorShares;
    }

    function pendingJuniorAssets() external view returns (uint256) {
        return _store.pendingJuniorAssets;
    }

    function pendingSeniorShares() external view returns (uint256) {
        return _store.pendingSeniorShares;
    }

    function pendingBorrowAssets() external view returns (uint256) {
        return _store.pendingBorrowAssets;
    }

    function pendingSeniorAssets() external view returns (uint256) {
        return _store.pendingSeniorAssets;
    }

    function pendingRefundAssets() external view returns (uint256) {
        return _store.pendingRefundAssets;
    }

    function pendingJuniorDeposits() external view returns (uint256) {
        return _store.pendingJuniorDeposits;
    }

    function juniorNavPerShare(
        uint256 seniorPrice,
        uint256 juniorPrice
    ) external view returns (uint256) {
        return _store.juniorNavPerShare(seniorPrice, juniorPrice);
    }

    function isJuniorBalanced(
        uint256 seniorPrice,
        uint256 juniorPrice
    ) external view returns (bool isBalanced, bool isRebalancing) {
        (isBalanced, , ) = _store.isJuniorBalanced(seniorPrice, juniorPrice);
        isRebalancing = _store.isRebalancing();
    }

    function claimableJuniorRewards(address account) external returns (uint256) {
        _store.updateRewards(account);
        return _store.rewardController.claimableJuniorRewards(account);
    }

    function claimableSeniorRewards(address account) external returns (uint256) {
        _store.updateRewards(account);
        return _store.rewardController.claimableSeniorRewards(account);
    }

    function isLiquidated() external view returns (bool) {
        return _store.isLiquidated;
    }

    // =============================================== Actions ===============================================

    // Idle => DepositJunior => Idle
    function depositJunior(
        uint256 assets
    ) external notPending notLiquidated nonReentrant onlyWhitelisted {
        _store.updateRewards(msg.sender);
        _store.depositJunior(msg.sender, assets);
    }

    // Idle => WithdrawJunior => Idle
    function withdrawJunior(
        uint256 shares
    ) external notPending notLiquidated nonReentrant onlyWhitelisted {
        _store.updateRewards(msg.sender);
        _store.withdrawJunior(msg.sender, shares);
    }

    function depositSenior(uint256 amount) external notLiquidated nonReentrant onlyWhitelisted {
        _store.updateRewards(msg.sender);
        _store.depositSenior(msg.sender, amount);
    }

    // Idle => WithdrawSenior => RefundJunior => Idle
    function withdrawSenior(
        uint256 amount,
        bool acceptPenalty
    ) external notPending notLiquidated nonReentrant onlyWhitelisted {
        _store.updateRewards(msg.sender);
        _store.withdrawSenior(msg.sender, amount, acceptPenalty);
    }

    // Idle => BuyJunior / SellJunior => Idle
    function rebalance(
        uint256 seniorPrice,
        uint256 juniorPrice
    ) external notPending notLiquidated onlyRole(KEEPER_ROLE) {
        _store.updateRewards();
        _store.rebalance(seniorPrice, juniorPrice);
    }

    // Idle => SellJunior => Idle
    function liquidate(uint256 seniorPrice, uint256 juniorPrice) external onlyRole(KEEPER_ROLE) {
        require(!_store.isLiquidated, "RouterV1::LIQUIDATED");
        _store.updateRewards();
        _store.liquidate(seniorPrice, juniorPrice);
    }

    // Idle => BuyJunior => Idle
    function refundJunior() external notPending nonReentrant onlyRole(KEEPER_ROLE) {
        require(_store.pendingRefundAssets != 0, "RouterV1::NO_REFUND_ASSETS");
        require(_store.users[address(0)].status == UserStatus.Idle, "RouterV1::INPROPER_STATUS");
        _store.updateRewards();
        _store.refundJunior();
    }

    function updateRewards() external nonReentrant {
        _store.updateRewards();
    }

    function cancelPendingOperation() external nonReentrant notLiquidated {
        _store.updateRewards(msg.sender);
        _store.cancelPendingOperation(msg.sender);
    }

    function claimJuniorRewards() external returns (uint256) {
        _store.updateRewards(msg.sender);
        return _store.rewardController.claimJuniorRewardsFor(msg.sender, msg.sender);
    }

    function claimSeniorRewards() external nonReentrant returns (uint256) {
        _store.updateRewards(msg.sender);
        return _store.rewardController.claimSeniorRewardsFor(msg.sender, msg.sender);
    }

    function migrateJunior(address to) external nonReentrant notPending notLiquidated {
        require(_store.juniorVault.balanceOf(to) == 0, "RouterV1::RECEIVER_NOT_EMPTY");
        uint256 balance = _store.juniorVault.balanceOf(msg.sender);
        require(balance != 0, "RouterV1::NO_ASSETS");
        _store.updateRewards(msg.sender);
        _store.rewardController.migrateJuniorRewardFor(msg.sender, to);
        _store.juniorVault.transferFrom(msg.sender, to, balance);
    }

    function migrateSenior(address to) external nonReentrant notPending notLiquidated {
        require(_store.seniorVault.balanceOf(to) == 0, "RouterV1::RECEIVER_NOT_EMPTY");
        uint256 balance = _store.seniorVault.balanceOf(msg.sender);
        require(balance != 0, "RouterV1::NO_ASSETS");
        _store.updateRewards(msg.sender);
        _store.rewardController.migrateSeniorRewardFor(msg.sender, to);
        _store.seniorVault.transferFrom(msg.sender, to, balance);
    }

    // ============================================= Callbacks =============================================
    function beforeFillLiquidityOrder(
        IMuxLiquidityCallback.LiquidityOrder calldata,
        uint96,
        uint96,
        uint96,
        uint96
    ) external nonReentrant returns (bool isValid) {
        isValid = true;
    }

    function afterFillLiquidityOrder(
        IMuxLiquidityCallback.LiquidityOrder calldata order,
        uint256 amountOut,
        uint96 seniorPrice,
        uint96 juniorPrice,
        uint96 currentSeniorValue,
        uint96 targetSeniorValue
    ) external nonReentrant {
        address orderBook = _store.config.mustGetAddress(MUX_ORDER_BOOK);
        require(
            msg.sender == orderBook || hasRole(KEEPER_ROLE, msg.sender),
            "RouterV1::ONLY_ORDERBOOK_OR_KEEPER"
        );
        MuxOrderContext memory context = MuxOrderContext({
            orderId: order.id,
            seniorAssetId: order.assetId,
            seniorPrice: seniorPrice,
            juniorPrice: juniorPrice,
            currentSeniorValue: currentSeniorValue,
            targetSeniorValue: targetSeniorValue
        });
        _store.onOrderFilled(context, amountOut);
    }

    function afterCancelLiquidityOrder(
        IMuxLiquidityCallback.LiquidityOrder calldata order
    ) external nonReentrant {
        address orderBook = _store.config.mustGetAddress(MUX_ORDER_BOOK);
        require(
            msg.sender == orderBook || hasRole(KEEPER_ROLE, msg.sender),
            "RouterV1::ONLY_ORDERBOOK_OR_KEEPER"
        );
        _store.onOrderCancelled(order.id);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../interfaces/ISeniorVault.sol";
import "../interfaces/IJuniorVault.sol";
import "../interfaces/IRewardController.sol";

import "../libraries/LibConfigSet.sol";
import "../libraries/LibDefines.sol";

uint256 constant STATE_VALUES_COUNT = 5;

enum UserStatus {
    Idle,
    DepositJunior,
    WithdrawJunior,
    WithdrawSenior,
    BuyJunior,
    SellJunior,
    RefundJunior,
    Liquidate
}

struct UserState {
    UserStatus status;
    uint64 orderId;
    uint256[STATE_VALUES_COUNT] stateValues;
}

struct RouterStateStore {
    bytes32[50] __offsets;
    // config;
    ConfigSet config;
    // components
    ISeniorVault seniorVault;
    IJuniorVault juniorVault;
    IRewardController rewardController;
    // properties
    bool isLiquidated;
    uint256 pendingJuniorShares;
    uint256 pendingJuniorAssets;
    uint256 pendingSeniorShares;
    uint256 pendingSeniorAssets;
    uint256 pendingRefundAssets;
    uint256 pendingBorrowAssets;
    mapping(address => UserState) users;
    mapping(uint64 => address) pendingOrders;
    EnumerableSetUpgradeable.AddressSet pendingUsers;
    uint256 pendingJuniorDeposits;
    mapping(address => bool) whitelist;
    bytes32[18] __reserves;
}

struct MuxOrderContext {
    uint64 orderId;
    uint8 seniorAssetId;
    uint96 seniorPrice;
    uint96 juniorPrice;
    uint96 currentSeniorValue;
    uint96 targetSeniorValue;
}