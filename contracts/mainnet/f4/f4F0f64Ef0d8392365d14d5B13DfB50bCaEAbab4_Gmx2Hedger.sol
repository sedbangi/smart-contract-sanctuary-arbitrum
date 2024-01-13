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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IOrderHandler, MarketUtils, Price, Market, IReferralStorage, IMarketToken, ISwapHandler, IOrderVault, IGmxOracle, IEventEmitter, BaseOrderUtils, PositionUtils, IGmxUtils, Order, IOrderUtils, IDataStore, IReader, IExchangeRouter, Position, EventUtils, IOrderCallbackReceiver} from "../../interfaces/IGmx2.sol";
import "../../interfaces/IHedgedPool.sol";
import "../../interfaces/IHedger.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title GMX v2 protocol perpetual hedger
/// @notice Hedges pool delta by trading perpetual contracts on GMX v2

contract Gmx2Hedger is IHedger, IOrderCallbackReceiver, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Price for Price.Props;
    using Position for Position.Props;

    event HedgeUpdated(int256 oldDelta, int256 newDelta);

    event Synced(int256 collateralDiff);

    // Gmx uses 30 decimals precision
    uint256 private constant Gmx_DECIMALS = 30;

    uint256 private constant SIREN_DECIMALS = 8;

    uint256 private constant ORDER_GAS_LIMIT = 7e6;

    uint256 private constant ACCEPTABLE_PRICE_THRESHOLD = 10;

    // Siren HedgedPool that will be our account for this contract
    address public hedgedPool;

    //ExchangeRouter what we use to execute orders
    address public exchangeRouter;

    address public orderVault;

    address public dataStore;

    address public reader;

    //Market that our long token is based on ie weth, wbtc, ect
    address public market;

    address public gmxOralce;

    uint256 public leverage;

    IERC20 collateralToken;

    uint256 public collateralDecimals;

    address public gmxUtils;

    uint256 public underlyingDecimals;

    int256 private deltaCached;

    Market.Props public marketProps;

    mapping(bytes32 => bool) public pendingOrders;

    uint256 public pendingOrdersCount;

    event GmxOrderCanceled(bytes32 key);

    event GmxOrderExecuted(bytes32 key);

    event GmxIncreaseOrderCreated(bytes32 key, bool isLong);

    event GmxDecreaseOrderCreated(bytes32 key, bool isLong);

    event GmxDepositOrderCreated(bytes32 key, bool isLong);

    event GmxWithdrawlOrderCreated(bytes32 key, bool isLong);

    event HedgerInitalized(
        address hedger,
        address indexToken,
        address longToken,
        address shortToken
    );

    BaseOrderUtils.ExecuteOrderParamsContracts executOrderParamContracts;

    modifier onlyAuthorized() {
        require(
            msg.sender == hedgedPool ||
                IHedgedPool(hedgedPool).keepers(msg.sender) ||
                msg.sender == owner(),
            "!authorized"
        );
        _;
    }

    modifier noPendingOrders() {
        require(pendingOrdersCount == 0, "Orders pending");
        _;
    }

    //Take the gmx price and compare the min and max
    // work on script to get the prices
    function __Gmx2Hedger_init(
        address _hedgedPool,
        address _exchangeRouter,
        address _reader,
        address _market,
        address _gmxUtils,
        uint256 _leverage
    ) external initializer {
        market = _market;
        _updateConfig(_exchangeRouter, _reader, _gmxUtils, _leverage);

        underlyingDecimals = IMarketToken(market).decimals();

        hedgedPool = _hedgedPool;
        collateralToken = IHedgedPool(hedgedPool).collateralToken();
        collateralDecimals = IERC20MetadataUpgradeable(address(collateralToken))
            .decimals();

        emit HedgerInitalized(
            address(this),
            marketProps.indexToken,
            marketProps.longToken,
            marketProps.shortToken
        );

        __Ownable_init();
    }

    function hedgerType() external pure returns (string memory) {
        return "GMX2";
    }

    /// @notice Update hedger configuration
    function updateConfig(
        address _exchangeRouter,
        address _reader,
        address _gmxUtils,
        uint256 _leverage
    ) external onlyOwner {
        _updateConfig(_exchangeRouter, _reader, _gmxUtils, _leverage);
    }

    receive() external payable {}

    function _updateConfig(
        address _exchangeRouter,
        address _reader,
        address _gmxUtils,
        uint256 _leverage
    ) private {
        leverage = _leverage;
        reader = _reader;
        exchangeRouter = _exchangeRouter;
        IOrderHandler orderHandler = IOrderHandler(
            IExchangeRouter(_exchangeRouter).orderHandler()
        );
        dataStore = address(IExchangeRouter(exchangeRouter).dataStore());

        (
            address marketToken,
            address indexToken,
            address longToken,
            address shortToken
        ) = IReader(reader).getMarket(dataStore, market);

        marketProps = Market.Props(
            marketToken,
            indexToken,
            longToken,
            shortToken
        );

        orderVault = address(orderHandler.orderVault());
        gmxOralce = address(orderHandler.oracle());
        ISwapHandler swapHandler = orderHandler.swapHandler();
        IReferralStorage referralStorage = orderHandler.referralStorage();
        gmxUtils = _gmxUtils;

        executOrderParamContracts = BaseOrderUtils.ExecuteOrderParamsContracts(
            IDataStore(dataStore),
            IEventEmitter(IExchangeRouter(exchangeRouter).eventEmitter()),
            IOrderVault(orderVault),
            IGmxOracle(gmxOralce),
            swapHandler,
            referralStorage
        );
    }

    function afterOrderExecution(
        bytes32 key,
        Order.Props memory /* order */,
        EventUtils.EventLogData memory /* eventData */
    ) external {
        require(
            address(msg.sender) ==
                address(IExchangeRouter(exchangeRouter).orderHandler()),
            "!orderHandler"
        );
        require(pendingOrders[key] == true, "!order key");
        pendingOrders[key] = false;
        pendingOrdersCount = pendingOrdersCount - 1;

        if (pendingOrdersCount == 0) {
            _syncDelta();
        }

        //Maybe here and on cancle order we want to get information form the order
        emit GmxOrderExecuted(key);
    }

    function afterOrderCancellation(
        bytes32 key,
        Order.Props memory /* order */,
        EventUtils.EventLogData memory /* eventData */
    ) external {
        require(
            address(msg.sender) ==
                address(IExchangeRouter(exchangeRouter).orderHandler()),
            "!orderHandler"
        );
        require(pendingOrders[key] == true, "!order key");
        pendingOrders[key] = false;
        pendingOrdersCount = pendingOrdersCount - 1;

        collateralToken.safeTransfer(
            hedgedPool,
            collateralToken.balanceOf(address(this))
        );

        if (pendingOrdersCount == 0) {
            _syncDelta();
        }

        emit GmxOrderCanceled(key);
    }

    function afterOrderFrozen(
        bytes32 /* key */,
        Order.Props memory /* order */,
        EventUtils.EventLogData memory /* eventData */
    ) external {
        // We only use market orders which cannot be frozen they will instead be canceled
        // Reference for this in Gmx
        // https://github.com/gmx-io/gmx-synthetics/blob/77a2ff39f1414a105e8589d622bdb09ac3dd97d8/contracts/exchange/OrderHandler.sol#L232
    }

    // /// @notice Set maintenance buffer in percent (200 means 2x maintenance required by product)
    // function setMaintenanceBuffer(
    //     uint256 _maintenanceBuffer
    // ) external onlyOwner {
    //     maintenanceBuffer = _maintenanceBuffer;
    // }

    /// @notice Adjust perpetual position in order to hedge given delta exposure
    /// @param targetDelta Target delta of the hedge (1e8)
    /// @param indexTokenPrice minPrice from Gmx oracle multiplied by oracle decimals
    /// @param longTokenPrice minPrice from Gmx oracle multiplied by oracle decimals
    /// @return deltaDiff difference between the new delta and the old delta
    function hedge(
        int256 targetDelta,
        uint256 indexTokenPrice,
        uint256 longTokenPrice
    ) external payable onlyAuthorized returns (int256 deltaDiff) {
        MarketUtils.MarketPrices memory prices = MarketUtils.MarketPrices(
            Price.Props(indexTokenPrice, indexTokenPrice),
            Price.Props(longTokenPrice, longTokenPrice),
            Price.Props(
                IGmxOracle(gmxOralce).getStablePrice(
                    dataStore,
                    address(collateralToken)
                ),
                IGmxOracle(gmxOralce).getStablePrice(
                    dataStore,
                    address(collateralToken)
                )
            )
        );

        _syncDelta();

        deltaDiff = targetDelta - deltaCached;

        // calculate changes in long and short
        uint currentLong;
        uint currentShort;
        uint targetLong;
        uint targetShort;

        if (targetDelta >= 0) {
            targetLong = uint256(targetDelta);

            // need long hedge
            if (deltaCached >= 0) {
                currentLong = uint256(deltaCached);
            } else {
                currentShort = uint256(-deltaCached);
            }
        } else if (targetDelta < 0) {
            targetShort = uint256(-targetDelta);

            // need short hedge
            if (deltaCached <= 0) {
                currentShort = uint256(-deltaCached);
            } else {
                currentLong = uint256(deltaCached);
            }
        }

        _changePosition(
            currentLong,
            targetLong,
            currentShort,
            targetShort,
            prices
        );

        emit HedgeUpdated(deltaCached, targetDelta);

        deltaCached = targetDelta;

        return deltaDiff;
    }

    function sync() external onlyAuthorized returns (int256 collateralDiff) {
        collateralDiff = _sync();
        return collateralDiff;
    }

    function getDelta() external view returns (int256) {
        return deltaCached;
    }

    function getCollateralValue() external view returns (uint256) {
        MarketUtils.MarketPrices memory prices = _getMarketPrices();
        uint256 collateralValue;

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;

            // TODO: handle edge case where position value is below zero
            collateralValue += uint256(
                int256(position.collateralAmount()) +
                    _getPositinPnlCollateral(position, prices)
            );
        }

        return collateralValue;
    }

    /// @notice Get required collateral
    /// @return collateral shortfall (positive) or excess (negative)
    function getRequiredCollateral() external view returns (int256) {
        int256 requiredCollateral;

        MarketUtils.MarketPrices memory prices = _getMarketPrices();
        uint256 indexTokenPrice = prices.indexTokenPrice.min;

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;

            int256 marginCurrent = int256(position.collateralAmount()) +
                _getPositinPnlCollateral(position, prices);
            uint256 marginRequired = _getMarginRequired(
                position.sizeInTokens(),
                indexTokenPrice
            );

            requiredCollateral += int256(marginRequired) - marginCurrent;
        }

        return requiredCollateral;
    }

    /// @notice Withdraw excess collateral or deposit more
    /// @return collateralDiff deposit (positive) or withdrawal (negative) amount
    function _sync() internal returns (int collateralDiff) {
        // sync delta
        _syncDelta();

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        MarketUtils.MarketPrices memory prices = _getMarketPrices();
        uint256 indexTokenPrice = prices.indexTokenPrice.min;

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;
            int256 marginCurrent;

            marginCurrent =
                int256(position.collateralAmount()) +
                _getPositinPnlCollateral(position, prices);

            uint256 marginRequired = _getMarginRequired(
                position.sizeInTokens(),
                indexTokenPrice
            );

            if (int256(marginRequired) > marginCurrent) {
                uint256 acceptablePrice = _getAcceptablePrice(
                    indexTokenPrice,
                    true,
                    isLong
                );

                // deposit
                uint256 depositAmount = uint256(
                    int256(marginRequired) - marginCurrent
                );
                _depositCollateral(isLong, depositAmount, acceptablePrice);
                collateralDiff += int256(depositAmount);
            } else if (int256(marginRequired) < marginCurrent) {
                uint256 acceptablePrice = _getAcceptablePrice(
                    indexTokenPrice,
                    false,
                    isLong
                );

                // withdraw
                uint256 withdrawAmount = uint256(marginCurrent) -
                    marginRequired;
                _withdrawCollateral(isLong, withdrawAmount, acceptablePrice);
                collateralDiff -= int256(withdrawAmount);
            }
        }

        emit Synced(collateralDiff);

        return collateralDiff;
    }

    /// @notice sync cached delta value
    function _syncDelta() internal noPendingOrders {
        int256 totalSizeInTokens;

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;

            uint256 sizeInTokens = position.sizeInTokens();
            require(
                sizeInTokens == 0 || totalSizeInTokens == 0,
                "two non-zero positions"
            );

            totalSizeInTokens += isLong
                ? int256(sizeInTokens)
                : -int256(sizeInTokens);
        }

        deltaCached =
            (totalSizeInTokens * int256(10 ** SIREN_DECIMALS)) /
            int256(10 ** underlyingDecimals);
    }

    function _getPositionInformation()
        internal
        view
        returns (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        )
    {
        Position.Props[] memory allPositions = IReader(reader)
            .getAccountPositions(IDataStore(dataStore), address(this), 0, 2);
        for (uint256 i; i < allPositions.length; i++) {
            if (allPositions[i].flags.isLong == true) {
                longPosition = allPositions[i];
            } else {
                shortPosition = allPositions[i];
            }
        }

        if (longPosition.addresses.account == address(0)) {
            longPosition.flags.isLong = true;
            longPosition.addresses.account = address(this);
            longPosition.addresses.market = market;
            longPosition.addresses.collateralToken = address(collateralToken);
        }

        if (shortPosition.addresses.account == address(0)) {
            shortPosition.addresses.account = address(this);
            shortPosition.addresses.market = market;
            shortPosition.addresses.collateralToken = address(collateralToken);
        }

        return (longPosition, shortPosition);
    }

    function _getPositinPnlCollateral(
        Position.Props memory position,
        MarketUtils.MarketPrices memory prices
    ) internal view returns (int256) {
        if (position.sizeInTokens() == 0) {
            return 0;
        }
        bytes32 key = _getPositionKey(position.isLong());

        (int256 positionPnlUsd, , ) = IReader(reader).getPositionPnlUsd(
            IDataStore(dataStore),
            marketProps,
            prices,
            key,
            0
        );

        // convert to collateral
        positionPnlUsd =
            positionPnlUsd /
            int256((10 ** (Gmx_DECIMALS - collateralDecimals)));

        return (positionPnlUsd);
    }

    //Internal Helper Functions

    //Do we need this or can we just set this in the init function
    function _createOrderParamAddresses()
        internal
        view
        returns (IOrderUtils.CreateOrderParamsAddresses memory)
    {
        //SwapPath for this I think should always be usdc->collateralToken if thats the case we can set this in init
        address[] memory swapPath;
        return
            IOrderUtils.CreateOrderParamsAddresses(
                address(hedgedPool),
                address(this),
                address(this),
                market,
                address(collateralToken),
                swapPath
            );
    }

    function _orderParamAddresses()
        internal
        view
        returns (Order.Addresses memory)
    {
        address[] memory swapPath;
        return
            Order.Addresses(
                address(this),
                address(this),
                address(this),
                address(this),
                market,
                address(collateralToken),
                swapPath
            );
    }

    function _createOrderParamNumbers(
        uint256 sizeDeltaUSD,
        uint256 initialCollateralDeltaAmount,
        uint256 minOutputAmount,
        uint256 acceptablePrice,
        uint256 executionFee
    ) internal pure returns (IOrderUtils.CreateOrderParamsNumbers memory) {
        return
            IOrderUtils.CreateOrderParamsNumbers(
                sizeDeltaUSD,
                initialCollateralDeltaAmount,
                0,
                acceptablePrice,
                executionFee,
                300000, // callback gas limit
                minOutputAmount
            );
    }

    function _orderParamNumbers(
        uint256 sizeDeltaUSD,
        uint256 initialCollateralDeltaAmount,
        uint256 minOutputAmount,
        uint256 acceptablePrice,
        Order.OrderType orderType
    ) internal view returns (Order.Numbers memory) {
        uint256 executionFee = _calculateExecutionFee();

        return
            Order.Numbers(
                orderType,
                Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
                sizeDeltaUSD,
                initialCollateralDeltaAmount,
                0,
                acceptablePrice,
                executionFee,
                0,
                minOutputAmount,
                block.number
            );
    }

    function _createMarketOrder(
        IOrderUtils.CreateOrderParamsAddresses memory createOrderParamAddresses,
        IOrderUtils.CreateOrderParamsNumbers memory createOrderParamNumbers,
        Order.OrderType orderType,
        Order.DecreasePositionSwapType decreasePositionSwap,
        bool isLong,
        bool shouldUnwrapNativeToken,
        bytes32 referralCode
    ) internal returns (bytes32) {
        bytes32 key = IExchangeRouter(exchangeRouter).createOrder(
            IOrderUtils.CreateOrderParams(
                createOrderParamAddresses,
                createOrderParamNumbers,
                orderType,
                decreasePositionSwap,
                isLong,
                shouldUnwrapNativeToken,
                referralCode
            )
        );
        return key;
    }

    function _sendCollateral(uint256 collateralAmount) internal {
        if (collateralAmount == 0) return;

        collateralToken.safeTransferFrom(
            hedgedPool,
            address(this),
            collateralAmount
        );
        IERC20(address(collateralToken)).approve(
            IExchangeRouter(exchangeRouter).router(),
            collateralAmount
        );
        IExchangeRouter(exchangeRouter).sendTokens(
            address(collateralToken),
            orderVault,
            collateralAmount
        );
    }

    struct ChangePositionVars {
        Position.Props longPosition;
        Position.Props shortPosition;
    }

    function _changePosition(
        uint256 currentLong,
        uint256 targetLong,
        uint256 currentShort,
        uint256 targetShort,
        MarketUtils.MarketPrices memory prices
    ) internal {
        ChangePositionVars memory vars;

        (vars.longPosition, vars.shortPosition) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            uint256 currentPos = isLong ? currentLong : currentShort;
            uint256 targetPos = isLong ? targetLong : targetShort;

            if (targetPos == currentPos) continue;

            uint256 price = prices.indexTokenPrice.pickPrice(isLong);

            uint256 acceptablePrice = _getAcceptablePrice(
                price,
                targetPos > currentPos,
                isLong
            );

            Position.Props memory position = isLong
                ? vars.longPosition
                : vars.shortPosition;
            int256 marginCurrent;

            marginCurrent =
                int256(position.collateralAmount()) +
                _getPositinPnlCollateral(position, prices);

            uint256 marginRequired = _getMarginRequired(
                (targetPos * (10 ** underlyingDecimals)) /
                    (10 ** SIREN_DECIMALS),
                price
            );

            if (targetPos > currentPos) {
                // increase position

                //First get the sizeInTokens of the position
                uint256 initialCollateralDelta;
                if (marginRequired > uint256(marginCurrent)) {
                    initialCollateralDelta = uint256(
                        marginRequired - uint256(marginCurrent)
                    );
                }

                uint256 sizeDeltaUsd = ((targetPos - currentPos) *
                    price *
                    (10 ** underlyingDecimals)) / (10 ** SIREN_DECIMALS);

                //Adjust for slippage
                uint256 executionPrice = _calculateAdjustedExecutionPrice(
                    position,
                    prices,
                    isLong,
                    sizeDeltaUsd,
                    initialCollateralDelta,
                    acceptablePrice,
                    Order.OrderType.MarketIncrease
                );

                sizeDeltaUsd =
                    ((targetPos - currentPos) *
                        executionPrice *
                        (10 ** underlyingDecimals)) /
                    (10 ** SIREN_DECIMALS);

                _gmxPositionIncrease(
                    isLong,
                    sizeDeltaUsd,
                    initialCollateralDelta,
                    acceptablePrice,
                    _calculateExecutionFee()
                );
            } else if (targetPos < currentPos) {
                // decrease position
                uint256 initialCollateralDelta;
                if (marginRequired < uint256(marginCurrent)) {
                    initialCollateralDelta =
                        uint256(marginCurrent) -
                        marginRequired;
                }

                uint256 sizeDeltaUsd = (position.sizeInUsd() *
                    (currentPos - targetPos)) / currentPos;

                _gmxPositionDecrease(
                    isLong,
                    sizeDeltaUsd,
                    initialCollateralDelta,
                    acceptablePrice,
                    _calculateExecutionFee()
                );
            }
        }
    }

    /// @notice Deposit collateral to a product
    function _depositCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        if (amount == 0) return;

        uint256 poolBalance = IHedgedPool(hedgedPool).getCollateralBalance();
        if (amount > poolBalance) {
            // pool doesn't have enough collateral, move all we can
            amount = poolBalance;
        }

        _gmxDepositCollateral(isLong, amount, acceptablePrice);
    }

    /// @notice Withdraw collateral from a product
    /// @dev It withdraws directly to the hedged pool
    function _withdrawCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        if (amount == 0) return;

        _gmxWithdrawCollateral(isLong, amount, acceptablePrice);
    }

    function _gmxPositionIncrease(
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 initialCollateralDelta,
        uint256 acceptablePrice,
        uint256 executionFee
    ) internal {
        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUsd,
                initialCollateralDelta,
                0,
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );
        _sendCollateral(initialCollateralDelta);

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketIncrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false,
            0
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxIncreaseOrderCreated(key, isLong);
    }

    function _gmxPositionDecrease(
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 initialCollateralDelta,
        uint256 acceptablePrice,
        uint256 executionFee
    ) internal {
        uint256 minOutputAmount = 0;
        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUsd,
                initialCollateralDelta,
                minOutputAmount,
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketDecrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false,
            0
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxDecreaseOrderCreated(key, isLong);
    }

    function _gmxDepositCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        uint256 sizeDeltaUSD = 0;
        uint256 initialCollateralDeltaAmount = 0;
        uint256 minOutputAmount = 0;

        uint256 executionFee = _calculateExecutionFee();

        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUSD,
                initialCollateralDeltaAmount,
                minOutputAmount,
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );
        _sendCollateral(amount);

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketIncrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false,
            0
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxDepositOrderCreated(key, isLong);
    }

    function _gmxWithdrawCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        uint256 executionFee = _calculateExecutionFee();

        uint256 minOutputAmount = 0;
        uint256 sizeDeltaUSD = 0;
        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUSD,
                amount,
                minOutputAmount, // have to find a way to calcualte the minOutputAmount
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketDecrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false,
            0
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxWithdrawlOrderCreated(key, isLong);
    }

    function _calculateAdjustedExecutionPrice(
        Position.Props memory position,
        MarketUtils.MarketPrices memory prices,
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 initialCollateralDelta,
        uint256 acceptablePrice,
        Order.OrderType orderType
    ) internal view returns (uint256) {
        PositionUtils.UpdatePositionParams
            memory updateOrderParams = PositionUtils.UpdatePositionParams(
                executOrderParamContracts,
                marketProps,
                Order.Props(
                    _orderParamAddresses(),
                    _orderParamNumbers(
                        sizeDeltaUsd,
                        initialCollateralDelta,
                        0,
                        acceptablePrice,
                        orderType
                    ),
                    Order.Flags(isLong, false, false)
                ),
                bytes32(0),
                position,
                bytes32(0),
                Order.SecondaryOrderType.None
            );

        (, , , uint256 executionPrice) = IGmxUtils(gmxUtils).getExecutionPrice(
            updateOrderParams,
            prices.indexTokenPrice
        );

        return executionPrice;
    }

    function _getPositionKey(bool isLong) internal view returns (bytes32) {
        bytes32 key = keccak256(
            abi.encode(address(this), market, collateralToken, isLong)
        );
        return key;
    }

    function _getMarginRequired(
        uint256 size, // in underlyingDecimals
        uint256 price
    ) internal view returns (uint256) {
        return
            (size * price) /
            leverage /
            (10 ** (Gmx_DECIMALS - collateralDecimals));
    }

    // increase order:
    //     - long: executionPrice should be smaller than acceptablePrice
    //     - short: executionPrice should be larger than acceptablePrice

    // decrease order:
    //     - long: executionPrice should be larger than acceptablePrice
    //     - short: executionPrice should be smaller than acceptablePrice
    function _getAcceptablePrice(
        uint256 price,
        bool isIncrease,
        bool isLong
    ) internal pure returns (uint256) {
        uint256 priceDiff = (price * ACCEPTABLE_PRICE_THRESHOLD) / 100;
        if (isIncrease) {
            if (isLong) {
                return price + priceDiff;
            } else {
                return price - priceDiff;
            }
        } else {
            if (isLong) {
                return price - priceDiff;
            } else {
                return price + priceDiff;
            }
        }
    }

    function _getMarketPrices()
        internal
        view
        returns (MarketUtils.MarketPrices memory)
    {
        uint256 indexTokenPrice;
        uint256 longTokenPrice;
        uint256 shortTokenPrice;
        bool hasPrice;
        (hasPrice, indexTokenPrice) = IGmxUtils(gmxUtils).getPriceFeedPrice(
            dataStore,
            marketProps.indexToken
        );
        require(hasPrice, "!indexTokenPrice");

        (hasPrice, longTokenPrice) = IGmxUtils(gmxUtils).getPriceFeedPrice(
            dataStore,
            marketProps.longToken
        );
        require(hasPrice, "!longTokenPrice");

        (hasPrice, shortTokenPrice) = IGmxUtils(gmxUtils).getPriceFeedPrice(
            dataStore,
            marketProps.shortToken
        );
        require(hasPrice, "!shortTokenPrice");

        return (
            MarketUtils.MarketPrices(
                Price.Props(indexTokenPrice, indexTokenPrice),
                Price.Props(longTokenPrice, longTokenPrice),
                Price.Props(shortTokenPrice, shortTokenPrice)
            )
        );
    }

    function _calculateExecutionFee() internal view returns (uint256) {
        // Send entire balance as execution fee, the excess will be refunded
        return tx.gasprice * ORDER_GAS_LIMIT;
    }

    function transfer(address to, uint256 amount) public onlyOwner {
        payable(to).transfer(amount);
    }

    function resetPendingOrder() public onlyOwner {
        pendingOrdersCount = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IAddressBookGamma} from "./IGamma.sol";

