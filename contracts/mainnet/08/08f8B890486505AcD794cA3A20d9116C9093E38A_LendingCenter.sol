// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface LendingDelegate {
    function getLendingIdList(
        uint8 _t,
        uint256 start,
        uint256 end
    ) external view returns (uint256[] memory);

    function insertLendingOrder(
        uint256 _annualInterestRate,
        uint8 _t,
        uint256 _lendingId,
        address lender
    ) external;

    function removeLendingOrder(
        uint256 _annualInterestRate,
        uint8 _t,
        uint256 _lendingId
    ) external;

    function insertBorrowOrder(
        uint256 _lendingId,
        uint256 _borrowId,
        address _borrower
    ) external;

    function fixList(uint256 _start) external;
}

interface LendingPriceManager {
    function getPrice() external view returns (uint256);

    function swapSell(
        uint256 amount,
        uint256 borrowedAmount
    ) external returns (uint256 dstAmount, uint256 srcAmount);
}

uint256 constant DEN = 10000;
uint256 constant ONE_DAY = 86400;
uint256 constant YEAR = ONE_DAY * 365;
uint256 constant CYCLE_30_DAY = ONE_DAY * 30;
uint256 constant CYCLE_60_DAY = ONE_DAY * 60;
uint256 constant CYCLE_90_DAY = ONE_DAY * 90;

