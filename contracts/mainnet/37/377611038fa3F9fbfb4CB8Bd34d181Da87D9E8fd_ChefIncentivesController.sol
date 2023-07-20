// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

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
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @param message The error msg
  /// @return z The difference of x and y
  function sub(
    uint256 x,
    uint256 y,
    string memory message
  ) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x, message);
    }
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require(x == 0 || (z = x * y) / x == y);
    }
  }

  /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
  /// @param x The numerator
  /// @param y The denominator
  /// @return z The product of x and y
  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x / y;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {
    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address user,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    function addPool(address _token, uint256 _allocPoint) external;

    function claim(address _user, address[] calldata _tokens) external;

    function setClaimReceiver(address _user, address _receiver) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IMultiFeeDistribution {
    function addReward(address rewardsToken) external;

    function mint(address user, uint256 amount, bool withPenalty) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IOnwardIncentivesController {
    function handleAction(
        address _token,
        address _user,
        uint256 _balance,
        uint256 _totalSupply
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;
import "../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../../dependencies/openzeppelin/contracts/Address.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./MultiFeeDistribution.sol";
import "../interfaces/IOnwardIncentivesController.sol";
import "../../dependencies/openzeppelin/contracts/IERC20.sol";
import "./../libs/SafeERC20.sol";
import "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../../dependencies/openzeppelin/contracts/Ownable.sol";

// based on the Sushi MasterChef
// https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
contract ChefIncentivesController is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 totalSupply;
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
        IOnwardIncentivesController onwardIncentives;
    }
    // Info about token emissions for a given time period.
    struct EmissionPoint {
        uint128 startTimeOffset;
        uint128 rewardsPerSecond;
    }

    address public poolConfigurator;

    IMultiFeeDistribution public rewardMinter;
    uint256 public rewardsPerSecond;
    uint256 public maxMintableTokens;
    uint256 public mintedTokens;

    // Info of each pool.
    address[] public registeredTokens;
    mapping(address => PoolInfo) public poolInfo;

    // Data about the future reward rates. emissionSchedule stored in reverse chronological order,
    // whenever the number of blocks since the start block exceeds the next block offset a new
    // reward rate is applied.
    EmissionPoint[] public emissionSchedule;
    // token => user => Info of each user that stakes LP tokens.
    mapping(address => mapping(address => UserInfo)) public userInfo;
    // user => base claimable balance
    mapping(address => uint256) public userBaseClaimable;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when reward mining starts.
    uint256 public startTime;

    // account earning rewards => receiver of rewards for this account
    // if receiver is set to address(0), rewards are paid to the earner
    // this is used to aid 3rd party contract integrations
    mapping(address => address) public claimReceiver;

    event BalanceUpdated(
        address indexed token,
        address indexed user,
        uint256 balance,
        uint256 totalSupply
    );

    constructor(address _poolConfigurator) Ownable() {
        poolConfigurator = _poolConfigurator;
    }

    // Start the party
    function start(
        IMultiFeeDistribution _rewardMinter,
        uint256 _maxMintable,
        uint128[] memory _startTimeOffset,
        uint128[] memory _rewardsPerSecond
    ) public onlyOwner {
        require(startTime == 0, "ChefIncentives already started");
        startTime = block.timestamp;
        rewardMinter = _rewardMinter;
        maxMintableTokens = _maxMintable;
        int256 length = int256(_startTimeOffset.length);
        for (int256 i = length - 1; i + 1 != 0; i--) {
            emissionSchedule.push(
                EmissionPoint({
                    startTimeOffset: _startTimeOffset[uint256(i)],
                    rewardsPerSecond: _rewardsPerSecond[uint256(i)]
                })
            );
        }
    }

    // Add a new lp to the pool. Can only be called by the poolConfigurator.
    function addPool(address _token, uint256 _allocPoint) external {
        require(
            msg.sender == poolConfigurator,
            "Only PoolConfigurator can call this function"
        );
        require(poolInfo[_token].lastRewardTime == 0, "Pool already exists");
        _updateEmissions();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        registeredTokens.push(_token);
        poolInfo[_token] = PoolInfo({
            totalSupply: 0,
            allocPoint: _allocPoint,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0,
            onwardIncentives: IOnwardIncentivesController(address(0))
        });
    }

    // Update the given pool's allocation point. Can only be called by the owner.
    function batchUpdateAllocPoint(
        address[] calldata _tokens,
        uint256[] calldata _allocPoints
    ) public onlyOwner {
        require(
            _tokens.length == _allocPoints.length,
            "Invalid parameters length"
        );
        _massUpdatePools();
        uint256 _totalAllocPoint = totalAllocPoint;
        for (uint256 i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0, "Pool does not exist");
            _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoints[i]
            );
            pool.allocPoint = _allocPoints[i];
        }
        totalAllocPoint = _totalAllocPoint;
    }

    function setOnwardIncentives(
        address _token,
        IOnwardIncentivesController _incentives
    ) external onlyOwner {
        require(poolInfo[_token].lastRewardTime != 0);
        poolInfo[_token].onwardIncentives = _incentives;
    }

    function setClaimReceiver(address _user, address _receiver) external {
        require(msg.sender == _user || msg.sender == owner());
        claimReceiver[_user] = _receiver;
    }

    function poolLength() external view returns (uint256) {
        return registeredTokens.length;
    }

    function claimableReward(
        address _user,
        address[] calldata _tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory claimable = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            PoolInfo storage pool = poolInfo[token];
            UserInfo storage user = userInfo[token][_user];
            uint256 accRewardPerShare = pool.accRewardPerShare;
            uint256 lpSupply = pool.totalSupply;
            if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
                uint256 duration = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = duration
                    .mul(rewardsPerSecond)
                    .mul(pool.allocPoint)
                    .div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(
                    reward.mul(1e12).div(lpSupply)
                );
            }
            claimable[i] = user.amount.mul(accRewardPerShare).div(1e12).sub(
                user.rewardDebt
            );
        }
        return claimable;
    }

    function _updateEmissions() internal {
        uint256 length = emissionSchedule.length;
        if (startTime > 0 && length > 0) {
            EmissionPoint memory e = emissionSchedule[length - 1];
            if (block.timestamp.sub(startTime) > e.startTimeOffset) {
                _massUpdatePools();
                rewardsPerSecond = uint256(e.rewardsPerSecond);
                emissionSchedule.pop();
            }
        }
    }

    // Update reward variables for all pools
    function _massUpdatePools() internal {
        uint256 totalAP = totalAllocPoint;
        uint256 length = registeredTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            _updatePool(poolInfo[registeredTokens[i]], totalAP);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(
        PoolInfo storage pool,
        uint256 _totalAllocPoint
    ) internal {
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.totalSupply;
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 duration = block.timestamp.sub(pool.lastRewardTime);
        uint256 reward = duration
            .mul(rewardsPerSecond)
            .mul(pool.allocPoint)
            .div(_totalAllocPoint);
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardTime = block.timestamp;
    }

    function _mint(address _user, uint256 _amount) internal {
        uint256 minted = mintedTokens;
        if (minted.add(_amount) > maxMintableTokens) {
            _amount = maxMintableTokens.sub(minted);
        }
        if (_amount > 0) {
            mintedTokens = minted.add(_amount);
            address receiver = claimReceiver[_user];
            if (receiver == address(0)) receiver = _user;
            rewardMinter.mint(receiver, _amount, true);
        }
    }

    //@Maneki modified

    function handleAction(
        address _user,
        uint256 _totalSupply,
        uint256 _balance
    ) external {
        PoolInfo storage pool = poolInfo[msg.sender];
        require(pool.lastRewardTime > 0);
        if (startTime != 0) {
            _updateEmissions();
            _updatePool(pool, totalAllocPoint);
        }
        UserInfo storage user = userInfo[msg.sender][_user];
        uint256 amount = user.amount;
        uint256 accRewardPerShare = pool.accRewardPerShare;
        if (amount > 0) {
            uint256 pending = amount.mul(accRewardPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                userBaseClaimable[_user] = userBaseClaimable[_user].add(
                    pending
                );
            }
        }
        user.amount = _balance;
        user.rewardDebt = _balance.mul(accRewardPerShare).div(1e12);
        pool.totalSupply = _totalSupply;
        if (pool.onwardIncentives != IOnwardIncentivesController(address(0))) {
            pool.onwardIncentives.handleAction(
                msg.sender,
                _user,
                _balance,
                _totalSupply
            );
        }
        emit BalanceUpdated(msg.sender, _user, _balance, _totalSupply);
    }

    // Claim pending rewards for one or more pools.
    // Rewards are not received directly, they are minted by the rewardMinter.
    function claim(address _user, address[] calldata _tokens) external {
        _updateEmissions();
        uint256 pending = userBaseClaimable[_user];
        userBaseClaimable[_user] = 0;
        uint256 _totalAllocPoint = totalAllocPoint;
        for (uint i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0);
            _updatePool(pool, _totalAllocPoint);
            UserInfo storage user = userInfo[_tokens[i]][_user];
            uint256 rewardDebt = user.amount.mul(pool.accRewardPerShare).div(
                1e12
            );
            pending = pending.add(rewardDebt.sub(user.rewardDebt));
            user.rewardDebt = rewardDebt;
        }
        _mint(_user, pending);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;
pragma abicoder v2;

import '../interfaces/IChefIncentivesController.sol';
import '../interfaces/IMultiFeeDistribution.sol';
import '../../dependencies/openzeppelin/contracts/Address.sol';
import '../../dependencies/openzeppelin/contracts/IERC20.sol';
import '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import '../../dependencies/openzeppelin/contracts/Ownable.sol';
import '../libs/SafeERC20.sol';

interface IMintableToken is IERC20 {
    function mint(address _receiver, uint256 _amount) external returns (bool);

    function setMinter(address _minter) external returns (bool);
}

/**
 * @author  Maneki.finance
 * @dev     The main staking contract that act as the distributor of rewards in the form of
 *          protocol token and ATokens to token stakers and lockers
 *          Based on Ellipsis EPS Staker
 *          https://github.com/ellipsis-finance/ellipsis/blob/master/contracts/EpsStaker.sol
 */
contract MultiFeeDistribution is IMultiFeeDistribution, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IMintableToken;

    /* ========== STATE VARIABLES ========== */

    /* Get staking token's information */
    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        // tracks already-added balances to handle accrued interest in aToken rewards
        // for the stakingToken this value is unused and will always be 0
        uint256 balance;
    }

    /* Represent balances of a given user */
    struct Balances {
        uint256 total;
        uint256 unlocked;
        uint256 locked;
        uint256 earned;
    }

    /* Struct to represent user's locked lp positions and user's vesting positions */
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }
    struct RewardData {
        address token;
        uint256 amount;
    }

    /* ChefIncentivesController address */
    IChefIncentivesController public incentivesController;

    /* LP Token Of The Project */
    IERC20 public immutable stakingToken;

    /* Native Token Of Th Project */
    IMintableToken public immutable protocolToken;

    /* List of reward tokens */
    address[] public rewardTokens;
    /* Mapping of reward tokens to its rewards data */
    mapping(address => Reward) public rewardData;

    /* Duration that rewards are streamed over */
    uint256 public constant rewardsDuration = 86400 * 7;

    /* Duration of locking period */
    uint256 public constant lockDuration = rewardsDuration * 13;

    /* Contracts that call MultiFeeDistribution to mint protocol token */
    mapping(address => bool) public minters;

    /* Minters can only be set once */
    bool public mintersAreSet;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    uint256 public totalSupply;
    uint256 public lockedSupply;

    // Private mappings for balance data
    mapping(address => Balances) private balances;

    /* Store the array of user's locked lp positions */
    mapping(address => LockedBalance[]) private userLocks;

    /* Store the array of user's vested protocol token positions */
    mapping(address => LockedBalance[]) private userEarnings;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakingToken, address _protocolToken) Ownable() {
        /* Assign Staking Token */
        stakingToken = IERC20(_stakingToken);

        /* Assign Protocol Token */
        protocolToken = IMintableToken(_protocolToken);

        /* Set MultiFeeDistribution as Protocol Token Minter */
        IMintableToken(_protocolToken).setMinter(address(this));

        // First reward MUST be the staking token or things will break
        // related to the 50% penalty and distribution to locked balances

        /* Set Protocol Token as first reward */
        rewardTokens.push(_protocolToken);
        rewardData[_protocolToken].lastUpdateTime = block.timestamp;
    }

    /* ========== ADMIN CONFIGURATION ========== */

    /**
     * @dev Set minters of the protocol token, can only be called once
     *      ChefIncentivesControlelr, TokenVesting, MerkleDistributor
     */
    function setMinters(address[] memory _minters) external onlyOwner {
        require(!mintersAreSet, 'Minters already set');
        for (uint i; i < _minters.length; i++) {
            minters[_minters[i]] = true;
        }
        mintersAreSet = true;
    }

    /**
     * @dev Set ChefIncentivesController
     */
    function setIncentivesController(
        IChefIncentivesController _controller
    ) external onlyOwner {
        incentivesController = _controller;
    }

    /**
     * @dev Add new reward token to be distributed to lockers
     */
    function addReward(address _rewardsToken) external override onlyOwner {
        require(
            rewardData[_rewardsToken].lastUpdateTime == 0,
            'Reward has been added before'
        );
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Calculates the eligible rewards of _rewardsToken per stakingToken
     */
    function _rewardPerToken(
        address _rewardsToken,
        uint256 _supply
    ) internal view returns (uint256) {
        /* If there is no stakingToken locked */
        if (_supply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            rewardData[_rewardsToken].rewardPerTokenStored.add(
                lastTimeRewardApplicable(_rewardsToken)
                    .sub(rewardData[_rewardsToken].lastUpdateTime)
                    .mul(rewardData[_rewardsToken].rewardRate)
                    .mul(1e18)
                    .div(_supply)
            );
    }

    /**
     * @dev Calculates the eligible rewards of _rewardsToken per stakingToken
     */
    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance,
        uint256 _currentRewardPerToken
    ) internal view returns (uint256) {
        return
            _balance
                .mul(
                    _currentRewardPerToken.sub(
                        userRewardPerTokenPaid[_user][_rewardsToken]
                    )
                )
                .div(1e18)
                .add(rewards[_user][_rewardsToken]);
    }

    /**
     * @dev Return either block.timestamp or periodFinish based on whichever is earlier
     */
    function lastTimeRewardApplicable(
        address _rewardsToken
    ) public view returns (uint256) {
        uint periodFinish = rewardData[_rewardsToken].periodFinish;
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken(
        address _rewardsToken
    ) external view returns (uint256) {
        uint256 supply = _rewardsToken == address(stakingToken)
            ? lockedSupply
            : totalSupply;
        return _rewardPerToken(_rewardsToken, supply);
    }

    function getRewardForDuration(
        address _rewardsToken
    ) external view returns (uint256) {
        return
            rewardData[_rewardsToken].rewardRate.mul(rewardsDuration).div(1e12);
    }

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(
        address account
    ) external view returns (RewardData[] memory rewards) {
        rewards = new RewardData[](rewardTokens.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            // If i == 0 this is the stakingReward, distribution is based on locked balances
            uint256 balance = i == 0
                ? balances[account].locked
                : balances[account].total;
            uint256 supply = i == 0 ? lockedSupply : totalSupply;
            rewards[i].token = rewardTokens[i];
            rewards[i].amount = _earned(
                account,
                rewards[i].token,
                balance,
                _rewardPerToken(rewardTokens[i], supply)
            ).div(1e12);
        }
        return rewards;
    }

    // Total balance of an account, including unlocked, locked and earned tokens
    /**
     * @dev Return the total balance including unlocked, locked and earned tokens of a user
     */
    function totalBalance(address user) external view returns (uint256 amount) {
        return balances[user].total;
    }

    // Total withdrawable balance for an account to which no penalty is applied
    function unlockedBalance(
        address user
    ) external view returns (uint256 amount) {
        amount = balances[user].unlocked;
        LockedBalance[] storage earnings = userEarnings[msg.sender];
        for (uint i = 0; i < earnings.length; i++) {
            if (earnings[i].unlockTime > block.timestamp) {
                break;
            }
            amount = amount.add(earnings[i].amount);
        }
        return amount;
    }

    // Information on the "earned" balances of a user
    // Earned balances may be withdrawn immediately for a 50% penalty
    function earnedBalances(
        address user
    )
        external
        view
        returns (uint256 total, LockedBalance[] memory earningsData)
    {
        LockedBalance[] storage earnings = userEarnings[user];
        uint256 idx;
        for (uint i = 0; i < earnings.length; i++) {
            if (earnings[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    earningsData = new LockedBalance[](earnings.length - i);
                }
                earningsData[idx] = earnings[i];
                idx++;
                total = total.add(earnings[i].amount);
            }
        }
        return (total, earningsData);
    }

    // Information on a user's locked balances
    function lockedBalances(
        address user
    )
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        )
    {
        LockedBalance[] storage locks = userLocks[user];
        uint256 idx;
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                locked = locked.add(locks[i].amount);
            } else {
                unlockable = unlockable.add(locks[i].amount);
            }
        }
        return (balances[user].locked, unlockable, locked, lockData);
    }

    /**
     * @dev Callculate the balance that user will receive and penaltyAmount
     *      imposed upon calling exit()
     */
    function withdrawableBalance(
        address user
    ) public view returns (uint256 amount, uint256 penaltyAmount) {
        Balances storage bal = balances[user];
        uint256 earned = bal.earned;
        if (earned > 0) {
            uint256 amountWithoutPenalty;
            uint256 length = userEarnings[user].length;
            for (uint i = 0; i < length; i++) {
                uint256 earnedAmount = userEarnings[user][i].amount;
                if (earnedAmount == 0) continue;
                if (userEarnings[user][i].unlockTime > block.timestamp) {
                    break;
                }
                amountWithoutPenalty = amountWithoutPenalty.add(earnedAmount);
            }

            penaltyAmount = earned.sub(amountWithoutPenalty).div(2);
        }
        amount = bal.unlocked.add(earned).sub(penaltyAmount);
        return (amount, penaltyAmount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Stake/Lock stakingTokens to be eligible for rewards
     *      Lokced tokens cannot be withdran for lockDuration, and are will
     *      receive penalty fees from early quitters
     */
    function stake(uint256 amount, bool lock) external {
        /* Temp overwrite */
        lock = true;

        /* Cannot stake 0 amount */
        require(amount > 0, 'Cannot stake 0');

        /* Update the previous accrued reward for user up to date before state change */
        _updateReward(msg.sender);

        /* Update the totalSupply of locked tokens */
        totalSupply = totalSupply.add(amount);

        /* Get the Balances information of msg.sender */
        Balances storage bal = balances[msg.sender];

        /* Add user's locked amount to user's Balances info */
        bal.total = bal.total.add(amount);
        if (lock) {
            /* Add user's locked amount to aggregated locked amount */
            lockedSupply = lockedSupply.add(amount);

            /* Add user's locked amount to user's Balances info */
            bal.locked = bal.locked.add(amount);

            /* Calculate the unlock time of the current lock position */
            /* The unlockTime will only advance for every rewardsDuration passed */
            uint256 unlockTime = block
                .timestamp
                .div(rewardsDuration)
                .mul(rewardsDuration)
                .add(lockDuration);

            /* Check the LockedBalances array of msg.sender */
            uint256 idx = userLocks[msg.sender].length;

            /* If user has not locked before */
            /* Or the previous LockedBalance unlockTime has passed more than lockDuration */
            /* Create new LockedBalance struct and push it to userLocks */
            if (
                idx == 0 ||
                userLocks[msg.sender][idx - 1].unlockTime < unlockTime
            ) {
                userLocks[msg.sender].push(
                    LockedBalance({amount: amount, unlockTime: unlockTime})
                );
            }
            /* Else add the locked amount onto the previous LockedBalance struct */
            else {
                userLocks[msg.sender][idx - 1].amount = userLocks[msg.sender][
                    idx - 1
                ].amount.add(amount);
            }
        } else {
            bal.unlocked = bal.unlocked.add(amount);
        }

        /* Transfer staking tokens from user to MultiFeeDistribution */
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, lock);
    }

    // Mint new t okens
    // Minted tokens receive rewards normally but incur a 50% penalty when
    // withdrawn before lockDuration has passed.

    /**
     * @dev Called by minters contract to mint protocol tokens to user
     *      Pass
     */

    function mint(
        address user,
        uint256 amount,
        bool withPenalty
    ) external override {
        /* Only authorized minters can call this function */
        require(minters[msg.sender]);

        /* Cannot mint 0 amount */
        if (amount == 0) return;

        /* Update the previous accrued reward for user up to date before state change */
        _updateReward(user);

        /* Mint protocol tokens of user to be at MultiFeeDistribution */
        protocolToken.mint(address(this), amount);

        if (user == address(this)) {
            // minting to this contract adds the new tokens as incentives for lockers
            _notifyReward(address(stakingToken), amount);
            return;
        }
        totalSupply = totalSupply.add(amount);
        Balances storage bal = balances[user];
        bal.total = bal.total.add(amount);
        if (withPenalty) {
            bal.earned = bal.earned.add(amount);
            uint256 unlockTime = block
                .timestamp
                .div(rewardsDuration)
                .mul(rewardsDuration)
                .add(lockDuration);
            LockedBalance[] storage earnings = userEarnings[user];
            uint256 idx = earnings.length;
            if (idx == 0 || earnings[idx - 1].unlockTime < unlockTime) {
                earnings.push(
                    LockedBalance({amount: amount, unlockTime: unlockTime})
                );
            } else {
                earnings[idx - 1].amount = earnings[idx - 1].amount.add(amount);
            }
        } else {
            bal.unlocked = bal.unlocked.add(amount);
        }
        emit Staked(user, amount, false);
    }

    // Withdraw staked tokens
    // First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
    // incurs a 50% penalty which is distributed based on locked balances.

    /**
     * @dev
     */

    function withdraw(uint256 amount) public {
        /* Cannot withdraw 0 amount */
        require(amount > 0, 'Cannot withdraw 0');

        /* Update the previous accrued reward for user up to date before state change */
        _updateReward(msg.sender);

        /* Get the Balances information of msg.sender */
        Balances storage bal = balances[msg.sender];
        uint256 penaltyAmount;

        if (amount <= bal.unlocked) {
            bal.unlocked = bal.unlocked.sub(amount);
        } else {
            uint256 remaining = amount.sub(bal.unlocked);
            require(bal.earned >= remaining, 'Insufficient unlocked balance');
            bal.unlocked = 0;
            bal.earned = bal.earned.sub(remaining);
            for (uint i = 0; ; i++) {
                uint256 earnedAmount = userEarnings[msg.sender][i].amount;
                if (earnedAmount == 0) continue;
                if (
                    penaltyAmount == 0 &&
                    userEarnings[msg.sender][i].unlockTime > block.timestamp
                ) {
                    penaltyAmount = remaining;
                    require(
                        bal.earned >= remaining,
                        'Insufficient balance after penalty'
                    );
                    bal.earned = bal.earned.sub(remaining);
                    if (bal.earned == 0) {
                        delete userEarnings[msg.sender];
                        break;
                    }
                    remaining = remaining.mul(2);
                }
                if (remaining <= earnedAmount) {
                    userEarnings[msg.sender][i].amount = earnedAmount.sub(
                        remaining
                    );
                    break;
                } else {
                    delete userEarnings[msg.sender][i];
                    remaining = remaining.sub(earnedAmount);
                }
            }
        }

        uint256 adjustedAmount = amount.add(penaltyAmount);
        bal.total = bal.total.sub(adjustedAmount);
        totalSupply = totalSupply.sub(adjustedAmount);
        stakingToken.safeTransfer(msg.sender, amount);
        if (penaltyAmount > 0) {
            incentivesController.claim(address(this), new address[](0));
            _notifyReward(address(stakingToken), penaltyAmount);
        }
        emit Withdrawn(msg.sender, amount, penaltyAmount);
    }

    function _getReward(address[] memory _rewardTokens) internal {
        uint256 length = _rewardTokens.length;
        for (uint i; i < length; i++) {
            address token = _rewardTokens[i];
            uint256 reward = rewards[msg.sender][token].div(1e12);
            if (token != address(stakingToken)) {
                // for rewards other than stakingToken, every 24 hours we check if new
                // rewards were sent to the contract or accrued via aToken interest
                Reward storage r = rewardData[token];
                uint256 periodFinish = r.periodFinish;
                require(periodFinish > 0, 'Unknown reward token');
                uint256 balance = r.balance;
                if (
                    periodFinish < block.timestamp.add(rewardsDuration - 86400)
                ) {
                    uint256 unseen = IERC20(token).balanceOf(address(this)).sub(
                        balance
                    );
                    if (unseen > 0) {
                        _notifyReward(token, unseen);
                        balance = balance.add(unseen);
                    }
                }
                r.balance = balance.sub(reward);
            }
            if (reward == 0) continue;
            rewards[msg.sender][token] = 0;
            IERC20(token).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, token, reward);
        }
    }

    /**
     * @dev Function to claim rewards accrued
     */
    function getReward(address[] memory _rewardTokens) public {
        /* Update the previous accrued reward for user up to date before state change */
        _updateReward(msg.sender);
        /* Claim accrued rewards */
        _getReward(_rewardTokens);
    }

    /**
     * @dev Withdraw user's all vesting protocol token, incurring penalty
     */

    function exit(bool claimRewards) external {
        /* Update the previous accrued reward for user up to date before state change */
        _updateReward(msg.sender);

        /* Update the previous accrued reward for user up to date before state change */
        (uint256 amount, uint256 penaltyAmount) = withdrawableBalance(
            msg.sender
        );

        /* Delete array of user's protocol token vesting schedule */
        delete userEarnings[msg.sender];

        /* Get the Balances info of msg.sender */
        Balances storage bal = balances[msg.sender];
        /* Get the Balances info of msg.sender */
        bal.total = bal.total.sub(bal.unlocked).sub(bal.earned);
        bal.unlocked = 0;
        bal.earned = 0;

        totalSupply = totalSupply.sub(amount.add(penaltyAmount));
        stakingToken.safeTransfer(msg.sender, amount);
        if (penaltyAmount > 0) {
            incentivesController.claim(address(this), new address[](0));
            _notifyReward(address(stakingToken), penaltyAmount);
        }

        /* Claim all rewardTokens */
        if (claimRewards) {
            _getReward(rewardTokens);
        }
        /* Emit Withdrwan event */
        emit Withdrawn(msg.sender, amount, penaltyAmount);
    }

    /**
     * @dev Withdraw all currently locked tokens where the unlock time has passed
     */
    function withdrawExpiredLocks() external {
        /* Update the previous accrued reward for user up to date before state change */
        _updateReward(msg.sender);

        /* Get the LockedBalance array of user */
        LockedBalance[] storage locks = userLocks[msg.sender];

        /* Get the Balances info of user*/
        Balances storage bal = balances[msg.sender];

        uint256 amount;

        /* Get the Balances info of user*/
        uint256 length = locks.length;

        /* If the entire locked array is expired */
        if (locks[length - 1].unlockTime <= block.timestamp) {
            amount = bal.locked;
            delete userLocks[msg.sender];
        }
        /* Loop through the lokced array until unlockTime > block.timestamp */
        else {
            for (uint i = 0; i < length; i++) {
                if (locks[i].unlockTime > block.timestamp) break;
                amount = amount.add(locks[i].amount);
                delete locks[i];
            }
        }
        /* Deduct withdrawable amount from user's Balances info */
        bal.locked = bal.locked.sub(amount);
        bal.total = bal.total.sub(amount);

        /* Deduct withdrawable amount from aggregate totalSupply */
        totalSupply = totalSupply.sub(amount);
        /* Deduct withdrawable amount from total lockedSupply */
        lockedSupply = lockedSupply.sub(amount);
        /* Transfer staking token back to user */
        stakingToken.safeTransfer(msg.sender, amount);

        /* Emit Withdrwan event */
        emit Withdrawn(msg.sender, amount, 0);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev If the current timestamp is greater than the `periodFinish` of a reward,
     *      a new `rewardRate` is calculated based on the provided `reward` input.
     *      If the current timestamp is less than `periodFinish`, the `rewardRate` is updated
     *      based on the remaining rewards (`leftover`) and the `reward` input.
     *      The `lastUpdateTime` and `periodFinish` for the reward are also updated.
     */
    function _notifyReward(address _rewardsToken, uint256 reward) internal {
        Reward storage r = rewardData[_rewardsToken];
        if (block.timestamp >= r.periodFinish) {
            r.rewardRate = reward.mul(1e12).div(rewardsDuration);
        } else {
            uint256 remainingTime = r.periodFinish.sub(block.timestamp);
            uint256 leftover = remainingTime.mul(r.rewardRate).div(1e12);
            r.rewardRate = reward.add(leftover).mul(1e12).div(rewardsDuration);
        }
        r.lastUpdateTime = block.timestamp;
        r.periodFinish = block.timestamp.add(rewardsDuration);
    }

    /**
     * @dev Recovers ERC20 tokens by sending it owner
     */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        /* Cannot withdraw stakingToken with function */
        require(
            tokenAddress != address(stakingToken),
            'Cannot withdraw staking token'
        );

        /* Cannot withdraw reward tokens */
        require(
            rewardData[tokenAddress].lastUpdateTime == 0,
            'Cannot withdraw reward token'
        );

        /* Transfer ERC20 tokens to owner */
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);

        /* Emit recovered event */
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @dev Update accrued reward for account before state change
     */
    function _updateReward(address account) internal {
        /* Get the address of protocol token */
        address token = address(protocolToken);

        uint256 balance;

        /* Get the rewardData information of protocol token */
        Reward storage r = rewardData[token];

        /* Calculate reward per staking token */
        uint256 rpt = _rewardPerToken(token, lockedSupply);

        /* Update reward perTokenStored of protocol token */
        r.rewardPerTokenStored = rpt;

        /* Update lastUpdateTime of protocol token */
        r.lastUpdateTime = lastTimeRewardApplicable(token);

        if (account != address(this)) {
            /* Update the earned amount of protocol token by user */
            rewards[account][token] = _earned(
                account,
                token,
                balances[account].locked,
                rpt
            );
            userRewardPerTokenPaid[account][token] = rpt;
            balance = balances[account].total;
        }

        /* Total stakingToken locked */
        uint256 supply = totalSupply;
        /* Length of the rewards */
        uint256 length = rewardTokens.length;

        /* Loop through all rewards token other than protocol token */
        for (uint i = 1; i < length; i++) {
            token = rewardTokens[i];
            r = rewardData[token];
            rpt = _rewardPerToken(token, supply);
            r.rewardPerTokenStored = rpt;
            r.lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(this)) {
                rewards[account][token] = _earned(account, token, balance, rpt);
                userRewardPerTokenPaid[account][token] = rpt;
            }
        }
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, bool locked);
    event Withdrawn(
        address indexed user,
        uint256 receivedAmount,
        uint256 penaltyPaid
    );
    event RewardPaid(
        address indexed user,
        address indexed rewardsToken,
        uint256 reward
    );
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event Recovered(address token, uint256 amount);
}