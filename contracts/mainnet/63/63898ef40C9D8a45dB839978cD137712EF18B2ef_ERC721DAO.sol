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
            0,
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