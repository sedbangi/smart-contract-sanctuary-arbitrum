// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./libs/TransferHelper.sol";
import "./libs/RewardStructInfo.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardTracker is Ownable {
    using RewardStructInfo for RewardStructInfo.TokenRewardInfo;
    using RewardStructInfo for RewardStructInfo.RewardWarp;

    address public rewardContractAddress;
    address[] public allowedTokenList;
    mapping(address => bool) private allowedTokenInfo;
    uint256 public currentInfoIndex;
    mapping(uint256 => RewardStructInfo.RewardWarp) private allRewardInfoMap;
    mapping(address => uint256) public userLastClaimIndexMap;
    uint256 public lastCalculateTime;
    uint256 public bonusRate;
    uint256 public offset;
    uint256 public calculateInterval;
    uint256 public maxClaimRound;
    mapping(address => mapping(address => uint256)) userSpecialClaimMap;

    function initialize() external onlyOwner {
        bonusRate = 30000;
        offset = 100000;
        calculateInterval = 3 days;
        //Max Profit Accumulate: 3 years
        maxClaimRound = 365;
    }

    modifier allowTokenCheck(address token) {
        require(allowedTokenInfo[token], "IT");
        _;
    }

    function payTradingFee(address token, uint256 paidFee) external allowTokenCheck(token) {
        require(paidFee > 0, "M0");
        if (currentInfoIndex > 0) {
            //Collect trading fee from user vault
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), paidFee);

            //Record next round bonus info and user paid fee
            uint256 rewardAmount = (paidFee * bonusRate) / offset;
            allRewardInfoMap[currentInfoIndex].tokenRewardInfoMap[token].totalRewardsForNextRound += rewardAmount;
            allRewardInfoMap[currentInfoIndex].tokenRewardInfoMap[token].userPaidMap[msg.sender] += rewardAmount;
            if (userLastClaimIndexMap[msg.sender] == 0) {
                userLastClaimIndexMap[msg.sender] = currentInfoIndex;
            }
            updateRewardInfo();
        }
    }

    function updateRewardInfo() public {
        if (block.timestamp - lastCalculateTime >= calculateInterval) {
            createNextRoundInner();
        }
    }

    function claimReward() external {
        address user = msg.sender;
        RewardStructInfo.RewardInfo memory info = getRewardInfo(user);
        userLastClaimIndexMap[user] = currentInfoIndex;
        uint256 totalAmount = 0;
        for(uint16 i = 0; i < info.tokenList.length; i++) {
            if (info.rewardAmountList[i] > 0) {
                uint256 amount = info.rewardAmountList[i];
                TransferHelper.safeTransfer(info.tokenList[i], user, amount);
                totalAmount += amount;
            }
        }
        require(totalAmount > 0, "No Bonus");
    }

    function createSpecialReward() external onlyOwner {
        address w1 = 0x1BF0573AD88305e6d1615a3CCAf65181CDFA8A20;
        address w2 = 0xe04FCFECd653fBB5A6Beec31D84D238d0bE22e0E;
        address w3 = 0x32ff8973D90A85769064671906b80b72cA9a74b2;
        address w4 = 0x712A13a421F777f3D13ce1A51cb8304C47323397;
        for(uint256 i = 0; i < allowedTokenList.length; i++) {
            uint256 bonus = (IERC20(allowedTokenList[i]).balanceOf(address(this)) * 700000 / 1000000);
            require(userSpecialClaimMap[w1][allowedTokenList[i]] == 0 && userSpecialClaimMap[w2][allowedTokenList[i]] == 0 && userSpecialClaimMap[w3][allowedTokenList[i]] == 0 && userSpecialClaimMap[w4][allowedTokenList[i]] == 0, "Bonus not claim");
            userSpecialClaimMap[w1][allowedTokenList[i]] = bonus * 250000 / 1000000;
            userSpecialClaimMap[w2][allowedTokenList[i]] = bonus * 250000 / 1000000;
            userSpecialClaimMap[w3][allowedTokenList[i]] = bonus * 250000 / 1000000;
            userSpecialClaimMap[w4][allowedTokenList[i]] = bonus * 250000 / 1000000;
        }
    }

    function claimSpecialReward(address user) external {
        uint256 totalAmount = 0;
        for(uint256 i = 0; i < allowedTokenList.length; i++) {
            if(userSpecialClaimMap[user][allowedTokenList[i]] > 0) {
                uint256 bonus = userSpecialClaimMap[user][allowedTokenList[i]];
                totalAmount += bonus;
                userSpecialClaimMap[user][allowedTokenList[i]] = 0;
                TransferHelper.safeTransfer(allowedTokenList[i], user, bonus);
            }
        }
        require(totalAmount > 0, "No Bonus");
    }

    function increaseIncentiveForCurrentRound(address token, uint256 incentive) external onlyOwner {
        require(incentive > 0, "M0");
        //Send incentive from admin
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), incentive);
        allRewardInfoMap[currentInfoIndex].tokenRewardInfoMap[token].totalRewardsForCurrentRound += incentive;
    }

    function forceCreateNextRound() public onlyOwner {
        createNextRoundInner();
    }

    function createNextRoundInner() internal {
        lastCalculateTime = block.timestamp;
        currentInfoIndex++;
        for (uint16 i = 0; i < allowedTokenList.length; i++) {
            allRewardInfoMap[currentInfoIndex].tokenRewardInfoMap[allowedTokenList[i]].totalRewardsForCurrentRound = allRewardInfoMap[currentInfoIndex - 1].tokenRewardInfoMap[allowedTokenList[i]].totalRewardsForNextRound;
        }
    }

    function insertFirstRewardInfo(address[] memory tokenList, uint256[] memory amount) external onlyOwner {
        require(currentInfoIndex == 0, "NF");
        for(uint16 i = 0; i < tokenList.length; i++) {
            allRewardInfoMap[0].tokenRewardInfoMap[tokenList[i]].totalRewardsForNextRound = amount[i];
        }
        currentInfoIndex++;
        for (uint16 i = 0; i < allowedTokenList.length; i++) {
            allRewardInfoMap[1].tokenRewardInfoMap[allowedTokenList[i]].totalRewardsForCurrentRound = allRewardInfoMap[0].tokenRewardInfoMap[allowedTokenList[i]].totalRewardsForNextRound;
        }
        lastCalculateTime = block.timestamp;
    }

    function initAllowToken(address[] memory tokenList) external onlyOwner {
        delete allowedTokenList;
        for(uint16 i = 0; i < tokenList.length; i++) {
            allowedTokenList.push(tokenList[i]);
            allowedTokenInfo[tokenList[i]] = true;
        }
    }

    function updateBasicInfo(uint256 _bonusRate, uint256 _offset, uint256 _calculateInterval, uint256 _maxClaimRound) external onlyOwner {
        bonusRate = _bonusRate;
        offset = _offset;
        calculateInterval = _calculateInterval;
        maxClaimRound = _maxClaimRound;
    }

    function getRewardInfo(address user) public view returns (RewardStructInfo.RewardInfo memory info) {
        address[] memory tokenList = new address[](allowedTokenList.length);
        uint256[] memory amountList = new uint256[](allowedTokenList.length);
        for (uint16 j = 0; j < allowedTokenList.length; j++) {
            uint256 myReward = 0;
            for (uint256 i = currentInfoIndex - 1; i >= userLastClaimIndexMap[user]; i--) {
                if ((i + maxClaimRound) <= currentInfoIndex - 1) {
                    break;
                }
                uint256 currentAllPaid = allRewardInfoMap[i].tokenRewardInfoMap[allowedTokenList[j]].totalRewardsForNextRound;
                if (currentAllPaid > 0) {
                    uint256 currentRoundReward = allRewardInfoMap[i].tokenRewardInfoMap[allowedTokenList[j]].totalRewardsForCurrentRound;
                    uint256 myPaid = allRewardInfoMap[i].tokenRewardInfoMap[allowedTokenList[j]].userPaidMap[user];
                    myReward += (myPaid * currentRoundReward * offset) / currentAllPaid / offset;
                }
                if (i == 0) {
                    break;
                }
            }
            tokenList[j] = allowedTokenList[j];
            amountList[j] = myReward;
        }
        info.tokenList = tokenList;
        info.rewardAmountList = amountList;
        return info;
    }

    function queryRewardInfo(uint256 round) public view returns(RewardStructInfo.RewardInfo memory info) {
        address[] memory tokenList = new address[](allowedTokenList.length);
        uint256[] memory amountList = new uint256[](allowedTokenList.length);
        uint256[] memory nextRewardList = new uint256[](allowedTokenList.length);
        for(uint16 i = 0; i < allowedTokenList.length; i++) {
            tokenList[i] = allowedTokenList[i];
            amountList[i] = allRewardInfoMap[round].tokenRewardInfoMap[allowedTokenList[i]].totalRewardsForCurrentRound;
            nextRewardList[i] = allRewardInfoMap[round].tokenRewardInfoMap[allowedTokenList[i]].totalRewardsForNextRound;
        }
        info.tokenList = tokenList;
        info.rewardAmountList = amountList;
        info.nextRewardAmountList = nextRewardList;
        return info;
    }

    // Receive ETH
    receive() external payable {}

    // Withdraw ERC20 tokens
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, msg.sender, amount);
    }

    // Withdraw ETH
    function withdrawETH(uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library RewardStructInfo {

    struct TokenRewardInfo {
        uint256 totalRewardsForNextRound;
        uint256 totalRewardsForCurrentRound;
        mapping(address => uint256) userPaidMap;
    }

    struct RewardWarp {
        mapping(address => RewardStructInfo.TokenRewardInfo) tokenRewardInfoMap;
    }

    struct RewardInfo {
        address[] tokenList;
        uint256[] rewardAmountList;
        uint256[] nextRewardAmountList;
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
                            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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