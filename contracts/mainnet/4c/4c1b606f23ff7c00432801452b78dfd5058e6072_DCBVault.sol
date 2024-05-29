// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IDecubateMasterChef.sol";

/**
 * @title DCBVault
 * @dev Vault contract for managing user deposits, staking, and rewards distribution
 */
contract DCBVault is Initializable, OwnableUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;

  struct UserInfo {
    uint256 shares; // number of shares for a user
    uint256 lastDepositedTime; // keeps track of deposited time for potential penalty
    uint256 totalInvested; // Total amount of token invested
    uint256 totalClaimed; // Total amount of token claimed
  }

  struct PoolInfo {
    uint256 totalShares; // Total shares in the pool
    uint256 pendingClaim; // Claim stored when pool is full
    uint256 lastHarvestedTime; // keeps track of the last pool update
  }

  struct Rebate {
    bool isEarlyWithdrawActive; // If early withdraw is active
    uint256 rebatePercent; // Rebate percent
    uint256 earlyWithdrawPenalty; // Penalty for early withdraw
  }

  IDecubateMasterChef public masterchef; // MasterChef contract

  uint256 public callFee; // Fee to call harvestAll function
  uint256 internal constant DIVISOR = 10000;

  // User staking info
  mapping(uint256 => mapping(address => UserInfo)) public users;
  // Pool info
  mapping(uint256 => PoolInfo) public pools;
  // Pool rebate info
  mapping(uint256 => Rebate) public rebates;

  event Deposit(
    address indexed sender,
    uint256 indexed poolId,
    uint256 amount,
    uint256 lastDepositedTime
  );
  event Withdraw(address indexed sender, uint256 indexed poolId, uint256 amount, uint256 time);
  event Harvest(address indexed sender, uint256 indexed poolId, uint256 time);
  event WithdrawPenalty(address indexed sender, uint256 indexed poolId, uint256 amount);
  event RebateSent(address indexed sender, uint256 indexed poolId, uint256 amount);
  event Pause();
  event Unpause();
  event CallFeeSet(uint256 callFee);
  event RebateInfoSet(uint256 pid, Rebate rebate);
  event TokenTransferred(address token, uint256 amount);

  /**
   * @notice Modifier to prevent contract interactions
   */
  modifier notContract() {
    require(msg.sender == tx.origin, "proxy contract not allowed");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializes the contract with the MasterChef contract address
   * @param _masterchef Address of the MasterChef contract
   */
  function initialize(IDecubateMasterChef _masterchef) external initializer {
    require(address(_masterchef) != address(0), "Zero address");
    __Ownable_init();
    masterchef = IDecubateMasterChef(_masterchef);
    callFee = 25;
  }

  /**
   * @notice Deposits tokens into the DCB Vault
   * @param _pid Pool id
   * @param _amount Amount of tokens to deposit
   */
  function deposit(uint256 _pid, uint256 _amount) external whenNotPaused notContract {
    require(_amount > 0, "Nothing to deposit");

    PoolInfo storage pool = pools[_pid];
    IERC20Upgradeable token;
    {
      (
        ,
        uint256 lockPeriodInDays,
        uint256 totalDeposit,
        ,
        uint256 endDate,
        uint256 hardCap,
        address tokenOfPool
      ) = masterchef.poolInfo(_pid);

      require(totalDeposit + _amount <= hardCap, "Pool full");
      uint256 stopDepo = endDate - (lockPeriodInDays * 1 days);
      require(block.timestamp <= stopDepo, "Staking disabled for this pool");

      token = IERC20Upgradeable(tokenOfPool);
    }

    uint256 poolBal = balanceOf(_pid);
    poolBal += masterchef.payout(_pid, address(this));
    token.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 currentShares = 0;

    if (pool.totalShares != 0) {
      currentShares = (_amount * pool.totalShares) / poolBal;
    } else {
      token.approve(address(masterchef), type(uint256).max);
      currentShares = _amount;
    }

    UserInfo storage user = users[_pid][msg.sender];

    user.shares += currentShares;
    user.lastDepositedTime = block.timestamp;
    user.totalInvested += _amount;

    pool.totalShares += currentShares;
    pool.pendingClaim += _amount;

    _earn(_pid);

    uint256 rebateAmount = (_amount * rebates[_pid].rebatePercent) / DIVISOR;
    if (rebateAmount > 0) {
      uint256 total = balanceOf(_pid);
      uint256 balance = token.balanceOf(address(masterchef));
      require(balance - total >= rebateAmount, "Not enough rebate balance");
      token.safeTransferFrom(address(masterchef), msg.sender, rebateAmount);

      emit RebateSent(msg.sender, _pid, rebateAmount);
    }

    emit Deposit(msg.sender, _pid, _amount, block.timestamp);
  }

  /**
   * @notice Withdraws all funds from the DCB Vault of a user
   * @param _pid Pool id
   */
  function withdrawAll(uint256 _pid) external notContract {
    withdraw(_pid, users[_pid][msg.sender].shares);
  }

  /**
   * @notice Harvests all pools
   * @dev Only possible when contract not paused.
   */
  function harvestAll() external notContract whenNotPaused {
    uint256 poolLen = masterchef.poolLength();

    for (uint256 pid = 0; pid < poolLen; pid++) {
      harvest(pid);
    }
  }

  /**
   * @notice Sets the call fee
   * @param _callFee New call fee
   */
  function setCallFee(uint256 _callFee) external onlyOwner {
    require(_callFee < DIVISOR, "Invalid call fee");
    callFee = _callFee;

    emit CallFeeSet(_callFee);
  }

  /**
   * @notice Sets rebate info
   * @param _pid Pool id
   * @param _rebate New rebate info
   */
  function setRebateInfo(uint256 _pid, Rebate memory _rebate) external onlyOwner {
    require(
      _rebate.rebatePercent <= DIVISOR && _rebate.earlyWithdrawPenalty <= DIVISOR,
      "Invalid rebate percent"
    );
    rebates[_pid] = _rebate;

    emit RebateInfoSet(_pid, _rebate);
  }

  /**
   * @notice Triggers stopped state
   * @dev Only possible when contract not paused.
   */
  function pause() external onlyOwner whenNotPaused {
    _pause();
    emit Pause();
  }

  /**
   * @notice Returns to normal state
   * @dev Only possible when contract is paused.
   */
  function unpause() external onlyOwner whenPaused {
    _unpause();
    emit Unpause();
  }

  /**
   * @notice Calculates the total pending reward of a pool
   * @param _pid Pool id
   * @return amount Total pending reward
   */
  function calculateTotalPendingRewards(uint256 _pid) external view returns (uint256 amount) {
    amount = masterchef.payout(_pid, address(this));
    amount += pools[_pid].pendingClaim;

    return amount;
  }

  /**
   * @notice Calculate the reward user receives on harvest
   * @param _pid Pool id
   * @return currentCallFee Reward amount
   */
  function calculateHarvestDcbRewards(uint256 _pid) external view returns (uint256 currentCallFee) {
    uint256 amount = masterchef.payout(_pid, address(this));
    amount += pools[_pid].pendingClaim;
    currentCallFee = (amount * callFee) / DIVISOR;

    return currentCallFee;
  }

  /**
   * @notice Calculate the reward user receives on withdraw
   * @param _user User address
   * @param _pid Pool id
   * @return reward Reward amount
   */
  function getRewardOfUser(address _user, uint256 _pid) external view returns (uint256 reward) {
    UserInfo storage user = users[_pid][_user];
    uint256 pricePerFullShare = getPricePerFullShare(_pid);
    uint256 userTotal = (user.shares * pricePerFullShare) / 1e18;

    reward = userTotal >= user.totalInvested ? userTotal - user.totalInvested : 0;
  }

  /**
   * @notice Withdraws funds from the DCB Vault
   * @param _pid Pool id
   * @param _shares Number of shares to withdraw
   */
  function withdraw(uint256 _pid, uint256 _shares) public notContract {
    harvest(_pid);

    PoolInfo storage pool = pools[_pid];
    UserInfo storage user = users[_pid][msg.sender];

    require(_shares > 0, "Nothing to withdraw");
    require(_shares <= user.shares, "Withdraw exceeds balance");
    require(canUnstake(msg.sender, _pid), "Stake still locked");

    uint256 currentAmount = (balanceOf(_pid) * _shares) / pool.totalShares;
    uint256 totalReward = currentAmount - (user.totalInvested * _shares) / user.shares;
    uint256 multipliedAmount = masterchef.handleNFTMultiplier(_pid, msg.sender, totalReward);

    user.totalInvested -= (user.totalInvested * _shares) / user.shares;
    user.shares -= _shares;
    pool.totalShares -= _shares;
    user.totalClaimed += totalReward + multipliedAmount; //With NFT Boost

    IERC20Upgradeable token = getTokenOfPool(_pid);
    masterchef.unStake(_pid, currentAmount);

    (, uint256 lockPeriod, , , , , ) = masterchef.poolInfo(_pid);
    if (block.timestamp < user.lastDepositedTime + (lockPeriod * 1 days)) {
      uint256 penalty = (currentAmount * rebates[_pid].earlyWithdrawPenalty) / DIVISOR;
      token.safeTransfer(address(masterchef), penalty);
      currentAmount -= penalty;
      emit WithdrawPenalty(msg.sender, _pid, penalty);
    }

    token.safeTransfer(msg.sender, currentAmount);

    emit Withdraw(msg.sender, _pid, currentAmount, block.timestamp);
  }

  /**
   * @notice Harvests the pool rewards
   * @param _pid Pool id
   */
  function harvest(uint256 _pid) public notContract whenNotPaused {
    PoolInfo storage pool = pools[_pid];
    IERC20Upgradeable token = getTokenOfPool(_pid);

    uint256 prevBal = token.balanceOf(address(this));
    masterchef.claim(_pid);
    uint256 claimed = token.balanceOf(address(this)) - prevBal;

    uint256 currentCallFee = (claimed * callFee) / DIVISOR;
    claimed -= currentCallFee;
    pool.lastHarvestedTime = block.timestamp;
    pool.pendingClaim += claimed;
    if (currentCallFee > 0) {
      token.safeTransfer(msg.sender, currentCallFee);
    }

    _earn(_pid);

    emit Harvest(msg.sender, _pid, block.timestamp);
  }

  /**
   * @notice Returns the price per full share
   * @param _pid Pool id
   * @return Price per full share
   */
  function getPricePerFullShare(uint256 _pid) public view returns (uint256) {
    PoolInfo memory pool = pools[_pid];

    return pool.totalShares == 0 ? 1e18 : (balanceOf(_pid) * 1e18) / pool.totalShares;
  }

  /**
   * @notice Checks if the user can unstake
   * @param _user User address
   * @param _pid Pool id
   * @return Whether unstaking is allowed
   */
  function canUnstake(address _user, uint256 _pid) public view returns (bool) {
    UserInfo storage user = users[_pid][_user];
    (, uint256 lockPeriod, , , , , ) = masterchef.poolInfo(_pid);

    return (block.timestamp >= user.lastDepositedTime + (lockPeriod * 1 days) ||
      rebates[_pid].isEarlyWithdrawActive);
  }

  /**
   * @notice Returns the balance staked on the pool
   * @param _pid Pool id
   * @return Balance staked
   */
  function balanceOf(uint256 _pid) public view returns (uint256) {
    (uint256 amount, , , , ) = masterchef.users(_pid, address(this));

    return pools[_pid].pendingClaim + amount;
  }

  /**
   * @notice Stake token to the pool
   * @param _pid Pool id
   */
  function _earn(uint256 _pid) internal {
    uint256 bal = pools[_pid].pendingClaim;
    if (bal > 0) {
      masterchef.stake(_pid, bal);
      pools[_pid].pendingClaim = 0;
    }
  }

  /**
   * @notice Returns the token of the pool
   * @param _pid Pool id
   * @return Token of the pool
   */
  function getTokenOfPool(uint256 _pid) internal view returns (IERC20Upgradeable) {
    (, , , , , , address token) = masterchef.poolInfo(_pid);
    return IERC20Upgradeable(token);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IDecubateMasterChef {
  /**
   * @dev NFTMultiplier reflects the info of each NFT
   *
   * @param active if the NFT is active
   * @param name name of the NFT
   * @param contractAdd address of the NFT contract
   * @param multiplier multiplier of the NFT
   * @param startIdx start index of the NFT
   * @param endIdx end index of the NFT
   */
  struct NFTMultiplier {
    bool active;
    string name;
    address contractAdd;
    uint16 multiplier;
    uint16 startIdx;
    uint16 endIdx;
  }

  /**
   *
   * @dev User reflects the info of each user
   *
   *
   * @param {totalInvested} how many tokens the user staked
   * @param {totalWithdrawn} how many tokens withdrawn so far
   * @param {lastPayout} time at which last claim was done
   * @param {depositTime} Time of last deposit
   * @param {totalClaimed} Total claimed by the user
   *
   */
  struct User {
    uint256 totalInvested;
    uint256 totalWithdrawn;
    uint256 lastPayout;
    uint256 depositTime;
    uint256 totalClaimed;
  }

  function add(
    uint256 _apy,
    uint256 _lockPeriodInDays,
    uint256 _endDate,
    uint256 _hardCap,
    address token
  ) external;

  function set(
    uint256 _pid,
    uint256 _apy,
    uint256 _lockPeriodInDays,
    uint256 _endDate,
    uint256 _hardCap,
    uint256 _maxTransfer,
    address token
  ) external;

  function setNFT(
    uint256 _pid,
    string calldata _name,
    address _contractAdd,
    bool _isUsed,
    uint16 _multiplier,
    uint16 _startIdx,
    uint16 _endIdx
  ) external;

  function stake(uint256 _pid, uint256 _amount) external returns (bool);

  function claim(uint256 _pid) external returns (bool);

  function reinvest(uint256 _pid) external returns (bool);

  function reinvestAll() external returns (bool);

  function claimAll() external returns (bool);

  function handleNFTMultiplier(
    uint256 _pid,
    address _user,
    uint256 _rewardAmount
  ) external returns (uint256);

  function unStake(uint256 _pid, uint256 _amount) external returns (bool);

  function updateCompounder(address _compounder) external;

  function canClaim(uint256 _pid, address _addr) external view returns (bool);

  function calcMultiplier(uint256 _pid, address _addr) external view returns (uint16);

  function payout(uint256 _pid, address _addr) external view returns (uint256 value);

  function poolInfo(
    uint256
  )
    external
    view
    returns (
      uint256 apy,
      uint256 lockPeriodInDays,
      uint256 totalDeposit,
      uint256 startDate,
      uint256 endDate,
      uint256 hardCap,
      address token
    );

  function users(
    uint256,
    address
  )
    external
    view
    returns (
      uint256 totalInvested,
      uint256 totalWithdrawn,
      uint256 lastPayout,
      uint256 depositTime,
      uint256 totalClaimed
    );

  function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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