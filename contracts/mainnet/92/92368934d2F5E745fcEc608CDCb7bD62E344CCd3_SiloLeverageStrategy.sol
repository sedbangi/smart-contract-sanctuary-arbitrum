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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFlashLoans {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

interface ICamelot {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;
  function getAmountsOut(uint amountIn, address[] calldata path) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;

interface IERC20Extended {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IFactorLeverageVault {
    function isRegisteredUpgrade(
        address baseImplementation,
        address upgradeImplementation
    ) external view returns (bool);

    function registerUpgrade(address baseImplementation, address upgradeImplementation) external;

    function createPosition(address asset, address debt) external returns (uint256 id, address vault);

    function assets(address) external view returns (address);

    function asset() external view returns (address);

    function debtToken() external view returns (address);

    function assetBalance() external view returns (uint256);

    function debtBalance() external view returns (uint256);

    function leverageFee() external view returns (uint256);

    function debts(address) external view returns (address);

    function claimRewardFee() external view returns (uint256);

    function version() external view returns (string memory);

    function feeRecipient() external view returns (address);

    function FEE_SCALE() external view returns (uint256);

    function positions(uint256) external view returns (address);

    function initialize(uint256, address, address, address, address, address) external;

    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILeverageStrategy {
    function vaultManager() external view returns (address);

    function positionId() external view returns (uint256);

    function asset() external view returns (address);

    function debtToken() external view returns (address);

    function assetPool() external view returns (address);

    function debtPool() external view returns (address);

    function assetBalance() external returns (uint256);

    function debtBalance() external returns (uint256);

    function owner() external view returns (address);

    function addLeverage(uint256 amount, uint256 debt, bytes calldata data) external;

    function removeLeverage(uint256 amount, bytes calldata data) external;

    function closeLeverage(uint256 amount, bytes calldata data) external;

    function supply(uint256 withdraw) external;

    function borrow(uint256 debt) external;

    function repay(uint256 amount) external;

    function withdraw(uint256 withdraw) external;

    function version() external returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.17;
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenOceanCaller {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    function makeCall(CallDescription memory desc) external;

    function makeCalls(CallDescription[] memory desc) external payable;
}

interface IOpenOceanExchange {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 guaranteedAmount;
        uint256 flags;
        address referrer;
        bytes permit;
    }

    function swap(
        IOpenOceanCaller caller,
        SwapDescription calldata desc,
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISiloStrategy {
    struct AssetStorage {
        /// @dev Token that represents a share in totalDeposits of Silo
        address collateralToken;
        /// @dev Token that represents a share in collateralOnlyDeposits of Silo
        address collateralOnlyToken;
        /// @dev Token that represents a share in totalBorrowAmount of Silo
        address debtToken;
        /// @dev COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        /// It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        /// @dev COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can be ONLY used
        /// as collateral. These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        /// @dev DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
    }

    function assetStorage(address _asset) external view returns (AssetStorage memory);

    function deposit(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 collateralAmount, uint256 collateralShare);

    function withdraw(
        address _asset,
        uint256 _amount,
        bool _collateralOnly
    ) external returns (uint256 withdrawnAmount, uint256 withdrawnShare);

    function borrow(address _asset, uint256 _amount) external returns (uint256 debtAmount, uint256 debtShare);

    function repay(address _asset, uint256 _amount) external returns (uint256 repaidAmount, uint256 burnedShare);

    function accrueInterest(address _asset) external;
}

interface ISiloLens {
    function depositAPY(ISiloStrategy _silo, address _asset) external view returns (uint256);

    function totalDepositsWithInterest(address _silo, address _asset) external view returns (uint256 _totalDeposits);

    function totalBorrowAmountWithInterest(
        address _silo,
        address _asset
    ) external view returns (uint256 _totalBorrowAmount);

    function collateralBalanceOfUnderlying(
        address _silo,
        address _asset,
        address _user
    ) external view returns (uint256);

    function debtBalanceOfUnderlying(address _silo, address _asset, address _user) external view returns (uint256);

    function balanceOfUnderlying(
        uint256 _assetTotalDeposits,
        address _shareToken,
        address _user
    ) external view returns (uint256);

    function calculateCollateralValue(address _silo, address _user, address _asset) external view returns (uint256);

    function calculateBorrowValue(
        address _silo,
        address _user,
        address _asset,
        uint256,
        uint256
    ) external view returns (uint256);

    function totalBorrowAmount(address _silo, address _asset) external view returns (uint256);
}

interface ISiloIncentiveController {
    function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);

    function getUserUnclaimedRewards(address user) external view returns (uint256);
}

interface ISiloRepository {
    function isSiloPaused(address _silo, address _asset) external view returns (bool);

    function getSilo(address _asset) external view returns (address);
}

interface ISiloToken {
    function silo() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import { ISiloStrategy, ISiloIncentiveController, ISiloRepository } from '../interfaces/ISiloStrategy.sol';
import { ICamelot } from '../interfaces/ICamelot.sol';
import { IFlashLoans } from '../interfaces/balancer/IFlashLoans.sol';

error INVALID_TOKEN();
error NOT_SELF();

library SiloReward {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    // Silo
    address public constant provider = 0x8658047e48CC09161f4152c79155Dac1d710Ff0a; //Silo Repository
    address public constant siloIncentive = 0x4999873bF8741bfFFB0ec242AAaA7EF1FE74FCE8; // Silo Incenctive
    address public constant siloIncentiveSTIP = 0xd592F705bDC8C1B439Bd4D665Ed99C4FaAd5A680; // Silo STIP ARB

    address public constant siloToken = 0x0341C0C0ec423328621788d4854119B97f44E391; // Silo Token
    address public constant arb = 0x912CE59144191C1204E64559FE8253a0e49E6548; // Arb Token

    // Camelot
    address public constant camelotRouter = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;

    // WETH
    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    /// @notice Claims the specified reward token from the given incentive contract and charges a fee.
    /// @param incentiveContractAddress The address of the incentive contract to claim rewards from.
    /// @param rewardToken The token address of the reward to be claimed.
    /// @param fee The fee percentage to be charged on the claimed rewards.
    /// @param feeScale The scale to calculate the actual fee amount (typically 10000 for percentages).
    /// @param recipient The address receiving the fee.
    /// @return The net amount of reward tokens claimed after deducting the fee.
    function claimReward(
        address incentiveContractAddress,
        address rewardToken,
        uint256 fee,
        uint256 feeScale,
        address recipient
    ) public returns (uint256) {
        address[] memory assets = new address[](1);
        assets[0] = rewardToken;
        ISiloIncentiveController(incentiveContractAddress).claimRewards(assets, type(uint256).max, address(this));

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 feeCharge = rewardFeeCharge(balance, rewardToken, fee, feeScale, recipient);
        IERC20(rewardToken).safeTransfer(msg.sender, balance - feeCharge);

        return balance - feeCharge;
    }

    /// @notice Claims rewards, swaps them to a specified asset, and then supplies the asset to a pool.
    /// @param incentiveContractAddress The address of the incentive contract to claim rewards from.
    /// @param rewardToken The token address of the reward to be claimed.
    /// @param asset The asset token to swap the rewards into and supply to the pool.
    /// @param fee The fee percentage to be charged on the claimed rewards.
    /// @param feeScale The scale to calculate the actual fee amount.
    /// @param recipient The address receiving the fee.
    /// @param amountOutMin The minimum amount expected from the swap operation.
    /// @param poolAddress The address of the pool where the asset will be supplied.
    /// @return The net amount of reward tokens claimed after the swap and fee deduction.
    function claimRewardsSupply(
        address incentiveContractAddress,
        address rewardToken,
        address asset,
        uint256 fee,
        uint256 feeScale,
        address recipient,
        uint256 amountOutMin,
        address poolAddress
    ) public returns (uint256) {
        address[] memory assets = new address[](1);
        assets[0] = rewardToken;
        ISiloIncentiveController(incentiveContractAddress).claimRewards(assets, type(uint256).max, address(this));

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 feeCharge = rewardFeeCharge(balance, rewardToken, fee, feeScale, recipient);
        uint256 netBalance = balance - feeCharge;

        if (netBalance > 0) {
            // Swap to asset
            IERC20(rewardToken).approve(camelotRouter, netBalance);
            swapToken(rewardToken, asset, netBalance, amountOutMin);

            // Supply
            IERC20(asset).approve(poolAddress, IERC20(asset).balanceOf(address(this)));
            ISiloStrategy(poolAddress).deposit(asset, IERC20(asset).balanceOf(address(this)), false);
        }
        return netBalance;
    }

    /// @notice Claims rewards, swaps them to a specified debt token, and then uses them to repay debt.
    /// @param incentiveContractAddress The address of the incentive contract to claim rewards from.
    /// @param rewardToken The token address of the reward to be claimed.
    /// @param debtToken The debt token to swap the rewards into for repayment.
    /// @param fee The fee percentage to be charged on the claimed rewards.
    /// @param feeScale The scale to calculate the actual fee amount.
    /// @param recipient The address receiving the fee.
    /// @param amountOutMin The minimum amount expected from the swap operation.
    /// @param poolAddress The address of the pool where the debt will be repaid.
    /// @return The net amount of reward tokens claimed after the swap and fee deduction.
    function claimRewardsRepay(
        address incentiveContractAddress,
        address rewardToken,
        address debtToken,
        uint256 fee,
        uint256 feeScale,
        address recipient,
        uint256 amountOutMin,
        address poolAddress
    ) public returns (uint256) {
        address[] memory assets = new address[](1);
        assets[0] = rewardToken;
        ISiloIncentiveController(incentiveContractAddress).claimRewards(assets, type(uint256).max, address(this));

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 feeCharge = rewardFeeCharge(balance, rewardToken, fee, feeScale, recipient);
        uint256 netBalance = balance - feeCharge;

        if (netBalance > 0) {
            // Swap to debtToken
            IERC20(rewardToken).approve(camelotRouter, netBalance);
            swapToken(rewardToken, debtToken, netBalance, amountOutMin);

            // Repay
            uint256 amount = IERC20(debtToken).balanceOf(address(this));
            IERC20(debtToken).approve(poolAddress, amount);
            ISiloStrategy(poolAddress).repay(debtToken, amount);
        }
        return netBalance;
    }

    /// @notice Calculates and transfers a fee based on the specified parameters.
    /// @dev This function is internal and used to handle fee deductions for various reward claiming operations.
    /// @param amount The total amount from which the fee is to be calculated.
    /// @param token The address of the token on which the fee is being charged.
    /// @param fee The fee percentage to be charged.
    /// @param feeScale The scale used for fee calculation, typically a value like 10000 for percentages.
    /// @param recipient The address that will receive the fee.
    /// @return depositFeeAmount The calculated fee amount that has been transferred to the recipient.
    function rewardFeeCharge(
        uint256 amount,
        address token,
        uint256 fee,
        uint256 feeScale,
        address recipient
    ) internal returns (uint256) {
        uint256 depositFeeAmount = amount.mul(fee).div(feeScale);
        IERC20(token).safeTransfer(recipient, depositFeeAmount);
        return depositFeeAmount;
    }

    /**
     * @notice Swaps tokens using the provided path.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The amount of input tokens to be swapped.
     * @param _amountOutMin The minimum amount of out tokens to be swapped.
     */
    function swapToken(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) internal {
        address[] memory path;

        if (_tokenOut == weth) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = weth;
            path[2] = _tokenOut;
        }

        ICamelot(camelotRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            address(0),
            block.timestamp
        );
    }

    // =============================================================
    //                 Helpers
    // =============================================================

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 numerator = share * totalAmount;
        uint256 result = numerator / totalShares;

        // Round up
        if (numerator % totalShares != 0) {
            result += 1;
        }

        return result;
    }

    // =============================================================
    //                  Supply, Borrow, Repay, Withdraw
    // =============================================================

    function supply(address asset, uint256 amount, address poolAddress) public returns (uint256) {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // supply
        IERC20(asset).approve(poolAddress, amount);
        ISiloStrategy(poolAddress).deposit(asset, amount, false);

        return amount;
    }

    function borrow(address debtToken, uint256 amount, address poolAddress) public returns (uint256) {
        ISiloStrategy(poolAddress).borrow(debtToken, amount);
        IERC20(debtToken).transfer(msg.sender, amount);
        return amount;
    }

    function repay(address debtToken, uint256 amount, address poolAddress) public returns (uint256) {
        IERC20(debtToken).transferFrom(msg.sender, address(this), amount);

        IERC20(debtToken).approve(poolAddress, amount);
        ISiloStrategy(poolAddress).repay(debtToken, amount);

        return amount;
    }

    function withdraw(address asset, address assetPool, uint256 amount, address poolAddress) public returns (uint256) {
        IERC20(assetPool).approve(poolAddress, amount);
        ISiloStrategy(poolAddress).withdraw(asset, amount, false);
        IERC20(asset).transfer(msg.sender, amount);

        return amount;
    }

    function withdrawTokenInCaseStuck(
        address tokenAddress,
        uint256 amount,
        address assetPool,
        address debtPool
    ) public returns (address, uint256) {
        if (tokenAddress == assetPool || tokenAddress == debtPool) revert INVALID_TOKEN();
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);

        return (tokenAddress, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IOpenOceanExchange, IOpenOceanCaller } from '../../interfaces/IOpenOceanExchange.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library OpenOceanAggregator {
    // =============================================================
    //                         Errors
    // =============================================================

    error WRONG_TOKEN_IN(); // 0xf6b8648c
    error WRONG_TOKEN_OUT(); // 0x5e8f1f5b
    error WRONG_AMOUNT(); // 0xc6ea1a16
    error WRONG_DST(); // 0xcb0b65a6
    error SWAP_ERROR(); // 0xcbe60bba
    error SWAP_METHOD_NOT_IDENTIFIED(); // 0xc257a710

    // =============================================================
    //                        Constants
    // =============================================================

    address constant router = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;

    // =============================================================
    //                        Functions
    // =============================================================

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        bytes calldata data
    ) public returns (uint256 outAmount) {
        IERC20(tokenIn).approve(address(router), amount);

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        bytes4 method = _getMethod(data);

        // swap
        if (
            method ==
            bytes4(
                keccak256(
                    'swap(address,(address,address,address,address,uint256,uint256,uint256,uint256,address,bytes),(uint256,uint256,uint256,bytes)[])'
                )
            )
        ) {
            (, IOpenOceanExchange.SwapDescription memory desc, ) = abi.decode(
                data[4:],
                (IOpenOceanCaller, IOpenOceanExchange.SwapDescription, IOpenOceanCaller.CallDescription[])
            );

            if (tokenIn != address(desc.srcToken)) revert WRONG_TOKEN_IN();
            if (tokenOut != address(desc.dstToken)) revert WRONG_TOKEN_OUT();
            if (amount != desc.amount) revert WRONG_AMOUNT();
            if (address(this) != desc.dstReceiver) revert WRONG_DST();

            _callOpenOcean(data);
        }
        // uniswapV3SwapTo
        else if (method == bytes4(keccak256('uniswapV3SwapTo(address,uint256,uint256,uint256[])'))) {
            (address recipient, uint256 swapAmount, , ) = abi.decode(data[4:], (address, uint256, uint256, uint256[]));
            if (address(this) != recipient) revert WRONG_DST();
            if (amount != swapAmount) revert WRONG_AMOUNT();

            _callOpenOcean(data);
        }
        // callUniswapTo
        else if (method == bytes4(keccak256('callUniswapTo(address,uint256,uint256,bytes32[],address)'))) {
            (address srcToken, uint256 swapAmount, , , address recipient) = abi.decode(
                data[4:],
                (address, uint256, uint256, bytes32[], address)
            );
            if (tokenIn != srcToken) revert WRONG_TOKEN_IN();
            if (amount != swapAmount) revert WRONG_AMOUNT();
            if (address(this) != recipient) revert WRONG_DST();

            _callOpenOcean(data);
        } else {
            revert SWAP_METHOD_NOT_IDENTIFIED();
        }

        return IERC20(tokenOut).balanceOf(address(this)) - balanceBefore;
    }

    function _getMethod(bytes memory data) internal pure returns (bytes4 method) {
        assembly {
            method := mload(add(data, add(32, 0)))
        }
    }

    function _callOpenOcean(bytes memory data) internal {
        (bool success, bytes memory result) = address(router).call(data);
        if (!success) {
            if (result.length < 68) revert SWAP_ERROR();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// inheritances
import { ILeverageStrategy } from '../../interfaces/ILeverageStrategy.sol';
import { IFlashLoanRecipient } from '../../interfaces/balancer/IFlashLoanRecipient.sol';
import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { UUPSUpgradeable } from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

// libraries
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { OpenOceanAggregator } from '../../libraries/swap/OpenOceanAggregator.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import { SiloReward } from '../../libraries/SiloReward.sol';

// interfaces
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC20Extended } from '../../interfaces/IERC20Extended.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IFlashLoans } from '../../interfaces/balancer/IFlashLoans.sol';
import { ISiloStrategy, ISiloLens, ISiloIncentiveController, ISiloToken, ISiloRepository } from '../../interfaces/ISiloStrategy.sol';
import { IFactorLeverageVault } from '../../interfaces/IFactorLeverageVault.sol';

contract SiloLeverageStrategy is
    Initializable,
    ILeverageStrategy,
    IFlashLoanRecipient,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // =============================================================
    //                         Libraries
    // =============================================================

    using SafeERC20 for IERC20;
    using Math for uint256;
    using SafeMath for uint256;

    // =============================================================
    //                         Enum
    // =============================================================

    enum RewardType {
        Silo,
        Arb
    }

    // =============================================================
    //                         Events
    // =============================================================

    event LeverageAdded(uint256 amount, uint256 debt);
    event LeverageRemoved(uint256 debt);
    event LeverageClosed(uint256 amount, uint256 debt);
    event AssetSwitched(address newAsset, uint256 balance);
    event DebtSwitched(address newDebt, uint256 balance);
    event Withdraw(uint256 amount);
    event Repay(uint256 amount);
    event Supply(uint256 amount);
    event Borrow(uint256 amount);
    event WithdrawTokenInCaseStuck(address tokenAddress, uint256 amount);
    event RewardClaimed(uint256 amount, address token);
    event RewardClaimedSupply(uint256 amount, address token);
    event RewardClaimedRepay(uint256 amount, address token);
    event LeverageChargeFee(uint256 amount);

    // =============================================================
    //                         Errors
    // =============================================================

    error NOT_OWNER();
    error NOT_BALANCER();
    error NOT_SELF();
    error INVALID_ASSET();
    error INVALID_DEBT();
    error INVALID_TOKEN();
    error AMOUNT_TOO_MUCH();

    // =============================================================
    //                         Constants
    // =============================================================
    // Silo
    address public constant provider = 0x8658047e48CC09161f4152c79155Dac1d710Ff0a; //Silo Repository
    address public constant siloIncentive = 0x4999873bF8741bfFFB0ec242AAaA7EF1FE74FCE8; // Silo Incenctive
    address public constant siloToken = 0x0341C0C0ec423328621788d4854119B97f44E391; // Silo Token
    address public constant siloLens = 0x07b94eB6AaD663c4eaf083fBb52928ff9A15BE47; // Silo Lens

    // balancer
    address public constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    // WETH
    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // =============================================================
    //                         Storages
    // =============================================================

    uint256 private _positionId;

    IERC721 private _vaultManager;

    IERC20 private _asset;

    IERC20 private _debtToken;

    IERC20 public _assetPool;

    IERC20 public _debtPool;

    uint8 private flMode; // 1 = addLeverage, 2 = removeLeverage, 3 = switch asset, 4 = switch debt, 5 = close leverage

    // =============================================================
    //                      Functions
    // =============================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 __positionId,
        address _vaultManagerAddress,
        address _assetAddress,
        address _debtAddress,
        address _assetPoolAddress,
        address _debtPoolAddress
    ) public initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _positionId = __positionId;
        _vaultManager = IERC721(_vaultManagerAddress);
        _asset = IERC20(_assetAddress);
        _debtToken = IERC20(_debtAddress);
        _assetPool = IERC20(_assetPoolAddress);
        _debtPool = IERC20(_debtPoolAddress);
    }

    function vaultManager() public view returns (address) {
        return address(_vaultManager);
    }

    function positionId() public view returns (uint256) {
        return _positionId;
    }

    function asset() public view returns (address) {
        return address(_asset);
    }

    function debtToken() public view returns (address) {
        return address(_debtToken);
    }

    function assetPool() public view returns (address) {
        return address(_assetPool);
    }

    function debtPool() public view returns (address) {
        return address(_debtPool);
    }

    function assetBalance() public view returns (uint256) {
        address poolAddress = ISiloToken(assetPool()).silo();

        return
            ISiloLens(siloLens).balanceOfUnderlying(
                ISiloLens(siloLens).totalDepositsWithInterest(poolAddress, asset()),
                assetPool(),
                address(this)
            );
    }

    function debtBalance() public view returns (uint256) {
        address poolAddress = ISiloToken(debtPool()).silo();

        return
            ISiloLens(siloLens).balanceOfUnderlying(
                ISiloLens(siloLens).totalBorrowAmountWithInterest(poolAddress, debtToken()),
                debtPool(),
                address(this)
            );
    }

    function owner() public view returns (address) {
        return _vaultManager.ownerOf(_positionId);
    }

    function addLeverage(uint256 amount, uint256 debt, bytes calldata data) external onlyOwner {
        // process = flashloan the expected debt -> swap the expected debt to asset -> supply the asset -> borrow to repay the flashloan
        address poolAddress = ISiloToken(assetPool()).silo();

        if (amount > 0) {
            IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);

            // supply
            IERC20(asset()).approve(poolAddress, amount);
            ISiloStrategy(poolAddress).deposit(asset(), amount, false);
        }

        if (debt > 0) {
            // execute flashloan
            bytes memory params = abi.encode(debt, poolAddress, data);
            address[] memory tokens = new address[](1);
            tokens[0] = debtToken();
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = debt;
            flMode = 1;
            IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
            flMode = 0;
        }

        emit LeverageAdded(amount, debt);
    }

    function _flAddLeverage(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (uint256 amount, address poolAddress, bytes memory data) = abi.decode(params, (uint256, address, bytes));

        // swap debt to asset
        // the only solution to convert from memory to calldata
        uint256 outAmountDebt = this.swapBySelf(debtToken(), asset(), amount, data);

        // supply
        IERC20(asset()).approve(poolAddress, outAmountDebt);
        ISiloStrategy(poolAddress).deposit(asset(), outAmountDebt, false);

        // borrow
        ISiloStrategy(poolAddress).borrow(debtToken(), amount + feeAmount);

        // repay debt Flashloan
        IERC20(debtToken()).safeTransfer(balancerVault, amount + feeAmount);
    }

    function removeLeverage(uint256 amount, bytes calldata data) external onlyOwner {
        // process = flashloan to repay all debt -> withdraw the asset -> swap the asset -> borrow to repay the flashloan

        address poolAddress = ISiloToken(assetPool()).silo();

        ISiloStrategy(poolAddress).accrueInterest(debtToken());

        uint256 repayAmount = _getRepayAmount(poolAddress);

        // execute flashloan
        bytes memory params = abi.encode(amount, repayAmount, poolAddress, data);
        address[] memory tokens = new address[](1);
        tokens[0] = debtToken();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = repayAmount;

        flMode = 2;
        IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
        flMode = 0;

        // transfer to owner
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        IERC20(asset()).safeTransfer(owner(), balance);

        emit LeverageRemoved(amount);
    }

    function _flRemoveLeverage(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (uint256 amount, uint256 repayAmount, address poolAddress, bytes memory data) = abi.decode(
            params,
            (uint256, uint256, address, bytes)
        );

        // repay
        IERC20(debtToken()).approve(poolAddress, repayAmount);
        ISiloStrategy(poolAddress).repay(debtToken(), repayAmount);

        // withdraw
        ISiloStrategy(poolAddress).withdraw(asset(), amount, false);

        // swap asset to debt
        uint256 outAmount = this.swapBySelf(asset(), debtToken(), amount, data);

        // you can't swap asset more than debt value
        if (outAmount > repayAmount) revert AMOUNT_TOO_MUCH();

        uint256 remainingFlashLoanAmount = repayAmount - _debtToken.balanceOf(address(this));

        // borrow
        ISiloStrategy(poolAddress).borrow(debtToken(), remainingFlashLoanAmount + feeAmount);

        // repay debt Flashloan
        IERC20(debtToken()).safeTransfer(balancerVault, repayAmount + feeAmount);
    }

    function switchAsset(address newAsset, uint256 amount, bytes calldata data) external onlyOwner {
        // process = flashloan to repay all debt -> withdraw all asset -> swap the asset to a new asset -> supply the new asset -> borrow to repay the flashloan

        // check if newAsset exist
        if (IFactorLeverageVault(vaultManager()).assets(newAsset) == address(0)) revert INVALID_ASSET();

        address poolAddress = ISiloToken(assetPool()).silo();

        ISiloStrategy(poolAddress).accrueInterest(debtToken());

        uint256 repayAmount = _getRepayAmount(poolAddress);

        // execute flashloan
        bytes memory params = abi.encode(newAsset, repayAmount, amount, poolAddress, data);
        address[] memory tokens = new address[](1);
        tokens[0] = debtToken();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = repayAmount;

        flMode = 3;
        IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
        flMode = 0;
    }

    function _flSwitchAsset(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (address newAsset, uint256 repayAmount, uint256 amount, address poolAddress, bytes memory data) = abi.decode(
            params,
            (address, uint256, uint256, address, bytes)
        );

        // repay all debt
        IERC20(debtToken()).approve(poolAddress, repayAmount);
        ISiloStrategy(poolAddress).repay(debtToken(), repayAmount);

        // withdraw all
        ISiloStrategy(poolAddress).withdraw(asset(), type(uint256).max, false);

        // swap asset to new asset
        this.swapBySelf(asset(), newAsset, amount, data);
        // change asset and pool to new one
        _asset = IERC20(newAsset);
        _assetPool = IERC20(IFactorLeverageVault(vaultManager()).assets(newAsset));

        // supply the new asset
        IERC20(asset()).approve(poolAddress, IERC20(asset()).balanceOf(address(this)));
        ISiloStrategy(poolAddress).deposit(asset(), IERC20(asset()).balanceOf(address(this)), false);

        // borrow
        ISiloStrategy(poolAddress).borrow(debtToken(), repayAmount + feeAmount);

        // repay debt Flashloan
        IERC20(debtToken()).safeTransfer(balancerVault, repayAmount + feeAmount);

        emit AssetSwitched(newAsset, assetBalance());
    }

    function switchDebt(address newDebtToken, uint256 newDebt, bytes calldata data) external onlyOwner {
        // process = flashloan to repay all debt -> borrow a new debt -> swap the new debt to repay the flash loan

        // check if newDebtToken exist
        if (IFactorLeverageVault(vaultManager()).debts(newDebtToken) == address(0)) revert INVALID_DEBT();

        address poolAddress = ISiloToken(assetPool()).silo();

        ISiloStrategy(poolAddress).accrueInterest(debtToken());

        uint256 repayAmount = _getRepayAmount(poolAddress);

        // execute flashloan
        bytes memory params = abi.encode(newDebtToken, repayAmount, newDebt, poolAddress, data);
        address[] memory tokens = new address[](1);
        tokens[0] = debtToken();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = repayAmount;

        flMode = 4;
        IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
        flMode = 0;
    }

    function _flSwitchDebt(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (address newDebtToken, uint256 repayAmount, uint256 newDebt, address poolAddress, bytes memory data) = abi
            .decode(params, (address, uint256, uint256, address, bytes));
        address oldDebtToken = debtToken();

        // repay all debt
        IERC20(debtToken()).approve(poolAddress, repayAmount);
        ISiloStrategy(poolAddress).repay(debtToken(), repayAmount);

        _debtToken = IERC20(newDebtToken);
        _debtPool = IERC20(IFactorLeverageVault(vaultManager()).debts(newDebtToken));

        // borrow
        ISiloStrategy(poolAddress).borrow(debtToken(), newDebt + feeAmount);

        // swap new debt to flashloan
        this.swapBySelf(debtToken(), oldDebtToken, IERC20(_debtToken).balanceOf(address(this)), data);

        // repay Flashloan
        IERC20(oldDebtToken).safeTransfer(balancerVault, repayAmount + feeAmount);

        emit DebtSwitched(newDebtToken, assetBalance());
    }

    function closeLeverage(uint256 amount, bytes calldata data) external onlyOwner {
        // process = flashloan to repay all debt -> withdraw all asset -> swap the asset to repay the flash loan

        // notes: if amount > debt value then the all position become debtToken
        // for example, when wstETH/USDC closes the leverage can be withdrawn as wstETH or USDC
        address poolAddress = ISiloToken(assetPool()).silo();

        ISiloStrategy(poolAddress).accrueInterest(debtToken());

        uint256 repayAmount = _getRepayAmount(poolAddress);

        // execute flashloan
        bytes memory params = abi.encode(amount, repayAmount, poolAddress, data);
        address[] memory tokens = new address[](1);
        tokens[0] = debtToken();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = repayAmount;

        flMode = 5;
        IFlashLoans(balancerVault).flashLoan(address(this), tokens, amounts, params);
        flMode = 0;

        uint256 closedAsset = IERC20(asset()).balanceOf(address(this));
        uint256 closedDebt = IERC20(debtToken()).balanceOf(address(this));

        // transfer asset & debt token to owner
        IERC20(asset()).safeTransfer(owner(), closedAsset);
        IERC20(debtToken()).safeTransfer(owner(), closedDebt);

        emit LeverageClosed(closedAsset, closedDebt);
    }

    function _flCloseLeverage(bytes calldata params, uint256 feeAmount) internal {
        // decode params
        (uint256 amount, uint256 repayAmount, address poolAddress, bytes memory data) = abi.decode(
            params,
            (uint256, uint256, address, bytes)
        );

        // repay
        IERC20(debtToken()).approve(poolAddress, repayAmount);
        ISiloStrategy(poolAddress).repay(debtToken(), repayAmount);

        ISiloStrategy(poolAddress).withdraw(asset(), type(uint256).max, false);

        // swap asset to debt
        this.swapBySelf(asset(), debtToken(), amount, data);

        // repay debt Flashloan
        IERC20(debtToken()).safeTransfer(balancerVault, repayAmount + feeAmount);
    }

    function swapBySelf(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        bytes calldata data
    ) public returns (uint256) {
        if (msg.sender != address(this)) revert NOT_SELF();
        uint256 outAmount = OpenOceanAggregator.swap(tokenIn, tokenOut, amount, data);
        uint256 feeCharge = leverageFeeCharge(outAmount, tokenOut);
        return outAmount - feeCharge;
    }

    function leverageFeeCharge(uint256 amount, address token) internal returns (uint256) {
        uint256 leverageFee = IFactorLeverageVault(vaultManager()).leverageFee();
        uint256 feeScale = IFactorLeverageVault(vaultManager()).FEE_SCALE();
        address factorFeeRecipient = IFactorLeverageVault(vaultManager()).feeRecipient();
        uint256 depositFeeAmount = amount.mul(leverageFee).div(feeScale);

        IERC20(token).safeTransfer(factorFeeRecipient, depositFeeAmount);

        emit LeverageChargeFee(depositFeeAmount);

        return depositFeeAmount;
    }

    function _getRepayAmount(address poolAddress) internal view returns (uint256) {
        uint256 repayShare = _debtPool.balanceOf(address(this));
        uint256 debtTokenTotalSupply = _debtPool.totalSupply();
        uint256 totalBorrowed = ISiloLens(siloLens).totalBorrowAmount(poolAddress, debtToken());

        return toAmountRoundUp(repayShare, totalBorrowed, debtTokenTotalSupply);
    }

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        return SiloReward.toAmountRoundUp(share, totalAmount, totalShares);
    }

    function supply(uint256 amount) external onlyOwner {
        SiloReward.supply(asset(), amount, getPoolAddress());
        emit Supply(amount);
    }

    function borrow(uint256 amount) external onlyOwner {
        SiloReward.borrow(debtToken(), amount, getPoolAddress());
        emit Borrow(amount);
    }

    function repay(uint256 amount) external onlyOwner {
        SiloReward.repay(debtToken(), amount, getPoolAddress());
        emit Repay(amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        SiloReward.withdraw(asset(), assetPool(), amount, getPoolAddress());
        emit Withdraw(amount);
    }

    function getPoolAddress() internal view returns (address) {
        return ISiloToken(assetPool()).silo();
    }

    function withdrawTokenInCaseStuck(address tokenAddress, uint256 amount) external onlyOwner {
        SiloReward.withdrawTokenInCaseStuck(tokenAddress, amount, assetPool(), debtPool());

        emit WithdrawTokenInCaseStuck(tokenAddress, amount);
    }

    /// @notice Claims rewards based on the specified reward type.
    /// @param rewardType The type of reward to claim (Silo or Arb).
    /// @dev Emits the RewardClaimed event upon successful execution.
    ///      Reverts if an invalid reward type is specified.
    function claimRewards(RewardType rewardType) external onlyOwner {
        (uint256 fee, uint256 feeScale, address factorFeeRecipient) = _getVaultDetails();

        if (rewardType == RewardType.Silo) {
            uint256 transferredAmount = SiloReward.claimReward(
                SiloReward.siloIncentive,
                SiloReward.siloToken,
                fee,
                feeScale,
                factorFeeRecipient
            );
            emit RewardClaimed(transferredAmount, SiloReward.siloToken);
        } else if (rewardType == RewardType.Arb) {
            uint256 transferredAmount = SiloReward.claimReward(
                SiloReward.siloIncentiveSTIP,
                SiloReward.arb,
                fee,
                feeScale,
                factorFeeRecipient
            );
            emit RewardClaimed(transferredAmount, SiloReward.arb);
        } else {
            revert('Invalid reward type');
        }
    }

    /// @notice Claims supply rewards based on the specified reward type and supplies them to a pool.
    /// @param rewardType The type of reward to claim (Silo or Arb).
    /// @param amountOutMin The minimum amount of out tokens expected to be received when swapping.
    /// @dev Emits the RewardClaimedSupply event upon successful execution.
    ///      Reverts if an invalid reward type is specified.
    function claimRewardsSupply(RewardType rewardType, uint256 amountOutMin) external onlyOwner {
        (uint256 fee, uint256 feeScale, address factorFeeRecipient, address poolAddress) = _getVaultAndPoolDetails();

        address incentiveContractAddress;
        address rewardToken;

        if (rewardType == RewardType.Silo) {
            incentiveContractAddress = SiloReward.siloIncentive;
            rewardToken = SiloReward.siloToken;
        } else if (rewardType == RewardType.Arb) {
            incentiveContractAddress = SiloReward.siloIncentiveSTIP;
            rewardToken = SiloReward.arb;
        } else {
            revert('Invalid reward type');
        }

        uint256 transferredAmount = SiloReward.claimRewardsSupply(
            incentiveContractAddress,
            rewardToken,
            asset(),
            fee,
            feeScale,
            factorFeeRecipient,
            amountOutMin,
            poolAddress
        );

        emit RewardClaimedSupply(transferredAmount, rewardToken);
    }

    /// @notice Claims repay rewards based on the specified reward type and uses them to repay debt.
    /// @param rewardType The type of reward to claim (Silo or Arb).
    /// @param amountOutMin The minimum amount of out tokens expected to be received when swapping.
    /// @dev Emits the RewardClaimedRepay event upon successful execution.
    ///      Reverts if an invalid reward type is specified.
    function claimRewardsRepay(RewardType rewardType, uint256 amountOutMin) external onlyOwner {
        (uint256 fee, uint256 feeScale, address factorFeeRecipient, address poolAddress) = _getVaultAndPoolDetails();

        address incentiveContractAddress;
        address rewardToken;

        if (rewardType == RewardType.Silo) {
            incentiveContractAddress = SiloReward.siloIncentive;
            rewardToken = SiloReward.siloToken;
        } else if (rewardType == RewardType.Arb) {
            incentiveContractAddress = SiloReward.siloIncentiveSTIP;
            rewardToken = SiloReward.arb;
        } else {
            revert('Invalid reward type');
        }
        uint256 transferredAmount = SiloReward.claimRewardsRepay(
            incentiveContractAddress,
            rewardToken,
            debtToken(),
            fee,
            feeScale,
            factorFeeRecipient,
            amountOutMin,
            poolAddress
        );
        emit RewardClaimedRepay(transferredAmount, rewardToken);
    }

    function _getVaultDetails() internal view returns (uint256 fee, uint256 feeScale, address factorFeeRecipient) {
        IFactorLeverageVault vault = IFactorLeverageVault(vaultManager());
        fee = vault.claimRewardFee();
        feeScale = vault.FEE_SCALE();
        factorFeeRecipient = vault.feeRecipient();
    }

    function _getVaultAndPoolDetails()
        internal
        view
        returns (uint256 fee, uint256 feeScale, address factorFeeRecipient, address poolAddress)
    {
        (fee, feeScale, factorFeeRecipient) = _getVaultDetails();
        poolAddress = ISiloToken(assetPool()).silo();
    }

    function version() external pure returns (string memory) {
        return '0.3';
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes calldata params
    ) external override nonReentrant {
        if (msg.sender != balancerVault) revert NOT_BALANCER();
        uint256 feeAmount = 0;
        if (feeAmounts.length > 0) {
            feeAmount = feeAmounts[0];
        }
        if (flMode == 1) _flAddLeverage(params, feeAmount);
        if (flMode == 2) _flRemoveLeverage(params, feeAmount);
        if (flMode == 3) _flSwitchAsset(params, feeAmount);
        if (flMode == 4) _flSwitchDebt(params, feeAmount);
        if (flMode == 5) _flCloseLeverage(params, feeAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        // check if the new implementation is registered
        if (IFactorLeverageVault(vaultManager()).isRegisteredUpgrade(_getImplementation(), newImplementation) == false)
            revert('INVALID_UPGRADE');
    }

    // =============================================================
    //                      modifiers
    // =============================================================

    modifier onlyOwner() {
        if (msg.sender != _vaultManager.ownerOf(_positionId)) revert NOT_OWNER();
        _;
    }
}