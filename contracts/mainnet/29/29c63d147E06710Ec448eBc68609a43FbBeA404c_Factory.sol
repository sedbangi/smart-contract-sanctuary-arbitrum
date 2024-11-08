// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
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
    function __ERC721_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
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
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
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
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(
            ERC721Upgradeable.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );

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
            try
                IERC721ReceiverUpgradeable(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return
                    retval ==
                    IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
        uint256 /* firstTokenId */,
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
library Counters {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
library StorageSlot {
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

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
pragma solidity ^0.8.7;

import "./proxy.sol";
import "./ZetaChain/ZetaImpl.sol";
import "./LayerZero/LayerZeroImpl.sol";
import "./helper.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ISafe {
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address proxy);

    function isOwner(address owner) external view returns (bool);
}

contract Deployer is Initializable, Helper {
    address private ERC20Implementation;
    address private ERC721Implementation;

    address private safe;
    address private singleton;

    address public zetaImpl;
    address public lzImpl;

    address private owner;

    string private salt =
        "0x0000000000000000000000000000000000000000000000000000000000000001";

    function initialize(
        address ERC20ImplementationAddress,
        address ERC721ImplementationAddress,
        address _safe,
        address _singleton,
        address _zetaImpl,
        address _lzImpl
    ) external initializer {
        //Setting ERC20 implementation contract for the reference
        ERC20Implementation = ERC20ImplementationAddress;

        //Setting ERC721 implementation contract for the reference
        ERC721Implementation = ERC721ImplementationAddress;

        safe = _safe;
        singleton = _singleton;

        zetaImpl = _zetaImpl;
        lzImpl = _lzImpl;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function defineContracts(
        address _ERC20ImplementationAddress,
        address _ERC721ImplementationAddress,
        address _safe,
        address _singleton,
        address _zetaImpl,
        address _lzImpl
    ) external onlyOwner {
        ERC20Implementation = _ERC20ImplementationAddress;
        ERC721Implementation = _ERC721ImplementationAddress;
        safe = _safe;
        singleton = _singleton;
        zetaImpl = _zetaImpl;
        lzImpl = _lzImpl;
    }

    function deployERC20DAO(
        address _owner,
        bytes calldata _data
    ) external returns (address ERC20DAO) {
        ERC20DAO = address(
            new ProxyContract(ERC20Implementation, _owner, _data)
        );
    }

    function deployERC721DAO(
        address _owner,
        bytes calldata _data
    ) external returns (address ERC721DAO) {
        ERC721DAO = address(
            new ProxyContract(ERC721Implementation, _owner, _data)
        );
    }

    function getNonce(address _daoAddress) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_daoAddress, salt)));
    }

    function deploySAFE(
        address[] calldata _admins,
        uint256 _safeThreshold,
        address _daoAddress
    ) external returns (address SAFE) {
        bytes memory _initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _admins,
            _safeThreshold,
            0x0000000000000000000000000000000000000000,
            "0x",
            0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4,
            0x0000000000000000000000000000000000000000,
            0,
            0x0000000000000000000000000000000000000000
        );

        uint256 nonce = getNonce(_daoAddress);
        do {
            try
                ISafe(safe).createProxyWithNonce(singleton, _initializer, nonce)
            returns (address _deployedSafe) {
                SAFE = _deployedSafe;
            } catch Error(string memory reason) {
                nonce = getNonce(_daoAddress);
                revert SafeProxyCreationFailed(reason);
            } catch {
                revert SafeProxyCreationFailed("Safe proxy creation failed");
            }
        } while (SAFE == address(0));
    }

    function getCommunicationLayer(
        uint16 _commLayerId
    ) external view returns (address commLayer) {
        if (_commLayerId == 1) {
            commLayer = zetaImpl;
        } else {
            commLayer = lzImpl;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title StationXFactory Emitter Contract
/// @dev Contract Emits events for Factory and Proxy
contract Emitter is Initializable, AccessControl {
    bytes32 constant ADMIN = keccak256("ADMIN");
    bytes32 public constant EMITTER = keccak256("EMITTER");
    bytes32 public constant FACTORY = keccak256("FACTORY");

    //FACTORY EVENTS
    event DefineContracts(
        address indexed factory,
        address ERC20ImplementationAddress,
        address ERC721ImplementationAddress,
        address emitterImplementationAddress
    );

    event ChangeMerkleRoot(
        address indexed factory,
        address indexed daoAddress,
        bytes32 newMerkleRoot
    );

    event CreateDaoErc20(
        address indexed deployerAddress,
        address indexed proxy,
        string name,
        string symbol,
        uint256 distributionAmount,
        uint256 pricePerToken,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 ownerFee,
        uint256 _days,
        uint256 quorum,
        uint256 threshold,
        address depositTokenAddress,
        address emitter,
        address gnosisAddress,
        bool isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    );

    event CreateDaoErc721(
        address indexed deployerAddress,
        address indexed proxy,
        string name,
        string symbol,
        string tokenURI,
        uint256 pricePerToken,
        uint256 distributionAmount,
        uint256 maxTokensPerUser,
        uint256 ownerFee,
        uint256 _days,
        uint256 quorum,
        uint256 threshold,
        address depositTokenAddress,
        address emitter,
        address gnosisAddress,
        bool isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    );

    event FactoryCreated(
        address indexed _ERC20Implementation,
        address indexed _ERC721Implementation,
        address indexed _factory,
        address _emitter
    );

    //PROXY EVENTS
    event Deposited(
        address indexed _daoAddress,
        address indexed _depositor,
        address indexed _depositTokenAddress,
        uint256 _amount,
        uint256 _timeStamp,
        uint256 _ownerFee,
        uint256 _adminShare
    );

    event StartDeposit(
        address indexed _proxy,
        uint256 startTime,
        uint256 closeTime
    );

    event CloseDeposit(address indexed _proxy, uint256 closeTime);

    event UpdateMinMaxDeposit(
        address indexed _proxy,
        uint256 _minDeposit,
        uint256 _maxDeposit
    );

    event UpdateOwnerFee(address indexed _proxy, uint256 _ownerFee);

    event AirDropToken(
        address indexed _daoAddress,
        address _token,
        address _to,
        uint256 _amount
    );

    event MintGTToAddress(
        address indexed _daoAddress,
        uint256[] _amount,
        address[] _userAddress
    );

    event UpdateGovernanceSettings(
        address indexed _daoAddress,
        uint256 _quorum,
        uint256 _threshold
    );

    event UpdateDistributionAmount(
        address indexed _daoAddress,
        uint256 _amount
    );

    event UpdatePricePerToken(address indexed _daoAddress, uint256 _amount);

    event SendCustomToken(
        address indexed _daoAddress,
        address _token,
        uint256[] _amount,
        address[] _addresses
    );

    event NewUser(
        address indexed _daoAddress,
        address indexed _depositor,
        address indexed _depositTokenAddress,
        uint256 _depositTokenAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    );

    event NewUserCC(
        address indexed _daoAddress,
        address indexed _depositor,
        address indexed _depositTokenAddress,
        uint256 _depositTokenAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    );

    //nft events
    event MintNft(
        address indexed _to,
        address indexed _daoAddress,
        string _tokenURI,
        uint256 _tokenId
    );

    event UpdateMaxTokensPerUser(
        address indexed _daoAddress,
        uint256 _maxTokensPerUser
    );

    event UpdateTotalSupplyOfToken(
        address indexed _daoAddress,
        uint256 _totalSupplyOfToken
    );

    event UpdateTokenTransferability(
        address indexed _daoAddress,
        bool _isTokenTransferable
    );

    event WhitelistAddress(
        address indexed _daoAddress,
        address indexed _address
    );

    event RemoveWhitelistAddress(
        address indexed _daoAddress,
        address indexed _address
    );

    event DeployRefundModule(
        address _refundModule,
        address _safe,
        address _daoAddress,
        bytes32 _merkleRoot
    );

    event RefundERC20DAO(
        address _user,
        address _daoAddress,
        address _refundModule,
        address _transferToken,
        uint256 _burnAmount,
        uint256 _transferAmount
    );

    event RefundERC721DAO(
        address _user,
        address _daoAddress,
        address _refundModule,
        address _transferToken,
        uint256 _tokenId,
        uint256 _transferAmount
    );

    event ChangeRefundModuleMerkleRoot(
        address indexed _refundModule,
        address indexed _daoAddress,
        bytes32 _newMerkleRoot
    );

    event CreateCCDAO(address _daoAddress, uint256[] _chainIds);

    event TransferGT(
        address indexed _daoAddress,
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event ChangedSigners(
        address indexed _daoAddress,
        address indexed _signer,
        bool indexed _isAdded
    );

    address public factoryAddress;

    function initialize(
        address _ERC20Implementation,
        address _ERC721Implementation,
        address _factory
    ) external initializer {
        _grantRole(ADMIN, msg.sender);
        _grantRole(FACTORY, _factory);
        _grantRole(EMITTER, _factory);
        factoryAddress = _factory;
        emit FactoryCreated(
            _ERC20Implementation,
            _ERC721Implementation,
            _factory,
            address(this)
        );
    }

    function changeFactory(address _newFactory) external onlyRole(ADMIN) {
        _revokeRole(FACTORY, factoryAddress);
        _grantRole(FACTORY, _newFactory);
        _revokeRole(EMITTER, factoryAddress);
        _grantRole(EMITTER, _newFactory);
        factoryAddress = _newFactory;
    }

    function allowActionContract(
        address _actionContract
    ) external onlyRole(ADMIN) {
        _grantRole(EMITTER, _actionContract);
    }

    function defineContracts(
        address ERC20ImplementationAddress,
        address ERC721ImplementationAddress,
        address emitterImplementationAddress
    ) external payable onlyRole(FACTORY) {
        emit DefineContracts(
            msg.sender,
            ERC20ImplementationAddress,
            ERC721ImplementationAddress,
            emitterImplementationAddress
        );
    }

    function changeMerkleRoot(
        address factory,
        address daoAddress,
        bytes32 newMerkleRoot
    ) external payable onlyRole(FACTORY) {
        emit ChangeMerkleRoot(factory, daoAddress, newMerkleRoot);
    }

    function createDaoErc20(
        address _deployerAddress,
        address _proxy,
        string memory _name,
        string memory _symbol,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _ownerFee,
        uint256 _totalDays,
        uint256 _quorum,
        uint256 _threshold,
        address _depositTokenAddress,
        address _emitter,
        address _gnosisAddress,
        bool _isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    ) external payable onlyRole(FACTORY) {
        _grantRole(EMITTER, _proxy);
        _grantRole(EMITTER, msg.sender);
        emit CreateDaoErc20(
            _deployerAddress,
            _proxy,
            _name,
            _symbol,
            _distributionAmount,
            _pricePerToken,
            _minDeposit,
            _maxDeposit,
            _ownerFee,
            _totalDays,
            _quorum,
            _threshold,
            _depositTokenAddress,
            _emitter,
            _gnosisAddress,
            _isGovernanceActive,
            isTransferable,
            assetsStoredOnGnosis
        );
    }

    function createDaoErc721(
        address _deployerAddress,
        address _proxy,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _pricePerToken,
        uint256 _distributionAmount,
        uint256 _maxTokensPerUser,
        uint256 _ownerFee,
        uint256 _totalDays,
        uint256 _quorum,
        uint256 _threshold,
        address _depositTokenAddress,
        address _emitter,
        address _gnosisAddress,
        bool _isGovernanceActive,
        bool isTransferable,
        bool assetsStoredOnGnosis
    ) external payable onlyRole(FACTORY) {
        _grantRole(EMITTER, _proxy);
        _grantRole(EMITTER, msg.sender);

        emit CreateDaoErc721(
            _deployerAddress,
            _proxy,
            _name,
            _symbol,
            _tokenURI,
            _pricePerToken,
            _distributionAmount,
            _maxTokensPerUser,
            _ownerFee,
            _totalDays,
            _quorum,
            _threshold,
            _depositTokenAddress,
            _emitter,
            _gnosisAddress,
            _isGovernanceActive,
            isTransferable,
            assetsStoredOnGnosis
        );
    }

    function deposited(
        address _daoAddress,
        address _depositor,
        address _depositTokenAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _ownerFee,
        uint256 _adminShare
    ) external onlyRole(EMITTER) {
        emit Deposited(
            _daoAddress,
            _depositor,
            _depositTokenAddress,
            _amount,
            _timestamp,
            _ownerFee,
            _adminShare
        );
    }

    function newUser(
        address _daoAddress,
        address _depositor,
        address _depositTokenAddress,
        uint256 _depositTokenAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    ) external onlyRole(EMITTER) {
        emit NewUser(
            _daoAddress,
            _depositor,
            _depositTokenAddress,
            _depositTokenAmount,
            _timeStamp,
            _gtToken,
            _isAdmin
        );
    }

    function newUserCC(
        address _daoAddress,
        address _depositor,
        address _depositTokenAddress,
        uint256 _depositTokenAmount,
        uint256 _timeStamp,
        uint256 _gtToken,
        bool _isAdmin
    ) external onlyRole(EMITTER) {
        emit NewUserCC(
            _daoAddress,
            _depositor,
            _depositTokenAddress,
            _depositTokenAmount,
            _timeStamp,
            _gtToken,
            _isAdmin
        );
    }

    function startDeposit(
        address _proxy,
        uint256 _startTime,
        uint256 _closeTime
    ) external onlyRole(EMITTER) {
        emit StartDeposit(_proxy, _startTime, _closeTime);
    }

    function closeDeposit(
        address _proxy,
        uint256 _closeTime
    ) external onlyRole(EMITTER) {
        emit CloseDeposit(_proxy, _closeTime);
    }

    function updateMinMaxDeposit(
        address _proxy,
        uint256 _minDeposit,
        uint256 _maxDeposit
    ) external onlyRole(EMITTER) {
        emit UpdateMinMaxDeposit(_proxy, _minDeposit, _maxDeposit);
    }

    function updateOwnerFee(
        address _proxy,
        uint256 _ownerFee
    ) external onlyRole(EMITTER) {
        emit UpdateOwnerFee(_proxy, _ownerFee);
    }

    function airDropToken(
        address _proxy,
        address _token,
        address _to,
        uint256 _amount
    ) external onlyRole(EMITTER) {
        emit AirDropToken(_proxy, _token, _to, _amount);
    }

    function mintGTToAddress(
        address _proxy,
        uint256[] memory _amount,
        address[] memory _userAddress
    ) external onlyRole(EMITTER) {
        emit MintGTToAddress(_proxy, _amount, _userAddress);
    }

    function updateGovernanceSettings(
        address _proxy,
        uint256 _quorum,
        uint256 _threshold
    ) external onlyRole(EMITTER) {
        emit UpdateGovernanceSettings(_proxy, _quorum, _threshold);
    }

    function updateDistributionAmount(
        address _daoAddress,
        uint256 _distributionAmount
    ) external onlyRole(EMITTER) {
        emit UpdateDistributionAmount(_daoAddress, _distributionAmount);
    }

    function updatePricePerToken(
        address _daoAddress,
        uint256 _pricePerToken
    ) external onlyRole(EMITTER) {
        emit UpdatePricePerToken(_daoAddress, _pricePerToken);
    }

    function sendCustomToken(
        address _daoAddress,
        address _token,
        uint256[] memory _amount,
        address[] memory _addresses
    ) external onlyRole(EMITTER) {
        emit SendCustomToken(_daoAddress, _token, _amount, _addresses);
    }

    function mintNft(
        address _to,
        address _implementation,
        string memory _tokenURI,
        uint256 _tokenId
    ) external onlyRole(EMITTER) {
        emit MintNft(_to, _implementation, _tokenURI, _tokenId);
    }

    function updateMaxTokensPerUser(
        address _nftAddress,
        uint256 _maxTokensPerUser
    ) external onlyRole(EMITTER) {
        emit UpdateMaxTokensPerUser(_nftAddress, _maxTokensPerUser);
    }

    function updateTotalSupplyOfToken(
        address _nftAddress,
        uint256 _totalSupplyOfToken
    ) external onlyRole(EMITTER) {
        emit UpdateTotalSupplyOfToken(_nftAddress, _totalSupplyOfToken);
    }

    function updateTokenTransferability(
        address _nftAddress,
        bool _isTokenTransferable
    ) external onlyRole(EMITTER) {
        emit UpdateTokenTransferability(_nftAddress, _isTokenTransferable);
    }

    function whitelistAddress(
        address _nftAddress,
        address _address
    ) external onlyRole(EMITTER) {
        emit WhitelistAddress(_nftAddress, _address);
    }

    function removeWhitelistAddress(
        address _nftAddress,
        address _address
    ) external onlyRole(EMITTER) {
        emit RemoveWhitelistAddress(_nftAddress, _address);
    }

    function deployRefundModule(
        address _refundModule,
        address _safe,
        address _dao,
        bytes32 _merkleRoot
    ) external onlyRole(EMITTER) {
        _grantRole(EMITTER, _refundModule);
        emit DeployRefundModule(_refundModule, _safe, _dao, _merkleRoot);
    }

    function refundERC20DAO(
        address _user,
        address _dao,
        address _refundModule,
        address _transferToken,
        uint256 _burnAmount,
        uint256 _transferAmount
    ) external onlyRole(EMITTER) {
        emit RefundERC20DAO(
            _user,
            _dao,
            _refundModule,
            _transferToken,
            _burnAmount,
            _transferAmount
        );
    }

    function refundERC721DAO(
        address _user,
        address _dao,
        address _refundModule,
        address _transferToken,
        uint256 _tokenId,
        uint256 _transferAmount
    ) external onlyRole(EMITTER) {
        emit RefundERC721DAO(
            _user,
            _dao,
            _refundModule,
            _transferToken,
            _tokenId,
            _transferAmount
        );
    }

    function changeRefundModuleMerkleRoot(
        address _refundModule,
        address _daoAddress,
        bytes32 newMerkleRoot
    ) external onlyRole(EMITTER) {}

    function createCCDao(
        address _dao,
        uint256[] memory _chainIds
    ) external onlyRole(EMITTER) {
        emit CreateCCDAO(_dao, _chainIds);
    }

    function transferGT(
        address _dao,
        address _from,
        address _to,
        uint256 _value
    ) external onlyRole(EMITTER) {
        emit TransferGT(_dao, _from, _to, _value);
    }

    function changedSigners(
        address _dao,
        address _signer,
        bool _isAdded
    ) external onlyRole(EMITTER) {
        emit ChangedSigners(_dao, _signer, _isAdded);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./factory.sol";
import "./emitter.sol";
import "./helper.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

/// @title StationX Governance Token Contract
/// @dev Base Contract as a reference for DAO Governance Token contract proxies
contract ERC20DAO is
    ERC20Upgradeable,
    AccessControl,
    IERC721Receiver,
    ReentrancyGuard,
    Helper
{
    using SafeERC20 for IERC20;

    ///@dev address of the emitter contract
    address public emitterContractAddress;

    address public factoryAddress;

    ERC20DAOdetails public erc20DaoDetails;

    bytes32 constant RefundModule = keccak256("RefundModule");

    constructor() {
        _disableInitializers();
    }

    /// @dev initialize Function to initialize Token contract
    function initializeERC20(
        address _factory,
        address _emitter,
        string memory _DaoName,
        string memory _DaoSymbol,
        uint256 _quorum,
        uint256 _threshold,
        bool _isGovernanceActive,
        bool _isTransferable,
        bool _onlyAllowWhitelist,
        address _owner
    ) external initializer {
        factoryAddress = _factory;
        emitterContractAddress = _emitter;
        ERC20DAOdetails memory _erc20DaoDetails = ERC20DAOdetails(
            _DaoName,
            _DaoSymbol,
            _quorum,
            _threshold,
            _isGovernanceActive,
            _isTransferable,
            _onlyAllowWhitelist,
            _owner
        );
        erc20DaoDetails = _erc20DaoDetails;

        __ERC20_init(_DaoName, _DaoSymbol);
    }

    /// @dev This function returns details of a particular dao
    function getERC20DAOdetails()
        external
        view
        returns (ERC20DAOdetails memory)
    {
        return erc20DaoDetails;
    }

    /// @dev Function execute proposals called by gnosis safe
    /// @param _data function signature data encoded along with parameters
    function updateProposalAndExecution(
        address _contract,
        bytes memory _data
    ) external onlyGnosis(factoryAddress, address(this)) nonReentrant {
        if (_contract == address(0))
            revert AddressInvalid("_contract", _contract);
        (bool success, ) = _contract.call(_data);
        require(success);
    }

    /// @dev Function to transfer NFT from this contract
    /// @param _nft address of nft to transfer
    /// @param _to address of receiver
    /// @param _tokenId tokenId of nft to transfer
    function transferNft(
        address _nft,
        address _to,
        uint256 _tokenId
    ) external onlyCurrentContract {
        if (_nft == address(0)) revert AddressInvalid("_nft", _nft);
        if (_to == address(0)) revert AddressInvalid("_to", _to);
        IERC721(_nft).safeTransferFrom(address(this), _to, _tokenId);
    }

    /// @dev function to mint GT token to a addresses
    /// @param _amountArray array of amount to be transferred
    /// @param _userAddress array of address where the amount should be transferred
    function mintGTToAddress(
        uint256[] memory _amountArray,
        address[] memory _userAddress
    ) external onlyCurrentContract {
        if (_amountArray.length != _userAddress.length)
            revert ArrayLengthMismatch(
                _amountArray.length,
                _userAddress.length
            );

        uint256 leng = _amountArray.length;
        for (uint256 i; i < leng; ) {
            _mint(_userAddress[i], _amountArray[i]);
            Emitter(emitterContractAddress).newUser(
                address(this),
                _userAddress[i],
                Factory(factoryAddress)
                    .getDAOdetails(address(this))
                    .depositTokenAddress,
                0,
                block.timestamp,
                _amountArray[i],
                Safe(
                    Factory(factoryAddress)
                        .getDAOdetails(address(this))
                        .gnosisAddress
                ).isOwner(_userAddress[i])
            );

            unchecked {
                ++i;
            }
        }

        Emitter(emitterContractAddress).mintGTToAddress(
            address(this),
            _amountArray,
            _userAddress
        );
    }

    /// @dev function to update governance settings
    /// @param _quorum update quorum into the contract
    /// @param _threshold update threshold into the contract
    function updateGovernanceSettings(
        uint256 _quorum,
        uint256 _threshold
    ) external onlyCurrentContract {
        if (_quorum == 0) revert AmountInvalid("_quorum", _quorum);
        if (_threshold == 0) revert AmountInvalid("_threshold", _threshold);

        if (!(_quorum <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_quorum", _quorum);
        if (!(_threshold <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_threshold", _threshold);

        erc20DaoDetails.quorum = _quorum;
        erc20DaoDetails.threshold = _threshold;

        Emitter(emitterContractAddress).updateGovernanceSettings(
            address(this),
            _quorum,
            _threshold
        );
    }

    /// @dev Function to change governance active
    /// @param _isGovernanceActive New governance active status
    function updateGovernanceActive(
        bool _isGovernanceActive
    ) external payable onlyCurrentContract {
        erc20DaoDetails.isGovernanceActive = _isGovernanceActive;
    }

    /// @dev Function to update token transferability for a particular token contract
    /// @param _isTokenTransferable New token transferability
    function updateTokenTransferability(
        bool _isTokenTransferable
    ) external payable onlyCurrentContract {
        erc20DaoDetails.isTransferable = _isTokenTransferable;

        Emitter(emitterContractAddress).updateTokenTransferability(
            address(this),
            _isTokenTransferable
        );
    }

    /// @dev Function to set whitelist to true for a particular token contract
    function toggleOnlyAllowWhitelist() external payable onlyCurrentContract {
        erc20DaoDetails.onlyAllowWhitelist = !erc20DaoDetails
            .onlyAllowWhitelist;
    }

    /// @dev Function to override transfer to restrict token transfers
    function transfer(
        address to,
        uint256 amount
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        require(erc20DaoDetails.isTransferable, "Token Non Transferable");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        Emitter(emitterContractAddress).transferGT(
            address(this),
            owner,
            to,
            amount
        );
        return true;
    }

    /// @dev Function to override transferFrom to restrict token transfers
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        require(erc20DaoDetails.isTransferable, "Token Non Transferable");

        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        Emitter(emitterContractAddress).transferGT(
            address(this),
            from,
            to,
            amount
        );
        return true;
    }

    /// @dev Function to mint Governance Token and assign delegate
    /// @param to Address to which tokens will be minted
    /// @param amount Value of tokens to be minted based on deposit by DAO member
    function mintToken(address to, uint256 amount) public {
        require(msg.sender == factoryAddress || msg.sender == address(this));
        _mint(to, amount);
    }

    // -- Who will have access control for burning tokens?
    /// @dev Function to burn Governance Token
    /// @param account Address from where token will be burned
    /// @param amount Value of tokens to be burned
    function burn(
        address account,
        uint256 amount
    ) external onlyRole(RefundModule) {
        _burn(account, amount);
    }

    function grantRefundModule(
        address _refundModule
    ) external payable onlyCurrentContract {
        _grantRole(RefundModule, _refundModule);
    }

    /// @dev Internal function that needs to be override
    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function emitSignerChanged(
        address _dao,
        address _signer,
        bool _isAdded
    ) external onlyGnosis(factoryAddress, address(this)) {
        Emitter(emitterContractAddress).changedSigners(_dao, _signer, _isAdded);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./interfaces/IEmitter.sol";
import "./factory.sol";

contract ERC721DAO is ERC721Upgradeable, AccessControl, ERC2981, Helper {
    using SafeERC20 for IERC20;

    uint256 public _tokenIdTracker;

    mapping(uint256 => string) private _tokenURIs;

    address public factoryAddress;

    address public emitterAddress;

    ERC721DAOdetails public erc721DaoDetails;

    bytes32 constant RefundModule = keccak256("RefundModule");

    constructor() {
        _disableInitializers();
    }

    /// @dev initialize Function to initialize NFT Token contract
    /// @param _DaoName name of DAO
    /// @param _DaoSymbol symbol of DAO
    function initializeERC721(
        string calldata _DaoName,
        string calldata _DaoSymbol,
        address _factoryAddress,
        address _emitterAddress,
        uint256 _quorum,
        uint256 _threshold,
        uint256 _maxTokensPerUser,
        bool _isTransferable,
        bool _isNftTotalSupplyUnlimited,
        bool _isGovernanceActive,
        bool _onlyAllowWhitelist,
        address _owner
    ) external initializer {
        factoryAddress = _factoryAddress;
        emitterAddress = _emitterAddress;
        erc721DaoDetails = ERC721DAOdetails(
            _DaoName,
            _DaoSymbol,
            _quorum,
            _threshold,
            _maxTokensPerUser,
            _isTransferable,
            _isNftTotalSupplyUnlimited,
            _isGovernanceActive,
            _onlyAllowWhitelist,
            _owner
        );

        __ERC721_init(_DaoName, _DaoSymbol);
    }

    /// @dev This function returns details of a particular dao
    function getERC721DAOdetails()
        external
        view
        returns (ERC721DAOdetails memory)
    {
        return erc721DaoDetails;
    }

    /// @dev Function to mint Governance Token and assign delegate
    /// @param _to Address to which tokens will be minted
    function mintToken(
        address _to,
        string calldata _tokenURI,
        uint256 _amount
    ) public onlyFactory(factoryAddress) {
        if (balanceOf(_to) + _amount > erc721DaoDetails.maxTokensPerUser)
            revert MaxTokensMintedForUser(_to);

        if (!erc721DaoDetails.isNftTotalSupplyUnlimited) {
            require(
                Factory(factoryAddress)
                    .getDAOdetails(address(this))
                    .distributionAmount >= _tokenIdTracker + _amount,
                "Max supply reached"
            );
        }
        for (uint256 i; i < _amount; ) {
            _tokenIdTracker += 1;
            _safeMint(_to, _tokenIdTracker);
            _setTokenURI(_tokenIdTracker, _tokenURI);
            unchecked {
                ++i;
            }
        }
        IEmitter(emitterAddress).mintNft(
            _to,
            address(this),
            _tokenURI,
            _tokenIdTracker
        );
    }

    /// @dev Function execute proposals called by gnosis safe
    /// @param _data function signature data encoded along with parameters
    function updateProposalAndExecution(
        address _contract,
        bytes memory _data
    ) external onlyGnosis(factoryAddress, address(this)) {
        if (_contract == address(0))
            revert AddressInvalid("_contract", _contract);
        (bool success, ) = _contract.call(_data);
        require(success);
    }

    /// @dev Function to transfer NFT from this contract
    /// @param _nft address of nft to transfer
    /// @param _to address of receiver
    /// @param _tokenId tokenId of nft to transfer
    function transferNft(
        address _nft,
        address _to,
        uint256 _tokenId
    ) external onlyCurrentContract {
        if (_nft == address(0)) revert AddressInvalid("_nft", _nft);
        if (_to == address(0)) revert AddressInvalid("_to", _to);
        IERC721(_nft).safeTransferFrom(address(this), _to, _tokenId);
    }

    /// @dev Function to change governance active
    /// @param _isGovernanceActive New governance active status
    function updateGovernanceActive(
        bool _isGovernanceActive
    ) external payable onlyCurrentContract {
        erc721DaoDetails.isGovernanceActive = _isGovernanceActive;
    }

    /// @param _amountArray array of amount to be transferred
    /// @param _tokenURI array of token uri for each nft
    /// @param _userAddress array of address where the amount should be transferred
    function mintGTToAddress(
        uint256[] memory _amountArray,
        string[] memory _tokenURI,
        address[] memory _userAddress
    ) external onlyCurrentContract {
        if (_tokenURI.length != _userAddress.length)
            revert ArrayLengthMismatch(_tokenURI.length, _userAddress.length);

        if (_amountArray.length != _userAddress.length)
            revert ArrayLengthMismatch(
                _amountArray.length,
                _userAddress.length
            );

        uint256 length = _userAddress.length;
        for (uint256 i; i < length; ) {
            if (!erc721DaoDetails.isNftTotalSupplyUnlimited) {
                require(
                    Factory(factoryAddress)
                        .getDAOdetails(address(this))
                        .distributionAmount >=
                        _tokenIdTracker + _amountArray[i],
                    "Max supply reached"
                );
            }
            for (uint j; j < _amountArray[i]; ) {
                if (
                    balanceOf(_userAddress[i]) + _amountArray[i] >
                    erc721DaoDetails.maxTokensPerUser
                ) revert MaxTokensMintedForUser(_userAddress[i]);

                _tokenIdTracker += 1;
                _safeMint(_userAddress[i], _tokenIdTracker);
                _setTokenURI(_tokenIdTracker, _tokenURI[i]);
                unchecked {
                    ++j;
                }
            }

            IEmitter(emitterAddress).newUser(
                address(this),
                _userAddress[i],
                Factory(factoryAddress)
                    .getDAOdetails(address(this))
                    .depositTokenAddress,
                0,
                block.timestamp,
                _amountArray[i],
                Safe(
                    Factory(factoryAddress)
                        .getDAOdetails(address(this))
                        .gnosisAddress
                ).isOwner(_userAddress[i])
            );

            unchecked {
                ++i;
            }
        }

        IEmitter(emitterAddress).mintGTToAddress(
            address(this),
            _amountArray,
            _userAddress
        );
    }

    /// @dev function to update governance settings
    /// @param _quorum update quorum into the contract
    /// @param _threshold update threshold into the contract
    function updateGovernanceSettings(
        uint256 _quorum,
        uint256 _threshold
    ) external onlyCurrentContract {
        if (_quorum == 0) revert AmountInvalid("_quorum", _quorum);
        if (_threshold == 0) revert AmountInvalid("_threshold", _threshold);

        if (!(_quorum <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_quorum", _quorum);
        if (!(_threshold <= FLOAT_HANDLER_TEN_4))
            revert AmountInvalid("_threshold", _threshold);

        erc721DaoDetails.quorum = _quorum;
        erc721DaoDetails.threshold = _threshold;

        IEmitter(emitterAddress).updateGovernanceSettings(
            address(this),
            _quorum,
            _threshold
        );
    }

    /// @dev Function to set whitelist to true for a particular token contract
    function toggleOnlyAllowWhitelist() external payable onlyCurrentContract {
        erc721DaoDetails.onlyAllowWhitelist = !erc721DaoDetails
            .onlyAllowWhitelist;
    }

    /// @dev Function to update nft transferability for a particular token contract
    /// @param _isNftTransferable New nft transferability
    function updateTokenTransferability(
        bool _isNftTransferable
    ) external payable onlyCurrentContract {
        erc721DaoDetails.isTransferable = _isNftTransferable;

        IEmitter(emitterAddress).updateTokenTransferability(
            address(this),
            _isNftTransferable
        );
    }

    function updateMaxTokensPerUser(
        uint256 _maxTokensPerUser
    ) external payable onlyCurrentContract {
        erc721DaoDetails.maxTokensPerUser = _maxTokensPerUser;
        IEmitter(emitterAddress).updateMaxTokensPerUser(
            address(this),
            _maxTokensPerUser
        );
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        return _tokenURIs[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721Upgradeable) {
        require(balanceOf(to) <= erc721DaoDetails.maxTokensPerUser);
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        require(erc721DaoDetails.isTransferable, "NFT Non Transferable");

        _transfer(from, to, tokenId);
        IEmitter(emitterAddress).transferGT(address(this), from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721Upgradeable) {
        require(balanceOf(to) <= erc721DaoDetails.maxTokensPerUser);
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        require(erc721DaoDetails.isTransferable, "NFT Non Transferable");
        _safeTransfer(from, to, tokenId, data);
        IEmitter(emitterAddress).transferGT(address(this), from, to, tokenId);
    }

    function burn(uint256 tokenId) external onlyRole(RefundModule) {
        _burn(tokenId);
    }

    function grantRefundModule(
        address _refundModule
    ) external payable onlyCurrentContract {
        _grantRole(RefundModule, _refundModule);
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setRoyalty(
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public onlyCurrentContract {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function emitSignerChanged(
        address _dao,
        address _signer,
        bool _isAdded
    ) external onlyGnosis(factoryAddress, address(this)) {
        IEmitter(emitterAddress).changedSigners(_dao, _signer, _isAdded);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IERC20DAO.sol";
import "./interfaces/IERC721DAO.sol";
import "./interfaces/IDeployer.sol";
import "./helper.sol";
import "./interfaces/IEmitter.sol";
import "./interfaces/ICommLayer.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IWrappedToken {
    function deposit() external payable;
}

/// @title StationXFactory Cloning Contract
/// @dev Contract create proxies of DAO Token and Governor contract
contract Factory is Helper {
    using SafeERC20 for IERC20;

    address private ERC20Implementation;
    address private ERC721Implementation;
    address private emitterAddress;
    address private constant wrappedTokenAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private safe;
    address private singleton;
    address private _owner;

    //Mapping to get details of a particular dao
    mapping(address => DAODetails) private daoDetails;

    //Mapping to store total deposit by a user in a particular dao
    mapping(address => mapping(address => uint256)) private totalDeposit;

    //Mapping to get details of token gating for a particular dao
    mapping(address => TokenGatingCondition[]) private tokenGatingDetails;

    bool private _initialized;

    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    bool public _isPaused;

    address private deployer;

    mapping(address => address) private dstCommLayer;

    //Mapping to store total deposit by a user in a particular dao

    mapping(address => mapping(address => uint256)) private ownerShares;

    //Mapping to get details of token gating for a particular dao
    mapping(address => TokenGatingCondition) private tokenGatingDetailsNew;

    address private commLayer;

    mapping(address => CrossChainDetails) private ccDetails;

    uint256 public createFees;

    uint256 public depositFees;

    uint256 public platformFeeMultiplier;

    mapping(address => bool) private isKycEnabled;

    function _onlyOwners() private view {
        require(msg.sender == _owner, "caller is not the owner");
    }

    function _onlyIsNotPaused() private view {
        require(!_isPaused, "deposits paused");
    }

    function initialize() external {
        require(!_initialized);
        _owner = msg.sender;
        _initialized = true;
        createFees = 1e14;
        depositFees = 1e14;
        platformFeeMultiplier = 125;
        _isPaused = false;
    }

    function changeOwner(address _newOwner) external {
        _onlyOwners();
        _owner = _newOwner;
    }

    function togglePaused() external {
        _onlyOwners();
        _isPaused = !_isPaused;
    }

    function defineTokenContracts(
        address _emitter,
        address _deployer,
        address _commLayer
    ) external {
        _onlyOwners();
        emitterAddress = _emitter;

        deployer = _deployer;

        commLayer = _commLayer;
    }

    /// @dev This function returns details of a particular dao
    /// @param _daoAddress address of token contract
    function getDAOdetails(
        address _daoAddress
    ) public view returns (DAODetails memory) {
        return daoDetails[_daoAddress];
    }

    /// @dev This function returns token gating details of a particular dao
    /// @param _daoAddress address of token contract
    function getTokenGatingDetails(
        address _daoAddress
    ) external view returns (TokenGatingCondition memory) {
        return tokenGatingDetailsNew[_daoAddress];
    }

    /// @dev Function to change merkle root of particular token contract
    /// @param _daoAddress address token contract
    function changeMerkleRoot(
        address _daoAddress,
        bytes32 _newMerkleRoot
    ) external payable onlyGnosisOrDao(address(this), _daoAddress) {
        validateDaoAddress(_daoAddress);
        daoDetails[_daoAddress].merkleRoot = _newMerkleRoot;

        IEmitter(emitterAddress).changeMerkleRoot(
            address(this),
            _daoAddress,
            _newMerkleRoot
        );
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function createERC20DAO(
        string calldata _DaoName,
        string calldata _DaoSymbol,
        uint16 _commLayerId,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        uint256 _minDepositPerUser,
        uint256 _maxDepositPerUser,
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        uint256 _safeThreshold,
        uint256[] calldata _depositChainIds,
        address _gnosisAddress,
        address[] calldata _depositTokenAddress,
        address[] memory _admins,
        bool _isGovernanceActive,
        bool _isTransferable,
        bool _onlyAllowWhitelist,
        bool _assetsStoredOnGnosis,
        bytes32 _merkleRoot
    ) external payable {
        uint256 fees = checkCreateFeesSent(_depositChainIds);

        bytes memory data = abi.encodeWithSignature(
            "initializeERC20(address,address,string,string,uint256,uint256,bool,bool,bool,address)",
            address(this),
            emitterAddress,
            _DaoName,
            _DaoSymbol,
            _quorumPercent,
            _thresholdPercent,
            _isGovernanceActive,
            _isTransferable,
            _onlyAllowWhitelist,
            msg.sender
        );

        address _daoAddress = IDeployer(deployer).deployERC20DAO(_owner, data);

        address _safe = IDeployer(deployer).deploySAFE(
            _admins,
            _safeThreshold,
            _daoAddress
        );

        _createERC20DAO(
            _distributionAmount,
            _pricePerToken,
            _minDepositPerUser,
            _maxDepositPerUser,
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _daoAddress,
            _depositTokenAddress[0],
            _safe,
            _assetsStoredOnGnosis,
            _merkleRoot
        );

        IEmitter(emitterAddress).createDaoErc20(
            msg.sender,
            _daoAddress,
            _DaoName,
            _DaoSymbol,
            _distributionAmount,
            _pricePerToken,
            _minDepositPerUser,
            _maxDepositPerUser,
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _depositTokenAddress[0],
            emitterAddress,
            _safe,
            _isGovernanceActive,
            _isTransferable,
            _assetsStoredOnGnosis
        );

        for (uint256 i; i < _admins.length; ) {
            IEmitter(emitterAddress).newUser(
                _daoAddress,
                _admins[i],
                _depositTokenAddress[0],
                0,
                block.timestamp,
                0,
                true
            );

            unchecked {
                ++i;
            }
        }

        if (_depositChainIds.length != 0) {
            for (uint256 i; i < _depositChainIds.length - 1; ) {
                bytes memory _payload = abi.encode(
                    _commLayerId,
                    _distributionAmount,
                    amountToSD(_depositTokenAddress[0], _pricePerToken),
                    amountToSD(_depositTokenAddress[0], _minDepositPerUser),
                    amountToSD(_depositTokenAddress[0], _maxDepositPerUser),
                    _ownerFeePerDepositPercent,
                    _depositTime,
                    _quorumPercent,
                    _thresholdPercent,
                    _safeThreshold,
                    _depositChainIds,
                    _daoAddress,
                    _depositTokenAddress[i + 1],
                    _admins,
                    _onlyAllowWhitelist,
                    _merkleRoot,
                    0
                );
                ICommLayer(commLayer).sendMsg{
                    value: (msg.value - fees) / _depositChainIds.length
                }(
                    commLayer,
                    _payload,
                    abi.encode(_depositChainIds[i + 1], msg.sender)
                );
                unchecked {
                    ++i;
                }
            }

            IEmitter(emitterAddress).createCCDao(_daoAddress, _depositChainIds);
        }
    }

    function createCrossChainERC20DAO(
        uint16 _commLayerId,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        uint256 _minDepositPerUser,
        uint256 _maxDepositPerUser,
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        uint256 _safeThreshold,
        uint256[] calldata _depositChainIds,
        address _daoAddress,
        address _depositTokenAddress,
        address[] memory _admins,
        bool _onlyAllowWhitelist,
        bytes32 _merkleRoot
    ) external {
        require(msg.sender == commLayer, "Caller not LZ Deployer");
        address _safe = IDeployer(deployer).deploySAFE(
            _admins,
            _safeThreshold,
            _daoAddress
        );

        _createERC20DAO(
            _distributionAmount,
            amountToLD(_depositTokenAddress, _pricePerToken),
            amountToLD(_depositTokenAddress, _minDepositPerUser),
            amountToLD(_depositTokenAddress, _maxDepositPerUser),
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _daoAddress,
            _depositTokenAddress,
            _safe,
            true,
            _merkleRoot
        );

        ccDetails[_daoAddress] = CrossChainDetails(
            _commLayerId,
            _depositChainIds,
            false,
            msg.sender,
            _onlyAllowWhitelist
        );

        for (uint256 i; i < _admins.length; ) {
            IEmitter(emitterAddress).newUserCC(
                _daoAddress,
                _admins[i],
                _depositTokenAddress,
                0,
                block.timestamp,
                0,
                true
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function _createERC20DAO(
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        uint256 _minDepositPerUser,
        uint256 _maxDepositPerUser,
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        address _daoAddress,
        address _depositTokenAddress,
        address _gnosisAddress,
        bool _assetsStoredOnGnosis,
        bytes32 _merkleRoot
    ) private {
        if (_quorumPercent == 0 || _quorumPercent > FLOAT_HANDLER_TEN_4) {
            revert AmountInvalid("_quorumPercent", _quorumPercent);
        }

        if (_thresholdPercent == 0 || _thresholdPercent > FLOAT_HANDLER_TEN_4) {
            revert AmountInvalid("_thresholdPercent", _thresholdPercent);
        }

        if (_depositTime == 0) {
            revert AmountInvalid("_depositFunctioningDays", _depositTime);
        }

        if (!(_ownerFeePerDepositPercent < FLOAT_HANDLER_TEN_4)) {
            revert AmountInvalid(
                "_ownerFeePerDeposit",
                _ownerFeePerDepositPercent
            );
        }

        if (_maxDepositPerUser == 0) {
            revert AmountInvalid("_maxDepositPerUser", _maxDepositPerUser);
        }

        if (_maxDepositPerUser <= _minDepositPerUser) {
            revert DepositAmountInvalid(_maxDepositPerUser, _minDepositPerUser);
        }

        if (
            ((_distributionAmount * _pricePerToken) / 1e18) < _maxDepositPerUser
        ) {
            revert RaiseAmountInvalid(
                ((_distributionAmount * _pricePerToken) / 1e18),
                _maxDepositPerUser
            );
        }

        daoDetails[_daoAddress] = DAODetails(
            _pricePerToken,
            _distributionAmount,
            _minDepositPerUser,
            _maxDepositPerUser,
            _ownerFeePerDepositPercent,
            _depositTime,
            _depositTokenAddress,
            _gnosisAddress,
            _merkleRoot,
            true,
            false,
            _assetsStoredOnGnosis
        );
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function createERC721DAO(
        string calldata _DaoName,
        string calldata _DaoSymbol,
        string calldata _tokenURI,
        uint16 _commLayerId,
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        uint256 _safeThreshold,
        uint256[] calldata _depositChainIds,
        address _gnosisAddress,
        address[] memory _depositTokenAddress,
        address[] memory _admins,
        uint256 _maxTokensPerUser,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        bool _isNftTransferable,
        bool _isNftTotalSupplyUnlimited,
        bool _isGovernanceActive,
        bool _onlyAllowWhitelist,
        bool _assetsStoredOnGnosis,
        bytes32 _merkleRoot
    ) external payable {
        uint256 fees = checkCreateFeesSent(_depositChainIds);

        bytes memory data = abi.encodeWithSignature(
            "initializeERC721(string,string,address,address,uint256,uint256,uint256,bool,bool,bool,bool,address)",
            _DaoName,
            _DaoSymbol,
            address(this),
            emitterAddress,
            _quorumPercent,
            _thresholdPercent,
            _maxTokensPerUser,
            _isNftTransferable,
            _isNftTotalSupplyUnlimited,
            _isGovernanceActive,
            _onlyAllowWhitelist,
            msg.sender
        );

        address _daoAddress = IDeployer(deployer).deployERC721DAO(_owner, data);

        address _safe = IDeployer(deployer).deploySAFE(
            _admins,
            _safeThreshold,
            _daoAddress
        );

        _createERC721DAO(
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _daoAddress,
            _depositTokenAddress[0],
            _safe,
            _maxTokensPerUser,
            _distributionAmount,
            _pricePerToken,
            _assetsStoredOnGnosis,
            _merkleRoot
        );

        IEmitter(emitterAddress).createDaoErc721(
            msg.sender,
            _daoAddress,
            _DaoName,
            _DaoSymbol,
            _tokenURI,
            _pricePerToken,
            _distributionAmount,
            _maxTokensPerUser,
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _depositTokenAddress[0],
            emitterAddress,
            _safe,
            _isGovernanceActive,
            _isNftTransferable,
            _assetsStoredOnGnosis
        );

        for (uint256 i; i < _admins.length; ) {
            IEmitter(emitterAddress).newUser(
                _daoAddress,
                _admins[i],
                _depositTokenAddress[0],
                0,
                block.timestamp,
                0,
                true
            );

            unchecked {
                ++i;
            }
        }

        if (_depositChainIds.length != 0) {
            for (uint256 i; i < _depositChainIds.length - 1; ) {
                bytes memory _payload = abi.encode(
                    _commLayerId,
                    _distributionAmount,
                    amountToSD(_depositTokenAddress[0], _pricePerToken),
                    0,
                    0,
                    _ownerFeePerDepositPercent,
                    _depositTime,
                    _quorumPercent,
                    _thresholdPercent,
                    _safeThreshold,
                    _depositChainIds,
                    _daoAddress,
                    _depositTokenAddress[i + 1],
                    _admins,
                    _onlyAllowWhitelist,
                    _merkleRoot,
                    _maxTokensPerUser
                );
                ICommLayer(commLayer).sendMsg{
                    value: (msg.value - fees) / _depositChainIds.length
                }(
                    commLayer,
                    _payload,
                    abi.encode(_depositChainIds[i + 1], msg.sender)
                );
                unchecked {
                    ++i;
                }
            }

            IEmitter(emitterAddress).createCCDao(_daoAddress, _depositChainIds);
        }
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function createCrossChainERC721DAO(
        uint16 _commLayerId,
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        uint256 _safeThreshold,
        uint256[] memory _depoitChainIds,
        address _daoAddress,
        address _depositTokenAddress,
        address[] memory _admins,
        uint256 _maxTokensPerUser,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        bool _onlyAllowWhitelist,
        bytes32 _merkleRoot
    ) external {
        require(msg.sender == commLayer, "Caller not LZ Deployer");
        address _safe = IDeployer(deployer).deploySAFE(
            _admins,
            _safeThreshold,
            _daoAddress
        );

        _createERC721DAO(
            _ownerFeePerDepositPercent,
            _depositTime,
            _quorumPercent,
            _thresholdPercent,
            _daoAddress,
            _depositTokenAddress,
            _safe,
            _maxTokensPerUser,
            _distributionAmount,
            amountToLD(_depositTokenAddress, _pricePerToken),
            true,
            _merkleRoot
        );

        ccDetails[_daoAddress] = CrossChainDetails(
            _commLayerId,
            _depoitChainIds,
            false,
            msg.sender,
            _onlyAllowWhitelist
        );

        for (uint256 i; i < _admins.length; ) {
            IEmitter(emitterAddress).newUserCC(
                _daoAddress,
                _admins[i],
                _depositTokenAddress,
                0,
                block.timestamp,
                0,
                true
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function _createERC721DAO(
        uint256 _ownerFeePerDepositPercent,
        uint256 _depositTime,
        uint256 _quorumPercent,
        uint256 _thresholdPercent,
        address _daoAddress,
        address _depositTokenAddress,
        address _gnosisAddress,
        uint256 _maxTokensPerUser,
        uint256 _distributionAmount,
        uint256 _pricePerToken,
        bool _assetsStoredOnGnosis,
        bytes32 _merkleRoot
    ) private {
        if (_quorumPercent == 0 || _quorumPercent > FLOAT_HANDLER_TEN_4) {
            revert AmountInvalid("_quorumPercent", _quorumPercent);
        }

        if (_thresholdPercent == 0 || _thresholdPercent > FLOAT_HANDLER_TEN_4) {
            revert AmountInvalid("_thresholdPercent", _thresholdPercent);
        }

        if (_depositTime == 0) {
            revert AmountInvalid("_depositFunctioningDays", _depositTime);
        }

        if (!(_ownerFeePerDepositPercent < FLOAT_HANDLER_TEN_4)) {
            revert AmountInvalid(
                "_ownerFeePerDeposit",
                _ownerFeePerDepositPercent
            );
        }

        if (_maxTokensPerUser == 0) {
            revert AmountInvalid("_maxTokensPerUser", _maxTokensPerUser);
        }

        daoDetails[_daoAddress] = DAODetails(
            _pricePerToken,
            _distributionAmount,
            0,
            0,
            _ownerFeePerDepositPercent,
            _depositTime,
            _depositTokenAddress,
            _gnosisAddress,
            _merkleRoot,
            true,
            false,
            _assetsStoredOnGnosis
        );
    }

    function crossChainMint(
        address _user,
        address payable _daoAddress,
        uint256 _numOfTokensToBuy,
        string calldata _tokenURI,
        bytes32[] calldata _merkleProof
    ) external {
        require(msg.sender == IDeployer(deployer).lzImpl());
        DAODetails memory _daoDetails = daoDetails[_daoAddress];
        uint256 _daoBalance = IERC20(_daoDetails.depositTokenAddress).balanceOf(
            _daoAddress
        );
        uint256 _totalAmount = _daoDetails.pricePerToken * (_numOfTokensToBuy);

        if (_daoDetails.isTokenGatingApplied) {
            ifTokenGatingApplied(_daoAddress);
        }

        if (bytes(_tokenURI).length != 0) {
            checkAmountValidity(
                _daoBalance,
                _totalAmount,
                _daoDetails.pricePerToken,
                _daoDetails.distributionAmount
            );

            if (
                IERC721DAO(_daoAddress).getERC721DAOdetails().onlyAllowWhitelist
            ) {
                if (
                    !MerkleProof.verify(
                        _merkleProof,
                        _daoDetails.merkleRoot,
                        keccak256(abi.encodePacked(_user))
                    )
                ) {
                    revert IncorrectProof();
                }
            }

            IERC721DAO(_daoAddress).mintToken(
                _user,
                _tokenURI,
                _numOfTokensToBuy
            );
        } else {
            _totalAmount = _totalAmount / 1e18;
            uint256 _totalDeposit = totalDeposit[_user][_daoAddress];

            if (_totalDeposit == 0) {
                if (_totalAmount < _daoDetails.minDepositPerUser) {
                    revert AmountInvalid(
                        "_numOfTokensToBuy",
                        _numOfTokensToBuy
                    );
                }
                if (_totalAmount > _daoDetails.maxDepositPerUser) {
                    revert AmountInvalid(
                        "_numOfTokensToBuy",
                        _numOfTokensToBuy
                    );
                }
            } else {
                if (
                    _totalDeposit + _totalAmount > _daoDetails.maxDepositPerUser
                ) {
                    revert AmountInvalid(
                        "_numOfTokensToBuy",
                        _numOfTokensToBuy
                    );
                }
            }

            totalDeposit[_user][_daoAddress] += _totalAmount;

            if (
                IERC20DAO(_daoAddress).getERC20DAOdetails().onlyAllowWhitelist
            ) {
                if (
                    !MerkleProof.verify(
                        _merkleProof,
                        _daoDetails.merkleRoot,
                        keccak256(abi.encodePacked(_user))
                    )
                ) {
                    revert IncorrectProof();
                }
            }

            if (
                _daoBalance + _totalAmount >
                (_daoDetails.pricePerToken * _daoDetails.distributionAmount) /
                    1e18
            ) {
                revert AmountInvalid("daoBalance", _daoBalance + _totalAmount);
            }
            IERC20DAO(_daoAddress).mintToken(_user, _numOfTokensToBuy);
        }

        IEmitter(emitterAddress).newUser(
            _daoAddress,
            _user,
            _daoDetails.depositTokenAddress,
            _totalAmount,
            block.timestamp,
            _numOfTokensToBuy,
            false
        );
    }

    function _buyGovernanceTokenERC20DAO(
        address payable _daoAddress,
        uint256 _numOfTokensToBuy
    ) private {
        DAODetails memory _daoDetails = daoDetails[_daoAddress];

        if (_daoDetails.depositCloseTime < block.timestamp) {
            revert DepositClosed();
        }

        if (_numOfTokensToBuy == 0) {
            revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
        }

        uint256 _totalAmount = (_numOfTokensToBuy * _daoDetails.pricePerToken) /
            1e18;

        if (_totalAmount == 0) {
            revert AmountInvalid("_numOfTokensToBuy", _totalAmount);
        }

        uint256 ownerShare = (_totalAmount *
            _daoDetails.ownerFeePerDepositPercent) / (FLOAT_HANDLER_TEN_4);

        if (_daoDetails.depositTokenAddress == NATIVE_TOKEN_ADDRESS) {
            checkDepositFeesSent(_daoAddress, _totalAmount + ownerShare);
            payable(
                _daoDetails.assetsStoredOnGnosis
                    ? _daoDetails.gnosisAddress
                    : _daoAddress
            ).call{value: _totalAmount}("");
            payable(
                ccDetails[_daoAddress].ownerAddress != address(0)
                    ? ccDetails[_daoAddress].ownerAddress
                    : IERC20DAO(_daoAddress).getERC20DAOdetails().ownerAddress
            ).call{value: ownerShare}("");
        } else {
            checkDepositFeesSent(_daoAddress, 0);
            IERC20(_daoDetails.depositTokenAddress).safeTransferFrom(
                msg.sender,
                _daoDetails.assetsStoredOnGnosis
                    ? _daoDetails.gnosisAddress
                    : _daoAddress,
                _totalAmount
            );
            IERC20(_daoDetails.depositTokenAddress).safeTransferFrom(
                msg.sender,
                ccDetails[_daoAddress].ownerAddress != address(0)
                    ? ccDetails[_daoAddress].ownerAddress
                    : IERC20DAO(_daoAddress).getERC20DAOdetails().ownerAddress,
                ownerShare
            );
        }

        IEmitter(emitterAddress).deposited(
            _daoAddress,
            msg.sender,
            _daoDetails.depositTokenAddress,
            _totalAmount,
            block.timestamp,
            _daoDetails.ownerFeePerDepositPercent,
            ownerShare
        );
    }

    function _buyGovernanceTokenERC721DAO(
        address payable _daoAddress,
        uint256 _numOfTokensToBuy
    ) private {
        DAODetails memory _daoDetails = daoDetails[_daoAddress];

        if (_daoDetails.depositCloseTime < block.timestamp) {
            revert DepositClosed();
        }

        if (_numOfTokensToBuy == 0) {
            revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
        }

        uint256 _totalAmount = _daoDetails.pricePerToken * (_numOfTokensToBuy);

        uint256 ownerShare = (_totalAmount *
            _daoDetails.ownerFeePerDepositPercent) / (FLOAT_HANDLER_TEN_4);

        if (_daoDetails.depositTokenAddress == NATIVE_TOKEN_ADDRESS) {
            checkDepositFeesSent(_daoAddress, _totalAmount + ownerShare);
            payable(
                _daoDetails.assetsStoredOnGnosis
                    ? _daoDetails.gnosisAddress
                    : _daoAddress
            ).call{value: _totalAmount}("");
            payable(
                ccDetails[_daoAddress].ownerAddress != address(0)
                    ? ccDetails[_daoAddress].ownerAddress
                    : IERC721DAO(_daoAddress).getERC721DAOdetails().ownerAddress
            ).call{value: ownerShare}("");
        } else {
            checkDepositFeesSent(_daoAddress, 0);
            IERC20(_daoDetails.depositTokenAddress).safeTransferFrom(
                msg.sender,
                _daoDetails.assetsStoredOnGnosis
                    ? _daoDetails.gnosisAddress
                    : _daoAddress,
                _totalAmount
            );
            IERC20(_daoDetails.depositTokenAddress).safeTransferFrom(
                msg.sender,
                ccDetails[_daoAddress].ownerAddress != address(0)
                    ? ccDetails[_daoAddress].ownerAddress
                    : IERC721DAO(_daoAddress)
                        .getERC721DAOdetails()
                        .ownerAddress,
                ownerShare
            );
        }

        IEmitter(emitterAddress).deposited(
            _daoAddress,
            msg.sender,
            _daoDetails.depositTokenAddress,
            _totalAmount,
            block.timestamp,
            _daoDetails.ownerFeePerDepositPercent,
            ownerShare
        );
    }

    /// @dev Function to update Minimum and Maximum deposits allowed by DAO members
    /// @param _minDepositPerUser New minimum deposit requirement amount in wei
    /// @param _maxDepositPerUser New maximum deposit limit amount in wei
    /// @param _daoAddress address of the token contract
    function updateMinMaxDeposit(
        uint256 _minDepositPerUser,
        uint256 _maxDepositPerUser,
        address _daoAddress
    ) external payable onlyGnosisOrDao(address(this), _daoAddress) {
        validateDaoAddress(_daoAddress);

        validateDepositAmounts(_minDepositPerUser, _maxDepositPerUser);

        daoDetails[_daoAddress].minDepositPerUser = _minDepositPerUser;
        daoDetails[_daoAddress].maxDepositPerUser = _maxDepositPerUser;

        IEmitter(emitterAddress).updateMinMaxDeposit(
            _daoAddress,
            _minDepositPerUser,
            _maxDepositPerUser
        );
    }

    /// @dev Function to update DAO Owner Fee
    /// @param _ownerFeePerDeposit New Owner fee
    /// @param _daoAddress address of the token contract
    function updateOwnerFee(
        uint256 _ownerFeePerDeposit,
        address _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        validateDaoAddress(_daoAddress);

        if (!(_ownerFeePerDeposit < FLOAT_HANDLER_TEN_4)) {
            revert AmountInvalid("_ownerFeePerDeposit", _ownerFeePerDeposit);
        }
        daoDetails[_daoAddress].ownerFeePerDepositPercent = _ownerFeePerDeposit;

        IEmitter(emitterAddress).updateOwnerFee(
            _daoAddress,
            _ownerFeePerDeposit
        );
    }

    /// @dev Function to update total raise amount
    /// @param _newDistributionAmount New distribution amount
    /// @param _newPricePerToken New price per token
    /// @param _daoAddress address of the token contract
    function updateTotalRaiseAmount(
        uint256 _newDistributionAmount,
        uint256 _newPricePerToken,
        address _daoAddress
    ) external payable onlyGnosisOrDao(address(this), _daoAddress) {
        validateDaoAddress(_daoAddress);
        uint256 _distributionAmount = daoDetails[_daoAddress]
            .distributionAmount;

        if (_distributionAmount != _newDistributionAmount) {
            if (_distributionAmount > _newDistributionAmount) {
                revert AmountInvalid(
                    "_newDistributionAmount",
                    _newDistributionAmount
                );
            }
            daoDetails[_daoAddress].distributionAmount = _newDistributionAmount;
            IEmitter(emitterAddress).updateDistributionAmount(
                _daoAddress,
                _newDistributionAmount
            );
        }

        if (daoDetails[_daoAddress].pricePerToken != _newPricePerToken) {
            daoDetails[_daoAddress].pricePerToken = _newPricePerToken;
            IEmitter(emitterAddress).updatePricePerToken(
                _daoAddress,
                _newPricePerToken
            );
        }
    }

    /// @dev Function to update deposit time
    /// @param _depositTime New start time
    /// @param _daoAddress address of the token contract
    function updateDepositTime(
        uint256 _depositTime,
        address _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        validateDaoAddress(_daoAddress);

        if (_depositTime == 0) revert AmountInvalid("_days", _depositTime);

        daoDetails[_daoAddress].depositCloseTime = _depositTime;

        IEmitter(emitterAddress).startDeposit(
            _daoAddress,
            block.timestamp,
            daoDetails[_daoAddress].depositCloseTime
        );
    }

    /// @dev Function to setup multiple token checks to gate community
    /// @param _tokens Address of tokens
    /// @param _operator Operator for token checks (0 for AND and 1 for OR)
    /// @param _value Minimum user balance amount
    /// @param _daoAddress Address to DAO
    function setupTokenGating(
        address[] calldata _tokens,
        Operator _operator,
        uint256[] calldata _value,
        address payable _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        require(_value.length == _tokens.length, "Length mismatch");

        tokenGatingDetailsNew[_daoAddress] = TokenGatingCondition(
            _tokens,
            _operator,
            _value
        );

        daoDetails[_daoAddress].isTokenGatingApplied = true;
    }

    // @dev Function to disable token gating
    /// @param _daoAddress address of the token contract
    function disableTokenGating(
        address _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        delete tokenGatingDetailsNew[_daoAddress];
        daoDetails[_daoAddress].isTokenGatingApplied = false;
    }

    /// @dev function to deposit tokens and receive dao tokens in return
    /// @param _daoAddress address of the token contract
    /// @param _numOfTokensToBuy amount of tokens to buy
    function buyGovernanceTokenERC20DAO(
        address payable _daoAddress,
        uint256 _numOfTokensToBuy,
        bytes32[] calldata _merkleProof
    ) public payable {
        _onlyIsNotPaused();
        DAODetails memory _daoDetails = daoDetails[_daoAddress];

        uint256 daoBalance;
        if (
            daoDetails[_daoAddress].depositTokenAddress == NATIVE_TOKEN_ADDRESS
        ) {
            daoBalance = _daoAddress.balance;
        } else {
            daoBalance = IERC20(daoDetails[_daoAddress].depositTokenAddress)
                .balanceOf(_daoAddress);
        }

        uint256 _totalAmount = (_numOfTokensToBuy * _daoDetails.pricePerToken) /
            1e18;

        uint256 _totalDeposit = totalDeposit[msg.sender][_daoAddress];

        if (_totalDeposit == 0) {
            if (_totalAmount < _daoDetails.minDepositPerUser) {
                revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
            }
            if (_totalAmount > _daoDetails.maxDepositPerUser) {
                revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
            }
        } else {
            if (_totalDeposit + _totalAmount > _daoDetails.maxDepositPerUser) {
                revert AmountInvalid("_numOfTokensToBuy", _numOfTokensToBuy);
            }
        }

        if (_daoDetails.isTokenGatingApplied) {
            ifTokenGatingApplied(_daoAddress);
        }

        if (IERC20DAO(_daoAddress).getERC20DAOdetails().onlyAllowWhitelist) {
            if (
                !MerkleProof.verify(
                    _merkleProof,
                    _daoDetails.merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            ) {
                revert IncorrectProof();
            }
        }

        totalDeposit[msg.sender][_daoAddress] += _totalAmount;

        if (
            daoBalance + _totalAmount >
            (_daoDetails.pricePerToken * _daoDetails.distributionAmount) / 1e18
        ) {
            revert AmountInvalid("daoBalance", daoBalance + _totalAmount);
        }

        _buyGovernanceTokenERC20DAO(_daoAddress, _numOfTokensToBuy);

        IERC20DAO(_daoAddress).mintToken(msg.sender, _numOfTokensToBuy);

        IEmitter(emitterAddress).newUser(
            _daoAddress,
            msg.sender,
            _daoDetails.depositTokenAddress,
            _totalAmount,
            block.timestamp,
            _numOfTokensToBuy,
            false
        );
    }

    /// @dev This internal function performs required operations if token gating is applied
    function ifTokenGatingApplied(address _daoAddress) private view {
        TokenGatingCondition memory condition = tokenGatingDetailsNew[
            _daoAddress
        ];

        bool isValid;
        bool isNewValid;

        for (uint256 i = 0; i < condition.tokens.length; ++i) {
            uint256 balance = IERC20(condition.tokens[i]).balanceOf(msg.sender);
            if (i == 0) {
                isValid = balance >= condition.value[i];
                isNewValid = balance >= condition.value[i];
            } else {
                isNewValid = balance >= condition.value[i];
            }

            if (condition.operator == Operator.AND) {
                isValid = isValid && isNewValid;
            } else {
                isValid = isValid || isNewValid;
                if (isValid) {
                    return;
                }
            }
        }

        if (!isValid) {
            revert InsufficientBalance();
        }
    }

    /// @dev function to deposit tokens and receive dao tokens in return
    /// @param _daoAddress address of the token contract
    /// @param _numOfTokensToBuy amount of nfts to mint
    function buyGovernanceTokenERC721DAO(
        address payable _daoAddress,
        string calldata _tokenURI,
        uint256 _numOfTokensToBuy,
        bytes32[] calldata _merkleProof
    ) public payable {
        _onlyIsNotPaused();
        DAODetails memory _daoDetails = daoDetails[_daoAddress];

        uint256 daoBalance;
        if (
            daoDetails[_daoAddress].depositTokenAddress == NATIVE_TOKEN_ADDRESS
        ) {
            daoBalance = _daoAddress.balance;
        } else {
            daoBalance = IERC20(daoDetails[_daoAddress].depositTokenAddress)
                .balanceOf(_daoAddress);
        }

        uint256 _totalAmount = _daoDetails.pricePerToken * (_numOfTokensToBuy);

        if (_daoDetails.isTokenGatingApplied) {
            ifTokenGatingApplied(_daoAddress);
        }

        if (IERC721DAO(_daoAddress).getERC721DAOdetails().onlyAllowWhitelist) {
            if (
                !MerkleProof.verify(
                    _merkleProof,
                    _daoDetails.merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            ) {
                revert IncorrectProof();
            }
        }

        checkAmountValidity(
            daoBalance,
            _totalAmount,
            _daoDetails.pricePerToken,
            _daoDetails.distributionAmount
        );

        _buyGovernanceTokenERC721DAO(_daoAddress, _numOfTokensToBuy);

        IERC721DAO(_daoAddress).mintToken(
            msg.sender,
            _tokenURI,
            _numOfTokensToBuy
        );

        IEmitter(emitterAddress).newUser(
            _daoAddress,
            msg.sender,
            _daoDetails.depositTokenAddress,
            _totalAmount,
            block.timestamp,
            _numOfTokensToBuy,
            false
        );
    }

    function crossChainBuy(
        address payable _daoAddress,
        string calldata _tokenURI,
        uint16 _commLayerId,
        uint256 _numOfTokensToBuy,
        bytes calldata _extraParams,
        bytes32[] calldata _merkleProof
    ) external payable {
        _onlyIsNotPaused();
        if (bytes(_tokenURI).length != 0) {
            _buyGovernanceTokenERC721DAO(_daoAddress, _numOfTokensToBuy);
        } else {
            _buyGovernanceTokenERC20DAO(_daoAddress, _numOfTokensToBuy);
        }

        bytes memory _payload = abi.encode(
            _daoAddress,
            msg.sender,
            _numOfTokensToBuy,
            _tokenURI,
            _merkleProof
        );
        address _commLayer = IDeployer(deployer).getCommunicationLayer(
            _commLayerId
        );

        uint256 fees = depositFees;

        if (
            ccDetails[_daoAddress].depositChainIds.length > 1 ||
            isKycEnabled[_daoAddress]
        ) {
            fees = ((depositFees * platformFeeMultiplier) / 100);
        }

        ICommLayer(_commLayer).sendMsg{value: msg.value - fees}(
            _commLayer,
            _payload,
            _extraParams
        );
    }

    function validateDaoAddress(address _daoAddress) internal view {
        if (!daoDetails[_daoAddress].isDeployedByFactory) {
            revert AddressInvalid("_daoAddress", _daoAddress);
        }
    }

    function validateDepositAmounts(uint256 _min, uint256 _max) internal pure {
        if (_min == 0 || _min > _max) revert DepositAmountInvalid(_min, _max);
    }

    function checkAmountValidity(
        uint256 _daoBalance,
        uint256 _totalAmount,
        uint256 _pricePerToken,
        uint256 _distributionAmount
    ) internal pure {
        if (_distributionAmount != 0) {
            uint256 _maxAllowedAmount = _pricePerToken * _distributionAmount;
            if (_daoBalance + _totalAmount > _maxAllowedAmount) {
                revert AmountInvalid("daoBalance", _daoBalance + _totalAmount);
            }
        }
    }

    function rescueFunds(address tokenAddr) external {
        _onlyOwners();
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint256 balance = address(this).balance;
            payable(_owner).call{value: balance}("");
        } else {
            uint256 balance = IERC20(tokenAddr).balanceOf(address(this));
            IERC20(tokenAddr).transfer(_owner, balance);
        }
    }

    function updateFees(
        uint256 _createFees,
        uint256 _depositFees,
        uint256 _val
    ) external {
        _onlyOwners();
        depositFees = _depositFees;
        createFees = _createFees;
        platformFeeMultiplier = _val;
    }

    function toggleKYC(
        address _daoAddress
    ) external payable onlyAdmins(daoDetails[_daoAddress].gnosisAddress) {
        isKycEnabled[_daoAddress] = !isKycEnabled[_daoAddress];
    }

    function checkCreateFeesSent(
        uint256[] calldata _depositChainIds
    ) internal returns (uint256) {
        uint256 fees = createFees * _depositChainIds.length;
        require(msg.value >= fees, "Insufficient fees");
        return fees;
    }

    function checkDepositFeesSent(
        address _daoAddress,
        uint256 _totalAmount
    ) internal {
        if (
            ccDetails[_daoAddress].depositChainIds.length > 1 ||
            isKycEnabled[_daoAddress]
        ) {
            require(
                msg.value >=
                    _totalAmount +
                        ((depositFees * platformFeeMultiplier) / 100),
                "Insufficient fees"
            );
        } else {
            require(
                msg.value >= _totalAmount + depositFees,
                "Insufficient fees"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IERC20Extended {
    function decimals() external view returns (uint8);
}

interface Safe {
    function isOwner(address owner) external view returns (bool);
}

contract Helper {
    ///@dev Admin role
    bytes32 constant ADMIN = keccak256("ADMIN");

    uint8 constant UNIFORM_DECIMALS = 18;

    bytes32 constant operationNameAND = keccak256(abi.encodePacked(("AND")));
    bytes32 constant operationNameOR = keccak256(abi.encodePacked(("OR")));

    uint256 constant EIGHTEEN_DECIMALS = 1e18;

    uint256 constant FLOAT_HANDLER_TEN_4 = 10000;

    struct DAODetails {
        uint256 pricePerToken;
        uint256 distributionAmount;
        uint256 minDepositPerUser;
        uint256 maxDepositPerUser;
        uint256 ownerFeePerDepositPercent;
        uint256 depositCloseTime;
        address depositTokenAddress;
        address gnosisAddress;
        bytes32 merkleRoot;
        bool isDeployedByFactory;
        bool isTokenGatingApplied;
        bool assetsStoredOnGnosis;
    }

    struct CrossChainDetails {
        uint16 commLayerId;
        uint256[] depositChainIds;
        bool isDefaultChain;
        address ownerAddress;
        bool onlyAllowWhitelist;
    }

    struct ERC20DAOdetails {
        string DaoName;
        string DaoSymbol;
        uint256 quorum;
        uint256 threshold;
        bool isGovernanceActive;
        bool isTransferable;
        bool onlyAllowWhitelist;
        address ownerAddress;
    }

    struct ERC721DAOdetails {
        string DaoName;
        string DaoSymbol;
        uint256 quorum;
        uint256 threshold;
        uint256 maxTokensPerUser;
        bool isTransferable;
        bool isNftTotalSupplyUnlimited;
        bool isGovernanceActive;
        bool onlyAllowWhitelist;
        address ownerAddress;
    }

    enum Operator {
        AND,
        OR
    }
    enum Comparator {
        GREATER,
        BELOW,
        EQUAL
    }

    struct TokenGatingCondition {
        address[] tokens;
        Operator operator;
        uint256[] value;
    }

    //implementation contract errors
    error AmountInvalid(string _param, uint256 _amount);
    error NotERC20Template();
    error DepositAmountInvalid(
        uint256 _maxDepositPerUser,
        uint256 _minDepositPerUser
    );
    error DepositClosed();
    error DepositStarted();
    error Max4TokensAllowed(uint256 _length);
    error ArrayLengthMismatch(uint256 _length1, uint256 _length2);
    error AddressInvalid(string _param, address _address);
    error InsufficientFunds();
    error InvalidData();
    error InsufficientAllowance(uint256 required, uint256 current);
    error SafeProxyCreationFailed(string _reason);

    //nft contract errors
    error NotWhitelisted();
    error MaxTokensMinted();
    error NoAccess(address _user);
    error MintingNotOpen();
    error MaxTokensMintedForUser(address _user);

    error RaiseAmountInvalid(
        uint256 _totalRaiseAmount,
        uint256 _maxDepositPerUser
    );

    error InsufficientBalance();
    error InsufficientFees();

    error NotDefaultChain();
    error IncorrectProof();

    /// @dev onlyOwner modifier to allow only Owner access to functions
    modifier onlyGnosis(address _factory, address _daoAddress) {
        require(
            IFactory(_factory).getDAOdetails(_daoAddress).gnosisAddress ==
                msg.sender,
            "Only Gnosis"
        );
        _;
    }

    function _onlyGnosisOrDao(address _factory, address _daoAddress) private {
        require(
            IFactory(_factory).getDAOdetails(_daoAddress).gnosisAddress ==
                msg.sender ||
                _daoAddress == msg.sender,
            "Only Gnosis or Dao"
        );
    }

    modifier onlyGnosisOrDao(address _factory, address _daoAddress) {
        _onlyGnosisOrDao(_factory, _daoAddress);
        _;
    }

    modifier onlyFactory(address _factory) {
        require(msg.sender == _factory);
        _;
    }

    modifier onlyCurrentContract() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyAdmins(address _safe) {
        require(Safe(_safe).isOwner(msg.sender), "Only owner access");
        _;
    }

    function amountToSD(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint8 decimals;
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            decimals = 18;
        } else {
            decimals = IERC20Extended(token).decimals();
        }
        if (decimals == 18) {
            return amount;
        } else {
            uint256 convertRate = 10 ** (18 - decimals);
            return amount * convertRate;
        }
    }

    function amountToLD(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint8 decimals;
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            decimals = 18;
        } else {
            decimals = IERC20Extended(token).decimals();
        }
        if (decimals == 18) {
            return amount;
        } else {
            uint256 convertRate = 10 ** (18 - decimals);
            return amount / convertRate;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICommLayer {
    function sendMsg(address, bytes memory, bytes memory) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDeployer {
    function lzImpl() external view returns (address);

    function deployERC20DAO(address, bytes calldata) external returns (address);

    function deployERC721DAO(
        address,
        bytes calldata
    ) external returns (address);

    function deploySAFE(
        address[] calldata,
        uint256,
        address
    ) external returns (address);

    function getCommunicationLayer(uint16) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEmitter {
    function initialize(address, address, address, address) external;

    function changeFactory(address) external;

    function allowActionContract(address) external;

    function defineContracts(address, address, address) external;

    function changeMerkleRoot(address, address, bytes32) external;

    function createDaoErc20(
        address,
        address,
        string calldata,
        string calldata,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address,
        address,
        bool,
        bool,
        bool
    ) external;

    function createDaoErc721(
        address,
        address,
        string calldata,
        string calldata,
        string calldata,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address,
        address,
        address,
        bool,
        bool,
        bool
    ) external;

    function deposited(
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256
    ) external;

    function newUser(
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        bool
    ) external;

    function newUserCC(
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        bool
    ) external;

    function startDeposit(address, uint256, uint256) external;

    function closeDeposit(address, uint256) external;

    function updateMinMaxDeposit(address, uint256, uint256) external;

    function updateOwnerFee(address, uint256) external;

    function airDropToken(address, address, address, uint256) external;

    function mintGTToAddress(
        address,
        uint256[] memory,
        address[] memory
    ) external;

    function updateGovernanceSettings(address, uint256, uint256) external;

    function updateDistributionAmount(address, uint256) external;

    function updatePricePerToken(address, uint256) external;

    function sendCustomToken(
        address,
        address,
        uint256[] memory,
        address[] memory
    ) external;

    function mintNft(address, address, string memory, uint256) external;

    function updateMaxTokensPerUser(address, uint256) external;

    function updateTotalSupplyOfToken(address, uint256) external;

    function updateTokenTransferability(address, bool) external;

    function whitelistAddress(address, address) external;

    function removeWhitelistAddress(address, address) external;

    function createCCDao(address, uint256[] memory) external;

    function transferGT(address, address, address, uint256) external;

    function changedSigners(address, address, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../helper.sol";

interface IERC20DAO {
    function getERC20DAOdetails()
        external
        returns (Helper.ERC20DAOdetails memory);

    function mintToken(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721DAO {
    struct ERC721DAOdetails {
        string DaoName;
        string DaoSymbol;
        uint256 quorum;
        uint256 threshold;
        uint256 maxTokensPerUser;
        bool isTransferable;
        bool isNftTotalSupplyUnlimited;
        bool isGovernanceActive;
        bool onlyAllowWhitelist;
        address ownerAddress;
    }

    function getERC721DAOdetails() external returns (ERC721DAOdetails memory);

    function mintToken(
        address _to,
        string calldata _tokenURI,
        uint256 _numOfTokensToBuy
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../helper.sol";

interface IFactory {
    function getDAOdetails(address) external returns (Helper.DAODetails memory);

    function crossChainMint(
        address,
        address,
        uint256,
        string calldata,
        bytes32[] calldata
    ) external;

    function createCrossChainERC20DAO(
        uint16,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] calldata,
        address,
        address,
        address[] memory,
        bool,
        bytes32
    ) external;

    function createCrossChainERC721DAO(
        uint16,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[] memory,
        address,
        address,
        address[] memory,
        uint256,
        uint256,
        uint256,
        bool,
        bytes32
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(
        bytes4 _newSelector,
        bytes memory _buf
    ) internal pure {
        require(_buf.length >= 4);
        uint _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(
        uint16 _dstChainId,
        address _srcAddress
    ) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(
        address _userApplication
    ) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(
        address _userApplication
    ) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(
        address _userApplication
    ) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(
        address _userApplication
    ) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import "../interfaces/IFactory.sol";
import "../interfaces/ICommLayer.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LayerZeroDeployer is ICommLayer, ILayerZeroReceiver, Initializable {
    /// @notice LayerZero endoint address
    ILayerZeroEndpoint public endpoint;

    IFactory public factory;

    address private owner;

    /// @notice mapping to keep track of failed messages
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    mapping(uint16 => address) private dstCommLayer;

    /// @notice Extra LayerZero fees customization parameters
    struct lzAdapterParams {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    event msgSent(
        uint16 _dstChainId,
        bytes _destination,
        bytes _payload,
        uint256 nonce
    );
    event ReceiveMsg(
        uint16 _srcChainId,
        address _from,
        bytes _payload,
        uint256 nonce
    );

    // event RetriedPayload(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    // event ForceResumed(uint16 _srcChainId, bytes _srcAddress, bytes _payload);

    function initialize(
        address _endpoint,
        address _factory
    ) external initializer {
        endpoint = ILayerZeroEndpoint(_endpoint);
        factory = IFactory(_factory);
        owner = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == address(factory));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _factory factory address
    function changeFactory(address _factory) external onlyOwner {
        factory = IFactory(_factory);
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _endpoint Source chain LayerZeroImpl address
    function changeEndpoint(address _endpoint) external onlyOwner {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /// @notice This function is responsible for sending messages to another chain using LayerZero
    /// @dev It makes call to LayerZero endpoint contract
    /// @dev This function can only be called from CommLayerAggregator
    /// @param _destination Address of destination contract to send message on
    /// @param _payload Encoded data to send on destination chain
    function sendMsg(
        address _destination,
        bytes calldata _payload,
        bytes memory extraParams
    ) public payable onlyFactory {
        (uint256 _dstChainId, address _refundAd) = abi.decode(
            extraParams,
            (uint256, address)
        );

        uint64 nextNonce = endpoint.getOutboundNonce(
            uint16(_dstChainId),
            address(this)
        ) + 1;

        endpoint.send{value: msg.value}(
            uint16(_dstChainId),
            abi.encodePacked(dstCommLayer[uint16(_dstChainId)], address(this)),
            _payload,
            payable(_refundAd),
            address(0x0),
            abi.encodePacked(uint16(1), uint256(2000000))
        );
        emit msgSent(
            uint16(_dstChainId),
            abi.encodePacked(dstCommLayer[uint16(_dstChainId)]),
            _payload,
            nextNonce
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        bytes memory trustedRemote = abi.encodePacked(
            dstCommLayer[_srcChainId],
            address(this)
        );
        require(
            _from.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_from) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );
        require(msg.sender == address(endpoint));
        if (
            keccak256(abi.encodePacked((_payload))) ==
            keccak256(abi.encodePacked((bytes10("ff"))))
        ) {
            endpoint.receivePayload(
                1,
                bytes(""),
                address(0x0),
                1,
                1,
                bytes("")
            );
        }
        (
            uint16 _commLayerId,
            uint256 _distributionAmount,
            uint256 _pricePerToken,
            uint256 _minDepositPerUser,
            uint256 _maxDepositPerUser,
            uint256 _ownerFeePerDepositPercent,
            uint256 _depositTime,
            uint256 _quorumPercent,
            uint256 _thresholdPercent,
            uint256 _safeThreshold,
            uint256[] memory _depoitChainIds,
            address _daoAddress,
            address _depositTokenAddress,
            address[] memory _admins,
            bool _onlyAllowWhitelist,
            bytes32 _merkleRoot,
            uint256 _maxTokensPerUser
        ) = abi.decode(
                _payload,
                (
                    uint16,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256[],
                    address,
                    address,
                    address[],
                    bool,
                    bytes32,
                    uint256
                )
            );

        if (_maxTokensPerUser > 0) {
            IFactory(factory).createCrossChainERC721DAO(
                _commLayerId,
                _ownerFeePerDepositPercent,
                _depositTime,
                _quorumPercent,
                _thresholdPercent,
                _safeThreshold,
                _depoitChainIds,
                _daoAddress,
                _depositTokenAddress,
                _admins,
                _maxTokensPerUser,
                _distributionAmount,
                _pricePerToken,
                _onlyAllowWhitelist,
                _merkleRoot
            );
        } else {
            IFactory(factory).createCrossChainERC20DAO(
                _commLayerId,
                _distributionAmount,
                _pricePerToken,
                _minDepositPerUser,
                _maxDepositPerUser,
                _ownerFeePerDepositPercent,
                _depositTime,
                _quorumPercent,
                _thresholdPercent,
                _safeThreshold,
                _depoitChainIds,
                _daoAddress,
                _depositTokenAddress,
                _admins,
                _onlyAllowWhitelist,
                _merkleRoot
            );
        }
    }

    function setDestination(
        uint16 _chainId,
        address _dstCommLayer
    ) external onlyOwner {
        dstCommLayer[_chainId] = _dstCommLayer;
    }

    function forceResume(
        uint16 _srcChainId,
        bytes memory _from
    ) external onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _from);
    }

    // // @notice set the send() LayerZero messaging library version to _version
    // // @param _version - new messaging library version
    // function setSendVersion(uint16 _version) external onlyOwner {
    //     endpoint.setSendVersion(_version);
    // }

    // // @notice set the lzReceive() LayerZero messaging library version to _version
    // // @param _version - new messaging library version
    // function setReceiveVersion(uint16 _version) external onlyOwner {
    //     endpoint.setReceiveVersion(_version);
    // }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import "../interfaces/IFactory.sol";
import "../interfaces/ICommLayer.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./ExcessivelySafeCall.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LayerZeroImpl is ICommLayer, ILayerZeroReceiver, Initializable {
    using ExcessivelySafeCall for address;

    /// @notice LayerZero endoint address
    ILayerZeroEndpoint public endpoint;

    IFactory public factory;

    address private owner;

    /// @notice mapping to keep track of failed messages
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
        public failedMessages;

    mapping(uint16 => address) private dstCommLayer;

    /// @notice Extra LayerZero fees customization parameters
    struct lzAdapterParams {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    event msgSent(
        uint16 _dstChainId,
        bytes _destination,
        bytes _payload,
        uint256 nonce
    );
    event ReceiveMsg(
        uint16 _srcChainId,
        address _from,
        bytes _payload,
        uint256 nonce
    );
    event RetriedPayload(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    event ForceResumed(uint16 _srcChainId, bytes _srcAddress, bytes _payload);
    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload,
        bytes _reason
    );

    function initialize(
        address _endpoint,
        address _factory
    ) external initializer {
        endpoint = ILayerZeroEndpoint(_endpoint);
        factory = IFactory(_factory);
        owner = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == address(factory), "Only Factory");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _factory factory address
    function changeFactory(address _factory) external onlyOwner {
        factory = IFactory(_factory);
    }

    /// @notice This function is responsible to estimate fees required for sending message
    /// @param _dstChainId Destination Chain Id
    /// @param _userApplication Destination contract address
    /// @param _payload Encoded data to send on destination chain
    /// @param _adapterParameters Extra fees customization parameters
    /// @return nativeFee Fees required in native token
    /// @return zroFee Fees required in zro token
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bytes calldata _adapterParameters
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            endpoint.estimateFees(
                _dstChainId,
                _userApplication,
                _payload,
                false,
                _adapterParameters
            );
    }

    /// @notice This function is responsible for setting source LayerZeroImpl addresses
    /// @dev onlyOwner is allowed to call this function
    /// @param _endpoint Source chain LayerZeroImpl address
    function changeEndpoint(address _endpoint) external onlyOwner {
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /// @notice This function is responsible for sending messages to another chain using LayerZero
    /// @dev It makes call to LayerZero endpoint contract
    /// @dev This function can only be called from CommLayerAggregator
    /// @param _destination Address of destination contract to send message on
    /// @param _payload Encoded data to send on destination chain
    function sendMsg(
        address _destination,
        bytes calldata _payload,
        bytes memory extraParams
    ) public payable onlyFactory {
        (uint16 _dstChainId, address refundAd) = abi.decode(
            extraParams,
            (uint16, address)
        );

        uint64 nextNonce = endpoint.getOutboundNonce(
            _dstChainId,
            address(this)
        ) + 1;

        endpoint.send{value: msg.value}(
            _dstChainId,
            abi.encodePacked(dstCommLayer[uint16(_dstChainId)], address(this)),
            _payload,
            payable(refundAd),
            address(0x0),
            abi.encodePacked(uint16(1), uint256(600000))
        );
        emit msgSent(
            _dstChainId,
            abi.encodePacked(dstCommLayer[uint16(_dstChainId)]),
            _payload,
            nextNonce
        );
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual override {
        require(
            msg.sender == address(endpoint),
            "LzApp: invalid endpoint caller"
        );
        bytes memory trustedRemote = abi.encodePacked(
            dstCommLayer[_srcChainId],
            address(this)
        );
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );
        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(
                this.nonblockingLzReceive.selector,
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload
            )
        );

        if (!success) {
            _storeFailedMessage(
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload,
                reason
            );
        }
    }

    function _storeFailedMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload,
        bytes memory _reason
    ) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        require(
            msg.sender == address(this),
            "NonblockingLzApp: caller must be LzApp"
        );
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _from,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        address from;
        assembly {
            from := mload(add(_from, 20))
        }
        // require(msg.sender == address(endpoint));
        require(from == dstCommLayer[_srcChainId]);
        if (
            keccak256(abi.encodePacked((_payload))) ==
            keccak256(abi.encodePacked((bytes10("ff"))))
        ) {
            endpoint.receivePayload(
                1,
                bytes(""),
                address(0x0),
                1,
                1,
                bytes("")
            );
        }
        (
            address _daoAddress,
            address _receiver,
            uint256 _amount,
            string memory _tokenURI,
            bytes32[] memory _merkleProof
        ) = abi.decode(
                _payload,
                (address, address, uint256, string, bytes32[])
            );

        IFactory(factory).crossChainMint(
            _receiver,
            _daoAddress,
            _amount,
            _tokenURI,
            _merkleProof
        );

        emit ReceiveMsg(_srcChainId, from, _payload, _nonce);
    }

    function forceResume(
        uint16 _srcChainId,
        bytes memory _from
    ) external onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _from);
    }

    function setDestination(
        uint16 _chainId,
        address _dstCommLayer
    ) external onlyOwner {
        dstCommLayer[_chainId] = _dstCommLayer;
    }

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external onlyOwner {
        endpoint.setSendVersion(_version);
    }

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external onlyOwner {
        endpoint.setReceiveVersion(_version);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */

contract ProxyContract is TransparentUpgradeableProxy {
    constructor(
        address _implementation,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_implementation, _admin, _data) {}

    function getAdmin() external view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    function getImplementation() external view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../emitter.sol";

contract RefundFactory is AccessControl, Initializable {
    uint public refundDeploymentFee;

    address private _emitterContract;
    address private _owner;

    address private _refundModuleImplementation;

    error InsufficientFee();

    function initialize(
        address refundModuleImplementation,
        uint _refundDeploymentFee,
        address _emitter
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _refundModuleImplementation = refundModuleImplementation;
        refundDeploymentFee = _refundDeploymentFee;
        _owner = msg.sender;
        _emitterContract = _emitter;
    }

    // Add changes to make sure only safe owner / only can be called via a proposal
    function deployRefundModule(
        address _dao,
        bytes32 _merkleRoot
    ) external payable {
        if (msg.value != refundDeploymentFee) revert InsufficientFee();
        bytes memory _initializer = abi.encodeWithSignature(
            "initialize(address,address,address,bytes32)",
            msg.sender,
            _dao,
            _emitterContract,
            _merkleRoot
        );

        address newRefundContract = address(
            new TransparentUpgradeableProxy(
                _refundModuleImplementation,
                _owner,
                _initializer
            )
        );

        Emitter(_emitterContract).deployRefundModule(
            address(newRefundContract),
            msg.sender,
            _dao,
            _merkleRoot
        );
    }

    /// @notice This function sets the address of emitter contract
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _emitter Address of emitter contract
    function setEmitter(
        address _emitter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _emitterContract = _emitter;
    }

    /// @notice This function is used to update fee of claim
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _newRefundDeploymentFee Updated  fee
    function changeRefundDeploymentFee(
        uint _newRefundDeploymentFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        refundDeploymentFee = _newRefundDeploymentFee;
    }

    /// @notice This function is used to change address of claim implementation
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _newRefundModuleImplementation Address of new implementation
    function changeRefundModuleImplementation(
        address _newRefundModuleImplementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _refundModuleImplementation = _newRefundModuleImplementation;
    }

    /// @notice This function is used to withdraw funds collected through claim deployments
    /// @dev Can be only called by DEFAULT_ADMIN_ROLE role
    /// @param _receiver Address of receiver
    /// @param _amount Amount to withdraw
    function withdrawFunds(
        address _receiver,
        uint _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = payable(_receiver).call{value: _amount}("");
        require(success, "Withdraw failed");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../emitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Token {
    function burn(address account, uint256 amount) external;

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface Safe {
    function isOwner(address owner) external view returns (bool);
}

contract RefundModule is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private emitterContract;

    address public safe;

    address public dao;

    bytes32 public merkleRoot;

    mapping(address => uint256) public burnAmount;

    mapping(address => uint256) public transferAmount;

    error IncorrectProof();
    error IncorrectUserAddress();

    modifier onlyAdmins(address _safe) {
        require(Safe(_safe).isOwner(msg.sender), "Only safe admin access");
        _;
    }

    function initialize(
        address _safe,
        address _dao,
        address _emitter,
        bytes32 _merkleRoot
    ) external initializer {
        safe = _safe;
        dao = _dao;
        emitterContract = _emitter;
        merkleRoot = _merkleRoot;
    }

    function refundERC20DAO(
        uint256 _burnAmount,
        uint256 _transferAmount,
        bytes32[] calldata _merkleProof,
        bytes memory _encodedData
    ) external payable nonReentrant {
        bytes32 leaf = keccak256(_encodedData);
        (
            address _adr,
            address _token,
            uint256 _maxBurnAmount,
            uint256 _maxTransferAmount
        ) = abi.decode(_encodedData, (address, address, uint256, uint256));

        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
            revert IncorrectProof();

        if (_adr != msg.sender) revert IncorrectUserAddress();
        require(
            burnAmount[msg.sender] + _burnAmount <= _maxBurnAmount,
            "Max burn amount reached"
        );
        require(
            transferAmount[msg.sender] + _transferAmount <= _maxTransferAmount,
            "Max transfer amount reached"
        );

        burnAmount[msg.sender] += _burnAmount;
        transferAmount[msg.sender] += _transferAmount;

        Token(dao).burn(_adr, _burnAmount);

        IERC20(_token).safeTransferFrom(safe, msg.sender, _transferAmount);

        Emitter(emitterContract).refundERC20DAO(
            _adr,
            dao,
            address(this),
            _token,
            _burnAmount,
            _transferAmount
        );
    }

    function refundERC721DAO(
        uint256 _tokenId,
        uint256 _transferAmount,
        address _transferToken,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(Token(dao).ownerOf(_tokenId) == msg.sender);
        bytes32 leaf = keccak256(
            abi.encode(msg.sender, _transferToken, _tokenId, _transferAmount)
        );

        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
            revert IncorrectProof();

        Token(dao).burn(_tokenId);

        IERC20(_transferToken).safeTransferFrom(
            safe,
            msg.sender,
            _transferAmount
        );

        Emitter(emitterContract).refundERC721DAO(
            msg.sender,
            dao,
            address(this),
            _transferToken,
            _tokenId,
            _transferAmount
        );
    }

    function changeRoot(bytes32 _newRoot) external onlyAdmins(safe) {
        merkleRoot = _newRoot;
        Emitter(emitterContract).changeRefundModuleMerkleRoot(
            address(this),
            dao,
            _newRoot
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TestNft is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {}

    function testMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    //Below functions are purely for testing purpose to mock gnosis safe
    mapping(address => bool) private _isOwner;

    function setupOwners(address owner) external {
        _isOwner[owner] = true;
    }

    function isOwner(address owner) public view returns (bool) {
        return _isOwner[owner];
    }
}

pragma solidity ^0.8.7;

contract WMATIC {
    string public name = "Wrapped Matic";
    string public symbol = "WMATIC";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    fallback() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {
        _mint(msg.sender, 100000000 * 10**decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address _address, uint256 _amount) public {
        _mint(_address, _amount * 10**decimals());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./emitter.sol";
import "./helper.sol";

contract Airdrop is ReentrancyGuard, Helper {
    address public emitterContractAddress;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _emitterContractAddress) {
        emitterContractAddress = _emitterContractAddress;
        owner = msg.sender;
    }

    function updateEmitterAddress(
        address _emitterContractAddress
    ) external onlyOwner {
        if (address(0) == _emitterContractAddress) {
            revert AddressInvalid(
                "_emitterContractAddress",
                _emitterContractAddress
            );
        }
        emitterContractAddress = _emitterContractAddress;
    }

    function airDropToken(
        address _airdropTokenAddress,
        uint256[] memory _airdropAmountArray,
        address[] memory _members
    ) external {
        uint256 amountArrLen = _airdropAmountArray.length;
        uint256 totalMembers = _members.length;

        if (amountArrLen != totalMembers)
            revert ArrayLengthMismatch(amountArrLen, totalMembers);

        uint256 _holdings = IERC20(_airdropTokenAddress).balanceOf(msg.sender);

        uint256 _minimumRequired = 0;

        for (uint256 j = 0; j < amountArrLen; ) {
            _minimumRequired = _minimumRequired + _airdropAmountArray[j];
            unchecked {
                ++j;
            }
        }

        if (!(_holdings >= _minimumRequired)) revert InsufficientFunds();

        uint256 allowance = IERC20(_airdropTokenAddress).allowance(
            msg.sender,
            address(this)
        );

        if (!(_minimumRequired <= allowance))
            revert InsufficientAllowance(_minimumRequired, allowance);

        for (uint256 i = 0; i < totalMembers; ) {
            IERC20(_airdropTokenAddress).transferFrom(
                msg.sender,
                _members[i],
                _airdropAmountArray[i]
            );
            Emitter(emitterContractAddress).airDropToken(
                msg.sender,
                _airdropTokenAddress,
                _members[i],
                _airdropAmountArray[i]
            );
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/ICommLayer.sol";
import "./ZetaInteractor.sol";
import "./ZetaInterfaces.sol";

interface CrossChainMessageErrors {
    error InvalidMessageType();
}

contract ZetaDeployer is
    ICommLayer,
    ZetaInteractor,
    ZetaReceiver,
    CrossChainMessageErrors
{
    bytes32 public constant CROSS_CHAIN_MESSAGE_MESSAGE_TYPE =
        keccak256("CROSS_CHAIN_CROSS_CHAIN_MESSAGE");

    event CrossChainMessageEvent(string);
    event CrossChainMessageRevertedEvent(string);

    address private factory;
    ZetaTokenConsumer private immutable _zetaConsumer;
    IERC20 internal immutable _zetaToken;

    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }

    constructor(
        address _factory,
        address connectorAddress,
        address zetaTokenAddress,
        address zetaConsumerAddress
    ) ZetaInteractor(connectorAddress) {
        factory = _factory;

        _zetaToken = IERC20(zetaTokenAddress);
        _zetaConsumer = ZetaTokenConsumer(zetaConsumerAddress);
    }

    function sendMsg(
        address _destination,
        bytes calldata _payload,
        bytes memory extraParams
    ) external payable onlyFactory {
        uint256 destinationChainId = abi.decode(extraParams, (uint256));
        // if (!_isValidChainId(destinationChainId))
        //     revert InvalidDestinationChainId();

        uint256 crossChainGas = 2 * (10 ** 18);
        uint256 zetaValueAndGas = _zetaConsumer.getZetaFromEth{
            value: msg.value
        }(address(this), crossChainGas);
        _zetaToken.approve(address(connector), zetaValueAndGas);

        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: destinationChainId,
                destinationAddress: interactorsByChainId[destinationChainId],
                destinationGasLimit: 15000000,
                message: _payload,
                zetaValueAndGas: zetaValueAndGas,
                zetaParams: abi.encode("")
            })
        );
    }

    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external override isValidMessageCall(zetaMessage) {
        (
            uint16 _commLayerId,
            uint256 _distributionAmount,
            uint256 _pricePerToken,
            uint256 _minDepositPerUser,
            uint256 _maxDepositPerUser,
            uint256 _ownerFeePerDepositPercent,
            uint256 _depositTime,
            uint256 _quorumPercent,
            uint256 _thresholdPercent,
            uint256 _safeThreshold,
            uint256[] memory _depoitChainIds,
            address _daoAddress,
            address _depositTokenAddress,
            address[] memory _admins,
            bool _onlyAllowWhitelist,
            bytes32 _merkleRoot,
            uint256 _maxTokensPerUser
        ) = abi.decode(
                zetaMessage.message,
                (
                    uint16,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    uint256[],
                    address,
                    address,
                    address[],
                    bool,
                    bytes32,
                    uint256
                )
            );

        if (_maxTokensPerUser > 0) {
            IFactory(factory).createCrossChainERC721DAO(
                _commLayerId,
                _ownerFeePerDepositPercent,
                _depositTime,
                _quorumPercent,
                _thresholdPercent,
                _safeThreshold,
                _depoitChainIds,
                _daoAddress,
                _depositTokenAddress,
                _admins,
                _maxTokensPerUser,
                _distributionAmount,
                _pricePerToken,
                _onlyAllowWhitelist,
                _merkleRoot
            );
        } else {
            IFactory(factory).createCrossChainERC20DAO(
                _commLayerId,
                _distributionAmount,
                _pricePerToken,
                _minDepositPerUser,
                _maxDepositPerUser,
                _ownerFeePerDepositPercent,
                _depositTime,
                _quorumPercent,
                _thresholdPercent,
                _safeThreshold,
                _depoitChainIds,
                _daoAddress,
                _depositTokenAddress,
                _admins,
                _onlyAllowWhitelist,
                _merkleRoot
            );
        }

        // emit CrossChainMessageEvent(zetaMessage.message);
    }

    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external override isValidRevertCall(zetaRevert) {
        (bytes32 messageType, string memory message) = abi.decode(
            zetaRevert.message,
            (bytes32, string)
        );

        if (messageType != CROSS_CHAIN_MESSAGE_MESSAGE_TYPE)
            revert InvalidMessageType();

        emit CrossChainMessageRevertedEvent(message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/ICommLayer.sol";
import "./ZetaInteractor.sol";
import "./ZetaInterfaces.sol";

interface CrossChainMessageErrors {
    error InvalidMessageType();
}

contract ZetaImpl is
    ICommLayer,
    ZetaInteractor,
    ZetaReceiver,
    CrossChainMessageErrors
{
    bytes32 public constant CROSS_CHAIN_MESSAGE_MESSAGE_TYPE =
        keccak256("CROSS_CHAIN_CROSS_CHAIN_MESSAGE");

    event CrossChainMessageEvent(bytes);
    event CrossChainMessageRevertedEvent(string);

    address private factory;
    ZetaTokenConsumer private immutable _zetaConsumer;
    IERC20 internal immutable _zetaToken;

    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }

    constructor(
        address _factory,
        address connectorAddress,
        address zetaTokenAddress,
        address zetaConsumerAddress
    ) ZetaInteractor(connectorAddress) {
        factory = _factory;

        _zetaToken = IERC20(zetaTokenAddress);
        _zetaConsumer = ZetaTokenConsumer(zetaConsumerAddress);
    }

    function sendMsg(
        address _destination,
        bytes calldata _payload,
        bytes memory extraParams
    ) external payable onlyFactory {
        uint256 destinationChainId = abi.decode(extraParams, (uint256));
        // if (!_isValidChainId(destinationChainId))
        //     revert InvalidDestinationChainId();

        uint256 crossChainGas = 2 * (10 ** 18);
        uint256 zetaValueAndGas = _zetaConsumer.getZetaFromEth{
            value: msg.value
        }(address(this), crossChainGas);
        _zetaToken.approve(address(connector), zetaValueAndGas);

        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: destinationChainId,
                destinationAddress: interactorsByChainId[destinationChainId],
                destinationGasLimit: 700000,
                message: _payload,
                zetaValueAndGas: zetaValueAndGas,
                zetaParams: abi.encode("")
            })
        );
    }

    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external override isValidMessageCall(zetaMessage) {
        (
            address _daoAddress,
            address _receiver,
            uint256 _amount,
            string memory _tokenURI,
            bytes32[] memory _merkleProof
        ) = abi.decode(
                zetaMessage.message,
                (address, address, uint256, string, bytes32[])
            );

        IFactory(factory).crossChainMint(
            _receiver,
            _daoAddress,
            _amount,
            _tokenURI,
            _merkleProof
        );

        emit CrossChainMessageEvent(zetaMessage.message);
    }

    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external override isValidRevertCall(zetaRevert) {
        (bytes32 messageType, string memory message) = abi.decode(
            zetaRevert.message,
            (bytes32, string)
        );

        if (messageType != CROSS_CHAIN_MESSAGE_MESSAGE_TYPE)
            revert InvalidMessageType();

        emit CrossChainMessageRevertedEvent(message);
    }

    function transferZeta(uint amount) external onlyOwner {
        _zetaToken.transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./ZetaInterfaces.sol";
import "./ZetaInteractorErrors.sol";

abstract contract ZetaInteractor is Ownable2Step, ZetaInteractorErrors {
    bytes32 constant ZERO_BYTES = keccak256(new bytes(0));
    uint256 internal immutable currentChainId;
    ZetaConnector public immutable connector;

    /**
     * @dev Maps a chain id to its corresponding address of the MultiChainSwap contract
     * The address is expressed in bytes to allow non-EVM chains
     * This mapping is useful, mainly, for two reasons:
     *  - Given a chain id, the contract is able to route a transaction to its corresponding address
     *  - To check that the messages (onZetaMessage, onZetaRevert) come from a trusted source
     */
    mapping(uint256 => bytes) public interactorsByChainId;

    modifier isValidMessageCall(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) {
        _isValidCaller();
        if (
            keccak256(zetaMessage.zetaTxSenderAddress) !=
            keccak256(interactorsByChainId[zetaMessage.sourceChainId])
        ) revert InvalidZetaMessageCall();
        _;
    }

    modifier isValidRevertCall(ZetaInterfaces.ZetaRevert calldata zetaRevert) {
        _isValidCaller();
        if (zetaRevert.zetaTxSenderAddress != address(this))
            revert InvalidZetaRevertCall();
        if (zetaRevert.sourceChainId != currentChainId)
            revert InvalidZetaRevertCall();
        _;
    }

    constructor(address zetaConnectorAddress) {
        if (zetaConnectorAddress == address(0))
            revert ZetaCommonErrors.InvalidAddress();
        currentChainId = block.chainid;
        connector = ZetaConnector(zetaConnectorAddress);
    }

    function _isValidCaller() private view {
        if (msg.sender != address(connector)) revert InvalidCaller(msg.sender);
    }

    /**
     * @dev Useful for contracts that inherit from this one
     */
    function _isValidChainId(uint256 chainId) internal view returns (bool) {
        return (keccak256(interactorsByChainId[chainId]) != ZERO_BYTES);
    }

    function setInteractorByChainId(
        uint256 destinationChainId,
        bytes calldata contractAddress
    ) external onlyOwner {
        interactorsByChainId[destinationChainId] = contractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface with Zeta Interactor errors
 */
interface ZetaInteractorErrors {
    // @dev Thrown when try to send a message or tokens to a non whitelisted chain
    error InvalidDestinationChainId();

    // @dev Thrown when the caller is invalid. e.g.: if onZetaMessage or onZetaRevert are not called by Connector
    error InvalidCaller(address caller);

    // @dev Thrown when message on onZetaMessage has the wrong format
    error InvalidZetaMessageCall();

    // @dev Thrown when message on onZetaRevert has the wrong format
    error InvalidZetaRevertCall();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ZetaInterfaces {
    /**
     * @dev Use SendInput to interact with the Connector: connector.send(SendInput)
     */
    struct SendInput {
        /// @dev Chain id of the destination chain. More about chain ids https://docs.zetachain.com/learn/glossary#chain-id
        uint256 destinationChainId;
        /// @dev Address receiving the message on the destination chain (expressed in bytes since it can be non-EVM)
        bytes destinationAddress;
        /// @dev Gas limit for the destination chain's transaction
        uint256 destinationGasLimit;
        /// @dev An encoded, arbitrary message to be parsed by the destination contract
        bytes message;
        /// @dev ZETA to be sent cross-chain + ZetaChain gas fees + destination chain gas fees (expressed in ZETA)
        uint256 zetaValueAndGas;
        /// @dev Optional parameters for the ZetaChain protocol
        bytes zetaParams;
    }

    /**
     * @dev Our Connector calls onZetaMessage with this struct as argument
     */
    struct ZetaMessage {
        bytes zetaTxSenderAddress;
        uint256 sourceChainId;
        address destinationAddress;
        /// @dev Remaining ZETA from zetaValueAndGas after subtracting ZetaChain gas fees and destination gas fees
        uint256 zetaValue;
        bytes message;
    }

    /**
     * @dev Our Connector calls onZetaRevert with this struct as argument
     */
    struct ZetaRevert {
        address zetaTxSenderAddress;
        uint256 sourceChainId;
        bytes destinationAddress;
        uint256 destinationChainId;
        /// @dev Equals to: zetaValueAndGas - ZetaChain gas fees - destination chain gas fees - source chain revert tx gas fees
        uint256 remainingZetaValue;
        bytes message;
    }
}

interface ZetaConnector {
    /**
     * @dev Sending value and data cross-chain is as easy as calling connector.send(SendInput)
     */
    function send(ZetaInterfaces.SendInput calldata input) external;
}

interface ZetaReceiver {
    /**
     * @dev onZetaMessage is called when a cross-chain message reaches a contract
     */
    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external;

    /**
     * @dev onZetaRevert is called when a cross-chain message reverts.
     * It's useful to rollback to the original state
     */
    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external;
}

/**
 * @dev ZetaTokenConsumer makes it easier to handle the following situations:
 *   - Getting Zeta using native coin (to pay for destination gas while using `connector.send`)
 *   - Getting Zeta using a token (to pay for destination gas while using `connector.send`)
 *   - Getting native coin using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 *   - Getting a token using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 * @dev The interface can be implemented using different strategies, like UniswapV2, UniswapV3, etc
 */
interface ZetaTokenConsumer {
    event EthExchangedForZeta(uint256 amountIn, uint256 amountOut);
    event TokenExchangedForZeta(
        address token,
        uint256 amountIn,
        uint256 amountOut
    );
    event ZetaExchangedForEth(uint256 amountIn, uint256 amountOut);
    event ZetaExchangedForToken(
        address token,
        uint256 amountIn,
        uint256 amountOut
    );

    function getZetaFromEth(
        address destinationAddress,
        uint256 minAmountOut
    ) external payable returns (uint256);

    function getZetaFromToken(
        address destinationAddress,
        uint256 minAmountOut,
        address inputToken,
        uint256 inputTokenAmount
    ) external returns (uint256);

    function getEthFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        uint256 zetaTokenAmount
    ) external returns (uint256);

    function getTokenFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        address outputToken,
        uint256 zetaTokenAmount
    ) external returns (uint256);

    function hasZetaLiquidity() external view returns (bool);
}

interface ZetaCommonErrors {
    error InvalidAddress();
}