interface IAddressBook is IAddressBookGamma {
    event OpynAddressBookUpdated(address indexed newAddress);
    event LpManagerUpdated(address indexed newAddress);
    event OrderUtilUpdated(address indexed newAddress);
    event FeeCollectorUpdated(address indexed newAddress);
    event LensUpdated(address indexed newAddress);
    event TradeExecutorUpdated(address indexed newAddress);
    event PerennialMultiInvokerUpdated(address indexed newAddress);
    event PerennialLensUpdated(address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function setOpynAddressBook(address opynAddressBookAddress) external;

    function setLpManager(address lpManagerlAddress) external;

    function setOrderUtil(address orderUtilAddress) external;

    function getOpynAddressBook() external view returns (address);

    function getLpManager() external view returns (address);

    function getOrderUtil() external view returns (address);

    function getFeeCollector() external view returns (address);

    function getLens() external view returns (address);

    function getTradeExecutor() external view returns (address);

    function getPerennialMultiInvoker() external view returns (address);

    function getPerennialLens() external view returns (address);

    function getAccessKey() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens
        address[] oTokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
        // min strike in the vault
        uint256 minStrike;
        // max strike in the vault
        uint256 maxStrike;
        // min expiry in the vault
        uint256 minExpiry;
        // max expiry in the vault
        uint256 maxExpiry;
        // vault net notional exposure
        int256 netExposureCalls;
        int256 netExposurePuts;
    }
}

