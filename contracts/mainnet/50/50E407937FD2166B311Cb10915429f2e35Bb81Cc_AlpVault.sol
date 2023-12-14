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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
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
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interface/IWater.sol";
import "./interface/IApxInterface/IAlpManager.sol";
import "./interface/IApxInterface/ISmartChefInitializable.sol";
import "./interface/IMasterChef.sol";
import "./interface/IAlpRewardHandler.sol";
import "./interface/IAlpVault.sol";

contract AlpVault is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC20BurnableUpgradeable, IAlpVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IWater public water;
    address public USDC;
    address private mFeeReceiver;

    uint256 public DTVLimit;
    uint256 public DTVSlippage;
    uint256 public MCPID;
    uint256 private defaultDebtAdjustment;
    uint256 private mFeePercent;

    StrategyMisc public strategyMisc;
    StrategyAddresses public strategyAddresses;
    FeeConfiguration public feeConfiguration;

    address[] public allUsers;

    mapping(address => bool) public isWhitelistedAsset;
    mapping(address => bool) public allowedClosers;
    mapping(address => bool) public allowedSenders;

    mapping(address => bool) public burner;
    mapping(address => bool) public isUser;
    mapping(address => UserInfo[]) public userInfo;

    uint256[50] private __gaps;

    modifier InvalidID(uint256 positionId, address user) {
        require(positionId < userInfo[user].length, "ApxVault: !valid");
        _;
    }

    modifier onlyBurner() {
        require(burner[msg.sender], "Not allowed to burn");
        _;
    }

    modifier zeroAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _water, address _usdc) external initializer {
        defaultDebtAdjustment = 1e18;
        strategyMisc.MAX_LEVERAGE = 10_000;
        strategyMisc.MIN_LEVERAGE = 2_000;
        strategyMisc.DECIMAL = 1e18;
        strategyMisc.MAX_BPS = 100_000;
        water = IWater(_water);
        USDC = _usdc;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC20_init("ALPPOD", "ALPPOD");
    }

    function setWhitelistedAsset(address token, bool status) external onlyOwner {
        isWhitelistedAsset[token] = status;
        emit SetWhitelistedAsset(token, status);
    }

    function setMFeeConfig(uint256 _mFeePercent, address _mFeeReceiver) external onlyOwner {
        mFeePercent = _mFeePercent;
        mFeeReceiver = _mFeeReceiver;
    }

    function setBurner(address _burner, bool _allowed) public onlyOwner zeroAddress(_burner) {
        burner[_burner] = _allowed;
        emit SetBurner(_burner, _allowed);
    }

    function setCloser(address _closer, bool _allowed) public onlyOwner zeroAddress(_closer) {
        allowedClosers[_closer] = _allowed;
        emit SetAllowedClosers(_closer, _allowed);
    }

    function setAllowed(address _sender, bool _allowed) public onlyOwner zeroAddress(_sender) {
        allowedSenders[_sender] = _allowed;
        emit SetAllowedSenders(_sender, _allowed);
    }

    function setStrategyAddress(
        address _diamond,
        address _smartChef,
        address _apolloXp,
        address _rewardHandler,
        address _masterChef,
        uint256 _pid
    ) external onlyOwner {
        strategyAddresses.alpDiamond = _diamond;
        strategyAddresses.smartChef = _smartChef;
        strategyAddresses.apolloXP = _apolloXp;
        strategyAddresses.alpRewardHandler = _rewardHandler;
        strategyAddresses.masterChef = _masterChef;
        MCPID = _pid;
        emit SetStrategyAddresses(_diamond, _smartChef, _apolloXp);
    }

    function setFeeConfiguration(
        address _feeReceiver,
        uint256 _withdrawalFee,
        address _waterFeeReceiver,
        uint256 _liquidatorsRewardPercentage,
        uint256 _fixedFeeSplit
    ) external onlyOwner {
        feeConfiguration.feeReceiver = _feeReceiver;
        feeConfiguration.withdrawalFee = _withdrawalFee;
        feeConfiguration.waterFeeReceiver = _waterFeeReceiver;
        feeConfiguration.liquidatorsRewardPercentage = _liquidatorsRewardPercentage;
        feeConfiguration.fixedFeeSplit = _fixedFeeSplit;
        emit SetFeeConfiguration(_feeReceiver, _withdrawalFee, _waterFeeReceiver, _liquidatorsRewardPercentage, _fixedFeeSplit);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function migrateLP(address _newSmartChef) external onlyOwner {
        // get total deposited amount
        uint256 totalDeposited = ISmartChefInitializable(strategyAddresses.smartChef).userInfo(address(this)).amount;
        // withdraw all from old smart chef
        ISmartChefInitializable(strategyAddresses.smartChef).withdraw(totalDeposited);
        // approve new smart chef to deposit
        IERC20Upgradeable(strategyAddresses.apolloXP).safeIncreaseAllowance(_newSmartChef, totalDeposited);
        // deposit to new smart chef
        ISmartChefInitializable(_newSmartChef).deposit(totalDeposited);
        // update smart chef address
        strategyAddresses.smartChef = _newSmartChef;
        emit MigrateLP(_newSmartChef, totalDeposited);
    }

    function setDTVLimit(uint256 _DTVLimit, uint256 _DTVSlippage) public onlyOwner {
        require(_DTVSlippage <= 1000, "Slippage < 1000");
        DTVLimit = _DTVLimit;
        DTVSlippage = _DTVSlippage;
    }

    function getAlpPrice() public view returns (uint256) {
        return IAlpManager(strategyAddresses.alpDiamond).alpPrice();
    }

    function getStakedInfo() public view returns (uint256 amountDeposited, uint256 rewards) {
        ISmartChefInitializable.UserInfo memory _userInfo = ISmartChefInitializable(strategyAddresses.smartChef).userInfo(address(this));
        return (_userInfo.amount, ISmartChefInitializable(strategyAddresses.smartChef).pendingReward(address(this)));
    }

    function getAlpCoolingDuration() public view returns (uint256) {
        return IAlpManager(strategyAddresses.alpDiamond).coolingDuration();
    }

    function getAllUsers() public view returns (address[] memory) {
        return allUsers;
    }

    function getAggregatePosition(address _user) public view returns (uint256) {
        uint256 aggregatePosition;
        for (uint256 i = 0; i < userInfo[_user].length; i++) {
            UserInfo memory _userInfo = userInfo[_user][i];
            if (!_userInfo.liquidated) {
                aggregatePosition += userInfo[_user][i].position;
            }
        }
        return aggregatePosition;
    }

    function getTotalNumbersOfOpenPositionBy(address _user) public view returns (uint256) {
        return userInfo[_user].length;
    }

    function getUpdatedDebt(
        uint256 _positionID,
        address _user
    ) public view returns (uint256 currentDTV, uint256 currentPosition, uint256 currentDebt) {
        UserInfo memory _userInfo = userInfo[_user][_positionID];
        if (_userInfo.closed || _userInfo.liquidated) return (0, 0, 0);

        uint256 previousValueInUSDC;
        // Get the current position and previous value in USDC using the `getCurrentPosition` function
        (currentPosition, previousValueInUSDC) = getCurrentPosition(_positionID, _userInfo.position, _user);
        uint256 leverage = _userInfo.leverageAmount;

        // Calculate the current DTV by dividing the amount owed to water by the current position
        currentDTV = (leverage * strategyMisc.DECIMAL) / currentPosition;
        // Return the current DTV, current position, and amount owed to water
        return (currentDTV, currentPosition, leverage);
    }

    function getCurrentPosition(
        uint256 _positionID,
        uint256 _shares,
        address _user
    ) public view returns (uint256 currentPosition, uint256 previousValueInUSDC) {
        UserInfo memory _userInfo = userInfo[_user][_positionID];
        return (_convertALPToUSDC(_shares, getAlpPrice()), _convertALPToUSDC(_shares, _userInfo.price));
    }

    function handleAndCompoundRewards() public returns (uint256) {
        // withdraw all from old smart chef
        if(ISmartChefInitializable(strategyAddresses.smartChef).userInfo(address(this)).amount > 0) {
            ISmartChefInitializable(strategyAddresses.smartChef).withdraw(0);
        }
        // get rewards token address from smart chef
        address rewardToken = ISmartChefInitializable(strategyAddresses.smartChef).rewardToken();
        // get balance of address(this) in reward token
        uint256 balance = IERC20Upgradeable(rewardToken).balanceOf(address(this));

        if (balance > 0) {
            (uint256 toOwner, uint256 toWater, uint256 toVodkaUsers) = IAlpRewardHandler(strategyAddresses.alpRewardHandler).getVodkaSplit(
                balance
            );

            IERC20Upgradeable(rewardToken).transfer(strategyAddresses.alpRewardHandler, balance);

            IAlpRewardHandler(strategyAddresses.alpRewardHandler).distributeCAKE(toVodkaUsers);
            IAlpRewardHandler(strategyAddresses.alpRewardHandler).distributeRewards(toOwner, toWater);
            emit CAKEHarvested(toVodkaUsers);
            return toVodkaUsers;
        }

        return 0;
    }

    // @todo add cool down time for each users
    function openPosition(address _token, uint256 _amount, uint256 _leverage) external whenNotPaused nonReentrant{
        require(_leverage >= strategyMisc.MIN_LEVERAGE && _leverage <= strategyMisc.MAX_LEVERAGE, "ApxVault: Invalid leverage");
        require(_amount > 0, "ApxVault: amount must > zero");
        require(isWhitelistedAsset[_token], "ApxVault: !whitelisted");

        IAlpRewardHandler(strategyAddresses.alpRewardHandler).claimCAKERewards(msg.sender);

        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // get leverage amount
        uint256 leveragedAmount = ((_amount * _leverage) / 1000) - _amount;
        bool status = water.lend(leveragedAmount, address(this));
        require(status, "Water: Lend failed");
        // add leverage amount to amount
        uint256 sumAmount = _amount + leveragedAmount;

        uint256 balanceBefore = IERC20Upgradeable(strategyAddresses.apolloXP).balanceOf(address(this));
        IERC20Upgradeable(_token).safeIncreaseAllowance(strategyAddresses.alpDiamond, sumAmount);
        // @todo since the price of alp is known, we can calculate the min alp required
        IAlpManager(strategyAddresses.alpDiamond).mintAlp(_token, sumAmount, 0, false);
        uint256 balanceAfter = IERC20Upgradeable(strategyAddresses.apolloXP).balanceOf(address(this));
        uint256 mintedAmount = balanceAfter - balanceBefore;
        // approve smart chef to deposit minted amount
        IERC20Upgradeable(strategyAddresses.apolloXP).safeIncreaseAllowance(strategyAddresses.smartChef, mintedAmount);
        // deposit minted amount to smart chef
        ISmartChefInitializable(strategyAddresses.smartChef).deposit(mintedAmount);

        UserInfo memory _userInfo = UserInfo({
            user: msg.sender,
            deposit: _amount,
            leverage: _leverage,
            position: mintedAmount,
            price: getAlpPrice(),
            liquidated: false,
            closedPositionValue: 0,
            liquidator: address(0),
            closePNL: 0,
            leverageAmount: leveragedAmount,
            positionId: userInfo[msg.sender].length,
            closed: false
        });

        //frontend helper to fetch all users and then their userInfo
        if (isUser[msg.sender] == false) {
            isUser[msg.sender] = true;
            allUsers.push(msg.sender);
        }

        userInfo[msg.sender].push(_userInfo);

        // mint pod
        _mint(msg.sender, mintedAmount);
        IAlpRewardHandler(strategyAddresses.alpRewardHandler).setDebtRecordCAKE(msg.sender);
        emit OpenPosition(msg.sender, _leverage, _amount, mintedAmount, userInfo[msg.sender].length - 1, block.timestamp);
    }

    function closePosition(uint256 _positionID, address _user) external InvalidID(_positionID, _user) nonReentrant {
        // Retrieve user information for the given position
        UserInfo storage _userInfo = userInfo[_user][_positionID];
        // Validate that the position is not liquidated
        require(!_userInfo.liquidated, "ApxVault: position is liquidated");
        // Validate that the position has enough shares to close
        require(_userInfo.position > 0, "ApxVault: position !enough to close");
        require(allowedClosers[msg.sender] || msg.sender == _userInfo.user, "ApxVault: !allowed to close position");

        IAlpRewardHandler(strategyAddresses.alpRewardHandler).claimCAKERewards(_user);
        // Struct to store intermediate data during calculation
        CloseData memory closeData;
        (closeData.currentDTV, , ) = getUpdatedDebt(_positionID, _user);

        if (closeData.currentDTV >= (DTVSlippage * DTVLimit) / 1000) {
            revert("liquidation");
        }

        _handlePODToken(_userInfo.user, _userInfo.position);

        // withdraw staked amount from smart chef
        ISmartChefInitializable(strategyAddresses.smartChef).withdraw(_userInfo.position);

        // @todo since the price of alp is known, we can calculate the min usdc required
        uint256 balanceBefore = IERC20Upgradeable(USDC).balanceOf(address(this));
        // approve alp diamond to burn alp
        IERC20Upgradeable(strategyAddresses.apolloXP).safeIncreaseAllowance(strategyAddresses.alpDiamond, _userInfo.position);
        // @todo wait for cooldown period to end
        IAlpManager(strategyAddresses.alpDiamond).burnAlp(USDC, _userInfo.position, 0, address(this));
        uint256 balanceAfter = IERC20Upgradeable(USDC).balanceOf(address(this));
        closeData.returnedValue = balanceAfter - balanceBefore;
        closeData.originalPosAmount = _userInfo.deposit + _userInfo.leverageAmount;

        if (closeData.returnedValue > closeData.originalPosAmount) {
            closeData.profits = closeData.returnedValue - closeData.originalPosAmount;
        }

        if (closeData.profits > 0) {
            (closeData.waterProfits, closeData.mFee, closeData.userShares) = _getProfitSplit(closeData.profits, _userInfo.leverage);
        }

        if (closeData.returnedValue < _userInfo.leverageAmount + closeData.waterProfits) {
            _userInfo.liquidator = msg.sender;
            _userInfo.liquidated = true;
            closeData.waterRepayment = closeData.returnedValue;
        } else {
            closeData.waterRepayment = _userInfo.leverageAmount;
            closeData.toLeverageUser = (closeData.returnedValue - closeData.waterRepayment) - closeData.waterProfits - closeData.mFee;
        }
        uint256 originalPosition = _userInfo.position;

        IERC20Upgradeable(USDC).safeIncreaseAllowance(address(water), closeData.waterRepayment);
        closeData.success = water.repayDebt(_userInfo.leverageAmount, closeData.waterRepayment);
        _userInfo.position = 0;
        _userInfo.leverageAmount = 0;
        _userInfo.closed = true;

        if (_userInfo.liquidated) {
            return;
        }

        if (closeData.waterProfits > 0) {
            IERC20Upgradeable(USDC).safeTransfer(feeConfiguration.waterFeeReceiver, closeData.waterProfits);
        }

        if (closeData.mFee > 0) {
            IERC20Upgradeable(USDC).safeTransfer(mFeeReceiver, closeData.mFee);
        }

        // take protocol fee
        uint256 amountAfterFee;
        if (feeConfiguration.withdrawalFee > 0) {
            uint256 fee = (closeData.toLeverageUser * feeConfiguration.withdrawalFee) / strategyMisc.MAX_BPS;
            IERC20Upgradeable(USDC).safeTransfer(feeConfiguration.feeReceiver, fee);
            amountAfterFee = closeData.toLeverageUser - fee;
        } else {
            amountAfterFee = closeData.toLeverageUser;
        }

        IERC20Upgradeable(USDC).safeTransfer(_user, amountAfterFee);

        _userInfo.closedPositionValue += closeData.returnedValue;
        _userInfo.closePNL += amountAfterFee;
        IAlpRewardHandler(strategyAddresses.alpRewardHandler).setDebtRecordCAKE(_user);
        emit ClosePosition(_user, amountAfterFee, _positionID, block.timestamp, originalPosition, _userInfo.leverage, block.timestamp);
    }

    function liquidatePosition(uint256 _positionId, address _user) external nonReentrant {
        UserInfo storage _userInfo = userInfo[_user][_positionId];
        require(!_userInfo.liquidated, "Sake: Already liquidated");
        require(_userInfo.user != address(0), "Sake: liquidation request does not exist");
        (uint256 currentDTV, , ) = getUpdatedDebt(_positionId, _user);

        if (currentDTV >= (DTVSlippage * DTVLimit) / 1000) {
            revert("liquidation");
        }
        IAlpRewardHandler(strategyAddresses.alpRewardHandler).claimCAKERewards(_user);

        _handlePODToken(_user, _userInfo.position);

        IERC20Upgradeable(strategyAddresses.apolloXP).safeIncreaseAllowance(strategyAddresses.alpDiamond, _userInfo.position);

        uint256 usdcBalanceBefore = IERC20Upgradeable(USDC).balanceOf(address(this));
        IAlpManager(strategyAddresses.alpDiamond).burnAlp(USDC, _userInfo.position, 0, address(this));

        uint256 usdcBalanceAfter = IERC20Upgradeable(USDC).balanceOf(address(this));
        uint256 returnedValue = usdcBalanceAfter - usdcBalanceBefore;

        _userInfo.liquidator = msg.sender;
        _userInfo.liquidated = true;

        uint256 liquidatorReward = (returnedValue * feeConfiguration.liquidatorsRewardPercentage) / strategyMisc.MAX_BPS;
        uint256 amountAfterLiquidatorReward = returnedValue - liquidatorReward;

        IERC20Upgradeable(USDC).safeIncreaseAllowance(address(water), amountAfterLiquidatorReward);
        bool success = water.repayDebt(_userInfo.leverageAmount, amountAfterLiquidatorReward);
        require(success, "Water: Repay failed");
        IERC20Upgradeable(USDC).safeTransfer(msg.sender, liquidatorReward);
        IAlpRewardHandler(strategyAddresses.alpRewardHandler).setDebtRecordCAKE(_user);
        emit Liquidated(_user, _positionId, msg.sender, returnedValue, liquidatorReward, block.timestamp);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        require(allowedSenders[from] || allowedSenders[to] || allowedSenders[spender], "ERC20: transfer not allowed");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address ownerOf = _msgSender();
        require(allowedSenders[ownerOf] || allowedSenders[to], "ERC20: transfer not allowed");
        _transfer(ownerOf, to, amount);
        return true;
    }

    function burn(uint256 amount) public virtual override onlyBurner {
        _burn(_msgSender(), amount);
    }

    function _handlePODToken(address _user, uint256 position) internal {
        if (strategyAddresses.masterChef != address(0)) {
            uint256 userBalance = balanceOf(_user);
            if (userBalance >= position) {
                _burn(_user, position);
            } else {
                _burn(_user, userBalance);
                uint256 remainingPosition = position - userBalance;
                IMasterChef(strategyAddresses.masterChef).unstakeAndLiquidate(MCPID, _user, remainingPosition);
            }
        } else {
            _burn(_user, position);
        }
    }

    function _getProfitSplit(uint256 _profit, uint256 _leverage) internal view returns (uint256, uint256, uint256) {
        uint256 split = (feeConfiguration.fixedFeeSplit * _leverage + (feeConfiguration.fixedFeeSplit * 10000)) / 100;
        uint256 toWater = (_profit * split) / 10000;
        uint256 mFee = (_profit * mFeePercent) / 10000;
        uint256 toSakeUser = _profit - (toWater + mFee);

        return (toWater, mFee, toSakeUser);
    }

    function _convertALPToUSDC(uint256 _amount, uint256 _alpPrice) internal pure returns (uint256) {
        return (_amount * _alpPrice) / (100e6);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IAlpRewardHandler {
    function notifyRewardAmount(uint256 reward) external;

    function getReward(address account) external;

    function distributeRewards(uint256 _teamAmount, uint256 _waterAmount) external;

    function distributeCAKE(uint256 _amount) external;

    function getVodkaSplit(uint256 _amount) external view returns (uint256, uint256, uint256);

    function claimCAKERewards(address account) external;

    function setDebtRecordCAKE(address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAlpVault {
    /**
     * @dev Struct representing user-specific information for a position in the strategy.
     */
    struct UserInfo {
        address user; // User's address.
        uint256 deposit; // Amount deposited by the user.
        uint256 leverage; // Leverage applied to the position.
        uint256 position; // Current position size.
        uint256 price; // Price of the asset at the time of the transaction.
        bool liquidated; // Flag indicating if the position has been liquidated.
        uint256 closedPositionValue; // Value of the closed position.
        address liquidator; // Address of the liquidator, if liquidated.
        uint256 closePNL; // Profit and Loss from closing the position.
        uint256 leverageAmount; // Amount leveraged in the position.
        uint256 positionId; // Unique identifier for the position.
        bool closed; // Flag indicating if the position is closed.
    }

    /**
     * @dev Struct used to store intermediate data during position closure calculations.
     */
    struct CloseData {
        uint256 returnedValue; // The amount returned after position closure.
        uint256 profits; // The profits made from the closure.
        uint256 originalPosAmount; // The original position amount.
        uint256 waterRepayment; // The amount repaid to the lending protocol.
        uint256 waterProfits; // The profits received from the lending protocol.
        uint256 mFee; // Management fee.
        uint256 userShares; // Shares allocated to the user.
        uint256 toLeverageUser; // Amount provided to the user after leverages.
        uint256 currentDTV; // Current debt-to-value ratio.
        bool success; // Flag indicating the success of the closure operation.
    }

    // @dev StrategyAddresses struct represents addresses used in the strategy
    struct StrategyAddresses {
        address alpDiamond; // ALP Diamond contract
        address smartChef; // Stake ALP
        address apolloXP; // ApolloX token contract
        address masterChef; // ALP-vodka MasterChef contract
        address alpRewardHandler; // ALP Reward Handler contract
    }

    // @dev StrategyMisc struct represents miscellaneous parameters of the strategy
    struct StrategyMisc {
        uint256 MAX_LEVERAGE; // Maximum allowed leverage
        uint256 MIN_LEVERAGE; // Minimum allowed leverage
        uint256 DECIMAL; // Decimal precision
        uint256 MAX_BPS; // Maximum basis points
    }

    // @dev FeeConfiguration struct represents fee-related parameters of the strategy
    struct FeeConfiguration {
        address feeReceiver; // Fee receiver address
        uint256 withdrawalFee; // Withdrawal fee amount
        address waterFeeReceiver; // Water fee receiver address
        uint256 liquidatorsRewardPercentage; // Liquidator's reward percentage
        uint256 fixedFeeSplit; // Fixed fee split amount
    }

    event SetWhitelistedAsset(address token, bool status);
    event SetStrategyAddresses(address diamond, address alpManager, address apolloXP);
    event SetFeeConfiguration(
        address feeReceiver,
        uint256 withdrawalFee,
        address waterFeeReceiver,
        uint256 liquidatorsRewardPercentage,
        uint256 fixedFeeSplit
    );
    event CAKEHarvested(uint256 amount);

    /**
     * @dev Emitted when a position is opened.
     * @param user The address of the user who opened the position.
     * @param leverageSize The size of the leverage used for the position.
     * @param amountDeposited The amount deposited by the user.
     * @param podAmountMinted The amount of POD tokens minted for the position.
     * @param positionId The ID of the position opened.
     * @param time The timestamp when the position was opened.
     */
    event OpenPosition(
        address indexed user,
        uint256 leverageSize,
        uint256 amountDeposited,
        uint256 podAmountMinted,
        uint256 positionId,
        uint256 time
    );

    /**
     * @dev Emitted when a position is closed.
     * @param user The address of the user who closed the position.
     * @param amountAfterFee The amount remaining after fees are deducted.
     * @param positionId The ID of the closed position.
     * @param timestamp The timestamp when the position was closed.
     * @param position The final position after closure.
     * @param leverageSize The size of the leverage used for the position.
     * @param time The timestamp of the event emission.
     */
    event ClosePosition(address user, uint256 amountAfterFee, uint256 positionId, uint256 timestamp, uint256 position, uint256 leverageSize, uint256 time);

    /**
     * @dev Emitted when a position is liquidated.
     * @param user The address of the user whose position is liquidated.
     * @param positionId The ID of the liquidated position.
     * @param liquidator The address of the user who performed the liquidation.
     * @param returnedAmount The amount returned after liquidation.
     * @param liquidatorRewards The rewards given to the liquidator.
     * @param time The timestamp of the liquidation event.
     */
    event Liquidated(address user, uint256 positionId, address liquidator, uint256 returnedAmount, uint256 liquidatorRewards, uint256 time);
    event SetBurner(address indexed burner, bool allowed);
    event SetAllowedClosers(address indexed closer, bool allowed);
    event SetAllowedSenders(address indexed sender, bool allowed);
    event MigrateLP(address indexed newLP, uint256 amount);

    /**
     * @dev Opens a new position.
     * @param _token The address of the token for the position.
     * @param _amount The amount of tokens to be used for the position.
     * @param _leverage The leverage multiplier for the position.
     *
     * Requirements:
     * - `_leverage` must be within the range of MIN_LEVERAGE to MAX_LEVERAGE.
     * - `_amount` must be greater than zero.
     * - `_token` must be whitelisted.
     *
     * Steps:
     * - Transfers `_amount` of tokens from the caller to this contract.
     * - Uses Water contract to lend a leveraged amount based on the provided `_amount` and `_leverage`.
     * - Mints Alp tokens using `_token` and `sumAmount` to participate in ApolloX.
     * - Deposits minted Alp tokens into the SmartChef contract.
     * - Records user information including deposit, leverage, position, etc.
     * - Mints POD tokens for the user.
     *
     * Emits an OpenPosition event with relevant details.
     */
    function openPosition(address _token, uint256 _amount, uint256 _leverage) external;

    /**
     * @dev Closes a position based on provided parameters.
     * @param positionId The ID of the position to close.
     * @param _user The address of the user holding the position.
     *
     * Requirements:
     * - Position must not be liquidated.
     * - Position must have enough shares to close.
     * - Caller must be allowed to close the position or must be the position owner.
     *
     * Steps:
     * - Retrieves user information for the given position.
     * - Validates that the position is not liquidated and has enough shares to close.
     * - Handles the POD token for the user.
     * - Withdraws the staked amount from the Smart Chef contract.
     * - Burns Alp tokens to retrieve USDC based on the position amount.
     * - Calculates profits, water repayment, and protocol fees.
     * - Repays the Water contract if the position is not liquidated.
     * - Transfers profits, fees, and protocol fees to the respective receivers.
     * - Takes protocol fees if applicable and emits a ClosePosition event.
     */
    function closePosition(uint256 positionId, address _user) external;

    /**
     * @dev Liquidates a position based on provided parameters.
     * @param _positionId The ID of the position to be liquidated.
     * @param _user The address of the user owning the position.
     *
     * Requirements:
     * - Position must not be already liquidated.
     * - Liquidation request must exist for the provided user.
     * - Liquidation should not exceed the predefined debt-to-value limit.
     *
     * Steps:
     * - Retrieves user information for the given position.
     * - Validates the position for liquidation based on the debt-to-value limit.
     * - Handles the POD token for the user.
     * - Burns Alp tokens to retrieve USDC based on the position amount.
     * - Calculates liquidator rewards and performs debt repayment to the Water contract.
     * - Transfers liquidator rewards and emits a Liquidated event.
     */
    function liquidatePosition(uint256 _positionId, address _user) external;

    /**
     * @dev Retrieves the current position and its previous value in USDC for a user's specified position.
     * @param _positionID The identifier for the user's position.
     * @param _shares The number of shares for the position.
     * @param _user The user's address.
     * @return currentPosition The current position value in USDC.
     * @return previousValueInUSDC The previous position value in USDC.
     */
    function getCurrentPosition(
        uint256 _positionID,
        uint256 _shares,
        address _user
    ) external view returns (uint256 currentPosition, uint256 previousValueInUSDC);

    /**
     * @dev Retrieves the updated debt values for a user's specified position.
     * @param _positionID The identifier for the user's position.
     * @param _user The user's address.
     * @return currentDTV The current Debt to Value (DTV) ratio.
     * @return currentPosition The current position value in USDC.
     * @return currentDebt The current amount of debt associated with the position.
     */
    function getUpdatedDebt(
        uint256 _positionID,
        address _user
    ) external view returns (uint256 currentDTV, uint256 currentPosition, uint256 currentDebt);

    /**
     * @dev Retrieves the cooling duration of the APL token from the AlpManagerFacet.
     * @return The cooling duration in seconds.
     */
    function getAlpCoolingDuration() external view returns (uint256);

    /**
     * @dev Retrieves an array containing all registered user addresses.
     * @return An array of all registered user addresses.
     */
    function getAllUsers() external view returns (address[] memory);

    /**
     * @dev Retrieves the total number of open positions associated with a specific user.
     * @param _user The user's address.
     * @return The total number of open positions belonging to the specified user.
     */
    function getTotalNumbersOfOpenPositionBy(address _user) external view returns (uint256);

    /**
     * @dev Retrieves the current price of the APL token from the AlpManagerFacet.
     * @return The current price of the APL token.
     */
    function getAlpPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAlpManager {
    function ALP() external view returns (address);

    function coolingDuration() external view returns (uint256);

    function setCoolingDuration(uint256 coolingDuration_) external;

    function mintAlp(address tokenIn, uint256 amount, uint256 minAlp, bool stake) external;

    function mintAlpBNB(uint256 minAlp, bool stake) external payable;

    function burnAlp(address tokenOut, uint256 alpAmount, uint256 minOut, address receiver) external;

    function burnAlpBNB(uint256 alpAmount, uint256 minOut, address payable receiver) external;

    function alpPrice() external view returns (uint256);

    function lastMintedTimestamp(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISmartChefInitializable {
    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt;
    }
    function userInfo(address _user) external view returns (UserInfo memory);
    function pendingReward(address _user) external view returns (uint256);
    function rewardToken() external view returns (address);
    function hasUserLimit() external view returns (bool);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMasterChef {
    function unstakeAndLiquidate(uint256 pid, address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IWater {
    function lend(uint256 _amount, address _receiver) external returns (bool);

    function repayDebt(uint256 leverage, uint256 debtValue) external returns (bool);

    function getTotalDebt() external view returns (uint256);

    function updateTotalDebt(uint256 profit) external returns (uint256);

    function totalAssets() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function balanceOfAsset() external view returns (uint256);
    function getUtilizationRate() external view returns (uint256);

    function asset() external view returns (address);
    function increaseTotalUSDC(uint256 amount) external;
}