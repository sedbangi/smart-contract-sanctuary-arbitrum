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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IExchangeRouter {
    struct CreateDepositParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minMarketTokens;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }
    /**
     * @param receiver The address that will receive the withdrawal tokens.
     * @param callbackContract The contract that will be called back.
     * @param market The market on which the withdrawal will be executed.
     * @param minLongTokenAmount The minimum amount of long tokens that must be withdrawn.
     * @param minShortTokenAmount The minimum amount of short tokens that must be withdrawn.
     * @param shouldUnwrapNativeToken Whether the native token should be unwrapped when executing the withdrawal.
     * @param executionFee The execution fee for the withdrawal.
     * @param callbackGasLimit The gas limit for calling the callback contract.
     */
    struct CreateWithdrawalParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    function createDeposit(
        CreateDepositParams memory params
    ) external returns (bytes32);

    function createWithdrawal(
        CreateWithdrawalParams calldata params
    ) external returns (bytes32);

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function sendWnt(address receiver, uint256 amount) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(
        uint256 _pid,
        address _user
    ) external view returns (uint256, uint256);

    function unstakeAndLiquidate(
        uint256 _pid,
        address user,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IWaterLendingHandler {    

    function getAssetsAddresses(address _longToken, address _shortToken) external view returns (address, address);
    function borrow(uint256 _amount, uint256 _leverage, address _longToken) external returns (uint256, uint256);
    function getUtilizationRate(address _waterVault) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IMasterChef.sol";
import "./interfaces/Gmx/IExchangeRouter.sol";
import "./interfaces/IWaterLendingHandler.sol";

// import "hardhat/console.sol";

interface IVodkaV2GMXHandler {
    function getEstimatedMarketTokenPrice(address _longToken) external view returns (int256);

    function tempPayableAddress() external view returns (address);

    function executeSwap(uint256 _amount, address _tokenIn, address _tokenOut, address _recipient) external returns (uint256);

    function getLatestData(address _token, bool _inDecimal) external view returns (uint256);
}

interface IWater {
    function repayDebt(uint256 leverage, uint256 debtValue) external;
}

contract VodkaVaultV2 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC20BurnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct PositionInfo {
        uint256 deposit;
        uint256 position;
        uint256 price;
        uint256 closedPositionValue;
        uint256 closePNL;
        address user;
        uint32 positionId;
        address liquidator;
        uint16 leverageMultiplier;
        bool closed;
        bool liquidated;
        address longToken;
    }

    struct PositionDebt {
        uint256 longDebtValue;
        uint256 shortDebtValue;
    }

    struct FeeConfiguration {
        uint256 withdrawalFee;
        uint256 liquidatorsRewardPercentage;
        address feeReceiver;
        address longTokenWaterFeeReceiver;
        address shortTokenWaterFeeReceiver;
        uint256 fixedFeeSplit;
        uint256 gmxOpenCloseFees;
    }

    struct ExtraData {
        uint256 toLeverageUser;
        uint256 waterProfit;
        uint256 leverageUserProfit;
        uint256 positionPreviousValue;
        uint256 profits;
        address longToken;
    }

    struct DepositRecord {
        address user;
        uint256 depositedAmount;
        uint256 receivedMarketTokens;
        uint256 shortTokenBorrowed;
        uint256 longTokenBorrowed;
        uint256 feesPaid;
        bool success;
        uint16 leverageMultiplier;
        address longToken;
    }

    struct WithdrawRecord {
        address user;
        uint256 returnedUSDC;
        // uint256 feesPaid;
        // uint256 profits;
        uint256 positionID;
        bool success;
        bool isLiquidation;
        address longToken;
        uint256 returnedLongAmount;
        address liquidator;
    }

    struct GMXAddresses {
        address depositHandler;
        address withdrawalHandler;
        address depositVault;
        address withdrawVault;
        address gmxRouter;
        address exchangeRouter;
    }

    struct GMXPoolAddresses {
        address longToken;
        address shortToken;
        address marketToken;
        address indexToken;
        address longTokenVault;
        address shortTokenVault;
    }

    struct StrategyAddresses {
        address USDC;
        address MasterChef;
        address WaterContract;
        address VodkaHandler;
        address WETH;
        address WaterLendingHandler;
        address univ3Router;
    }

    struct UserDebtAdjustmentValues {
        uint256 longDebtValue;
        uint256 shortDebtValue;
    }

    struct DebtAdjustmentValues {
        uint256 debtAdjustment;
        uint256 time;
        uint256 debtValueRatio;
    }

    struct StrategyMisc {
        uint256 MAX_LEVERAGE;
        uint256 MIN_LEVERAGE;
        uint256 DECIMAL;
        uint256 MAX_BPS;
    }

    FeeConfiguration public feeConfiguration;
    GMXAddresses public gmxAddresses;
    StrategyAddresses public strategyAddresses;
    StrategyMisc public strategyMisc;

    address[] public allUsers;
    address public keeper;
    uint256 public MCPID;

    uint256 public timeAdjustment;
    uint256 public DTVLimit;
    uint256 public DTVSlippage;
    uint256 private defaultDebtAdjustment;

    mapping(address => PositionInfo[]) public positionInfo;
    mapping(address => PositionDebt[]) public positionDebt;
    mapping(bytes32 => DepositRecord) public depositRecord;
    mapping(address => bytes32[]) public userDepositKeyRecords;
    mapping(bytes32 => WithdrawRecord) public withdrawRecord;
    mapping(address => bytes32[]) public userWithdrawKeyRecords;
    mapping(address => bool) public allowedSenders;
    mapping(address => bool) public burner;
    mapping(address => bool) public isUser;
    mapping(address => bool) public isWhitelistedAsset;
    mapping(address => GMXPoolAddresses) public gmxPoolAddresses;
    mapping(address => mapping(uint256 => UserDebtAdjustmentValues)) public userDebtAdjustmentValue;
    mapping(address => mapping(uint256 => bool)) public inCloseProcess;
    mapping(address => DebtAdjustmentValues) public debtAdjustmentValues;

    uint256[50] private __gaps;
    uint256 public mFeePercent;
    address public mFeeReceiver;
    uint256 public vaultMaturityTime;
    mapping(address => mapping(uint256 => uint256)) private positionOpenTimestamp;
    mapping(address => bool) public allowedClosers;

    modifier InvalidID(uint256 positionId, address user) {
        require(positionId < positionInfo[user].length, "Vodka: positionID is not valid");
        _;
    }

    modifier onlyBurner() {
        require(burner[msg.sender], "Not allowed to burn");
        _;
    }

    modifier onlyHandler() {
        require(msg.sender == strategyAddresses.VodkaHandler, "Not allowed to burn");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Not allowed to burn");
        _;
    }

    /** --------------------- Event --------------------- */
    event ProtocolFeeChanged(
        address newFeeReceiver,
        uint256 newWithdrawalFee,
        address newLongVaultWaterFeeReceiver,
        address newShortVaultWaterFeeReceiver,
        uint256 liquidatorsRewardPercentage,
        uint256 gmxFees
    );
    event Deposited(
        address indexed depositer,
        uint256 depositTokenAmount,
        uint256 createdAt,
        uint256 GMXMarketAmount,
        address longToken,
        uint256 _positionID
    );
    event Liquidation(
        address indexed liquidator,
        address indexed borrower,
        uint256 positionId,
        uint256 liquidatedAmount,
        uint256 outputAmount,
        uint256 time
    );

    event SetAllowedSenders(address indexed sender, bool allowed);
    event SetBurner(address indexed burner, bool allowed);

    event Liquidated(address indexed user, uint256 indexed positionId, address liquidator, uint256 amount, uint256 reward);
    event WithdrawalFulfilled(
        address indexed user,
        uint256 amount,
        uint256 time,
        uint256 returnedUSDC,
        uint256 waterProfit,
        uint256 leverageUserProfit,
        address longToken,
        uint256 positionID,
        uint256 gmTokenWithdrawnAmount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _waterLendingHandler) external initializer {
        strategyAddresses.WaterLendingHandler = _waterLendingHandler;
        defaultDebtAdjustment = 1e18;

        strategyMisc.MAX_LEVERAGE = 10_000;
        strategyMisc.MIN_LEVERAGE = 2_000;
        strategyMisc.DECIMAL = 1e18;
        strategyMisc.MAX_BPS = 100_000;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC20_init("VodkaV2DN", "V2DNPOD");
    }

    /** ----------- Change onlyOwner functions ------------- */
    function setVaultMaturityTime(uint256 _timeInSeconds) external onlyOwner {
        vaultMaturityTime = _timeInSeconds;
    }
    function setCloser(address _closer, bool _allowed) public onlyOwner {
        allowedClosers[_closer] = _allowed;
    }

    function setAllowed(address _sender, bool _allowed) public onlyOwner {
        allowedSenders[_sender] = _allowed;
        // emit SetAllowedSenders(_sender, _allowed);
    }

    function setMFeePercent(uint256 _mFeePercent, address _mFeeReceiver) external onlyOwner {
        //require(_mFeePercent <= 10000, "Invalid mFeePercent");
        mFeeReceiver = _mFeeReceiver;
        mFeePercent = _mFeePercent;
    }

    function setDTVLimit(uint256 _DTVLimit, uint256 _DTVSlippage) public onlyOwner {
        //require(_DTVSlippage <= 1000, "Slippage < 1000");
        DTVLimit = _DTVLimit;
        DTVSlippage = _DTVSlippage;
    }

    function setAssetWhitelist(
        address _asset,
        address _longToken,
        address _shortToken,
        address _marketToken,
        address _indexToken,
        bool _status,
        address _longTokenVault,
        address _shortTokenVault
    ) public onlyOwner {
        GMXPoolAddresses storage gmp = gmxPoolAddresses[_asset];
        gmp.longToken = _longToken;
        gmp.shortToken = _shortToken;
        gmp.marketToken = _marketToken;
        gmp.indexToken = _indexToken;
        isWhitelistedAsset[_asset] = _status;
        gmp.longTokenVault = _longTokenVault;
        gmp.shortTokenVault = _shortTokenVault;
        IERC20Upgradeable(_marketToken).transfer(msg.sender, IERC20Upgradeable(_marketToken).balanceOf(address(this)));
    }

    // function setBurner(address _burner, bool _allowed) public onlyOwner {
    //     burner[_burner] = _allowed;
        // emit SetBurner(_burner, _allowed);
    // }

    function setStrategyParams(
        address _MasterChef,
        uint256 _MCPID,
        address _water,
        address _VodkaHandler,
        address _usdc,
        address _lendingHandler,
        address _uniRouter,
        address _keeper,
        uint256 _maxLeverage,
        uint256 _minLeverage
    ) public onlyOwner {
        // require(_maxLeverage >= _minLeverage, "Max < min lev");
        strategyAddresses.MasterChef = _MasterChef;
        strategyAddresses.WaterContract = _water;
        strategyAddresses.VodkaHandler = _VodkaHandler;
        strategyAddresses.USDC = _usdc;
        strategyAddresses.WaterLendingHandler = _lendingHandler;
        strategyAddresses.univ3Router = _uniRouter;
        MCPID = _MCPID;
        keeper = _keeper;
        strategyMisc.MAX_LEVERAGE = _maxLeverage;
        strategyMisc.MIN_LEVERAGE = _minLeverage;
    }

    function setProtocolFee(
        address _feeReceiver,
        uint256 _withdrawalFee,
        address _longTokenWaterFeeReceiver,
        address _shortTokenWaterFeeReceiver,
        uint256 _liquidatorsRewardPercentage,
        uint256 _fixedFeeSplit,
        uint256 _gmxOpenCloseFees
    ) external onlyOwner {
        feeConfiguration.feeReceiver = _feeReceiver;
        feeConfiguration.withdrawalFee = _withdrawalFee;
        feeConfiguration.longTokenWaterFeeReceiver = _longTokenWaterFeeReceiver;
        feeConfiguration.shortTokenWaterFeeReceiver = _shortTokenWaterFeeReceiver;
        feeConfiguration.liquidatorsRewardPercentage = _liquidatorsRewardPercentage;
        feeConfiguration.fixedFeeSplit = _fixedFeeSplit;
        feeConfiguration.gmxOpenCloseFees = _gmxOpenCloseFees;

        // emit ProtocolFeeChanged(
        //     _feeReceiver,
        //     _withdrawalFee,
        //     _longTokenWaterFeeReceiver,
        //     _shortTokenWaterFeeReceiver,
        //     _liquidatorsRewardPercentage,
        //     _gmxOpenCloseFees
        // );
    }

    function setGmxContracts(
        address _depositHandler,
        address _withdrawalHandler,
        address _depositVault,
        address _gmxRouter,
        address _exchangeRouter,
        address _withdrawVault
    ) external onlyOwner {
        gmxAddresses.depositHandler = _depositHandler;
        gmxAddresses.withdrawalHandler = _withdrawalHandler;
        gmxAddresses.depositVault = _depositVault;
        gmxAddresses.gmxRouter = _gmxRouter;
        gmxAddresses.exchangeRouter = _exchangeRouter;
        gmxAddresses.withdrawVault = _withdrawVault;
    }

    function setDebtValueRatio(address _waterVault, uint256 _debtValueRatio, uint256 _timeAdjustment) external onlyOwner {
        DebtAdjustmentValues storage _debtAdjustmentValues = debtAdjustmentValues[_waterVault];
        _debtAdjustmentValues.debtValueRatio = _debtValueRatio;
        timeAdjustment = _timeAdjustment;
    }

    // function withdrawArb(address _arb, address _to) external onlyKeeper {
    //     IERC20Upgradeable(_arb).safeTransfer(_to, IERC20Upgradeable(_arb).balanceOf(address(this)));
    // }

    //@TODO ADD ONLY KEEPER BACK
    function updateDebtAdjustment(address _waterVault) external onlyKeeper {
        DebtAdjustmentValues storage _debtAdjustmentValues = debtAdjustmentValues[_waterVault];

        // ensure time difference when last update was made is greater than 72 hours
        // require(block.timestamp - _debtAdjustmentValues.time > timeAdjustment, "Time !> 72hrs");

        _debtAdjustmentValues.debtAdjustment =
            _debtAdjustmentValues.debtAdjustment +
            (_debtAdjustmentValues.debtAdjustment * _debtAdjustmentValues.debtValueRatio) /
            strategyMisc.DECIMAL;
        _debtAdjustmentValues.time = block.timestamp;
    }

    // function pause() external onlyOwner {
    //     _pause();
    // }

    /** ----------- View functions ------------- */

    function getEstimatedGMPrice(address _longToken) public view returns (uint256) {
        int256 gmPrice = IVodkaV2GMXHandler(strategyAddresses.VodkaHandler).getEstimatedMarketTokenPrice(_longToken);
        return uint256(gmPrice);
    }

    function getAllUsers() public view returns (address[] memory) {
        return allUsers;
    }

    function getPositionOpenTimestamp(address _user, uint256 _positionId) external view returns(uint256) {
        return positionOpenTimestamp[_user][_positionId];
    }

    function getTotalOpenPosition(address _user) public view returns (uint256) {
        return positionInfo[_user].length;
    }

    function getUpdatedDebt(uint256 _positionID, address _user) public view returns (uint256, uint256, uint256) {
        PositionInfo memory _positionInfo = positionInfo[_user][_positionID];
        PositionDebt memory pb = positionDebt[_user][_positionID];
        if (_positionInfo.closed || _positionInfo.liquidated) return (0, 0, 0);

        (uint256 currentPosition, ) = getEstimatedCurrentPosition(_positionID, _user);

        uint256 longTokenOwed = (pb.longDebtValue *
            IVodkaV2GMXHandler(strategyAddresses.VodkaHandler).getLatestData(_positionInfo.longToken, true)) /
            strategyMisc.DECIMAL /
            1e6;

        uint256 owedToWater = longTokenOwed + pb.shortDebtValue;
        uint256 currentDTV = (owedToWater * strategyMisc.DECIMAL) / currentPosition;

        return (currentDTV, owedToWater, currentPosition);
    }

    function getEstimatedCurrentPosition(
        uint256 _positionID,
        address _user
    ) public view returns (uint256 currentValueInUSDC, uint256 previousValueInUSDC) {
        PositionInfo memory _positionInfo = positionInfo[_user][_positionID];

        return (
            _convertGMXMarketToUSDC(_positionInfo.position, getEstimatedGMPrice(_positionInfo.longToken)),
            _convertGMXMarketToUSDC(_positionInfo.position, _positionInfo.price)
        );
    }

    /** ----------- User functions ------------- */

    function requestOpenPosition(uint256 _amount, uint16 _leverage, address _longAsset) external payable whenNotPaused {
        require(_leverage >= strategyMisc.MIN_LEVERAGE && _leverage <= strategyMisc.MAX_LEVERAGE, "VodkaV2: Invalid leverage");
        require(_amount > 0, "VodkaV2: amount must > zero");
        require(isWhitelistedAsset[_longAsset], "VodkaV2: !whitelisted");
        require(msg.value == feeConfiguration.gmxOpenCloseFees, "VodkaV2: !fee");

        IERC20Upgradeable(strategyAddresses.USDC).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 amount = _amount;

        GMXPoolAddresses memory gmp = gmxPoolAddresses[_longAsset];

        (uint256 longTokenAmount, uint256 shortTokenAmount) = IWaterLendingHandler(strategyAddresses.WaterLendingHandler).borrow(
            amount,
            _leverage,
            gmp.longToken
        );

        IERC20Upgradeable(gmp.longToken).safeIncreaseAllowance(gmxAddresses.gmxRouter, longTokenAmount);
        IERC20Upgradeable(gmp.shortToken).safeIncreaseAllowance(gmxAddresses.gmxRouter, shortTokenAmount + amount);

        IExchangeRouter(gmxAddresses.exchangeRouter).sendTokens(gmp.longToken, gmxAddresses.depositVault, longTokenAmount);
        IExchangeRouter(gmxAddresses.exchangeRouter).sendTokens(gmp.shortToken, gmxAddresses.depositVault, shortTokenAmount + amount);

        IExchangeRouter(gmxAddresses.exchangeRouter).sendWnt{ value: msg.value }(gmxAddresses.depositVault, msg.value);

        IExchangeRouter.CreateDepositParams memory params = IExchangeRouter.CreateDepositParams({
            receiver: address(this),
            callbackContract: strategyAddresses.VodkaHandler,
            uiFeeReceiver: msg.sender,
            market: gmp.marketToken,
            initialLongToken: gmp.longToken,
            initialShortToken: gmp.shortToken,
            longTokenSwapPath: new address[](0),
            shortTokenSwapPath: new address[](0),
            minMarketTokens: 0,
            shouldUnwrapNativeToken: false,
            executionFee: feeConfiguration.gmxOpenCloseFees,
            callbackGasLimit: 2000000
        });

        bytes32 key = IExchangeRouter(gmxAddresses.exchangeRouter).createDeposit(params);

        DepositRecord storage dr = depositRecord[key];

        dr.depositedAmount = amount;
        dr.shortTokenBorrowed = shortTokenAmount;
        dr.longTokenBorrowed = longTokenAmount;
        dr.feesPaid = msg.value;
        dr.user = msg.sender;
        dr.leverageMultiplier = _leverage;
        dr.longToken = gmp.longToken;
        userDepositKeyRecords[msg.sender].push(key);
    }

    function fulfillOpenPosition(bytes32 key, uint256 _receivedTokens) public onlyHandler returns (bool) {
        DepositRecord storage dr = depositRecord[key];
        address user = dr.user;
        require(user != address(0), "VodkaV2: deposit !found");
        dr.receivedMarketTokens = _receivedTokens;
        PositionInfo memory _positionInfo = PositionInfo({
            user: dr.user,
            deposit: dr.depositedAmount,
            leverageMultiplier: dr.leverageMultiplier,
            position: dr.receivedMarketTokens,
            price: ((((dr.depositedAmount * dr.leverageMultiplier) / 1000) * 1e12) * strategyMisc.DECIMAL) / dr.receivedMarketTokens,
            liquidated: false,
            closedPositionValue: 0,
            liquidator: address(0),
            closePNL: 0,
            positionId: uint32(positionInfo[user].length),
            closed: false,
            longToken: dr.longToken
        });

        PositionDebt memory pb = PositionDebt({ longDebtValue: dr.longTokenBorrowed, shortDebtValue: dr.shortTokenBorrowed });

        positionDebt[user].push(pb);

        //frontend helper to fetch all users and then their userInfo
        if (isUser[user] == false) {
            isUser[user] = true;
            allUsers.push(user);
        }
        GMXPoolAddresses memory gmp = gmxPoolAddresses[dr.longToken];

        userDebtAdjustmentValue[dr.user][positionInfo[user].length] = UserDebtAdjustmentValues({
            longDebtValue: debtAdjustmentValues[gmp.longTokenVault].debtAdjustment,
            shortDebtValue: debtAdjustmentValues[gmp.shortTokenVault].debtAdjustment
        });

        positionOpenTimestamp[user][positionInfo[user].length] = block.timestamp;


        positionInfo[user].push(_positionInfo);
        // mint gmx shares to user
        _mint(user, dr.receivedMarketTokens);

        dr.success = true;

        emit Deposited(
            user,
            _positionInfo.deposit,
            block.timestamp,
            dr.receivedMarketTokens,
            dr.longToken,
            (positionInfo[user].length - 1)
        );

        return true;
    }

    function requestClosePosition(uint256 _positionID, address _user) external payable InvalidID(_positionID, _user) nonReentrant {
        PositionInfo storage _positionInfo = positionInfo[_user][_positionID];
        require(!_positionInfo.liquidated && !_positionInfo.closed, "Position is closed or liquidated");
        require(_positionInfo.position > 0, "Position is not enough");
        require(msg.sender == _positionInfo.user || allowedClosers[msg.sender], "!allowed");
        require(!inCloseProcess[_user][_positionID], "ongoing");
        require(msg.value == feeConfiguration.gmxOpenCloseFees, "VodkaV2: !fee");
        if (allowedClosers[msg.sender]) {
            require(block.timestamp >= positionOpenTimestamp[_user][_positionID] + vaultMaturityTime, "VodkaV2: !Mature date");
        }

        GMXPoolAddresses memory gmp = gmxPoolAddresses[_positionInfo.longToken];
        _actualizeExtraDebt(gmp, _positionID, _user);

        (uint256 currentDTV, , ) = getUpdatedDebt(_positionID, _user);
        if (currentDTV >= (DTVSlippage * DTVLimit) / 1000) {
            revert("liquidation");
        }

        IExchangeRouter.CreateWithdrawalParams memory params = _sendTokenAndCreateWithdrawalParams(gmp, _positionInfo.position);

        bytes32 key = IExchangeRouter(gmxAddresses.exchangeRouter).createWithdrawal(params);

        WithdrawRecord storage wr = withdrawRecord[key];
        wr.user = _user;
        wr.positionID = _positionID;
        wr.longToken = _positionInfo.longToken;
        userWithdrawKeyRecords[_user].push(key);
        inCloseProcess[_user][_positionID] = true;
    }

    function fulfillClosePosition(
        bytes32 _key,
        uint256 _returnedLongAmount, // debt from longToken vault
        uint256 _returnedUSDC, // debt from shortToken vault + profits and deposit amount (if there is profit)
        uint256 _profit
    ) public onlyHandler returns (bool) {
        WithdrawRecord storage wr = withdrawRecord[_key];
        PositionInfo storage _positionInfo = positionInfo[wr.user][wr.positionID];
        ExtraData memory extraData;
        PositionDebt storage pb = positionDebt[wr.user][wr.positionID];
        GMXPoolAddresses memory gmp = gmxPoolAddresses[wr.longToken];

        require(inCloseProcess[wr.user][wr.positionID], "!ongoing");
        require(!wr.success, "Already closed");

        _handlePODToken(wr.user, _positionInfo.position);
        uint256 positionID = wr.positionID;
        uint256 gmMarketAmount = _positionInfo.position;

        wr.returnedUSDC = _returnedUSDC;
        wr.returnedLongAmount = _returnedLongAmount;
        extraData.longToken = wr.longToken;

        extraData.positionPreviousValue = pb.shortDebtValue + _positionInfo.deposit;
        uint256 mFee;

        _positionInfo.closed = true;
        wr.success = true;

        if (_profit > 0) {
            extraData.profits = _profit;
            uint256 split = (feeConfiguration.fixedFeeSplit * _positionInfo.leverageMultiplier + (feeConfiguration.fixedFeeSplit * 10000)) /
                100;
            extraData.waterProfit = (extraData.profits * split) / 10000;
            mFee = (_profit * mFeePercent) / 10000;
            extraData.leverageUserProfit = extraData.profits - (extraData.waterProfit + mFee);
            _payWaterProfits(extraData.waterProfit, gmp.longToken, gmp.shortToken);
        }

        uint256 shortTokenVaultPayment;
        if (wr.returnedUSDC < (pb.shortDebtValue + extraData.profits)) {
            _positionInfo.liquidator = wr.user;
            _positionInfo.liquidated = true;
            shortTokenVaultPayment = wr.returnedUSDC;
        } else {
            extraData.toLeverageUser = (wr.returnedUSDC - pb.shortDebtValue - extraData.profits) + extraData.leverageUserProfit;
            shortTokenVaultPayment = wr.returnedUSDC - extraData.toLeverageUser - extraData.waterProfit - mFee;
        }

        _settleWaterDebt(_key, shortTokenVaultPayment, _returnedLongAmount);

        if (mFee > 0) {
            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(mFeeReceiver, mFee);
        }

        if (_positionInfo.liquidated) {
            return (false);
        }

        uint256 userShortAmountAfterFee;
        if (feeConfiguration.withdrawalFee > 0) {
            uint256 fee = (extraData.toLeverageUser * feeConfiguration.withdrawalFee) / strategyMisc.MAX_BPS;
            IERC20Upgradeable(gmp.shortToken).safeTransfer(feeConfiguration.feeReceiver, fee);
            userShortAmountAfterFee = extraData.toLeverageUser - fee;
        } else {
            userShortAmountAfterFee = extraData.toLeverageUser;
        }

        IERC20Upgradeable(gmp.shortToken).safeTransfer(wr.user, userShortAmountAfterFee);

        _positionInfo.closedPositionValue = wr.returnedUSDC;
        // _positionInfo.closePNL = _returnedUSDC;

        emit WithdrawalFulfilled(
            _positionInfo.user,
            userShortAmountAfterFee,
            block.timestamp,
            wr.returnedUSDC,
            extraData.waterProfit,
            extraData.leverageUserProfit,
            extraData.longToken,
            positionID,
            gmMarketAmount
        );
        return (true);
    }

    function fulfillCancelDeposit(address longToken) external onlyHandler {
        GMXPoolAddresses memory gmp = gmxPoolAddresses[longToken];
        IERC20Upgradeable(gmp.longToken).safeTransfer(msg.sender, IERC20MetadataUpgradeable(gmp.longToken).balanceOf(address(this)));
        IERC20Upgradeable(gmp.shortToken).safeTransfer(msg.sender, IERC20MetadataUpgradeable(gmp.shortToken).balanceOf(address(this)));
    }

    function fulfillCancelWithdrawal(bytes32 key) external onlyHandler {
        inCloseProcess[withdrawRecord[key].user][withdrawRecord[key].positionID] = false;
    }

    function requestLiquidatePosition(address _user, uint256 _positionID) external payable nonReentrant {
        PositionInfo storage _positionInfo = positionInfo[_user][_positionID];
        GMXPoolAddresses memory gmp = gmxPoolAddresses[_positionInfo.longToken];
        _actualizeExtraDebt(gmp, _positionID, _user);
        require(!_positionInfo.liquidated, "Already liquidated");
        require(!inCloseProcess[_user][_positionID], "ongoing");
        require(_positionInfo.user != address(0), "Request !exist");
        (uint256 currentDTV, , ) = getUpdatedDebt(_positionID, _user);
        require(currentDTV >= (DTVLimit * DTVSlippage) / 1000, "Threshold !reached");
        uint256 assetToBeLiquidated = _positionInfo.position;

        IExchangeRouter.CreateWithdrawalParams memory params = _sendTokenAndCreateWithdrawalParams(gmp, assetToBeLiquidated);

        bytes32 key = IExchangeRouter(gmxAddresses.exchangeRouter).createWithdrawal(params);

        WithdrawRecord storage wr = withdrawRecord[key];
        wr.user = _user;
        wr.positionID = _positionID;
        wr.isLiquidation = true;
        wr.liquidator = msg.sender;
        wr.longToken = _positionInfo.longToken;
        userWithdrawKeyRecords[_user].push(key);
        inCloseProcess[_user][_positionID] = true;
    }

    function fulfillLiquidation(bytes32 _key, uint256 _returnedLongAmount, uint256 _returnedUSDC) external onlyHandler returns (bool) {
        WithdrawRecord storage wr = withdrawRecord[_key];
        PositionInfo storage _positionInfo = positionInfo[wr.user][wr.positionID];
        PositionDebt memory pb = positionDebt[wr.user][wr.positionID];
        GMXPoolAddresses memory gmp = gmxPoolAddresses[wr.longToken];
        wr.returnedUSDC = _returnedUSDC;
        _handlePODToken(wr.user, _positionInfo.position);
        require(!_positionInfo.liquidated, "Already liquidated");
        require(inCloseProcess[wr.user][wr.positionID], "!ongoing");
        uint256 gmTokenWithdrawnAmount = _positionInfo.position;

        _positionInfo.liquidated = true;
        _positionInfo.closed = true;
        wr.success = true;

        if (_returnedUSDC > pb.shortDebtValue) {
            wr.returnedUSDC -= pb.shortDebtValue;

            uint256 liquidatorReward = (wr.returnedUSDC * feeConfiguration.liquidatorsRewardPercentage) / strategyMisc.MAX_BPS;

            IERC20Upgradeable(strategyAddresses.USDC).safeTransfer(wr.liquidator, liquidatorReward);

            uint256 leftovers = wr.returnedUSDC - liquidatorReward;
            if (leftovers > 0) {
                IERC20Upgradeable(gmp.shortToken).safeTransfer(wr.user, leftovers);
            } 
            _settleWaterDebt(_key, pb.shortDebtValue, _returnedLongAmount);
        } else {
            _settleWaterDebt(_key, _returnedUSDC, _returnedLongAmount);
        }

        emit Liquidation(msg.sender, wr.user, wr.positionID, gmTokenWithdrawnAmount, wr.returnedUSDC, block.timestamp);
        return (true);
    }

    /** ----------- Token functions ------------- */

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

    /** ----------- Internal functions ------------- */

    function _settleWaterDebt(bytes32 _key, uint256 _shortTokenValue, uint256 _longTokenValue) internal {
        WithdrawRecord memory wr = withdrawRecord[_key];
        PositionDebt memory pb = positionDebt[wr.user][wr.positionID];
        GMXPoolAddresses memory gmp = gmxPoolAddresses[wr.longToken];
        IERC20Upgradeable(gmp.shortToken).safeIncreaseAllowance(gmp.shortTokenVault, _shortTokenValue);
        IERC20Upgradeable(gmp.longToken).safeIncreaseAllowance(gmp.longTokenVault, _longTokenValue);
        IWater(gmp.shortTokenVault).repayDebt(pb.shortDebtValue, _shortTokenValue);
        IWater(gmp.longTokenVault).repayDebt(pb.longDebtValue, _longTokenValue);
    }

    function _sendTokenAndCreateWithdrawalParams(
        GMXPoolAddresses memory gmp,
        uint256 assetToBeLiquidated
    ) internal returns (IExchangeRouter.CreateWithdrawalParams memory) {
        IERC20Upgradeable(gmp.marketToken).approve(gmxAddresses.gmxRouter, assetToBeLiquidated);
        IExchangeRouter(gmxAddresses.exchangeRouter).sendWnt{ value: msg.value }(gmxAddresses.withdrawVault, msg.value);
        IExchangeRouter(gmxAddresses.exchangeRouter).sendTokens(gmp.marketToken, gmxAddresses.withdrawVault, assetToBeLiquidated);
        return
            IExchangeRouter.CreateWithdrawalParams({
                receiver: strategyAddresses.VodkaHandler,
                callbackContract: strategyAddresses.VodkaHandler,
                uiFeeReceiver: msg.sender,
                market: gmp.marketToken,
                longTokenSwapPath: new address[](0),
                shortTokenSwapPath: new address[](0),
                minLongTokenAmount: 0,
                minShortTokenAmount: 0,
                shouldUnwrapNativeToken: false,
                executionFee: feeConfiguration.gmxOpenCloseFees,
                callbackGasLimit: 2000000
            });
    }

    function _actualizeExtraDebt(GMXPoolAddresses memory gmp, uint256 _positionID, address _user) internal {
        PositionDebt storage pb = positionDebt[_user][_positionID];

        uint256 previousLongTokenVaultDA = userDebtAdjustmentValue[_user][_positionID].longDebtValue;
        uint256 previousShortTokenVaultDA = userDebtAdjustmentValue[_user][_positionID].shortDebtValue;

        uint256 longTokenDebtAdjustment = debtAdjustmentValues[gmp.longTokenVault].debtAdjustment;
        uint256 shortTokenDebtAdjustment = debtAdjustmentValues[gmp.shortTokenVault].debtAdjustment;

        if (longTokenDebtAdjustment > previousLongTokenVaultDA) {
            pb.longDebtValue = (pb.longDebtValue * longTokenDebtAdjustment) / previousLongTokenVaultDA;
            userDebtAdjustmentValue[_user][_positionID].longDebtValue = longTokenDebtAdjustment;
        }

        if (shortTokenDebtAdjustment > previousShortTokenVaultDA) {
            pb.shortDebtValue = (pb.shortDebtValue * shortTokenDebtAdjustment) / previousShortTokenVaultDA;
            userDebtAdjustmentValue[_user][_positionID].shortDebtValue = shortTokenDebtAdjustment;
        }
    }

    function _convertGMXMarketToUSDC(uint256 _amount, uint256 _GMXMarketPrice) internal pure returns (uint256) {
        return ((_amount * _GMXMarketPrice) / (10 ** 18)) / 1e12;
    }

    function _handlePODToken(address _user, uint256 position) internal {
        if (strategyAddresses.MasterChef != address(0)) {
            uint256 userBalance = balanceOf(_user);
            if (userBalance >= position) {
                _burn(_user, position);
            } else {
                _burn(_user, userBalance);
                uint256 remainingPosition = position - userBalance;
                IMasterChef(strategyAddresses.MasterChef).unstakeAndLiquidate(MCPID, _user, remainingPosition);
            }
        } else {
            _burn(_user, position);
        }
    }

    function _payWaterProfits(uint256 _waterProfit, address longToken, address shortToken) internal {
        // with a ratio of 50% to longTokenVault and 50% to shortTokenVault
        uint256 longTokenWaterProfit = _waterProfit / 2;
        uint256 shortTokenWaterProfit = _waterProfit - longTokenWaterProfit;
        // transfer longTokenWaterProfit to vodka handler for swap
        IERC20Upgradeable(shortToken).safeTransfer(strategyAddresses.VodkaHandler, longTokenWaterProfit);
        // swap longTokenWaterProfit to longToken
        uint256 amountOut = IVodkaV2GMXHandler(strategyAddresses.VodkaHandler).executeSwap(
            longTokenWaterProfit,
            shortToken,
            longToken,
            address(this)
        );
        IERC20Upgradeable(longToken).safeTransfer(feeConfiguration.longTokenWaterFeeReceiver, amountOut);
        IERC20Upgradeable(shortToken).safeTransfer(feeConfiguration.shortTokenWaterFeeReceiver, shortTokenWaterProfit);
    }

    receive() external payable {
        require(msg.sender == gmxAddresses.depositVault || msg.sender == gmxAddresses.withdrawVault, "Not gmx");
        payable(IVodkaV2GMXHandler(strategyAddresses.VodkaHandler).tempPayableAddress()).transfer(address(this).balance);
    }
}