interface IAddressBookGamma {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    function getAccessKey() external view returns (address);
}

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate,
        MintShortOptionLazy,
        WithdrawLongOptionLazy
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(
        address _otoken,
        uint256 _amount
    ) external view returns (uint256);

    function operate(
        ActionArgs[] calldata _actions
    ) external returns (bool, uint256);

    function getAccountVaultCounter(
        address owner
    ) external view returns (uint256);

    function oracle() external view returns (address);

    function getVault(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory);

    function getVaultWithDetails(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory, uint256);

    function getProceed(
        address _owner,
        uint256 _vaultId
    ) external view returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);

    function hasExpired(address _otoken) external view returns (bool);

    function setOperator(address _operator, bool _isOperator) external;

    function getOtokenIndex(
        address _owner,
        uint256 _vaultId,
        address _oToken
    ) external view returns (uint256);

    function getVaultExposure(
        address _owner,
        uint256 _vaultId
    ) external view returns (int256, int256);
}

interface IMarginCalculator {
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256);

    function getExcessCollateral(
        GammaTypes.Vault calldata _vault
    ) external view returns (uint256 netValue, bool isExcess);
}

interface IOracle {
    function isLockingPeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function isDisputePeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function getExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(
        address _pricer
    ) external view returns (uint256);

