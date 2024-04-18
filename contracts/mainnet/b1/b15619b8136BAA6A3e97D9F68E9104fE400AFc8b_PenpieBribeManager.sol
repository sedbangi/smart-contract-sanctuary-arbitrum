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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
pragma solidity ^0.8.19;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import "../interfaces/IPendleVoteManager.sol";
import "../libraries/math/Math.sol";

/// @title PenpieBribeManager
/// @notice Penpie bribe manager is used to manage market pools for voting and bribing.
///         This contract allows us to add and remove pools for Pendle market tokens.
///         When bribes are added, the tokens will be separated with a fee and transferred
///         to the distributor contract and the fee collector.
///         To save on gas fees, we will save all bribe tokens in each pool using a unique
///         index for pools and bribe tokens for each epoch (or round), instead of using nested mappings.
///         At the end of each epoch, we will retrieve the total bribes from this contract
///         and aggregate the voting results using subgraph querying.
///         We will calculate rewards for each user who has voted, package the distribution
///         using the merkleTree structure, and import it into the distributor contract.
///         This will allow users to claim their rewards from the distributor contract.
///
/// @author Penpie Team
contract PenpieBribeManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /* ============ Structs ============ */

    struct Pool {
        address _market;
        bool _active;
        uint256 _chainId;
    }

    struct Bribe {
        address _token;
        uint256 _amount;
    }

    struct PoolVotes {
        address _bribe;
        uint256 _votes;
    }

    /* ============ State Variables ============ */

    address constant NATIVE = address(1);
    uint256 constant DENOMINATOR = 10000;

    address public voteManager;
    address payable public distributor;
    address payable private feeCollector;
    uint256 public feeRatio;
    uint256 public maxBribingBatch;

    uint256 public epochPeriod;
    uint256 public epochStartTime;
    uint256 private currentEpoch;

    Pool[] public pools;
    mapping(address => uint256) public marketToPid;
    mapping(address => uint256) public unCollectedFee;

    address[] public allowedTokens;
    mapping(address => bool) public allowedToken;
    mapping(bytes32 => Bribe) public bribes;  // The index is hashed based on the epoch, pid and token address
    mapping(bytes32 => bytes32[]) public bribesInPool;  // Mapping pool => bribes. The index is hashed based on the epoch, pid
    mapping(address => bool) public allowedOperator;

    /* ============ 1st upgrade for vePendle bribing ============ */

    address payable public distributorForVePendle;
    mapping(bytes32 => Bribe) public bribesForVePendle;
    mapping(bytes32 => bytes32[]) public bribesInPoolForVePendle;
    uint256 public pnpBribingRatio;

    /* ============ Events ============ */

    event NewBribe(address indexed _user, uint256 indexed _epoch, uint256 _pid, address _bribeToken, uint256 _amount);
    event NewBribeForVePendle(address indexed _user, uint256 indexed _epoch, uint256 _pid, address _bribeToken, uint256 _amount);
    event NewPool(address indexed _market, uint256 _chainId);
    event EpochPushed(uint256 indexed _epoch, uint256 _startTime);
    event EpochForcePushed(uint256 indexed _epoch, uint256 _startTime);
    event UpdateOperatorStatus(address indexed _user, bool _status);
    event BribeReallocated(
        uint256 indexed _pid,
        address indexed _token,
        uint256 _epochFrom,
        uint256 _epochTo,
        uint256 _amount
    );

    /* ============ Errors ============ */

    error InvalidPool();
    error InvalidBribeToken();
    error ZeroAddress();
    error ZeroAmount();
    error PoolOccupied();
    error InvalidEpoch();
    error OnlyNotInEpoch();
    error OnlyInEpoch();
    error InvalidTime();
    error InvalidBatch();
    error OnlyOperator();
    error MarketExists();
    error NativeTransferFailed();
    error InsufficientAmount();

    /* ============ Constructor ============ */

    function __PenpieBribeManager_init(
        address _voteManager,
        uint256 _epochPeriod,
        uint256 _feeRatio
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        voteManager = _voteManager;
        epochPeriod = _epochPeriod;
        feeRatio = _feeRatio;
        maxBribingBatch = 8;
        currentEpoch = 0;
        allowedOperator[owner()] = true;
    }

    /* ============ Modifiers ============ */

    modifier onlyOperator() {
        if (!allowedOperator[msg.sender]) revert OnlyOperator();
        _;
    }    

    /* ============ External Getters ============ */

    function exactCurrentEpoch() public view returns (uint256) {
        if (epochStartTime == 0) return 0;

        uint256 epochEndTime = epochStartTime + epochPeriod;
        if (block.timestamp > epochEndTime)
            return currentEpoch + 1;
        else
            return currentEpoch;
    }

    function getCurrentEpochEndTime() public view returns(uint256 endTime) {
        endTime = epochStartTime + epochPeriod;
    }

    function getApprovedTokens() public view returns(address[] memory) {
        return allowedTokens;
    }

    function getPoolLength() public view returns(uint256) {
        return pools.length;
    }

    /// @notice this function could make havey gas cost, please prevent to call this in non-view functions
    function getBribesInAllPools(uint256 _epoch) external view returns (Bribe[][] memory) {
        Bribe[][] memory rewards = new Bribe[][](pools.length);
        for (uint256 i = 0; i < pools.length; i++){
            rewards[i] = getBribesInPool(_epoch, i);
        }
        return rewards;
    }

    function getBribesInPool(uint256 _epoch, uint256 _pid) public view returns (Bribe[] memory) {
        if (_pid >= getPoolLength()) revert InvalidPool();
        
        bytes32 poolIdentifier = _getPoolIdentifier(_epoch, _pid);

        bytes32[] memory poolBribes = bribesInPool[poolIdentifier];
        Bribe[] memory rewards = new Bribe[](poolBribes.length);

        for (uint256 i = 0; i < poolBribes.length; i++) {
            rewards[i] = bribes[poolBribes[i]];
        }

        return rewards;
    }

    function getBribesInAllPoolsForVePendle(uint256 _epoch) external view returns (Bribe[][] memory) {
        Bribe[][] memory rewards = new Bribe[][](pools.length);
        for (uint256 i = 0; i < pools.length; i++){
            rewards[i] = getBribesInPoolForVePendle(_epoch, i);
        }
        return rewards;
    }

    function getBribesInPoolForVePendle(uint256 _epoch, uint256 _pid) public view returns (Bribe[] memory) {
        if (_pid >= getPoolLength()) revert InvalidPool();
        
        bytes32 poolIdentifier = _getPoolIdentifier(_epoch, _pid);

        bytes32[] memory poolBribes = bribesInPoolForVePendle[poolIdentifier];
        Bribe[] memory rewards = new Bribe[](poolBribes.length);

        for (uint256 i = 0; i < poolBribes.length; i++) {
            rewards[i] = bribesForVePendle[poolBribes[i]];
        }

        return rewards;
    }

    /* ============ External Functions ============ */

    function addBribeNative(uint256 _batch, uint256 _pid, bool _forPreviousEpoch) external payable nonReentrant whenNotPaused {
        _addBribeNative(_batch, _pid, _forPreviousEpoch, false);
    }

    function addBribeERC20(uint256 _batch, uint256 _pid, address _token, uint256 _amount, bool _forPreviousEpoch) external nonReentrant whenNotPaused {
        _addBribeERC20(_batch, _pid, _token, _amount, _forPreviousEpoch, false);
    }

    function addBribeNativeForVePendle(uint256 _batch, uint256 _pid, bool _forPreviousEpoch) external payable nonReentrant whenNotPaused {
        _addBribeNative(_batch, _pid, _forPreviousEpoch, true);
    }

    function addBribeERC20ForVePendle(uint256 _batch, uint256 _pid, address _token, uint256 _amount, bool _forPreviousEpoch) external nonReentrant whenNotPaused {
        _addBribeERC20(_batch, _pid, _token, _amount, _forPreviousEpoch, true);
    }

    function addBribeNativeToEpoch(uint256 _epoch, uint256 _pid, bool forVePendle) external payable nonReentrant whenNotPaused onlyOperator {
        if (_epoch < exactCurrentEpoch() - 1) revert InvalidEpoch();
        if (_pid >= pools.length || !pools[_pid]._active) revert InvalidPool();

        bool successNativeTransfer;
        uint256 bribeForVlPNP = msg.value;
        uint256 bribeForVePendle;
        uint256 totalFee = 0;

        if (forVePendle) {
            bribeForVlPNP = msg.value * pnpBribingRatio / DENOMINATOR;
            bribeForVePendle = msg.value - bribeForVlPNP;
            if (bribeForVePendle > 0) {
                (uint256 feeForVePendle, uint256 afterFeeForVePendle) = _addBribeForVePendle(_epoch, _pid, NATIVE, bribeForVePendle);
                totalFee += feeForVePendle;
                (successNativeTransfer, )  = distributorForVePendle.call{value: afterFeeForVePendle}("");
                if (!successNativeTransfer) revert NativeTransferFailed();
            }
        }

        (uint256 fee, uint256 afterFee) = _addBribe(_epoch, _pid, NATIVE, bribeForVlPNP);
        totalFee += fee;

        // transfer the token to the target directly in one time to save the gas fee
        if (totalFee > 0) {
            if (feeCollector == address(0)) {
                unCollectedFee[NATIVE] += totalFee;
            } else {
                feeCollector.transfer(totalFee);
            }
        }
        (successNativeTransfer, )  = distributor.call{value: afterFee}("");
        if (!successNativeTransfer) revert NativeTransferFailed();
    }

    function addBribeERC20ToEpoch(uint256 _epoch, uint256 _pid, address _token, uint256 _amount, bool forVePendle) external nonReentrant whenNotPaused onlyOperator {
        if (_epoch < exactCurrentEpoch() - 1) revert InvalidEpoch();
        if (_pid >= pools.length || !pools[_pid]._active) revert InvalidPool();
        if (!allowedToken[_token] && _token != NATIVE) revert InvalidBribeToken();

        uint256 bribeForVlPNP = _amount;
        uint256 bribeForVePendle;
        uint256 totalFee = 0;

        if (forVePendle) {
            bribeForVlPNP = _amount * pnpBribingRatio / DENOMINATOR;
            bribeForVePendle = _amount - bribeForVlPNP;
            if (bribeForVePendle > 0) {
                (uint256 feeForVePendle, uint256 afterFeeForVePendle) = _addBribeForVePendle(_epoch, _pid, _token, bribeForVePendle);
                totalFee += feeForVePendle;
                IERC20(_token).safeTransferFrom(msg.sender, distributorForVePendle, afterFeeForVePendle);
            }
        }

        (uint256 fee, uint256 afterFee) = _addBribe(_epoch, _pid, _token, bribeForVlPNP);
        totalFee += fee;

        // transfer the token to the target directly in one time to save the gas fee
        if (totalFee > 0) {
            if (feeCollector == address(0)) {
                unCollectedFee[_token] += totalFee;
                IERC20(_token).safeTransferFrom(msg.sender, address(this), totalFee);
            } else {
                IERC20(_token).safeTransferFrom(msg.sender, feeCollector, totalFee);
            }
        }
        
        IERC20(_token).safeTransferFrom(msg.sender, distributor, afterFee);
    }

    function pushEpoch(uint256 _time) external onlyOperator {
        epochStartTime = _time;
        currentEpoch ++;

        emit EpochPushed(currentEpoch, _time);
    }

    /* ============ Internal Functions ============ */

    function _getPoolIdentifier(uint256 _epoch, uint256 _pid) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_epoch, _pid)
            );
    }

    function _getTokenIdentifier(uint256 _epoch, uint256 _pid, address _token) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_epoch, _pid, _token)
            );
    }

    function _addBribeNative(uint256 _batch, uint256 _pid, bool _forPreviousEpoch, bool forVePendle) internal {
        if (_batch == 0 || _batch > maxBribingBatch) revert InvalidBatch();
        if (_pid >= pools.length || !pools[_pid]._active) revert InvalidPool();

        uint256 startFromEpoch = exactCurrentEpoch();
        if (startFromEpoch > 0 && _forPreviousEpoch){
            startFromEpoch -= 1;
        }
        uint256 totalFee = 0;
        uint256 totalBribing = 0;
        uint256 totalBribingForVePendle = 0;

        uint256 bribePerEpoch = msg.value / _batch;
        uint256 bribePerEpochForVlPNP = bribePerEpoch;
        uint256 bribePerEpochForVePendle = 0;
        if (forVePendle) {
            bribePerEpochForVlPNP = bribePerEpoch * pnpBribingRatio / DENOMINATOR;
            bribePerEpochForVePendle = bribePerEpoch - bribePerEpochForVlPNP;
        }

        for (uint256 epoch = startFromEpoch; epoch < startFromEpoch + _batch; epoch++) {
            if (forVePendle && bribePerEpochForVePendle > 0) {
                (uint256 feeForVePendle, uint256 afterFeeForVePendle) = _addBribeForVePendle(epoch, _pid, NATIVE, bribePerEpochForVePendle);
                totalFee += feeForVePendle;
                totalBribingForVePendle += afterFeeForVePendle;
            }
            (uint256 fee, uint256 afterFee) = _addBribe(epoch, _pid, NATIVE, bribePerEpochForVlPNP);
            totalFee += fee;
            totalBribing += afterFee;
        }

        // transfer the token to the target directly in one time to save the gas fee
        bool success;
        if (totalFee > 0) {
            if (feeCollector == address(0)) {
                unCollectedFee[NATIVE] += totalFee;
            } else {
                feeCollector.transfer(totalFee);
            }
        }
        (success, )  = distributor.call{value: totalBribing}("");
        if (!success) revert NativeTransferFailed();

        if (forVePendle && totalBribingForVePendle > 0) {
            (success, )  = distributorForVePendle.call{value: totalBribingForVePendle}("");
            if (!success) revert NativeTransferFailed();
        }
    }

    function _addBribeERC20(uint256 _batch, uint256 _pid, address _token, uint256 _amount, bool _forPreviousEpoch, bool forVePendle) internal {
        if (_batch == 0 || _batch > maxBribingBatch) revert InvalidBatch();
        if (_pid >= pools.length || !pools[_pid]._active) revert InvalidPool();
        if (!allowedToken[_token] && _token != NATIVE) revert InvalidBribeToken();

        uint256 startFromEpoch = exactCurrentEpoch();
        if (startFromEpoch > 0 && _forPreviousEpoch){
            startFromEpoch -= 1;
        }
        uint256 totalFee = 0;
        uint256 totalBribing = 0;
        uint256 totalBribingForVePendle = 0;

        uint256 bribePerEpochForVlPNP = _amount / _batch;
        uint256 bribePerEpochForVePendle = 0;
        if (forVePendle) {
            bribePerEpochForVlPNP = (_amount  * pnpBribingRatio) / (_batch * DENOMINATOR );
            bribePerEpochForVePendle = _amount / _batch - bribePerEpochForVlPNP;
        }

        for (uint256 epoch = startFromEpoch; epoch < startFromEpoch + _batch; epoch++) {
            if (forVePendle && bribePerEpochForVePendle > 0) {
                (uint256 feeForVePendle, uint256 afterFeeForVePendle) = _addBribeForVePendle(epoch, _pid, _token, bribePerEpochForVePendle);
                totalFee += feeForVePendle;
                totalBribingForVePendle += afterFeeForVePendle;
            }
            (uint256 fee, uint256 afterFee) = _addBribe(epoch, _pid, _token, bribePerEpochForVlPNP);
            totalFee += fee;
            totalBribing += afterFee;
        }

        // transfer the token to the target directly in one time to save the gas fee
        if (totalFee > 0) {
            if (feeCollector == address(0)) {
                unCollectedFee[_token] += totalFee;
                IERC20(_token).safeTransferFrom(msg.sender, address(this), totalFee);
            } else {
                IERC20(_token).safeTransferFrom(msg.sender, feeCollector, totalFee);
            }
        }
        
        IERC20(_token).safeTransferFrom(msg.sender, distributor, totalBribing);

        if (forVePendle && totalBribingForVePendle > 0) {
            IERC20(_token).safeTransferFrom(msg.sender, distributorForVePendle, totalBribingForVePendle);
        }
    }

    function _addBribe(uint256 _epoch, uint256 _pid, address _token, uint256 _amount) internal returns (uint256 fee, uint256 afterFee) {
        fee = _amount * feeRatio / DENOMINATOR;
        afterFee = _amount - fee;

        // We will generate a unique index for each pool and reward based on the epoch
        bytes32 poolIdentifier = _getPoolIdentifier(_epoch, _pid);
        bytes32 rewardIdentifier = _getTokenIdentifier(_epoch, _pid, _token);

        Bribe storage bribe = bribes[rewardIdentifier];
        bribe._amount += afterFee;
        if(bribe._token == address(0)) {
            bribe._token = _token;
            bribesInPool[poolIdentifier].push(rewardIdentifier);
        }

        emit NewBribe(msg.sender, _epoch, _pid, _token, afterFee);
    }

    function _addBribeForVePendle(uint256 _epoch, uint256 _pid, address _token, uint256 _amount) internal returns (uint256 fee, uint256 afterFee) {
        fee = _amount * feeRatio / DENOMINATOR;
        afterFee = _amount - fee;

        // We will generate a unique index for each pool and reward based on the epoch
        bytes32 poolIdentifier = _getPoolIdentifier(_epoch, _pid);
        bytes32 rewardIdentifier = _getTokenIdentifier(_epoch, _pid, _token);

        Bribe storage bribe = bribesForVePendle[rewardIdentifier];
        bribe._amount += afterFee;
        if(bribe._token == address(0)) {
            bribe._token = _token;
            bribesInPoolForVePendle[poolIdentifier].push(rewardIdentifier);
        }

        emit NewBribeForVePendle(msg.sender, _epoch, _pid, _token, afterFee);
    }

    /* ============ Admin Functions ============ */

    /// @notice this function will create a new pool in the bribeManager and voteManager
    function newPool(address _market, uint16 _chainId) external onlyOwner {
        if (_market == address(0)) revert ZeroAddress();

        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i]._market == _market) {
                revert MarketExists();
            }
        }

        Pool memory pool = Pool(_market, true, _chainId);
        pools.push(pool);

        marketToPid[_market] = pools.length - 1;

        IPendleVoteManager(voteManager).addPool(_market, _chainId);

        emit NewPool(_market, _chainId);
    }

    function removePool(uint256 _pid) external onlyOwner {
        if (_pid >= pools.length) revert InvalidPool();
        pools[_pid]._active = false;
        IPendleVoteManager(voteManager).removePool(_pid);
    }

    function updatePool(uint256 _pid, uint256 _chainId, address _market, bool _active) external onlyOwner {
        Pool storage pool = pools[_pid];
        pool._chainId = _chainId;
        pool._market = _market;
        pool._active = _active;
    }

    function forceSetMarketPID(address _market, uint256 _newPid) external onlyOwner {
        marketToPid[_market] = _newPid;
    }

    function forcePopLastPool() external onlyOwner {
        if (pools.length == 0) revert InvalidPool();
        pools.pop();
    }

    function forcePushEpoch(uint256 _epoch, uint256 _time) external onlyOwner {
        epochStartTime = _time;
        currentEpoch = _epoch;

        emit EpochForcePushed(currentEpoch, _time);
    }

    function setEpochPeriod(uint256 _epochPeriod) external onlyOwner {
        epochPeriod = _epochPeriod;
    }

    function addAllowedTokens(address _token) external onlyOwner {
        if (allowedToken[_token]) revert InvalidBribeToken();

        allowedTokens.push(_token);

        allowedToken[_token] = true;
    }

    function removeAllowedTokens(address _token) external onlyOwner {
        if (!allowedToken[_token]) revert InvalidBribeToken();
        uint256 allowedTokensLength = allowedTokens.length;
        uint256 i = 0;
        while (allowedTokens[i] != _token) {
            i++;
            if (i >= allowedTokensLength) revert InvalidBribeToken();
        }

        allowedTokens[i] = allowedTokens[allowedTokensLength-1];
        allowedTokens.pop();

        allowedToken[_token] = false;
    }

    function updateAllowedOperator(address _user, bool _allowed) external onlyOwner {
        allowedOperator[_user] = _allowed;

        emit UpdateOperatorStatus(_user, _allowed);
    }

    function setDistributor(address payable _distributor) external onlyOwner {
        distributor= _distributor;
    }

    function setFeeCollector(address payable _collector) external onlyOwner {
        feeCollector= _collector;
    }

    function setFeeRatio(uint256 _feeRatio) external onlyOwner {
        feeRatio = _feeRatio;
    }

    function setDistributorForVePendle(address payable _distributorForVePendle) external onlyOwner {
        distributorForVePendle = _distributorForVePendle;
    }

    function setPnpBribingRatio(uint256 _pnpBribingRatio) external onlyOwner {
        pnpBribingRatio = _pnpBribingRatio;
    }

    function manualClaimFees(address _token) external onlyOwner {
        if (feeCollector != address(0)) {
            unCollectedFee[_token] = 0;
            if (_token == NATIVE) {
                feeCollector.transfer(address(this).balance);
            } else {
                uint256 balance = IERC20(_token).balanceOf(address(this));
                IERC20(_token).safeTransfer(feeCollector, balance);
            }
        }
    }

    function reallocateBribe(
        uint256 _epochFrom,
        uint256 _epochTo,
        uint256 _pid,
        address _token,
        uint256 _amount,
        bool forVePendle
    ) external onlyOwner {
        if (_pid >= pools.length || !pools[_pid]._active) revert InvalidPool();
        if (!allowedToken[_token] && _token != NATIVE) revert InvalidBribeToken();

        if (_epochFrom < exactCurrentEpoch() - 1 || _epochTo < exactCurrentEpoch() - 1) revert InvalidEpoch();
        if (_amount == 0) revert ZeroAmount();

        bytes32 rewardIdentifierFrom = _getTokenIdentifier(_epochFrom, _pid, _token);

        Bribe storage bribeFrom = forVePendle
            ? bribesForVePendle[rewardIdentifierFrom]
            : bribes[rewardIdentifierFrom];

        if (bribeFrom._token == address(0)) revert InvalidBribeToken();

        if (bribeFrom._amount < _amount) revert InsufficientAmount();

        bribeFrom._amount -= _amount;

        bytes32 poolIdentifierTo = _getPoolIdentifier(_epochTo, _pid);
        bytes32 rewardIdentifierTo = _getTokenIdentifier(_epochTo, _pid, _token);

        Bribe storage bribeTo = forVePendle
            ? bribesForVePendle[rewardIdentifierTo]
            : bribes[rewardIdentifierTo];
        bribeTo._amount += _amount;
        if (bribeTo._token == address(0)) {
            bribeTo._token = _token;
            if (forVePendle) bribesInPoolForVePendle[poolIdentifierTo].push(rewardIdentifierTo);
            else bribesInPool[poolIdentifierTo].push(rewardIdentifierTo);
        }

        emit BribeReallocated(_pid, _token, _epochFrom, _epochTo, _amount);
    }

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IPendleVoteManager {

    function castVotes() external;

    function getClaimReward() external;

    function claimAllRewards(address _for) external returns (uint256[] memory earnedRewards);

    function vote(address[] calldata _lps, int256[] calldata _deltas) external;

    function userVotedForPoolInVlPenpie(address, address) external view returns (uint256);

    function userTotalVotedInVlPenpie(address _user) external view returns(uint256);

    function getUserVoteForPoolsInVlPenpie(address[] calldata lps, address _user)
        external
        view
        returns (uint256[] memory votes);

    function isPoolActive(address pool) external view returns (bool);

    function unVote(address _lp) external;

    function addPool(address _market, uint16 _chainId) external;

    function removePool(uint256 _index) external;

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.19;

/* solhint-disable private-vars-leading-underscore, reason-string */

library Math {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    int256 internal constant IONE = 1e18; // 18 decimal places

    function subMax0(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a >= b ? a - b : 0);
        }
    }

    function subNoNeg(int256 a, int256 b) internal pure returns (int256) {
        require(a >= b, "negative");
        return a - b; // no unchecked since if b is very negative, a - b might overflow
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        unchecked {
            return product / ONE;
        }
    }

    function mulDown(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        unchecked {
            return product / IONE;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 aInflated = a * ONE;
        unchecked {
            return aInflated / b;
        }
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        int256 aInflated = a * IONE;
        unchecked {
            return aInflated / b;
        }
    }

    function rawDivUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    // @author Uniswap
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x > 0 ? x : -x);
    }

    function neg(int256 x) internal pure returns (int256) {
        return x * (-1);
    }

    function neg(uint256 x) internal pure returns (int256) {
        return Int(x) * (-1);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y ? x : y);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return (x > y ? x : y);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x < y ? x : y);
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return (x < y ? x : y);
    }

    /*///////////////////////////////////////////////////////////////
                               SIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Int(uint256 x) internal pure returns (int256) {
        require(x <= uint256(type(int256).max));
        return int256(x);
    }

    function Int128(int256 x) internal pure returns (int128) {
        require(type(int128).min <= x && x <= type(int128).max);
        return int128(x);
    }

    function Int128(uint256 x) internal pure returns (int128) {
        return Int128(Int(x));
    }

    /*///////////////////////////////////////////////////////////////
                               UNSIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Uint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function Uint32(uint256 x) internal pure returns (uint32) {
        require(x <= type(uint32).max);
        return uint32(x);
    }

    function Uint112(uint256 x) internal pure returns (uint112) {
        require(x <= type(uint112).max);
        return uint112(x);
    }

    function Uint96(uint256 x) internal pure returns (uint96) {
        require(x <= type(uint96).max);
        return uint96(x);
    }

    function Uint128(uint256 x) internal pure returns (uint128) {
        require(x <= type(uint128).max);
        return uint128(x);
    }

    function isAApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return mulDown(b, ONE - eps) <= a && a <= mulDown(b, ONE + eps);
    }

    function isAGreaterApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return a >= b && a <= mulDown(b, ONE + eps);
    }

    function isASmallerApproxB(uint256 a, uint256 b, uint256 eps) internal pure returns (bool) {
        return a <= b && a >= mulDown(b, ONE - eps);
    }
}