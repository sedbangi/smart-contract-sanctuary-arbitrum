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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IConsumable is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;

    function adminBurn(address account, uint256 id, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICorruption is IERC20Upgradeable {
    function burn(address _account, uint256 _amount) external;
    function setCorruptionStreamBoost(address _account, uint32 _boost) external;
    function corruptionMinimum(address _account) external view returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./CraftingDiamondState.sol";

contract CraftingDiamondSettings is Initializable, CraftingDiamondState {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function setCraftingFee(uint256 _craftingFee) external onlyAdminOrOwner {
        craftingFee = _craftingFee;
    }

    function setSimpleSettings(
        uint256 _craftingFee,
        uint8 _percentReturnedOnFailure)
    external
    onlyAdminOrOwner
    {
        require(_percentReturnedOnFailure >= 0 && _percentReturnedOnFailure <= 100, "Bad refund percent");
        craftingFee = _craftingFee;
        percentReturnedOnFailure = _percentReturnedOnFailure;
    }

    function setRewards(
        CraftingReward[] calldata _easyRewards,
        CraftingReward[] calldata _mediumRewards,
        CraftingReward[] calldata _hardRewards,
        CraftingReward[] calldata _prismSmallToMediumRewards,
        CraftingReward[] calldata _prismMediumToLargeRewards)
    external
    onlyAdminOrOwner
    {

        RecipeDifficulty[5] memory _difficulties = [
            RecipeDifficulty.EASY,
            RecipeDifficulty.MEDIUM,
            RecipeDifficulty.HARD,
            RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM,
            RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE
        ];

        for(uint256 i = 0; i < _difficulties.length; i++) {
            delete difficultyToRewards[_difficulties[i]];

            CraftingReward[] memory _rewardsForDifficulty;
            if(_difficulties[i] == RecipeDifficulty.EASY) {
                _rewardsForDifficulty = _easyRewards;
            } else if(_difficulties[i] == RecipeDifficulty.MEDIUM) {
                _rewardsForDifficulty = _mediumRewards;
            } else if(_difficulties[i] == RecipeDifficulty.HARD) {
                _rewardsForDifficulty = _hardRewards;
            } else if(_difficulties[i] == RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM) {
                _rewardsForDifficulty = _prismSmallToMediumRewards;
            } else {
                _rewardsForDifficulty = _prismMediumToLargeRewards;
            }
            uint256 _totalRewardOdds = 0;
            for(uint256 j = 0; j < _rewardsForDifficulty.length; j++) {
                difficultyToRewards[_difficulties[i]].push(_rewardsForDifficulty[j]);
                _totalRewardOdds += _rewardsForDifficulty[j].odds;
            }

            require(_totalRewardOdds == 100000, "Bad odds");
        }
    }

    function setDifficultySettings(
        uint256[5] calldata _recipeLengths,
        uint256[5] calldata _successRates,
        uint8[5][5] calldata _treasureAmountPerTier,
        uint8[5] memory _levelUnlocked)
    external
    onlyAdminOrOwner
    {
        difficultyToRecipeLength[RecipeDifficulty.EASY] = _recipeLengths[0];
        difficultyToRecipeLength[RecipeDifficulty.MEDIUM] = _recipeLengths[1];
        difficultyToRecipeLength[RecipeDifficulty.HARD] = _recipeLengths[2];
        difficultyToRecipeLength[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = _recipeLengths[3];
        difficultyToRecipeLength[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = _recipeLengths[4];

        difficultyToSuccessRate[RecipeDifficulty.EASY] = _successRates[0];
        difficultyToSuccessRate[RecipeDifficulty.MEDIUM] = _successRates[1];
        difficultyToSuccessRate[RecipeDifficulty.HARD] = _successRates[2];
        difficultyToSuccessRate[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = _successRates[3];
        difficultyToSuccessRate[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = _successRates[4];

        for(uint256 i = 0; i < 5; i++) {
            difficultyToAmountPerTier[RecipeDifficulty.EASY][i] = _treasureAmountPerTier[0][i];
            difficultyToAmountPerTier[RecipeDifficulty.MEDIUM][i] = _treasureAmountPerTier[1][i];
            difficultyToAmountPerTier[RecipeDifficulty.HARD][i] = _treasureAmountPerTier[2][i];
            difficultyToAmountPerTier[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM][i] = _treasureAmountPerTier[3][i];
            difficultyToAmountPerTier[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE][i] = _treasureAmountPerTier[4][i];
        }

        difficultyToLevelUnlocked[RecipeDifficulty.EASY] = _levelUnlocked[0];
        difficultyToLevelUnlocked[RecipeDifficulty.MEDIUM] = _levelUnlocked[1];
        difficultyToLevelUnlocked[RecipeDifficulty.HARD] = _levelUnlocked[2];
        difficultyToLevelUnlocked[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = _levelUnlocked[3];
        difficultyToLevelUnlocked[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = _levelUnlocked[4];
    }

    function setCraftingLevelSettings(
        uint8 _maxCraftingLevel,
        uint256[] calldata _levelToCPNeeded,
        uint256[5] calldata _difficultyToCPGainedPerRecipe)
    external
    onlyAdminOrOwner
    {
        require(_maxCraftingLevel > 0, "Bad max level");
        require(_levelToCPNeeded.length == _maxCraftingLevel - 1, "Not enough CP steps");

        maxCraftingLevel = _maxCraftingLevel;

        delete levelToCPNeeded;
        delete levelToCPGainedPerRecipe;

        levelToCPNeeded.push(0);
        levelToCPGainedPerRecipe.push(0);

        for(uint256 i = 0; i < _maxCraftingLevel - 1; i++) {
            levelToCPNeeded.push(_levelToCPNeeded[i]);
        }

        difficultyToCPGained[RecipeDifficulty.EASY] = _difficultyToCPGainedPerRecipe[0];
        difficultyToCPGained[RecipeDifficulty.MEDIUM] = _difficultyToCPGainedPerRecipe[1];
        difficultyToCPGained[RecipeDifficulty.HARD] = _difficultyToCPGainedPerRecipe[2];
        difficultyToCPGained[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = _difficultyToCPGainedPerRecipe[3];
        difficultyToCPGained[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = _difficultyToCPGainedPerRecipe[4];
    }

    function setDifficultyAndGenerationReward(
        RecipeDifficulty _difficulty,
        LegionGeneration _generation,
        CraftingReward[] calldata _rewards)
    external
    onlyAdminOrOwner
    {
        delete difficultyToGenerationToRewards[_difficulty][_generation];

        for(uint256 i = 0; i < _rewards.length; i++) {
            difficultyToGenerationToRewards[_difficulty][_generation].push(_rewards[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "../../shared/randomizer/IRandomizer.sol";
import "./ICrafting.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../external/ITreasure.sol";
import "../external/IMagic.sol";
import "../legion/ILegion.sol";
import "../treasury/ITreasury.sol";
import "../consumable/IConsumable.sol";
import "../treasuremetadatastore/ITreasureMetadataStore.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";
import "../corruption/ICorruption.sol";

abstract contract CraftingDiamondState is Initializable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, AdminableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event CraftingStarted(address indexed _owner, uint256 indexed _tokenId, uint256 indexed _requestId, uint256 _finishTime, uint256[] _treasureIds, uint8[] _treasureAmounts, RecipeDifficulty _difficulty);
    event CraftingRevealed(address indexed _owner, uint256 indexed _tokenId, CraftingOutcome _outcome);
    event CraftingFinished(address indexed _owner, uint256 indexed _tokenId);

    event CPGained(uint256 _tokenId, uint8 _craftLevel, uint256 _cpFinal);

    uint256 constant SMALL_PRISM_ID = 1;
    uint256 constant MEDIUM_PRISM_ID = 2;
    uint256 constant EOS_ID = 8;
    uint256 constant PRISM_SHARDS_ID = 9;

    IRandomizer internal randomizer;
    ITreasure internal treasure;
    ILegion internal legion;
    ITreasureMetadataStore internal treasureMetadataStore;
    ILegionMetadataStore internal legionMetadataStore;
    IMagic internal magic;
    ITreasury internal treasury;
    IConsumable internal consumable;

    mapping(RecipeDifficulty => uint256) public difficultyToRecipeLength;
    mapping(RecipeDifficulty => uint256) public difficultyToSuccessRate;
    mapping(RecipeDifficulty => uint8[5]) public difficultyToAmountPerTier;
    mapping(RecipeDifficulty => uint8) public difficultyToLevelUnlocked;

    // Reward state
    mapping(RecipeDifficulty => CraftingReward[]) public difficultyToRewards;

    uint8 public maxCraftingLevel;
    uint256[] public levelToCPNeeded;
    // DEPRECATED
    uint256[] public levelToCPGainedPerRecipe;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal userToLegionsInProgress;

    mapping(uint256 => uint256) public tokenIdToCP;
    mapping(uint256 => uint256) public tokenIdToCraftingStartTime;
    mapping(uint256 => uint256) public tokenIdToRequestId;
    mapping(uint256 => uint256) public tokenIdToMagicPaid;
    mapping(uint256 => RecipeDifficulty) public tokenIdToRecipeDifficulty;
    mapping(uint256 => StakedTreasure[]) public tokenIdToStakedTreasure;

    uint256 public craftingFee;
    uint8 public percentReturnedOnFailure;

    mapping(RecipeDifficulty => mapping(LegionGeneration => CraftingReward[])) public difficultyToGenerationToRewards;
    mapping(RecipeDifficulty => uint256) public difficultyToCPGained;

    ICorruption internal corruption;

    function __CraftingDiamondState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();

        difficultyToRecipeLength[RecipeDifficulty.EASY] = 8 hours;
        difficultyToRecipeLength[RecipeDifficulty.MEDIUM] = 12 hours;
        difficultyToRecipeLength[RecipeDifficulty.HARD] = 16 hours;
        difficultyToRecipeLength[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = 2 days;
        difficultyToRecipeLength[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = 2 days;

        difficultyToSuccessRate[RecipeDifficulty.EASY] = 100000;
        difficultyToSuccessRate[RecipeDifficulty.MEDIUM] = 100000;
        difficultyToSuccessRate[RecipeDifficulty.HARD] = 100000;
        difficultyToSuccessRate[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = 100000;
        difficultyToSuccessRate[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = 100000;

        difficultyToLevelUnlocked[RecipeDifficulty.EASY] = 1;
        difficultyToLevelUnlocked[RecipeDifficulty.MEDIUM] = 3;
        difficultyToLevelUnlocked[RecipeDifficulty.HARD] = 5;
        difficultyToLevelUnlocked[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = 1;
        difficultyToLevelUnlocked[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = 1;

        difficultyToAmountPerTier[RecipeDifficulty.EASY] = [0, 0, 1, 2, 4];
        difficultyToAmountPerTier[RecipeDifficulty.MEDIUM] = [1, 1, 2, 2, 5];
        difficultyToAmountPerTier[RecipeDifficulty.HARD] = [0, 1, 1, 3, 4];
        difficultyToAmountPerTier[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = [0, 0, 0, 0, 0];
        difficultyToAmountPerTier[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = [0, 0, 0, 0, 0];

        difficultyToRewards[RecipeDifficulty.EASY].push(CraftingReward(1, 1, 75000));
        difficultyToRewards[RecipeDifficulty.EASY].push(CraftingReward(2, 1, 15000));
        difficultyToRewards[RecipeDifficulty.EASY].push(CraftingReward(3, 1, 10000));
        difficultyToRewards[RecipeDifficulty.MEDIUM].push(CraftingReward(7, 1, 99990));
        difficultyToRewards[RecipeDifficulty.MEDIUM].push(CraftingReward(7, 2, 10));
        difficultyToRewards[RecipeDifficulty.HARD].push(CraftingReward(4, 1, 75000));
        difficultyToRewards[RecipeDifficulty.HARD].push(CraftingReward(5, 1, 15000));
        difficultyToRewards[RecipeDifficulty.HARD].push(CraftingReward(6, 1, 10000));
        difficultyToRewards[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM].push(CraftingReward(2, 1, 100000));
        difficultyToRewards[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE].push(CraftingReward(3, 1, 100000));

        maxCraftingLevel = 6;

        levelToCPNeeded.push(0);
        levelToCPNeeded.push(140);
        levelToCPNeeded.push(160);
        levelToCPNeeded.push(160);
        levelToCPNeeded.push(160);
        levelToCPNeeded.push(480);

        difficultyToCPGained[RecipeDifficulty.EASY] = 10;
        difficultyToCPGained[RecipeDifficulty.MEDIUM] = 20;
        difficultyToCPGained[RecipeDifficulty.HARD] = 40;
        difficultyToCPGained[RecipeDifficulty.PRISM_UPGRADE_SMALL_TO_MEDIUM] = 0;
        difficultyToCPGained[RecipeDifficulty.PRISM_UPGRADE_MEDIUM_TO_LARGE] = 0;

        percentReturnedOnFailure = 90;

        craftingFee = 5 ether;
    }
}

struct StartCraftingParams {
    uint256 legionId;
    RecipeDifficulty difficulty;
    uint256[] treasureIds;
    uint8[] treasureAmounts;
}

// Do not change, stored in state.
struct CraftingReward {
    uint256 consumableId;
    uint8 amount;
    uint32 odds;
}

// Do not change, stored in state.
struct StakedTreasure {
    uint8 amount;
    uint256 treasureId;
}

// Safe to change, as only in event not in state.
struct CraftingOutcome {
    bool wasSuccessful;
    uint256 magicReturned;
    uint256 rewardId;
    uint256[] brokenTreasureIds;
    uint256[] brokenAmounts;
    uint8 rewardAmount;
}

enum RecipeDifficulty {
    EASY,
    MEDIUM,
    HARD,
    PRISM_UPGRADE_SMALL_TO_MEDIUM,
    PRISM_UPGRADE_MEDIUM_TO_LARGE
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICrafting {

    function processCPGainAndLevelUp(uint256 _tokenId, uint8 _currentCraftingLevel, uint256 _craftingCPGained) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMagic {

    // Transfers the given amount to the recipient's wallet. Returns a boolean indicating if it was
    // successful or not.
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns(bool);

    // Transfer the given amount to the recipient's wallet. The sender is the caller of this function.
    // Returns a boolean indicating if it was successful or not.
    function transfer(address _recipient, uint256 _amount) external returns(bool);

    function approve(address _spender, uint256 _amount) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasure {
    // Transfers the treasure at the given ID of the given amount.
    // Requires that the legions are pre-approved.
    //
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes memory data) external;

    // Transfers the treasure at the given ID of the given amount.
    //
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory data) external;

    // Admin only.
    //
    function mint(address _account, uint256 _tokenId, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface ILegion is IERC721MetadataUpgradeable {

    // Mints a legion to the given address. Returns the token ID.
    // Admin only.
    function safeMint(address _to) external returns(uint256);

    // Sets the URI for the given token id. Token must exist.
    // Admin only.
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;

    // Transfers the token to the given address. Does not need approval. _from still must be the owner of the token.
    // Admin only.
    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    // Burns the given legion. Ensures that the _from user is the owner.
    //
    function adminBurn(address _from, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LegionMetadataStoreState.sol";

interface ILegionMetadataStore {
    // Sets the intial metadata for a token id.
    // Admin only.
    function setInitialMetadataForLegion(address _owner, uint256 _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity, uint256 _oldId) external;

    // Increases the quest level by one. It is up to the calling contract to regulate the max quest level. No validation.
    // Admin only.
    function increaseQuestLevel(uint256 _tokenId) external;

    // Increases the craft level by one. It is up to the calling contract to regulate the max craft level. No validation.
    // Admin only.
    function increaseCraftLevel(uint256 _tokenId) external;

    // Increases the rank of the given constellation to the given number. It is up to the calling contract to regulate the max constellation rank. No validation.
    // Admin only.
    function increaseConstellationRank(uint256 _tokenId, Constellation _constellation, uint8 _to) external;

    // Returns the metadata for the given legion.
    function metadataForLegion(uint256 _tokenId) external view returns(LegionMetadata memory);

    // Returns the tokenUri for the given token.
    function tokenURI(uint256 _tokenId) external view returns(string memory);
}

// As this will likely change in the future, this should not be used to store state, but rather
// as parameters and return values from functions.
struct LegionMetadata {
    LegionGeneration legionGeneration;
    LegionClass legionClass;
    LegionRarity legionRarity;
    uint8 questLevel;
    uint8 craftLevel;
    uint8[6] constellationRanks;
    uint256 oldId;
}

enum Constellation {
    FIRE,
    EARTH,
    WIND,
    WATER,
    LIGHT,
    DARK
}

enum LegionRarity {
    LEGENDARY,
    RARE,
    SPECIAL,
    UNCOMMON,
    COMMON,
    RECRUIT
}

enum LegionClass {
    RECRUIT,
    SIEGE,
    FIGHTER,
    ASSASSIN,
    RANGED,
    SPELLCASTER,
    RIVERMAN,
    NUMERAIRE,
    ALL_CLASS,
    ORIGIN
}

enum LegionGeneration {
    GENESIS,
    AUXILIARY,
    RECRUIT
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "./ILegionMetadataStore.sol";

abstract contract LegionMetadataStoreState is Initializable, AdminableUpgradeable {

    event LegionQuestLevelUp(uint256 indexed _tokenId, uint8 _questLevel);
    event LegionCraftLevelUp(uint256 indexed _tokenId, uint8 _craftLevel);
    event LegionConstellationRankUp(uint256 indexed _tokenId, Constellation indexed _constellation, uint8 _rank);
    event LegionCreated(address indexed _owner, uint256 indexed _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity);

    mapping(uint256 => LegionGeneration) internal idToGeneration;
    mapping(uint256 => LegionClass) internal idToClass;
    mapping(uint256 => LegionRarity) internal idToRarity;
    mapping(uint256 => uint256) internal idToOldId;
    mapping(uint256 => uint8) internal idToQuestLevel;
    mapping(uint256 => uint8) internal idToCraftLevel;
    mapping(uint256 => uint8[6]) internal idToConstellationRanks;

    mapping(LegionGeneration => mapping(LegionClass => mapping(LegionRarity => mapping(uint256 => string)))) internal _genToClassToRarityToOldIdToUri;

    function __LegionMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TreasureMetadataStoreState.sol";

interface ITreasureMetadataStore {
    // Sets the metadata for the given Ids.
    // Admin only.
    function setMetadataForIds(uint256[] calldata _ids, TreasureMetadata[] calldata _metadatas) external;

    // Returns if the given ID has metadata set.
    function hasMetadataForTreasureId(uint256 _treasureId) external view returns(bool);

    // Returns the metadata for the given ID. Reverts if no metadata for the ID is set.
    function getMetadataForTreasureId(uint256 _treasureId) external view returns(TreasureMetadata memory);

    // For the given tier, gets a random MINTABLE treasure id.
    function getRandomTreasureForTier(uint8 _tier, uint256 _randomNumber) external view returns(uint256);

    // For the given tier AND category, gets a random MINTABLE treasure id.
    function getRandomTreasureForTierAndCategory(
        uint8 _tier,
        TreasureCategory _category,
        uint256 _randomNumber)
    external view returns(uint256);

    // For the given tier, gets a random treasure id, MINTABLE OR NOT.
    function getAnyRandomTreasureForTier(uint8 _tier, uint256 _randomNumber) external view returns(uint256);
}

// Do not change. Stored in state.
struct TreasureMetadata {
    TreasureCategory category;
    uint8 tier;
    // Out of 100,000
    uint32 craftingBreakOdds;
    bool isMintable;
    uint256 consumableIdDropWhenBreak;
}

enum TreasureCategory {
    ALCHEMY,
    ARCANA,
    BREWING,
    ENCHANTER,
    LEATHERWORKING,
    SMITHING
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/AdminableUpgradeable.sol";
import "./ITreasureMetadataStore.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract TreasureMetadataStoreState is AdminableUpgradeable {

    mapping(uint8 => EnumerableSetUpgradeable.UintSet) internal tierToMintableTreasureIds;
    mapping(uint256 => TreasureMetadata) internal treasureIdToMetadata;
    mapping(uint8 => mapping(TreasureCategory => EnumerableSetUpgradeable.UintSet)) internal tierToCategoryToMintableTreasureIds;
    mapping(uint8 => EnumerableSetUpgradeable.UintSet) internal tierToTreasureIds;

    function __TreasureMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {

    function isBridgeWorldPowered() external view returns(bool);

    function forwardCoinsToMine(uint256 _totalMagicSent) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}