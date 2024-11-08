// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./utils/AssetTransfer.sol";

contract NftLottery is Ownable,ReentrancyGuard,ERC721Holder{
    enum PrizeType {
        ETH,
        ERC20,
        ERC721
    }

    struct Prize {
        address asset;
        uint amount;
        uint tokenId;
        PrizeType prizeType;
    }

    struct LotteryList {
        uint luckyTokenId;
        address winner;
        Prize prize;
    }

    uint private immutable _prizeCount;
    address private _lotteryNft;

    mapping(uint => uint) private _phaseLotteryTime; //期数-开奖时间
    mapping(uint => Prize[]) private _phasePrizes;//期数-奖项集合映射关系
    mapping(uint => LotteryList[]) private _phaseLotteryLists;//期数-中奖名单映射关系

    event ResetLotteryNft(address indexed operator, address oldLotteryNft, address newLotteryNft);
    event PaymentReceived(address indexed sender,uint amount);
    event ClaimPrize(address indexed winner, uint phase, uint rank, uint luckyTokenId);
    event WithdrawAsset(address indexed operator, address indexed asset, address indexed receiver, uint amount);

    constructor(address lotteryNft, uint prizeCount) {
        require(lotteryNft != address(0) ,"nft is the zero address");
        _lotteryNft = lotteryNft;
        _prizeCount = prizeCount;
    }

    function resetLotteryNft(address lotteryNft) external onlyOwner{
        address oldLotteryNft = _lotteryNft;
        _lotteryNft = lotteryNft;

        emit ResetLotteryNft(msg.sender, oldLotteryNft, lotteryNft);
    }

    function prizeCount() public view returns(uint){
        return _prizeCount;
    }

    function lotteryNft() public view returns(address){
        return _lotteryNft;
    }

    function phaseIsLottery(uint phase) public view returns(bool){
        return _phaseLotteryTime[phase] >0;
    }

    function phaseIsExpire(uint phase) public view returns(bool){
        if(!phaseIsLottery(phase)){
            return false;
        }

        return _phaseLotteryTime[phase]+ 24*60*60 < block.timestamp;
    }

    function phasePrizes(uint phase, uint index) public view returns(Prize memory){
        return _phasePrizes[phase][index];
    }

    function phaseLotteryLists(uint phase, uint index) public view returns(LotteryList memory){
        return _phaseLotteryLists[phase][index];
    }

    //20230710,[["0x0000000000000000000000000000000000000000",10000000,0,0],["0x0000000000000000000000000000000000000000",10000000,0,0],["0x0000000000000000000000000000000000000000",10000000,0,0],["0x0000000000000000000000000000000000000000",10000000,0,0],["0x0000000000000000000000000000000000000000",10000000,0,0]]
    function setPhasePrizes(uint _phase, Prize[] calldata _prizes) external onlyOwner{
        require(!phaseIsLottery(_phase),"Prize has been drawn");
        require(_prizes.length == prizeCount(),"The number of prizes does not match");

        delete _phasePrizes[_phase];
        Prize[] storage prizes = _phasePrizes[_phase];

        for(uint i=0;i<_prizes.length;i++){
            Prize memory _prize = _prizes[i];
            prizes.push(_prize);
        }
    }

    //开奖
    //20230710,[1,2,3,4,5]
    function lottery(uint _phase, uint[] calldata _luckyTokenIds) external onlyOwner{
        Prize[] memory prizes = _phasePrizes[_phase];
        require(prizes.length == prizeCount(),"The draw hasn't started yet");
        require(_luckyTokenIds.length == prizeCount(),"The number of tokenIds does not match");
        require(!phaseIsLottery(_phase),"Prize has been drawn");

        LotteryList[] storage lotteryLists = _phaseLotteryLists[_phase];
        for(uint i= 0; i< _luckyTokenIds.length; i++){
            uint _luckyTokenId = _luckyTokenIds[i];
            Prize memory prize = prizes[i];

            LotteryList memory lotteryList = LotteryList({
                luckyTokenId: _luckyTokenId,
                winner: address(0),
                prize: prize
            });

            lotteryLists.push(lotteryList);
        }
        _phaseLotteryTime[_phase] = block.timestamp;
    }

    //兑奖
    function claimPrize(uint _phase) external nonReentrant{
        address winner = msg.sender;
        require(isUserLottery(_phase, winner),"Losing lottery");
        require(!phaseIsExpire(_phase),"The claim has expired");

        LotteryList[] storage lotteryLists = _phaseLotteryLists[_phase];
        for(uint i=0; i< lotteryLists.length; i++){
            LotteryList storage lotteryList = lotteryLists[i];
            //已领取过
            if(lotteryList.winner != address(0)){
                continue;
            }

            uint256 tokenId = lotteryList.luckyTokenId;
            //该中奖的tokenId的所有者不是领奖人
            if(IERC721(_lotteryNft).ownerOf(tokenId) != winner){
                continue;
            }

            lotteryList.winner = winner;

            Prize memory prize = lotteryList.prize;
            if(PrizeType.ETH == prize.prizeType || PrizeType.ERC20 == prize.prizeType){
                AssetTransfer.coinReward(winner, prize.asset, prize.amount);
            }else if(PrizeType.ERC721 == prize.prizeType){
                IERC721(prize.asset).safeTransferFrom(address(this), winner, prize.tokenId);
            }else{
                revert("NftLottery: Unknown prize type");
            }

            emit ClaimPrize(winner, _phase, (i+1), tokenId);
        }
    }

    //用户是否已中奖
    function isUserLottery(uint _phase, address _user) public view returns(bool){
        bool[] memory _prizeLResults = getUserLotteryResults(_phase, _user);
        for(uint i=0; i<_prizeLResults.length;i++){
            if(_prizeLResults[i]){
                return true;
            }
        }
        return false;
    }

    //获取用户中奖结果集
    function getUserLotteryResults(uint _phase, address _user) public view returns(bool[] memory){
        bool[] memory _lotteryResults = new bool[](prizeCount());
        if(!phaseIsLottery(_phase)){
            return _lotteryResults;
        }

        LotteryList[] memory lotteryLists = _phaseLotteryLists[_phase];
        for(uint i=0; i< lotteryLists.length; i++){
            LotteryList memory lotteryList = lotteryLists[i];
            if(isClaimPrize(_phase, i)){
                if(lotteryList.winner == _user){
                    _lotteryResults[i] = true;
                }
            }else{
                if(IERC721(_lotteryNft).ownerOf(lotteryList.luckyTokenId) == _user){
                    _lotteryResults[i] = true;
                }
            }
        }

        return _lotteryResults;
    }

    //是否已兑奖
    function isClaimPrize(uint _phase, uint _index) public view returns(bool){
        if(!phaseIsLottery(_phase)){
            return false;
        }

        LotteryList memory lotteryList = phaseLotteryLists(_phase,_index);
        return lotteryList.winner != address(0);
    }

    function withdraw(address _asset, address _to, uint256 _amount) public onlyOwner{
        require(_to != address(0),"WithdrawAsset: _to the zero address");
        uint256 amount = _asset == address(0) ? address(this).balance : IERC20(_asset).balanceOf(address(this));
        require(_amount >0 && _amount <= amount);
        AssetTransfer.coinReward(_to, _asset, _amount);

        emit WithdrawAsset(msg.sender, _to, _asset, _amount);
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library AssetTransfer {

    function coinCost(address to, address coin, uint256 amount) internal{
        if(amount == 0 ){
            return;
        }
        if(coin == address(0)){
            require(msg.value >= amount, "The ether value sent is not correct");
            payable(to).transfer(msg.value);//retransfer to receiver
        }else{
            IERC20(coin).transferFrom(msg.sender, to, amount);
        }
    }

    function coinReward(address to, address coin, uint256 amount) internal{
        if(amount == 0 ){
            return;
        }
        if(coin == address(0)){
            payable(to).transfer(amount);
        }else{
            IERC20(coin).transfer(to, amount);
        }
    }
}