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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


/**
 * @title Agreement Store Library
 * @author Nevermined
 *
 * @dev Implementation of the Agreement Store Library.
 *      The agreement store library holds the business logic
 *      in which manages the life cycle of SEA agreement, each 
 *      agreement is linked to the DID of an asset, template, and
 *      condition IDs.
 */
library AgreementStoreLibrary {

    struct Agreement {
        address templateId;
    }

    struct AgreementList {
        mapping(bytes32 => Agreement) agreements;
        mapping(bytes32 => bytes32[]) didToAgreementIds;
        mapping(address => bytes32[]) templateIdToAgreementIds;
    }

    /**
     * @dev create new agreement
     *      checks whether the agreement Id exists, creates new agreement 
     *      instance, including the template, conditions and DID.
     * @param _self is AgreementList storage pointer
     * @param _id agreement identifier
     * @param _templateId template identifier
     */
    function create(
        AgreementList storage _self,
        bytes32 _id,
        address _templateId
    )
        internal
    {
        require(
            _self.agreements[_id].templateId == address(0),
            'Id already exists'
        );

        _self.agreements[_id].templateId = _templateId;
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './AgreementStoreLibrary.sol';
import '../conditions/ConditionStoreManager.sol';
import '../conditions/ICondition.sol';
import '../registry/DIDRegistry.sol';
import '../templates/TemplateStoreManager.sol';

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

interface Template {
    function getConditionTypes() external view returns (address[] memory);
}

/**
 * @title Agreement Store Manager
 * @author Nevermined
 *
 * @dev Implementation of the Agreement Store.
 *
 *      The agreement store generates conditions for an agreement template.
 *      Agreement templates must to be approved in the Template Store
 *      Each agreement is linked to the DID of an asset.
 */
contract AgreementStoreManager is CommonAccessControl {

    bytes32 private constant PROXY_ROLE = keccak256('PROXY_ROLE');

    function grantProxyRole(address _address) public onlyOwner {
        grantRole(PROXY_ROLE, _address);
    }

    function revokeProxyRole(address _address) public onlyOwner {
        revokeRole(PROXY_ROLE, _address);
    }

    /**
     * @dev The Agreement Store Library takes care of the basic storage functions
     */
    using AgreementStoreLibrary for AgreementStoreLibrary.AgreementList;

    /**
     * @dev state storage for the agreements
     */
    AgreementStoreLibrary.AgreementList internal agreementList;

    ConditionStoreManager internal conditionStoreManager;
    TemplateStoreManager internal templateStoreManager;
    DIDRegistry internal didRegistry;

    /**
     * @dev initialize AgreementStoreManager Initializer
     *      Initializes Ownable. Only on contract creation.
     * @param _owner refers to the owner of the contract
     * @param _conditionStoreManagerAddress is the address of the connected condition store
     * @param _templateStoreManagerAddress is the address of the connected template store
     * @param _didRegistryAddress is the address of the connected DID Registry
     */
    function initialize(
        address _owner,
        address _conditionStoreManagerAddress,
        address _templateStoreManagerAddress,
        address _didRegistryAddress
    )
        public
        initializer
    {
        require(
            _owner != address(0) &&
            _conditionStoreManagerAddress != address(0) &&
            _templateStoreManagerAddress != address(0) &&
            _didRegistryAddress != address(0),
            'Invalid address'
        );
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
        
        conditionStoreManager = ConditionStoreManager(
            _conditionStoreManagerAddress
        );
        templateStoreManager = TemplateStoreManager(
            _templateStoreManagerAddress
        );
        didRegistry = DIDRegistry(
            _didRegistryAddress
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);

    }

    function fullConditionId(
        bytes32 _agreementId,
        address _condType,
        bytes32 _valueHash
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _agreementId,
                _condType,
                _valueHash
            )
        );
    }
    function agreementId(
        bytes32 _agreementId,
        address _creator
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _agreementId,
                _creator
            )
        );
    }
    
    /**
     * @dev Create a new agreement.
     *      The agreement will create conditions of conditionType with conditionId.
     *      Only "approved" templates can access this function.
     * @param _id is the ID of the new agreement. Must be unique.
     * @param _did is the bytes32 DID of the asset. The DID must be registered beforehand.
     * @param _conditionTypes is a list of addresses that point to Condition contracts.
     * @param _conditionIds is a list of bytes32 content-addressed Condition IDs
     * @param _timeLocks is a list of uint time lock values associated to each Condition
     * @param _timeOuts is a list of uint time out values associated to each Condition
     */
    function createAgreement(
        bytes32 _id,
        bytes32 _did,
        address[] memory _conditionTypes,
        bytes32[] memory _conditionIds,
        uint[] memory _timeLocks,
        uint[] memory _timeOuts
    )
        public
    {
        require(
            templateStoreManager.isTemplateApproved(_msgSender()) == true,
            'Template not Approved'
        );
        require(
            didRegistry.getBlockNumberUpdated(_did) > 0,
            'DID not registered'
        );
        require(
            _conditionIds.length == _conditionTypes.length &&
            _timeLocks.length == _conditionTypes.length &&
            _timeOuts.length == _conditionTypes.length,
            'Arguments have wrong length'
        );

        // create the conditions in condition store. Fail if conditionId already exists.
        for (uint256 i = 0; i < _conditionTypes.length; i++) {
            conditionStoreManager.createCondition(
                fullConditionId(_id, _conditionTypes[i], _conditionIds[i]),
                _conditionTypes[i],
                _timeLocks[i],
                _timeOuts[i]
            );
        }
        agreementList.create(
            _id,
            _msgSender()
        );
    }

    struct CreateAgreementArgs {
        bytes32 _id;
        bytes32 _did;
        address[] _conditionTypes;
        bytes32[] _conditionIds;
        uint[] _timeLocks;
        uint[] _timeOuts;
        address _creator;
        uint _idx;
        address payable _rewardAddress;
        address _tokenAddress;
        uint256[] _amounts;
        address[] _receivers;
    }

    function createAgreementAndPay(CreateAgreementArgs memory args)
        public payable
    {
        address[] memory _account = new address[](1);
        _account[0] = args._creator;
        uint[] memory indices = new uint[](1);
        indices[0] = args._idx;
        bytes[] memory params = new bytes[](1);
        params[0] = abi.encode(args._did, args._rewardAddress, args._tokenAddress, args._amounts, args._receivers);
        createAgreementAndFulfill(args._id, args._did, args._conditionTypes, args._conditionIds, args._timeLocks, args._timeOuts, _account, indices, params);
    }

    function createAgreementAndFulfill(
        bytes32 _id,
        bytes32 _did,
        address[] memory _conditionTypes,
        bytes32[] memory _conditionIds,
        uint[] memory _timeLocks,
        uint[] memory _timeOuts,
        address[] memory _account,
        uint[] memory _idx,
        bytes[] memory params
    )
        public payable
    {
        require(hasRole(PROXY_ROLE, _msgSender()) || hasNVMOperatorRole(_msgSender()), 'Proxy role required');
        createAgreement(_id, _did, _conditionTypes, _conditionIds, _timeLocks, _timeOuts);
        if (_idx.length > 0) {
            ICondition(_conditionTypes[_idx[0]]).fulfillProxy{value: msg.value}(_account[0], _id, params[0]);
        }
        for (uint i = 1; i < _idx.length; i++) {
            ICondition(_conditionTypes[_idx[i]]).fulfillProxy(_account[i], _id, params[i]);
        }
    }

    function getAgreementTemplate(bytes32 _id)
        external
        view
        returns (address)
    {
        return agreementList.agreements[_id].templateId;
    }

    /**
     * @dev getDIDRegistryAddress utility function 
     * used by other contracts or any EOA.
     * @return the DIDRegistry address
     */
    function getDIDRegistryAddress()
        public
        virtual
        view
        returns(address)
    {
        return address(didRegistry);
    }

    /**
     * @dev getNvmConfigAddress get the address of the NeverminedConfig contract
     * @return NeverminedConfig contract address
     */
    function getNvmConfigAddress()
    public
    override
    view
    returns (address)
    {
        if (address(didRegistry) == address(0)) {
            return address(0);
        }
        return didRegistry.getNvmConfigAddress();
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import './governance/INVMConfig.sol';

import 'hardhat/console.sol';

/**
 * @title Common functions
 * @author Nevermined
 */
abstract contract Common {

   /**
    * @notice getCurrentBlockNumber get block number
    * @return the current block number
    */
    function getCurrentBlockNumber()
        external
        view
        returns (uint)
    {
        return block.number;
    }

    /**
     * @dev isContract detect whether the address is 
     *          is a contract address or externally owned account
     * @return true if it is a contract address
     */
    function isContract(address addr)
        public
        view
        returns (bool)
    {
        uint size;
        // solhint-disable-next-line
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
     * @dev Sum the total amount given an uint array
     * @return the total amount
     */
    function calculateTotalAmount(
        uint256[] memory _amounts
    )
    public
    pure
    returns (uint256)
    {
        uint256 _totalAmount;
        for(uint i; i < _amounts.length; i++)
            _totalAmount += _amounts[i];
        return _totalAmount;
    }

    function addressToBytes32(
        address _addr
    ) 
    public 
    pure 
    returns (bytes32) 
    {
        return bytes32(uint256(uint160(_addr)));
    }

    function bytes32ToAddress(
        bytes32 _b32
    ) 
    public 
    pure 
    returns (address) 
    {
        return address(uint160(uint256(_b32)));
    }

    function getNvmConfigAddress() public virtual view returns (address);

    /// Implement IERC2771Recipient
    function getTrustedForwarder() public virtual view returns(address) {
        address addr = getNvmConfigAddress();
        if (addr == address(0)) {
            return address(0);
        }
        return INVMConfig(addr).getTrustedForwarder();
    }

    function hasNVMOperatorRole(address a) public virtual view returns(bool) {
        address addr = getNvmConfigAddress();
        if (addr == address(0)) {
            return false;
        }
        return INVMConfig(addr).hasNVMOperatorRole(a);
    }

    function isTrustedForwarder(address forwarder) public virtual view returns(bool) {
        return forwarder == getTrustedForwarder();
    }

    function _msgSender() internal virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            // solhint-disable-next-line
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
    
}

abstract contract CommonOwnable is OwnableUpgradeable, Common {
    function _msgSender() internal override(Common,ContextUpgradeable) virtual view returns (address ret) {
        return Common._msgSender();
    }
    function _msgData() internal override(Common,ContextUpgradeable) virtual view returns (bytes calldata ret) {
        return Common._msgData();
    }
}

abstract contract CommonAccessControl is CommonOwnable, AccessControlUpgradeable {
    function _msgSender() internal override(CommonOwnable,ContextUpgradeable) virtual view returns (address ret) {
        return Common._msgSender();
    }
    function _msgData() internal override(CommonOwnable,ContextUpgradeable) virtual view returns (bytes calldata ret) {
        return Common._msgData();
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './Condition.sol';
import '../registry/DIDRegistry.sol';
import '../interfaces/IAccessControl.sol';
import '../agreements/AgreementStoreManager.sol';

/**
 * @title Access Condition
 * @author Nevermined
 *
 * @dev Implementation of the Access Condition
 *
 *      Access Secret Store Condition is special condition
 *      where a client or Parity secret store can encrypt/decrypt documents 
 *      based on the on-chain granted permissions. For a given DID 
 *      document, and agreement ID, the owner/provider of the DID 
 *      will fulfill the condition. Consequently secret store 
 *      will check whether the permission is granted for the consumer
 *      in order to encrypt/decrypt the document.
 */
contract AccessCondition is Condition, IAccessControl {

    bytes32 constant public CONDITION_TYPE = keccak256('AccessCondition');

    struct DocumentPermission {
        bytes32 agreementIdDeprecated;
        mapping(address => bool) permission;
    }

    mapping(bytes32 => DocumentPermission) private documentPermissions;
    AgreementStoreManager private agreementStoreManager;
    DIDRegistry private didRegistry;

    event Fulfilled(
        bytes32 indexed _agreementId,
        bytes32 indexed _documentId,
        address indexed _grantee,
        bytes32 _conditionId
    );
    
    modifier onlyDIDOwnerOrProvider(
        bytes32 _documentId
    )
    {
        require(
            didRegistry.isDIDProviderOrOwner(_documentId, _msgSender()),
            'Invalid DID owner/provider'
        );
        _;
    }

   /**
    * @notice initialize init the 
    *       contract with the following parameters
    * @dev this function is called only once during the contract
    *       initialization.
    * @param _owner contract's owner account address
    * @param _conditionStoreManagerAddress condition store manager address
    * @param _agreementStoreManagerAddress agreement store manager address
    */
    function initialize(
        address _owner,
        address _conditionStoreManagerAddress,
        address _agreementStoreManagerAddress
    )
        external
        initializer()
    {
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);

        conditionStoreManager = ConditionStoreManager(
            _conditionStoreManagerAddress
        );

        agreementStoreManager = AgreementStoreManager(
            _agreementStoreManagerAddress
        );
        didRegistry = DIDRegistry(
            agreementStoreManager.getDIDRegistryAddress()
        );
        
    }

    /**
     * Should be called when the contract has been upgraded.
     */
    function reinitialize() external reinitializer(2) {
        didRegistry = DIDRegistry(
            agreementStoreManager.getDIDRegistryAddress()
        );
    }

   /**
    * @notice hashValues generates the hash of condition inputs 
    *        with the following parameters
    * @param _documentId refers to the DID in which secret store will issue the decryption keys
    * @param _grantee is the address of the granted user or the DID provider
    * @return bytes32 hash of all these values 
    */
    function hashValues(
        bytes32 _documentId,
        address _grantee
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_documentId, _grantee));
    }

   /**
    * @notice fulfill access secret store condition
    * @dev only DID owner or DID provider can call this
    *       method. Fulfill method sets the permissions 
    *       for the granted consumer's address to true then
    *       fulfill the condition
    * @param _agreementId agreement identifier
    * @param _documentId refers to the DID in which secret store will issue the decryption keys
    * @param _grantee is the address of the granted user or the DID provider
    * @return condition state (Fulfilled/Aborted)
    */
    function fulfill(
        bytes32 _agreementId,
        bytes32 _documentId,
        address _grantee
    )
        public
        returns (ConditionStoreLibrary.ConditionState)
    {
        grantPermission(
            _grantee,
            _documentId
        );
        
        bytes32 _id = generateId(
            _agreementId,
            hashValues(_documentId, _grantee)
        );

        ConditionStoreLibrary.ConditionState state = super.fulfillWithProvenance(
            _id,
            ConditionStoreLibrary.ConditionState.Fulfilled,
            _documentId,
            'AccessCondition',
            _msgSender()
        );
        
        emit Fulfilled(
            _agreementId,
            _documentId,
            _grantee,
            _id
        );

        return state;
    }
    
   /**
    * @notice grantPermission is called only by DID owner or provider
    * @param _grantee is the address of the granted user or the DID provider
    * @param _documentId refers to the DID in which secret store will issue the decryption keys
    */
    function grantPermission(
        address _grantee,
        bytes32 _documentId
        
    )
        public
        override
        onlyDIDOwnerOrProvider(_documentId)
    {
        documentPermissions[_documentId].permission[_grantee] = true;
    }

   /**
    * @notice renouncePermission is called only by DID owner or provider
    * @param _grantee is the address of the granted user or the DID provider
    * @param _documentId refers to the DID in which secret store will issue the decryption keys
    */
    function renouncePermission(
        address _grantee,
        bytes32 _documentId
    )
        public
        override
        onlyDIDOwnerOrProvider(_documentId)
    {
        documentPermissions[_documentId].permission[_grantee] = false;
    }
    
   /**
    * @notice checkPermissions is called by Parity secret store
    * @param _documentId refers to the DID in which secret store will issue the decryption keys
    * @param _grantee is the address of the granted user or the DID provider
    * @return permissionGranted true if the access was granted
    */
    function checkPermissions(
        address _grantee,
        bytes32 _documentId
    )
        external view
        override
        returns(bool permissionGranted)
    {
        return (
            didRegistry.isDIDProvider(_documentId, _grantee) ||
            didRegistry.isDIDOwner(_grantee, _documentId) ||
            documentPermissions[_documentId].permission[_grantee] ||
            didRegistry.getPermission(_documentId, _grantee)
        );
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './ConditionStoreManager.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
/**
 * @title Condition
 * @author Nevermined
 *
 * @dev Implementation of the Condition
 *
 *      Each condition has a validation function that returns either FULFILLED, 
 *      ABORTED or UNFULFILLED. When a condition is successfully solved, we call 
 *      it FULFILLED. If a condition cannot be FULFILLED anymore due to a timeout 
 *      or other types of counter-proofs, the condition is ABORTED. UNFULFILLED 
 *      values imply that a condition has not been provably FULFILLED or ABORTED. 
 *      All initialized conditions start out as UNFULFILLED.
 */
contract Condition is CommonOwnable {

    ConditionStoreManager internal conditionStoreManager;

   /**
    * @notice generateId condition Id from the following 
    *       parameters
    * @param _agreementId SEA agreement ID
    * @param _valueHash hash of all the condition input values
    */
    function generateId(
        bytes32 _agreementId,
        bytes32 _valueHash
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                _agreementId,
                address(this),
                _valueHash
            )
        );
    }

   /**
    * @notice fulfill set the condition state to Fulfill | Abort
    * @param _id condition identifier
    * @param _newState new condition state (Fulfill/Abort)
    * @return the updated condition state 
    */
    function fulfill(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState
    )
        internal
        returns (ConditionStoreLibrary.ConditionState)
    {
        // _newState can be Fulfilled or Aborted
        return conditionStoreManager.updateConditionState(_id, _newState);
    }

    function fulfillWithProvenance(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState,
        bytes32 _did,
        string memory _name,
        address _user
    )
        internal
        returns (ConditionStoreLibrary.ConditionState)
    {
        // _newState can be Fulfilled or Aborted
        return conditionStoreManager.updateConditionStateWithProvenance(_id, _did, _name, _user, _newState);
    }


    /**
    * @notice abortByTimeOut set condition state to Aborted 
    *         if the condition is timed out
    * @param _id condition identifier
    * @return the updated condition state
    */
    function abortByTimeOut(
        bytes32 _id
    )
        external
        returns (ConditionStoreLibrary.ConditionState)
    {
        require(
            conditionStoreManager.isConditionTimedOut(_id),
            'Condition needs to be timed out'
        );

        return conditionStoreManager.updateConditionState(
            _id,
            ConditionStoreLibrary.ConditionState.Aborted
        );
    }

    function getNvmConfigAddress()
    public
    override
    view
    returns (address)
    {
        if (address(conditionStoreManager) == address(0)) {
            return address(0);
        }
        return conditionStoreManager.getNvmConfigAddress();
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


/**
 * @title Condition Store Library
 * @author Nevermined
 *
 * @dev Implementation of the Condition Store Library.
 *      
 *      Condition is a key component in the service execution agreement. 
 *      This library holds the logic for creating and updating condition 
 *      Any Condition has only four state transitions starts with Uninitialized,
 *      Unfulfilled, Fulfilled, and Aborted. Condition state transition goes only 
 *      forward from Unintialized -> Unfulfilled -> {Fulfilled || Aborted} 
 */
library ConditionStoreLibrary {

    enum ConditionState { Uninitialized, Unfulfilled, Fulfilled, Aborted }

    struct Condition {
        address typeRef;
        ConditionState state;
    }

    struct ConditionList {
        mapping(bytes32 => Condition) conditions;
        mapping(bytes32 => mapping(bytes32 => bytes32)) map;
    }
    
    
   /**
    * @notice create new condition
    * @dev check whether the condition exists, assigns 
    *       condition type, condition state, last updated by, 
    *       and update at (which is the current block number)
    * @param _self is the ConditionList storage pointer
    * @param _id valid condition identifier
    * @param _typeRef condition contract address
    */
    function create(
        ConditionList storage _self,
        bytes32 _id,
        address _typeRef
    )
        internal
    {
        require(
            _self.conditions[_id].typeRef == address(0),
            'Id already exists'
        );

        _self.conditions[_id].typeRef = _typeRef;
        _self.conditions[_id].state = ConditionState.Unfulfilled;
    }

    /**
    * @notice updateState update the condition state
    * @dev check whether the condition state transition is right,
    *       assign the new state, update last updated by and
    *       updated at.
    * @param _self is the ConditionList storage pointer
    * @param _id condition identifier
    * @param _newState the new state of the condition
    */
    function updateState(
        ConditionList storage _self,
        bytes32 _id,
        ConditionState _newState
    )
        internal
    {
        require(
            _self.conditions[_id].state == ConditionState.Unfulfilled &&
            _newState > _self.conditions[_id].state,
            'Invalid state transition'
        );

        _self.conditions[_id].state = _newState;
    }
    
    function updateKeyValue(
        ConditionList storage _self,
        bytes32 _id,
        bytes32 _key,
        bytes32 _value
    )
    internal
    {
        _self.map[_id][_key] = _value;
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import '../libraries/EpochLibrary.sol';
import './ConditionStoreLibrary.sol';
import '../governance/INVMConfig.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '../interfaces/IExternalRegistry.sol';
import '../Common.sol';

/**
 * @title Condition Store Manager
 * @author Nevermined
 *
 * @dev Implementation of the Condition Store Manager.
 *
 *      Condition store manager is responsible for enforcing the 
 *      the business logic behind creating/updating the condition state
 *      based on the assigned role to each party. Only specific type of
 *      contracts are allowed to call this contract, therefore there are 
 *      two types of roles, create role that in which is able to create conditions.
 *      The second role is the update role, which is can update the condition state.
 *      Also, it support delegating the roles to other contract(s)/account(s).
 */
contract ConditionStoreManager is CommonAccessControl {

    bytes32 private constant PROXY_ROLE = keccak256('PROXY_ROLE');

    using ConditionStoreLibrary for ConditionStoreLibrary.ConditionList;
    using EpochLibrary for EpochLibrary.EpochList;

    enum RoleType { Create, Update }
    address private createRole;
    ConditionStoreLibrary.ConditionList internal conditionList;
    EpochLibrary.EpochList internal epochList;

    address internal nvmConfigAddress;

    IExternalRegistry public didRegistry;
    
    event ConditionCreated(
        bytes32 indexed _id,
        address indexed _typeRef,
        address indexed _who
    );

    event ConditionUpdated(
        bytes32 indexed _id,
        address indexed _typeRef,
        ConditionStoreLibrary.ConditionState indexed _state,
        address _who
    );

    modifier onlyCreateRole(){
        require(
            createRole == _msgSender(),
            'Invalid CreateRole'
        );
        _;
    }

    modifier onlyUpdateRole(bytes32 _id)
    {
        require(
            conditionList.conditions[_id].typeRef != address(0),
            'Condition doesnt exist'
        );
        require(
            conditionList.conditions[_id].typeRef == _msgSender(),
            'Invalid UpdateRole'
        );
        _;
    }

    modifier onlyValidType(address typeRef)
    {
        require(
            typeRef != address(0),
            'Invalid address'
        );
        require(AddressUpgradeable.isContract(typeRef), 'Invalid contract address');
        _;
    }

   /**
    * @notice create creates new Epoch
    * @param _self is the Epoch storage pointer
    * @param _timeLock value in block count (can not fulfill before)
    * @param _timeOut value in block count (can not fulfill after)
    */
    function createEpoch(
        EpochLibrary.EpochList storage _self,
        bytes32 _id,
        uint256 _timeLock,
        uint256 _timeOut
    )
        internal
    {
        require(
            _self.epochs[_id].blockNumber == 0,
            'Id already exists'
        );

        require(
            _timeLock + block.number >= block.number &&
            _timeOut + block.number >= block.number,
            'Indicating integer overflow/underflow'
        );

        if (_timeOut > 0 && _timeLock > 0) {
            require(
                _timeLock < _timeOut,
                'Invalid time margin'
            );
        }

        _self.epochs[_id] = EpochLibrary.Epoch({
            timeLock : _timeLock,
            timeOut : _timeOut,
            blockNumber : block.number
        });

    }


    /**
     * @dev initialize ConditionStoreManager Initializer
     *      Initialize Ownable. Only on contract creation,
     * @param _creator refers to the creator of the contract
     * @param _owner refers to the owner of the contract           
     * @param _nvmConfigAddress refers to the contract address of `NeverminedConfig`
     */
    function initialize(
        address _creator,
        address _owner,
        address _nvmConfigAddress
    )
        public
        initializer
    {
        require(
            _owner != address(0),
            'Invalid address'
        );
        require(
            createRole == address(0),
            'Role already assigned'
        );

        require(
            _nvmConfigAddress != address(0), 
                'Invalid Address'
        );
        
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
        createRole = _creator;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        
        nvmConfigAddress= _nvmConfigAddress;
    }

    /**
     * @dev Set provenance registry
     * @param _didAddress did registry address. can be zero
     */
    function setProvenanceRegistry(address _didAddress) public {
        didRegistry = IExternalRegistry(_didAddress);
    }

    /**
     * @dev getCreateRole get the address of contract
     *      which has the create role
     * @return create condition role address
     */
    function getCreateRole()
        external
        view
        returns (address)
    {
        return createRole;
    }

    /**
     * @dev getNvmConfigAddress get the address of the NeverminedConfig contract
     * @return NeverminedConfig contract address
     */
    function getNvmConfigAddress()
    public
    override
    view
    returns (address)
    {
        return nvmConfigAddress;
    }    
    
    function setNvmConfigAddress(address _addr)
    external
    onlyOwner
    {
        nvmConfigAddress = _addr;
    }
    
    /**
     * @dev delegateCreateRole only owner can delegate the 
     *      create condition role to a different address
     * @param delegatee delegatee address
     */
    function delegateCreateRole(
        address delegatee
    )
        external
        onlyOwner()
    {
        require(
            delegatee != address(0),
            'Invalid delegatee address'
        );
        createRole = delegatee;
    }

    /**
     * @dev delegateUpdateRole only owner can delegate 
     *      the update role to a different address for 
     *      specific condition Id which has the create role
     * @param delegatee delegatee address
     */
    function delegateUpdateRole(
        bytes32 _id,
        address delegatee
    )
        external
        onlyOwner()
    {
        require(
            delegatee != address(0),
            'Invalid delegatee address'
        );
        require(
            conditionList.conditions[_id].typeRef != address(0),
            'Invalid condition Id'
        );
        conditionList.conditions[_id].typeRef = delegatee;
    }

    function grantProxyRole(address _address) public onlyOwner {
        grantRole(PROXY_ROLE, _address);
    }

    function revokeProxyRole(address _address) public onlyOwner {
        revokeRole(PROXY_ROLE, _address);
    }

    /**
     * @dev createCondition only called by create role address 
     *      the condition should use a valid condition contract 
     *      address, valid time lock and timeout. Moreover, it 
     *      enforce the condition state transition from 
     *      Uninitialized to Unfulfilled.
     * @param _id unique condition identifier
     * @param _typeRef condition contract address
     */
    function createCondition(
        bytes32 _id,
        address _typeRef
    )
    external
    {
        createCondition(
            _id,
            _typeRef,
            uint(0),
            uint(0)
        );
    }
    
    function createCondition2(
        bytes32 _id,
        address _typeRef
    )
    external
    {
        createCondition(
            _id,
            _typeRef,
            uint(0),
            uint(0)
        );
    }
    
    /**
     * @dev createCondition only called by create role address 
     *      the condition should use a valid condition contract 
     *      address, valid time lock and timeout. Moreover, it 
     *      enforce the condition state transition from 
     *      Uninitialized to Unfulfilled.
     * @param _id unique condition identifier
     * @param _typeRef condition contract address
     * @param _timeLock start of the time window
     * @param _timeOut end of the time window
     */
    function createCondition(
        bytes32 _id,
        address _typeRef,
        uint _timeLock,
        uint _timeOut
    )
        public
        onlyCreateRole
        onlyValidType(_typeRef)
    {
        createEpoch(epochList, _id, _timeLock, _timeOut);

        conditionList.create(_id, _typeRef);

        emit ConditionCreated(
            _id,
            _typeRef,
            _msgSender()
        );
    }

    /**
     * @dev updateConditionState only called by update role address. 
     *      It enforce the condition state transition to either 
     *      Fulfill or Aborted state
     * @param _id unique condition identifier
     * @return the current condition state 
     */
    function updateConditionState(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState
    )
        external
        onlyUpdateRole(_id)
        returns (ConditionStoreLibrary.ConditionState)
    {
        return _updateConditionState(_id, _newState);
    }

    function _updateConditionState(
        bytes32 _id,
        ConditionStoreLibrary.ConditionState _newState
    )
        internal
        returns (ConditionStoreLibrary.ConditionState)
    {
        // no update before time lock
        require(
            !isConditionTimeLocked(_id),
            'TimeLock is not over yet'
        );

        ConditionStoreLibrary.ConditionState updateState = _newState;

        // auto abort after time out
        if (isConditionTimedOut(_id)) {
            updateState = ConditionStoreLibrary.ConditionState.Aborted;
        }

        conditionList.updateState(_id, updateState);

        emit ConditionUpdated(
            _id,
            conditionList.conditions[_id].typeRef,
            updateState,
            _msgSender()
        );

        return updateState;
    }

    function updateConditionStateWithProvenance(
        bytes32 _id,
        bytes32 _did,
        string memory name,
        address user,
        ConditionStoreLibrary.ConditionState _newState
    )
        external
        onlyUpdateRole(_id)
        returns (ConditionStoreLibrary.ConditionState)
    {
        ConditionStoreLibrary.ConditionState state = _updateConditionState(_id, _newState);
        if (address(didRegistry) != address(0)) {
            didRegistry.used(_id, _did, user, keccak256(bytes(name)), '', name);
        }
        
        return state;
    }

    function updateConditionMapping(
        bytes32 _id,
        bytes32 _key,
        bytes32 _value
    )
    external
    onlyUpdateRole(_id)
    {
        conditionList.updateKeyValue(
            _id, 
            _key, 
            _value
        );
    }
    
    function updateConditionMappingProxy(
        bytes32 _id,
        bytes32 _key,
        bytes32 _value
    )
    external
    {
        require(hasRole(PROXY_ROLE, _msgSender()) || hasNVMOperatorRole(_msgSender()), 'Invalid access role');
        conditionList.updateKeyValue(
            _id, 
            _key, 
            _value
        );
    }
    
    /**
     * @dev getCondition  
     * @return typeRef the type reference
     * @return state condition state
     * @return timeLock the time lock
     * @return timeOut time out
     * @return blockNumber block number
     */
    function getCondition(bytes32 _id)
        external
        view
        returns (
            address typeRef,
            ConditionStoreLibrary.ConditionState state,
            uint timeLock,
            uint timeOut,
            uint blockNumber
        )
    {
        typeRef = conditionList.conditions[_id].typeRef;
        state = conditionList.conditions[_id].state;
        timeLock = epochList.epochs[_id].timeLock;
        timeOut = epochList.epochs[_id].timeOut;
        blockNumber = epochList.epochs[_id].blockNumber;
    }

    /**
     * @dev getConditionState  
     * @return condition state
     */
    function getConditionState(bytes32 _id)
        external
        view
        virtual
        returns (ConditionStoreLibrary.ConditionState)
    {
        return conditionList.conditions[_id].state;
    }

    /**
     * @dev getConditionTypeRef  
     * @return condition typeRef
     */
    function getConditionTypeRef(bytes32 _id)
    external
    view
    virtual
    returns (address)
    {
        return conditionList.conditions[_id].typeRef;
    }    

    /**
     * @dev getConditionState  
     * @return condition state
     */
    function getMappingValue(bytes32 _id, bytes32 _key)
    external
    view
    virtual
    returns (bytes32)
    {
        return conditionList.map[_id][_key];
    }    

    /**
     * @dev isConditionTimeLocked  
     * @return whether the condition is timedLock ended
     */
    function isConditionTimeLocked(bytes32 _id)
        public
        view
        returns (bool)
    {
        return epochList.isTimeLocked(_id);
    }

    /**
     * @dev isConditionTimedOut  
     * @return whether the condition is timed out 
     */
    function isConditionTimedOut(bytes32 _id)
        public
        view
        returns (bool)
    {
        return epochList.isTimedOut(_id);
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

interface ICondition {
    function fulfillProxy(
        address _account,
        bytes32 _agreementId,
        bytes memory params
    ) external payable;
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

abstract contract INVMConfig {

    bytes32 public constant GOVERNOR_ROLE = keccak256('NVM_GOVERNOR_ROLE');
    
    /**
    * @notice Event that is emitted when a parameter is changed
    * @param _whoChanged the address of the governor changing the parameter
    * @param _parameter the hash of the name of the parameter changed
    */
    event NeverminedConfigChange(
        address indexed _whoChanged,
        bytes32 indexed _parameter
    );

    /**
     * @notice The governor can update the Nevermined Marketplace fees
     * @param _marketplaceFee new marketplace fee 
     * @param _feeReceiver The address receiving the fee      
     */
    function setMarketplaceFees(
        uint256 _marketplaceFee,
        address _feeReceiver
    ) virtual external;

    /**
     * @notice Indicates if an address is a having the GOVERNOR role
     * @param _address The address to validate
     * @return true if is a governor 
     */    
    function isGovernor(
        address _address
    ) external view virtual returns (bool);

    /**
     * @notice Returns the marketplace fee
     * @return the marketplace fee
     */
    function getMarketplaceFee()
    external view virtual returns (uint256);

    /**
     * @notice Returns the receiver address of the marketplace fee
     * @return the receiver address
     */    
    function getFeeReceiver()
    external view virtual returns (address);

    /**
     * @notice Returns true if provenance should be stored in storage
     * @return true if provenance should be stored in storage
     */    
    function getProvenanceStorage()
    external view virtual returns (bool);

    /**
     * @notice Returns the address of OpenGSN forwarder contract
     * @return a address of OpenGSN forwarder contract
     */    
    function getTrustedForwarder()
    external virtual view returns(address);

    /**
     * @notice Indicates if an address is a having the OPERATOR role
     * @param _address The address to validate
     * @return true if is a governor 
     */    
    function hasNVMOperatorRole(address _address)
    external view virtual returns (bool);
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import './INVMConfig.sol';

contract NeverminedConfig is 
    OwnableUpgradeable,
    AccessControlUpgradeable,
INVMConfig
{

    // Role to operate the NFT contract
    bytes32 public constant NVM_OPERATOR_ROLE = keccak256('NVM_OPERATOR_ROLE');

    ///////////////////////////////////////////////////////////////////////////////////////
    /////// NEVERMINED GOVERNABLE VARIABLES ////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    
    // @notice The fee charged by Nevermined for using the Service Agreements.
    // Integer representing a 2 decimal number. i.e 350 means a 3.5% fee
    uint256 public marketplaceFee;

    // @notice The address that will receive the fee charged by Nevermined per transaction
    // See `marketplaceFee`
    address public feeReceiver;

    // @notice Switch to turn off provenance in storage. By default the storage is on
    bool public provenanceOff;

    address public trustedForwarder;

    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    
    
    /**
     * @notice Used to initialize the contract during delegator constructor
     * @param _owner The owner of the contract
     * @param _governor The address to be granted with the `GOVERNOR_ROLE`
     */
    function initialize(
        address _owner,
        address _governor,
        bool _provenanceOff
    )
    public
    initializer
    {
        __Ownable_init();
        transferOwnership(_owner);

        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._setupRole(DEFAULT_ADMIN_ROLE, _owner);
        AccessControlUpgradeable._setupRole(GOVERNOR_ROLE, _governor);
        provenanceOff = _provenanceOff;
    }

    function setMarketplaceFees(
        uint256 _marketplaceFee,
        address _feeReceiver
    )
    external
    virtual
    override
    onlyGovernor(msg.sender)
    {
        require(
            _marketplaceFee >=0 && _marketplaceFee <= 1000000,
            'NeverminedConfig: Fee must be between 0 and 100 percent'
        );
        
        if (_marketplaceFee > 0)    {
            require(
                _feeReceiver != address(0),
                'NeverminedConfig: Receiver can not be 0x0'
            );            
        }

        marketplaceFee = _marketplaceFee;
        feeReceiver = _feeReceiver;
        emit NeverminedConfigChange(msg.sender, keccak256('marketplaceFee'));
        emit NeverminedConfigChange(msg.sender, keccak256('feeReceiver'));
    }

    function setGovernor(address _address) external onlyOwner {
        _grantRole(GOVERNOR_ROLE, _address);
    }

    function isGovernor(
        address _address
    )
    external
    view
    override
    returns (bool)
    {
        return hasRole(GOVERNOR_ROLE, _address);
    }

    function grantNVMOperatorRole(address _address) external onlyOwner {
        _grantRole(NVM_OPERATOR_ROLE, _address);
    }

    function revokeNVMOperatorRole(address _address) external onlyOwner {
        _revokeRole(NVM_OPERATOR_ROLE, _address);
    }

    function hasNVMOperatorRole(
        address _address
    )
    external
    view
    override
    returns (bool)
    {
        return hasRole(NVM_OPERATOR_ROLE, _address);
    }

    function getMarketplaceFee()
    external
    view
    override 
    returns (uint256) 
    {
        return marketplaceFee;
    }

    function getFeeReceiver()
    external
    view
    override 
    returns (address)
    {
        return feeReceiver;
    }
    
    function getProvenanceStorage()
    external
    view
    override 
    returns (bool)
    {
        return !provenanceOff;
    }

    function getTrustedForwarder()
    external override virtual view returns(address) {
        return trustedForwarder;
    }

    function setTrustedForwarder(address forwarder)
    external onlyGovernor(msg.sender) {
        trustedForwarder = forwarder;
    }

    modifier onlyGovernor(address _address)
    {
        require(
            hasRole(GOVERNOR_ROLE, _address),
            'NeverminedConfig: Only governor'
        );
        _;
    }
    
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0



/**
 * @title Access Control Interface
 * @author Nevermined
 */
interface IAccessControl {

    /**
    * @notice It checks if an address (`_address`) has access to a certain asset (`_did`) 
    * @param _address address of the account to check if has address
    * @param _did unique identifier of the asset
    * @return permissionGranted is true if the `_address` has access to the `_did`
    */    
    function checkPermissions(
        address _address,
        bytes32 _did
    )
    external view
    returns (bool permissionGranted);

    /**
    * @notice Grants access permissions to an `_address` to a specific `_did`
    * @dev `grantPermission` is called only by the `_did` owner or provider
    * @param _address address of the account to check if has address
    * @param _did unique identifier of the asset     
    */
    function grantPermission(
        address _address,
        bytes32 _did
    )
    external;
    
    /**
    * @notice Renounce access permissions to an `_address` to a specific `_did`
    * @dev `renouncePermission` is called only by the `_did` owner or provider
    * @param _address address of the account to check if has address
    * @param _did unique identifier of the asset     
    */    
    function renouncePermission(
        address _address,
        bytes32 _did
    )
    external;    
}

pragma solidity ^0.8.0;
// Copyright 2023 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

/**
 * @title Interface for a NFT Registry of assets
 * @author Nevermined
 */
interface IExternalRegistry {

    function used(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        bytes memory _signatureUsing,
        string memory _attributes
    )
    external
    returns (bool success);

    
    function getDIDOwner(bytes32 _did)
    external
    view
    returns (address didOwner);

    
    function isDIDProvider(
        bytes32 _did,
        address _provider
    )
    external
    view
    returns (bool);
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

/**
 * @title Interface for different royalty schemes.
 * @author Nevermined
 */
interface IRoyaltyScheme {
    /**
     * @notice check that royalties are correct
     * @param _did compute royalties for this DID
     * @param _amounts amounts in payment
     * @param _receivers receivers of payments
     * @param _tokenAddress payment token. zero address means native token (ether)
     */
    function check(bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address _tokenAddress) external view returns (bool);
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


/**
 * @title Epoch Library
 * @author Nevermined
 *
 * @dev Implementation of Epoch Library.
 *      For an arbitrary Epoch, this library manages the life
 *      cycle of an Epoch. Usually this library is used for 
 *      handling the time window between conditions in an agreement.
 */
library EpochLibrary {

    struct Epoch {
        uint256 timeLock;
        uint256 timeOut;
        uint256 blockNumber;
    }

    struct EpochList {
        mapping(bytes32 => Epoch) epochs;
    }

   /**
    * @notice isTimedOut means you cannot fulfill after
    * @param _self is the Epoch storage pointer
    * @return true if the current block number is gt timeOut
    */
    function isTimedOut(
        EpochList storage _self,
        bytes32 _id
    )
        internal
        view
        returns (bool)
    {
        if (_self.epochs[_id].timeOut == 0) {
            return false;
        }

        return (block.number > getEpochTimeOut(_self.epochs[_id]));
    }

   /**
    * @notice isTimeLocked means you cannot fulfill before
    * @param _self is the Epoch storage pointer
    * @return true if the current block number is gt timeLock
    */
    function isTimeLocked(
        EpochList storage _self,
        bytes32 _id
    )
        internal
        view
        returns (bool)
    {
        return (block.number < getEpochTimeLock(_self.epochs[_id]));
    }

   /**
    * @notice getEpochTimeOut
    * @param _self is the Epoch storage pointer
    */
    function getEpochTimeOut(
        Epoch storage _self
    )
        internal
        view
        returns (uint256)
    {
        return _self.timeOut + _self.blockNumber;
    }

    /**
    * @notice getEpochTimeLock
    * @param _self is the Epoch storage pointer
    */
    function getEpochTimeLock(
        Epoch storage _self
    )
        internal
        view
        returns (uint256)
    {
        return _self.timeLock + _self.blockNumber;
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './DIDRegistryLibrary.sol';
import './ProvenanceRegistry.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

/**
 * @title DID Factory
 * @author Nevermined
 *
 * @dev Implementation of the DID Registry.
 */
abstract contract DIDFactory is ProvenanceRegistry { 
    
    /**
     * @dev The DIDRegistry Library takes care of the basic DID storage functions.
     */
    using DIDRegistryLibrary for DIDRegistryLibrary.DIDRegisterList;

    /**
     * @dev state storage for the DID registry
     */
    DIDRegistryLibrary.DIDRegisterList internal didRegisterList;

    // DID -> Address -> Boolean Permission
    mapping(bytes32 => mapping(address => bool)) internal didPermissions;
    
    address public manager;

    //////////////////////////////////////////////////////////////
    ////////  MODIFIERS   ////////////////////////////////////////
    //////////////////////////////////////////////////////////////

    
    modifier onlyDIDOwner(bytes32 _did)
    {
        require(
            isDIDOwner(_msgSender(), _did),
            'Only owner'
        );
        _;
    }

    modifier onlyOwnerProviderOrDelegated(bytes32 _did)
    {
        require(isOwnerProviderOrDelegate(_did),
            'Only owner, provider or delegated'
        );
        _;
    }

    modifier onlyValidAttributes(string memory _attributes)
    {
        require(
            bytes(_attributes).length <= 2048,
            'Invalid attributes size'
        );
        _;
    }

    modifier nftIsInitialized(bytes32 _did)
    {
        require(
            didRegisterList.didRegisters[_did].nftInitialized,
            'NFT not initialized'
        );
        _;
    }    
    
    //////////////////////////////////////////////////////////////
    ////////  EVENTS  ////////////////////////////////////////////
    //////////////////////////////////////////////////////////////

    /**
     * DID Events
     */
    event DIDAttributeRegistered(
        bytes32 indexed _did,
        address indexed _owner,
        bytes32 indexed _checksum,
        string _value,
        address _lastUpdatedBy,
        uint256 _blockNumberUpdated
    );

    event DIDMetadataUpdated(
        bytes32 indexed _did,
        address indexed _owner,
        bytes32 _checksum,
        string _url,
        string _immutableUrl
    );
    
    event DIDProviderRemoved(
        bytes32 _did,
        address _provider,
        bool state
    );

    event DIDProviderAdded(
        bytes32 _did,
        address _provider
    );

    event DIDOwnershipTransferred(
        bytes32 _did,
        address _previousOwner,
        address _newOwner
    );

    event DIDPermissionGranted(
        bytes32 indexed _did,
        address indexed _owner,
        address indexed _grantee
    );

    event DIDPermissionRevoked(
        bytes32 indexed _did,
        address indexed _owner,
        address indexed _grantee
    );

    event DIDProvenanceDelegateRemoved(
        bytes32 _did,
        address _delegate,
        bool state
    );

    event DIDProvenanceDelegateAdded(
        bytes32 _did,
        address _delegate
    );

    /**
     * @notice Register DID attributes.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID). 
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _url refers to the attribute value, limited to 2048 bytes.
     */
    function registerAttribute(
        bytes32 _didSeed,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url
    )
    public
    virtual
    {
        registerDID(_didSeed, _checksum, _providers, _url, '', '');
    }


    /**
     * @notice Register DID attributes.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID). 
     *          The final DID will be calculated with the creator address using the `hashDID` function
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _providers list of DID providers addresses
     * @param _activityId refers to activity
     * @param _immutableUrl refers to url stored in an immutable storage network like IPFS, Filecoin, Arweave
     */
    function registerDID(
        bytes32 _didSeed,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        bytes32 _activityId,
        string memory _immutableUrl
    )
    public
    virtual
    {
        bytes32 _did = hashDID(_didSeed, _msgSender());
        require(
            didRegisterList.didRegisters[_did].owner == address(0x0),
            'DID already registered'
        );

        didRegisterList.update(_did, _checksum, _url, _msgSender(), _immutableUrl);

        // push providers to storage
        for (uint256 i = 0; i < _providers.length; i++) {
            didRegisterList.addProvider(
                _did,
                _providers[i]
            );
        }

        emit DIDAttributeRegistered(
            _did,
            didRegisterList.didRegisters[_did].owner,
            _checksum,
            _url,
            _msgSender(),
            block.number
        );
        
        _wasGeneratedBy(_did, _did, _msgSender(), _activityId, _immutableUrl);

    }

    function updateMetadataUrl(
        bytes32 _did,
        bytes32 _checksum,
        string memory _url,
        string memory _immutableUrl
    )
    public
    onlyDIDOwner(_did)
    virtual {
        didRegisterList.update(_did, _checksum, _url, _msgSender(), _immutableUrl);
        used(
            keccak256(abi.encode(_did, _checksum, _url, _immutableUrl, block.number, _msgSender())),
            _did,
            _msgSender(),
            keccak256('updateMetadataUrl'),
            '',
            _immutableUrl
        );
        emit DIDMetadataUpdated(
            _did,
            _msgSender(),
            _checksum,
            _url,
            _immutableUrl
        ); 
    }
    
    /**
     * @notice It generates a DID using as seed a bytes32 and the address of the DID creator
     * @param _didSeed refers to DID Seed used as base to generate the final DID
     * @param _creator address of the creator of the DID     
     * @return the new DID created
    */
    function hashDID(
        bytes32 _didSeed, 
        address _creator
    ) 
    public 
    pure 
    returns (bytes32) 
    {
        return keccak256(abi.encode(_didSeed, _creator));
    }
    
    /**
     * @notice areRoyaltiesValid checks if for a given DID and rewards distribution, this allocate the  
     * original creator royalties properly
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _amounts refers to the amounts to reward
     * @param _receivers refers to the receivers of rewards
     * @return true if the rewards distribution respect the original creator royalties
     */
    function areRoyaltiesValid(     
        bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address _tokenAddress
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.areRoyaltiesValid(_did, _amounts, _receivers, _tokenAddress);
    }
    
    function wasGeneratedBy(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    onlyDIDOwner(_did)
    returns (bool)
    {
        return _wasGeneratedBy(_provId, _did, _agentId, _activityId, _attributes);
    }

    
    function used(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        bytes memory _signatureUsing,    
        string memory _attributes
    )
    public
    returns (bool success)
    {
        return _used(
            _provId, _did, _agentId, _activityId, _signatureUsing, _attributes);
    }
    
    
    function wasDerivedFrom(
        bytes32 _provId,
        bytes32 _newEntityDid,
        bytes32 _usedEntityDid,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    public
    onlyOwnerProviderOrDelegated(_usedEntityDid)
    returns (bool success)
    {
        return _wasDerivedFrom(
            _provId, _newEntityDid, _usedEntityDid, _agentId, _activityId, _attributes);
    }

    
    function wasAssociatedWith(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    public
    onlyOwnerProviderOrDelegated(_did)
    returns (bool success)
    {
        return _wasAssociatedWith(
            _provId, _did, _agentId, _activityId, _attributes);
    }

    
    /**
     * @notice Implements the W3C PROV Delegation action
     * Each party involved in this method (_delegateAgentId & _responsibleAgentId) must provide a valid signature.
     * The content to sign is a representation of the footprint of the event (_did + _delegateAgentId + _responsibleAgentId + _activityId) 
     *
     * @param _provId unique identifier referring to the provenance entry
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity
     * @param _delegateAgentId refers to address acting on behalf of the provenance record
     * @param _responsibleAgentId refers to address responsible of the provenance record
     * @param _activityId refers to activity
     * @param _signatureDelegate refers to the digital signature provided by the did delegate.     
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
     */
    function actedOnBehalf(
        bytes32 _provId,
        bytes32 _did,
        address _delegateAgentId,
        address _responsibleAgentId,
        bytes32 _activityId,
        bytes memory _signatureDelegate,
        string memory _attributes
    )
    public
    onlyOwnerProviderOrDelegated(_did)
    returns (bool success)
    {
        _actedOnBehalf(
            _provId, _did, _delegateAgentId, _responsibleAgentId, _activityId, _signatureDelegate, _attributes);
        addDIDProvenanceDelegate(_did, _delegateAgentId);
        return true;
    }
    
    
    /**
     * @notice addDIDProvider add new DID provider.
     *
     * @dev it adds new DID provider to the providers list. A provider
     *      is any entity that can serve the registered asset
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _provider provider's address.
     */
    function addDIDProvider(
        bytes32 _did,
        address _provider
    )
    external
    onlyDIDOwner(_did)
    {
        didRegisterList.addProvider(_did, _provider);

        emit DIDProviderAdded(
            _did,
            _provider
        );
    }

    /**
     * @notice removeDIDProvider delete an existing DID provider.
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _provider provider's address.
     */
    function removeDIDProvider(
        bytes32 _did,
        address _provider
    )
    external
    onlyDIDOwner(_did)
    {
        bool state = didRegisterList.removeProvider(_did, _provider);

        emit DIDProviderRemoved(
            _did,
            _provider,
            state
        );
    }

    /**
     * @notice addDIDProvenanceDelegate add new DID provenance delegate.
     *
     * @dev it adds new DID provenance delegate to the delegates list. 
     * A delegate is any entity that interact with the provenance entries of one DID
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _delegate delegates's address.
     */
    function addDIDProvenanceDelegate(
        bytes32 _did,
        address _delegate
    )
    public
    onlyOwnerProviderOrDelegated(_did)
    {
        didRegisterList.addDelegate(_did, _delegate);

        emit DIDProvenanceDelegateAdded(
            _did,
            _delegate
        );
    }

    /**
     * @notice removeDIDProvenanceDelegate delete an existing DID delegate.
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _delegate delegate's address.
     */
    function removeDIDProvenanceDelegate(
        bytes32 _did,
        address _delegate
    )
    external
    onlyOwnerProviderOrDelegated(_did)
    {
        bool state = didRegisterList.removeDelegate(_did, _delegate);

        emit DIDProvenanceDelegateRemoved(
            _did,
            _delegate,
            state
        );
    }


    /**
     * @notice transferDIDOwnership transfer DID ownership
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _newOwner new owner address
     */
    function transferDIDOwnership(bytes32 _did, address _newOwner)
    external
    {
        _transferDIDOwnership(_msgSender(), _did, _newOwner);
    }

    function _transferDIDOwnership(address _sender, bytes32 _did, address _newOwner) internal
    {
        require(isDIDOwner(_sender, _did), 'Only owner');

        didRegisterList.updateDIDOwner(_did, _newOwner);

        _wasAssociatedWith(
            keccak256(abi.encode(_did, _sender, 'transferDID', _newOwner, block.number)),
            _did, _newOwner, keccak256('transferDID'), 'transferDID');
        
        emit DIDOwnershipTransferred(
            _did, 
            _sender,
            _newOwner
        );
    }

    /**
     * @dev grantPermission grants access permission to grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function grantPermission(
        bytes32 _did,
        address _grantee
    )
    external
    onlyDIDOwner(_did)
    {
        _grantPermission(_did, _grantee);
    }

    /**
     * @dev revokePermission revokes access permission from grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function revokePermission(
        bytes32 _did,
        address _grantee
    )
    external
    onlyDIDOwner(_did)
    {
        _revokePermission(_did, _grantee);
    }

    /**
     * @dev getPermission gets access permission of a grantee
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address
     * @return true if grantee has access permission to a DID
     */
    function getPermission(
        bytes32 _did,
        address _grantee
    )
    external
    view
    returns(bool)
    {
        return _getPermission(_did, _grantee);
    }

    /**
     * @notice isDIDProvider check whether a given DID provider exists
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _provider provider's address.
     */
    function isDIDProvider(
        bytes32 _did,
        address _provider
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.isProvider(_did, _provider);
    }

    function isDIDProviderOrOwner(
        bytes32 _did,
        address _provider
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.isProvider(_did, _provider) || _provider == getDIDOwner(_did);
    }

    /**
    * @param _did refers to decentralized identifier (a bytes32 length ID).
    * @return owner the did owner
    * @return lastChecksum last checksum
    * @return url URL to the DID metadata
    * @return lastUpdatedBy who was the last updating the DID
    * @return blockNumberUpdated In which block was the DID updated
    * @return providers the list of providers
    * @return royalties the royalties amount
    * @return immutableUrl includes the url to the DDO in immutable storage
    * @return nftInitialized if the NFT has been initialized
    */
    function getDIDRegister(
        bytes32 _did
    )
    public
    view
    returns (
        address owner,
        bytes32 lastChecksum,
        string memory url,
        address lastUpdatedBy,
        uint256 blockNumberUpdated,
        address[] memory providers,
        uint256 royalties,
        string memory immutableUrl,
        bool nftInitialized
    )
    {
        owner = didRegisterList.didRegisters[_did].owner;
        lastChecksum = didRegisterList.didRegisters[_did].lastChecksum;
        url = didRegisterList.didRegisters[_did].url;
        lastUpdatedBy = didRegisterList.didRegisters[_did].lastUpdatedBy;
        blockNumberUpdated = didRegisterList
            .didRegisters[_did].blockNumberUpdated;
        providers = didRegisterList.didRegisters[_did].providers;
        royalties = didRegisterList.didRegisters[_did].royalties;
        immutableUrl = didRegisterList.didRegisters[_did].immutableUrl;
        nftInitialized = didRegisterList.didRegisters[_did].nftInitialized;
    }

    function getNFTInfo(
        bytes32 _did
    )
    public
    view
    returns (
        address nftContractAddress,
        bool nftInitialized
    )
    {
        nftContractAddress = didRegisterList.didRegisters[_did].nftContractAddress;
        nftInitialized = didRegisterList.didRegisters[_did].nftInitialized;
    }
    
    /**
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return blockNumberUpdated last modified (update) block number of a DID.
     */
    function getBlockNumberUpdated(bytes32 _did)
    public
    view
    returns (uint256 blockNumberUpdated)
    {
        return didRegisterList.didRegisters[_did].blockNumberUpdated;
    }

    /**
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return didOwner the address of the DID owner.
     */
    function getDIDOwner(bytes32 _did)
    public
    view
    returns (address didOwner)
    {
        return didRegisterList.didRegisters[_did].owner;
    }

    function getDIDRoyaltyRecipient(bytes32 _did)
    public
    view
    returns (address)
    {
        address res = didRegisterList.didRegisters[_did].royaltyRecipient;
        if (res == address(0)) {
            return didRegisterList.didRegisters[_did].creator;
        }
        return res;
    }

    function getDIDRoyaltyScheme(bytes32 _did)
    public
    view
    returns (address)
    {
        return address(didRegisterList.didRegisters[_did].royaltyScheme);
    }

    function getDIDCreator(bytes32 _did)
    public
    view
    returns (address)
    {
        return didRegisterList.didRegisters[_did].creator;
    }

    /**
     * @dev _grantPermission grants access permission to grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function _grantPermission(
        bytes32 _did,
        address _grantee
    )
    internal
    {
        require(
            _grantee != address(0),
            'Invalid grantee'
        );
        didPermissions[_did][_grantee] = true;
        emit DIDPermissionGranted(
            _did,
            _msgSender(),
            _grantee
        );
    }

    /**
     * @dev _revokePermission revokes access permission from grantee 
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     */
    function _revokePermission(
        bytes32 _did,
        address _grantee
    )
    internal
    {
        require(
            didPermissions[_did][_grantee],
            'Grantee already revoked'
        );
        didPermissions[_did][_grantee] = false;
        emit DIDPermissionRevoked(
            _did,
            _msgSender(),
            _grantee
        );
    }

    /**
     * @dev _getPermission gets access permission of a grantee
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _grantee address 
     * @return true if grantee has access permission to a DID 
     */
    function _getPermission(
        bytes32 _did,
        address _grantee
    )
    internal
    view
    returns(bool)
    {
        return didPermissions[_did][_grantee];
    }


    //// PROVENANCE SUPPORT METHODS

    /**
     * Fetch the complete provenance entry attributes
     * @param _provId refers to the provenance identifier
     * @return did to what DID refers this entry
     * @return relatedDid DID related with the entry
     * @return agentId the agent identifier
     * @return activityId referring to the id of the activity
     * @return agentInvolvedId agent involved with the action
     * @return method the w3c provenance method
     * @return createdBy who is creating this entry
     * @return blockNumberUpdated in which block was updated
     * @return signature digital signature 
     * 
     */
    function getProvenanceEntry(
        bytes32 _provId
    )
    public
    view
    returns (     
        bytes32 did,
        bytes32 relatedDid,
        address agentId,
        bytes32 activityId,
        address agentInvolvedId,
        uint8   method,
        address createdBy,
        uint256 blockNumberUpdated,
        bytes memory signature
    )
    {
        did = provenanceRegistry.list[_provId].did;
        relatedDid = provenanceRegistry.list[_provId].relatedDid;
        agentId = provenanceRegistry.list[_provId].agentId;
        activityId = provenanceRegistry.list[_provId].activityId;
        agentInvolvedId = provenanceRegistry.list[_provId].agentInvolvedId;
        method = provenanceRegistry.list[_provId].method;
        createdBy = provenanceRegistry.list[_provId].createdBy;
        blockNumberUpdated = provenanceRegistry
            .list[_provId].blockNumberUpdated;
        signature = provenanceRegistry.list[_provId].signature;
    }

    /**
     * @notice isDIDOwner check whether a given address is owner for a DID
     * @param _address user address.
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     */
    function isDIDOwner(
        address _address,
        bytes32 _did
    )
    public
    view
    returns (bool)
    {
        return _address == didRegisterList.didRegisters[_did].owner;
    }


    /**
     * @notice isOwnerProviderOrDelegate check whether _msgSender() is owner, provider or
     * delegate for a DID given
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return boolean true if yes
     */
    function isOwnerProviderOrDelegate(
        bytes32 _did
    )
    public
    view
    returns (bool)
    {
        return (_msgSender() == didRegisterList.didRegisters[_did].owner ||
                    isProvenanceDelegate(_did, _msgSender()) ||
                    isDIDProvider(_did, _msgSender()));
    }    
    
    /**
     * @notice isProvenanceDelegate check whether a given DID delegate exists
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @param _delegate delegate's address.
     * @return boolean true if yes     
     */
    function isProvenanceDelegate(
        bytes32 _did,
        address _delegate
    )
    public
    view
    returns (bool)
    {
        return didRegisterList.isDelegate(_did, _delegate);
    }

    /**
     * @param _did refers to decentralized identifier (a bytes32 length ID).
     * @return provenanceOwner the address of the Provenance owner.
     */
    function getProvenanceOwner(bytes32 _did)
    public
    view
    returns (address provenanceOwner)
    {
        return provenanceRegistry.list[_did].createdBy;
    }
    
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import '../Common.sol';
import './DIDFactory.sol';
import '../token/erc1155/NFT1155Upgradeable.sol';
import '../token/erc721/NFT721Upgradeable.sol';
import '../royalties/StandardRoyalties.sol';

/**
 * @title DID Registry
 * @author Nevermined
 *
 * @dev Implementation of an on-chain registry of assets. It allows users to register their digital assets
 * and the on-chain resolution of them via a Decentralized Identifier (DID) into their Metadata (DDO).  
 *
 * The permissions are organized in different levels:
 *
 * 1. Contract Ownership Level. At the top level the DID Registry contract is 'Ownable' so the owner (typically the deployer) of the contract
 *    can manage everything in the registry.
 * 2. Contract Operator Level. At the second level we have the Registry contract operator `REGISTRY_OPERATOR_ROLE`. Typically this role is 
 *    granted to some Nevermined contracts to automate the execution of common functions.
 *    This role is managed using the  `grantRegistryOperatorRole` and `revokeRegistryOperatorRole` function
 * 3. Asset Access Level. Asset owners can provide individual asset permissions to external providers via the `addProvider` function.
 *    Providers typically (Nevermined Nodes) can manage asset access. 
 * 4. Asset Provenance Level. Provenance delegates can register provenance events at asset level.
 */
contract DIDRegistry is DIDFactory {

    using DIDRegistryLibrary for DIDRegistryLibrary.DIDRegisterList;

    NFT1155Upgradeable public erc1155;
    NFT721Upgradeable public erc721;

    mapping (address => bool) public royaltiesCheckers;
    StandardRoyalties public defaultRoyalties;

    INVMConfig public nvmConfig;

    // Role to operate the NFT contract
    bytes32 public constant REGISTRY_OPERATOR_ROLE = keccak256('REGISTRY_OPERATOR_ROLE');
    
    modifier onlyRegistryOperator
    {
        require(
            isRegistryOperator(_msgSender()) || hasNVMOperatorRole(_msgSender()),
            'Only registry operator'
        );
        _;
    }    
    
    //////////////////////////////////////////////////////////////
    ////////  EVENTS  ////////////////////////////////////////////
    //////////////////////////////////////////////////////////////
    
    /**
     * @dev DIDRegistry Initializer
     *      Initialize Ownable. Only on contract creation.
     * @param _owner refers to the owner of the contract.
     */
    function initialize(
        address _owner,
        address _erc1155,
        address _erc721,
        address _config,
        address _royalties
    )
    public
    initializer
    {
        OwnableUpgradeable.__Ownable_init();
        AccessControlUpgradeable.__AccessControl_init();
        AccessControlUpgradeable._setupRole(REGISTRY_OPERATOR_ROLE, _owner);
        
        erc1155 = NFT1155Upgradeable(_erc1155);
        erc721 = NFT721Upgradeable(_erc721);
        transferOwnership(_owner);
        manager = _owner;
        defaultRoyalties = StandardRoyalties(_royalties);
        nvmConfig = INVMConfig(_config);
    }

    function setDefaultRoyalties(address _royalties) public onlyOwner {
        defaultRoyalties = StandardRoyalties(_royalties);
    }

    function registerRoyaltiesChecker(address _addr) public onlyOwner {
        royaltiesCheckers[_addr] = true;
    }

    function setNFT1155(address _erc1155) public onlyOwner {
        erc1155 = NFT1155Upgradeable(_erc1155);
    }

    ///// PERMISSIONS
    function grantRegistryOperatorRole(
        address account
    )
    public
    virtual
    onlyOwner
    {
        AccessControlUpgradeable._setupRole(REGISTRY_OPERATOR_ROLE, account);
    }

    function revokeRegistryOperatorRole(
        address account
    )
    public
    virtual
    onlyOwner
    {
        AccessControlUpgradeable._revokeRole(REGISTRY_OPERATOR_ROLE, account);
    }

    function isRegistryOperator(
        address operator
    )
    public
    view
    virtual
    returns (bool)
    {
        return AccessControlUpgradeable.hasRole(REGISTRY_OPERATOR_ROLE, operator);
    }

    event DIDRoyaltiesAdded(bytes32 indexed did, address indexed addr);
    event DIDRoyaltyRecipientChanged(bytes32 indexed did, address indexed addr);

    function setDIDRoyalties(
        bytes32 _did,
        address _royalties
    )
    public
    {
        require(didRegisterList.didRegisters[_did].creator == _msgSender(), 'Only creator can set royalties');
        require(address(didRegisterList.didRegisters[_did].royaltyScheme) == address(0), 'Cannot change royalties');
        didRegisterList.didRegisters[_did].royaltyScheme = IRoyaltyScheme(_royalties);

        emit DIDRoyaltiesAdded(
            _did,
            _royalties
        );
    }

    function setDIDRoyaltyRecipient(
        bytes32 _did,
        address _recipient
    )
    public
    {
        require(didRegisterList.didRegisters[_did].creator == _msgSender(), 'Only creator can set royalties');
        didRegisterList.didRegisters[_did].royaltyRecipient = _recipient;

        emit DIDRoyaltyRecipientChanged(
            _did,
            _recipient
        );
    }

    /**
     * @notice transferDIDOwnershipManaged transfer DID ownership
     * @param _did refers to decentralized identifier (a bytes32 length ID)
     * @param _newOwner new owner address
     */
    function transferDIDOwnershipManaged(address _sender, bytes32 _did, address _newOwner)
    external
    onlyRegistryOperator
    {
        _transferDIDOwnership(_sender, _did, _newOwner);
    }

    /**
     * @notice Register a Mintable DID using NFTs based in the ERC-1155 standard.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID).
     * @param _nftContractAddress is the address of the NFT contract associated to the asset
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _cap refers to the mint cap
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if true it mints the ERC-1155 NFTs attached to the asset
     * @param _activityId refers to activity
     * @param _nftMetadata refers to the url providing the NFT Metadata 
     * @param _immutableUrl includes the url to the DDO in immutable storage              
     */
    function registerMintableDID(
        bytes32 _didSeed,
        address _nftContractAddress,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        uint256 _cap,
        uint256 _royalties,
        bool _mint,
        bytes32 _activityId,
        string memory _nftMetadata,
        string memory _immutableUrl
    )
    public
    onlyValidAttributes(_nftMetadata)
    {
        registerDID(_didSeed, _checksum, _providers, _url, _activityId, _immutableUrl);
        enableAndMintDidNft(
            hashDID(_didSeed, _msgSender()),
            _nftContractAddress,
            _cap,
            _royalties,
            _mint,
            _nftMetadata
        );
    }

    /**
     * @notice Register a Mintable DID using NFTs based in the ERC-721 standard.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID).
     * @param _nftContractAddress address of the NFT contract associated to the asset
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if true it mints the ERC-1155 NFTs attached to the asset
     * @param _activityId refers to activity
     * @param _immutableUrl includes the url to the DDO in immutable storage       
     */
    function registerMintableDID721(
        bytes32 _didSeed,
        address _nftContractAddress,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        uint256 _royalties,
        bool _mint,
        bytes32 _activityId,
        string memory _immutableUrl
    )
    public
    {
        registerDID(_didSeed, _checksum, _providers, _url, _activityId, _immutableUrl);
        enableAndMintDidNft721(
            hashDID(_didSeed, _msgSender()),
            _nftContractAddress,
            _royalties,
            _mint
        );
    }



    /**
     * @notice Register a Mintable DID.
     *
     * @dev The first attribute of a DID registered sets the DID owner.
     *      Subsequent updates record _checksum and update info.
     *
     * @param _didSeed refers to decentralized identifier seed (a bytes32 length ID).
     * @param _nftContractAddress address of the NFT contract associated to the asset     
     * @param _checksum includes a one-way HASH calculated using the DDO content.
     * @param _providers list of addresses that can act as an asset provider     
     * @param _url refers to the url resolving the DID into a DID Document (DDO), limited to 2048 bytes.
     * @param _cap refers to the mint cap
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _activityId refers to activity
     * @param _nftMetadata refers to the url providing the NFT Metadata
     * @param _immutableUrl includes the url to the DDO in immutable storage               
     */
    function registerMintableDID(
        bytes32 _didSeed,
        address _nftContractAddress,
        bytes32 _checksum,
        address[] memory _providers,
        string memory _url,
        uint256 _cap,
        uint256 _royalties,
        bytes32 _activityId,
        string memory _nftMetadata,
        string memory _immutableUrl
    )
    public
    onlyValidAttributes(_nftMetadata)
    {
        registerMintableDID(
            _didSeed, _nftContractAddress, _checksum, _providers, _url, _cap, _royalties, false, _activityId, _nftMetadata, _immutableUrl);
    }

    
    /**
     * @notice enableDidNft creates the initial setup of NFTs minting and royalties distribution for ERC-1155 NFTs.
     * After this initial setup, this data can't be changed anymore for the DID given, even for the owner of the DID.
     * The reason of this is to avoid minting additional NFTs after the initial agreement, what could affect the 
     * valuation of NFTs of a DID already created.
      
     * @dev update the DID registry providers list by adding the mintCap and royalties configuration
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _cap refers to the mint cap
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if is true mint directly the amount capped tokens and lock in the _lockAddress
     * @param _nftMetadata refers to the url providing the NFT Metadata          
     */
    function enableAndMintDidNft(
        bytes32 _did,
        address _nftAddress,
        uint256 _cap,
        uint256 _royalties,
        bool _mint,
        string memory _nftMetadata
    )
    public
    onlyDIDOwner(_did)
    returns (bool success)
    {
        didRegisterList.initializeNftConfig(_did, _nftAddress, _royalties > 0 ? defaultRoyalties : IRoyaltyScheme(address(0)));
        NFT1155Upgradeable _nftInstance;
        if (_nftAddress == address(0))
            _nftInstance = erc1155;
        else
            _nftInstance = NFT1155Upgradeable(_nftAddress);
        
        _nftInstance.setNFTAttributes(uint256(_did), 0, _cap, _nftMetadata);
        
        if (_royalties > 0) {
            _nftInstance.setTokenRoyalty(uint256(_did), _msgSender(), _royalties);
            if (address(defaultRoyalties) != address(0)) defaultRoyalties.setRoyalty(_did, _royalties);
        }
        
        if (_mint)
            _nftInstance.mint(_msgSender() ,uint256(_did), _cap, '');
        
        return super.used(
            keccak256(abi.encode(_did, _cap, _royalties, _msgSender())),
            _did, _msgSender(), keccak256('enableNft'), '', 'nft initialization');
    }

    /**
     * @notice enableAndMintDidNft721 creates the initial setup of NFTs minting and royalties distribution for ERC-721 NFTs.
     * After this initial setup, this data can't be changed anymore for the DID given, even for the owner of the DID.
     * The reason of this is to avoid minting additional NFTs after the initial agreement, what could affect the 
     * valuation of NFTs of a DID already created.
      
     * @dev update the DID registry providers list by adding the mintCap and royalties configuration
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _nftContractAddress address of the NFT contract associated to the asset     
     * @param _royalties refers to the royalties to reward to the DID creator in the secondary market
     * @param _mint if is true mint directly the amount capped tokens and lock in the _lockAddress          
     */    
    function enableAndMintDidNft721(
        bytes32 _did,
        address _nftContractAddress,
        uint256 _royalties,
        bool _mint
    )
    public
    onlyDIDOwner(_did)
    returns (bool success)
    {
        didRegisterList.initializeNft721Config(_did, _nftContractAddress, _royalties > 0 ? defaultRoyalties : IRoyaltyScheme(address(0)));

        NFT721Upgradeable _nftInstance;
        if (_nftContractAddress == address(0))
            _nftInstance = erc721;
        else
            _nftInstance = NFT721Upgradeable(_nftContractAddress);
        
        if (_royalties > 0) {
            if (address(defaultRoyalties) != address(0)) defaultRoyalties.setRoyalty(_did, _royalties);
            _nftInstance.setTokenRoyalty(uint256(_did), _msgSender(), _royalties);
        }
        
        if (_mint)
            _nftInstance.mint(_msgSender() ,uint256(_did));
        
        return super.used(
            keccak256(abi.encode(_did, 1, _royalties, _msgSender())),
            _did, _msgSender(), keccak256('enableNft721'), '', 'nft initialization');
    }

    function _provenanceStorage() override internal view returns (bool) {
        return address(nvmConfig) == address(0) || nvmConfig.getProvenanceStorage();
    }

    function registerUsedProvenance(bytes32 _did, bytes32 _cond, string memory name, address user) public onlyRegistryOperator {
        _used(_cond, _did, user, keccak256(bytes(name)), '', name);
    }

    /**
     * @dev getNvmConfigAddress get the address of the NeverminedConfig contract
     * @return NeverminedConfig contract address
     */
    function getNvmConfigAddress()
    public
    override
    view
    returns (address)
    {
        return address(nvmConfig);
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '../interfaces/IRoyaltyScheme.sol';

/**
 * @title DID Registry Library
 * @author Nevermined
 *
 * @dev All function calls are currently implemented without side effects
 */
library DIDRegistryLibrary {

    // DIDRegistry Entity
    struct DIDRegister {
        // DIDRegistry entry owner
        address owner;
        // The percent of the sale that is going back to the original `creator` in the secondary market  
        uint8 royalties;
        // Flag to control if NFTs config was already initialized
        bool nftInitialized;
        // Address of the NFT Contract
        address nftContractAddress;
        // DIDRegistry original creator, this can't be modified after the asset is registered 
        address creator;
        // Checksum associated to the DID
        bytes32 lastChecksum;
        // URL to the metadata associated to the DID
        string  url;
        // Who was the last one updated the entry
        address lastUpdatedBy;
        // When was the last time was updated
        uint256 blockNumberUpdated;
        // Providers able to manage this entry
        address[] providers;
        // Delegates able to register provenance events on behalf of the owner or providers
        address[] delegates;
        // The NFTs supply associated to the DID 
//        uint256 nftSupply;
        // The max number of NFTs associated to the DID that can be minted 
//        uint256 mintCap;
        address royaltyRecipient;
        IRoyaltyScheme royaltyScheme;
        // URL to the Metadata in Immutable storage 
        string  immutableUrl;        
    }

    // List of DID's registered in the system
    struct DIDRegisterList {
        mapping(bytes32 => DIDRegister) didRegisters;
    }

    /**
     * @notice update the DID store
     * @dev access modifiers and storage pointer should be implemented in DIDRegistry
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _checksum includes a one-way HASH calculated using the DDO content
     * @param _url includes the url resolving to the DID Document (DDO)
     * @param _sender the address of the user updating the entry
     * @param _immutableUrl includes the url to the DDO in immutable storage     
     */
    function update(
        DIDRegisterList storage _self,
        bytes32 _did,
        bytes32 _checksum,
        string memory _url,
        address _sender,
        string memory _immutableUrl
    )
    internal
    {
        address didOwner = _self.didRegisters[_did].owner;
        address creator = _self.didRegisters[_did].creator;
        
        if (didOwner == address(0)) {
            didOwner = _sender;
            creator = didOwner;
        }

        _self.didRegisters[_did].owner = didOwner;
        _self.didRegisters[_did].creator = creator;
        _self.didRegisters[_did].lastChecksum = _checksum;
        _self.didRegisters[_did].url = _url;
        _self.didRegisters[_did].lastUpdatedBy = _sender;
        _self.didRegisters[_did].owner = didOwner;
        _self.didRegisters[_did].blockNumberUpdated = block.number;
        _self.didRegisters[_did].immutableUrl = _immutableUrl;
    }

    /**
     * @notice initializeNftConfig creates the initial setup of NFTs minting and royalties distribution.
     * After this initial setup, this data can't be changed anymore for the DID given, even for the owner of the DID.
     * The reason of this is to avoid minting additional NFTs after the initial agreement, what could affect the 
     * valuation of NFTs of a DID already created. 
     * @dev update the DID registry providers list by adding the nftContract and royalties configuration
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _royaltyHandler contract for handling royalties
     */
    function initializeNftConfig(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _nftContractAddress,
        IRoyaltyScheme _royaltyHandler
    )
    internal
    {
        require(_self.didRegisters[_did].owner != address(0), 'DID not stored');
        require(!_self.didRegisters[_did].nftInitialized, 'NFT already initialized');
        
        _self.didRegisters[_did].nftContractAddress = _nftContractAddress;
        _self.didRegisters[_did].royaltyScheme = _royaltyHandler;
        _self.didRegisters[_did].nftInitialized = true;
    }

    function initializeNft721Config(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _nftContractAddress,
        IRoyaltyScheme _royaltyHandler
    )
    internal
    {
        require(_self.didRegisters[_did].owner != address(0), 'DID not stored');
        require(!_self.didRegisters[_did].nftInitialized, 'NFT already initialized');
        
        _self.didRegisters[_did].nftContractAddress = _nftContractAddress;
        _self.didRegisters[_did].royaltyScheme = _royaltyHandler;
        _self.didRegisters[_did].nftInitialized = true;
    }


    /**
     * @notice areRoyaltiesValid checks if for a given DID and rewards distribution, this allocate the  
     * original creator royalties properly
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _amounts refers to the amounts to reward
     * @param _receivers refers to the receivers of rewards
     * @return true if the rewards distribution respect the original creator royalties
     */
    function areRoyaltiesValid(
        DIDRegisterList storage _self,
        bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address _tokenAddress
    )
    internal
    view
    returns (bool)
    {
        if (address(_self.didRegisters[_did].royaltyScheme) != address(0)) {
            return _self.didRegisters[_did].royaltyScheme.check(_did, _amounts, _receivers, _tokenAddress);
        }
        // If there are no royalties everything is good
        if (_self.didRegisters[_did].royalties == 0) {
            return true;
        }

        // If (sum(_amounts) == 0) - It means there is no payment so everything is valid
        // returns true;
        uint256 _totalAmount = 0;
        for(uint i = 0; i < _amounts.length; i++)
            _totalAmount = _totalAmount + _amounts[i];
        if (_totalAmount == 0)
            return true;
        
        // If (_did.creator is not in _receivers) - It means the original creator is not included as part of the payment
        // return false;
        address recipient = _self.didRegisters[_did].creator;
        if (_self.didRegisters[_did].royaltyRecipient != address(0)) {
            recipient = _self.didRegisters[_did].royaltyRecipient;
        }
        bool found = false;
        uint256 index;
        for (index = 0; index < _receivers.length; index++) {
            if (recipient == _receivers[index])  {
                found = true;
                break;
            }
        }

        // The creator royalties are not part of the rewards
        if (!found) {
            return false;
        }

        // If the amount to receive by the creator is lower than royalties the calculation is not valid
        // return false;
        uint256 _requiredRoyalties = _totalAmount * _self.didRegisters[_did].royalties / 100;

        // Check if royalties are enough
        // Are we paying enough royalties in the secondary market to the original creator?
        return (_amounts[index] >= _requiredRoyalties);
    }


    /**
     * @notice addProvider add provider to DID registry
     * @dev update the DID registry providers list by adding a new provider
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param provider the provider's address 
     */
    function addProvider(
        DIDRegisterList storage _self,
        bytes32 _did,
        address provider
    )
    internal
    {
        require(
            provider != address(0) && provider != address(this),
            'Invalid provider'
        );
        
        if (!isProvider(_self, _did, provider)) {
            _self.didRegisters[_did].providers.push(provider);
        }

    }

    /**
     * @notice removeProvider remove provider from DID registry
     * @dev update the DID registry providers list by removing an existing provider
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _provider the provider's address 
     */
    function removeProvider(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _provider
    )
    internal
    returns(bool)
    {
        require(
            _provider != address(0),
            'Invalid provider'
        );

        int256 i = getProviderIndex(_self, _did, _provider);

        if (i == -1) {
            return false;
        }

        delete _self.didRegisters[_did].providers[uint256(i)];

        return true;
    }

    /**
     * @notice updateDIDOwner transfer DID ownership to a new owner
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _newOwner the new DID owner address
     */
    function updateDIDOwner(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _newOwner
    )
    internal
    {
        require(_newOwner != address(0));
        _self.didRegisters[_did].owner = _newOwner;
    }

    /**
     * @notice isProvider check whether DID provider exists
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _provider the provider's address 
     * @return true if the provider already exists
     */
    function isProvider(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _provider
    )
    internal
    view
    returns(bool)
    {
        if (getProviderIndex(_self, _did, _provider) == -1)
            return false;
        return true;
    }


    
    /**
     * @notice getProviderIndex get the index of a provider
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param provider the provider's address 
     * @return the index if the provider exists otherwise return -1
     */
    function getProviderIndex(
        DIDRegisterList storage _self,
        bytes32 _did,
        address provider
    )
    private
    view
    returns(int256 )
    {
        for (uint256 i = 0;
            i < _self.didRegisters[_did].providers.length; i++) {
            if (provider == _self.didRegisters[_did].providers[i]) {
                return int(i);
            }
        }

        return - 1;
    }

    //////////// DELEGATE METHODS

    /**
     * @notice addDelegate add delegate to DID registry
     * @dev update the DID registry delegates list by adding a new delegate
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param delegate the delegate's address 
     */
    function addDelegate(
        DIDRegisterList storage _self,
        bytes32 _did,
        address delegate
    )
    internal
    {
        require(delegate != address(0) && delegate != address(this));

        if (!isDelegate(_self, _did, delegate)) {
            _self.didRegisters[_did].delegates.push(delegate);
        }

    }

    /**
     * @notice removeDelegate remove delegate from DID registry
     * @dev update the DID registry delegates list by removing an existing delegate
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _delegate the delegate's address 
     */
    function removeDelegate(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _delegate
    )
    internal
    returns(bool)
    {
        require(_delegate != address(0));

        int256 i = getDelegateIndex(_self, _did, _delegate);

        if (i == -1) {
            return false;
        }

        delete _self.didRegisters[_did].delegates[uint256(i)];

        return true;
    }

    /**
     * @notice isDelegate check whether DID delegate exists
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _delegate the delegate's address 
     * @return true if the delegate already exists
     */
    function isDelegate(
        DIDRegisterList storage _self,
        bytes32 _did,
        address _delegate
    )
    internal
    view
    returns(bool)
    {
        if (getDelegateIndex(_self, _did, _delegate) == -1)
            return false;
        return true;
    }

    /**
     * @notice getDelegateIndex get the index of a delegate
     * @param _self refers to storage pointer
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param delegate the delegate's address 
     * @return the index if the delegate exists otherwise return -1
     */
    function getDelegateIndex(
        DIDRegisterList storage _self,
        bytes32 _did,
        address delegate
    )
    private
    view
    returns(int256)
    {
        for (uint256 i = 0;
            i < _self.didRegisters[_did].delegates.length; i++) {
            if (delegate == _self.didRegisters[_did].delegates[i]) {
                return int(i);
            }
        }

        return - 1;
    }

}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../governance/INVMConfig.sol';
import '../Common.sol';

/**
 * @title Provenance Registry Library
 * @author Nevermined
 *
 * @dev All function calls are currently implemented without side effects
 */
/* solium-disable-next-line */
abstract contract ProvenanceRegistry is CommonOwnable, AccessControlUpgradeable {

    // solhint-disable-next-line
    function __ProvenanceRegistry_init() internal initializer {
        __Context_init_unchained();
        __ProvenanceRegistry_init_unchained();
    }

    // solhint-disable-next-line
    function __ProvenanceRegistry_init_unchained() internal initializer {
    }
    
    // Provenance Entity
    struct Provenance {
        // DID associated to this provenance event
        bytes32 did;
        // DID created or associated to the original one triggered on this provenance event
        bytes32 relatedDid;
        // Agent associated to the provenance event
        address agentId;
        // Provenance activity
        bytes32 activityId;
        // Agent involved in the provenance event beyond the agent id
        address agentInvolvedId;
        // W3C PROV method
        uint8   method;
        // Who added this event to the registry
        address createdBy;
        // Block number of when it was added
        uint256 blockNumberUpdated;
        // Signature of the delegate
        bytes   signature;  
    }

    // List of Provenance entries registered in the system
    struct ProvenanceRegistryList {
        mapping(bytes32 => Provenance) list;
    }
    
    ProvenanceRegistryList internal provenanceRegistry;
    
    // W3C Provenance Methods
    enum ProvenanceMethod {
        ENTITY,
        ACTIVITY,
        WAS_GENERATED_BY,
        USED,
        WAS_INFORMED_BY,
        WAS_STARTED_BY,
        WAS_ENDED_BY,
        WAS_INVALIDATED_BY,
        WAS_DERIVED_FROM,
        AGENT,
        WAS_ATTRIBUTED_TO,
        WAS_ASSOCIATED_WITH,
        ACTED_ON_BEHALF
    }

    /**
    * Provenance Events
    */
    event ProvenanceAttributeRegistered(
        bytes32 indexed provId,
        bytes32 indexed _did,
        address indexed _agentId,
        bytes32 _activityId,
        bytes32 _relatedDid,
        address _agentInvolvedId,
        ProvenanceMethod _method,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    ///// EVENTS ///////
    
    event WasGeneratedBy(
        bytes32 indexed _did,
        address indexed _agentId,
        bytes32 indexed _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );


    event Used(
        bytes32 indexed _did,
        address indexed _agentId,
        bytes32 indexed _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    event WasDerivedFrom(
        bytes32 indexed _newEntityDid,
        bytes32 indexed _usedEntityDid,
        address indexed _agentId,
        bytes32 _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    event WasAssociatedWith(
        bytes32 indexed _entityDid,
        address indexed _agentId,
        bytes32 indexed _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    event ActedOnBehalf(
        bytes32 indexed _entityDid,
        address indexed _delegateAgentId,
        address indexed _responsibleAgentId,
        bytes32 _activityId,
        bytes32 provId,
        string _attributes,
        uint256 _blockNumberUpdated
    );

    function _provenanceStorage() virtual internal returns (bool);

    /**
     * @notice create an event in the Provenance store
     * @dev access modifiers and storage pointer should be implemented in ProvenanceRegistry
     * @param _provId refers to provenance event identifier
     * @param _did refers to decentralized identifier (a byte32 length ID)
     * @param _relatedDid refers to decentralized identifier (a byte32 length ID) of a related entity
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _agentInvolvedId refers to address of the agent involved with the provenance record     
     * @param _method refers to the W3C Provenance method
     * @param _createdBy refers to address of the agent triggering the activity
     * @param _signatureDelegate refers to the digital signature provided by the did delegate. 
    */
    function createProvenanceEntry(
        bytes32 _provId,
        bytes32 _did,
        bytes32 _relatedDid,
        address _agentId,
        bytes32 _activityId,
        address _agentInvolvedId,
        ProvenanceMethod   _method,
        address _createdBy,
        bytes  memory _signatureDelegate,
        string memory _attributes
    )
    internal
    {

        if (!_provenanceStorage()) {
            return;
        }

        require(
            provenanceRegistry.list[_provId].createdBy == address(0x0),
            'Already existing provId'
        );

        provenanceRegistry.list[_provId] = Provenance({
            did: _did,
            relatedDid: _relatedDid,
            agentId: _agentId,
            activityId: _activityId,
            agentInvolvedId: _agentInvolvedId,
            method: uint8(_method),
            createdBy: _createdBy,
            blockNumberUpdated: block.number,
            signature: _signatureDelegate
        });

        /* emitting _attributes here to avoid expensive storage */
        emit ProvenanceAttributeRegistered(
            _provId,
            _did, 
            _agentId,
            _activityId,
            _relatedDid,
            _agentInvolvedId,
            _method,
            _attributes,
            block.number
        );
        
    }


    /**
     * @notice Implements the W3C PROV Generation action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity created
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _attributes refers to the provenance attributes
     * @return the number of the new provenance size
     */
    function _wasGeneratedBy(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    virtual
    returns (bool)
    {
        
        createProvenanceEntry(
            _provId,
            _did,
            '',
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.WAS_GENERATED_BY,
            _msgSender(),
            new bytes(0), // No signatures between parties needed
            _attributes
        );

        emit WasGeneratedBy(
            _did,
           _msgSender(),
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

    /**
     * @notice Implements the W3C PROV Usage action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity created
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _signatureUsing refers to the digital signature provided by the agent using the _did     
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
    */
    function _used(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        bytes memory _signatureUsing,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {

        createProvenanceEntry(
            _provId,
            _did,
            '',
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.USED,
            _msgSender(),
            _signatureUsing,
            _attributes
        );
        
        emit Used(
            _did,
            _agentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }


    /**
     * @notice Implements the W3C PROV Derivation action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _newEntityDid refers to decentralized identifier (a bytes32 length ID) of the entity created
     * @param _usedEntityDid refers to decentralized identifier (a bytes32 length ID) of the entity used to derive the new did
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
     */
    function _wasDerivedFrom(
        bytes32 _provId,
        bytes32 _newEntityDid,
        bytes32 _usedEntityDid,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {

        createProvenanceEntry(
            _provId,
            _newEntityDid,
            _usedEntityDid,
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.WAS_DERIVED_FROM,
            _msgSender(),
            new bytes(0), // No signatures between parties needed
            _attributes
        );

        emit WasDerivedFrom(
            _newEntityDid,
            _usedEntityDid,
            _agentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

    /**
     * @notice Implements the W3C PROV Association action
     *
     * @param _provId unique identifier referring to the provenance entry     
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity
     * @param _agentId refers to address of the agent creating the provenance record
     * @param _activityId refers to activity
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
    */
    function _wasAssociatedWith(
        bytes32 _provId,
        bytes32 _did,
        address _agentId,
        bytes32 _activityId,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {
        
        createProvenanceEntry(
            _provId,
            _did,
            '',
            _agentId,
            _activityId,
            address(0x0),
            ProvenanceMethod.WAS_ASSOCIATED_WITH,
            _msgSender(),
            new bytes(0), // No signatures between parties needed
            _attributes
        );

        emit WasAssociatedWith(
            _did,
            _agentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

    /**
     * @notice Implements the W3C PROV Delegation action
     * Each party involved in this method (_delegateAgentId & _responsibleAgentId) must provide a valid signature.
     * The content to sign is a representation of the footprint of the event (_did + _delegateAgentId + _responsibleAgentId + _activityId) 
     *
     * @param _provId unique identifier referring to the provenance entry
     * @param _did refers to decentralized identifier (a bytes32 length ID) of the entity
     * @param _delegateAgentId refers to address acting on behalf of the provenance record
     * @param _responsibleAgentId refers to address responsible of the provenance record
     * @param _activityId refers to activity
     * @param _signatureDelegate refers to the digital signature provided by the did delegate.     
     * @param _attributes refers to the provenance attributes
     * @return success true if the action was properly registered
     */
    function _actedOnBehalf(
        bytes32 _provId,
        bytes32 _did,
        address _delegateAgentId,
        address _responsibleAgentId,
        bytes32 _activityId,
        bytes memory _signatureDelegate,
        string memory _attributes
    )
    internal
    virtual
    returns (bool success)
    {

        createProvenanceEntry(
            _provId,
            _did,
            '',
            _delegateAgentId,
            _activityId,
            _responsibleAgentId,
            ProvenanceMethod.ACTED_ON_BEHALF,
            _msgSender(),
            _signatureDelegate,
            _attributes
        );
        
        emit ActedOnBehalf(
            _did,
            _delegateAgentId,
            _responsibleAgentId,
            _activityId,
            _provId,
            _attributes,
            block.number
        );

        return true;
    }

    function _msgSender() internal override(CommonOwnable,ContextUpgradeable) virtual view returns (address ret) {
        return Common._msgSender();
    }
    function _msgData() internal override(CommonOwnable,ContextUpgradeable) virtual view returns (bytes calldata ret) {
        return Common._msgData();
    }    
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG\.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '../interfaces/IRoyaltyScheme.sol';
import '../registry/DIDRegistry.sol';
import '../Common.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @title Standard royalty scheme.
 * @author Nevermined
 */

contract StandardRoyalties is IRoyaltyScheme, Initializable, Common {

    DIDRegistry public registry;

    uint256 constant public DENOMINATOR = 1000000;

    mapping (bytes32 => uint256) public royalties;

    function initialize(address _registry) public initializer {
        registry = DIDRegistry(_registry);
    }

    /**
     * @notice Set royalties for a DID
     * @dev Can only be called by creator of the DID
     * @param _did DID for which the royalties are set
     * @param _royalty Royalty, the actual royalty will be _royalty / 10000 percent
     */
    function setRoyalty(bytes32 _did, uint256 _royalty) public {
        require(_royalty <= DENOMINATOR, 'royalty cannot be more than 100%');
        require(_msgSender() == registry.getDIDCreator(_did) || _msgSender() == address(registry), 'only owner can change');
        require(royalties[_did] == 0, 'royalties cannot be changed');
        royalties[_did] = _royalty;
    }

    function check(bytes32 _did,
        uint256[] memory _amounts,
        address[] memory _receivers,
        address)
    external view returns (bool)
    {
        // If there are no royalties everything is good
        uint256 rate = royalties[_did];
        if (rate == 0) {
            return true;
        }

        // If (sum(_amounts) == 0) - It means there is no payment so everything is valid
        // returns true;
        uint256 _totalAmount = 0;
        for(uint i = 0; i < _amounts.length; i++)
            _totalAmount = _totalAmount + _amounts[i];
        // If the amount to receive by the creator is lower than royalties the calculation is not valid
        // return false;
        uint256 _requiredRoyalties = _totalAmount * rate / DENOMINATOR;

        if (_requiredRoyalties == 0)
            return true;
        
        // If (_did.creator is not in _receivers) - It means the original creator is not included as part of the payment
        // return false;
        address recipient = registry.getDIDRoyaltyRecipient(_did);
        bool found = false;
        uint256 index;
        for (index = 0; index < _receivers.length; index++) {
            if (recipient == _receivers[index])  {
                found = true;
                break;
            }
        }

        // The creator royalties are not part of the rewards
        if (!found) {
            return false;
        }

        // Check if royalties are enough
        // Are we paying enough royalties in the secondary market to the original creator?
        return (_amounts[index] >= _requiredRoyalties);
    }

    /**
     * @dev getNvmConfigAddress get the address of the NeverminedConfig contract
     * @return NeverminedConfig contract address
     */
    function getNvmConfigAddress()
    public
    override
    view
    returns (address)
    {
        if (address(registry) == address(0)) {
            return address(0);
        }
        return registry.getNvmConfigAddress();
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


/**
 * @title Template Store Library
 * @author Nevermined
 *
 * @dev Implementation of the Template Store Library.
 *      
 *      Templates are blueprints for modular SEAs. When 
 *      creating an Agreement, a templateId defines the condition 
 *      and reward types that are instantiated in the ConditionStore.
 */
library TemplateStoreLibrary {

    enum TemplateState {
        Uninitialized,
        Proposed,
        Approved,
        Revoked
    }

    struct Template {
        TemplateState state;
        address owner;
        address lastUpdatedBy;
        uint256 blockNumberUpdated;
    }

    struct TemplateList {
        mapping(address => Template) templates;
        address[] templateIds;
    }

   /**
    * @notice propose new template
    * @param _self is the TemplateList storage pointer
    * @param _id proposed template contract address 
    * @return size which is the index of the proposed template
    */
    function propose(
        TemplateList storage _self,
        address _id,
        address _sender
    )
        internal
        returns (uint size)
    {
        require(
            _self.templates[_id].state == TemplateState.Uninitialized,
            'TemplateId already initialized'
        );

        _self.templates[_id] = Template({
            state: TemplateState.Proposed,
            owner: _sender,
            lastUpdatedBy: _sender,
            blockNumberUpdated: block.number
        });

        _self.templateIds.push(_id);

        return _self.templateIds.length;
    }

   /**
    * @notice approve new template
    * @param _self is the TemplateList storage pointer
    * @param _id proposed template contract address
    */
    function approve(
        TemplateList storage _self,
        address _id,
        address _sender
    )
        internal
    {
        require(
            _self.templates[_id].state == TemplateState.Proposed,
            'Template not Proposed'
        );

        _self.templates[_id].state = TemplateState.Approved;
        _self.templates[_id].lastUpdatedBy = _sender;
        _self.templates[_id].blockNumberUpdated = block.number;
    }

   /**
    * @notice revoke new template
    * @param _self is the TemplateList storage pointer
    * @param _id approved template contract address
    */
    function revoke(
        TemplateList storage _self,
        address _id,
        address _sender
    )
        internal
    {
        require(
            _self.templates[_id].state == TemplateState.Approved,
            'Template not Approved'
        );

        _self.templates[_id].state = TemplateState.Revoked;
        _self.templates[_id].lastUpdatedBy = _sender;
        _self.templates[_id].blockNumberUpdated = block.number;
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.

// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0


import './TemplateStoreLibrary.sol';
import '../Common.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

/**
 * @title Template Store Manager
 * @author Nevermined
 *
 * @dev Implementation of the Template Store Manager.
 *      Templates are blueprints for modular SEAs. When creating an Agreement, 
 *      a templateId defines the condition and reward types that are instantiated 
 *      in the ConditionStore. This contract manages the life cycle 
 *      of the template ( Propose --> Approve --> Revoke ).
 *      
 */
contract TemplateStoreManager is CommonOwnable {

    using TemplateStoreLibrary for TemplateStoreLibrary.TemplateList;

    TemplateStoreLibrary.TemplateList internal templateList;

    address public nvmConfig;

    modifier onlyOwnerOrTemplateOwner(address _id){
        require(
            _msgSender() == owner() ||
            templateList.templates[_id].owner == _msgSender(),
            'Invalid UpdateRole'
        );
        _;
    }

    /**
     * @dev initialize TemplateStoreManager Initializer
     *      Initializes Ownable. Only on contract creation.
     * @param _owner refers to the owner of the contract
     */
    function initialize(
        address _owner
    )
        public
        initializer()
    {
        require(
            _owner != address(0),
            'Invalid address'
        );

        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
    }

    /**
     * @notice proposeTemplate proposes a new template
     * @param _id unique template identifier which is basically
     *        the template contract address
     */
    function proposeTemplate(address _id)
        external
        returns (uint size)
    {
        return templateList.propose(_id, _msgSender());
    }

    /**
     * @notice approveTemplate approves a template
     * @param _id unique template identifier which is basically
     *        the template contract address. Only template store
     *        manager owner (i.e OPNF) can approve this template.
     */
    function approveTemplate(address _id)
        external
        onlyOwner
    {
        return templateList.approve(_id, _msgSender());
    }

    /**
     * @notice revokeTemplate revoke a template
     * @param _id unique template identifier which is basically
     *        the template contract address. Only template store
     *        manager owner (i.e OPNF) or template owner
     *        can revoke this template.
     */
    function revokeTemplate(address _id)
        external
        onlyOwnerOrTemplateOwner(_id)
    {
        return templateList.revoke(_id, _msgSender());
    }

    /**
     * @notice getTemplate get more information about a template
     * @param _id unique template identifier which is basically
     *        the template contract address.
     * @return state template status
     * @return owner template owner
     * @return lastUpdatedBy last updated by
     * @return blockNumberUpdated last updated at.
     */
    function getTemplate(address _id)
        external
        view
        returns (
            TemplateStoreLibrary.TemplateState state,
            address owner,
            address lastUpdatedBy,
            uint blockNumberUpdated
        )
    {
        state = templateList.templates[_id].state;
        owner = templateList.templates[_id].owner;
        lastUpdatedBy = templateList.templates[_id].lastUpdatedBy;
        blockNumberUpdated = templateList.templates[_id].blockNumberUpdated;
    }

    /**
     * @notice getTemplateListSize number of templates
     * @return size number of templates
     */
    function getTemplateListSize()
        external
        view
        virtual
        returns (uint size)
    {
        return templateList.templateIds.length;
    }

    /**
     * @notice isTemplateApproved check whether the template is approved
     * @param _id unique template identifier which is basically
     *        the template contract address.
     * @return true if the template is approved
     */
    function isTemplateApproved(address _id) external view returns (bool) {
        return templateList.templates[_id].state ==
            TemplateStoreLibrary.TemplateState.Approved;
    }
    
    /**
     * @dev getNvmConfigAddress get the address of the NeverminedConfig contract
     * @return NeverminedConfig contract address
     */
    function getNvmConfigAddress()
    public
    override
    view
    returns (address)
    {
        return nvmConfig;
    }

    function setNvmConfigAddress(address _addr)
    external
    onlyOwner
    {
        nvmConfig = _addr;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '../NFTBase.sol';
import '../../interfaces/IExternalRegistry.sol';

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 */
contract NFT1155Upgradeable is ERC1155Upgradeable, NFTBase {
    
    // Token name
    string public name;

    // Token symbol
    string public symbol;

    IExternalRegistry internal nftRegistry;

    function initialize(
        address owner,
        address didRegistryAddress,
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address nvmConfig_
    )
    public
    virtual
    initializer  
    {
        require(
            owner != address(0) && didRegistryAddress != address(0),
            'Invalid address'
        );
        __NFT1155Upgradeable_init(owner, didRegistryAddress, name_, symbol_, uri_, nvmConfig_);
    }

    // solhint-disable-next-line
    function __NFT1155Upgradeable_init(
        address owner,
        address didRegistryAddress,
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address nvmConfig_
    )
    public
    virtual
    onlyInitializing
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
        __Ownable_init_unchained();
        
        AccessControlUpgradeable.__AccessControl_init();
    __NFT1155Upgradeable_unchained(owner, didRegistryAddress, name_, symbol_, uri_, nvmConfig_);
    }

    // solhint-disable-next-line
    function __NFT1155Upgradeable_unchained(
        address owner,
        address didRegistryAddress,
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address nvmConfig_
    )
    public
    virtual
    onlyInitializing
    {
        AccessControlUpgradeable._setupRole(NVM_OPERATOR_ROLE, _msgSender());
        AccessControlUpgradeable._setupRole(NVM_OPERATOR_ROLE, didRegistryAddress);
        AccessControlUpgradeable._setupRole(NVM_OPERATOR_ROLE, owner);
        setContractMetadataUri(uri_);
        name = name_;
        symbol = symbol_;
        nvmConfig = nvmConfig_;

        nftRegistry = IExternalRegistry(didRegistryAddress);
        if (owner != _msgSender()) {
            transferOwnership(owner);
        }
    }

    function createClone(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _operators
    )
    external
    virtual
    returns (address)
    {
        address implementation = StorageSlotUpgradeable.getAddressSlot(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc).value;
        if (implementation == address(0)) {
            implementation = address(this);
        }
        address cloneAddress = ClonesUpgradeable.clone(implementation);
        NFT1155Upgradeable nftContract = NFT1155Upgradeable(cloneAddress);
        nftContract.initialize(_msgSender(), address(nftRegistry), _name, _symbol, _uri, nvmConfig);
        for (uint256 i = 0; i < _operators.length; i++) {
            nftContract.grantOperatorRole(_operators[i]);
        }
        nftContract.renounceOperatorRole();
        emit NFTCloned(cloneAddress, implementation, 1155);
        return cloneAddress;
    }    
    
    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(account, operator) || isOperator(operator);
    }

    function mint(uint256 id, uint256 amount) public {
        mint(_msgSender(), id, amount, '');
    }
    
    function mint(address to, uint256 id, uint256 amount, bytes memory data) virtual public {
        // Only can mint if:
        require(isOperator(_msgSender()) || // is contract operator  
            to == owner() || // is contract owner
            _msgSender() == nftRegistry.getDIDOwner(bytes32(id)) // is asset owner
            , // Is operator or the NFT owner is _msgSender() 
            'only operator can mint');
        
        require(_nftAttributes[id].nftInitialized, 'NFT not initialized');
        if (_nftAttributes[id].mintCap > 0)    {
            require(_nftAttributes[id].nftSupply + amount <= _nftAttributes[id].mintCap, 'Cap exceeded');
        }
        
        // Update nftSupply
        _nftAttributes[id].nftSupply += amount;
        // Register provenance event
        nftRegistry.used(
            keccak256(abi.encode(id, _msgSender(), 'mint', amount, block.number)),
            bytes32(id), _msgSender(), keccak256('mint'), '', 'mint');
        
        _mint(to, id, amount, data);
    }

    function burn(uint256 id, uint256 amount) virtual public {
        burn(_msgSender(), id, amount); 
    }
    
    function burn(address to, uint256 id, uint256 amount) virtual public {
        require(balanceOf(to, id) >= amount, 'ERC1155: burn amount exceeds balance');
        require(         
            isOperator(_msgSender()) || // Or the DIDRegistry is burning the NFT 
            to == _msgSender() || // Or the NFT owner is _msgSender()
            nftRegistry.isDIDProvider(bytes32(id), _msgSender()) || // Or the DID Provider (Node) is burning the NFT
            isApprovedForAll(to, _msgSender()), // Or the _msgSender() is approved
            'ERC1155: caller is not owner nor approved'
        );

        // Update nftSupply
        _nftAttributes[id].nftSupply -= amount;
        // Register provenance event
        nftRegistry.used(
            keccak256(abi.encode(id, _msgSender(), 'burn', amount, block.number)),
                bytes32(id), _msgSender(), keccak256('burn'), '', 'burn');
        
        _burn(to, id, amount);
    }
    
    function uri(uint256 tokenId) public view override returns (string memory) {
        return _nftAttributes[tokenId].nftURI;
    }

    /**
    * @dev Record some NFT Metadata
    * @param tokenId the id of the asset with the royalties associated
    * @param nftSupply the NFTs supply
    * @param mintCap the max number of editions that can be minted
    * @param nftURI the URI (https, ipfs, etc) to the metadata describing the NFT
    */
    function setNFTAttributes(
        uint256 tokenId,
        uint256 nftSupply,
        uint256 mintCap,    
        string memory nftURI
    )
    public
    {
        require(isOperator(_msgSender()), 'only nft operator');
        _setNFTAttributes(tokenId, nftSupply, mintCap, nftURI);
    }    
    
    /**
    * @dev Record some NFT Metadata
    * @param tokenId the id of the asset with the royalties associated
    * @param nftURI the URI (https, ipfs, etc) to the metadata describing the NFT
    */
    function setNFTMetadata(
        uint256 tokenId,
        string memory nftURI
    )
    public
    {
        require(isOperator(_msgSender()), 'only nft operator');
        _setNFTMetadata(tokenId, nftURI);
    }    
    
    /**
    * @dev Record the asset royalties
    * @param tokenId the id of the asset with the royalties associated
    * @param receiver the receiver of the royalties (the original creator)
    * @param royaltyAmount percentage (no decimals, between 0 and 100)    
    */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 royaltyAmount
    ) 
    public
    {
        require(isOperator(_msgSender()), 'only nft operator');
        _setTokenRoyalty(tokenId, receiver, royaltyAmount);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) 
    public 
    view 
    virtual 
    override(ERC1155Upgradeable, AccessControlUpgradeable, IERC165Upgradeable) 
    returns (bool) 
    {
        return AccessControlUpgradeable.supportsInterface(interfaceId)
        || ERC1155Upgradeable.supportsInterface(interfaceId)
        || interfaceId == type(IERC2981Upgradeable).interfaceId;
    }
    
    function _msgSender() internal override(NFTBase,ContextUpgradeable) virtual view returns (address ret) {
        return Common._msgSender();
    }
    function _msgData() internal override(NFTBase,ContextUpgradeable) virtual view returns (bytes calldata ret) {
        return Common._msgData();
    }

    /**
    * @dev It protects NFT transfers to force going through service agreements and enforce royalties
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    internal
    virtual
    override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(
            from == address(0) || // We exclude mints
            to == address(0) || // We exclude burns
            isOperator(_msgSender()) // Only NFT Contract Operators (Nevermined condition contracts)
            , 'only proxy'
        );
    }

    function nftType() external pure override virtual returns (bytes32) {
        return keccak256('nft1155');
    }
    
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '../NFTBase.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '../../interfaces/IExternalRegistry.sol';

/**
 *
 * @dev Implementation of the basic standard multi-token.
 */
contract NFT721Upgradeable is ERC721Upgradeable, NFTBase {
    
    uint256 private _nftContractCap;

    IExternalRegistry internal nftRegistry;
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _counterMinted;
    
    // solhint-disable-next-line
    function initialize(
        address owner,
        address didRegistryAddress,
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 cap,
        address nvmConfig_
    )
    public
    virtual
    initializer
    {
        __NFT721Upgradeable_init(owner, didRegistryAddress, name, symbol, uri, cap, nvmConfig_);
    }

    // solhint-disable-next-line
    function __NFT721Upgradeable_init(
        address owner,
        address didRegistryAddress,
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 cap,
        address nvmConfig_
    )
    internal
    onlyInitializing
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __Ownable_init_unchained();
        AccessControlUpgradeable.__AccessControl_init();
        __NFT721Upgradeable_unchained(owner, didRegistryAddress, uri, cap, nvmConfig_);
    }

    // solhint-disable-next-line
    function __NFT721Upgradeable_unchained(
        address owner,
        address didRegistryAddress,
        string memory uri,
        uint256 cap,
        address nvmConfig_
    )
    internal
    onlyInitializing
    {
        AccessControlUpgradeable._setupRole(NVM_OPERATOR_ROLE, _msgSender());
        AccessControlUpgradeable._setupRole(NVM_OPERATOR_ROLE, didRegistryAddress);
        AccessControlUpgradeable._setupRole(NVM_OPERATOR_ROLE, owner);
        setContractMetadataUri(uri);
        _nftContractCap = cap;
        nvmConfig = nvmConfig_;

        nftRegistry = IExternalRegistry(didRegistryAddress);
        if (owner != _msgSender()) {
            transferOwnership(owner);
        }
    }

    function createClone(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256 cap,
        address[] memory _operators
    )
    external
    virtual
    returns (address)
    {
        address implementation = StorageSlotUpgradeable.getAddressSlot(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc).value;
        if (implementation == address(0)) {
            implementation = address(this);
        }        
        address cloneAddress = ClonesUpgradeable.clone(implementation);
        NFT721Upgradeable nftContract = NFT721Upgradeable(cloneAddress);
        nftContract.initialize(_msgSender(), address(nftRegistry), name, symbol, uri, cap, nvmConfig);
        for (uint256 i = 0; i < _operators.length; i++) {
            nftContract.grantOperatorRole(_operators[i]);
        }
        nftContract.renounceOperatorRole();
        emit NFTCloned(cloneAddress, implementation, 721);
        return cloneAddress;
    }
    
    function isApprovedForAll(
        address account, 
        address operator
    ) 
    public 
    view 
    virtual 
    override
    returns (bool) 
    {
        return super.isApprovedForAll(account, operator) || isOperator(operator);
    }
    
    function mint(
        address to,
        uint256 tokenId
    )
    public
    virtual
    {
        require(isOperator(_msgSender()) || to == owner(), 'only nft operator can mint');
        require(_nftContractCap == 0 || _counterMinted.current() < _nftContractCap,
            'ERC721: Cap exceed'
        );
        
        // Update nftSupply
        _counterMinted.increment();
        // the supply will just become the number of minted even if something was burned before?
        _nftAttributes[tokenId].nftSupply = _counterMinted.current();
        _nftAttributes[tokenId].nftURI = '';
        
        // Register provenance event
        nftRegistry.used(
            keccak256(abi.encode(tokenId, _msgSender(), 'mint', 1, block.number)),
            bytes32(tokenId), _msgSender(), keccak256('mint'), '', 'mint');
        
        _mint(to, tokenId);
    }

    function mint(
        uint256 tokenId
    )
    public
    virtual
    {
        return mint(_msgSender(), tokenId);
    }    
    
    function getHowManyMinted()
    public
    view
    returns (uint256)
    {
        return _counterMinted.current();
    }
    
    /**
    * @dev Burning tokens does not decrement the counter of tokens minted!
    *      This is by design.
    */
    function burn(
        uint256 tokenId
    ) 
    virtual
    public 
    {
        require(
            isOperator(_msgSender()) || // The DIDRegistry is burning the NFT 
            ownerOf(tokenId) == _msgSender(), // Or the _msgSender() is owner of the tokenId
            'ERC721: caller is not owner or not have balance'
        );
        // Update nftSupply
        _nftAttributes[tokenId].nftSupply -= 1;
        // Register provenance event
        nftRegistry.used(
            keccak256(abi.encode(tokenId, _msgSender(), 'burn', 1, block.number)),
                bytes32(tokenId), _msgSender(), keccak256('burn'), '', 'burn');
        
        _burn(tokenId);
    }

    function _baseURI() 
    internal 
    view 
    override
    virtual
    returns (string memory) 
    {
        return contractURI();
    }
    
    /**
    * @dev Record some NFT Metadata
    * @param tokenId the id of the asset with the royalties associated
    * @param nftURI the URI (https, ipfs, etc) to the metadata describing the NFT
    */
    function setNFTMetadata(
        uint256 tokenId,
        string memory nftURI
    )
    public
    {
        require(isOperator(_msgSender()), 'only nft operator');
        _setNFTMetadata(tokenId, nftURI);
    }

    function tokenURI(
        uint256 tokenId
    ) 
    public 
    view 
    virtual 
    override (ERC721Upgradeable)
    returns (string memory) 
    {
        string memory baseURI = _baseURI();
        if (_exists(tokenId))
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toHexString())) : '';
        else
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : '';        
    }    
    
    /**
    * @dev Record the asset royalties
    * @param tokenId the id of the asset with the royalties associated
    * @param receiver the receiver of the royalties (the original creator)
    * @param royaltyAmount percentage (no decimals, between 0 and 100)    
    */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 royaltyAmount
    )
    public
    {
        require(isOperator(_msgSender()), 'only nft operator');
        _setTokenRoyalty(tokenId, receiver, royaltyAmount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) 
    public 
    view 
    virtual 
    override(ERC721Upgradeable, AccessControlUpgradeable, IERC165Upgradeable) 
    returns (bool) 
    {
        return AccessControlUpgradeable.supportsInterface(interfaceId)
        || ERC721Upgradeable.supportsInterface(interfaceId)
        || interfaceId == type(IERC2981Upgradeable).interfaceId;
    }
    
    function _msgSender() internal override(NFTBase,ContextUpgradeable) virtual view returns (address ret) {
        return Common._msgSender();
    }
    function _msgData() internal override(NFTBase,ContextUpgradeable) virtual view returns (bytes calldata ret) {
        return Common._msgData();
    }
    
    /**
    * @dev It protects NFT transfers to force going through service agreements and enforce royalties
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) 
    internal 
    virtual 
    override 
    {
        require(
            from == address(0) || // We exclude mints
            to == address(0) || // We exclude burns
            isOperator(_msgSender()) // Only NFT Contract Operators (Nevermined condition contracts)
        , 'only proxy'
        );
        super._beforeTokenTransfer(from, to, 0, batchSize);
    }

    function nftType() external pure override virtual returns (bytes32) {
        return keccak256('nft721');
    }
}

pragma solidity ^0.8.0;
// Copyright 2022 Nevermined AG.
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

import '../Common.sol';
import '../governance/NeverminedConfig.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol';

/**
 * @title Nevermined NFT Base
 * @author Nevermined
 *
 * It provides base functionality for all the Nevermined NFT implementations (ERC-1155 or ERC-721).
 * 
 * Nevermined NFT permissions are organized in different levels:
 *
 * 1. At the top level the NFT contracts are 'Ownable' so the owner (typically the deployer) of the contract
 *    can manage totally the NFT contract.
 * 2. At the second level we have the NFT contract operator role. The accounts having that role can do some
 *    operations like mint/burn/transfer. Typically this role is granted to some Nevermined contracts to 
 *    automate the execution of common functions, like the interaction with the service agreements.
 *    This role is managed using the  `grantOperatorRole` and `revokeOperatorRole` function
 * 3. At the bottom level the token/edition owners can provide some permissions to token/editions holders 
 *    via `setApprovalForAll`
 *   
 * @dev Implementation of the Royalties EIP-2981 base contract
 * See https://eips.ethereum.org/EIPS/eip-2981
 */
abstract contract NFTBase is IERC2981Upgradeable, CommonOwnable, AccessControlUpgradeable {

    // Role to operate the NFT contract
    bytes32 public constant NVM_OPERATOR_ROLE = keccak256('NVM_OPERATOR_ROLE');
    
    struct RoyaltyInfo {
        address receiver;
        uint256 royaltyAmount;
    }
    
    struct NFTAttributes {
        // Flag to control if NFTs config was already initialized
        bool nftInitialized;
        // The NFTs supply associated to the DID 
        uint256 nftSupply;
        // The max number of NFTs associated to the DID that can be minted 
        uint256 mintCap;
        // URL to NFT metadata        
        string nftURI;
    }
    
    // Mapping of Royalties per asset (DID)
    mapping(uint256 => RoyaltyInfo) internal _royalties;
    // Mapping of NFT Attributes object per tokenId
    mapping(uint256 => NFTAttributes) internal _nftAttributes;

    // @dev: Variable out of date. Kept because upgradeability
    // @dev: Use `_expirationBlock` mapping instead
    mapping(address => uint256) internal _expiration; // UNUSED 

    // Used as a URL where is stored the Metadata describing the NFT contract
    string private _contractMetadataUri;

    address public nvmConfig;
    
    event NFTCloned(
        address indexed _newAddress,
        address indexed _fromAddress,
        uint _ercType
    );

    modifier onlyOperatorOrOwner
    {
        require(
            owner() == _msgSender() || isOperator(_msgSender()),
            'Only operator or owner'
        );
        _;
    }

    /**
     * @dev getNvmConfigAddress get the address of the NeverminedConfig contract
     * @return NeverminedConfig contract address
     */
    function getNvmConfigAddress()
    public
    override
    view
    returns (address)
    {
        return nvmConfig;
    }

    function setNvmConfigAddress(address _addr)
    external
    onlyOwner
    {
        nvmConfig = _addr;
    }

    function _setNFTAttributes(
        uint256 tokenId,
        uint256 nftSupply,
        uint256 mintCap,
        string memory tokenURI
    )
    internal
    {
        _nftAttributes[tokenId].nftInitialized = true;
        _nftAttributes[tokenId].nftSupply = nftSupply;
        _nftAttributes[tokenId].mintCap = mintCap;
        _nftAttributes[tokenId].nftURI = tokenURI;
    }
    
    function _setNFTMetadata(
        uint256 tokenId,
        string memory tokenURI
    )
    internal
    {
        _nftAttributes[tokenId].nftInitialized = true;
        _nftAttributes[tokenId].nftURI = tokenURI;
    }

    function getNFTAttributes(
        uint256 tokenId
    )
    external
    view
    virtual
    returns (bool nftInitialized, uint256 nftSupply, uint256 mintCap, string memory nftURI)
    {
        NFTAttributes memory attributes = _nftAttributes[tokenId];
        nftInitialized = attributes.nftInitialized;
        nftSupply = attributes.nftSupply;
        mintCap = attributes.mintCap;
        nftURI = attributes.nftURI;
    }    
    
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint256 royaltyAmount
    )
    internal
    {
        require(royaltyAmount <= 1000000, 'ERC2981Royalties: Too high');
        _royalties[tokenId] = RoyaltyInfo(receiver, royaltyAmount);
    }    
    
    /**
     * @inheritdoc	IERC2981Upgradeable
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 value
    )
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.receiver;
        royaltyAmount = (value * royalties.royaltyAmount) / 100;
    }

    /**
    * @dev Record the URI storing the Metadata describing the NFT Contract
    *      More information about the file format here: 
    *      https://docs.opensea.io/docs/contract-level-metadata
    * @param _uri the URI (https, ipfs, etc) to the metadata describing the NFT Contract    
    */    
    function setContractMetadataUri(
        string memory _uri
    )
    public
    onlyOperatorOrOwner
    virtual
    {
        _contractMetadataUri = _uri;
    }
    
    function contractURI()
    public
    view
    returns (string memory) {
        return _contractMetadataUri;
    }

    function grantOperatorRole(
        address account
    )
    public
    virtual
    onlyOperatorOrOwner
    {
        AccessControlUpgradeable._setupRole(NVM_OPERATOR_ROLE, account);
    }

    function revokeOperatorRole(
        address account
    )
    public
    virtual
    onlyOperatorOrOwner
    {
        AccessControlUpgradeable._revokeRole(NVM_OPERATOR_ROLE, account);
    }

    function renounceOperatorRole()
    public
    virtual
    {
        AccessControlUpgradeable._revokeRole(NVM_OPERATOR_ROLE, _msgSender());
    }

    function isOperator(
        address operator
    )
    public
    view
    virtual
    returns (bool)
    {
        if (nvmConfig == address(0)) {
            return AccessControlUpgradeable.hasRole(NVM_OPERATOR_ROLE, operator);
        }
        return NeverminedConfig(nvmConfig).hasNVMOperatorRole(operator) || AccessControlUpgradeable.hasRole(NVM_OPERATOR_ROLE, operator);
    }

    function _msgSender() internal override(CommonOwnable,ContextUpgradeable) virtual view returns (address ret) {
        return Common._msgSender();
    }
    function _msgData() internal override(CommonOwnable,ContextUpgradeable) virtual view returns (bytes calldata ret) {
        return Common._msgData();
    }

    function nftType() external pure virtual returns (bytes32) {
        return keccak256('');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}