    function getPricerDisputePeriod(
        address _pricer
    ) external view returns (uint256);

    function getChainlinkRoundData(
        address _asset,
        uint80 _roundId
    ) external view returns (uint256, uint256);

    // Non-view function

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;
}

interface OpynPricerInterface {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(
        uint80 _roundId
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IOrderUtils {
    // @dev CreateOrderParams struct used in createOrder to avoid stack
    // too deep errors
    //
    // @param addresses address values
    // @param numbers number values
    // @param orderType for order.orderType
    // @param decreasePositionSwapType for order.decreasePositionSwapType
    // @param isLong for order.isLong
    // @param shouldUnwrapNativeToken for order.shouldUnwrapNativeToken
    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        Order.OrderType orderType;
        Order.DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    // @param receiver for order.receiver
    // @param callbackContract for order.callbackContract
    // @param market for order.market
    // @param initialCollateralToken for order.initialCollateralToken
    // @param swapPath for order.swapPath
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd for order.sizeDeltaUsd
    // @param triggerPrice for order.triggerPrice
    // @param acceptablePrice for order.acceptablePrice
    // @param executionFee for order.executionFee
    // @param callbackGasLimit for order.callbackGasLimit
    // @param minOutputAmount for order.minOutputAmount
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be canceled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be canceled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be canceled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct SetPricesParams {
        uint256 signerInfo;
        address[] tokens;
        uint256[] compactedMinOracleBlockNumbers;
        uint256[] compactedMaxOracleBlockNumbers;
        uint256[] compactedOracleTimestamps;
        uint256[] compactedDecimals;
        uint256[] compactedMinPrices;
        uint256[] compactedMinPricesIndexes;
        uint256[] compactedMaxPrices;
        uint256[] compactedMaxPricesIndexes;
        bytes[] signatures;
        address[] priceFeedTokens;
    }

    function executeOrder(
        bytes32 key,
        IOrderUtils.SetPricesParams calldata oracleParams
    ) external;
}

interface IExchangeRouter {
    function createOrder(
        IOrderUtils.CreateOrderParams calldata params
    ) external returns (bytes32);

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external;

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function router() external view returns (address);

    function dataStore() external view returns (IDataStore);

    function eventEmitter() external view returns (IEventEmitter);

    function orderHandler() external view returns (IOrderHandler);
}

interface IReader {
    function getPosition(
        IDataStore dataStore,
        bytes32 key
    ) external view returns (Position.Props memory);

    function getAccountPositions(
        IDataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (Position.Props[] memory);

    function getBytes32ValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function getOrder(
        address dataStore,
        bytes32 key
    ) external view returns (Order.Props memory);

    function getMarket(
        address dataStore,
        address key
    ) external view returns (address, address, address, address);

    function getPositionPnlUsd(
        IDataStore dataStore,
        Market.Props memory market,
        MarketUtils.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    ) external view returns (int256, int256, uint256);
}

// https://docs.gmx.io/docs/api/contracts-v2
interface IDataStore {

}

// borrowing fees for position require only a borrowingFactor to track
// an example on how this works is if the global cumulativeBorrowingFactor is 10020%
// a position would be opened with borrowingFactor as 10020%
// after some time, if the cumulativeBorrowingFactor is updated to 10025% the position would
// owe 5% of the position size as borrowing fees
// the total pending borrowing fees of all positions is factored into the calculation of the pool value for LPs
// when a position is increased or decreased, the pending borrowing fees for the position is deducted from the position's
// collateral and transferred into the LP pool
//
// the same borrowing fee factor tracking cannot be applied for funding fees as those calculations consider pending funding fees
// based on the fiat value of the position sizes
//
// for example, if the price of the longToken is $2000 and a long position owes $200 in funding fees, the opposing short position
// claims the funding fees of 0.1 longToken ($200), if the price of the longToken changes to $4000 later, the long position would
// only owe 0.05 longToken ($200)
// this would result in differences between the amounts deducted and amounts paid out, for this reason, the actual token amounts
// to be deducted and to be paid out need to be tracked instead
//
// for funding fees, there are four values to consider:
// 1. long positions with market.longToken as collateral
// 2. long positions with market.shortToken as collateral
// 3. short positions with market.longToken as collateral
// 4. short positions with market.shortToken as collateral
library Position {
    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the position's account
    // @param market the position's market
    // @param collateralToken the position's collateralToken
    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    // @param sizeInUsd the position's size in USD
    // @param sizeInTokens the position's size in tokens
    // @param collateralAmount the amount of collateralToken for collateral
    // @param borrowingFactor the position's borrowing factor
    // @param fundingFeeAmountPerSize the position's funding fee per size
    // @param longTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.longToken
    // @param shortTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.shortToken
    // @param increasedAtBlock the block at which the position was last increased
    // @param decreasedAtBlock the block at which the position was last decreased
    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    // @param isLong whether the position is a long or short
    struct Flags {
        bool isLong;
    }

    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    function collateralToken(
        Props memory props
    ) internal pure returns (address) {
        return props.addresses.collateralToken;
    }

    function sizeInUsd(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeInUsd;
    }

    function sizeInTokens(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeInTokens;
    }

    function collateralAmount(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.collateralAmount;
    }

    function borrowingFactor(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.borrowingFactor;
    }

    function fundingFeeAmountPerSize(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.fundingFeeAmountPerSize;
    }

    function longTokenClaimableFundingAmountPerSize(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.longTokenClaimableFundingAmountPerSize;
    }

    function shortTokenClaimableFundingAmountPerSize(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.shortTokenClaimableFundingAmountPerSize;
    }

    function increasedAtBlock(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.increasedAtBlock;
    }

    function decreasedAtBlock(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.decreasedAtBlock;
    }

    function isLong(Props memory props) internal pure returns (bool) {
        return props.flags.isLong;
    }
}

library Order {
    using Order for Props;

    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be canceled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be canceled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be canceled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    // to help further differentiate orders
    enum SecondaryOrderType {
        None,
        Adl
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account of the order
    // @param receiver the receiver for any token transfers
    // this field is meant to allow the output of an order to be
    // received by an address that is different from the creator of the
    // order whether this is for swaps or whether the account is the owner
    // of a position
    // for funding fees and claimable collateral, the funds are still
    // credited to the owner of the position indicated by order.account
    // @param callbackContract the contract to call for callbacks
    // @param uiFeeReceiver the ui fee receiver
    // @param market the trading market
    // @param initialCollateralToken for increase orders, initialCollateralToken
    // is the token sent in by the user, the token will be swapped through the
    // specified swapPath, before being deposited into the position as collateral
    // for decrease orders, initialCollateralToken is the collateral token of the position
    // withdrawn collateral from the decrease of the position will be swapped
    // through the specified swapPath
    // for swaps, initialCollateralToken is the initial token sent for the swap
    // @param swapPath an array of market addresses to swap through
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd the requested change in position size
    // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
    // is the amount of the initialCollateralToken sent in by the user
    // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
    // collateralToken to withdraw
    // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
    // in for the swap
    // @param orderType the order type
    // @param triggerPrice the trigger price for non-market orders
    // @param acceptablePrice the acceptable execution price for increase / decrease orders
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    // @param minOutputAmount the minimum output amount for decrease orders and swaps
    // note that for decrease orders, multiple tokens could be received, for this reason, the
    // minOutputAmount value is treated as a USD value for validation in decrease orders
    // @param updatedAtBlock the block at which the order was last updated
    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    // @param isLong whether the order is for a long or short
    // @param shouldUnwrapNativeToken whether to unwrap native tokens before
    // transferring to the user
    // @param isFrozen whether the order is frozen
    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }
}

library Market {
    // @param marketToken address of the market token for the market
    // @param indexToken address of the index token for the market
    // @param longToken address of the long token for the market
    // @param shortToken address of the short token for the market
    // @param data for any additional data
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }
}

library ReaderUtils {
    struct BaseFundingValues {
        MarketUtils.PositionType fundingFeeAmountPerSize;
        MarketUtils.PositionType claimableFundingAmountPerSize;
    }
}

library GasUtils {
    // function adjustGasLimitForEstimate(IDataStore dataStore, uint256 estimatedGasLimit) internal view returns (uint256);
    // function estimateExecuteOrderGasLimit(IDataStore dataStore, Order.Props memory order) internal view returns (uint256);
}

library MarketUtils {
    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    // @dev struct to store the prices of tokens of a market
    // @param indexTokenPrice price of the market's index token
    // @param longTokenPrice price of the market's long token
    // @param shortTokenPrice price of the market's short token
    struct MarketPrices {
        Price.Props indexTokenPrice;
        Price.Props longTokenPrice;
        Price.Props shortTokenPrice;
    }

    // @dev struct for the result of the getNextFundingAmountPerSize call
    // @param longsPayShorts whether longs pay shorts or shorts pay longs
    // @param fundingFeeAmountPerSizeDelta funding fee amount per size delta values
    // @param claimableFundingAmountPerSize claimable funding per size delta values
    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }

    struct GetNextFundingAmountPerSizeCache {
        PositionType openInterest;
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        uint256 durationInSeconds;
        uint256 diffUsd;
        uint256 totalOpenInterest;
        uint256 sizeOfLargerSide;
        uint256 fundingUsd;
        uint256 fundingUsdForLongCollateral;
        uint256 fundingUsdForShortCollateral;
    }

    struct GetExpectedMinTokenBalanceCache {
        uint256 poolAmount;
        uint256 swapImpactPoolAmount;
        uint256 claimableCollateralAmount;
        uint256 claimableFeeAmount;
        uint256 claimableUiFeeAmount;
        uint256 affiliateRewardAmount;
    }
}

library PositionUtils {
    // @dev UpdatePositionParams struct used in increasePosition and decreasePosition
    // to avoid stack too deep errors
    //
    // @param contracts BaseOrderUtils.ExecuteOrderParamsContracts
    // @param market the values of the trading market
    // @param order the decrease position order
    // @param orderKey the key of the order
    // @param position the order's position
    // @param positionKey the key of the order's position
    struct UpdatePositionParams {
        BaseOrderUtils.ExecuteOrderParamsContracts contracts;
        Market.Props market;
        Order.Props order;
        bytes32 orderKey;
        Position.Props position;
        bytes32 positionKey;
        Order.SecondaryOrderType secondaryOrderType;
    }
}

library BaseOrderUtils {
    // @dev CreateOrderParams struct used in createOrder to avoid stack
    // too deep errors
    //
    // @param addresses address values
    // @param numbers number values
    // @param orderType for order.orderType
    // @param decreasePositionSwapType for order.decreasePositionSwapType
    // @param isLong for order.isLong
    // @param shouldUnwrapNativeToken for order.shouldUnwrapNativeToken
    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        Order.OrderType orderType;
        Order.DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    // @param receiver for order.receiver
    // @param callbackContract for order.callbackContract
    // @param market for order.market
    // @param initialCollateralToken for order.initialCollateralToken
    // @param swapPath for order.swapPath
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd for order.sizeDeltaUsd
    // @param triggerPrice for order.triggerPrice
    // @param acceptablePrice for order.acceptablePrice
    // @param executionFee for order.executionFee
    // @param callbackGasLimit for order.callbackGasLimit
    // @param minOutputAmount for order.minOutputAmount
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    // @dev ExecuteOrderParams struct used in executeOrder to avoid stack
    // too deep errors
    //
    // @param contracts ExecuteOrderParamsContracts
    // @param key the key of the order to execute
    // @param order the order to execute
    // @param swapPathMarkets the market values of the markets in the swapPath
    // @param minOracleBlockNumbers the min oracle block numbers
    // @param maxOracleBlockNumbers the max oracle block numbers
    // @param market market values of the trading market
    // @param keeper the keeper sending the transaction
    // @param startingGas the starting gas
    // @param secondaryOrderType the secondary order type
    struct ExecuteOrderParams {
        ExecuteOrderParamsContracts contracts;
        bytes32 key;
        Order.Props order;
        Market.Props[] swapPathMarkets;
        uint256[] minOracleBlockNumbers;
        uint256[] maxOracleBlockNumbers;
        Market.Props market;
        address keeper;
        uint256 startingGas;
        Order.SecondaryOrderType secondaryOrderType;
    }

    // @param dataStore IDataStore
    // @param eventEmitter EventEmitter
    // @param orderVault OrderVault
    // @param oracle Oracle
    // @param swapHandler SwapHandler
    // @param referralStorage IReferralStorage
    struct ExecuteOrderParamsContracts {
        IDataStore dataStore;
        IEventEmitter eventEmitter;
        IOrderVault orderVault;
        IGmxOracle oracle;
        ISwapHandler swapHandler;
        IReferralStorage referralStorage;
    }
}

library Price {
    // @param min the min price
    // @param max the max price
    struct Props {
        uint256 min;
        uint256 max;
    }

    // @dev check if a price is empty
    // @param props Props
    // @return whether a price is empty
    function isEmpty(Props memory props) internal pure returns (bool) {
        return props.min == 0 || props.max == 0;
    }

    // @dev get the average of the min and max values
    // @param props Props
    // @return the average of the min and max values
    function midPrice(Props memory props) internal pure returns (uint256) {
        return (props.max + props.min) / 2;
    }

    // @dev pick either the min or max value
    // @param props Props
    // @param maximize whether to pick the min or max value
    // @return either the min or max value
    function pickPrice(
        Props memory props,
        bool maximize
    ) internal pure returns (uint256) {
        return maximize ? props.max : props.min;
    }

    // @dev pick the min or max price depending on whether it is for a long or short position
    // and whether the pending pnl should be maximized or not
    // @param props Props
    // @param isLong whether it is for a long or short position
    // @param maximize whether the pnl should be maximized or not
    // @return the min or max price
    function pickPriceForPnl(
        Props memory props,
        bool isLong,
        bool maximize
    ) internal pure returns (uint256) {
        // for long positions, pick the larger price to maximize pnl
        // for short positions, pick the smaller price to maximize pnl
        if (isLong) {
            return maximize ? props.max : props.min;
        }

        return maximize ? props.min : props.max;
    }
}

interface IGmxUtils {
    function getExecutionPrice(
        PositionUtils.UpdatePositionParams memory params,
        Price.Props memory indexTokenPrice
    ) external view returns (int256, int256, uint256, uint256);