contract LendingCenter is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    address public borrowToken;
    address public pledgeToken;

    struct RateConfig {
        // 质押率
        uint256 pledgeRate;
        // 平仓线
        uint256 clearanceRate;
        // 预警线
        uint256 reminderRate;
    }

    struct LendingOrder {
        // 放贷id
        uint256 id;
        // 放贷USDT数量
        uint256 lendingAmount;
        // 可成交的数量
        uint256 loanableAmount;
        // USDT剩余量
        uint256 borrowBalance;
        // 放贷营收
        uint256 interestIncome;
        // 已领取的放贷营收
        uint256 claimedIncome;
        // 手续费年化利率
        uint32 annualInterestRate;
        // 放贷周期（秒）
        uint256 cycle;
        // 订单发起时间
        uint256 startTime;
        // 订单实际结束放贷时间
        uint256 endTime;
        // 订单创建者地址
        address lender;
        // 是否打烊
        bool isClosed;
    }

    struct BorrowOrder {
        // 借贷id
        uint256 id;
        // 放贷id
        uint256 lendingId;
        // 借USDT数量
        uint256 borrowedAmount;
        // 质押LP数量
        uint256 pledgedAmount;
        // 利息
        uint256 interestExpense;
        // 借出方收益
        uint256 interestIncome;
        // 平台费
        uint256 platformFee;
        // LP价格
        uint256 pledgedTokenPrice;
        // 触发清算的价格
        uint256 clearanceLine;
        // 触发预警的价格
        uint256 reminderLine;
        // 借贷时间
        uint256 startTime;
        // 实际还款时间
        uint256 finishTime;
        // 借款方
        address borrower;
    }

    // 逾期
    uint256 deferredRpaymentTime = 86400;

    // 借贷周期 => 借贷配置
    mapping(uint256 => RateConfig) public CYCLE_RATE_CONFIG;

    mapping(address => uint256) public lendingAmount;
    mapping(address => uint256) public borrowAmount;
    mapping(address => uint256) public pledgeAmount;

    uint256 public autoLendingOrderId;
    mapping(uint256 => LendingOrder) public lendingOrders;

    uint256 public autoBorrowOrderId;
    mapping(uint256 => BorrowOrder) public borrowOrders;

    uint256 public totalPlatformFee;
    address public exchequer;

    address public delegate;
    address public priceManager;
    address public gate;
    uint256 public lendingBorrowMin;

    event LendingOrderCreate(
        // 订单id
        uint256 indexed id,
        // 订单创建者地址
        address indexed lender,
        // 放贷USDT
        uint256 lendingAmount,
        // 可成交的数量
        uint256 loanableAmount,
        // 订单USDT余额
        uint256 borrowBalance,
        // 放贷利息年利率
        uint32 annualInterestRate,
        // 放贷周期（秒）
        uint256 cycle,
        // 创建时间
        uint256 startTime
    );
    event LendingOrderWithdraw(
        // 订单id
        uint256 indexed id,
        // 订单创建者地址
        address indexed lender,
        // 提现USDT数量
        uint256 withdrawAmount,
        // 提现后可成交的数量
        uint256 loanableAmount,
        // 提现后订单USDT余额
        uint256 borrowBalance,
        // 订单是否打烊
        bool isClosed
    );
    event LendingOrderBorrow(
        // 订单id
        uint256 indexed id,
        // 借贷后可成交的数量
        uint256 loanableAmount,
        // 借贷后订单USDT余额
        uint256 borrowBalance,
        // 订单是否打烊
        bool isClosed
    );
    event LendingOrderRepay(
        // 订单id
        uint256 indexed id,
        // 订单创建者地址
        address indexed lender,
        // 还款后订单USDT余额
        uint256 borrowBalance,
        // 收到的利息
        uint256 amount,
        // 收到利息后的订单总利息
        uint256 interestIncome
    );
    event LendingOrderClaimedIncome(
        // 订单id
        uint256 indexed id,
        // 订单创建者地址
        address indexed lender,
        // 当前领取的数量
        uint256 amount,
        // 该订单累计领取的数量
        uint256 claimedIncome
    );

    event BorrowOrderCreate(
        // 借贷订单id
        uint256 indexed id,
        // 借贷地址
        address indexed borrower,
        // 对应的放贷订单id
        uint256 indexed lendingId,
        // 借贷USDT的数量
        uint256 borrowedAmount,
        // 抵押lp的数量
        uint256 pledgedAmount,
        // 利息年化率
        uint32 annualInterestRate,
        // 借贷周期（秒）
        uint256 cycle,
        // 利息
        uint256 interestExpense,
        // 生成订单时的lp价格（？？？USDT/LP）
        uint256 pledgedTokenPrice,
        // 触发清算的价格
        uint256 clearanceLine,
        // 触发预警的价格
        uint256 reminderLine
    );
    event BorrowOrderRepay(
        // 借贷id
        uint256 indexed id,
        // 借贷地址
        address indexed borrower,
        // 放贷id
        uint256 indexed lendingId,
        // 放贷者的收益
        uint256 interestIncome,
        // 平台收益
        uint256 platformFee
    );
    event BorrowOrderLiquidation(
        // 借贷id
        uint256 indexed id,
        // 借贷地址
        address indexed borrower,
        // 放贷id
        uint256 indexed lendingId,
        // 放贷者的收益
        uint256 interestIncome,
        // 平台收益
        uint256 platformFee
    );

    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

    function initialize(
        address _borrowToken,
        address _pledgeToken
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        borrowToken = _borrowToken;
        pledgeToken = _pledgeToken;

        CYCLE_RATE_CONFIG[CYCLE_30_DAY] = RateConfig(5000, 6000, 7000);
        CYCLE_RATE_CONFIG[CYCLE_60_DAY] = RateConfig(5000, 6000, 7000);
        CYCLE_RATE_CONFIG[CYCLE_90_DAY] = RateConfig(5000, 6000, 7000);

        lendingBorrowMin = 100 * (10 ** ERC20(borrowToken).decimals());
    }

    function setDelegate(address _delegate) external onlyOwner {
        delegate = _delegate;
    }

    function setPriceManager(address _priceManager) external onlyOwner {
        priceManager = _priceManager;
    }

    function setGate(address _gate) external onlyOwner {
        gate = _gate;
    }

    function setExchequer(address _exchequer) external onlyOwner {
        exchequer = _exchequer;
    }

    modifier onlyGate() {
        require(gate == msg.sender, "dev: caller is not the gate");
        _;
    }

    function CYCLE(uint8 _cycleType) internal pure returns (uint256) {
        if (_cycleType == 0) {
            return CYCLE_30_DAY;
        } else if (_cycleType == 1) {
            return CYCLE_60_DAY;
        } else if (_cycleType == 2) {
            return CYCLE_90_DAY;
        }
        return 0;
    }

    function CYCLE_TYPE(uint256 _cycle) internal pure returns (uint8) {
        if (_cycle == CYCLE_30_DAY) {
            return 0;
        } else if (_cycle == CYCLE_60_DAY) {
            return 1;
        } else if (_cycle == CYCLE_90_DAY) {
            return 2;
        }
        return 0;
    }

    function makeLendingOrderInfo(
        address _account,
        uint8 _cycleType,
        uint256 _amount,
        uint32 _annualInterestRate
    ) external view returns (LendingOrder memory) {
        uint256 _cycle = CYCLE(_cycleType);
        LendingOrder memory result;
        if (_cycle == 0) return result;
        result.lendingAmount = _amount;
        result.loanableAmount = _amount;
        result.borrowBalance = _amount;
        result.annualInterestRate = _annualInterestRate;
        result.cycle = _cycle;
        result.startTime = block.timestamp;
        result.lender = _account;
        result.interestIncome =
            (((_amount * _annualInterestRate) / DEN) * _cycle) /
            YEAR;
        return result;
    }

    function createLendingOrder(
        address _account,
        uint8 _cycleType,
        uint256 _amount,
        uint32 _annualInterestRate
    ) external nonReentrant onlyGate {
        LendingOrder memory order = this.makeLendingOrderInfo(
            _account,
            _cycleType,
            _amount,
            _annualInterestRate
        );
        order.interestIncome = 0;

        TransferHelper.safeTransferFrom(
            borrowToken,
            msg.sender,
            address(this),
            _amount
        );
        lendingAmount[_account] += _amount;

        order.id = autoLendingOrderId;
        lendingOrders[order.id] = order;
        autoLendingOrderId++;

        // 插入数据
        if (delegate != address(0))
            LendingDelegate(delegate).insertLendingOrder(
                order.annualInterestRate,
                _cycleType,
                order.id,
                order.lender
            );

        emit LendingOrderCreate(
            order.id,
            order.lender,
            order.lendingAmount,
            order.loanableAmount,
            order.borrowBalance,
            order.annualInterestRate,
            order.cycle,
            order.startTime
        );
    }

    function withdraw(
        address _account,
        uint256 _lendingId,
        uint256 _amount
    ) external nonReentrant onlyGate {
        LendingOrder storage order = lendingOrders[_lendingId];
        require(_account == order.lender, "borrow: rror lendingId");
        require(_amount > 0, "borrow: The value cannot be 0");
        require(order.borrowBalance >= _amount, "borrow: Insufficient surplus");

        TransferHelper.safeTransfer(borrowToken, _account, _amount);
        order.borrowBalance -= _amount;
        order.loanableAmount = order.loanableAmount > _amount
            ? (order.loanableAmount - _amount)
            : 0;
        if (order.borrowBalance < lendingBorrowMin) {
            order.isClosed = true;

            // 插入数据
            if (delegate != address(0))
                LendingDelegate(delegate).removeLendingOrder(
                    order.annualInterestRate,
                    CYCLE_TYPE(order.cycle),
                    order.id
                );
        }

        emit LendingOrderWithdraw(
            order.id,
            order.lender,
            _amount,
            order.loanableAmount,
            order.borrowBalance,
            order.isClosed
        );
    }

    function getClaimedIncome(
        address _account,
        uint256 _lendingId
    ) external view onlyGate returns (uint256) {
        LendingOrder storage order = lendingOrders[_lendingId];
        require(_account == order.lender, "borrow: error lendingId");
        return order.claimedIncome;
    }

    function getClaimableIncome(
        address _account,
        uint256 _lendingId
    ) external view onlyGate returns (uint256) {
        LendingOrder storage order = lendingOrders[_lendingId];
        require(_account == order.lender, "borrow: error lendingId");
        return (order.interestIncome - order.claimedIncome);
    }

    function claimeIncome(
        address _account,
        uint256 _lendingId
    ) external nonReentrant onlyGate {
        LendingOrder storage order = lendingOrders[_lendingId];
        require(_account == order.lender, "borrow: error lendingId");

        uint256 amount = order.interestIncome - order.claimedIncome;
        require(amount > 0, "borrow: underdraw");

        TransferHelper.safeTransfer(borrowToken, _account, amount);
        order.claimedIncome = order.interestIncome;

        emit LendingOrderClaimedIncome(
            order.id,
            order.lender,
            order.claimedIncome,
            amount
        );
    }

    function forecastPledgedAmount(
        uint256 _lendingId,
        uint256 _amount
    ) external view returns (uint256) {
        LendingOrder storage order = lendingOrders[_lendingId];
        uint256 price = LendingPriceManager(priceManager).getPrice();
        uint256 _pledgedAmount = (((_amount * 1e18) / price) * DEN) /
            CYCLE_RATE_CONFIG[order.cycle].pledgeRate;
        return _pledgedAmount;
    }

    // 借款
    function borrow(
        address _account,
        uint256 _lendingId,
        uint256 _amount,
        uint256 _pledgeAmount
    ) external nonReentrant onlyGate {
        LendingOrder storage order = lendingOrders[_lendingId];
        require(order.isClosed == false, "borrow: is closed");
        require(
            _amount < lendingBorrowMin,
            "borrow: Less than the minimum borrowing requirement"
        );
        require(
            order.loanableAmount >= _amount,
            "borrow: Insufficient surplus"
        );
        uint256 price = LendingPriceManager(priceManager).getPrice();
        uint256 _pledgedAmount = (((_amount * 1e18) / price) * DEN) /
            CYCLE_RATE_CONFIG[order.cycle].pledgeRate;

        require(
            _pledgeAmount >= _pledgedAmount,
            "Insufficient amount of pledge"
        );

        TransferHelper.safeTransferFrom(
            pledgeToken,
            msg.sender,
            address(this),
            _pledgeAmount
        );

        BorrowOrder memory borrowOrder;
        borrowOrder.id = autoBorrowOrderId;
        borrowOrder.lendingId = _lendingId;
        borrowOrder.borrowedAmount = _amount;
        borrowOrder.pledgedAmount = _pledgedAmount;
        borrowOrder.interestExpense =
            (((_amount * order.annualInterestRate) / DEN) * order.cycle) /
            YEAR;
        borrowOrder.interestIncome = (borrowOrder.interestExpense * 10) / 8;
        borrowOrder.platformFee =
            borrowOrder.interestExpense -
            borrowOrder.interestIncome;
        borrowOrder.pledgedTokenPrice = price;
        borrowOrder.clearanceLine =
            (price * CYCLE_RATE_CONFIG[order.cycle].clearanceRate) /
            DEN;
        borrowOrder.reminderLine =
            (price * CYCLE_RATE_CONFIG[order.cycle].reminderRate) /
            DEN;
        borrowOrder.startTime = block.timestamp;
        borrowOrder.borrower = _account;

        borrowOrders[borrowOrder.id] = borrowOrder;
        autoBorrowOrderId++;

        order.loanableAmount -= _amount;
        order.borrowBalance -= _amount;

        pledgeAmount[borrowOrder.borrower] += _pledgedAmount;
        TransferHelper.safeTransfer(
            pledgeToken,
            msg.sender,
            _pledgeAmount - _pledgedAmount
        );

        TransferHelper.safeTransfer(
            borrowToken,
            _account,
            (borrowOrder.borrowedAmount - borrowOrder.interestExpense)
        );
        borrowAmount[borrowOrder.borrower] -= borrowOrder.borrowedAmount;

        //插入数据
        if (delegate != address(0))
            LendingDelegate(delegate).insertBorrowOrder(
                order.id,
                borrowOrder.id,
                borrowOrder.borrower
            );

        if (order.borrowBalance < lendingBorrowMin) {
            order.isClosed = true;

            // 插入数据
            if (delegate != address(0))
                LendingDelegate(delegate).removeLendingOrder(
                    order.annualInterestRate,
                    CYCLE_TYPE(order.cycle),
                    order.id
                );
        }

        emit LendingOrderBorrow(
            order.id,
            order.loanableAmount,
            order.borrowBalance,
            order.isClosed
        );

        emit BorrowOrderCreate(
            borrowOrder.id,
            borrowOrder.borrower,
            borrowOrder.lendingId,
            borrowOrder.borrowedAmount,
            borrowOrder.pledgedAmount,
            order.annualInterestRate,
            order.cycle,
            borrowOrder.interestExpense,
            borrowOrder.pledgedTokenPrice,
            borrowOrder.clearanceLine,
            borrowOrder.reminderLine
        );
    }

    function finishBorrowOrder(uint256 _borrowId) internal {
        BorrowOrder storage borrowOrder = borrowOrders[_borrowId];
        LendingOrder storage order = lendingOrders[borrowOrder.lendingId];

        borrowOrder.finishTime = block.timestamp;

        order.borrowBalance += borrowOrder.borrowedAmount;
        order.interestIncome += borrowOrder.interestIncome;

        // 平台手续费
        totalPlatformFee += borrowOrder.platformFee;
        TransferHelper.safeTransfer(
            borrowToken,
            exchequer,
            borrowOrder.platformFee
        );

        //插入数据
        if (delegate != address(0))
            LendingDelegate(delegate).insertBorrowOrder(
                order.id,
                borrowOrder.id,
                borrowOrder.borrower
            );
    }

    // 还款
    function repay(
        address _account,
        uint256 _borrowId
    ) external nonReentrant onlyGate {
        BorrowOrder storage borrowOrder = borrowOrders[_borrowId];
        LendingOrder storage order = lendingOrders[borrowOrder.lendingId];

        require(_account == borrowOrder.borrower, "Personal operation only");

        TransferHelper.safeTransferFrom(
            borrowToken,
            msg.sender,
            address(this),
            borrowOrder.borrowedAmount
        );
        borrowAmount[borrowOrder.borrower] += borrowOrder.borrowedAmount;

        TransferHelper.safeTransfer(
            pledgeToken,
            borrowOrder.borrower,
            borrowOrder.pledgedAmount
        );
        pledgeAmount[borrowOrder.borrower] += borrowOrder.pledgedAmount;

        finishBorrowOrder(borrowOrder.id);

        emit LendingOrderRepay(
            order.id,
            order.lender,
            order.borrowBalance,
            borrowOrder.interestIncome,
            order.interestIncome
        );

        emit BorrowOrderRepay(
            borrowOrder.id,
            borrowOrder.borrower,
            borrowOrder.lendingId,
            borrowOrder.interestIncome,
            borrowOrder.platformFee
        );
    }

    // 清算平仓
    function liquidation(uint256 _borrowId) external nonReentrant onlyGate {
        BorrowOrder storage borrowOrder = borrowOrders[_borrowId];
        LendingOrder storage order = lendingOrders[borrowOrder.lendingId];

        uint256 price = LendingPriceManager(priceManager).getPrice();
        require(price <= borrowOrder.clearanceLine, "error");

        TransferHelper.safeApprove(
            pledgeToken,
            priceManager,
            borrowOrder.pledgedAmount
        );
        (
            uint256 borrowTokenAmount,
            uint256 residualPledgedAmount
        ) = LendingPriceManager(priceManager).swapSell(
                borrowOrder.pledgedAmount,
                borrowOrder.borrowedAmount
            );
        require(
            borrowTokenAmount >= borrowOrder.interestExpense,
            "The price is too low"
        );
        TransferHelper.safeTransfer(
            borrowToken,
            exchequer,
            borrowTokenAmount - borrowOrder.interestExpense
        );
        TransferHelper.safeTransfer(
            pledgeToken,
            borrowOrder.borrower,
            residualPledgedAmount
        );
        finishBorrowOrder(borrowOrder.id);

        emit LendingOrderRepay(
            order.id,
            order.lender,
            order.borrowBalance,
            borrowOrder.interestIncome,
            order.interestIncome
        );

        emit BorrowOrderLiquidation(
            borrowOrder.id,
            borrowOrder.borrower,
            borrowOrder.lendingId,
            borrowOrder.interestIncome,
            borrowOrder.platformFee
        );
    }
}