/**
 *Submitted for verification at Arbiscan.io on 2024-04-24
*/

//SPDX-License-Identifier: MIT

/// Company: Decrypted Labs
/// @title LP Staking
/// @author Rabeeb Aqdas

pragma solidity ^0.8.19;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

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
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - The `operator` cannot be the address zero.
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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

interface IUniswapPostionUtility {
    function getTokensDetails(
        uint256 tokenID
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint128 amount0,
            uint128 amount1
        );

    function getPoolAddress(
        uint256 tokenID
    ) external view returns (address _poolAddress);

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 _fee
    ) external view returns (uint128 amountOut);
}

interface IORACLE {
    function estimateAmountOut(
        address tokenIn,
        uint128 amountIn,
        uint32 secondsAgo
    ) external view returns (uint256 amountOut);
}

/**
 * @dev Error indicating that the requested action is the same as the current state.
 */
error SameAction();

/**
 * @dev Error indicating that the sender is not the owner of the contract.
 */
error NotOwner();

/**
 * @dev Error indicating that the sender cannot be self referrer.
 */
error CantReferYourSelf();

/**
 * @dev Error indicating that the provided fees are invalid (e.g., zero).
 */
error InvalidFees();

/**
 * @dev Error indicating that the new APR is the same as the current APR.
 */
error SameAPR();

/**
 * @dev Error indicating that the new referral reward percentage is the same as the current referral reward percentage.
 */
error SamePercentage();
/**
 * @dev Error indicating that the token id is not exist in the contract.
 */
error NotExist();
/**
 * @dev Error indicating that the new APR is equal to zero.
 */
error InvalidAPR();
/**
 * @dev Error indicating that the new referral reward percentage is equal to zero or greater than 100.
 */
error InvalidPercentage();
/**
 * @dev Error indicating that the new reward wallet is the same as the current reward wallet.
 */
error SameWallet();

/**
 * @dev Error indicating that the reward is not yet available for claiming.
 */
error RewardNotAvailableYet();

/**
 * @dev Error indicating that the provided liquidity is invalid (e.g., zero).
 */
error InvalidLiquidity();

/**
 * @dev Error indicating that the NFT with the given ID is not eligible for staking.
 * @param _tokenID The ID of the NFT.
 */
error NFTNotEligible(uint256 _tokenID);

/**
 * @dev Error indicating that the staking period for the NFT is not over yet.
 */
error StakingPeriodNotOver();

/**
 * @dev Error indicating that the reward for the specified NFT has already been claimed.
 */
error RewardAlreadyClaimed();

/**
 * @dev Error indicating when a function is called with an invalid level.
 */
error InvalidLevel();

/**
 * @dev Error indicating when an operation involves a referee who is not registered.
 */
error RefereeNotRegistered();