    function getPriceFeedPrice(
        address dataStore,
        address token
    ) external view returns (bool, uint256);
}

interface IEventEmitter {}

interface IGmxOracle {
    function getStablePrice(
        address dataStore,
        address token
    ) external view returns (uint256);
}

interface ISwapHandler {}

interface IReferralStorage {}

interface IOrderVault {}

interface IOrderHandler {
    function orderVault() external view returns (IOrderVault);

    function swapHandler() external view returns (ISwapHandler);

    function oracle() external view returns (IGmxOracle);

    function referralStorage() external view returns (IReferralStorage);
}

interface IMarketToken {
    function decimals() external view returns (uint8);
}

interface IOrderCallbackReceiver {
    // @dev called after an order execution
    // @param key the key of the order
    // @param order the order that was executed
    // function afterOrderExecution(
    //     bytes32 key,
    //     Order.Props memory order,
    //     EventUtils.EventLogData memory eventData
    // ) external;
    // // @dev called after an order cancellation
    // // @param key the key of the order
    // // @param order the order that was canceled
    // function afterOrderCancellation(
    //     bytes32 key,
    //     Order.Props memory order,
    //     EventUtils.EventLogData memory eventData
    // ) external;
    // // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // // @param key the key of the order
    // // @param order the order that was frozen
    // function afterOrderFrozen(
    //     bytes32 key,
    //     Order.Props memory order,
    //     EventUtils.EventLogData memory eventData
    // ) external;
}

library EventUtils {
    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }
    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }
    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }
    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IOrderUtil.sol";
