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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity 0.8.17;

import { IAccessControl } from "../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import { Context } from "../lib/openzeppelin-contracts/contracts/utils/Context.sol";
import { Strings } from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import { GlobalConstants } from "./Constants.sol";

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
abstract contract AccessControl is Context, IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    // Allow the super admin to grant & revoke contract access
    bool private _hasAdminAccess = true;
    bool private _revokedAdminAccess = false;

    // Allow the team to grant & revoke contract access
    bool private _hasTeamAccess = false;
    bool private _revokedTeamAccess = false;

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

    // /**
    //  * @dev See {IERC165-supportsInterface}.
    //  */
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    //     return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    // }

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
     * @dev Revert with a standard message if `account` is missing `role` and denied access to stakable contract.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkContractRole(address account) internal view virtual {
        if (hasRole(GlobalConstants.SUPER_ADMIN_ROLE, account)) {
            if (_hasAdminAccess) {
                return;
            } else {
                revert("AccessControl: access denied");
            }
        }

        if (hasRole(GlobalConstants.MID_ADMIN_ROLE, account)) {
            if (_hasTeamAccess) {
                return;
            } else {
                revert("AccessControl: access denied");
            }
        }

        revert("AccessControl: caller is missing role");
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

    function _setAdminContractAccess(bool access) internal {
        if (_revokedAdminAccess) revert("AccessControl: access denied");
        _revokedAdminAccess = !access;
        _hasAdminAccess = access;
    }

    function _setTeamContractAccess(bool access) internal {
        if (_revokedTeamAccess) revert("AccessControl: access denied");
        _revokedTeamAccess = !access;
        _hasTeamAccess = access;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";

interface IConfigStore {
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
    function getImplementationUint256(bytes32 interfaceName) external view returns (uint256);
}

error ImplementationNotFound();

contract ConfigStore is IConfigStore, Ownable, Multicall {
    mapping(bytes32 => address) public interfacesImplemented;

    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 of the interface name that is either changed or registered.
     * @param implementationAddress address of the implementation contract.
     */
    function changeImplementationAddress(
        bytes32 interfaceName,
        address implementationAddress
    )
        external
        override
        onlyOwner
    {
        interfacesImplemented[interfaceName] = implementationAddress;

        emit InterfaceImplementationChanged(interfaceName, implementationAddress);
    }

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the defined interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view override returns (address) {
        address implementationAddress = interfacesImplemented[interfaceName];
        if (implementationAddress == address(0x0)) revert ImplementationNotFound();
        return implementationAddress;
    }

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationUint256 uint256 of the defined interface.
     */
    function getImplementationUint256(bytes32 interfaceName) external view override returns (uint256) {
        address implementationAddress = interfacesImplemented[interfaceName];
        return uint256(uint160(implementationAddress));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/**
 * @title Stores common interface names used throughout Spire contracts by registration in the ConfigStore.
 */
library ConfigStoreInterfaces {
    // Receives staked treasure from Contest winners and ETH from minting losing entries.
    bytes32 public constant BENEFICIARY = "BENEFICIARY";
    // Creates new Contests
    bytes32 public constant CONTEST_FACTORY = "CONTEST_FACTORY";
    // Creates new ToggleGovernors
    bytes32 public constant TOGGLE_GOVERNOR_FACTORY = "TOGGLE_GOVERNOR_FACTORY";
    // Creates new TEAM
    bytes32 public constant TEAM = "TEAM";
    // Creates new TEAMPERCENT
    bytes32 public constant TEAM_PERCENT = "TEAM_PERCENT";
}

/**
 * @title Global constants used throughout Spire contracts.
 *
 */
library GlobalConstants {
    uint256 public constant GENESIS_TEXT_COUNT = 6;
    uint256 public constant CONTEST_REWARD_AMOUNT = 100;
    uint256 public constant INITIAL_ECHO_COUNT = 5;
    uint256 public constant DEFAULT_CONTEST_MINIMUM_TIME = 7 days;
    uint256 public constant DEFAULT_CONTEST_MINIMUM_APPROVED_ENTRIES = 8;
    uint256 public constant MAX_CHAPTER_COUNT = 100;
    bytes32 public constant SUPER_ADMIN_ROLE = bytes32(keccak256("SPIRE_SUPER_ADMIN"));
    bytes32 public constant MID_ADMIN_ROLE = bytes32(keccak256("SPIRE_MID_ADMIN"));
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { IContestStaker } from "./ContestStaker.sol";
import { IContest } from "./IContest.sol";
import { ConfigStore } from "./ConfigStore.sol";
import { HasConfigStore } from "./HasConfigStore.sol";

// Contest Errors
error HasWinner();
error NoWinner();
error Closed();
error NotClosed();
error EntryNotExists();
error NoStake();
error EntryApproved();
error EntryNotApproved();
error NotEntrant();
error CannotReclaimWinner();
error InvalidMinimumContestTime();
error InvalidApprovedEntryThreshold();

/**
 * @title Contest
 * @notice A Contest lasts for a minimum of 7 days, during which time users can submit entries. The owner can
 * select a winning entry after the 7 days are passed and at least 8 entries have been submitted. The winning entry
 * is minted ERC1155's unique to their entry ID. After 7 days and at least 8 entries have been submitted the contest
 * is closed to new entries.
 * @dev How entries work: In order to submit an entry, a user must stake a designated ERC1155 `stakedContract` in the
 * contest staker contract. By submitting an entry, the user allows this contract to freeze their staked balance
 * in the staker contract until they cancel their entry (or reclaim their losing one). The owner can then approve
 * approve the entry in order for it to be considered for a winning entry and to count towards the
 * "approved entry threshold".
 * @dev What happens to losing entries: Losing entrants can "reclaim" their staked token which instructs this contract
 * to unfreeze their balance in the staker contract. Any user can also can cancel their entry submission if it
 * hasn't been approved as a valid entry yet.
 * @dev What happens to winning entries: The winning entry's staked token is transferred to the beneficiary. The winner
 * is minted a an ERC1155 token with an ID unique to their entry ID.
 */
contract Contest is IContest, HasConfigStore, Ownable, ReentrancyGuard, Multicall {
    // Count of approved entries.
    uint256 public approvedEntries;

    // Timestamp when contest was constructed.
    uint256 public immutable contestStartTime;

    // Conditions that must pass for submission phase to be closed.
    uint256 public immutable minimumContestTime;
    uint256 public immutable approvedEntryThreshold;

    // Counter of submitted entries
    uint256 private _entryId;

    struct Winner {
        uint256 winningId; // entryID of winner
        address winner;
    }

    struct Entry {
        bool isApproved;
        string entryURI;
        address entrant;
        address stakedContract;
        uint256 stakedTokenId;
    }

    Winner public winner;

    mapping(uint256 => Entry) public entries;

    modifier noWinner() {
        if (hasWinner()) {
            revert HasWinner();
        }
        _;
    }

    event SubmittedEntry(
        address indexed stakedContract,
        uint256 indexed stakedTokenId,
        uint256 indexed entryId,
        address entrant,
        string uri
    );
    event AcceptedEntry(uint256 indexed entryId, address indexed entrant);
    event SetWinningEntry(
        uint256 indexed entryId, address winner, address indexed stakedContract, uint256 indexed stakedTokenId
    );
    event CancelledEntry(
        uint256 indexed entryId, address entrant, address indexed stakedContract, uint256 indexed stakedTokenId
    );
    event ReclaimedLosingEntry(
        uint256 indexed entryId, address entrant, address indexed stakedContract, uint256 indexed stakedTokenId
    );

    constructor(
        uint256 _minimumContestTime,
        uint256 _approvedEntryThreshold,
        ConfigStore _configStore
    )
        HasConfigStore(_configStore)
    {
        contestStartTime = block.timestamp;

        if (_minimumContestTime < 600) revert InvalidMinimumContestTime();
        if (_approvedEntryThreshold == 0) revert InvalidApprovedEntryThreshold();
        minimumContestTime = _minimumContestTime;
        approvedEntryThreshold = _approvedEntryThreshold;
    }

    /**
     *
     * Admin functions
     *
     */

    // Once an entry is approved, it cannot be rejected. Skips already approved entries. Entries can't be accepted
    // once a contest is closed but they can be accepted before the contest admin has set a winner.
    function acceptEntries(uint256[] memory entryIds) external override onlyOwner {
        if (isClosed()) revert Closed();
        uint256 newlyAcceptedEntries;
        uint256 len = entryIds.length;
        for (uint32 i; i < len;) {
            if (entries[entryIds[i]].entrant == address(0)) revert EntryNotExists();
            if (!entries[entryIds[i]].isApproved) {
                entries[entryIds[i]].isApproved = true;
                newlyAcceptedEntries++;
                emit AcceptedEntry(entryIds[i], entries[entryIds[i]].entrant);
            }
            unchecked {
                ++i;
            }
        }
        approvedEntries += newlyAcceptedEntries;
    }

    function setWinningEntry(uint256 entryId) external override onlyOwner noWinner nonReentrant {
        if (!isClosed()) revert NotClosed();
        if (entries[entryId].entrant == address(0)) revert EntryNotExists();
        if (!entries[entryId].isApproved) revert EntryNotApproved();
        winner = Winner(entryId, entries[entryId].entrant);

        // Burn staked token.
        IContestStaker(address(_getContestFactory())).transferFrozenStake(
            entries[entryId].stakedContract,
            entries[entryId].stakedTokenId,
            entries[entryId].entrant,
            _getContestFactory().getSpireContract(),
            1
        );
        emit SetWinningEntry(
            entryId, entries[entryId].entrant, entries[entryId].stakedContract, entries[entryId].stakedTokenId
        );
    }

    /**
     *
     * User functions
     *
     */

    // User can choose which Treasure ID `stakedTokenId` to use as their stake provided it os registered in the
    // ContestStaker. The caller must have staked in the contestStaker contract and this function will freeze
    // their balance from being withdrawn in that contract, until the user has either cancelled their
    // unapproved entry or reclaimed their losing entry.
    function submitEntry(
        address stakedContract,
        uint256 stakedTokenId,
        string memory entryURI
    )
        external
        returns (uint256)
    {
        if (isClosed()) revert Closed();
        if (!IContestStaker(address(_getContestFactory())).canUseStake(stakedContract, stakedTokenId, msg.sender)) {
            revert NoStake();
        }
        entries[_entryId] = Entry(false, entryURI, msg.sender, stakedContract, stakedTokenId);
        IContestStaker(address(_getContestFactory())).freezeStake(stakedContract, stakedTokenId, msg.sender, 1);
        emit SubmittedEntry(stakedContract, stakedTokenId, _entryId, msg.sender, entryURI);
        return _entryId++;
    }

    // Can be called as long as an entry is not approved. Unfreezes their stake in contestStaker so user can
    // withdraw. Caller must be entrant.
    function cancelEntry(uint256 entryId) external {
        if (entries[entryId].entrant != msg.sender) revert NotEntrant();
        if (entries[entryId].isApproved) revert EntryApproved();
        address stakedContract = entries[entryId].stakedContract;
        uint256 stakedTokenId = entries[entryId].stakedTokenId;
        delete entries[entryId];
        IContestStaker(address(_getContestFactory())).unfreezeStake(stakedContract, stakedTokenId, msg.sender, 1);
        emit CancelledEntry(entryId, msg.sender, stakedContract, stakedTokenId);
    }

    // When a winner is selected in a contest, all losing entries, except for the winner's entries, will be reclaim
    // their stakes.
    function reclaimEntry(uint256 entryId) external override onlyOwner nonReentrant {
        if (!hasWinner()) revert NoWinner();
        if (entryId == winner.winningId) revert CannotReclaimWinner();
        if (entries[entryId].entrant == address(0)) revert EntryNotExists();
        if (!entries[entryId].isApproved) revert EntryNotApproved();
        address stakedContract = entries[entryId].stakedContract;
        uint256 stakedTokenId = entries[entryId].stakedTokenId;
        IContestStaker(address(_getContestFactory())).unfreezeStake(
            stakedContract, stakedTokenId, entries[entryId].entrant, 1
        );
        emit ReclaimedLosingEntry(entryId, entries[entryId].entrant, stakedContract, stakedTokenId);

        // Don't delete entry as it might be able to be minted again as a losing entry.
    }

    function hasWinner() public view override returns (bool) {
        return winner.winner != address(0);
    }

    function getWinner() external view override returns (address) {
        return winner.winner;
    }

    function getWinningId() external view override returns (uint256) {
        return winner.winningId;
    }

    function getEntrant(uint256 entryId) external view override returns (address) {
        return entries[entryId].entrant;
    }

    // No more entries can be submitted after this threshold is reached. Since approvedEntryThreshold and
    // contest time elapsed are only increasing, once this is true it can reset to false (i.e. this should return
    // false until its true and then always true).
    function isClosed() public view override returns (bool) {
        //slither-disable-next-line timestamp
        return approvedEntries >= approvedEntryThreshold && block.timestamp - contestStartTime >= minimumContestTime;
    }

    function getEntryURI(uint256 entryId) external view override returns (string memory) {
        return entries[entryId].entryURI;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ConfigStore } from "./ConfigStore.sol";
import { Contest } from "./Contest.sol";
import { ContestStaker } from "./ContestStaker.sol";
import { ISpire } from "./ISpire.sol";

// Deploys new Contests and transfers ownership of them to the deployer. Also registers the contract with a
// contest staker contract so that the contests can freeze and unfreeze user stakes. This contract deploys the
// contest staker upon construction so this contract owns the staker contract.

error InvalidSpireAddress();

interface IContestFactory {
    function deployNewContest(
        uint256 minimumContestTime,
        uint256 approvedEntryThreshold,
        ConfigStore _configStore
    )
        external
        returns (address);
    function addStakeableTokenId(address stakedContract, uint256 tokenId) external;
    function removeStakedContract(address stakedContract) external;
    function removeStakeableTokenId(address stakedContract, uint256 tokenId) external;
    function getSpireContract() external view returns (address);
}

contract ContestFactory is IContestFactory, ContestStaker {
    address private _spire;

    modifier onlyContract() {
        ISpire(_spire).checkContractRole(msg.sender);
        _;
    }

    event SetSpireAddress(address indexed spireAddress);

    constructor(
        address spire,
        address _stakedContract,
        uint256[] memory _stakeableTokenIds
    )
        ContestStaker(_stakedContract, _stakeableTokenIds) // solhint-disable-next-line no-empty-blocks
    {
        if (spire == address(0)) revert InvalidSpireAddress();
        _spire = spire;
        emit SetSpireAddress(_spire);
    }

    function getSpireContract() external view returns (address) {
        return _spire;
    }

    function addStakeableTokenId(address stakedContract, uint256 tokenId) external override onlyContract {
        _addStakeableTokenId(stakedContract, tokenId);
    }

    function removeStakedContract(address stakedContract) external override onlyContract {
        _removeStakedContract(stakedContract);
    }

    function removeStakeableTokenId(address stakedContract, uint256 tokenId) external override onlyContract {
        _removeStakeableTokenId(stakedContract, tokenId);
    }

    // Anyone can call this function to deploy a new Contest that sets the caller as the owner of the new Contest.
    // This should be called by the Spire contract but there is no harm if anyone calls it.
    function deployNewContest(
        uint256 minimumContestTime,
        uint256 approvedEntryThreshold,
        ConfigStore _configStore
    )
        external
        override
        returns (address)
    {
        address contest = address(new Contest(minimumContestTime, approvedEntryThreshold, _configStore));
        _registerContest(address(contest));
        Ownable(contest).transferOwnership(msg.sender);
        return address(contest);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Anyone can stake a designated ERC1155 token into this contract, and they can choose which token ID to stake
// provided the ID is whitelisted (see the private stakeableTokenIds set). This contract provides internal methods that
// another contract can use to append to the stakeable token ID set and register contests, which can freeze and
// unfreeze user's stakes. The idea is that the contests can freeze a user's stake if they submit an entry,
// and unfreeze it if they withdraw their entry. The contests can also transfer a user's frozen stake,
// which could be used to take a winner's stake for example. The advantage of this design is that a user's stake
// can be re-used for multiple contests and they only need to interface with this staking contract, instead of
// approving and staking per contest entered.

error UnregisteredContest();
error AddToSetFailed();
error StakedContractNotExists();
error TokenIdNotExists();
error InvalidStakedContract();
error InvalidTokenId();
error InvalidInputAmount();
error InsufficientStake(uint256 usableStake, uint256 requestedStake);
error InsufficientFrozenStake(uint256 frozenStake, uint256 requestedStake);
error InitialSettingStakeableTokenIdFailed();

interface IContestStaker {
    function freezeStake(address stakedContract, uint256 tokenId, address staker, uint256 amount) external;
    function unfreezeStake(address stakedContract, uint256 tokenId, address staker, uint256 amount) external;
    function transferFrozenStake(
        address stakedContract,
        uint256 tokenId,
        address staker,
        address recipient,
        uint256 amount
    )
        external;
    function canUseStake(address stakedContract, uint256 tokenId, address staker) external view returns (bool);
}

contract ContestStaker is IContestStaker, ERC1155Holder, ReentrancyGuard, Multicall {
    using EnumerableSet for EnumerableSet.UintSet;

    // Whitelisted token IDs that can be staked. This set is append-only to eliminate situation where a user has
    // staked a token ID that is no longer whitelisted.
    mapping(address => bool) public stakedContracts;
    mapping(address => EnumerableSet.UintSet) private stakeableTokenIds;

    // contract address => tokenId => staker => stake amount.
    mapping(address => mapping(uint256 => mapping(address => uint256))) public stakes;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public frozenStakes;

    // Contests can put a hold on a user's stake.
    mapping(address => bool) public contests;

    modifier onlyContest() {
        if (!contests[msg.sender]) revert UnregisteredContest();
        _;
    }

    event Staked(address indexed stakedContract, uint256 indexed tokenId, uint256 amount, address indexed staker);
    event Unstaked(address indexed stakedContract, uint256 indexed tokenId, uint256 amount, address indexed staker);
    event AddedTokenId(address indexed stakedContract, uint256 indexed tokenId);
    event RemovedStakedContract(address indexed stakedContract);
    event RemovedTokenId(address indexed stakedContract, uint256 indexed tokenId);
    event FreezeStake(address indexed stakedContract, uint256 indexed tokenId, address indexed staker, uint256 amount);
    event UnfreezeStake(
        address indexed stakedContract, uint256 indexed tokenId, address indexed staker, uint256 amount
    );
    event TransferFrozenStake(
        address indexed stakedContract,
        uint256 indexed tokenId,
        address indexed staker,
        address recipient,
        uint256 amount
    );

    // @dev This will revert if `_stakeableTokenIds` contains duplicate ID's or ones that otherwise fail to add to the
    // stakeableTokenIds set.
    constructor(address _stakedContract, uint256[] memory _stakeableTokenIds) {
        stakedContracts[_stakedContract] = true;
        uint256 len = _stakeableTokenIds.length;
        for (uint256 i; i < len;) {
            if (!stakeableTokenIds[_stakedContract].add(_stakeableTokenIds[i])) {
                revert InitialSettingStakeableTokenIdFailed();
            }
            emit AddedTokenId(_stakedContract, _stakeableTokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     *
     * Contest functions: Can only be called by whitelisted contest contract.
     *
     */

    // Invariant: stake amount should always be >= frozen stake amount.
    /**
     * @notice Freeze 1 stake of user
     */
    function freezeStake(
        address stakedContract,
        uint256 tokenId,
        address staker,
        uint256 amount
    )
        external
        override
        onlyContest
    {
        if (!stakedContracts[stakedContract]) revert InvalidStakedContract();
        if (!stakeableTokenIds[stakedContract].contains(tokenId)) revert InvalidTokenId();
        if (getUsableStake(stakedContract, tokenId, staker) < amount) {
            revert InsufficientStake(getUsableStake(stakedContract, tokenId, staker), amount);
        }
        frozenStakes[stakedContract][tokenId][staker] += amount;
        emit FreezeStake(stakedContract, tokenId, staker, amount);
    }

    function unfreezeStake(
        address stakedContract,
        uint256 tokenId,
        address staker,
        uint256 amount
    )
        external
        override
        onlyContest
    {
        if (frozenStakes[stakedContract][tokenId][staker] < amount) {
            revert InsufficientFrozenStake(frozenStakes[stakedContract][tokenId][staker], amount);
        }
        frozenStakes[stakedContract][tokenId][staker] -= amount;
        emit UnfreezeStake(stakedContract, tokenId, staker, amount);
    }

    // Only stake frozen by contest can be transferred away to recipient. Decrements both stakes
    // and frozen stakes amount of user.
    function transferFrozenStake(
        address stakedContract,
        uint256 tokenId,
        address staker,
        address recipient,
        uint256 amount
    )
        external
        override
        onlyContest
        nonReentrant
    {
        if (frozenStakes[stakedContract][tokenId][staker] < amount) {
            revert InsufficientFrozenStake(frozenStakes[stakedContract][tokenId][staker], amount);
        }
        stakes[stakedContract][tokenId][staker] -= amount;
        frozenStakes[stakedContract][tokenId][staker] -= amount;
        IERC1155(address(stakedContract)).safeTransferFrom(address(this), recipient, tokenId, amount, "");
        emit TransferFrozenStake(stakedContract, tokenId, staker, recipient, amount);
    }

    /**
     *
     * Public functions.
     *
     */

    /**
     * @notice Increase stake amount. Cannot send any staked amount that was frozen by a contest.
     * @dev Caller must approve this contract to transfer the token ID.
     */
    function stake(address stakedContract, uint256 tokenId, uint256 amount) external nonReentrant {
        if (!stakedContracts[stakedContract]) revert InvalidStakedContract();
        if (!stakeableTokenIds[stakedContract].contains(tokenId)) revert InvalidTokenId();
        if (amount == 0) revert InvalidInputAmount();
        stakes[stakedContract][tokenId][msg.sender] += amount;
        IERC1155(address(stakedContract)).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Staked(stakedContract, tokenId, amount, msg.sender);
    }

    /**
     * @notice Send stake back to user. Cannot send any staked amount that was frozen by a contest.
     */
    function unstake(address stakedContract, uint256 tokenId, uint256 amount) external nonReentrant {
        if (getUsableStake(stakedContract, tokenId, msg.sender) < amount) {
            revert InsufficientStake(getUsableStake(stakedContract, tokenId, msg.sender), amount);
        }
        if (amount == 0) revert InvalidInputAmount();
        stakes[stakedContract][tokenId][msg.sender] -= amount;
        IERC1155(address(stakedContract)).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        emit Unstaked(stakedContract, tokenId, amount, msg.sender);
    }

    /**
     *
     * View functions
     *
     */
    function getStakeableTokenIds(address stakedContract) public view returns (uint256[] memory) {
        return stakeableTokenIds[stakedContract].values();
    }

    // This could theoretically run out of gas if token ID count is very high.
    // Returns stake amount for user for each token ID returned by `getStakeableTokenIds`. Returns in same order
    // as `getStakeableTokenIds` so caller should be sure to merge on indices.
    function getStakeAmountsForUser(address stakedContract, address user) external view returns (uint256[] memory) {
        uint256[] memory allTokenIds = getStakeableTokenIds(stakedContract);
        uint256 len = allTokenIds.length;
        for (uint256 i; i < len;) {
            allTokenIds[i] = getUsableStake(stakedContract, allTokenIds[i], user);
            unchecked {
                ++i;
            }
        }
        return allTokenIds;
    }

    function getUsableStake(address stakedContract, uint256 tokenId, address staker) public view returns (uint256) {
        return stakes[stakedContract][tokenId][staker] - frozenStakes[stakedContract][tokenId][staker];
    }

    function canUseStake(
        address stakedContract,
        uint256 tokenId,
        address staker
    )
        external
        view
        override
        returns (bool)
    {
        return getUsableStake(stakedContract, tokenId, staker) > 0;
    }

    function isStakedContract(address stakedContract) external view returns (bool) {
        return stakedContracts[stakedContract];
    }
    /**
     *
     * Internal functions
     *
     */

    // Register a contest that can freeze and unfreeze stakes.
    function _registerContest(address contest) internal {
        contests[contest] = true;
    }

    // Add a token ID that can be staked.
    function _addStakeableTokenId(address stakedContract, uint256 tokenId) internal {
        stakedContracts[stakedContract] = true;
        bool success = stakeableTokenIds[stakedContract].add(tokenId);
        if (!success) revert AddToSetFailed();
        emit AddedTokenId(stakedContract, tokenId);
    }

    // Remove a staked contract.
    function _removeStakedContract(address stakedContract) internal {
        if (!stakedContracts[stakedContract]) revert StakedContractNotExists();
        stakedContracts[stakedContract] = false;
        uint256[] memory tokenIds = stakeableTokenIds[stakedContract].values();
        uint256 len = tokenIds.length;
        for (uint256 i; i < len;) {
            stakeableTokenIds[stakedContract].remove(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        emit RemovedStakedContract(stakedContract);
    }

    // Remove a token ID that can be staked.
    function _removeStakeableTokenId(address stakedContract, uint256 tokenId) internal {
        if (!stakedContracts[stakedContract] || !stakeableTokenIds[stakedContract].contains(tokenId)) {
            revert TokenIdNotExists();
        }
        stakeableTokenIds[stakedContract].remove(tokenId);
        emit RemovedTokenId(stakedContract, tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ERC1155Supply, ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { IContest } from "./IContest.sol";
import { GlobalConstants } from "./Constants.sol";
import { ConfigStore } from "./ConfigStore.sol";
import { HasConfigStore } from "./HasConfigStore.sol";

// Echoes is designed to be extended by the GenesisText contract to give it access to a set of Echo contests that
// are unique to each chapter ID and Genesis Text ID. This contract provides helper functions to set Echo contest
// winner, create new contests, and approve entries for contests. The Spire contract needs to know when to move
// on to the next Chapter and Echo contest and it therefore must know when echo contests are closed for a given
// chapter. They are considered closed when *all* echo contests for a chapter are closed, so this contract provides
// helper functions to read the state of all echo contests for a given chapter.
error InitialEchoContestsDoNotHaveWinner();
error InvalidAdditionalEchoContestCount();
error AlreadyIntializedEchoes();

contract Echoes is HasConfigStore, ERC1155Supply {
    // Keeps track of ERC1155 Token Id
    // Changes for each subsequent contest
    uint256 public nextContestWinnerId;

    // SPIR-160 Changes
    // tokenId -> uri
    mapping(uint256 => string) public contestURI;

    // Mapping of Genesis Text ID to Chapter ID to Echo contest identified by unique ID.
    mapping(uint256 => mapping(uint256 => mapping(uint256 => address))) public chapterEchoes;
    mapping(uint256 => mapping(uint256 => uint256)) public echoCount;

    event CreatedEchoContest(
        uint256 genesisTextId,
        uint256 indexed chapterId,
        uint256 indexed echoId,
        uint256 minimumContestTime,
        uint256 approvedEntryThreshold,
        address indexed echoContestAddress
    );

    event SetEchoContestWinner(
        uint256 indexed genesisTextId,
        uint256 indexed chapterId,
        uint256 echoId,
        uint256 indexed winningId,
        address winner,
        uint256 contestWinnerTokenId
    );

    event MintContestReward(uint256 indexed contestRewardTokenId, address indexed recipient, uint256 indexed amount);

    constructor(ConfigStore _configStore, string memory _uri) HasConfigStore(_configStore) ERC1155(_uri) {
        // solhint-disable-previous-line no-empty-blocks
    }

    // Don't call uri(), it will return the default URI
    // Call this function by passing the specific tokenId
    function _getURI(uint256 tokenId) internal view returns (string memory) {
        return contestURI[tokenId];
    }

    // Internal function given admin accessibility in parent contracts
    function _setURI(uint256 tokenId, string memory uri) internal {
        contestURI[tokenId] = uri;
        emit URI(uri, tokenId);
    }

    function _mintContestWinner(address winner, bool toBeneficiary) internal returns (uint256 contestRewardTokenId) {
        contestRewardTokenId = nextContestWinnerId++;
        uint256 _teamCount = GlobalConstants.CONTEST_REWARD_AMOUNT * _getTeamPercent() / (100);
        if (toBeneficiary) {
            _mint(_getBeneficiary(), contestRewardTokenId, GlobalConstants.CONTEST_REWARD_AMOUNT - _teamCount, "");
        } else {
            _mint(winner, contestRewardTokenId, GlobalConstants.CONTEST_REWARD_AMOUNT - _teamCount, "");
        }
        _mint(_getTeamWallet(), contestRewardTokenId, _teamCount, "");
        emit MintContestReward(contestRewardTokenId, winner, GlobalConstants.CONTEST_REWARD_AMOUNT - _teamCount);
    }

    // Internal function only for token minted of genensis text.
    function _mintContestWinnerBatch(address winner, uint256 count) internal {
        uint256 contestRewardTokenId = nextContestWinnerId;
        for (uint256 i; i < count;) {
            _mint(winner, contestRewardTokenId + i, GlobalConstants.CONTEST_REWARD_AMOUNT, "");
            emit MintContestReward(contestRewardTokenId + i, winner, GlobalConstants.CONTEST_REWARD_AMOUNT);
            unchecked {
                ++i;
            }
        }
        nextContestWinnerId += count;
    }

    // Create `contestCount` new Echo contests. This method will only succeed once and create INITIAL_ECHO_COUNT
    // echoes at once.
    function _createInitialEchoContests(
        uint256 genesisTextId,
        uint256 chapterId,
        uint256 minimumContestTime,
        uint256 approvedEntryThreshold
    )
        internal
    {
        if (echoCount[genesisTextId][chapterId] != 0) revert AlreadyIntializedEchoes();
        for (uint256 i; i < GlobalConstants.INITIAL_ECHO_COUNT;) {
            _createEchoContest(genesisTextId, chapterId, minimumContestTime, approvedEntryThreshold);
            unchecked {
                ++i;
            }
        }
    }

    // Approve entryIds for echo ID.
    function _approveEchoContestEntries(
        uint256 genesisTextId,
        uint256 chapterId,
        uint256 echoId,
        uint256[] memory entryIds
    )
        internal
    {
        IContest(chapterEchoes[genesisTextId][chapterId][echoId]).acceptEntries(entryIds);
    }

    function _createEchoContest(
        uint256 genesisTextId,
        uint256 chapterId,
        uint256 minimumContestTime,
        uint256 approvedEntryThreshold
    )
        private
    {
        uint256 nextEchoId = echoCount[genesisTextId][chapterId];
        echoCount[genesisTextId][chapterId]++;
        address echoContestAddress =
            _getContestFactory().deployNewContest(minimumContestTime, approvedEntryThreshold, configStore);
        chapterEchoes[genesisTextId][chapterId][nextEchoId] = echoContestAddress;
        emit CreatedEchoContest(
            genesisTextId, chapterId, nextEchoId, minimumContestTime, approvedEntryThreshold, echoContestAddress
        );
    }

    // This can be used to set winner of echo contests.
    function _setEchoContestWinner(
        uint256 genesisTextId,
        uint256 chapterId,
        uint256 contestId,
        uint256 entryId,
        uint256[] memory losingEntryIds,
        bool toBeneficiary
    )
        internal
    {
        IContest echoContest = IContest(chapterEchoes[genesisTextId][chapterId][contestId]);
        if (echoContest.hasWinner() || !echoContest.isClosed()) return;
        echoContest.setWinningEntry(entryId);
        address winner = echoContest.getWinner();
        uint256 contestWinnerTokenId = _mintContestWinner(winner, toBeneficiary);
        _setURI(contestWinnerTokenId, echoContest.getEntryURI(entryId));
        uint256 len = losingEntryIds.length;
        for (uint256 i; i < len;) {
            echoContest.reclaimEntry(losingEntryIds[i]);
            unchecked {
                ++i;
            }
        }
        emit SetEchoContestWinner(genesisTextId, chapterId, contestId, entryId, winner, contestWinnerTokenId);
    }

    function _initialEchoContestsClosed(uint256 genesisTextId, uint256 chapterId) internal view returns (bool) {
        for (uint256 i; i < GlobalConstants.INITIAL_ECHO_COUNT;) {
            if (!IContest(chapterEchoes[genesisTextId][chapterId][i]).isClosed()) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _initialEchoContestsHaveWinner(uint256 genesisTextId, uint256 chapterId) internal view returns (bool) {
        if (chapterEchoes[genesisTextId][chapterId][0] == address(0)) {
            return false;
        }

        for (uint256 i; i < GlobalConstants.INITIAL_ECHO_COUNT;) {
            if (!IContest(chapterEchoes[genesisTextId][chapterId][i]).hasWinner()) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IContest } from "./IContest.sol";
import { GlobalConstants } from "./Constants.sol";
import { ConfigStore } from "./ConfigStore.sol";
import { Echoes } from "./Echoes.sol";

error ChapterContestNotCreated();
error GenesisEchoContestsDoNotHaveWinner();
error GenesisEchoContestsNotCreated();
error ChapterContestDoesNotHaveWinner();
error PreviousEchoContestsDoNotHaveWinner();
error PreviousChapterContestDoesNotHaveWinner();
error ChapterIdDoesNotExist();

// Genesis texts store a list of chapters which can be mapped to echo contests. This contract keeps track of the latest
// chapter and echo contest that can be opened by the Spire admin. This contract should own
// all of the Echoes contracts in the Spire, so that the admin has to go through this contract to create new echo
// contests, set winner, and approve entries. Similarly, this contract should own all chapter contests.
// The Spire contract should own the Genesis Text contract.
contract GenesisText is Echoes {
    mapping(uint256 => uint256) public nextChapterId;
    mapping(uint256 => uint256) public nextEchoChapterId;

    // The list of Chapters for this Genesis Text. Each Chapter can be mapped to a list of Echo Contests. Each Chapter
    // is also a Contest.
    mapping(uint256 => mapping(uint256 => address)) internal chapterContests;

    event CreatedNextEchoContest(uint256 indexed genesisTextId, uint256 indexed chapterId);
    event CreatedNextChapterContest(
        address indexed nextChapterAddress, uint256 indexed genesisTextId, uint256 indexed chapterId
    );
    event SetChapterContestWinner(
        uint256 indexed genesisTextId,
        uint256 indexed chapterId,
        uint256 indexed winningId,
        address winner,
        uint256 contestWinnerTokenId
    );

    // solhint-disable-next-line no-empty-blocks
    constructor(ConfigStore _configStore, string memory _uri) Echoes(_configStore, _uri) { }

    // This function should be called by Spire when it wants to open a new chapter contest for the genesis text ID.
    function _createNextChapterContest(uint256 genesisTextId) internal {
        // If this is the first chapter contest, then we need to check that the genesis echo contests have set winner.
        if (nextChapterId[genesisTextId] == 0) {
            if (nextEchoChapterId[genesisTextId] == 0) revert GenesisEchoContestsNotCreated();
            if (!_initialEchoContestsHaveWinner(genesisTextId, 0)) revert GenesisEchoContestsDoNotHaveWinner();
        }
        // Otherwise check that the previous chapter's echo contests have winner and that the previous chapter
        // has set a winner.
        else {
            if (!IContest(chapterContests[genesisTextId][nextChapterId[genesisTextId] - 1]).hasWinner()) {
                revert PreviousChapterContestDoesNotHaveWinner();
            }
            if (!_initialEchoContestsHaveWinner(genesisTextId, nextChapterId[genesisTextId])) {
                revert PreviousEchoContestsDoNotHaveWinner();
            }
        }
        uint256 newChapterId = nextChapterId[genesisTextId]++;
        address nextChapterContestAddress = _getContestFactory().deployNewContest(
            GlobalConstants.DEFAULT_CONTEST_MINIMUM_TIME,
            GlobalConstants.DEFAULT_CONTEST_MINIMUM_APPROVED_ENTRIES,
            configStore
        );

        chapterContests[genesisTextId][newChapterId] = nextChapterContestAddress;
        emit CreatedNextChapterContest(nextChapterContestAddress, genesisTextId, newChapterId);
    }

    // This function should be called by Spire when it wants to open a new echoes contest for the genesis text ID.
    function _createNextEchoContests(uint256 genesisTextId) internal {
        // If nextEchoChapterId is 0 then there is a special case where we don't need the chapter contest 0
        // to have closed to create echo contests for the chapter. This is because there is no contest for the first
        // chapter. These echoes are essentially the echoes for the genesis text itself.
        uint256 _nextEchoChapterId = nextEchoChapterId[genesisTextId];
        if (_nextEchoChapterId == 0) {
            nextEchoChapterId[genesisTextId]++;
            emit CreatedNextEchoContest(genesisTextId, _nextEchoChapterId);
            _createInitialEchoContests(
                genesisTextId,
                _nextEchoChapterId,
                GlobalConstants.DEFAULT_CONTEST_MINIMUM_TIME,
                GlobalConstants.DEFAULT_CONTEST_MINIMUM_APPROVED_ENTRIES
            );
        } else {
            // If the next echo chapter ID > 0, then the genesis echoes have been created and we need to now check
            // the next echo chapter ID - 1 (i.e. the "latest echo ID") to see its contest status before proceeding
            // to create new contests.
            uint256 latestEchoId = _latestEchoChapterId(genesisTextId);
            nextEchoChapterId[genesisTextId]++;
            // The chapter contest should be created and must have set a winner before we can open its echoes.
            if (!_hasCreatedChapterContest(genesisTextId, latestEchoId)) {
                revert ChapterContestNotCreated();
            }
            if (!IContest(chapterContests[genesisTextId][latestEchoId]).hasWinner()) {
                revert ChapterContestDoesNotHaveWinner();
            }

            // Link chapter contest with this echo contest.
            // Note: echo contests are 1 ahead of the chapter contest because the genesis echo has the ID 0
            // while the first chapter has ID 1. So to create a new echo we need to create it at the ID + 1.
            emit CreatedNextEchoContest(genesisTextId, latestEchoId + 1);
            _createInitialEchoContests(
                genesisTextId,
                latestEchoId + 1,
                GlobalConstants.DEFAULT_CONTEST_MINIMUM_TIME,
                GlobalConstants.DEFAULT_CONTEST_MINIMUM_APPROVED_ENTRIES
            );
        }
    }

    function _setChapterContestWinner(
        uint256 genesisTextId,
        uint256 chapterId,
        uint256 winnerId,
        uint256[] memory losingEntryIds,
        bool toBeneficiary
    )
        internal
    {
        if (chapterId >= nextChapterId[genesisTextId]) revert ChapterIdDoesNotExist();
        IContest contest = IContest(chapterContests[genesisTextId][chapterId]);
        contest.setWinningEntry(winnerId);
        address winner = contest.getWinner();
        uint256 contestWinnerTokenId = _mintContestWinner(winner, toBeneficiary);
        _setURI(contestWinnerTokenId, contest.getEntryURI(winnerId));
        uint256 len = losingEntryIds.length;
        for (uint256 i; i < len;) {
            contest.reclaimEntry(losingEntryIds[i]);
            unchecked {
                ++i;
            }
        }

        emit SetChapterContestWinner(genesisTextId, chapterId, winnerId, winner, contestWinnerTokenId);
    }

    function _canCloseLatestChapterContest(uint256 genesisTextId) internal view returns (bool) {
        return IContest(chapterContests[genesisTextId][_latestChapterId(genesisTextId)]).isClosed();
    }

    function _hasCreatedChapterContest(uint256 genesisTextId, uint256 chapterId) internal view returns (bool) {
        return chapterContests[genesisTextId][chapterId] != address(0);
    }

    function _latestChapterId(uint256 genesisTextId) internal view returns (uint256) {
        return nextChapterId[genesisTextId] - 1;
    }

    function _latestEchoChapterId(uint256 genesisTextId) internal view returns (uint256) {
        return nextEchoChapterId[genesisTextId] - 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import { ConfigStore } from "./ConfigStore.sol";
import { ConfigStoreInterfaces } from "./Constants.sol";
import { IContestFactory } from "./ContestFactory.sol";
import { ToggleGovernanceFactory } from "./ToggleGovernanceFactory.sol";

contract HasConfigStore {
    ConfigStore public immutable configStore;

    constructor(ConfigStore _configStore) {
        configStore = _configStore;
    }

    function _getContestFactory() internal view returns (IContestFactory) {
        return IContestFactory(configStore.getImplementationAddress(ConfigStoreInterfaces.CONTEST_FACTORY));
    }

    function _getToggleGovernorFactory() internal view returns (ToggleGovernanceFactory) {
        return // solhint-disable-next-line max-line-length
            ToggleGovernanceFactory(configStore.getImplementationAddress(ConfigStoreInterfaces.TOGGLE_GOVERNOR_FACTORY));
    }

    function _getBeneficiary() internal view returns (address) {
        return configStore.getImplementationAddress(ConfigStoreInterfaces.BENEFICIARY);
    }

    function _getTeamWallet() internal view returns (address) {
        return configStore.getImplementationAddress(ConfigStoreInterfaces.TEAM);
    }

    function _getTeamPercent() internal view returns (uint256) {
        return configStore.getImplementationUint256(ConfigStoreInterfaces.TEAM_PERCENT);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IContest {
    function acceptEntries(uint256[] memory entryIds) external;
    function setWinningEntry(uint256 entryId) external;
    function isClosed() external view returns (bool);
    function hasWinner() external view returns (bool);
    function getWinner() external view returns (address);
    function getWinningId() external view returns (uint256);
    function getEntrant(uint256 entryId) external view returns (address);
    function reclaimEntry(uint256 entryId) external;
    function getEntryURI(uint256 entryId) external returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Supply is IERC1155 {
    function totalSupply(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ISpire {
    function checkContractRole(address sender) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import { ERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { AccessControl } from "./AccessControl.sol";
import { IToggleGovernance } from "./ToggleGovernance.sol";
import { IERC1155Supply } from "./IERC1155Supply.sol";
import { ConfigStore } from "./ConfigStore.sol";
import { GenesisText } from "./GenesisText.sol";
import { GlobalConstants } from "./Constants.sol";
import { ISpire } from "./ISpire.sol";
import { IContest } from "./Contest.sol";

error NotBeneficiary();
error InvalidGenesisTextIdSetEchoContestWinner();
error MustSetPreviousEchoContestWinner();
error CannotAdvanceEchoFlow();
error ChapterFlowInitialized();
error InvalidGenesisTextIdSetChapterContestWinner();
error MustSetPreviousChapterContestWinner();
error CannotAdvanceChapterFlow();
error AllGenesisTextsSkipped();
error InvalidAdditionalEchoContestId();

// Maintains the flow of Chapter and Echo Contests. Mints Genesis text tokens to deployer.
// This contract should be the only entrypoint for the Owner to:
// - Set Chapter and Echo contest winner
// - Approve Chapter and Echo contest entries
// Upon approving the latest contest entries, the next contests can open up.

// Losing entrants in Chapter Contests: Tokens unique to losing entry ID's can be minted for a price set by the
// beneficiary. This is only possible if the beneficiary decides to set a losing mint price for the chapter and
// genesis text.
contract Spire is ISpire, GenesisText, ERC1155Holder, AccessControl, Ownable, ReentrancyGuard, Multicall {
    enum Flow {
        Echo,
        Chapter
    }

    string public name = "SPIRE";
    string public symbol = "SPIRE";

    // Track the ID's of the Genesis Texts whose Chapter/Echo Contests are currently open for submissions.
    // The chapter and echo contests take place in parallel, so we need two sets of tracking variables. This is
    // why we are labeling the t..rackers as "FlowId's" because they track the genesis text ID that the chapter/echo
    // flow is on. The flows are circular, going from ID 0 --> GENESIS_TEXT_COUNT - 1 --> 0 --> etc.
    // Specifically, the counters are used so that we know when we can open new contests when the
    // following conditions are met:
    // - when the current contest can select a winner
    // - when the previous contest has selected a winner

    uint256 public currentChapterFlowId;
    uint256 public previousChapterFlowId;
    uint256 public currentEchoFlowId;
    uint256 public previousEchoFlowId;

    // Governor contracts for each genesis text. These are used to govern whether to skip a genesis text.
    mapping(uint256 => address) public genesisGovernors;

    // If initiated
    bool private _initiatedSpire;
    bool private _initializeChapterFlow;

    event AdvancedEchoFlow(uint256 indexed previousEchoFlowId, uint256 indexed currentEchoFlowId);
    event AdvancedChapterFlow(uint256 indexed previousChapterFlowId, uint256 indexed currentChapterFlowId);

    // Deployer can pass in address of ConfigStore so that they can re-use factories amongst Spire contracts.
    // This is a UX enhancement as it allows users to re-use stake for contests for different Spire contracts.
    // @dev: If the ContestFactory changes in the ConfigStore, then users will have to migrate their stake. The
    // ContestFactory owner should be sure that that stakeable token ID's are carried over between ContestFactories.
    constructor(ConfigStore _configStore) GenesisText(_configStore, "GENESIS_TEXT_URI") {
        // Mint genesis text tokens to deployer.

        // Slither complains that the external call `deployNewToggleGovernor` is made inside the following loop,
        // which we choose to ignore. We could have made ToggleGovernanceFactory an internal library but that would
        // increase this contract's bytecode size, which we are willing to live with in exchange for more gas when
        // deploying this contract. Since these calls take place in the constructor we are OK living with the tradeoff.

        // slither-disable-start calls-loop
        for (uint256 i; i < GlobalConstants.GENESIS_TEXT_COUNT;) {
            // The genesis text tokens are used to govern whether to skip a genesis text.
            genesisGovernors[i] = _getToggleGovernorFactory().deployNewToggleGovernor(IERC1155Supply(address(this)), i);
            unchecked {
                ++i;
            }
        }
        //slither-disable-end calls-loop
    }

    function init() external onlyOwner nonReentrant {
        require(!_initiatedSpire, "already initiated Spire");
        _mintContestWinnerBatch(msg.sender, GlobalConstants.GENESIS_TEXT_COUNT);

        // Begin echo 0 contests for genesis text 0.
        _createNextEchoContests(0);

        // Gives msg.sender aka Owner the SUPER_ADMIN_ROLE
        _setupRole(GlobalConstants.SUPER_ADMIN_ROLE, msg.sender);

        // SpireSuperAdmin is Also MID_ADMIN_ROLE
        _setupRole(GlobalConstants.MID_ADMIN_ROLE, msg.sender);

        // SpireSuperAdmin is "admin" for MID_ADMIN_ROLE
        _setRoleAdmin(GlobalConstants.MID_ADMIN_ROLE, GlobalConstants.SUPER_ADMIN_ROLE);

        _initiatedSpire = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // To be called after contract deployment by the owner
    function grantRoles(address[] memory _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        for (uint256 i; i < len;) {
            _grantRole(GlobalConstants.MID_ADMIN_ROLE, _addresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdrawRoles(address[] memory _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        for (uint256 i; i < len;) {
            _revokeRole(GlobalConstants.MID_ADMIN_ROLE, _addresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    // allows the super admin to revoke their own access
    function setAdminContractAccess(bool access) external onlyOwner {
        _setAdminContractAccess(access);
    }

    // allows the super admin to revoke team access
    function setTeamContractAccess(bool access) external onlyOwner {
        _setTeamContractAccess(access);
    }

    function checkContractRole(address account) external view override {
        _checkContractRole(account);
    }

    function setURI(uint256 tokenId, string calldata _uri) external onlyRole(GlobalConstants.MID_ADMIN_ROLE) {
        _setURI(tokenId, _uri);
    }

    function getURI(uint256 tokenId) external view returns (string memory) {
        return _getURI(tokenId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _getURI(tokenId);
    }

    // Will revert unless winningIds.length == initial echo count. Will set winner for echo contests that are closed.
    // This will not revert if no new winner are set.
    function setEchoContestWinner(
        uint256 genesisTextId,
        uint256 winningId,
        uint256 echoId,
        uint256[] memory losingEntryIds,
        bool toBeneficiary
    )
        external
        onlyRole(GlobalConstants.MID_ADMIN_ROLE)
        nonReentrant
    {
        uint256 previousFlow = previousEchoFlowId;
        uint256 currentFlow = currentEchoFlowId;

        // Can only set current or previous echo contest winner.
        if (genesisTextId != previousFlow && genesisTextId != currentFlow) {
            revert InvalidGenesisTextIdSetEchoContestWinner();
        }

        // Must set previous echo contest winner before current one.
        if (genesisTextId == currentFlow && currentFlow != previousFlow) {
            if (!_latestEchoContestsHaveWinner(previousFlow)) revert MustSetPreviousEchoContestWinner();
        }
        _setLatestEchoContestWinner(genesisTextId, winningId, echoId, losingEntryIds, toBeneficiary);
        _advanceEchoFlowIfPossible();
        if (_initializeChapterFlow) _advanceChapterFlowIfPossible();
    }

    function setChapterContestWinner(
        uint256 genesisTextId,
        uint256 winningId,
        uint256[] memory losingEntryIds,
        bool toBeneficiary
    )
        external
        onlyRole(GlobalConstants.MID_ADMIN_ROLE)
        nonReentrant
    {
        uint256 previousFlow = previousChapterFlowId;
        uint256 currentFlow = currentChapterFlowId;

        // Can only set current or previous chapter contest winner.
        if (genesisTextId != previousFlow && genesisTextId != currentFlow) {
            revert InvalidGenesisTextIdSetChapterContestWinner();
        }

        // Must set previous chapter contest winner before current one.
        if (genesisTextId == currentFlow && currentFlow != previousFlow) {
            if (!_latestChapterContestHasWinner(previousFlow)) revert MustSetPreviousChapterContestWinner();
        }
        _setLatestChapterContestWinner(genesisTextId, winningId, losingEntryIds, toBeneficiary);
        _advanceChapterFlowIfPossible();
        _advanceEchoFlowIfPossible();
    }

    // Calling function should not use newCurrentFlowId and newPreviousFlowId if canAdvance is false.
    function _advanceFlowIfPossible(
        uint256 prevFlowId,
        uint256 currFlowId,
        Flow flow
    )
        private
        view
        returns (bool canAdvance, uint256 newCurrentFlowId, uint256 newPreviousFlowId)
    {
        // If current contest can be closed and previous one has selected a winner, increment the flow
        // pointers. If current and previous IDs are the same, then only check if the current contest can be closed.
        bool currEqualsPrev = prevFlowId == currFlowId;
        bool previousContestHasWinner;
        if (flow == Flow.Chapter) {
            previousContestHasWinner = currEqualsPrev || _latestChapterContestHasWinner(prevFlowId);
        } else {
            previousContestHasWinner = currEqualsPrev || _latestEchoContestsHaveWinner(prevFlowId);
        }
        bool latestContestsHaveClosed =
            flow == Flow.Chapter ? _canCloseLatestChapterContest(currFlowId) : _latestEchoContestsClosed(currFlowId);

        if (latestContestsHaveClosed && previousContestHasWinner) {
            canAdvance = true;
            (newCurrentFlowId, newPreviousFlowId) = _incrementFlowCounter(currFlowId, prevFlowId, flow);
        } else {
            canAdvance = false;
        }
    }

    function _advanceEchoFlowIfPossible() private returns (bool) {
        (bool canAdvance, uint256 newCurrentFlowId, uint256 newPreviousFlowId) =
            _advanceFlowIfPossible(previousEchoFlowId, currentEchoFlowId, Flow.Echo);
        if (canAdvance) {
            if (nextEchoChapterId[newCurrentFlowId] > 0) {
                uint256 latestEchoId = _latestEchoChapterId(newCurrentFlowId);
                // The chapter contest should be created and must have set a winner before we can open its echoes.
                if (!_hasCreatedChapterContest(newCurrentFlowId, latestEchoId)) {
                    return false;
                }
                if (!IContest(chapterContests[newCurrentFlowId][latestEchoId]).hasWinner()) {
                    return false;
                }
            }

            currentEchoFlowId = newCurrentFlowId;
            previousEchoFlowId = newPreviousFlowId;
            emit AdvancedEchoFlow(newPreviousFlowId, newCurrentFlowId);

            // If next genesis text hasn't opened its echo contests yet then open them.
            _createNextEchoContests(newCurrentFlowId);
        }
        return canAdvance;
    }

    function _advanceChapterFlowIfPossible() private returns (bool) {
        uint256 curChapterFlowId = currentChapterFlowId;
        uint256 flowCount;

        while (_shouldSkipGenesisText(curChapterFlowId, Flow.Chapter)) {
            if (curChapterFlowId + 1 < GlobalConstants.GENESIS_TEXT_COUNT) {
                curChapterFlowId++;
            } else {
                curChapterFlowId = 0;
            }
            if (
                flowCount == GlobalConstants.GENESIS_TEXT_COUNT - 1
                    && _shouldSkipGenesisText(curChapterFlowId, Flow.Chapter)
            ) {
                return false;
            }

            flowCount++;
        }

        (bool canAdvance, uint256 newCurrentFlowId, uint256 newPreviousFlowId) =
            _advanceFlowIfPossible(previousChapterFlowId, currentChapterFlowId, Flow.Chapter);
        if (canAdvance) {
            uint256 _nextChapterId = nextChapterId[newCurrentFlowId];
            if (_nextChapterId == 0) {
                if (nextEchoChapterId[newCurrentFlowId] == 0 || !_initialEchoContestsHaveWinner(newCurrentFlowId, 0)) {
                    return false;
                }
            } else {
                if (
                    !IContest(chapterContests[newCurrentFlowId][_nextChapterId - 1]).hasWinner()
                        || !_initialEchoContestsHaveWinner(newCurrentFlowId, _nextChapterId)
                ) {
                    return false;
                }
            }

            currentChapterFlowId = newCurrentFlowId;
            previousChapterFlowId = newPreviousFlowId;
            emit AdvancedChapterFlow(newPreviousFlowId, newCurrentFlowId);

            _createNextChapterContest(newCurrentFlowId);
        }
        return canAdvance;
    }

    // Helpful manual trigger to advance echo flow.
    function advanceEchoFlow() external nonReentrant {
        if (!_advanceEchoFlowIfPossible()) revert CannotAdvanceEchoFlow();
    }

    // This method kicks off the chapter flow, which flows automatically from here on out. This method should only be
    // callable once. This method is callable by anyone to save gas. The alternative implementation would be to
    // check whether the first chapter was created everytime we set an Echo chapter contest winner. We only need to
    // kickstart the chapter flow once, so requiring it to be manually called once seems OK.
    function initializeChapterFlow() external nonReentrant {
        if (_initializeChapterFlow) revert ChapterFlowInitialized();

        while (_shouldSkipGenesisText(currentChapterFlowId, Flow.Chapter)) {
            if (currentChapterFlowId + 1 < GlobalConstants.GENESIS_TEXT_COUNT) {
                currentChapterFlowId++;
            }

            if (currentChapterFlowId == GlobalConstants.GENESIS_TEXT_COUNT - 1) {
                if (_shouldSkipGenesisText(currentChapterFlowId, Flow.Chapter)) revert AllGenesisTextsSkipped();
            }
        }

        previousChapterFlowId = currentChapterFlowId;
        _createNextChapterContest(currentChapterFlowId);

        _initializeChapterFlow = true;
    }

    // Convenient method to approve contest entry in current chapter flow genesis text. Owner will never need to
    // approve entry in previous capter flow genesis text because that contest must have been closed in order for the
    // current one to have opened.
    function approveChapterContestEntries(uint256[] memory entryIds)
        external
        onlyRole(GlobalConstants.MID_ADMIN_ROLE)
        nonReentrant
    {
        uint256 currentChapterFlow = currentChapterFlowId;
        IContest(chapterContests[currentChapterFlow][_latestChapterId(currentChapterFlow)]).acceptEntries(entryIds);
        _advanceChapterFlowIfPossible();
    }

    // Helper function to advance flow anyone can call
    function advanceChapterFlow() external nonReentrant {
        if (!_advanceChapterFlowIfPossible()) revert CannotAdvanceChapterFlow();
    }

    // Convenient method to approve contest entries in current echo flow genesis text. Owner will never need to
    // approve entries in previous echo flow genesis text because those contests must have been closed in order for the
    // current one to have opened.
    function approveEchoContestEntries(
        uint256 echoId,
        uint256[] memory entryIds
    )
        external
        onlyRole(GlobalConstants.MID_ADMIN_ROLE)
        nonReentrant
    {
        uint256 currentEchoFlow = currentEchoFlowId;
        _approveEchoContestEntries(currentEchoFlow, _latestEchoChapterId(currentEchoFlow), echoId, entryIds);
        _advanceEchoFlowIfPossible();
    }

    function _shouldSkipGenesisText(uint256 genesisTextId, Flow flow) internal view returns (bool) {
        if (flow == Flow.Chapter && nextChapterId[genesisTextId] >= GlobalConstants.MAX_CHAPTER_COUNT) {
            return true;
        }

        if (flow == Flow.Echo) {
            uint256 _nextEchoChapterId = nextEchoChapterId[genesisTextId];
            if (_nextEchoChapterId == 0) {
                return false;
            } else if (
                _hasCreatedChapterContest(genesisTextId, _nextEchoChapterId - 1)
                    && IContest(chapterContests[genesisTextId][_latestChapterId(genesisTextId)]).hasWinner()
            ) {
                return false;
            } else {
                return true;
            }
        }

        // Genesis Text Owners can “toggle” their NFT as “Open” or “Closed”, at any time.
        // Each time the Chapter Flow has the required Spire Owner and Creator actions completed to move to a
        // new Chapter, the last thing that must be checked is the “toggles”. If there are not enough “Open” for
        // the Genesis Text that the chapter is built on, then the Chapter’s competition is skipped.
        // The Chapter Flow moves onto the next storyline.
        // For example, if the Chapter flow is scheduled to open a contest for Chapter #4 of “The Dragon”,
        // then only four of the Genesis Texts for “The Dragon” storyline are required to be set to “Open”.
        // If it’s Chapter #17, then 17 need to be Open. If it’s Chapter #64, then 64 need to be open.
        // If it’s Chapter #100 or higher, all 100 Genesis Texts need to be “Open” at the time the Chapter Flow
        // moves through this storyline.
        bool hasEnoughOpenContest = IToggleGovernance(genesisGovernors[genesisTextId]).hasEnoughOpenGovernToggles(
            nextChapterId[genesisTextId] + 1
        );
        return !hasEnoughOpenContest;
    }

    // This function should not modify state. It returns what the incremented current and previous flow ID's
    // should be while taking into account chapters that should be skipped, and when ID's should roll over from the
    // highest possible genesis text ID to the first.
    function _incrementFlowCounter(
        uint256 currentFlowId,
        uint256 previousFlowId,
        Flow flow
    )
        internal
        view
        returns (uint256 newCurrentFlowId, uint256 newPreviousFlowId)
    {
        // Update previous flow pointer to current one. Then enter loop to figure out what
        // current pointer should update to.
        previousFlowId = currentFlowId;

        do {
            if (currentFlowId + 1 < GlobalConstants.GENESIS_TEXT_COUNT) {
                currentFlowId++;
            } else {
                // We've completed a full circle around the spire. Reset the genesis text ID to 0.
                currentFlowId = 0;
            }

            // If current flow pointer gets updated to the previous one, then we've gone around a full
            // circle meaning. If the current genesis text is then closed, then every single genesis text is closed.
            if (previousFlowId == currentFlowId && _shouldSkipGenesisText(currentFlowId, flow)) {
                if (flow == Flow.Chapter) {
                    revert AllGenesisTextsSkipped();
                } else {
                    break;
                }
            }

            newCurrentFlowId = currentFlowId;
            newPreviousFlowId = previousFlowId;
        } while (_shouldSkipGenesisText(currentFlowId, flow));
    }

    function _latestEchoContestsClosed(uint256 genesisTextId) internal view returns (bool) {
        return _initialEchoContestsClosed(genesisTextId, _latestEchoChapterId(genesisTextId));
    }

    function _latestEchoContestsHaveWinner(uint256 genesisTextId) internal view returns (bool) {
        return _initialEchoContestsHaveWinner(genesisTextId, _latestEchoChapterId(genesisTextId));
    }

    function _latestChapterContestHasWinner(uint256 genesisTextId) internal view returns (bool) {
        return IContest(chapterContests[genesisTextId][_latestChapterId(genesisTextId)]).hasWinner();
    }

    function _setLatestChapterContestWinner(
        uint256 genesisTextId,
        uint256 winningId,
        uint256[] memory losingEntryIds,
        bool toBeneficiary
    )
        internal
    {
        _setChapterContestWinner(
            genesisTextId, _latestChapterId(genesisTextId), winningId, losingEntryIds, toBeneficiary
        );
    }

    function _setLatestEchoContestWinner(
        uint256 genesisTextId,
        uint256 winningId,
        uint256 echoId,
        uint256[] memory losingEntryIds,
        bool toBeneficiary
    )
        internal
    {
        _setEchoContestWinner(
            genesisTextId, _latestEchoChapterId(genesisTextId), echoId, winningId, losingEntryIds, toBeneficiary
        );
    }

    function getChapterContests(uint256 genesisTextId, uint256 chapterId) external view returns (address) {
        return chapterContests[genesisTextId][chapterId];
    }

    // Custom implementation of transferOwnership in MyContract
    // Additional logic to grant MID_ADMIN_ROLE
    function transferOwnership(address newOwner) public override onlyOwner {
        if (owner() == newOwner) return;

        // Revoke SUPER_ADMIN_ROLE & MID_ADMIN_ROLE for old owner
        _revokeRole(GlobalConstants.MID_ADMIN_ROLE, owner());
        _revokeRole(GlobalConstants.SUPER_ADMIN_ROLE, owner());

        // Gives newOwner the SUPER_ADMIN_ROLE & MID_ADMIN_ROLE
        _setupRole(GlobalConstants.SUPER_ADMIN_ROLE, newOwner);
        _setupRole(GlobalConstants.MID_ADMIN_ROLE, newOwner);

        super.transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import { IERC1155Supply } from "./IERC1155Supply.sol";
import { GlobalConstants } from "./Constants.sol";

interface IToggleGovernance {
    function hasEnoughOpenGovernToggles(uint256 requiredStake) external view returns (bool);
}

error InsufficientStakeAmount();

contract ToggleGovernance is ERC1155Holder, IToggleGovernance, ReentrancyGuard, Multicall {
    IERC1155Supply public immutable governanceToken;
    uint256 public immutable governanceTokenId;

    mapping(address => uint256) public stakers;
    uint256 public stakedAmount;

    event Stake(address indexed staker, uint256 indexed amount);
    event Unstake(address indexed staker, uint256 indexed amount);

    constructor(IERC1155Supply _governanceToken, uint256 _governanceTokenId) {
        governanceToken = _governanceToken;
        governanceTokenId = _governanceTokenId;
    }

    function stake(uint256 amount) external nonReentrant {
        stakers[msg.sender] += amount;
        stakedAmount += amount;
        governanceToken.safeTransferFrom(msg.sender, address(this), governanceTokenId, amount, "");
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        if (stakers[msg.sender] < amount) revert InsufficientStakeAmount();
        stakers[msg.sender] -= amount;
        stakedAmount -= amount;
        governanceToken.safeTransferFrom(address(this), msg.sender, governanceTokenId, amount, "");
        emit Unstake(msg.sender, amount);
    }

    function hasEnoughOpenGovernToggles(uint256 requiredOpenToggles) external view override returns (bool) {
        // staked   = "closed" toggles
        // unstaked = "open" toggles
        // inital   = all of "open" toggles
        return GlobalConstants.MAX_CHAPTER_COUNT - stakedAmount >= requiredOpenToggles;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ToggleGovernance } from "./ToggleGovernance.sol";
import { IERC1155Supply } from "./IERC1155Supply.sol";

contract ToggleGovernanceFactory {
    function deployNewToggleGovernor(
        IERC1155Supply governanceToken,
        uint256 governanceTokenId
    )
        external
        returns (address)
    {
        return address(new ToggleGovernance(governanceToken, governanceTokenId));
    }
}