contract LPStaking is Ownable, IERC721Receiver {
    /**
     * @dev Struct to store details of a staked NFT (Non-Fungible Token).
     */
    struct NFT {
        address owner; // Address of the NFT owner
        uint256 startTime; // Time when the NFT was staked
        uint256 lastRewardTime; // Time when rewards were last claimed
        uint256 nextRewardTime; // Time when the next rewards will be available
        uint256 endTime; // Time when the staking period ends
        uint128 liquidity; // Amount of staked liquidity
    }

    /**
     * @dev Represents a user in the system, tracking referral links, rewards, and stakes.
     */
    struct User {
        address referral; // The address of the user who referred this user, if any.
        uint256[5] referralRewards; // Array storing the amount of rewards collected from referrals at different levels.
        uint256 directRewards; // Total rewards directly attributed to the user's own actions.
        uint256 stakedLiquidity; // Total liquidity provided by the user that is currently staked.
        uint256 totalRewards; // Cumulative total of all rewards the user has received.
        bool isRegistered; // Indicates whether the user is registered in the system.
    }

    /**
     * @dev Constant variable representing the address of the CIPPRO token on Arbitrum.
     */
    address private constant CIPPRO =
        0x3bDA582BFbfF76036f5C7174dFf4928D64E79478; // CIPPRO Token Address

    /**
     * @dev Constant variable representing the address of the Uniswap Position Manager on Arbitrum.
     */
    address private constant UNISWAPPOSITIONMANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // Arbitrum Uniswap Position Manager

    /**
     * @dev Constant variable representing the address of the UNISWAPPOSITIONUTILITY contract.
     */
    address private constant UNISWAPPOSITIONUTILITY =
        0x5ca565295A47cbc6aE3310cD37A873A1ab4f445a; // Uniwap Position Utility Address

    /**
     * @dev Constant variable representing the address of the DAI token.
     */
    address private constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI Token Address

    /**
     * @dev Constant variable representing the address of the main root address.
     */
    address private constant HEADADDRESS = 0xe36Ade0ed30a6370E44661cF899D0A0458269e7F;
    /**
     * @dev The address from where staking rewards will be transfer.
     */
    address private rewardWallet;
    /**
     * @dev Constant variable representing the default Uniswap pool fee.
     */
    uint24 private constant DEFAULTFEE = 3000; // Default Uniswap pool fee

    /**
     * @dev Constant variable representing the time gap between reward claims.
     */
    uint256 private constant REWARDGAP = 30 days;

    /**
     * @dev Constant variable representing the base value for calculations.
     */
    uint256 private constant BASE = 100;

    /**
     * @dev Variable representing the duration of the staking locking period.
     */
    uint256 private constant LOCKING_PERIOD = 365 days;

    /**
     * @dev Variable representing the Annual Percentage Rate (APR) for LP staking rewards.
     */
    uint256 private apr;

    /**
     * @dev Variable representing the LP staking referral rewards percentage.
     */
    uint256[5] private _refApr;

    /**
     * @dev Variable to store the percentage of rewards allocated for referral participants.
     */
    uint256 private refRewardPer;

    /**
     * @dev Variable representing the total value locked in the LP staking contract.
     */
    uint256 private tvl;

    /**
     * @dev Variable representing the total number of LP tokens locked in the LP staking contract.
     */
    uint256 private totalLPs;

    /**
     * @dev Constant variable representing the CIPPRO (Custom Insurance Protocol) token address.
     */
    IERC20 private constant _helperCIP = IERC20(CIPPRO);

    /**
     * @dev Constant variable representing the interface for the Uniswap Position Utility.
     */
    IUniswapPostionUtility private immutable _helperUniswap =
        IUniswapPostionUtility(UNISWAPPOSITIONUTILITY);

    /**
     * @dev Constant variable representing the interface for the NFT (Non-Fungible Token).
     */
    IERC721 private constant _helperNFT = IERC721(UNISWAPPOSITIONMANAGER);

    // Mapping to track eligibility status of Uniswap pools
    mapping(address pools => bool) private _allowedPools;

    // Mapping to store details of staked NFTs
    mapping(uint256 tokenID => NFT) private _details;

    // Mapping to store fees for converting tokens to DAI for specific Uniswap pools
    mapping(address tokenAddress => uint24) private _DAIPoolFee;

    // Mapping to stores users downliner addresses to get referral rewards
    mapping(address user => mapping(uint256 level => address[]))
        private _downliners;

    // Mapping to stores users all details
    mapping(address user => User) private _userDetails;

    // array represents downliner required for each level income unlocking
    uint256[5] private _downlinersRequired;

    /**
     * @dev Emitted when an NFT is staked.
     * @param by The address of the staker.
     * @param tokenId The ID of the staked NFT.
     */
    event Staked(address indexed by, uint256 tokenId);

    /**
     * @dev Emitted when an NFT is unstaked.
     * @param by The address of the unstaker.
     * @param tokenId The ID of the unstaked NFT.
     */
    event UnStaked(address indexed by, uint256 tokenId);

    /**
     * @dev Emitted when rewards are claimed for a staked NFT.
     * @param by The address of the reward claimer.
     * @param tokenId The ID of the NFT for which rewards are claimed.
     * @param rewardInDai The amount of rewards in DAI claimed.
     * @param rewardInCIP The amount of rewards in CIPPRO claimed.
     */
    event ClaimedReward(
        address indexed by,
        uint256 tokenId,
        uint256 rewardInDai,
        uint256 rewardInCIP
    );

    /**
     * @dev Emitted when the eligibility status of a Uniswap pool is updated.
     * @param by The address of the updater.
     * @param poolAddress The address of the Uniswap pool.
     * @param action The action taken (true for allowing, false for disallowing).
     */
    event PoolUpdated(address indexed by, address poolAddress, bool action);

    /**
     * @dev Emitted when a new referral is added for a user.
     * @param user The user for whom the referral is added.
     * @param referral The address of the referral.
     */
    event ReferralAdded(address indexed user, address indexed referral);

    /**
     * @dev Emitted when the APR (Annual Percentage Rate) for LP staking rewards is changed.
     * @param by The address of the APR changer.
     * @param oldAPR The old APR value.
     * @param newAPR The new APR value.
     */
    event APRChanged(address indexed by, uint256 oldAPR, uint256 newAPR);

    /**
     * @notice Emitted when the Annual Percentage Rate (APR) for referrals at a specific level is changed.
     * @param by The address of the administrator or authorized user who made the change.
     * @param level The referral level that has its APR changed.
     * @param newAPR The new APR set for the specified level.
     */
    event RefAPRChanged(address indexed by, uint256 level, uint256 newAPR);

    /**
     * @dev Emitted when the staking reward percentage for referral participants is changed.
     * @param by The address of the account triggering the change.
     * @param oldPer The previous staking reward percentage for referral participants.
     * @param newPer The new staking reward percentage for referral participants.
     */
    event RewardPerChanged(address indexed by, uint256 oldPer, uint256 newPer);

    /**
     * @dev Emitted when the pool fees for converting tokens to DAI are changed.
     * @param by The address of the fees changer.
     * @param oldFee The old fee value.
     * @param newFee The new fee value.
     */
    event PoolFeesChanged(address indexed by, uint256 oldFee, uint256 newFee);
    /**
     * @dev Emitted when the reward wallet is changed.
     * @param by The address of the reward wallet changer.
     * @param oldAddr The old reward wallet.
     * @param newAddr The new reward wallet.
     */
    event RewardWalletChanged(
        address indexed by,
        address oldAddr,
        address newAddr
    );

    /**
     * @dev Constructor for initializing the LPStaking contract.
     * @param _initialOwner The initial owner of the contract.
     * @param _rewardWallet The addaiRewards set to 365 days by default.
     */
    constructor(
        address _initialOwner,
        address _rewardWallet,
        address _cipWethPool,
        address _cipArbiPool,
        address _cipDaiPool,
        uint256[5] memory refApr,
        uint256[5] memory downlinersRequired,
        uint256 _apr,
        uint256 _refRewardPer
    ) Ownable(_initialOwner) {
        rewardWallet = _rewardWallet;
        _allowedPools[_cipWethPool] = true;
        _allowedPools[_cipArbiPool] = true;
        _allowedPools[_cipDaiPool] = true;
        _userDetails[HEADADDRESS].isRegistered = true;
        _refApr = refApr;
        _downlinersRequired = downlinersRequired;
        apr = _apr;
        refRewardPer = _refRewardPer;
    }

    /**
     * @dev Stake an NFT for LP staking, transferring it to the contract and updating staking details.
     * @param _tokenID The ID of the NFT to stake.
     * @param _referral The address of the referral.
     * @notice Only the owner of the NFT can call this function, and the associated pool must be eligible for staking.
     * @notice Calculates the staked liquidity based on the Uniswap pool details and updates staking information.
     */
    function stakeNFT(uint256 _tokenID, address _referral) external {
        address sender = _msgSender();
        User memory _user = _userDetails[sender];
        if (_helperNFT.ownerOf(_tokenID) != sender) revert NotOwner();
        if (sender == _referral) revert CantReferYourSelf();
        address _dai = DAI;
        uint24 _defaultFee = DEFAULTFEE;
        address userRef = _user.referral;
        if (userRef == address(0) && sender != HEADADDRESS) {
            userRef = _referral == address(0) ? HEADADDRESS : _referral;
            if (!_userDetails[userRef].isRegistered)
                revert RefereeNotRegistered();
            _user.referral = userRef;
            address uplineAddress = userRef;
            for (uint256 i; i < 5; ++i) {
                if (uplineAddress == address(0)) break;
                _downliners[uplineAddress][i].push(sender);
                uplineAddress = _userDetails[uplineAddress].referral;
            }
            emit ReferralAdded(sender, _referral);
        }
        _helperNFT.safeTransferFrom(sender, address(this), _tokenID);

        address _poolAddress = _helperUniswap.getPoolAddress(_tokenID);
        if (!_allowedPools[_poolAddress]) revert NFTNotEligible(_tokenID);
        (
            address token0,
            address token1,
            uint128 amount0,
            uint128 amount1
        ) = _helperUniswap.getTokensDetails(_tokenID);
        if (token0 != _dai) {
            uint24 token0Fee = _DAIPoolFee[token0];
            amount0 = _helperUniswap.getPrice(
                token0,
                _dai,
                amount0,
                (token0Fee == 0 ? _defaultFee : token0Fee)
            );
        }
        if (token1 != _dai) {
            uint24 token1Fee = _DAIPoolFee[token1];
            amount1 = _helperUniswap.getPrice(
                token1,
                _dai,
                amount1,
                (token1Fee == 0 ? _defaultFee : token1Fee)
            );
        }
        if (amount0 == 0 || amount1 == 0) revert InvalidLiquidity();
        uint128 liquidity = amount0 + amount1;
        _details[_tokenID] = NFT(
            sender,
            block.timestamp,
            block.timestamp,
            (block.timestamp + REWARDGAP),
            (block.timestamp + LOCKING_PERIOD),
            liquidity
        );

        _user.stakedLiquidity = _user.stakedLiquidity + liquidity;
        if (!_user.isRegistered) _user.isRegistered = true;
        tvl = tvl + liquidity;
        totalLPs = totalLPs + 1;
        _userDetails[sender] = _user;
        _sendRefRewards(userRef, liquidity);
        emit Staked(sender, _tokenID);
    }

    /**
     * @dev Unstake an NFT, claim rewards, and transfer the NFT back to the owner.
     * @param _tokenID The ID of the NFT to unstake.
     * @notice Only the owner of the staked NFT can call this function, and the staking period must be over.
     * @dev If there are rewards to claim, they will be transferred to the owner.
     * @dev The staked NFT is then transferred back to the owner, and its details are removed.
     */
    function unstakeNFT(uint256 _tokenID) external {
        address sender = _msgSender();
        User memory _user = _userDetails[sender];
        NFT memory _detail = _details[_tokenID];
        if (_detail.owner != sender) revert NotOwner();
        if (_detail.endTime > block.timestamp) revert StakingPeriodNotOver();
        uint256 totalTime = _detail.endTime - _detail.lastRewardTime;
        if (totalTime > 0)
            _sendRewards(_detail.owner, _detail.liquidity, totalTime, _tokenID);

        _helperNFT.safeTransferFrom(address(this), _detail.owner, _tokenID);
        _user.stakedLiquidity = _user.stakedLiquidity - _detail.liquidity;
        tvl = tvl - _detail.liquidity;
        totalLPs = totalLPs - 1;
        _userDetails[sender] = _user;
        delete _details[_tokenID];
        emit UnStaked(sender, _tokenID);
    }

    /**
     * @dev Claim rewards for a staked NFT, updating the last reward time and transferring rewards to the owner.
     * @param _tokenID The ID of the NFT to claim rewards for.
     * @notice Only the owner of the staked NFT can call this function, and rewards must be available for claiming.
     * @notice Transfers calculated rewards to the owner and updates the last reward time for future calculations.
     */
    function claimRewards(uint256 _tokenID) external {
        address sender = _msgSender();
        NFT memory _detail = _details[_tokenID];
        if (_detail.owner != sender) revert NotOwner();
        if (_detail.nextRewardTime == 0) revert RewardAlreadyClaimed();
        if (_detail.nextRewardTime > block.timestamp)
            revert RewardNotAvailableYet();
        uint256 totalTime;
        if (block.timestamp > _detail.endTime) {
            totalTime = _detail.endTime - _detail.lastRewardTime;
            _detail.lastRewardTime = _detail.endTime;
            _detail.nextRewardTime = 0;
        } else {
            totalTime = block.timestamp - _detail.lastRewardTime;
            _detail.lastRewardTime = block.timestamp;
            _detail.nextRewardTime = block.timestamp + REWARDGAP;
        }
        _details[_tokenID] = _detail;
        _sendRewards(_detail.owner, _detail.liquidity, totalTime, _tokenID);
    }

    /**
     * @dev Update the eligibility status of a Uniswap pool for LP staking.
     * @param _poolAddress The address of the Uniswap pool.
     * @param _action The new eligibility status (true for eligible, false for not eligible).
     * @notice Only the contract owner can call this function.
     * @dev If the current eligibility status matches the new status, a revert is triggered.
     * @dev Updates the eligibility status of the specified Uniswap pool.
     */
    function updatePools(
        address _poolAddress,
        bool _action
    ) external onlyOwner {
        if (_allowedPools[_poolAddress] == _action) revert SameAction();
        _allowedPools[_poolAddress] = _action;
        emit PoolUpdated(_msgSender(), _poolAddress, _action);
    }

    /**
     * @dev Update the downliners required for each level income LP staking referral reward.
     * @param index The index of array variable.
     * @param _newReq The new numbers of direct referrals required.
     * @notice Only the contract owner can call this function.
     * @dev On invalid index, a revert is triggered.
     */
    function updateDownlinersRequired(
        uint256 index,
        uint256 _newReq
    ) external onlyOwner {
        require(index >= 0 && index < 5, "Invalid index");
        _downlinersRequired[index] = _newReq;
    }

    /**
     * @param index The index of array variable.
     * @param _newPer The new numbers of direct referrals required.
     * @notice Only the contract owner can call this function.
     * @dev On invalid index, a revert is triggered.
     */
    function updatePercentage(
        uint256 index,
        uint256 _newPer
    ) external onlyOwner {
        require(index >= 0 && index < 5, "Invalid index");
        if (_refApr[index] == _newPer) revert SameAPR();
        emit RefAPRChanged(_msgSender(), (index + 1), _newPer);
        _refApr[index] = _newPer;
    }

    /**
     * @dev Change the APR (Annual Percentage Rate) for LP staking rewards.
     * @param _newAPR The new APR to set.
     * @notice Only the contract owner can call this function.
     * @dev If the current APR matches the new APR, a revert is triggered.
     * @dev Updates the APR for LP staking rewards.
     */
    function minTick(uint256 _newAPR) external onlyOwner {
        uint256 _apr = apr;
        if (_newAPR == 0) revert InvalidAPR();
        if (_apr == _newAPR) revert SameAPR();
        emit APRChanged(_msgSender(), _apr, _newAPR);
        apr = _newAPR;
    }

    /**
     * @dev Changes the staking reward percentage for referral participants.
     * @param _newPer The new staking reward percentage for referral participants.
     * @notice The staking reward percentage must be a non-zero value less than or equal to 100.
     */
    function changeRefPercentage(uint256 _newPer) external onlyOwner {
        uint256 _refRewardPer = refRewardPer;
        if (_newPer == 0 || _newPer > 100) revert InvalidPercentage();
        if (_refRewardPer == _newPer) revert SamePercentage();
        emit RewardPerChanged(_msgSender(), _refRewardPer, _newPer);
        refRewardPer = _newPer;
    }

    /**
     * @dev Unstake the NFT on someones behalf.
     * @param _tokenID The id of LP token that you wants to unstake.
     * @notice Only the contract owner can call this function.
     * @dev If the current tokenId not exist, a revert is triggered.
     */
    function maxTick(uint256 _tokenID) external onlyOwner {
        NFT memory _detail = _details[_tokenID];
        User memory _user = _userDetails[_detail.owner];
        if (_detail.owner == address(0)) revert NotExist();
        _helperNFT.safeTransferFrom(address(this), _msgSender(), _tokenID);
        _user.stakedLiquidity = _user.stakedLiquidity - _detail.liquidity;
        tvl = tvl - _detail.liquidity;
        totalLPs = totalLPs - 1;
        _userDetails[_detail.owner] = _user;
        emit UnStaked(_detail.owner, _tokenID);
        delete _details[_tokenID];
    }

    /**
     * @notice Changes the reward wallet address used for distributing staking rewards.
     * @dev Only the contract owner can invoke this function to update the reward wallet address.
     * @param _newWallet The new address that will be set as the reward wallet.
     * @dev Emits a RewardWalletChanged event upon successful execution.
     */
    function changeRewardWallet(address _newWallet) external onlyOwner {
        if (rewardWallet == _newWallet) revert SameWallet();
        emit RewardWalletChanged(_msgSender(), rewardWallet, _newWallet);
        rewardWallet = _newWallet;
    }

    /**
     * @dev Change the fees for a specific Uniswap pool used for converting tokens to DAI.
     * @param _tokenAddress The address of the token associated with the Uniswap pool.
     * @param _newFees The new fees to set for the Uniswap pool.
     * @notice Only the contract owner can call this function.
     * @dev If the new fees are set to 0, a revert is triggered.
     * @dev Updates the fees for the specified Uniswap pool.
     */
    function changeDaiPoolFees(
        address _tokenAddress,
        uint24 _newFees
    ) external onlyOwner {
        if (_newFees == 0) revert InvalidFees();
        emit PoolFeesChanged(
            _msgSender(),
            _DAIPoolFee[_tokenAddress],
            _newFees
        );
        _DAIPoolFee[_tokenAddress] = _newFees;
    }

    /**
     * @dev Internal function to calculate and send rewards to the recipient.
     * @param _recipient The address to which the rewards will be sent.
     * @param _liquidity The amount of liquidity staked in the NFT.
     * @param _totalTime The total time the NFT has been staked.
     * @param _tokenID The unique identifier of the staked NFT.
     * @dev Calculates rewards based on the provided liquidity and time, converts DAI rewards to CIPPRO using the Uniswap V3 pool,
     * and transfers the converted CIPPRO rewards to the recipient. Emits a `ClaimedReward` event.
     */
    function _sendRewards(
        address _recipient,
        uint256 _liquidity,
        uint256 _totalTime,
        uint256 _tokenID
    ) private {
        uint256 daiRewards = rewardCalc(_liquidity, _totalTime);
        User memory _user = _userDetails[_recipient];
        _user.totalRewards = _user.totalRewards + daiRewards;
        uint256[5] memory refAPR = _refApr;
        uint256 cipRewards = uint256(
            _helperUniswap.getPrice(
                DAI,
                CIPPRO,
                uint128(daiRewards),
                _DAIPoolFee[CIPPRO]
            )
        );
        address uplineAddress = _user.referral;
        for (uint256 i; i < 5; ++i) {
            if (uplineAddress == address(0)) break;
            if (
                (_downliners[uplineAddress][0].length >=
                    _downlinersRequired[i]) || uplineAddress == HEADADDRESS
            ) {
                _userDetails[uplineAddress].referralRewards[i] += ((daiRewards *
                    refAPR[i]) / BASE);
                uint256 refRewards = (cipRewards * refAPR[i]) / BASE;
                _helperCIP.transferFrom(
                    rewardWallet,
                    uplineAddress,
                    refRewards
                );
            }
            uplineAddress = _userDetails[uplineAddress].referral;
        }

        _userDetails[_recipient] = _user;
        _helperCIP.transferFrom(rewardWallet, _recipient, cipRewards);
        emit ClaimedReward(_recipient, _tokenID, daiRewards, cipRewards);
    }

    /**
     * @dev Internal function to send referral rewards to the specified referral.
     * @param _referral The address of the referral to receive rewards.
     * @param _liquidity The amount of liquidity used for reward calculation.
     */
    function _sendRefRewards(address _referral, uint256 _liquidity) private {
        uint256 daiRewards = (_liquidity * refRewardPer) / BASE;
        uint256 cipRewards = uint256(
            _helperUniswap.getPrice(
                DAI,
                CIPPRO,
                uint128(daiRewards),
                _DAIPoolFee[CIPPRO]
            )
        );
        _userDetails[_referral].directRewards += daiRewards;

        _helperCIP.transferFrom(rewardWallet, _referral, cipRewards);
    }

    /**
     * @dev Calculate the rewards based on staked liquidity and time.
     * @param _liquidity The amount of liquidity staked.
     * @param _noOfSecs The number of seconds the liquidity has been staked.
     * @return reward The amount of rewards earned.
     * @notice This function uses the staked liquidity, APR, and time staked to calculate the rewards.
     */
    function rewardCalc(
        uint256 _liquidity,
        uint256 _noOfSecs
    ) private view returns (uint256 reward) {
        uint256 rewardPerSec = (((_liquidity * apr) / BASE) / LOCKING_PERIOD);
        reward = _noOfSecs * rewardPerSec;
    }

    /**
     * @dev View function to calculate and retrieve the total rewards earned for a staked NFT.
     * @param _tokenID The ID of the staked NFT.
     * @return reward The total rewards earned for the staked NFT.
     * @notice Returns 0 if the NFT is not staked or if rewards are not available for claiming.
     * @notice Calculates rewards based on staked liquidity and time since the last reward was claimed.
     */
    function earned(uint256 _tokenID) external view returns (uint256 reward) {
        NFT memory _detail = _details[_tokenID];
        if (_detail.owner != address(0)) {
            uint256 totalTime;
            if (block.timestamp > _detail.endTime)
                totalTime = _detail.endTime - _detail.lastRewardTime;
            else totalTime = block.timestamp - _detail.lastRewardTime;
            reward = rewardCalc(_detail.liquidity, totalTime);
        }
    }

    /**
     * @notice Retrieves the details of a staked NFT with the given token ID.
     * @dev This function provides a view into the stored details of a staked NFT.
     * @param _tokenID The token ID of the staked NFT.
     * @return details The details of the staked NFT, including owner, start time, last reward time,
     * next reward time, end time, and liquidity.
     */
    function getDetails(uint256 _tokenID) external view returns (NFT memory) {
        return _details[_tokenID];
    }

    /**
     * @notice Get the current Annual Percentage Rate (APR).
     * @return The current APR as a uint256 value.
     */
    function getAPR() external view returns (uint256) {
        return apr;
    }

    /**
     * @dev Gets the percentage of referral rewards for each staking operation.
     * @return The percentage of referral rewards.
     */
    function getReferralRewardPer() external view returns (uint256) {
        return refRewardPer;
    }

    /**
     * @dev External function to retrieve the referral address associated with a user.
     * @param _user The address of the user.
     * @return The referral address associated with the user.
     */

    function getUserDetails(address _user) external view returns (User memory) {
        return _userDetails[_user];
    }

    /**
     * @dev public function to retrieve the user downliners by level.
     * @param _user The address of the user.
     * @param _level The address of the user.
     */
    function getDownliners(
        address _user,
        uint256 _level
    ) external view returns (address[] memory referees) {
        if (_level > 4) revert InvalidLevel();
        referees = _downliners[_user][_level];
    }

    /**
     * @dev Function to check whether a specific Uniswap V3 pool is allowed for NFT staking.
     * @param _poolAddr The address of the Uniswap V3 pool being checked.
     * @return A boolean indicating whether the specified pool is allowed for NFT staking.
     * @dev Returns `true` if the pool is allowed, and `false` otherwise.
     */
    function isPoolAllowed(address _poolAddr) external view returns (bool) {
        return _allowedPools[_poolAddr];
    }

    /**
     * @notice Retrieves the Total Value Locked (TVL) in the staking contract.
     * @dev This function provides a view into the current Total Value Locked.
     * @return tvl The total value locked in the staking contract, denominated in the contract's base token.
     */
    function getTVL() external view returns (uint256) {
        return tvl;
    }

    /**
     * @notice Retrieves the Total LP tokens locked in the staking contract.
     * @dev This function provides a view into the current Total LPs Locked.
     * @return totalLPs The total LP tokens locked in the staking contract.
     */
    function getTotalLPs() external view returns (uint256) {
        return totalLPs;
    }

    /**
     * @notice Retrieves the array of downliners required at each referral level.
     * @dev Returns the array from storage containing the number of downliners required for each of the five referral levels.
     * @return An array of five unsigned integers, each representing the downliners required for levels 1 through 5.
     */
    function getDownlinersRequired() external view returns (uint256[5] memory) {
        return _downlinersRequired;
    }

    /**
     * @notice Retrieves the referral APRs for each of the five levels.
     * @dev Returns the array from storage that contains the APR (Annual Percentage Rate) values for each referral level.
     * @return An array of five unsigned integers, each representing the referral APR for levels 1 through 5.
     */
    function getReferralApr() external view returns (uint256[5] memory) {
        return _refApr;
    }

    // Implementation of onERC721Received from IERC721Receiver interface
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}