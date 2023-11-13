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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
pragma solidity 0.8.19;

interface IEsRDNTHelper {
    
    event swappedRdntToEsRdnt( uint256 amountIn, uint256 amountOut );
    event swappedEsRdntToRdnt( uint256 amountIn, uint256 amountOut);

    function swapRDNTToEsRDNT(
        uint256 amountToSwap,
        uint160 sqrtPriceLimit,
        uint256 amountOutMin
    ) external returns (uint256 amountOut);

    function swapEsRDNTToRDNT(
        uint256 amountToSwap,
        uint160 sqrtPriceLimit,
        uint256 amountOutMin
    ) external returns (uint256 amountOut);

    function swapEsRDNTToRDNTFor(
        uint256 amountToSwap,
        uint256 amountOutMin,
        uint160 sqrtPriceLimit,
        address receiver
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterRadpie {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _stakingTokenToken,
        address _receiptToken,
        address _rewarder
    ) external;

    function set(
        address _stakingToken,
        uint256 _allocPoint,
        address _helper,
        address _rewarder,
        bool _helperNeedsHarvest
    ) external;

    function createRewarder(
        address _stakingTokenToken,
        address mainRewardToken
    ) external returns (address);

    // View function to see pending GMPs on frontend.
    function getPoolInfo(
        address token
    )
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function pendingTokens(
        address _stakingToken,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 _pendingGMP,
            address _bonusTokenAddress,
            string memory _bonusTokenSymbol,
            uint256 _pendingBonusToken
        );

    function allPendingTokens(
        address _stakingToken,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRadpie,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function massUpdatePools() external;

    function updatePool(address _stakingToken) external;

    function deposit(address _stakingToken, uint256 _amount) external;

    function depositFor(
        address _stakingToken,
        address _for,
        uint256 _amount
    ) external;

    function withdraw(address _stakingToken, uint256 _amount) external;

    function beforeReceiptTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function afterReceiptTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;


    function multiclaimFor(
        address[] calldata _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function multiclaimOnBehalf(
        address[] memory _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function emergencyWithdraw(address _stakingToken, address sender) external;

    function updateEmissionRate(uint256 _gmpPerSec) external;

    function stakingInfo(
        address _stakingToken,
        address _user
    ) external view returns (uint256 depositAmount, uint256 availableAmount);

    function totalTokenStaked(
        address _stakingToken
    ) external view returns (uint256);

    function registeredToken(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMintableERC20 {
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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    function mint(address, uint256) external;

    function faucet(uint256) external;

    function burn(address, uint256) external;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRadiantStaking {

    function depositAssetFor(address _asset, address _for, uint256 _amount) external payable;

    function withdrawAssetFor(address _asset, address _for, uint256 _liquidity) external;

    function vestAllClaimableRDNT(bool _force) external;

    function claimVestedRDNT() external;

    function poolLength() external view returns (uint256);

    function poolTokenList(uint256 i) external view returns(address);

    function accrueStreamingFee(address _receiptToken) external;

    function pools(address _asset) external view returns(
        address asset,
        address rToken,
        address vdToken,
        address rewarder,
        address receiptToken,
        uint256 maxCap,
        uint256 lastActionHandled,
        bool isNative,
        bool isActive
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRDNTVestManager {

    function scheduleVesting(
        address _for,
        uint256 _amount,
        uint256 _endTime
    ) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {
    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     **/
    function handleActionBefore(address user) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

    /**
     * @dev Called by the locking contracts after locking or unlocking happens
     * @param user The address of the user
     **/
    function beforeLockUpdate(address user) external;

    /**
     * @notice Hook for lock update.
     * @dev Called by the locking contracts after locking or unlocking happens
     */
    function afterLockUpdate(address _user) external;

    function addPool(address _token, uint256 _allocPoint) external;

    function claim(address _user, address[] calldata _tokens) external;

    function setClaimReceiver(address _user, address _receiver) external;

    function getRegisteredTokens() external view returns (address[] memory);

    function disqualifyUser(address _user, address _hunter) external returns (uint256 bounty);

    function bountyForUser(address _user) external view returns (uint256 bounty);

    function allPendingRewards(address _user) external view returns (uint256 pending);

    function claimAll(address _user) external;

    function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

    function setEligibilityExempt(address _address, bool _value) external;

    function pendingRewards(
        address _user,
        address[] memory _tokens
    ) external view returns (uint256[] memory);

    function rewardsPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function userBaseClaimable(address _user) external view returns (uint256);

    function poolInfo(address _pool) external view returns(uint256 totalSupply, uint256 allocPoint, uint256 lastRewardTime, uint256 accRewardPerShar, address onwardIncentives);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MintableERC20 } from "./MintableERC20.sol";
import { RadpieReceiptToken } from "../rewards/RadpieReceiptToken.sol";

library ERC20FactoryLib {
    function createERC20(string memory name_, string memory symbol_) public returns (address) {
        ERC20 token = new MintableERC20(name_, symbol_);
        return address(token);
    }

    function createReceipt(
        uint8 _decimals,
        address _stakeToken,
        address _radiantStaking,
        address _masterRadpie,
        string memory _name,
        string memory _symbol
    ) public returns (address) {
        ERC20 token = new RadpieReceiptToken(_decimals, _stakeToken, _radiantStaking, _masterRadpie, _name, _symbol);
        return address(token);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MintableERC20 is ERC20, Ownable {
    /*
    The ERC20 deployed will be owned by the others contracts of the protocol, specifically by
    MasterMagpie and WombatStaking, forbidding the misuse of these functions for nefarious purposes
    */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {} 

    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.19;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IMasterRadpie.sol";
import "../interfaces/IRadiantStaking.sol";

/// @title RadpieReceiptToken is to represent a Radiant Asset deposited back to Radiant. RadpieReceiptToken is minted to user who deposited Asset token
///        on Radiant again DLP Tokens again on Radidant increase defi lego
///
///         Reward from Magpie and on BaseReward should be updated upon every transfer.
///
/// @author Magpie Team
/// @notice Master Radpie emit `RDP` reward token based on Time. For a pool,

contract RadpieReceiptToken is ERC20, Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    address public underlying;
    address public immutable masterRadpie;
    address public immutable radiantStaking;
    uint256 public constant WAD = 10 ** 18;
    uint8 public immutable setDecimal;

    constructor(
        uint8 _decimals,
        address _underlying,
        address _radiantStaking,
        address _masterRadpie,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        underlying = _underlying;
        masterRadpie = _masterRadpie;
        setDecimal = _decimals;
        radiantStaking = _radiantStaking;
    }

    function decimals() public view override returns (uint8) {
        return setDecimal;
    }

    /// @dev ratio of receipt token to underlying asset. Calculated by All collateral minus debt.
    /// return in WAD
    function assetPerShare() external view returns(uint256) {
        if (radiantStaking == address(0))
            return WAD;

        (,address rToken, address vdToken,,,,,,) = IRadiantStaking(radiantStaking).pools(underlying);

        uint256 reciptTokenTotal = this.totalSupply();
        uint256 rTokenBal = IERC20(rToken).balanceOf(address(radiantStaking));
        
        if (reciptTokenTotal == 0 || rTokenBal == 0) return WAD;

        uint256 vdTokenBal = IERC20(vdToken).balanceOf(address(radiantStaking));

        return ((rTokenBal - vdTokenBal) * WAD) / reciptTokenTotal;        
    }

    // should only be called by 1. RadiantStaking for Radiant Asset deposits 2. masterRadpie for other general staking token such as mDLP or Radpie DLp tokens
    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    // should only be called by 1. RadiantStaking for Radiant Asset deposits 2. masterRadpie for other general staking token such as mDLP or Radpie DLp tokens
    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }

    // rewards are calculated based on user's receipt token balance, so reward should be updated on master Radpie before transfer
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        IMasterRadpie(masterRadpie).beforeReceiptTokenTransfer(from, to, amount);
    }

    // rewards are calculated based on user's receipt token balance, so balance should be updated on master Radpie before transfer
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        IMasterRadpie(masterRadpie).afterReceiptTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IRadiantStaking.sol";
import "../interfaces/IEsRDNTHelper.sol";
import "../interfaces/IRDNTVestManager.sol";
import "../interfaces/radiant/IChefIncentivesController.sol";
import "../interfaces/IMintableERC20.sol";
import "../libraries/ERC20FactoryLib.sol";

/// @title A contract for managing entitled RDNT and vestable RDNT for users
/// Entitled RDNT are the RDNT amount that Radiant Staking claim from Radiant Capital, waiting to vest
/// Vestable RDNT are the RDNT amount that Radiant Staking has started claiming

/// The flow of RDNT vesting flow.
/// 1. RDNTVestManager.nextVestedTime is the RDNT vested time for all Radpie user they start vesting their Entitled RDNT at anytime.  (timestamp: T1 - x, 0 days < x < 10 days)
/// 2. RDNTRewardManager.startVestingAll call to make RadianStaking request vesting all current claimable RDNT on Radiant.            (timestamp: T1)
/// 3. RDNTRewardManager.collectVestedRDNTAll to make RadianStaking claim all vesterd RDNT and trasnfer to RDNTVestManager            (timestamp: T1 + 90)
/// 4. User can claim their vested RDNT from RDNTVestManager                                                                          (after timestamp: T1 + 90 )
/// vesting day of RDNT for Radpie user will be:   90 < RDNT vest time < 90 + x, (0 days < x < 10 days)

/// @author Radpie Team

contract RDNTRewardManager is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    struct RDNTRewardStats {
        uint256 queuedRewards;
        uint256 entitledPerTokenStored;
    }

    struct UserInfo {
        uint256 userEntitledPerTokenPaid;
        uint256 userEntitled;
    }

    IRadiantStaking public radiantStaking;
    address public rewardDistributor;
    IRDNTVestManager public rdntVestManager;
    IChefIncentivesController public chefIncentivesController;
    address[] public registeredReceipts; // all registerd receipt
    address[] public whitelistedOperators;

    mapping(address => RDNTRewardStats) public rdntRewardStats; // _radpieReceipt to RDNTRewardStats
    mapping(address => mapping(address => UserInfo)) public userInfos; // amount by [_receipt][account],
    mapping(address => bool) public rewardQueuers;
    mapping(address => bool) public isTokenRegistered;

    uint256 public RDNTVestingDays; // The vesting days on RADIAN Capital
    uint256 public RDNTVestingCoolDown; // The time gap before next RadiantStaking request vesting RDNT
    uint256 public nextVestingTime; // The expect time of next RadiantStaking request vesting RDNT, should be currrent timeblock + RDNTVestingCoolDown

    uint256 public constant OFFSET = 10 ** 12;

    address public esRDNT;
    address public RDNT;
    IEsRDNTHelper public EsRDNTHelper;

    /* ============ Events ============ */

    event RDNTEntitled(address indexed _receipt, uint256 _amount);
    event RDNTVestable(uint256 _amount);
    event VestingRDNTSchedule(address indexed _user, uint256 _vestAmount, uint256 _unblockTime);
    event EntitledRDNTUpdated(
        address indexed _account,
        address indexed _receipt,
        uint256 _entitledRDNT,
        uint256 _entitledPerTokenStored
    );
    event RewardQueuerUpdated(address indexed _manager, bool _allowed);
    event RdntVestingDaysUpdated(uint256 updatedRDNTVestingDays, uint256 updatedRDNTCoolDownDays);
    event VestingEsRDNTSchedule(address indexed _user, uint256 _vestAmount, uint256 _unblockTime);
    event esRDNTEarned(address indexed user, uint256 totalEntitled);
    event RDNTEarned(address indexed user, uint256 totalEntitled);
    event swappedRdntToEsRdntStartedVestingEsRDNT(uint256 amountIn, uint256 amountOut);

    /* ============ Errors ============ */

    error OnlyRewardQueuer();
    error NotAllowZeroAddress();
    error VestingTimeNotReached();
    error OnlyWhiteListedOperator();
    error AlreadyRegistered();
    error InsufficientBalance();
    error esRDNTNotSet();
    error AlreadyCreated();
    error ZeroAmount();
    error RDNTNotSet();
    error EsRDNTHelperNotSet();
    error EsRDNTHelperARBChainNotSet();

    /* ============ Constructor ============ */
    constructor() {
        _disableInitializers();
    }

    function __RDNTRewardManager_init(
        address _radiantStaking,
        address _chefIncentivesController
    ) public initializer {
        __Ownable_init();
        if (_radiantStaking == address(0)) revert NotAllowZeroAddress();
        radiantStaking = IRadiantStaking(_radiantStaking);
        if (_chefIncentivesController == address(0)) revert NotAllowZeroAddress();
        chefIncentivesController = IChefIncentivesController(_chefIncentivesController);
        rewardQueuers[_radiantStaking] = true;
        RDNTVestingDays = 90 days;
        RDNTVestingCoolDown = 10 days;
        nextVestingTime = block.timestamp + RDNTVestingCoolDown;
    }

    /* ============ Modifiers ============ */

    modifier onlyRewardQueuer() {
        if (!rewardQueuers[msg.sender]) revert OnlyRewardQueuer();
        _;
    }

    modifier updateEntitledRDNTs(address _account) {
        uint256 length = registeredReceipts.length;

        for (uint256 i = 0; i < length; i++) {
            address registeredReceipt = registeredReceipts[i];
            _updateForByReceipt(_account, registeredReceipt);
        }
        _;
    }

    modifier _onlyWhitelisted() {
        bool isCallerWhiteListed = false;
        for (uint i; i < whitelistedOperators.length; i++) {
            if (whitelistedOperators[i] == msg.sender) {
                isCallerWhiteListed = true;
                break;
            }
        }
        if (isCallerWhiteListed == true || owner() == msg.sender) {
            _;
        } else {
            revert OnlyWhiteListedOperator();
        }
    }

    /* ============ External Getters ============ */

    /// @dev How Entitled RDNT should be distributed.
    /// RDNT emit for the same underlying asset of rToken and vdToken goes to the same pool on Radpie.
    function entitledRdntGauge()
        external
        view
        returns (uint256 totalWeight, address[] memory assets, uint256[] memory weights)
    {
        uint256 length = radiantStaking.poolLength();
        assets = new address[](length);
        weights = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address asset = radiantStaking.poolTokenList(i);
            assets[i] = asset;

            uint256 weight = calculatePoolWeight(asset);

            // Assign weight directly to the array without a separate variable
            weights[i] = weight;

            totalWeight += weight;
        }
    }

    /// @dev Returns current amount of staked tokens
    function totalStaked(address _receiptToken) public view virtual returns (uint256) {
        return IERC20(_receiptToken).totalSupply();
    }

    /// @dev Returns amount of staked tokens in master Radpie by account
    /// @param _receiptToken The address of the receipt
    /// @param _account The address of the account
    function balanceOf(
        address _account,
        address _receiptToken
    ) public view virtual returns (uint256) {
        return IERC20(_receiptToken).balanceOf(_account);
    }

    /// @dev Returns the entitled RDNT per token for a specific receipt
    /// @param _receipt The address of the receipt
    function entitledPerToken(address _receipt) public view returns (uint256) {
        return rdntRewardStats[_receipt].entitledPerTokenStored;
    }

    /// @dev Returns the total entitled RDNT for a specific account
    /// @param _account The address of the account
    /// @return The total entitled RDNT for the account
    function entitledRDNT(address _account) public view returns (uint256) {
        uint256 length = registeredReceipts.length;
        uint256 userTotalEntitled;

        for (uint256 i = 0; i < length; i++) {
            userTotalEntitled += this.entitledRDNTByReceipt(_account, registeredReceipts[i]);
        }

        return userTotalEntitled;
    }

    /// @dev Returns the entitled RDNT for a specific account and receipt
    /// @param _account The address of the account
    /// @param _receipt The address of the receipt
    /// @return The entitled RDNT for the account and receipt and Balance of ReceiptToken
    function entitledRDNTByReceipt(
        address _account,
        address _receipt
    ) public view returns (uint256) {
        return _entitled(_account, _receipt, balanceOf(_account, _receipt));
    }

    function nextVestedTime() external view returns (uint256) {
        return nextVestingTime + RDNTVestingDays;
    }

    /* ============ External Functions ============ */

    /// @dev Updates the entitled RDNTs for a specific account and receipt
    /// @param _account The address of the account
    /// @param _receipt The address of the receipt
    function updateFor(address _account, address _receipt) external {
        _updateForByReceipt(_account, _receipt);
    }

    /// @dev Start vesting the RDNT tokens for the calling account
    function vestRDNT() external updateEntitledRDNTs(msg.sender) {
        uint256 totalEntitled = processEntitlement(msg.sender);

        if (totalEntitled > 0) {
            uint256 vestedTime = this.nextVestedTime();
            IRDNTVestManager(rdntVestManager).scheduleVesting(
                msg.sender,
                totalEntitled,
                vestedTime
            );
            emit VestingRDNTSchedule(msg.sender, totalEntitled, vestedTime);
        }
    }

    /// @notice Vest a specified amount of esRDNT tokens for the calling account.
    /// @param _amount The amount of esRDNT tokens to vest.
    function vestEsRDNT(uint256 _amount) external {
        if (esRDNT == address(0)) revert esRDNTNotSet();
        uint256 esRDNTBal = IMintableERC20(esRDNT).balanceOf(msg.sender);

        if (_amount > esRDNTBal) revert InsufficientBalance();

        if (_amount > 0) {
            IMintableERC20(esRDNT).burn(msg.sender, _amount);
            uint256 vestedTime = this.nextVestedTime();
            IRDNTVestManager(rdntVestManager).scheduleVesting(msg.sender, _amount, vestedTime);
            emit VestingEsRDNTSchedule(msg.sender, _amount, vestedTime);
        }
    }

    function swapRDNTToEsRDNTStartVestingEsRDNT(
        uint256 amountToSwap,
        uint160 sqrtPriceLimit,
        uint256 amountOutMin
    ) external returns (uint256 startedVesting) {
        if (amountToSwap == 0) revert ZeroAmount();
        if (RDNT == address(0)) revert RDNTNotSet();
        if (address(EsRDNTHelper) == address(0)) revert EsRDNTHelperNotSet();

        IERC20(RDNT).safeTransferFrom(msg.sender, address(this), amountToSwap);
        IERC20(RDNT).safeApprove(address(EsRDNTHelper), amountToSwap);

        (startedVesting) = EsRDNTHelper.swapRDNTToEsRDNT(
            amountToSwap,
            sqrtPriceLimit,
            amountOutMin
        );

        uint256 vestedTime = this.nextVestedTime();
        IRDNTVestManager(rdntVestManager).scheduleVesting(msg.sender, startedVesting, vestedTime);

        emit swappedRdntToEsRdntStartedVestingEsRDNT(amountToSwap, startedVesting);
    }

    function withdrawEsRDNTToRDNT(uint256 amountRdntOutMin, uint160 sqrtPriceLimit) external {
        if (esRDNT == address(0)) revert esRDNTNotSet();
        if (address(EsRDNTHelper) == address(0)) revert EsRDNTHelperNotSet();

        uint256 totalEntitled = processEntitlement(msg.sender);

        if (totalEntitled > 0) {
            IMintableERC20(esRDNT).mint(address(this), totalEntitled);
            IERC20(esRDNT).safeApprove(address(EsRDNTHelper), totalEntitled);

            uint256 amountRDNTOut = EsRDNTHelper.swapEsRDNTToRDNTFor(
                totalEntitled,
                amountRdntOutMin,
                sqrtPriceLimit,
                msg.sender
            );

            emit RDNTEarned(msg.sender, amountRDNTOut);
        }
    }

    //  @notice Redeem entitled RDNT tokens to esRDNT Tokens for the calling account.
    function redeemEntitledRDNT() external updateEntitledRDNTs(msg.sender) {
        if (esRDNT == address(0)) revert esRDNTNotSet();

        uint256 totalEntitled = processEntitlement(msg.sender);

        if (totalEntitled > 0) {
            IMintableERC20(esRDNT).mint(msg.sender, totalEntitled);
            emit esRDNTEarned(msg.sender, totalEntitled);
        }
    }

    /* ============ Admin Functions ============ */

    /// @dev Updates the reward queuer status for a manager
    /// @param _rewardManager The address of the reward manager
    /// @param _allowed The status to be set (true or false)
    function updateRewardQueuer(address _rewardManager, bool _allowed) external onlyOwner {
        rewardQueuers[_rewardManager] = _allowed;
        emit RewardQueuerUpdated(_rewardManager, rewardQueuers[_rewardManager]);
    }

    /// @dev Queues the entitled RDNT tokens for a specific receipt
    /// @param _rdntAmount The amount of RDNT tokens to be queued
    /// @param _radpieReceipt The address of the radpie receipt token
    function queueEntitledRDNT(
        address _radpieReceipt,
        uint256 _rdntAmount
    ) external onlyRewardQueuer {
        if (!isTokenRegistered[_radpieReceipt]) {
            isTokenRegistered[_radpieReceipt] = true;
            registeredReceipts.push(_radpieReceipt);
        }

        RDNTRewardStats storage rdntRewardStat = rdntRewardStats[_radpieReceipt];

        emit RDNTEntitled(_radpieReceipt, _rdntAmount);

        uint256 totalStake = totalStaked(_radpieReceipt);
        if (totalStake == 0) {
            rdntRewardStat.queuedRewards += _rdntAmount;
        } else {
            if (rdntRewardStat.queuedRewards > 0) {
                _rdntAmount += rdntRewardStat.queuedRewards;
                rdntRewardStat.queuedRewards = 0;
            }
            rdntRewardStat.entitledPerTokenStored =
                rdntRewardStat.entitledPerTokenStored +
                (_rdntAmount * 10 ** IERC20Metadata(_radpieReceipt).decimals()) /
                totalStake;
        }
    }

    /// @dev Radpie to start vesting currnet all claimmable RDNT on Radiant. This function is expected to be called every other 5 - 10 days
    function startVestingAll(bool _force) external _onlyWhitelisted {
        IRadiantStaking(radiantStaking).vestAllClaimableRDNT(_force);
        nextVestingTime = block.timestamp + RDNTVestingCoolDown; // nextVestingTime has to be updated as block.timestamp + RDNTVestingDays
    }

    /// @dev Radpie to claim all vested RDNT and transfer RDNT to RDNTVest Manager so user can claim
    function collectVestedRDNTAll() external _onlyWhitelisted {
        if (block.timestamp < nextVestingTime) revert VestingTimeNotReached();
        radiantStaking.claimVestedRDNT();
    }

    function setRDNTVestManager(address _rdntVestManager) external onlyOwner {
        if (_rdntVestManager == address(0)) revert NotAllowZeroAddress();
        rdntVestManager = IRDNTVestManager(_rdntVestManager);
    }

    function setRewardDistributor(address _rewardDistributor) external onlyOwner {
        if (_rewardDistributor == address(0)) revert NotAllowZeroAddress();
        rewardDistributor = _rewardDistributor;
    }

    function setEsRDNTHelper(address _esRDNTHelper) external onlyOwner {
        if (_esRDNTHelper == address(0)) revert NotAllowZeroAddress();
        EsRDNTHelper = IEsRDNTHelper(_esRDNTHelper);
    }

    function setRDNT(address _rdnt) external onlyOwner {
        if (_rdnt == address(0)) revert NotAllowZeroAddress();
        RDNT = _rdnt;
    }

    function addRegisteredReceipt(address _receiptToken) external onlyRewardQueuer {
        if (isTokenRegistered[_receiptToken]) revert AlreadyRegistered();

        isTokenRegistered[_receiptToken] = true;
        registeredReceipts.push(_receiptToken);
    }

    function addWhitelistedOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) {
            revert NotAllowZeroAddress();
        }
        whitelistedOperators.push(_operator);
    }

    function removeWhitelistedOperator(uint _index) external onlyOwner {
        if (_index >= whitelistedOperators.length) {
            revert NotAllowZeroAddress();
        }
        whitelistedOperators[_index] = whitelistedOperators[whitelistedOperators.length - 1];
        whitelistedOperators.pop();
    }

    function updateVestingTimePeriodData(
        uint256 _radiantVestingCoolDownDays,
        uint256 _radinatVestingDays
    ) external onlyOwner {
        RDNTVestingDays = _radinatVestingDays * 1 days;
        RDNTVestingCoolDown = _radiantVestingCoolDownDays * 1 days;
        emit RdntVestingDaysUpdated(RDNTVestingDays, RDNTVestingCoolDown);
    }

    // Admin function to create the esRDNT token
    function createEsRDNT(string memory name, string memory symbol) external onlyOwner {
        if (esRDNT != address(0)) revert AlreadyCreated();
        esRDNT = ERC20FactoryLib.createERC20(name, symbol);
    }

    /* ============ Internal Functions ============ */

    /// @dev Calculate the weight for a given pool
    function calculatePoolWeight(address asset) internal view returns (uint256) {
        (, address rToken, address vdToken, , , , , , bool isActive) = radiantStaking.pools(asset);

        if (!isActive) return 0;

        uint256 rTokenBal = IERC20(rToken).balanceOf(address(radiantStaking));
        uint256 vdTokenBal = IERC20(vdToken).balanceOf(address(radiantStaking));

        (uint256 rTokenTotalSup, uint256 rAlloc, , , ) = chefIncentivesController.poolInfo(rToken);
        (uint256 vdTokenTotalSup, uint256 vdAlloc, , , ) = chefIncentivesController.poolInfo(
            vdToken
        );

        uint256 rTokenWeight = (OFFSET * rTokenBal * rAlloc) / rTokenTotalSup;
        uint256 vdTokenWeight = (OFFSET * vdTokenBal * vdAlloc) / vdTokenTotalSup;

        return rTokenWeight + vdTokenWeight;
    }

    /// @dev Calculates the entitled RDNT for a specific account and receipt
    function _entitled(
        address _account,
        address _receipt,
        uint256 _userShare
    ) internal view returns (uint256) {
        UserInfo storage userInfo = userInfos[_receipt][_account];
        if (_userShare == 0) return userInfo.userEntitled;

        return
            ((_userShare * (entitledPerToken(_receipt) - userInfo.userEntitledPerTokenPaid)) /
                10 ** IERC20Metadata(_receipt).decimals()) + userInfo.userEntitled;
    }

    /// @dev Updates the entitled RDNTs for a specific account and receipt
    function _updateForByReceipt(address _account, address _receipt) internal {
        UserInfo storage userInfo = userInfos[_receipt][_account];
        RDNTRewardStats storage rewardStat = rdntRewardStats[_receipt];

        if (userInfo.userEntitledPerTokenPaid == rewardStat.entitledPerTokenStored) return;

        userInfo.userEntitled = entitledRDNTByReceipt(_account, _receipt);
        userInfo.userEntitledPerTokenPaid = rewardStat.entitledPerTokenStored;

        emit EntitledRDNTUpdated(
            _account,
            _receipt,
            userInfo.userEntitled,
            userInfo.userEntitledPerTokenPaid
        );
    }

    /// @dev Common function to process entitlement
    function processEntitlement(address _account) internal returns (uint256) {
        uint256 length = registeredReceipts.length;
        uint256 totalEntitled = 0;

        for (uint256 i = 0; i < length; i++) {
            address receipt = registeredReceipts[i];
            if (userInfos[receipt][_account].userEntitled == 0) continue;

            totalEntitled += userInfos[receipt][_account].userEntitled; // updated during updateReward modifier
            userInfos[receipt][_account].userEntitled = 0;
        }

        return totalEntitled;
    }
}