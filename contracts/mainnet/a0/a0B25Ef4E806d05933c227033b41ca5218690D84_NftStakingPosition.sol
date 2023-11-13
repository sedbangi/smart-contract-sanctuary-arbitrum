pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "ERC721.sol";
import "Ownable.sol";
import "IERC20.sol";
import "ListingList.sol";
import "NftBattleArena.sol";
import "IZooFunctions.sol";

/// @title NftStakingPosition
/// @notice Contract to stake/unstake NFTs
contract NftStakingPosition is ERC721, Ownable
{
	struct Nft
	{
		address token;
		uint256 id;
	}

	IZooFunctions public zooFunctions;                               // zooFunctions contract.
	address payable public team;

	event NftBattleArenaSet(address nftBattleArena);

	event ClaimedIncentiveRewardFromVoting(address indexed staker, address beneficiary, uint256 zooReward, uint256 stakingPositionId);

	// Records NFT contracts available for staking.
	NftBattleArena public nftBattleArena;
	ListingList public listingList;
	IERC20 public zoo;

	mapping (uint256 => Nft) public positions;

	constructor(string memory _name, string memory _symbol, address _listingList, address _zoo, address baseZooFunctions, address payable _team) ERC721(_name, _symbol) Ownable()
	{
		listingList = ListingList(_listingList);
		zoo = IERC20(_zoo);
		zooFunctions = IZooFunctions(baseZooFunctions);
		team = _team;
	}

	modifier feePaid(uint256 fee) {
		require(fee >= zooFunctions.getArenaFee(), "Fee wasn't provide to arena");
		_;
		(bool sent, ) = address(team).call{value: msg.value}("");
		require(sent, "Failed to send");
	}

	function setNftBattleArena(address _nftBattleArena) external onlyOwner
	{
		require(address(nftBattleArena) == address(0));

		nftBattleArena = NftBattleArena(_nftBattleArena);

		emit NftBattleArenaSet(_nftBattleArena);
	}

	function stakeNft(address token, uint256 id) payable feePaid(msg.value) external
	{
		require(listingList.eligibleCollections(token), "NFT collection is not allowed");
		require(nftBattleArena.getCurrentStage() == Stage.FirstStage, "Wrong stage!");

		IERC721(token).transferFrom(msg.sender, address(this), id);                // Sends NFT token to this contract.

		uint256 index = nftBattleArena.createStakerPosition(msg.sender, token);
		_safeMint(msg.sender, index);
		positions[index] = Nft(token, id);
	}

	function unstakeNft(uint256 stakingPositionId) external
	{
		require(ownerOf(stakingPositionId) == msg.sender, "Not the owner of NFT");
		require(nftBattleArena.getCurrentStage() == Stage.FirstStage, "Wrong stage!");

		nftBattleArena.removeStakerPosition(stakingPositionId, msg.sender);

		Nft storage nft = positions[stakingPositionId];
		IERC721(nft.token).transferFrom(address(this), msg.sender, nft.id);                 // Transfers token back to owner.
	}

	function claimRewardFromStaking(uint256 stakingPositionId, address beneficiary) external
	{
		require(ownerOf(stakingPositionId) == msg.sender, "Not the owner of NFT");
		
		nftBattleArena.claimRewardFromStaking(stakingPositionId, msg.sender, beneficiary);
	}

	/// Claims rewards from multiple staking positions
	/// @param stakingPositionIds array of staking positions indexes
	/// @param beneficiary address to transfer reward to
	function batchClaimRewardsFromStaking(uint256[] calldata stakingPositionIds, address beneficiary) external
	{
		for (uint256 i = 0; i < stakingPositionIds.length; i++)
		{
			require(msg.sender == ownerOf(stakingPositionIds[i]), "Not the owner of NFT");

			nftBattleArena.claimRewardFromStaking(stakingPositionIds[i], msg.sender, beneficiary);
		}
	}

	function batchUnstakeNft(uint256[] calldata stakingPositionIds) external
	{
		require(nftBattleArena.getCurrentStage() == Stage.FirstStage, "Wrong stage!");

		for (uint256 i = 0; i < stakingPositionIds.length; i++)
		{
			require(msg.sender == ownerOf(stakingPositionIds[i]), "Not the owner of NFT");

			nftBattleArena.removeStakerPosition(stakingPositionIds[i], msg.sender);

			Nft storage nft = positions[stakingPositionIds[i]];
			IERC721(nft.token).transferFrom(address(this), msg.sender, nft.id);                 // Transfers token back to owner.
		}
	}

	function claimIncentiveStakerReward(uint256 stakingPositionId, address beneficiary) external returns (uint256)
	{
		require(ownerOf(stakingPositionId) == msg.sender, "Not the owner!");             // Requires to be owner of position.
		uint256 reward = nftBattleArena.calculateIncentiveRewardForStaker(stakingPositionId);

		zoo.transfer(beneficiary, reward);

		return reward;
	}

	function batchClaimIncentiveStakerReward(uint256[] calldata stakingPositionIds, address beneficiary) external returns (uint256 reward)
	{
		for (uint256 i = 0; i < stakingPositionIds.length; i++)
		{
			require(ownerOf(stakingPositionIds[i]) == msg.sender, "Not the owner!");             // Requires to be owner of position.

			uint256 claimed = nftBattleArena.calculateIncentiveRewardForStaker(stakingPositionIds[i]);
			reward += claimed;

			emit ClaimedIncentiveRewardFromVoting(msg.sender, beneficiary, claimed, stakingPositionIds[i]);
		}
		zoo.transfer(beneficiary, reward);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC721Metadata.sol";
import "Address.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "Math.sol";

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
        // в†’ `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // в†’ `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "Ownable.sol";
import "IERC20.sol";
import "ERC721.sol";

interface INftBattleArena
{
	function addVotesToVeZoo(address collection, uint256 amount) external;

	function removeVotesFromVeZoo(address collection, uint256 amount) external;
}

/// @title ListingList
/// @notice Contract for recording nft contracts eligible for Zoo Dao Battles.
contract ListingList is Ownable, ERC721
{
	struct VePositionInfo
	{
		uint256 zooLocked;
		address collection;
		uint256 decayRate;
	}

	IERC20 public zoo;                                                               // Zoo collection interface.

	/// @notice Event records address of allowed nft contract.
	event NewContractAllowed(address indexed collection, address royalteRecipient);

	event ContractDisallowed(address indexed collection, address royalteRecipient);

	event RoyalteRecipientChanged(address indexed collection, address recipient);

	event VotedForCollection(address indexed collection, address indexed voter, uint256 amount, uint256 positionId);

	event ZooUnlocked(address indexed voter, address indexed collection, uint256 amount, uint256 positionId);

	// Nft contract => allowed or not.
	mapping (address => bool) public eligibleCollections;

	// Nft contract => address recipient.
	mapping (address => address) public royalteRecipient;

	mapping (uint256 => VePositionInfo) public vePositions;

	mapping (address => uint256[]) public tokenOfOwnerByIndex;

	uint256 public vePositionIndex = 1;

	uint256 public endEpochOfIncentiveRewards;

	INftBattleArena public arena;

	constructor(address _zoo, uint256 _endEpochOfIncentiveRewards) ERC721("veZoo", "VEZOO")
	{
		zoo = IERC20(_zoo);
		endEpochOfIncentiveRewards = _endEpochOfIncentiveRewards;
	}

	function init(address nftBattleArena) external
	{
		require(address(arena) == address(0), "Var has already inited");

		arena = INftBattleArena(nftBattleArena);
	}

/* ========== Eligible projects and royalte managemenet ===========*/

	/// @notice Function to allow new NFT contract into eligible projects.
	/// @param collection - address of new Nft contract.
	function allowNewContractForStaking(address collection, address _royalteRecipient) external onlyOwner
	{
		eligibleCollections[collection] = true;                                          // Boolean for contract to be allowed for staking.

		royalteRecipient[collection] = _royalteRecipient;                                // Recipient for % of reward from that nft collection.

		emit NewContractAllowed(collection, _royalteRecipient);                                             // Emits event that new contract are allowed.
	}

	/// @notice Function to allow multiplie contracts into eligible projects.
	function batchAllowNewContract(address[] calldata tokens, address[] calldata royalteRecipients) external onlyOwner
	{
		for (uint256 i = 0; i < tokens.length; i++)
		{
			eligibleCollections[tokens[i]] = true;

			royalteRecipient[tokens[i]] = royalteRecipients[i];                     // Recipient for % of reward from that nft collection.

			emit NewContractAllowed(tokens[i], royalteRecipients[i]);                                     // Emits event that new contract are allowed.
		}
	}

	/// @notice Function to disallow contract from eligible projects and change royalte recipient for already staked nft.
	function disallowContractFromStaking(address collection, address recipient) external onlyOwner
	{
		eligibleCollections[collection] = false;

		royalteRecipient[collection] = recipient;                                        // Recipient for % of reward from that nft collection.

		emit ContractDisallowed(collection, recipient);                                             // Emits event that new contract are allowed.
	}

	/// @notice Function to set or change royalte recipient without removing from eligible projects.
	function setRoyalteRecipient(address collection, address recipient) external onlyOwner
	{
		royalteRecipient[collection] = recipient;

		emit RoyalteRecipientChanged(collection, recipient);
	}

/* ========== Ve-Model voting part ===========*/
	
	function voteForNftCollection(address collection, uint256 amount) public
	{
		require(eligibleCollections[collection], "NFT collection is not allowed");

		zoo.transferFrom(msg.sender, address(this), amount);

		vePositions[vePositionIndex] = VePositionInfo(amount, collection, 0);
		arena.addVotesToVeZoo(collection, amount * 3 / 2);

		tokenOfOwnerByIndex[msg.sender].push(vePositionIndex);
		emit VotedForCollection(collection, msg.sender, amount, vePositionIndex);
		_mint(msg.sender, vePositionIndex++);
	}

	function unlockZoo(uint256 positionId) external
	{
		require(ownerOf(positionId) == msg.sender);
		VePositionInfo storage vePosition = vePositions[positionId];

		arena.removeVotesFromVeZoo(vePosition.collection, vePosition.zooLocked * 3 / 2);
		zoo.transfer(msg.sender, vePosition.zooLocked);
		_burn(positionId);

		emit ZooUnlocked(msg.sender, vePosition.collection, vePosition.zooLocked, positionId);
	}
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "IVault.sol";
import "IZooFunctions.sol";
import "ZooGovernance.sol";
import "ListingList.sol";
import "IERC20Metadata.sol";
import "Math.sol";
import "ERC4626.sol";

/// @notice Struct with stages of arena.
enum Stage
{
	FirstStage,
	SecondStage,
	ThirdStage,
	FourthStage,
	FifthStage
}

/// @title NftBattleArena contract.
/// @notice Contract for staking ZOO-Nft for participate in battle votes.
contract NftBattleArena
{
	using Math for uint256;
	using Math for int256;

	ERC4626 public lpZoo;                                            // lp zoo interface.
	IERC20Metadata public dai;                                       // stablecoin token interface
	IERC20Metadata public zoo;                                       // Zoo token interface
	VaultAPI public vault;                                           // Vault interface.
	ZooGovernance public zooGovernance;                              // zooGovernance contract.
	IZooFunctions public zooFunctions;                               // zooFunctions contract.
	ListingList public veZoo;

	/// @notice Struct with info about rewards, records for epoch.
	struct BattleRewardForEpoch
	{
		int256 yTokensSaldo;                                         // Saldo from deposit in yearn in yTokens.
		uint256 votes;                                               // Total amount of votes for nft in this battle in this epoch.
		uint256 yTokens;                                             // Amount of yTokens.
		uint256 tokensAtBattleStart;                                 // Amount of yTokens at battle start.
		uint256 pricePerShareAtBattleStart;                          // pps at battle start.
		uint256 pricePerShareCoef;                                   // pps1*pps2/pps2-pps1
		uint256 zooRewards;                                          // Reward from arena 50-50 battle
		uint8 league;                                                // League of NFT
	}

	/// @notice Struct with info about staker positions.
	struct StakerPosition
	{
		uint256 startEpoch;                                          // Epoch when started to stake.
		uint256 endEpoch;                                            // Epoch when unstaked.
		uint256 lastRewardedEpoch;                                   // Epoch when last reward were claimed.
		uint256 lastUpdateEpoch;                                     // Epoch when last updateInfo called.
		address collection;                                          // Address of nft collection contract.
		uint256 lastEpochOfIncentiveReward;
	}

	/// @notice struct with info about voter positions.
	struct VotingPosition
	{
		uint256 stakingPositionId;                                   // Id of staker position voted for.
		uint256 daiInvested;                                         // Amount of dai invested in voting position.
		uint256 yTokensNumber;                                       // Amount of yTokens got for dai.
		uint256 zooInvested;                                         // Amount of Zoo used to boost votes.
		uint256 daiVotes;                                            // Amount of votes got from voting with dai.
		uint256 votes;                                               // Amount of total votes from dai, zoo and multiplier.
		uint256 startEpoch;                                          // Epoch when created voting position.
		uint256 endEpoch;                                            // Epoch when liquidated voting position.
		uint256 lastRewardedEpoch;                                   // Epoch when last battle reward was claimed.
		uint256 lastEpochYTokensWereDeductedForRewards;              // Last epoch when yTokens used for rewards in battles were deducted from all voting position's yTokens
		uint256 yTokensRewardDebt;                                   // Amount of yTokens which voter can claim for previous epochs before add/withdraw votes.
		uint256 lastEpochOfIncentiveReward;
	}

	/// @notice Struct for records about pairs of Nfts for battle.
	struct NftPair
	{
		uint256 token1;                                              // Id of staker position of 1st candidate.
		uint256 token2;                                              // Id of staker position of 2nd candidate.
		bool playedInEpoch;                                          // Returns true if winner chosen.
		bool win;                                                    // Boolean, where true is when 1st candidate wins, and false for 2nd.
	}

	/// @notice Event about staked nft.                         FirstStage
	event CreatedStakerPosition(uint256 indexed currentEpoch, address indexed staker, uint256 indexed stakingPositionId);

	/// @notice Event about withdrawed nft from arena.          FirstStage
	event RemovedStakerPosition(uint256 indexed currentEpoch, address indexed staker, uint256 indexed stakingPositionId);


	/// @notice Event about created voting position.            SecondStage
	event CreatedVotingPosition(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 daiAmount, uint256 votes, uint256 votingPositionId);

	/// @notice Event about liquidated voting position.         FirstStage
	event LiquidatedVotingPosition(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, address beneficiary, uint256 votingPositionId, uint256 zooReturned, uint256 daiReceived);

	/// @notice Event about recomputing votes from dai.         SecondStage
	event RecomputedDaiVotes(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 newVotes, uint256 oldVotes);

	/// @notice Event about recomputing votes from zoo.         FourthStage
	event RecomputedZooVotes(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 newVotes, uint256 oldVotes);


	/// @notice Event about adding dai to voter position.       SecondStage
	event AddedDaiToVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 amount, uint256 votes);

	/// @notice Event about adding zoo to voter position.       FourthStage
	event AddedZooToVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 amount, uint256 votes);


	/// @notice Event about withdraw dai from voter position.   FirstStage
	event WithdrawedDaiFromVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, address beneficiary, uint256 votingPositionId, uint256 daiNumber);

	/// @notice Event about withdraw zoo from voter position.   FirstStage
	event WithdrawedZooFromVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, uint256 votingPositionId, uint256 zooNumber, address beneficiary);


	/// @notice Event about claimed reward from voting.         FirstStage
	event ClaimedRewardFromVoting(uint256 indexed currentEpoch, address indexed voter, uint256 indexed stakingPositionId, address beneficiary, uint256 daiReward, uint256 votingPositionId);

	/// @notice Event about claimed reward from staking.        FirstStage
	event ClaimedRewardFromStaking(uint256 indexed currentEpoch, address indexed staker, uint256 indexed stakingPositionId, address beneficiary, uint256 yTokenReward, uint256 daiReward);


	/// @notice Event about paired nfts.                        ThirdStage
	event PairedNft(uint256 indexed currentEpoch, uint256 indexed fighter1, uint256 indexed fighter2, uint256 pairIndex);

	/// @notice Event about winners in battles.                 FifthStage
	event ChosenWinner(uint256 indexed currentEpoch, uint256 indexed fighter1, uint256 indexed fighter2, bool winner, uint256 pairIndex, uint256 playedPairsAmount);

	/// @notice Event about changing epochs.
	event EpochUpdated(uint256 date, uint256 newEpoch);

	uint256 public epochStartDate;                                                 // Start date of battle epoch.
	uint256 public currentEpoch = 1;                                               // Counter for battle epochs.

	uint256 public firstStageDuration;                                             // Duration of first stage(stake).
	uint256 public secondStageDuration;                                            // Duration of second stage(DAI)'.
	uint256 public thirdStageDuration;                                             // Duration of third stage(Pair).
	uint256 public fourthStageDuration;                                            // Duration fourth stage(ZOO).
	uint256 public fifthStageDuration;                                             // Duration of fifth stage(Winner).
	uint256 public epochDuration;                                                  // Total duration of battle epoch.

	uint256[] public activeStakerPositions;                                        // Array of ZooBattle nfts, which are StakerPositions.
	uint256 public numberOfNftsWithNonZeroVotes;                                   // Staker positions with votes for, eligible to pair and battle.
	uint256 public numberOfNftsWithNonZeroVotesPending; // positions eligible for paring from next epoch.
	uint256 public nftsInGame;                                                     // Amount of Paired nfts in current epoch.

	uint256 public numberOfStakingPositions = 1;
	uint256 public numberOfVotingPositions = 1;

	address public treasury;                                                       // Address of ZooDao insurance pool.
	// address public team;                                                           // Address of ZooDao team reward pool.
	address public nftStakingPosition; // address of staking positions contract.
	address public nftVotingPosition;  // address of voting positions contract.

	uint256 public baseStakerReward = 133_000 * 10 ** 18 * 15 / 100; // amount of incentives for staker.
	uint256 public baseVoterReward = 133_000 * 10 ** 18 * 85 / 100; // amount of incentives for voter.

	uint256 public zooVoteRateNominator; // amount of votes for 1 LP with zoo.
	uint256 public zooVoteRateDenominator;

	uint256 public constant endEpochOfIncentiveRewards = 13;

	mapping (address => mapping (uint256 => uint256)) public poolWeight;

	// epoch number => index => NftPair struct.
	mapping (uint256 => NftPair[]) public pairsInEpoch;                            // Records info of pair in struct per battle epoch.

	// epoch number => number of played pairs in epoch.
	mapping (uint256 => uint256) public numberOfPlayedPairsInEpoch;                // Records amount of pairs with chosen winner in current epoch.

	// position id => StakerPosition struct.
	mapping (uint256 => StakerPosition) public stakingPositionsValues;             // Records info about staker position.

	// position id => VotingPosition struct.
	mapping (uint256 => VotingPosition) public votingPositionsValues;              // Records info about voter position.

	// epoch index => collection => number of staked nfts.
	mapping (uint256 => mapping (address => uint256)) public numberOfStakedNftsInCollection;

	// collection => last epoch when info about numberOfStakedNftsInCollection was updated.
	mapping (address => uint256) public lastUpdatesOfStakedNumbers;

	// staker position id => epoch = > rewards struct.
	mapping (uint256 => mapping (uint256 => BattleRewardForEpoch)) public rewardsForEpoch;

	// epoch number => timestamp of epoch start
	mapping (uint256 => uint256) public epochsStarts;

	// epoch number => votes from stablecoins played in this epoch
	mapping (uint256 => uint256) public playedVotesByEpoch;

	// id voting position => pendingVotes
	mapping (uint256 => uint256) public pendingVotes;      // Votes amount for next epoch.

	// id voting position => pendingVotesEpoch
	mapping (uint256 => uint256) public pendingVotesEpoch; // Epoch when voted for next epoch.

	// id voting position => zooTokenRewardDebt
	mapping (uint256 => uint256) public zooTokensRewardDebt; // This needs for correct distributing of zoo reward for 50-50 arena battle case.

	// voting position id => zoo debt
	mapping (uint256 => uint256) public voterIncentiveDebt;

	modifier only(address who)
	{
		require(msg.sender == who);
		_;
	}

	/// @notice Contract constructor.
	/// @param _lpZoo - address of LP token with zoo.
	/// @param _dai - address of stable token contract.
	/// @param _vault - address of yearn.
	/// @param _zooGovernance - address of ZooDao Governance contract.
	/// @param _treasuryPool - address of ZooDao treasury pool.
	///  _teamAddress - address of ZooDao team reward pool.
	constructor (
		ERC4626 _lpZoo,
		IERC20Metadata _dai,
		address _vault,
		address _zooGovernance,
		address _treasuryPool,
		// address _teamAddress,
		address _nftStakingPosition,
		address _nftVotingPosition,
		address _veZoo)
	{
		lpZoo = _lpZoo;
		dai = _dai;
		vault = VaultAPI(_vault);
		zooGovernance = ZooGovernance(_zooGovernance);
		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());
		veZoo = ListingList(_veZoo);

		treasury = _treasuryPool;
		// team = _teamAddress;
		nftStakingPosition = _nftStakingPosition;
		nftVotingPosition = _nftVotingPosition;

		epochStartDate = block.timestamp; // Start date of 1st battle.
		epochsStarts[currentEpoch] = block.timestamp;
		(firstStageDuration, secondStageDuration, thirdStageDuration, fourthStageDuration, fifthStageDuration, epochDuration) = zooFunctions.getStageDurations();
	}

	/// @param _zooVoteRateNominator - amount of votes for 1 LP with zoo.
	/// @param _zooVoteRateDenomibator - divider for amount of votes for 1 LP with zoo.
	/// @param _zoo actual zoo token(not LP).
	function init(uint256 _zooVoteRateNominator, uint256 _zooVoteRateDenomibator, IERC20Metadata _zoo) external
	{
		require(zooVoteRateNominator == 0);

		zooVoteRateNominator = _zooVoteRateNominator;
		zooVoteRateDenominator = _zooVoteRateDenomibator;
		zoo = _zoo;
	}

	/// @notice Function to get amount of nft in array StakerPositions/staked in battles.
	/// @return amount - amount of ZooBattles nft.
	function getStakerPositionsLength() public view returns (uint256 amount)
	{
		return activeStakerPositions.length;
	}

	/// @notice Function to get amount of nft pairs in epoch.
	/// @param epoch - number of epoch.
	/// @return length - amount of nft pairs.
	function getNftPairLength(uint256 epoch) public view returns(uint256 length)
	{
		return pairsInEpoch[epoch].length;
	}

	/// @notice Function to calculate amount of tokens from shares.
	/// @param sharesAmount - amount of shares.
	/// @return tokens - calculated amount tokens from shares.
	function sharesToTokens(uint256 sharesAmount) public returns (uint256 tokens)
	{
		return sharesAmount * vault.exchangeRateCurrent() / (10 ** 18);
	}

	/// @notice Function for calculating tokens to shares.
	/// @param tokens - amount of tokens to calculate.
	/// @return shares - calculated amount of shares.
	function tokensToShares(uint256 tokens) public returns (uint256 shares)
	{
		return tokens * (10 ** 18) / vault.exchangeRateCurrent();
	}

	/// @notice Function for staking NFT in this pool.
	/// @param staker address of staker
	/// @param token NFT collection address
	function createStakerPosition(address staker, address token) public only(nftStakingPosition) returns (uint256)
	{
		//require(getCurrentStage() == Stage.FirstStage, "Wrong stage!"); // Require turned off cause its moved to staker position contract due to lack of space for bytecode. // Requires to be at first stage in battle epoch.

		StakerPosition storage position = stakingPositionsValues[numberOfStakingPositions];
		position.startEpoch = currentEpoch;                                                     // Records startEpoch.
		position.lastRewardedEpoch = currentEpoch;                                              // Records lastRewardedEpoch
		position.collection = token;                                                            // Address of nft collection.
		position.lastEpochOfIncentiveReward = currentEpoch;

		numberOfStakedNftsInCollection[currentEpoch][token]++;                                  // Increments amount of nft collection.

		activeStakerPositions.push(numberOfStakingPositions);                                   // Records this position to stakers positions array.

		emit CreatedStakerPosition(currentEpoch, staker, numberOfStakingPositions);             // Emits StakedNft event.

		return numberOfStakingPositions++;                                                      // Increments amount and id of future positions.
	}

	/// @notice Function for withdrawing staked nft.
	/// @param stakingPositionId - id of staker position.
	function removeStakerPosition(uint256 stakingPositionId, address staker) external only(nftStakingPosition)
	{
		//require(getCurrentStage() == Stage.FirstStage, "Wrong stage!"); // Require turned off cause its moved to staker position contract due to lack of space for bytecode. // Requires to be at first stage in battle epoch.
		StakerPosition storage position = stakingPositionsValues[stakingPositionId];
		require(position.endEpoch == 0, "E1");                                        // Requires token to be staked.

		position.endEpoch = currentEpoch;                                                       // Records epoch when unstaked.
		updateInfo(stakingPositionId);                                                          // Updates staking position params from previous epochs.

		if (rewardsForEpoch[stakingPositionId][currentEpoch].votes > 0 || rewardsForEpoch[stakingPositionId][currentEpoch + 1].votes > 0)                         // If votes for position in current or next epoch more than zero.
		{
			for(uint256 i = 0; i < numberOfNftsWithNonZeroVotes; ++i)                           // Iterates for non-zero positions.
			{
				if (activeStakerPositions[i] == stakingPositionId)                              // Finds this position in array of active positions.
				{
					// Replace this position with another position from end of array. Then shift zero positions for one point.
					activeStakerPositions[i] = activeStakerPositions[numberOfNftsWithNonZeroVotes - 1];
					activeStakerPositions[--numberOfNftsWithNonZeroVotes] = activeStakerPositions[activeStakerPositions.length - 1];
					break;
				}
			}
		}
		else // If votes for position in current epoch are zero, does the same, but without decrement numberOfNftsWithNonZeroVotes.
		{
			for(uint256 i = numberOfNftsWithNonZeroVotes; i < activeStakerPositions.length; ++i)
			{
				if (activeStakerPositions[i] == stakingPositionId)                                     // Finds this position in array.
				{
					activeStakerPositions[i] = activeStakerPositions[activeStakerPositions.length - 1];// Swaps to end of array.
					break;
				}
			}
		}

		updateInfoAboutStakedNumber(position.collection);
		numberOfStakedNftsInCollection[currentEpoch][position.collection]--;
		activeStakerPositions.pop();                                                            // Removes staker position from array.

		emit RemovedStakerPosition(currentEpoch, staker, stakingPositionId);                    // Emits UnstakedNft event.
	}

	/// @notice Function for vote for nft in battle.
	/// @param stakingPositionId - id of staker position.
	/// @param amount - amount of dai to vote.
	/// @return votes - computed amount of votes.
	function createVotingPosition(uint256 stakingPositionId, address voter, uint256 amount) external only(nftVotingPosition) returns (uint256 votes, uint256 votingPositionId)
	{
		//require(getCurrentStage() == Stage.SecondStage, "Wrong stage!"); // Require turned off cause its moved to voting position contract due to lack of space for bytecode. // Requires to be at second stage of battle epoch.

		updateInfo(stakingPositionId);                                                          // Updates staking position params from previous epochs.

		dai.approve(address(vault), type(uint256).max);                                         // Approves Dai for yearn.
		uint256 yTokensNumber = vault.balanceOf(address(this));
		require(vault.mint(amount) == 0);                                                       // Deposits dai to yearn vault and get yTokens.

		(votes, votingPositionId) = _createVotingPosition(stakingPositionId, voter, vault.balanceOf(address(this)) - yTokensNumber, amount);// Calls internal create voting position.
	}

	/// @dev internal function to modify voting position params without vault deposit, making swap votes possible.
	/// @param stakingPositionId ID of staking to create voting for
	/// @param voter address of voter
	/// @param yTokens amount of yTokens got from Yearn from deposit
	/// @param amount daiVotes amount
	function _createVotingPosition(uint256 stakingPositionId, address voter, uint256 yTokens, uint256 amount) public only(nftVotingPosition) returns (uint256 votes, uint256 votingPositionId)
	{
		StakerPosition storage stakingPosition = stakingPositionsValues[stakingPositionId];
		require(stakingPosition.startEpoch != 0 && stakingPosition.endEpoch == 0, "E1"); // Requires for staking position to be staked.

		VotingPosition storage position = votingPositionsValues[numberOfVotingPositions];
		votes = zooFunctions.computeVotesByDai(amount);                                         // Calculates amount of votes.

		uint256 epoch = currentEpoch;
		if (getCurrentStage() > Stage.ThirdStage)
		{
			epoch += 1;
			pendingVotes[numberOfVotingPositions] = votes;
			pendingVotesEpoch[numberOfVotingPositions] = currentEpoch;
		}
		else
		{
			position.daiVotes = votes;                     // Records computed amount of votes to daiVotes.
			position.votes = votes;                        // Records computed amount of votes to total votes.
		}

		position.stakingPositionId = stakingPositionId;    // Records staker position Id voted for.
		position.yTokensNumber = yTokens;                  // Records amount of yTokens got from yearn vault.
		position.daiInvested = amount;                     // Records amount of dai invested.
		position.startEpoch = epoch;                       // Records epoch when position created.
		position.lastRewardedEpoch = epoch;                // Sets starting point for reward to current epoch.
		position.lastEpochOfIncentiveReward = epoch;       // Sets starting point for incentive rewards calculation.

		BattleRewardForEpoch storage battleReward = rewardsForEpoch[stakingPositionId][currentEpoch];
		BattleRewardForEpoch storage battleReward1 = rewardsForEpoch[stakingPositionId][epoch];

		if (battleReward.votes == 0)                                                            // If staker position had zero votes before,
		{
			if (epoch == currentEpoch) // if vote for this epoch
			{
				_swapActiveStakerPositions(stakingPositionId);
				numberOfNftsWithNonZeroVotes++;
			}
			else if (battleReward1.votes == 0) // if vote for next epoch and position have zero votes in both epochs.
			{
				_swapActiveStakerPositions(stakingPositionId);
				numberOfNftsWithNonZeroVotesPending++;
			}
		}
		battleReward1.votes += votes;                                                            // Adds votes for staker position for this epoch.
		battleReward1.yTokens += yTokens;                                                        // Adds yTokens for this staker position for this epoch.

		battleReward1.league = zooFunctions.getNftLeague(battleReward1.votes);

		votingPositionId = numberOfVotingPositions;
		numberOfVotingPositions++;

		emit CreatedVotingPosition(epoch, voter, stakingPositionId, amount, votes, votingPositionId);
	}


	function _swapActiveStakerPositions(uint256 stakingPositionId) internal
	{
		for(uint256 i = 0; i < activeStakerPositions.length; ++i)                           // Iterate for active staker positions.
		{
			if (activeStakerPositions[i] == stakingPositionId)                              // Finds this position.
			{
				uint256 endIndex = numberOfNftsWithNonZeroVotes + numberOfNftsWithNonZeroVotesPending;
				if (i > endIndex)                                       // if equal, then its already in needed place in array.
				{
					(activeStakerPositions[i], activeStakerPositions[endIndex]) = (activeStakerPositions[endIndex], activeStakerPositions[i]);                                              // Swaps this position in array, moving it to last point of non-zero positions.
					break;
				}
			}
		}
	}

	/// @notice Function to recompute votes from dai.
	/// @notice Reasonable to call at start of new epoch for better multiplier rate, if voted with low rate before.
	/// @param votingPositionId - id of voting position.
	function recomputeDaiVotes(uint256 votingPositionId) public
	{
		require(getCurrentStage() <= Stage.SecondStage, "Wrong stage!");              // Requires to be at second stage of battle epoch.

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		_updateVotingPosition(votingPositionId);
		// _updateVotingRewardDebt(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;
		updateInfo(stakingPositionId);                                                // Updates staking position params from previous epochs.

		uint256 daiNumber = votingPosition.daiInvested;                               // Gets amount of dai from voting position.
		uint256 newVotes = zooFunctions.computeVotesByDai(daiNumber);                 // Recomputes dai to votes.
		uint256 oldVotes = votingPosition.daiVotes;                                   // Gets amount of votes from voting position.

		require(newVotes > oldVotes, "E1");                     // Requires for new votes amount to be bigger than before.

		votingPosition.daiVotes = newVotes;                                           // Records new votes amount from dai.
		votingPosition.votes += newVotes - oldVotes;                                  // Records new votes amount total.
		rewardsForEpoch[stakingPositionId][currentEpoch].votes += newVotes - oldVotes;// Increases rewards for staker position for added amount of votes in this epoch.
		emit RecomputedDaiVotes(currentEpoch, msg.sender, stakingPositionId, votingPositionId, newVotes, oldVotes);
	}

	// todo: check for correct work with change for zoo-mim
	/// @notice Function to recompute votes from zoo.
	/// @param votingPositionId - id of voting position.
	function recomputeZooVotes(uint256 votingPositionId) public
	{
		require(getCurrentStage() == Stage.FourthStage, "Wrong stage!");              // Requires to be at 4th stage.

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		_updateVotingPosition(votingPositionId);
		// _updateVotingRewardDebt(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;
		updateInfo(stakingPositionId);

		uint256 zooNumber = votingPosition.zooInvested * zooVoteRateNominator / zooVoteRateDenominator;                 // Gets amount of zoo invested from voting position.
		uint256 newZooVotes = zooFunctions.computeVotesByZoo(zooNumber);              // Recomputes zoo to votes.
		uint256 oldZooVotes = votingPosition.votes - votingPosition.daiVotes;         // Get amount of votes from zoo.

		require(newZooVotes > oldZooVotes, "E1");               // Requires for new votes amount to be bigger than before.

		votingPosition.votes += newZooVotes - oldZooVotes;                            // Add amount of recently added votes to total votes in voting position.
		rewardsForEpoch[stakingPositionId][currentEpoch].votes += newZooVotes - oldZooVotes; // Adds amount of recently added votes to reward for staker position for current epoch.

		emit RecomputedZooVotes(currentEpoch, msg.sender, stakingPositionId, votingPositionId, newZooVotes, oldZooVotes);
	}

	/// @notice Function to add dai tokens to voting position.
	/// @param votingPositionId - id of voting position.
	/// @param voter - address of voter.
	/// @param amount - amount of dai tokens to add.
	/// @param _yTokens - amount of yTokens from previous position when called with swap.
	function addDaiToVoting(uint256 votingPositionId, address voter, uint256 amount, uint256 _yTokens) public only(nftVotingPosition) returns (uint256 votes)
	{
		require(getCurrentStage() != Stage.ThirdStage, "Wrong stage!");

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;                 // Gets id of staker position.
		require(stakingPositionsValues[stakingPositionId].endEpoch == 0, "E1");       // Requires to be staked.

		_updateVotingPosition(votingPositionId);
		// _updateVotingRewardDebt(votingPositionId);

		votes = zooFunctions.computeVotesByDai(amount);                               // Gets computed amount of votes from multiplier of dai.
		// case for NOT swap.
		if (_yTokens == 0)                                                            // if no _yTokens from another position with swap.
		{
			_yTokens = vault.balanceOf(address(this));
			require(vault.mint(amount) == 0);                                         // Deposits dai to yearn and gets yTokens.
			_yTokens = vault.balanceOf(address(this)) - _yTokens;
		}

		uint256 epoch = currentEpoch;
		if (getCurrentStage() > Stage.SecondStage)
		{
			epoch += 1;
			pendingVotes[votingPositionId] += votes;
			pendingVotesEpoch[votingPositionId] = currentEpoch;
		}
		else
		{
			votingPosition.daiVotes += votes;                                             // Adds computed daiVotes amount from to voting position.
			votingPosition.votes += votes;                                                // Adds computed votes amount to totalVotes amount for voting position.
		}

		votingPosition.yTokensNumber = _calculateVotersYTokensExcludingRewards(votingPositionId) + _yTokens;// Adds yTokens to voting position.
		votingPosition.daiInvested += amount;                                         // Adds amount of dai to voting position.
		votingPosition.startEpoch = epoch;

		updateInfo(stakingPositionId);
		BattleRewardForEpoch storage battleReward = rewardsForEpoch[stakingPositionId][epoch];

		battleReward.votes += votes;              // Adds votes to staker position for current epoch.
		battleReward.yTokens += _yTokens;         // Adds yTokens to rewards from staker position for current epoch.

		battleReward.league = zooFunctions.getNftLeague(battleReward.votes);

		emit AddedDaiToVoting(currentEpoch, voter, stakingPositionId, votingPositionId, amount, votes);
	}

	/// @notice Function to add zoo tokens to voting position.
	/// @param votingPositionId - id of voting position.
	/// @param amount - amount of zoo LP tokens to add.
	function addZooToVoting(uint256 votingPositionId, address voter, uint256 amount) external only(nftVotingPosition) returns (uint256 votes)
	{
		//require(getCurrentStage() == Stage.FourthStage, "Wrong stage!"); // Require turned off cause its moved to voting position contract due to lack of space for bytecode. // Requires to be at 3rd stage.

		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		_updateVotingPosition(votingPositionId);
		// _updateVotingRewardDebt(votingPositionId);                                    // Records current reward for voting position to reward debt.

		uint256 zooVotesFromLP = amount * zooVoteRateNominator / zooVoteRateDenominator; // Gets amount of zoo votes from LP.
		votes = zooFunctions.computeVotesByZoo(zooVotesFromLP);                               // Gets computed amount of votes from multiplier of zoo.
		require(votingPosition.zooInvested + amount <= votingPosition.daiInvested, "E1");// Requires for votes from zoo to be less than votes from dai.

		uint256 stakingPositionId = votingPosition.stakingPositionId;                 // Gets id of staker position.
		updateInfo(stakingPositionId);                                                // Updates staking position params from previous epochs.
		BattleRewardForEpoch storage battleReward = rewardsForEpoch[stakingPositionId][currentEpoch];

		poolWeight[address(0)][currentEpoch] += votes;
		poolWeight[stakingPositionsValues[stakingPositionId].collection][currentEpoch] += votes;

		battleReward.votes += votes;              // Adds votes for staker position.
		votingPositionsValues[votingPositionId].votes += votes;                       // Adds votes to voting position.
		votingPosition.zooInvested += amount;                                         // Adds amount of zoo tokens to voting position.

		battleReward.league = zooFunctions.getNftLeague(battleReward.votes);

		emit AddedZooToVoting(currentEpoch, voter, stakingPositionId, votingPositionId, amount, votes);
	}

	/// @notice Functions to withdraw dai from voting position.
	/// @param votingPositionId - id of voting position.
	/// @param daiNumber - amount of dai to withdraw.
	/// @param beneficiary - address of recipient.
	function withdrawDaiFromVoting(uint256 votingPositionId, address voter, address beneficiary, uint256 daiNumber, bool toSwap) public only(nftVotingPosition)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;               // Gets id of staker position.
		updateInfo(stakingPositionId);                                              // Updates staking position params from previous epochs.

		require(getCurrentStage() == Stage.FirstStage || stakingPositionsValues[stakingPositionId].endEpoch != 0, "Wrong stage!"); // Requires correct stage or nft to be unstaked.
		require(votingPosition.endEpoch == 0, "E1");                  // Requires to be not liquidated yet.

		_updateVotingPosition(votingPositionId);
		// _updateVotingRewardDebt(votingPositionId);
		_subtractYTokensUserForRewardsFromVotingPosition(votingPositionId);

		if (daiNumber >= votingPosition.daiInvested)                                // If withdraw amount more or equal of maximum invested.
		{
			_liquidateVotingPosition(votingPositionId, voter, beneficiary, stakingPositionId, toSwap);// Calls liquidate and ends call.
			return;
		}

		uint256 shares = tokensToShares(daiNumber);                                 // If withdraw amount don't require liquidating, get amount of shares and continue.

		if (toSwap == false)                                                        // If called not through swap.
		{
			require(vault.redeem(shares) == 0);
			_stablecoinTransfer(voter, dai.balanceOf(address(this)));
		}
		BattleRewardForEpoch storage battleReward = rewardsForEpoch[stakingPositionId][currentEpoch];

		uint256 deltaVotes = votingPosition.daiVotes * daiNumber / votingPosition.daiInvested;// Gets average amount of votes withdrawed, cause vote price could be different.
		battleReward.yTokens -= shares;                                          // Decreases amount of shares for epoch.
		battleReward.votes -= deltaVotes;                                        // Decreases amount of votes for epoch for average votes.

		votingPosition.yTokensNumber -= shares;                                     // Decreases amount of shares.
		votingPosition.daiVotes -= deltaVotes;
		votingPosition.votes -= deltaVotes;                                         // Decreases amount of votes for position.
		votingPosition.daiInvested -= daiNumber;                                    // Decreases daiInvested amount of position.

		if (votingPosition.zooInvested > votingPosition.daiInvested)                // If zooInvested more than daiInvested left in position.
		{
			_rebalanceExceedZoo(votingPositionId, stakingPositionId, beneficiary);  // Withdraws excess zoo to save 1-1 dai-zoo proportion.
		}

		battleReward.league = zooFunctions.getNftLeague(battleReward.votes);

		emit WithdrawedDaiFromVoting(currentEpoch, voter, stakingPositionId, beneficiary, votingPositionId, daiNumber);
	}

	function addVotesToVeZoo(address collection, uint256 amount) external only(address(veZoo))
	{
		require(getCurrentStage() != Stage.FifthStage, "Wrong stage!");

		poolWeight[collection][currentEpoch] += amount * zooVoteRateNominator / zooVoteRateDenominator;
		poolWeight[address(0)][currentEpoch] += amount * zooVoteRateNominator / zooVoteRateDenominator;
	}

	function removeVotesFromVeZoo(address collection, uint256 amount) external only(address(veZoo))
	{
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");

		updateInfoAboutStakedNumber(collection);
		poolWeight[collection][currentEpoch] -= amount * zooVoteRateNominator / zooVoteRateDenominator;
		poolWeight[address(0)][currentEpoch] -= amount * zooVoteRateNominator / zooVoteRateDenominator;
	}

	/// @dev Function to liquidate voting position and claim reward.
	/// @param votingPositionId - id of position.
	/// @param voter - address of position owner.
	/// @param beneficiary - address of recipient.
	/// @param stakingPositionId - id of staking position.
	/// @param toSwap - boolean for swap votes, True if called from swapVotes function.
	function _liquidateVotingPosition(uint256 votingPositionId, address voter, address beneficiary, uint256 stakingPositionId, bool toSwap) internal
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];

		uint256 yTokens = votingPosition.yTokensNumber;

		if (toSwap == false)                                         // If false, withdraws tokens from vault for regular liquidate.
		{
			require(vault.redeem(yTokens) == 0);
			_stablecoinTransfer(beneficiary, dai.balanceOf(address(this))); // True when called from swapVotes, ignores withdrawal to re-assign them for another position.
		}

		_withdrawZoo(votingPosition.zooInvested, beneficiary);                      // Even if it is swap, withdraws all zoo.

		votingPosition.endEpoch = currentEpoch;                      // Sets endEpoch to currentEpoch.

		BattleRewardForEpoch storage battleReward = rewardsForEpoch[stakingPositionId][currentEpoch];
		battleReward.votes -= votingPosition.votes;                  // Decreases votes for staking position in current epoch.

		if (battleReward.yTokens >= yTokens)                         // If withdraws less than in staking position.
		{
			battleReward.yTokens -= yTokens;                         // Decreases yTokens for this staking position.
		}
		else
		{
			battleReward.yTokens = 0;                                // Or nullify it if trying to withdraw more yTokens than left in position(because of yTokens current rate)
		}

		// IF there is votes on position AND staking position is active
		if (battleReward.votes == 0 && stakingPositionsValues[stakingPositionId].endEpoch == 0)
		{
			// Move staking position to part, where staked without votes.
			for(uint256 i = 0; i < activeStakerPositions.length; ++i)
			{
				if (activeStakerPositions[i] == stakingPositionId)
				{
					(activeStakerPositions[i], activeStakerPositions[numberOfNftsWithNonZeroVotes - 1]) = (activeStakerPositions[numberOfNftsWithNonZeroVotes - 1], activeStakerPositions[i]);      // Swaps position to end of array
					numberOfNftsWithNonZeroVotes--;                                    // Decrements amount of non-zero positions.
					break;
				}
			}
		}

		battleReward.league = zooFunctions.getNftLeague(battleReward.votes);

		emit LiquidatedVotingPosition(currentEpoch, voter, stakingPositionId, beneficiary, votingPositionId, votingPosition.zooInvested * 995 / 1000, votingPosition.daiInvested);
	}

	function _subtractYTokensUserForRewardsFromVotingPosition(uint256 votingPositionId) internal
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];

		votingPosition.yTokensNumber = _calculateVotersYTokensExcludingRewards(votingPositionId);
		votingPosition.lastEpochYTokensWereDeductedForRewards = currentEpoch;
	}

	/// @dev Calculates voting position's own yTokens - excludes yTokens that was used for rewards
	/// @dev yTokens must be substracted even if voting won in battle (they go to the voting's pending reward)
	/// @param votingPositionId ID of voting to calculate yTokens
	function _calculateVotersYTokensExcludingRewards(uint256 votingPositionId) internal view returns(uint256 yTokens)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;

		yTokens = votingPosition.yTokensNumber;
		uint256 endEpoch = computeLastEpoch(votingPositionId);

		// From user yTokens subtract all tokens that go to the rewards
		// This way allows to withdraw exact same amount of DAI user invested at the start
		for (uint256 i = votingPosition.lastEpochYTokensWereDeductedForRewards; i < endEpoch; ++i)
		{
			if (rewardsForEpoch[stakingPositionId][i].pricePerShareCoef != 0)
			{
				yTokens -= votingPosition.daiInvested * 10**18 / rewardsForEpoch[stakingPositionId][i].pricePerShareCoef;
			}
		}
	}

	/// @dev function to withdraw Zoo number greater than Dai number to save 1-1 dai-zoo proportion.
	/// @param votingPositionId ID of voting to reduce Zoo number
	/// @param stakingPositionId ID of staking to reduce number of votes
	/// @param beneficiary address to withdraw Zoo
	function _rebalanceExceedZoo(uint256 votingPositionId, uint256 stakingPositionId, address beneficiary) internal
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 zooDelta = votingPosition.zooInvested - votingPosition.daiInvested;    // Get amount of zoo exceeding.

		_withdrawZoo(zooDelta, beneficiary);                                           // Withdraws exceed zoo.
		_reduceZooVotes(votingPositionId, stakingPositionId, zooDelta);
	}

	/// @dev function to calculate votes from zoo using average price and withdraw it.
	function _reduceZooVotes(uint256 votingPositionId, uint256 stakingPositionId, uint256 zooNumber) internal
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		StakerPosition storage stakerPosition = stakingPositionsValues[stakingPositionId];
		updateInfoAboutStakedNumber(stakerPosition.collection);

		uint256 zooVotes = votingPosition.votes - votingPosition.daiVotes;             // Calculates amount of votes got from zoo.
		uint256 deltaVotes = zooVotes * zooNumber * zooVoteRateDenominator / zooVoteRateNominator / votingPosition.zooInvested; // Calculates average amount of votes from this amount of zoo.

		votingPosition.votes -= deltaVotes;                                            // Decreases amount of votes.
		votingPosition.zooInvested -= zooNumber;                                       // Decreases amount of zoo invested.
		poolWeight[address(0)][currentEpoch] -= deltaVotes;
		poolWeight[stakerPosition.collection][currentEpoch] -= deltaVotes;

		updateInfo(stakingPositionId);                                                 // Updates staking position params from previous epochs.
		BattleRewardForEpoch storage battleReward = rewardsForEpoch[stakingPositionId][currentEpoch];
		battleReward.votes -= deltaVotes;          // Decreases amount of votes for staking position in current epoch.

		battleReward.league = zooFunctions.getNftLeague(battleReward.votes);
	}

	/// @notice Functions to withdraw zoo from voting position.
	/// @param votingPositionId - id of voting position.
	/// @param zooNumber - amount of zoo to withdraw.
	/// @param beneficiary - address of recipient.
	function withdrawZooFromVoting(uint256 votingPositionId, address voter, uint256 zooNumber, address beneficiary) external only(nftVotingPosition)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		_updateVotingPosition(votingPositionId);
		// _updateVotingRewardDebt(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;                  // Gets id of staker position from this voting position.
		StakerPosition storage stakingPosition = stakingPositionsValues[stakingPositionId];

		require(getCurrentStage() == Stage.FirstStage || stakingPosition.endEpoch != 0, "Wrong stage!"); // Requires correct stage or nft to be unstaked.
		require(votingPosition.endEpoch == 0, "E1");                     // Requires to be not liquidated yet.

		if (zooNumber > votingPosition.zooInvested)                                                   // If trying to withdraw more than invested, withdraws maximum.
		{
			zooNumber = votingPosition.zooInvested;
		}

		_withdrawZoo(zooNumber, beneficiary);
		_reduceZooVotes(votingPositionId, stakingPositionId, zooNumber);

		emit WithdrawedZooFromVoting(currentEpoch, voter, stakingPositionId, votingPositionId, zooNumber, beneficiary);
	}


	/// @notice Function to claim reward in yTokens from voting.
	/// @param votingPositionId - id of voting position.
	/// @param beneficiary - address of recipient of reward.
	function claimRewardFromVoting(uint256 votingPositionId, address voter, address beneficiary) external only(nftVotingPosition) returns (uint256 daiReward)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];

		require(getCurrentStage() == Stage.FirstStage || stakingPositionsValues[votingPosition.stakingPositionId].endEpoch != 0, "Wrong stage!"); // Requires to be at first stage or position should be liquidated.

		updateInfo(votingPosition.stakingPositionId);

		(uint256 yTokenReward, uint256 zooRewards) = getPendingVoterReward(votingPositionId); // Calculates amount of reward in yTokens.

		yTokenReward += votingPosition.yTokensRewardDebt;                                // Adds reward debt, from previous epochs.
		zooRewards += zooTokensRewardDebt[votingPositionId];
		votingPosition.yTokensRewardDebt = 0;                                            // Nullify reward debt.
		zooTokensRewardDebt[votingPositionId] = 0;

		yTokenReward = yTokenReward * 95 / 96; // 95% of income to voter.

		require(vault.redeem(yTokenReward) == 0);                                                      // Withdraws dai from vault for yTokens, minus staker %.
		daiReward = dai.balanceOf(address(this));

		_stablecoinTransfer(beneficiary, daiReward);                             // Transfers voter part of reward.

		BattleRewardForEpoch storage battleReward = rewardsForEpoch[votingPosition.stakingPositionId][currentEpoch];
		if (battleReward.yTokens >= yTokenReward)
		{
			battleReward.yTokens -= yTokenReward;                                        // Subtracts yTokens for this position.
		}
		else
		{
			battleReward.yTokens = 0;
		}

		zoo.transfer(beneficiary, zooRewards);

		votingPosition.lastRewardedEpoch = computeLastEpoch(votingPositionId);           // Records epoch of last reward claimed.

		emit ClaimedRewardFromVoting(currentEpoch, voter, votingPosition.stakingPositionId, beneficiary, daiReward, votingPositionId);
	}

	// /// @dev Updates yTokensRewardDebt of voting.
	// /// @dev Called before every action with voting to prevent increasing share % in battle reward.
	// /// @param votingPositionId ID of voting to be updated.
	// function _updateVotingRewardDebt(uint256 votingPositionId) internal {
	// 	(uint256 reward,uint256 zooRewards) = getPendingVoterReward(votingPositionId);

	// 	if (reward != 0)
	// 	{
	// 		votingPositionsValues[votingPositionId].yTokensRewardDebt += reward;
	// 	}
	// 	if (zooRewards != 0)
	// 	{
	// 		zooTokensRewardDebt[votingPositionId] += zooRewards;
	// 	}

	// 	votingPositionsValues[votingPositionId].lastRewardedEpoch = currentEpoch;
	// }

	/// @notice Function to calculate pending reward from voting for position with this id.
	/// @param votingPositionId - id of voter position in battles.
	/// @return yTokens - amount of pending reward and 2 technical numbers, which must me always equal 0.
	function getPendingVoterReward(uint256 votingPositionId) public view returns (uint256 yTokens, uint256 zooRewards)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];

		uint256 endEpoch = computeLastEpoch(votingPositionId);

		uint256 stakingPositionId = votingPosition.stakingPositionId;                  // Gets staker position id from voter position.

		uint256 pendingVotes = pendingVotes[votingPositionId];
		uint256 pendingVotesEpoch = pendingVotesEpoch[votingPositionId];
		uint256 votes = votingPosition.votes;
		for (uint256 i = votingPosition.lastRewardedEpoch; i < endEpoch; ++i)
		{
			if (i == pendingVotesEpoch + 1 && pendingVotes > 0)
			{
				votes += pendingVotes;
			}

			int256 saldo = rewardsForEpoch[stakingPositionId][i].yTokensSaldo;         // Gets saldo from staker position for every epoch in range.

			if (saldo > 0)
			{
				yTokens += uint256(saldo) * votes / rewardsForEpoch[stakingPositionId][i].votes;         // Calculates yTokens amount for voter.
			}

			BattleRewardForEpoch storage leagueRewards = rewardsForEpoch[stakingPositionId][i];

			if (rewardsForEpoch[stakingPositionId][i].votes > 0)
			{
				zooRewards += leagueRewards.zooRewards * votes / rewardsForEpoch[stakingPositionId][i].votes;         // Calculates yTokens amount for voter.
			}
		}

		return (yTokens, zooRewards);
	}

	/// @notice Function to claim reward for staker.
	/// @param stakingPositionId - id of staker position.
	/// @param beneficiary - address of recipient.
	function claimRewardFromStaking(uint256 stakingPositionId, address staker, address beneficiary) public only(nftStakingPosition) returns (uint256 daiReward)
	{
		StakerPosition storage stakerPosition = stakingPositionsValues[stakingPositionId];
		require(getCurrentStage() == Stage.FirstStage || stakerPosition.endEpoch != 0, "Wrong stage!"); // Requires to be at first stage in battle epoch.

		updateInfo(stakingPositionId);
		(uint256 yTokenReward, uint256 end) = getPendingStakerReward(stakingPositionId);
		stakerPosition.lastRewardedEpoch = end;                                               // Records epoch of last reward claim.

		require(vault.redeem(yTokenReward) == 0);                                                           // Gets reward from yearn.
		daiReward = dai.balanceOf(address(this));
		_stablecoinTransfer(beneficiary, daiReward);

		emit ClaimedRewardFromStaking(currentEpoch, staker, stakingPositionId, beneficiary, yTokenReward, daiReward);
	}

	/// @notice Function to get pending reward fo staker for this position id.
	/// @param stakingPositionId - id of staker position.
	/// @return stakerReward - reward amount for staker of this nft.
	function getPendingStakerReward(uint256 stakingPositionId) public view returns (uint256 stakerReward, uint256 end)
	{
		StakerPosition storage stakerPosition = stakingPositionsValues[stakingPositionId];
		uint256 endEpoch = stakerPosition.endEpoch;                                           // Gets endEpoch from position.

		end = endEpoch == 0 ? currentEpoch : endEpoch;                                        // Sets end variable to endEpoch if it non-zero, otherwise to currentEpoch.

		for (uint256 i = stakerPosition.lastRewardedEpoch; i < end; ++i)
		{
			int256 saldo = rewardsForEpoch[stakingPositionId][i].yTokensSaldo;                // Get saldo from staker position.

			if (saldo > 0)
			{
				stakerReward += uint256(saldo / 96);                                          // Calculates reward for staker: 1% = 1 / 96
			}
		}
	}

	/// @notice Function for pair nft for battles.
	/// @param stakingPositionId - id of staker position.
	function pairNft(uint256 stakingPositionId) external
	{
		require(getCurrentStage() == Stage.ThirdStage, "Wrong stage!");                       // Requires to be at 3 stage of battle epoch.

		updateInfo(stakingPositionId);
		BattleRewardForEpoch storage battleReward1 = rewardsForEpoch[stakingPositionId][currentEpoch];

		// this require makes impossible to pair if there are no available pair. // require(numberOfNftsWithNonZeroVotes / 2 > nftsInGame / 2, "E1");            // Requires enough nft for pairing.
		uint256 index1;                                                                       // Index of nft paired for.
		uint256[] memory leagueList = new uint256[](numberOfNftsWithNonZeroVotes);
		uint256 nftsInSameLeague = 0;
		bool idFound;

		// Find first staking position and get list of opponents from league for index2
		for (uint256 i = nftsInGame; i < numberOfNftsWithNonZeroVotes; ++i)
		{
			updateInfo(activeStakerPositions[i]);
			if (activeStakerPositions[i] == stakingPositionId)
			{
				index1 = i;
				idFound = true;
				continue;
				// break;
			}
			// In the same league
			else if (battleReward1.league == rewardsForEpoch[activeStakerPositions[i]][currentEpoch].league)
			{
				leagueList[nftsInSameLeague] = activeStakerPositions[i];
				nftsInSameLeague++;
			}
		}
		require(idFound, "E1");

		(activeStakerPositions[index1], activeStakerPositions[nftsInGame]) = (activeStakerPositions[nftsInGame], activeStakerPositions[index1]);// Swaps nftsInGame with index.
		nftsInGame++;                                                                         // Increases amount of paired nft.

		uint256 stakingPosition2;
		battleReward1.tokensAtBattleStart = sharesToTokens(battleReward1.yTokens);            // Records amount of yTokens on the moment of pairing for candidate.
		battleReward1.pricePerShareAtBattleStart = vault.exchangeRateCurrent();

		if (nftsInSameLeague != 0)
		{
			uint256 index2;
			stakingPosition2 = leagueList[0];
			if (nftsInSameLeague > 1)
			{
				stakingPosition2 = leagueList[zooFunctions.computePseudoRandom() % nftsInSameLeague];
			}

			for (uint256 i = nftsInGame; i < numberOfNftsWithNonZeroVotes; ++i)
			{
				if (activeStakerPositions[i] == stakingPosition2)
				{
					index2 = i;
				}
			}

			//updateInfo(stakingPosition2);
			BattleRewardForEpoch storage battleReward2 = rewardsForEpoch[stakingPosition2][currentEpoch];
			battleReward2.tokensAtBattleStart = sharesToTokens(battleReward2.yTokens);            // Records amount of yTokens on the moment of pairing for opponent.
			battleReward2.pricePerShareAtBattleStart = vault.exchangeRateCurrent();

			(activeStakerPositions[index2], activeStakerPositions[nftsInGame]) = (activeStakerPositions[nftsInGame], activeStakerPositions[index2]); // Swaps nftsInGame with index of opponent.
			nftsInGame++;                                                                         // Increases amount of paired nft.
		}
		else
		{
			stakingPosition2 = 0;
		}

		pairsInEpoch[currentEpoch].push(NftPair(stakingPositionId, stakingPosition2, false, false));// Pushes nft pair to array of pairs.
		uint256 pairIndex = getNftPairLength(currentEpoch) - 1;

		emit PairedNft(currentEpoch, stakingPositionId, stakingPosition2, pairIndex);
	}

	/// @notice Function to request random once per epoch.
	function requestRandom() public
	{
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");                       // Requires to be at 5th stage.

		zooFunctions.requestRandomNumber();                                                 // Calls generate random number from chainlink or blockhash.
	}

	/// @notice Function for chosing winner for pair by its index in array.
	/// @notice returns error if random number for deciding winner is NOT requested OR fulfilled in ZooFunctions contract
	/// @param pairIndex - index of nft pair.
	function chooseWinnerInPair(uint256 pairIndex) external
	{
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");                     // Requires to be at 5th stage.
		NftPair storage pair = pairsInEpoch[currentEpoch][pairIndex];
		require(pair.playedInEpoch == false, "E1");                      // Requires to be not paired before.

		uint256 randomNumber = zooFunctions.getRandomResult();
		uint256 votes1 = rewardsForEpoch[pair.token1][currentEpoch].votes;
		uint256 votes2 = rewardsForEpoch[pair.token2][currentEpoch].votes;
		playedVotesByEpoch[currentEpoch] += votes1 + votes2;

		if (pair.token2 == 0)
		{
			votes2 = votes1;
		}

		pair.win = zooFunctions.decideWins(votes1, votes2, randomNumber);                   // Calculates winner and records it, 50/50 result
		// Getting winner and loser to calculate rewards
		(uint256 winner, uint256 loser) = pair.win? (pair.token1, pair.token2) : (pair.token2, pair.token1);
		_calculateBattleRewards(winner, loser);

		numberOfPlayedPairsInEpoch[currentEpoch]++;                                         // Increments amount of pairs played this epoch.
		pair.playedInEpoch = true;

		emit ChosenWinner(currentEpoch, pair.token1, pair.token2, pair.win, pairIndex, numberOfPlayedPairsInEpoch[currentEpoch]); // Emits ChosenWinner event.

		if (numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length)
		{
			updateEpoch();                                                                  // calls updateEpoch if winner determined in every pair.
		}
	}

	/// @dev Contains calculation logic of battle rewards
	/// @param winner stakingPositionId of NFT that WON in battle
	/// @param loser stakingPositionId of NFT that LOST in battle
	function _calculateBattleRewards(uint256 winner, uint256 loser) internal
	{
		BattleRewardForEpoch storage winnerRewards = rewardsForEpoch[winner][currentEpoch];
		BattleRewardForEpoch storage loserRewards = rewardsForEpoch[loser][currentEpoch];

		BattleRewardForEpoch storage winnerRewards1 = rewardsForEpoch[winner][currentEpoch + 1];
		BattleRewardForEpoch storage loserRewards1 = rewardsForEpoch[loser][currentEpoch + 1];

		if (winner == 0 || loser == 0) // arena 50-50 case
		{
			if (winner == 0) { // Battle Arena won
				// Take yield
				uint256 income = loserRewards.yTokens - tokensToShares(loserRewards.tokensAtBattleStart);
				require(vault.redeem(income) == 0);
				_stablecoinTransfer(treasury, dai.balanceOf(address(this)));
			} else {
			// Grant Zoo
				winnerRewards.zooRewards += zooFunctions.getLeagueZooRewards(winnerRewards.league);
			}
			return;
		}

		// Skip if price per share didn't change since pairing
		uint256 currentPps = vault.exchangeRateCurrent();
		if (winnerRewards.pricePerShareAtBattleStart == currentPps)
		{
			return;
		}

		winnerRewards.pricePerShareCoef = currentPps * winnerRewards.pricePerShareAtBattleStart / (currentPps - winnerRewards.pricePerShareAtBattleStart);
		loserRewards.pricePerShareCoef = winnerRewards.pricePerShareCoef;

		// Income = yTokens at battle end - yTokens at battle start
		uint256 income1 = winnerRewards.yTokens - tokensToShares(winnerRewards.tokensAtBattleStart);
		uint256 income2 = loserRewards.yTokens - tokensToShares(loserRewards.tokensAtBattleStart);

		require(vault.redeem(((income1 + income2) / 25)) == 0);           // Withdraws dai from vault for yTokens, minus staker %.

		uint256 daiReward = dai.balanceOf(address(this));
		_stablecoinTransfer(treasury, daiReward);                                       // Transfers treasury part. 4 / 100 == 4%

		winnerRewards.yTokensSaldo += int256(((income1 + income2) * 96 / 100));
		loserRewards.yTokensSaldo -= int256(income2);

		winnerRewards1.yTokens = winnerRewards.yTokens + income2 - ((income1 + income2) / 25);
		loserRewards1.yTokens = loserRewards.yTokens - income2; // Withdraw reward amount.

		stakingPositionsValues[winner].lastUpdateEpoch = currentEpoch + 1;          // Update lastUpdateEpoch to next epoch.
		stakingPositionsValues[loser].lastUpdateEpoch = currentEpoch + 1;           // Update lastUpdateEpoch to next epoch.
		winnerRewards1.votes += winnerRewards.votes;                                 // Update votes for next epoch.
		loserRewards1.votes += loserRewards.votes;                                   // Update votes for next epoch.

		winnerRewards1.league = zooFunctions.getNftLeague(winnerRewards1.votes);	// Update league for next epoch.
		loserRewards1.league = zooFunctions.getNftLeague(loserRewards1.votes);		// Update league for next epoch.
	}

	/// @notice Function for updating position from lastUpdateEpoch, in case there was no battle with position for a while.
	function updateInfo(uint256 stakingPositionId) public
	{
		StakerPosition storage position = stakingPositionsValues[stakingPositionId];
		uint256 lastUpdateEpoch = position.lastUpdateEpoch;                         // Get lastUpdateEpoch for position.
		if (lastUpdateEpoch == currentEpoch)                                        // If already updated in this epoch - skip.
			return;

		for (; lastUpdateEpoch < currentEpoch; ++lastUpdateEpoch)
		{
			BattleRewardForEpoch storage rewardOfCurrentEpoch = rewardsForEpoch[stakingPositionId][lastUpdateEpoch + 1];
			BattleRewardForEpoch storage rewardOflastUpdateEpoch = rewardsForEpoch[stakingPositionId][lastUpdateEpoch];

			rewardOfCurrentEpoch.votes += rewardOflastUpdateEpoch.votes;             // Get votes from lastUpdateEpoch.
			rewardOfCurrentEpoch.yTokens += rewardOflastUpdateEpoch.yTokens;         // Get yTokens from lastUpdateEpoch.

			rewardOfCurrentEpoch.league = zooFunctions.getNftLeague(rewardOfCurrentEpoch.votes);
		}

		position.lastUpdateEpoch = currentEpoch;                                    // Set lastUpdateEpoch to currentEpoch.
	}

	function _updateVotingPosition(uint256 votingPositionId) internal
	{
		VotingPosition storage position = votingPositionsValues[votingPositionId];

		(uint256 reward, uint256 zooRewards) = getPendingVoterReward(votingPositionId);
		voterIncentiveDebt[votingPositionId] += computeInvenctiveRewardForVoter(votingPositionId);

		if (reward != 0)
		{
			position.yTokensRewardDebt += reward;
		}
		if (zooRewards != 0)
		{
			zooTokensRewardDebt[votingPositionId] += zooRewards;
		}

		position.lastRewardedEpoch = currentEpoch;

		if (pendingVotesEpoch[votingPositionId] == 0 || pendingVotesEpoch[votingPositionId] == currentEpoch) // If already updated in this epoch - skip.
			return;

		uint256 votes = pendingVotes[votingPositionId];
		position.daiVotes += votes;
		position.votes += votes;

		pendingVotes[votingPositionId] = 0;
		pendingVotesEpoch[votingPositionId] = 0;
	}

	/// @notice Function to increment epoch.
	function updateEpoch() public {
		require(getCurrentStage() == Stage.FifthStage, "Wrong stage!");             // Requires to be at fourth stage.
		require(block.timestamp >= epochStartDate + epochDuration || numberOfPlayedPairsInEpoch[currentEpoch] == pairsInEpoch[currentEpoch].length); // Requires fourth stage to end, or determine every pair winner.

		zooFunctions = IZooFunctions(zooGovernance.zooFunctions());                 // Sets ZooFunctions to contract specified in zooGovernance.

		epochStartDate = block.timestamp;                                           // Sets start date of new epoch.
		currentEpoch++;                                                             // Increments currentEpoch.
		epochsStarts[currentEpoch] = block.timestamp;                               // Records timestamp of new epoch start for ve-Zoo.
		nftsInGame = 0;                                                             // Nullifies amount of paired nfts.
		poolWeight[address(0)][currentEpoch] += poolWeight[address(0)][currentEpoch - 1];

		numberOfNftsWithNonZeroVotes += numberOfNftsWithNonZeroVotesPending;
		numberOfNftsWithNonZeroVotesPending = 0;

		zooFunctions.resetRandom();     // Resets random in zoo functions.

		(firstStageDuration, secondStageDuration, thirdStageDuration, fourthStageDuration, fifthStageDuration, epochDuration) = zooFunctions.getStageDurations();

		emit EpochUpdated(block.timestamp, currentEpoch);
	}

	/// @notice Function to calculate incentive reward from ve-Zoo for voter.
	function calculateIncentiveRewardForVoter(uint256 votingPositionId) external only(nftVotingPosition) returns (uint256 reward)
	{
		_updateVotingPosition(votingPositionId);
		reward = computeInvenctiveRewardForVoter(votingPositionId) + voterIncentiveDebt[votingPositionId];
		voterIncentiveDebt[votingPositionId] = 0;
	}

	function computeInvenctiveRewardForVoter(uint256 votingPositionId) internal returns (uint256 reward)
	{
		VotingPosition storage votingPosition = votingPositionsValues[votingPositionId];
		uint256 stakingPositionId = votingPosition.stakingPositionId;

		address collection = stakingPositionsValues[stakingPositionId].collection;
		updateInfo(stakingPositionId);
		updateInfoAboutStakedNumber(collection);                                      // Updates info about collection.
		
		uint256 lastEpoch = computeLastEpoch(votingPositionId); // Last epoch
		if (lastEpoch > endEpochOfIncentiveRewards)
			lastEpoch = endEpochOfIncentiveRewards;
		if (pendingVotesEpoch[votingPositionId] != 0 && lastEpoch > pendingVotesEpoch[votingPositionId])
			lastEpoch = pendingVotesEpoch[votingPositionId];

		for (uint256 i = votingPosition.lastEpochOfIncentiveReward; i < lastEpoch; ++i)
		{
			if (poolWeight[address(0)][i] != 0 && rewardsForEpoch[stakingPositionId][i].yTokensSaldo != 0) // Check that collection has non-zero weight in veZoo and nft played in battle.
				reward += baseVoterReward * votingPosition.daiVotes * poolWeight[collection][i] / (poolWeight[address(0)][i] * playedVotesByEpoch[i]);
		}

		votingPosition.lastEpochOfIncentiveReward = lastEpoch;
	}

	/// @notice Function to calculate incentive reward from ve-Zoo for staker.
	function calculateIncentiveRewardForStaker(uint256 stakingPositionId) external only(nftStakingPosition) returns (uint256 reward)
	{
		StakerPosition storage stakingPosition = stakingPositionsValues[stakingPositionId];

		address collection = stakingPosition.collection;                              // Gets nft collection.
		updateInfo(stakingPositionId);                                                // Updates staking position params from previous epochs.
		updateInfoAboutStakedNumber(collection);                                      // Updates info about collection.

		uint256 end = stakingPosition.endEpoch == 0 ? currentEpoch : stakingPosition.endEpoch;// Get recorded end epoch if it's not 0, or current epoch.
		if (end > endEpochOfIncentiveRewards)
			end = endEpochOfIncentiveRewards;

		for (uint256 i = stakingPosition.lastEpochOfIncentiveReward; i < end; ++i)
		{
			if (poolWeight[address(0)][i] != 0)
				reward += baseStakerReward * poolWeight[collection][i] / (poolWeight[address(0)][i] * numberOfStakedNftsInCollection[i][collection]);
		}

		stakingPosition.lastEpochOfIncentiveReward = currentEpoch;

		return reward;
	}

	/// @notice Function to get last epoch.
	function computeLastEpoch(uint256 votingPositionId) public view returns (uint256 lastEpochNumber)
	{
		VotingPosition storage votingposition = votingPositionsValues[votingPositionId];
		//uint256 stakingPositionId = votingposition.stakingPositionId;  // Gets staker position id from voter position.
		uint256 lastEpochOfStaking = stakingPositionsValues[votingposition.stakingPositionId].endEpoch;        // Gets endEpoch from staking position.

		// Staking - finished, Voting - finished
		if (lastEpochOfStaking != 0 && votingposition.endEpoch != 0)
		{
			lastEpochNumber = Math.min(lastEpochOfStaking, votingposition.endEpoch);
		}
		// Staking - finished, Voting - existing
		else if (lastEpochOfStaking != 0)
		{
			lastEpochNumber = lastEpochOfStaking;
		}
		// Staking - exists, Voting - finished
		else if (votingposition.endEpoch != 0)
		{
			lastEpochNumber = votingposition.endEpoch;
		}
		// Staking - exists, Voting - exists
		else
		{
			lastEpochNumber = currentEpoch;
		}
	}

	function updateInfoAboutStakedNumber(address collection) public returns (uint256 actualWeight)
	{
		uint256 lastUpdateEpoch = lastUpdatesOfStakedNumbers[collection];
		if (lastUpdateEpoch == currentEpoch)
			return poolWeight[collection][currentEpoch];

		uint256 i = lastUpdateEpoch + 1;
		for (; i <= currentEpoch; ++i)
		{
			numberOfStakedNftsInCollection[i][collection] += numberOfStakedNftsInCollection[i - 1][collection];
			poolWeight[collection][i] += poolWeight[collection][i - 1];
		}

		lastUpdatesOfStakedNumbers[collection] = currentEpoch;
		return poolWeight[collection][currentEpoch];
	}

	/// @notice Internal function to calculate amount of zoo to burn and withdraw.
	function _withdrawZoo(uint256 zooAmount, address beneficiary) internal
	{
		uint256 zooWithdraw = zooAmount * 995 / 1000; // Calculates amount of zoo to withdraw.

		lpZoo.transfer(beneficiary, zooWithdraw);                                           // Transfers lp to beneficiary.
		lpZoo.transfer(treasury, zooAmount * 5 / 1000);
	}

	function _stablecoinTransfer(address who, uint256 value) internal
	{
		if (value > 0)
			dai.transfer(who, value);
	}

	/// @notice Function to view current stage in battle epoch.
	/// @return stage - current stage.
	function getCurrentStage() public view returns (Stage)
	{
		uint256 time = epochStartDate + firstStageDuration;
		if (block.timestamp < time)
		{
			return Stage.FirstStage; // Staking stage
		}

		time += secondStageDuration;
		if (block.timestamp < time)
		{
			return Stage.SecondStage; // Dai vote stage.
		}

		time += thirdStageDuration;
		if (block.timestamp < time)
		{
			return Stage.ThirdStage; // Pair stage.
		}

		time += fourthStageDuration;
		if (block.timestamp < time)
		{
			return Stage.FourthStage; // Zoo vote stage.
		}
		else
		{
			return Stage.FifthStage; // Choose winner stage.
		}
	}
}

pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface VaultAPI {
	function mint(uint256 mintAmount) external returns (uint256);

	function redeem(uint redeemTokens) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function transfer(address who, uint256 amount) external returns (bool);

	function increaseMockBalance() external;

	function balanceOf(address who) external view returns (uint256);
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

/// @title interface of Zoo functions contract.
interface IZooFunctions {

	/// @notice returns random number.
	function randomResult() external view returns(uint256 random);

	/// @notice returns league of nft.
	function getNftLeague(uint256 votes) external view returns(uint8);

	/// @notice returns league rewards.
	function getLeagueZooRewards(uint8 league) external returns(uint256);

	/// @notice returns arena fee.
	function getArenaFee() external returns(uint256);

	/// @notice sets random number in battles back to zero.
	function resetRandom() external;

	function randomFulfilled() external view returns(bool);

	/// @notice Function for choosing winner in battle.
	function decideWins(uint256 votesForA, uint256 votesForB, uint256 random) external view returns (bool);

	/// @notice Function for generating random number.
	function requestRandomNumber() external;

	/// @notice Function for getting random number.
	function getRandomResult() external returns(uint256);

	/// @notice Function for getting random number for selected epoch (historical).
	function getRandomResultByEpoch(uint256 epoch) external returns(uint256);

	function computePseudoRandom() external view returns (uint256);

	/// @notice Function for calculating voting with Dai in vote battles.
	function computeVotesByDai(uint256 amount) external view returns (uint256);

	/// @notice Function for calculating voting with Zoo in vote battles.
	function computeVotesByZoo(uint256 amount) external view returns (uint256);

	function firstStageDuration() external view returns (uint256);

	function secondStageDuration() external view returns (uint256);

	function thirdStageDuration() external view returns (uint256);

	function fourthStageDuration() external view returns (uint256);

	function fifthStageDuration() external view returns (uint256);

	function getStageDurations() external view returns (uint256, uint256, uint256, uint256, uint256, uint256 epochDuration);
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "IZooFunctions.sol";
import "Ownable.sol";

/// @title Contract ZooGovernance.
/// @notice Contract for Zoo Dao vote proposals.
contract ZooGovernance is Ownable {

	address public zooFunctions;                    // Address of contract with Zoo functions.

	/// @notice Contract constructor.
	/// @param baseZooFunctions - address of baseZooFunctions contract.
	/// @param aragon - address of aragon zoo dao agent.
	constructor(address baseZooFunctions, address aragon) {

		zooFunctions = baseZooFunctions;

		transferOwnership(aragon);                  // Sets owner to aragon.
	}

	/// @notice Function for vote for changing Zoo fuctions.
	/// @param newZooFunctions - address of new zoo functions contract.
	function changeZooFunctionsContract(address newZooFunctions) external onlyOwner
	{
		zooFunctions = newZooFunctions;
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "ERC20.sol";
import "SafeERC20.sol";
import "IERC4626.sol";
import "Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: Deposits and withdrawals may incur unexpected slippage. Users should verify that the amount received of
 * shares or assets is as expected. EOAs should operate through a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _decimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _decimals = success ? assetDecimals : super.decimals();
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).call(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are read from the underlying asset in the constructor and cached. If this fails (e.g., the asset
     * has not been created yet), the cached value is set to a default obtained by `super.decimals()` (which depends on
     * inheritance but is most likely 18). Override this function in order to set a guaranteed hardcoded value.
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}. */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is вЂњmanagedвЂќ by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the вЂњper-userвЂќ price-per-share, and instead should reflect the
     * вЂњaverage-userвЂ™sвЂќ price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the вЂњper-userвЂќ price-per-share, and instead should reflect the
     * вЂњaverage-userвЂ™sвЂќ price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the VaultвЂ™s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the VaultвЂ™s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}