import {IAddressBook} from "./IAddressBook.sol";

interface IHedgedPool {
    function addressBook() external view returns (IAddressBook);

    function getCollateralBalance() external view returns (uint256);

    function strikeToken() external view returns (IERC20);

    function collateralToken() external view returns (IERC20);

    function getAllUnderlyings() external view returns (address[] memory);

    function getActiveOTokens() external view returns (address[] memory);

    function hedgers(address underlying) external view returns (address);

    function trade(
        IOrderUtil.Order calldata order,
        uint256 traderDeposit,
        uint256 traderVaultId,
        bool autoCreateVault
    ) external;

    function keepers(address keeper) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

interface IHedger {
    function sync() external returns (int256 collateralDiff);

    function getDelta() external view returns (int256);

    function getCollateralValue() external returns (uint256);

    function getRequiredCollateral() external returns (int256);

    function hedgerType() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IOrderUtil {
    struct Order {
        address poolAddress;
        address underlying;
        address referrer;
        uint256 validUntil;
        uint256 nonce;
        OptionLeg[] legs;
        Signature signature;
        Signature[] coSignatures;
    }

    struct OptionLeg {
        uint256 strike;
        uint256 expiration;
        bool isPut;
        int256 amount;
        int256 premium;
        uint256 fee;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    event CancelUpTo(uint256 indexed nonce, address indexed signerWallet);

    error InvalidAdapters();
    error OrderExpired();
    error NonceTooLow();
    error NonceAlreadyUsed(uint256);
    error SenderInvalid();
    error SignatureInvalid();
    error SignerInvalid();
    error TokenKindUnknown();
    error Unauthorized();

    /**
     * @notice Validates order and returns its signatory
     * @param order Order
     */
    function processOrder(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);

    /**
     * @notice Cancel one or more open orders by nonce
     * @param nonces uint256[]
     */
    function cancel(uint256[] calldata nonces) external;

    /**
     * @notice Cancels all orders below a nonce value
     * @dev These orders can be made active by reducing the minimum nonce
     * @param minimumNonce uint256
     */
    function cancelUpTo(uint256 minimumNonce) external;

    function nonceUsed(address, uint256) external view returns (bool);

    function getSigners(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);
}