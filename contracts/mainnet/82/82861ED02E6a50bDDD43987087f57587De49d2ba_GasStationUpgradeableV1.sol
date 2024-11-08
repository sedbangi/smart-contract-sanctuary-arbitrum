// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IInitializerSender.sol";
import "./interfaces/IClientReceiverContract.sol";
import "./base/AsterizmEnv.sol";
import "./base/AsterizmWithdrawalUpgradeable.sol";
import "./libs/AddressLib.sol";
import "./libs/UintLib.sol";
import "./libs/AsterizmHashLib.sol";

abstract contract AsterizmClientUpgradeable is UUPSUpgradeable, IClientReceiverContract, AsterizmEnv, AsterizmWithdrawalUpgradeable {

    using AddressLib for address;
    using UintLib for uint;
    using AsterizmHashLib for bytes;

    /// Set initializer event
    /// @param _initializerAddress address  Initializer address
    event SetInitializerEvent(address _initializerAddress);

    /// Set external relay event
    /// @param _externalRelayAddress address  External relay address
    event SetExternalRelayEvent(address _externalRelayAddress);

    /// Set fee token event
    /// @param _feeTokenAddress address  Fee token address
    event SetFeeTokenEvent(address _feeTokenAddress);

    /// Set local chain id event
    /// @param _localChainId uint64
    event SetLocalChainIdEvent(uint64 _localChainId);

    /// Initiate transfer event (for client server logic)
    /// @param _dstChainId uint64  Destination chein ID
    /// @param _dstAddress uint  Destination address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _payload bytes  Payload
    event InitiateTransferEvent(uint64 _dstChainId, uint _dstAddress, uint _txId, bytes32 _transferHash, bytes _payload);

    /// Payload receive event (for client server logic)
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _txId uint  Transfer ID
    /// @param _transferHash bytes32  Transaction hash
    event PayloadReceivedEvent(uint64 _srcChainId, uint _srcAddress, uint _txId, bytes32 _transferHash);

    /// Add sender event
    /// @param _sender address  Sender address
    event AddSenderEvent(address _sender);

    /// Remove sender event
    /// @param _sender address  Sender address
    event RemoveSenderEvent(address _sender);

    /// Add trusted address event
    /// @param _chainId uint64  Chain ID
    /// @param _address uint  Trusted address
    event AddTrustedAddressEvent(uint64 _chainId, uint _address);

    /// Remove trusted address event
    /// @param _chainId uint64  Chain ID
    /// @param _address uint  Trusted address
    event RemoveTrustedAddressEvent(uint64 _chainId, uint _address);

    /// Set notify transfer sending result event
    /// @param _flag bool  Notify transfer sending result flag
    event SetNotifyTransferSendingResultEvent(bool _flag);

    /// Set disable hash validation flag event
    /// @param _flag bool  Use force order flag
    event SetDisableHashValidationEvent(bool _flag);

    /// Resend Asterizm transfer event
    /// @param _transferHash bytes32  Transfer hash
    /// @param _feeAmount uint  Additional fee amount
    event ResendAsterizmTransferEvent(bytes32 _transferHash, uint _feeAmount);

    /// Transfer sending result notification event
    /// @param _transferHash bytes32  Transfer hash
    /// @param _statusCode uint8  Status code
    event TransferSendingResultNotification(bytes32 indexed _transferHash, uint8 _statusCode);

    struct AsterizmTransfer {
        bool successReceive;
        bool successExecute;
    }

    struct AsterizmChain {
        bool exists;
        uint trustedAddress;
        uint8 chainType;
    }
    struct Sender {
        bool exists;
    }

    IInitializerSender private initializerLib;
    address private externalRelay;
    mapping(uint64 => AsterizmChain) private trustedAddresses;
    mapping(bytes32 => AsterizmTransfer) private inboundTransfers;
    mapping(bytes32 => AsterizmTransfer) private outboundTransfers;
    mapping(address => Sender) private senders;
    bool private notifyTransferSendingResult;
    bool private disableHashValidation;
    uint private txId;
    uint64 private localChainId;
    IERC20 private feeToken;

    /// Initializing function for upgradeable contracts (constructor)
    /// @param _initializerLib IInitializerSender  Initializer library address
    /// @param _notifyTransferSendingResult bool  Transfer sending result notification flag
    /// @param _disableHashValidation bool  Disable hash validation flag
    function __AsterizmClientUpgradeable_init(IInitializerSender _initializerLib, bool _notifyTransferSendingResult, bool _disableHashValidation) initializer public {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _setInitializer(_initializerLib);
        _setLocalChainId(initializerLib.getLocalChainId());
        _setNotifyTransferSendingResult(_notifyTransferSendingResult);
        _setDisableHashValidation(_disableHashValidation);
        addSender(owner());
        addTrustedAddress(localChainId, address(this).toUint());
    }

    /// Upgrade implementation address for UUPS logic
    /// @param _newImplementation address  New implementation address
    function _authorizeUpgrade(address _newImplementation) internal onlyOwner override {}

    /// Only initializer modifier
    modifier onlyInitializer {
        require(msg.sender == address(initializerLib), "AsterizmClient: only initializer");
        _;
    }

    /// Only owner or initializer modifier
    modifier onlyOwnerOrInitializer {
        require(msg.sender == owner() || msg.sender == address(initializerLib), "AsterizmClient: only owner or initializer");
        _;
    }

    /// Only sender modifier
    modifier onlySender {
        require(senders[msg.sender].exists, "AsterizmClient: only sender");
        _;
    }

    /// Only sender or owner modifier
    modifier onlySenderOrOwner {
        require(msg.sender == owner() || senders[msg.sender].exists, "AsterizmClient: only sender or owner");
        _;
    }

    /// Only trusted address modifier
    /// You must add trusted addresses in production networks!
    modifier onlyTrustedAddress(uint64 _chainId, uint _address) {
        require(trustedAddresses[_chainId].trustedAddress == _address, "AsterizmClient: wrong source address");
        _;
    }

    /// Only trusted trarnsfer modifier
    /// Validate transfer hash on initializer
    /// Use this modifier for validate transfer by hash
    /// @param _transferHash bytes32  Transfer hash
    modifier onlyTrustedTransfer(bytes32 _transferHash) {
        require(initializerLib.validIncomeTransferHash(_transferHash), "AsterizmClient: transfer hash is invalid");
        _;
    }

    /// Only received transfer modifier
    /// @param _transferHash bytes32  Transfer hash
    modifier onlyReceivedTransfer(bytes32 _transferHash) {
        require(inboundTransfers[_transferHash].successReceive, "AsterizmClient: transfer not received");
        _;
    }

    /// Only non-executed transfer modifier
    /// @param _transferHash bytes32  Transfer hash
    modifier onlyNonExecuted(bytes32 _transferHash) {
        require(!inboundTransfers[_transferHash].successExecute, "AsterizmClient: transfer executed already");
        _;
    }

    /// Only exists outbound transfer modifier
    /// @param _transferHash bytes32  Transfer hash
    modifier onlyExistsOutboundTransfer(bytes32 _transferHash) {
        require(outboundTransfers[_transferHash].successReceive, "AsterizmClient: outbound transfer not exists");
        _;
    }

    /// Only not executed outbound transfer modifier
    /// @param _transferHash bytes32  Transfer hash
    modifier onlyNotExecutedOutboundTransfer(bytes32 _transferHash) {
        require(!outboundTransfers[_transferHash].successExecute, "AsterizmClient: outbound transfer executed already");
        _;
    }

    /// Only executed outbound transfer modifier
    /// @param _transferHash bytes32  Transfer hash
    modifier onlyExecutedOutboundTransfer(bytes32 _transferHash) {
        require(outboundTransfers[_transferHash].successExecute, "AsterizmClient: outbound transfer not executed");
        _;
    }

    /// Only nvalid transfer hash modifier
    /// @param _dto ClAsterizmReceiveRequestDto  Transfer data
    modifier onlyValidTransferHash(ClAsterizmReceiveRequestDto memory _dto) {
        if (!disableHashValidation) {
            require(
                _validTransferHash(_dto.srcChainId, _dto.srcAddress, _dto.dstChainId, _dto.dstAddress, _dto.txId, _dto.payload, _dto.transferHash),
                "AsterizmClient: transfer hash is invalid"
            );
        }
        _;
    }

    /** Internal logic */

    /// Set initizlizer library
    /// _initializerLib IInitializerSender  Initializer library
    function _setInitializer(IInitializerSender _initializerLib) private {
        initializerLib = _initializerLib;
        emit SetInitializerEvent(address(_initializerLib));
    }

    /// Set local chain id library
    /// _localChainId uint64
    function _setLocalChainId(uint64 _localChainId) private {
        localChainId = _localChainId;
        emit SetLocalChainIdEvent(_localChainId);
    }

    /// Set notify transfer sending result
    /// _flag bool  Transfer sending result notification flag
    function _setNotifyTransferSendingResult(bool _flag) private {
        notifyTransferSendingResult = _flag;
        emit SetNotifyTransferSendingResultEvent(_flag);
    }

    /// Set disable hash validation flag
    /// _flag bool  Disable hash validation flag
    function _setDisableHashValidation(bool _flag) private {
        disableHashValidation = _flag;
        emit SetDisableHashValidationEvent(_flag);
    }

    /// Return chain type by id
    /// @param _chainId uint64  Chain id
    /// @return uint8  Chain type
    function _getChainType(uint64 _chainId) internal view returns(uint8) {
        return initializerLib.getChainType(_chainId);
    }

    /// Set external relay address (one-time initiation)
    /// _externalRelay address  External relay address
    function setExternalRelay(address _externalRelay) public onlyOwner {
        require(externalRelay == address(0), "AsterizmClient: relay changing not available");
        externalRelay = _externalRelay;
        emit SetExternalRelayEvent(_externalRelay);
    }

    /// Return external relay
    /// @return address  External relay address
    function getExternalRelay() external view returns(address) {
        return externalRelay;
    }

    /// Set external relay address (one-time initiation)
    /// _feeToken IERC20  External relay address
    function setFeeToken(IERC20 _feeToken) public onlyOwner {
        feeToken = _feeToken;
        emit SetFeeTokenEvent(address(_feeToken));
    }

    /// Return fee token
    /// @return address  Fee token address
    function getFeeToken() external view returns(address) {
        return address(feeToken);
    }

    /// Add sender
    /// @param _sender address  Sender address
    function addSender(address _sender) public onlyOwner {
        senders[_sender].exists = true;
        emit AddSenderEvent(_sender);
    }

    /// Remove sender
    /// @param _sender address  Sender address
    function removeSender(address _sender) public onlyOwner {
        require(senders[_sender].exists, "AsterizmClient: sender not exists");
        delete senders[_sender];
        emit RemoveSenderEvent(_sender);
    }

    /// Add trusted address
    /// @param _chainId uint64  Chain ID
    /// @param _trustedAddress address  Trusted address
    function addTrustedAddress(uint64 _chainId, uint _trustedAddress) public onlyOwner {
        trustedAddresses[_chainId].exists = true;
        trustedAddresses[_chainId].trustedAddress = _trustedAddress;
        trustedAddresses[_chainId].chainType = initializerLib.getChainType(_chainId);

        emit AddTrustedAddressEvent(_chainId, _trustedAddress);
    }

    /// Add trusted addresses
    /// @param _chainIds uint64[]  Chain IDs
    /// @param _trustedAddresses uint[]  Trusted addresses
    function addTrustedAddresses(uint64[] calldata _chainIds, uint[] calldata _trustedAddresses) external onlyOwner {
        for (uint i = 0; i < _chainIds.length; i++) {
            addTrustedAddress(_chainIds[i], _trustedAddresses[i]);
        }
    }

    /// Remove trusted address
    /// @param _chainId uint64  Chain ID
    function removeTrustedAddress(uint64 _chainId) external onlyOwner {
        require(trustedAddresses[_chainId].exists, "AsterizmClient: trusted address not found");
        uint removingAddress = trustedAddresses[_chainId].trustedAddress;
        delete trustedAddresses[_chainId];

        emit RemoveTrustedAddressEvent(_chainId, removingAddress);
    }

    /// Build transfer hash
    /// @param _srcChainId uint64  Chain ID
    /// @param _srcAddress uint  Address
    /// @param _dstChainId uint64  Chain ID
    /// @param _dstAddress uint  Address
    /// @param _txId uint  Transaction ID
    /// @param _payload bytes  Payload
    function _buildTransferHash(uint64 _srcChainId, uint _srcAddress, uint64 _dstChainId, uint _dstAddress, uint _txId, bytes memory _payload) internal view returns(bytes32) {
        bytes memory encodeData = abi.encodePacked(_srcChainId, _srcAddress, _dstChainId, _dstAddress, _txId, _buildPackedPayload(_payload));

        return _getChainType(_srcChainId) == _getChainType(_dstChainId) ? encodeData.buildSimpleHash() : encodeData.buildCrosschainHash();
    }

    /// Check is transfer hash valid
    /// @param _srcChainId uint64  Chain ID
    /// @param _srcAddress uint  Address
    /// @param _dstChainId uint64  Chain ID
    /// @param _dstAddress uint  Address
    /// @param _txId uint  Transaction ID
    /// @param _payload bytes  Packed payload
    /// @param _transferHash bytes32  Transfer hash
    function _validTransferHash(uint64 _srcChainId, uint _srcAddress, uint64 _dstChainId, uint _dstAddress, uint _txId, bytes memory _payload, bytes32 _transferHash) internal view returns(bool) {
        return _buildTransferHash(_srcChainId, _srcAddress, _dstChainId, _dstAddress, _txId, _payload) == _transferHash;
    }

    /// Return txId
    /// @return uint
    function _getTxId() internal view returns(uint) {
        return txId;
    }

    /// Return local chain id
    /// @return uint64
    function _getLocalChainId() internal view returns(uint64) {
        return localChainId;
    }

    /// Return initializer address
    /// @return address
    function getInitializerAddress() external view returns(address) {
        return address(initializerLib);
    }

    /// Return trusted src addresses
    /// @param _chainId uint64  Chain id
    /// @return AsterizmChain
    function getTrustedAddresses(uint64 _chainId) external view returns(AsterizmChain memory) {
        return trustedAddresses[_chainId];
    }

    /// Return disable hash validation flag
    /// @return bool
    function getDisableHashValidation() external view returns(bool) {
        return disableHashValidation;
    }

    /// Return notify transfer sending result flag
    /// @return bool
    function getNotifyTransferSendingResult() external view returns(bool) {
        return notifyTransferSendingResult;
    }

    /** Sending logic */

    /// Initiate transfer event
    /// Generate event for client server
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _payload bytes  Payload
    function _initAsterizmTransferEvent(uint64 _dstChainId, bytes memory _payload) internal {
        require(trustedAddresses[_dstChainId].exists, "AsterizmClient: trusted address not found");
        uint id = txId++;
        bytes32 transferHash = _buildTransferHash(_getLocalChainId(), address(this).toUint(), _dstChainId, trustedAddresses[_dstChainId].trustedAddress, id, _payload);
        outboundTransfers[transferHash].successReceive = true;
        emit InitiateTransferEvent(_dstChainId, trustedAddresses[_dstChainId].trustedAddress, id, transferHash, _payload);
    }

    /// External initiation transfer
    /// This function needs for external initiating non-encoded payload transfer
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _txId uint  Transaction ID
    function initAsterizmTransfer(uint64 _dstChainId, uint _txId, bytes32 _transferHash) external payable onlySender nonReentrant {
        require(trustedAddresses[_dstChainId].exists, "AsterizmClient: trusted address not found");
        ClInitTransferRequestDto memory dto = _buildClInitTransferRequestDto(_dstChainId, trustedAddresses[_dstChainId].trustedAddress, _txId, _transferHash, msg.value);
        _initAsterizmTransferPrivate(dto);
    }

    /// Private initiation transfer
    /// This function needs for internal initiating non-encoded payload transfer
    /// @param _dto ClInitTransferRequestDto  Init transfer DTO
    function _initAsterizmTransferPrivate(ClInitTransferRequestDto memory _dto) private
    onlyExistsOutboundTransfer(_dto.transferHash)
    onlyNotExecutedOutboundTransfer(_dto.transferHash)
    {
        require(address(this).balance >= _dto.feeAmount, "AsterizmClient: contract balance is not enough");
        require(_dto.txId <= _getTxId(), "AsterizmClient: wrong txId param");

        IzInitTransferRequestDto memory initDto = _buildIzInitTransferRequestDto(
            _dto.dstChainId, _dto.dstAddress, _dto.txId, _dto.transferHash,
            externalRelay, notifyTransferSendingResult, address(feeToken)
        );

        if (address(feeToken) != address(0)) {
            uint feeAmountInToken = initializerLib.getFeeAmountInTokens(externalRelay, initDto);
            if (feeAmountInToken > 0) {
                require(feeToken.balanceOf(address(this)) >= feeAmountInToken, "AsterizmClient: fee token balance is not enough");
                feeToken.approve(address(initializerLib), feeAmountInToken);
            }
        }

        initializerLib.initTransfer{value: _dto.feeAmount} (initDto);
        outboundTransfers[_dto.transferHash].successExecute = true;
    }

    /// Resend failed by fee amount transfer
    /// @param _transferHash bytes32  Transfer hash
    function resendAsterizmTransfer(bytes32 _transferHash) external payable
    onlyOwner
    onlyExistsOutboundTransfer(_transferHash)
    onlyExecutedOutboundTransfer(_transferHash)
    {
        initializerLib.resendTransfer{value: msg.value}(_transferHash, externalRelay);
        emit ResendAsterizmTransferEvent(_transferHash, msg.value);
    }

    /// Transfer sending result notification
    /// @param _transferHash bytes32  Transfer hash
    /// @param _statusCode uint8  Status code
    function transferSendingResultNotification(bytes32 _transferHash, uint8 _statusCode) external onlyInitializer onlyExecutedOutboundTransfer(_transferHash) {
        if (notifyTransferSendingResult) {
            emit TransferSendingResultNotification(_transferHash, _statusCode);
        }
    }

    /** Receiving logic */

    /// Receive payload from initializer
    /// @param _dto IzAsterizmReceiveRequestDto  Method DTO
    function asterizmIzReceive(IzAsterizmReceiveRequestDto calldata _dto) external onlyInitializer {
        _asterizmReceiveExternal(_dto);
    }

    /// Receive external payload
    /// @param _dto IzAsterizmReceiveRequestDto  Method DTO
    function _asterizmReceiveExternal(IzAsterizmReceiveRequestDto calldata _dto) private
    onlyOwnerOrInitializer
    onlyTrustedAddress(_dto.srcChainId, _dto.srcAddress)
    onlyNonExecuted(_dto.transferHash)
    {
        inboundTransfers[_dto.transferHash].successReceive = true;
        emit PayloadReceivedEvent(_dto.srcChainId, _dto.srcAddress, _dto.txId, _dto.transferHash);
    }

    /// Receive payload from client server
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _payload bytes  Payload
    function asterizmClReceive(uint64 _srcChainId, uint _srcAddress, uint _txId, bytes32 _transferHash, bytes calldata _payload) external onlySender nonReentrant {
        ClAsterizmReceiveRequestDto memory dto = _buildClAsterizmReceiveRequestDto(_srcChainId, _srcAddress, localChainId, address(this).toUint(), _txId, _transferHash, _payload);
        _asterizmReceiveInternal(dto);
    }

    /// Receive non-encoded payload for internal usage
    /// @param _dto ClAsterizmReceiveRequestDto  Method DTO
    function _asterizmReceiveInternal(ClAsterizmReceiveRequestDto memory _dto) private
    onlyOwnerOrInitializer
    onlyReceivedTransfer(_dto.transferHash)
    onlyTrustedAddress(_dto.srcChainId, _dto.srcAddress)
    onlyTrustedTransfer(_dto.transferHash)
    onlyNonExecuted(_dto.transferHash)
    onlyValidTransferHash(_dto)
    {
        _asterizmReceive(_dto);
        inboundTransfers[_dto.transferHash].successExecute = true;
    }

    /// Receive payload
    /// You must realize this function if you want to transfer payload
    /// If disableHashValidation = true you must validate transferHash with _validTransferHash() method for more security!
    /// @param _dto ClAsterizmReceiveRequestDto  Method DTO
    function _asterizmReceive(ClAsterizmReceiveRequestDto memory _dto) internal virtual {}

    /// Build packed payload (abi.encodePacked() result)
    /// @param _payload bytes  Default payload (abi.encode() result)
    /// @return bytes  Packed payload (abi.encodePacked() result)
    function _buildPackedPayload(bytes memory _payload) internal view virtual returns(bytes memory) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IAsterizmEnv.sol";

abstract contract AsterizmEnv is IAsterizmEnv {

    /// Build initializer receive payload request DTO
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @return BaseTransferDirectionDto
    function _buildBaseTransferDirectionDto(
        uint64 _srcChainId, uint _srcAddress,
        uint64 _dstChainId, uint _dstAddress
    ) internal pure returns(BaseTransferDirectionDto memory) {
        BaseTransferDirectionDto memory dto;
        dto.srcChainId = _srcChainId;
        dto.srcAddress = _srcAddress;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;

        return dto;
    }

    /// Build client initiation transfer request DTO
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @param _transferHash bytes32  Transfer hash
    /// @param _feeAmount uint  Fee amount
    /// @param _txId uint  Transaction ID
    /// @return ClInitTransferRequestDto
    function _buildClInitTransferRequestDto(uint64 _dstChainId, uint _dstAddress, uint _txId, bytes32 _transferHash, uint _feeAmount) internal pure returns(ClInitTransferRequestDto memory) {
        ClInitTransferRequestDto memory dto;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;
        dto.transferHash = _transferHash;
        dto.feeAmount = _feeAmount;
        dto.txId = _txId;

        return dto;
    }

    /// Build iuntrnal client initiation transfer request DTO
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @param _feeAmount uint  Fee amount
    /// @param _payload bytes  Payload
    /// @return InternalClInitTransferRequestDto
    function _buildInternalClInitTransferRequestDto(uint64 _dstChainId, uint _dstAddress, uint _feeAmount, bytes memory _payload) internal pure returns(InternalClInitTransferRequestDto memory) {
        InternalClInitTransferRequestDto memory dto;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;
        dto.feeAmount = _feeAmount;
        dto.payload = _payload;

        return dto;
    }

    /// Build translator send message request DTO
    /// @param _srcAddress uint  Source address
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _transferResultNotifyFlag bool  Transfer result notification flag
    /// @return TrSendMessageRequestDto
    function _buildTrSendMessageRequestDto(
        uint _srcAddress, uint64 _dstChainId, uint _dstAddress,
        uint _txId, bytes32 _transferHash, bool _transferResultNotifyFlag
    ) internal pure returns(TrSendMessageRequestDto memory) {
        TrSendMessageRequestDto memory dto;
        dto.srcAddress = _srcAddress;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;
        dto.txId = _txId;
        dto.transferHash = _transferHash;
        dto.transferResultNotifyFlag = _transferResultNotifyFlag;

        return dto;
    }

    /// Build translator transfer message request DTO
    /// @param _gasLimit uint  Gas limit
    /// @param _payload bytes  Payload
    /// @return TrTransferMessageRequestDto
    function _buildTrTransferMessageRequestDto(uint _gasLimit, bytes memory _payload) internal pure returns(TrTransferMessageRequestDto memory) {
        TrTransferMessageRequestDto memory dto;
        dto.gasLimit = _gasLimit;
        dto.payload = _payload;

        return dto;
    }

    /// Build initializer init transfer request DTO
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _relay address  External relay
    /// @param _transferResultNotifyFlag bool  Transfer result notification flag
    /// @param _feeToken address  Token address for paying relay fee (Chainlink for example)
    /// @return IzIninTransferRequestDto
    function _buildIzInitTransferRequestDto(
        uint64 _dstChainId, uint _dstAddress, uint _txId, bytes32 _transferHash, address _relay,
        bool _transferResultNotifyFlag, address _feeToken
    ) internal pure returns(IzInitTransferRequestDto memory) {
        IzInitTransferRequestDto memory dto;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;
        dto.txId = _txId;
        dto.transferHash = _transferHash;
        dto.relay = _relay;
        dto.transferResultNotifyFlag = _transferResultNotifyFlag;
        dto.feeToken = _feeToken;

        return dto;
    }

    /// Build initializer asterizm receive request DTO
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @return IzAsterizmReceiveRequestDto
    function _buildIzAsterizmReceiveRequestDto(
        uint64 _srcChainId, uint _srcAddress, uint64 _dstChainId,
        uint _dstAddress, uint _txId, bytes32 _transferHash
    ) internal pure returns(IzAsterizmReceiveRequestDto memory) {
        IzAsterizmReceiveRequestDto memory dto;
        dto.srcChainId = _srcChainId;
        dto.srcAddress = _srcAddress;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;
        dto.txId = _txId;
        dto.transferHash = _transferHash;

        return dto;
    }

    /// Build client asterizm receive request DTO
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _payload bytes  Transfer payload
    /// @return ClAsterizmReceiveRequestDto
    function _buildClAsterizmReceiveRequestDto(
        uint64 _srcChainId, uint _srcAddress, uint64 _dstChainId, uint _dstAddress,
        uint _txId, bytes32 _transferHash, bytes memory _payload
    ) internal pure returns(ClAsterizmReceiveRequestDto memory) {
        ClAsterizmReceiveRequestDto memory dto;
        dto.srcChainId = _srcChainId;
        dto.srcAddress = _srcAddress;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;
        dto.txId = _txId;
        dto.transferHash = _transferHash;
        dto.payload = _payload;

        return dto;
    }

    /// Build initializer receive payload request DTO
    /// @param _baseTransferDirectioDto BaseTransferDirectionDto  Base transfer direction DTO
    /// @param _gasLimit uint  Gas limit
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @return IzReceivePayloadRequestDto
    function _buildIzReceivePayloadRequestDto(
        BaseTransferDirectionDto memory _baseTransferDirectioDto,
        uint _gasLimit, uint _txId, bytes32 _transferHash
    ) internal pure returns(IzReceivePayloadRequestDto memory) {
        IzReceivePayloadRequestDto memory dto;
        dto.srcChainId = _baseTransferDirectioDto.srcChainId;
        dto.srcAddress = _baseTransferDirectioDto.srcAddress;
        dto.dstChainId = _baseTransferDirectioDto.dstChainId;
        dto.dstAddress = _baseTransferDirectioDto.dstAddress;
        dto.gasLimit = _gasLimit;
        dto.txId = _txId;
        dto.transferHash = _transferHash;

        return dto;
    }

    /// Build initializer retry payload request DTO
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _dstChainId uint64  Destination chain ID
    /// @param _dstAddress uint  Destination address
    /// @param _nonce uint  Nonce
    /// @param _gasLimit uint  Gas limit
    /// @param _forceOrder bool  Force order flag
    /// @param _transferHash bytes32  Transfer hash
    /// @param _payload bytes  Payload
    /// @return IzRetryPayloadRequestDto
    function _buildIzRetryPayloadRequestDto(
        uint64 _srcChainId, uint _srcAddress, uint64 _dstChainId, uint _dstAddress,
        uint _nonce, uint _gasLimit, bool _forceOrder, bytes32 _transferHash, bytes calldata _payload
    ) internal pure returns(IzRetryPayloadRequestDto memory) {
        IzRetryPayloadRequestDto memory dto;
        dto.srcChainId = _srcChainId;
        dto.srcAddress = _srcAddress;
        dto.dstChainId = _dstChainId;
        dto.dstAddress = _dstAddress;
        dto.nonce = _nonce;
        dto.gasLimit = _gasLimit;
        dto.forceOrder = _forceOrder;
        dto.transferHash = _transferHash;
        dto.payload = _payload;

        return dto;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Asterizm withdrawal contract
abstract contract AsterizmWithdrawalUpgradeable is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20 for IERC20;

    /// Withdrawal coins event
    /// @param _targetAddress address  Target address
    /// @param _amount uint  Amount
    event WithdrawCoinsEvent(address _targetAddress, uint _amount);

    /// Withdrawal tokens event
    /// @param _tokenAddress address  Token address
    /// @param _targetAddress address  Target address
    /// @param _amount uint  Amount
    event WithdrawTokensEvent(address _tokenAddress, address _targetAddress, uint _amount);

    receive() external payable {}
    fallback() external payable {}

    /// Withdraw coins
    /// @param _target address  Target address
    /// @param _amount uint  Amount
    function withdrawCoins(address _target, uint _amount) external onlyOwner nonReentrant {
        require(address(this).balance >= _amount, "AsterizmWithdrawal: coins balance not enough");
        (bool success, ) = _target.call{value: _amount}("");
        require(success, "AsterizmWithdrawal: transfer error");
        emit WithdrawCoinsEvent(_target, _amount);
    }

    /// Withdraw tokens
    /// @param _token IERC20  Token address
    /// @param _target address  Target address
    /// @param _amount uint  Amount
    function withdrawTokens(IERC20 _token, address _target, uint _amount) external onlyOwner nonReentrant {
        require(_token.balanceOf(address(this)) >= _amount, "AsterizmWithdrawal: coins balance not enough");
        _token.safeTransfer(_target, _amount);
        emit WithdrawTokensEvent(address(_token), _target, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAsterizmEnv {

    /// Base transfer direction DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    struct BaseTransferDirectionDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
    }

    /// Client initiation transfer request DTO
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param feeAmount uint  Fee amount
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Payload
    struct ClInitTransferRequestDto {
        uint64 dstChainId;
        uint dstAddress;
        uint feeAmount;
        uint txId;
        bytes32 transferHash;
    }

    /// Internal client initiation transfer request DTO
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param feeAmount uint  Fee amount
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Payload
    struct InternalClInitTransferRequestDto {
        uint64 dstChainId;
        uint dstAddress;
        uint feeAmount;
        bytes payload;
    }

    /// Initializer asterizm receive request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param nonce uint  Nonce
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    struct IzAsterizmReceiveRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint txId;
        bytes32 transferHash;
    }

    /// Client asterizm receive request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Transfer payload
    struct ClAsterizmReceiveRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint txId;
        bytes32 transferHash;
        bytes payload;
    }

    /// Translator send message request DTO
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    /// @param transferResultNotifyFlag bool  Transfer result notification flag
    struct TrSendMessageRequestDto {
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint txId;
        bytes32 transferHash;
        bool transferResultNotifyFlag;
    }

    /// Translator transfer message request DTO
    /// @param gasLimit uint  Gas limit
    /// @param payload bytes  Payload
    struct TrTransferMessageRequestDto {
        uint gasLimit;
        bytes payload;
    }

    /// Initializator initiate transfer request DTO
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param transferHash bytes32  Transfer hash
    /// @param txId uint  Transaction ID
    /// @param relay address  Relay address
    /// @param transferResultNotifyFlag bool  Transfer result notification flag
    /// @param feeToken address  Token address for paying relay fee (Chainlink for example)
    struct IzInitTransferRequestDto {
        uint64 dstChainId;
        uint dstAddress;
        bytes32 transferHash;
        uint txId;
        address relay;
        bool transferResultNotifyFlag;
        address feeToken;
    }

    /// Initializator receive payload request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param gasLimit uint  Gas limit
    /// @param txId uint  Transaction ID
    /// @param transferHash bytes32  Transfer hash
    struct IzReceivePayloadRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint gasLimit;
        uint txId;
        bytes32 transferHash;
    }

    /// Initializator retry payload request DTO
    /// @param srcChainId uint64  Source chain ID
    /// @param srcAddress uint  Source address
    /// @param dstChainId uint64  Destination chain ID
    /// @param dstAddress uint  Destination address
    /// @param nonce uint  Nonce
    /// @param gasLimit uint  Gas limit
    /// @param forceOrder bool  Force order flag
    /// @param isEncrypted bool  User encryption flag
    /// @param transferHash bytes32  Transfer hash
    /// @param payload bytes  Payload
    struct IzRetryPayloadRequestDto {
        uint64 srcChainId;
        uint srcAddress;
        uint64 dstChainId;
        uint dstAddress;
        uint nonce;
        uint gasLimit;
        bool forceOrder;
        bool useEncryption;
        bytes32 transferHash;
        bytes payload;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAsterizmEnv.sol";

interface IClientReceiverContract is IAsterizmEnv {

    /// Receive payload from initializer
    /// @param _dto IzAsterizmReceiveRequestDto  Method DTO
    function asterizmIzReceive(IzAsterizmReceiveRequestDto calldata _dto) external;

    /// Receive payload from client server
    /// @param _srcChainId uint64  Source chain ID
    /// @param _srcAddress uint  Source address
    /// @param _txId uint  Transaction ID
    /// @param _transferHash bytes32  Transfer hash
    /// @param _payload bytes  Payload
    function asterizmClReceive(uint64 _srcChainId, uint _srcAddress, uint _txId, bytes32 _transferHash, bytes calldata _payload) external;

    /// Transfer sending result notification
    /// @param _transferHash bytes32  Transfer hash
    /// @param _statusCode uint8  Status code
    function transferSendingResultNotification(bytes32 _transferHash, uint8 _statusCode) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAsterizmEnv.sol";

/// Initializer sender interface
interface IInitializerSender is IAsterizmEnv {

    /// Initiate asterizm transfer
    /// @param _dto IzInitTransferRequestDto  Method DTO
    function initTransfer(IzInitTransferRequestDto calldata _dto) external payable;

    /// Validate income transfer by hash
    /// @param _transferHash bytes32
    function validIncomeTransferHash(bytes32 _transferHash) external view returns(bool);

    /// Return local chain id
    /// @return uint64
    function getLocalChainId() external view returns(uint64);

    /// Return chain type by id
    /// @param _chainId  Chain id
    /// @return uint8  Chain type
    function getChainType(uint64 _chainId) external view returns(uint8);

    /// Resend failed by fee amount transfer
    /// @param _transferHash bytes32  Transfer hash
    /// @param _relay address  Relay address
    function resendTransfer(bytes32 _transferHash, address _relay) external payable;

    /// Return fee amount in tokens
    /// @param _relayAddress  Relay address
    /// @param _dto IzInitTransferV2RequestDto  Method DTO
    /// @return uint  Token fee amount
    function getFeeAmountInTokens(address _relayAddress, IzInitTransferRequestDto calldata _dto) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library AddressLib {

    /// Convert address to uint (uint256) format
    /// @param _address address
    /// @return uint
    function toUint(address _address) internal pure returns(uint) {
        return uint(uint160(_address));
    }

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library AsterizmHashLib {

    /// Build asterizm simple hash (used for transfer within same network types)
    /// @param _packed bytes
    /// @return bytes32
    function buildSimpleHash(bytes memory _packed) internal pure returns(bytes32) {
        return sha256(_packed);
    }

    /// Build asterizm crosschain hash (used for transfer within different network types)
    /// @param _packed bytes
    /// @return bytes32
    function buildCrosschainHash(bytes memory _packed) internal pure returns(bytes32) {
        bytes memory staticChunk = new bytes(112);
        for (uint i = 0; i < 112; i++) {
            staticChunk[i] = bytes(_packed)[i];
        }

        bytes memory payloadChunk = new bytes(_packed.length - staticChunk.length);
        for (uint i = staticChunk.length; i < _packed.length; i++) {
            payloadChunk[i - staticChunk.length] = bytes(_packed)[i];
        }

        uint length = payloadChunk.length;
        uint8 chunkLength = 127;

        bytes32 hash = sha256(staticChunk);

        for (uint i = 0; i <= length / chunkLength; i++) {
            uint from = chunkLength * i;
            uint to = from + chunkLength <= length ? from + chunkLength : length;
            bytes memory chunk = new bytes(to - from);
            for(uint j = from; j < to; j++){
                chunk[j - from] = bytes(payloadChunk)[j];
            }

            hash = sha256(abi.encode(hash, sha256(chunk)));
        }

        return hash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library UintLib {

    /// Convert uint (uint256) to address format
    /// @param _val uint
    /// @return uint
    function toAddress(uint _val) internal pure returns(address) {
        return address(uint160(_val));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "asterizmprotocol/contracts/evm/AsterizmClientUpgradeable.sol";

contract GasStationUpgradeableV1 is AsterizmClientUpgradeable {

    using SafeERC20 for IERC20;
    using UintLib for uint;
    using AddressLib for address;

    event CoinsReceivedEvent(uint _amount, uint _transactionId, address _dstAddress);
    event GasSendEvent(uint64 _dstChainId, uint _transactionId, bytes _payload);
    event AddStableCoinEvent(address _address);
    event RemoveStableCoinEvent(address _address);
    event SetMinUsdAmountEvent(uint _amount);
    event SetMaxUsdAmountEvent(uint _amount);
    event SetMinUsdAmountPerChainEvent(uint _amount);
    event SetMaxUsdAmountPerChainEvent(uint _amount);

    struct StableCoin {
        bool exists;
        uint8 decimals;
    }

    mapping(address => StableCoin) public stableCoins;
    uint public minUsdAmount;
    uint public maxUsdAmount;
    uint public minUsdAmountPerChain;
    uint public maxUsdAmountPerChain;

    /// Initializing function for upgradeable contracts (constructor)
    /// @param _initializerLib IInitializerSender  Initializer library address
    function initialize(IInitializerSender _initializerLib) initializer public {
        __AsterizmClientUpgradeable_init(_initializerLib, false, true);
    }


    /// Add stable coin
    /// @param _tokenAddress address  Token address
    function addStableCoin(address _tokenAddress) external onlyOwner {
        (bool success, bytes memory result) = _tokenAddress.call(abi.encodeWithSignature("decimals()"));
        require(success, "GasStation: decimals request failed");

        stableCoins[_tokenAddress].decimals = abi.decode(result, (uint8));
        stableCoins[_tokenAddress].exists = true;

        emit AddStableCoinEvent(_tokenAddress);
    }

    /// Remove stable coin
    /// @param _tokenAddress address  Token address
    function removeStableCoin(address _tokenAddress) external onlyOwner {
        delete stableCoins[_tokenAddress];
        emit RemoveStableCoinEvent(_tokenAddress);
    }

    /// Set minimum amount in USD
    /// @param _amount uint  Amount
    function setMinUsdAmount(uint _amount) external onlyOwner {
        minUsdAmount = _amount;
        emit SetMinUsdAmountEvent(_amount);
    }

    /// Set maximum amount in USD
    /// @param _amount uint  Amount
    function setMaxUsdAmount(uint _amount) external onlyOwner {
        maxUsdAmount = _amount;
        emit SetMaxUsdAmountEvent(_amount);
    }

    /// Set minimum amount in USD per chain
    /// @param _amount uint  Amount
    function setMinUsdAmountPerChain(uint _amount) external onlyOwner {
        minUsdAmountPerChain = _amount;
        emit SetMinUsdAmountPerChainEvent(_amount);
    }

    /// Set maximum amount in USD per chain
    /// @param _amount uint  Amount
    function setMaxUsdAmountPerChain(uint _amount) external onlyOwner {
        maxUsdAmountPerChain = _amount;
        emit SetMaxUsdAmountPerChainEvent(_amount);
    }

    /// Send gas logic
    /// @param _chainIds uint64[]  Chains IDs
    /// @param _amounts uint[]  Amounts
    /// @param _receivers uint[]  Receivers
    /// @param _token IERC20  Token
    function sendGas(uint64[] memory _chainIds, uint[] memory _amounts, uint[] memory _receivers, IERC20 _token) external nonReentrant {
        address tokenAddress = address(_token);
        require(stableCoins[tokenAddress].exists, "GasStation: wrong token");

        uint tokenDecimals = 10 ** stableCoins[tokenAddress].decimals;
        uint sum;
        for (uint i = 0; i < _amounts.length; i++) {
            if (minUsdAmountPerChain > 0) {
                uint amountInUsd = _amounts[i] / tokenDecimals;
                require(amountInUsd >= minUsdAmountPerChain, "GasStation: minimum amount per chain validation error");
            }
            if (maxUsdAmountPerChain > 0) {
                uint amountInUsd = _amounts[i] / tokenDecimals;
                require(amountInUsd <= maxUsdAmountPerChain, "GasStation: maximum amount per chain validation error");
            }

            sum += _amounts[i];
        }

        require(sum > 0, "GasStation: wrong amounts");
        {
            uint sumInUsd = sum / tokenDecimals;
            require(sumInUsd > 0, "GasStation: wrong amounts in USD");
            if (minUsdAmount > 0) {
                require(sumInUsd >= minUsdAmount, "GasStation: minimum amount validation error");
            }
            if (maxUsdAmount > 0) {
                require(sumInUsd <= maxUsdAmount, "GasStation: maximum amount validation error");
            }
        }

        _token.safeTransferFrom(msg.sender, owner(), sum);
        for (uint i = 0; i < _amounts.length; i++) {
            uint txId = _getTxId();
            bytes memory payload = abi.encode(_receivers[i], _amounts[i], txId, tokenAddress.toUint(), stableCoins[tokenAddress].decimals);
            _initAsterizmTransferEvent(_chainIds[i], payload);
            emit GasSendEvent(_chainIds[i], txId, payload);
        }
    }

    /// Receive payload
    /// @param _dto ClAsterizmReceiveRequestDto  Method DTO
    function _asterizmReceive(ClAsterizmReceiveRequestDto memory _dto) internal override {
        (uint dstAddressUint, uint amount, uint txId , uint tokenAddressUint, uint8 decimals, uint stableRate) = abi.decode(_dto.payload, (uint, uint, uint, uint, uint8, uint));
        require(
            _validTransferHash(
                _dto.srcChainId, _dto.srcAddress, _dto.dstChainId, _dto.dstAddress, _dto.txId,
                abi.encode(dstAddressUint, amount, txId, tokenAddressUint, decimals),
                _dto.transferHash
            ),
            "GasStation: transfer hash is invalid"
        );

        address dstAddress = dstAddressUint.toAddress();
        uint amountToSend = amount * stableRate / (10 ** decimals);
        if (dstAddress != address(this)) {
            (bool success, ) = dstAddress.call{value: amountToSend}("");
            require(success, "GasStation: transfer error");
        }

        emit CoinsReceivedEvent(amountToSend, _dto.txId, dstAddress);
    }

    /// Build packed payload (abi.encodePacked() result)
    /// @param _payload bytes  Default payload (abi.encode() result)
    /// @return bytes  Packed payload (abi.encodePacked() result)
    function _buildPackedPayload(bytes memory _payload) internal pure override returns(bytes memory) {
        (uint dstAddressUint, uint amount, uint txId , uint tokenAddressUint, uint8 decimals) = abi.decode(_payload, (uint, uint, uint, uint, uint8));

        return abi.encodePacked(dstAddressUint, amount, txId, tokenAddressUint, decimals);
    }
}