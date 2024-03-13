/**
 *Submitted for verification at Arbiscan.io on 2024-03-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    // Function to get the number of decimal places for the token
    function decimals() external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
        assembly { codehash := extcodehash(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IAggregator {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

interface ITreasury {
    function manage( address _token, uint _amount ) external;
}

interface IUinswapRouter {
  function WETH() external pure returns (address);
  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] memory path, address to, uint deadline) external returns (uint[] memory amounts);
}


contract Loan is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct PoolInfo {
        IERC20 token;
        uint rewardRate;
        uint accRewardShare;
        uint lendSupply;
        uint debtRate;
        uint accDebtShare;
        uint borrowSupply;
        uint lastTimestamp;
        address feed;
        uint lendLiquidated;
        uint borrowLiquidated;
    }

    PoolInfo[] public poolInfo;

    struct UserInfo {
      uint lent;
      uint borrowed;
      uint reward;
      uint debt;
    }

    mapping(uint => mapping(address => UserInfo)) public userInfo;

    address[] public borrowers;

    uint public borrowableRate = 8000; // 80%

    uint public liquidateRate = 9500; // 95%

    address public treasury;

    constructor(address _treasury) {
        require(_treasury != address(0));
        treasury = _treasury;
        borrowers.push(address(0));
    }

    function add(IERC20 _token, uint _rewardRate, uint _debtRate, address _feed) external onlyOwner {
        poolInfo.push(PoolInfo({
            token: _token,
            rewardRate: _rewardRate,
            accRewardShare: 0,
            lendSupply: 0,
            debtRate: _debtRate,
            accDebtShare: 0,
            borrowSupply: 0,
            lastTimestamp: block.timestamp,
            feed: _feed,
            lendLiquidated: 0,
            borrowLiquidated: 0
        }));
    }

    function set(uint _pid, uint _rewardRate, uint _debtRate, address _feed) external onlyOwner {
        poolInfo[_pid].rewardRate = _rewardRate;
        poolInfo[_pid].debtRate = _debtRate;
        poolInfo[_pid].feed = _feed;
    }

    function getMultiplier(uint _from, uint _to) public pure returns (uint) {
        return _to.sub(_from);
    }

    function pendingReward(uint _pid, address _user) public view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint accRewardShare = pool.accRewardShare;

        if (block.timestamp > pool.lastTimestamp) {
            uint multiplier = getMultiplier(pool.lastTimestamp, block.timestamp);
            accRewardShare = pool.accRewardShare.add(multiplier.mul(1e18).mul(pool.rewardRate).div(10000).div(365 days));
        }
        return user.lent.mul(accRewardShare).div(1e18).sub(user.reward);
    }

    function pendingDebt(uint _pid, address _user) public view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint accDebtShare = pool.accDebtShare;

        if (block.timestamp > pool.lastTimestamp) {
            uint multiplier = getMultiplier(pool.lastTimestamp, block.timestamp);
            accDebtShare = pool.accDebtShare.add(multiplier.mul(1e18).mul(pool.debtRate).div(10000).div(365 days));
        }
        return user.borrowed.mul(accDebtShare).div(1e18).sub(user.debt);
    }


    function updatePool(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastTimestamp) {
            return;
        }

        uint multiplier = getMultiplier(pool.lastTimestamp, block.timestamp);
        pool.accRewardShare = pool.accRewardShare.add(multiplier.mul(1e18).mul(pool.rewardRate).div(100).div(10512000));
        pool.accDebtShare = pool.accDebtShare.add(multiplier.mul(1e18).mul(pool.debtRate).div(100).div(10512000));
        pool.lastTimestamp = block.timestamp;
    }

    // deposit and compound
    function deposit(uint _pid, uint _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.lent > 0) {
            uint pending = user.lent.mul(pool.accRewardShare).div(1e18).sub(user.reward);
            if (pending > 0) {
                user.lent = user.lent.add(pending);
                pool.lendSupply = pool.lendSupply.add(pending);
            }
        }

        if (_amount > 0) {
            pool.token.safeTransferFrom(msg.sender, treasury, _amount);
            // pool.token.safeTransferFrom(msg.sender, address(this), _amount);
            user.lent = user.lent.add(_amount);
            pool.lendSupply = pool.lendSupply.add(_amount);
        }
        user.reward = user.lent.mul(pool.accRewardShare).div(1e18);
    }

    // withdraw and claim.
    function withdraw(uint _pid, uint _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lent >= _amount, "withdraw: not good");
        require(_amount < withdrawableToken(_pid, msg.sender), 'Collateral amount is small.');

        updatePool(_pid);
        uint pending = user.lent.mul(pool.accRewardShare).div(1e18).sub(user.reward);
        if (pending > 0) {
            ITreasury(treasury).manage(address(pool.token), pending);
            pool.token.safeTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.lent = user.lent.sub(_amount);
            ITreasury(treasury).manage(address(pool.token), _amount);
            pool.token.safeTransfer(msg.sender, _amount);
            pool.lendSupply = pool.lendSupply - _amount;
        }
        user.reward = user.lent.mul(pool.accRewardShare).div(1e18);
    }

    function borrow(uint _pid, uint _amount) external nonReentrant {
        uint index = getUserIndex(msg.sender);
        if (index == 0) {
          borrowers.push(msg.sender);
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount < borrowableToken(_pid, msg.sender), 'Collateral amount is small.');
        updatePool(_pid);

        if (user.borrowed > 0) {
            uint pending = user.borrowed.mul(pool.accDebtShare).div(1e18).sub(user.debt);
            if (pending > 0) {
                user.borrowed = user.borrowed.add(pending);
                pool.borrowSupply = pool.borrowSupply.add(pending);
            }
        }

        if (_amount > 0) {
            ITreasury(treasury).manage(address(pool.token), _amount);
            pool.token.safeTransfer(msg.sender, _amount);
            user.borrowed = user.borrowed.add(_amount);
            pool.borrowSupply = pool.borrowSupply.add(_amount);
        }
        user.debt = user.borrowed.mul(pool.accDebtShare).div(1e18);
  }

    function repay(uint _pid, uint _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint pending = user.borrowed.mul(pool.accDebtShare).div(1e18).sub(user.debt);
        require(user.borrowed + pending >= _amount, "repay: not good");
        if (pending > 0) {
          pool.token.safeTransferFrom(msg.sender, treasury, pending);
        //   pool.token.safeTransferFrom(msg.sender, address(this), pending);
        }
        if (_amount > 0) {
            user.borrowed = user.borrowed.sub(_amount);
            pool.token.safeTransferFrom(msg.sender, treasury, _amount);
            // pool.token.safeTransferFrom(msg.sender, address(this), _amount);
            pool.borrowSupply = pool.borrowSupply - _amount;
        }
        user.debt = user.borrowed.mul(pool.accDebtShare).div(1e18);
    }

    function getCollateralUsd(address _user) public view returns (uint) {
        uint colllateral = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_user];
            uint decimals = pool.token.decimals();            
            ( , int price, , , ) = IAggregator(pool.feed).latestRoundData();
            uint pending = pendingReward(i, _user);
            colllateral = colllateral.add(user.lent.add(pending).mul(1e18).div(10 ** decimals).mul(uint(price)));
        }
        return colllateral.div(1e18);
    }

    function getBorrowedUsd(address _user) public view returns (uint) {
        uint borrowed = 0;
        for (uint i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            UserInfo storage user = userInfo[i][_user];
            uint decimals = pool.token.decimals();            
            ( , int price, , , ) = IAggregator(pool.feed).latestRoundData();
            uint pending = pendingDebt(i, _user);
            borrowed = borrowed.add(user.borrowed.add(pending).mul(1e18).div(10 ** decimals).mul(uint(price)));
        }
        return borrowed.div(1e18);
    }

    function borrowableUsd(address _user) public view returns (uint) {
        uint colllateral = getCollateralUsd(_user);
        uint borrowed = getBorrowedUsd(_user);
        uint collateralRated = colllateral.mul(borrowableRate).div(10000);
        if (collateralRated >= borrowed) {
            return collateralRated.sub(borrowed);
        }
        return 0;
    }

    function borrowableToken(uint _pid, address _user) public view returns (uint) {
        uint borrowableAmount = borrowableUsd(_user);
        PoolInfo storage pool = poolInfo[_pid];
        ( , int price, , , ) = IAggregator(pool.feed).latestRoundData();
        uint decimals = pool.token.decimals();
        uint borrowableTokenAmount = borrowableAmount.mul(10 ** decimals).div(uint(price));
        return borrowableTokenAmount;
    }

    function withdrawableUsd(address _user) public view returns (uint) {
        uint colllateral = getCollateralUsd(_user);
        uint borrowed = getBorrowedUsd(_user);
        uint borrowedRated = borrowed.mul(10000).div(borrowableRate);
        if (colllateral >= borrowedRated) {
            return colllateral.sub(borrowedRated);
        }
        return 0;
    }

    function withdrawableToken(uint _pid, address _user) public view returns (uint) {
        uint withdrawableAmount = withdrawableUsd(_user);
        PoolInfo storage pool = poolInfo[_pid];
        ( , int price, , , ) = IAggregator(pool.feed).latestRoundData();
        uint decimals = pool.token.decimals();
        uint withdrawableTokenAmount = withdrawableAmount.mul(10 ** decimals).div(uint(price));
        return withdrawableTokenAmount;
    }

    function borrowablePool(uint _pid) public view returns (uint) {
        PoolInfo storage pool = poolInfo[_pid];
        uint poolBalance = pool.token.balanceOf(treasury);
        // uint poolBalance = pool.token.balanceOf(address(this));
        return poolBalance;
    }

    function setBorrowableRate(uint _borrowableRate) public onlyOwner {
        require(_borrowableRate <= 10000, 'max is 100%.');
        borrowableRate = _borrowableRate;
    }

    function setLiquidateRate(uint _liquidateRate) public onlyOwner {
        require(_liquidateRate <= 10000, 'max is 100%.');
        liquidateRate = _liquidateRate;
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0));
        treasury = _treasury;      
    }

    function getUserIndex(address _user) public view returns (uint) {
        for (uint i = 0; i < borrowers.length; i++) {
            if (borrowers[i] == _user) {
                return i;
            }
        }
        return 0;
    }

    function checkLiquidate(address _user) public view returns (bool) {
        uint colllateral = getCollateralUsd(_user);
        if (colllateral == 0) {
            return false;
        }
        uint borrowed = getBorrowedUsd(_user);
        if (colllateral.mul(liquidateRate).div(10000) <= borrowed) {
            return true;
        }
        return false;
    }

    function liquidate(address[] memory _users) public {
        for (uint i = 0; i < _users.length; i++) {
            address _user = _users[i];
            require(checkLiquidate(_user), 'This user cannot liquidate.');
            for (uint _pid = 0; _pid < poolInfo.length; _pid++) {
                PoolInfo storage pool = poolInfo[_pid];
                UserInfo storage user = userInfo[_pid][_user];
                pool.lendSupply = pool.lendSupply.sub(user.lent);
                pool.lendLiquidated = pool.lendLiquidated.add(user.lent);
                pool.borrowSupply = pool.borrowSupply.sub(user.borrowed);
                pool.borrowLiquidated = pool.borrowLiquidated.add(user.borrowed);
                user.lent = 0;
                user.borrowed = 0;
                user.reward = 0;
                user.debt = 0;
            }
        }
    }

    function swap(uint _pid1, uint _pid2, uint _amount, address _router) public onlyOwner {
        PoolInfo storage pool1 = poolInfo[_pid1];
        PoolInfo storage pool2 = poolInfo[_pid2];
        ITreasury(treasury).manage(address(pool1.token), _amount);
        if (pool1.token.allowance(address(this), _router) == 0) {
            pool1.token.approve(_router, type(uint256).max);
        }
        if (address(pool1.token) == address(IUinswapRouter(_router).WETH()) || address(pool2.token) == address(IUinswapRouter(_router).WETH())) {
            address[] memory path = new address[](2);
            path[0] = address(pool1.token);
            path[1] = address(pool2.token);
            uint[] memory amounts = IUinswapRouter(_router).swapExactTokensForTokens(_amount, 0, path, treasury, block.timestamp);
            pool1.lendLiquidated = pool1.lendLiquidated.sub(amounts[0]);
            pool2.borrowLiquidated = pool2.borrowLiquidated.add(amounts[1]);
        } else {
            address[] memory path = new address[](3);
            path[0] = address(pool1.token);
            path[1] = IUinswapRouter(_router).WETH();
            path[2] = address(pool2.token);
            uint[] memory amounts = IUinswapRouter(_router).swapExactTokensForTokens(_amount, 0, path, treasury, block.timestamp);
            pool1.lendLiquidated = pool1.lendLiquidated.sub(amounts[0]);
            pool2.borrowLiquidated = pool2.borrowLiquidated.add(amounts[2]);
        }        
    }

    function poolLength() public view returns (uint) {
        return poolInfo.length;
    }

    function borrowersLength() public view returns (uint) {
        return borrowers.length;
    }
}