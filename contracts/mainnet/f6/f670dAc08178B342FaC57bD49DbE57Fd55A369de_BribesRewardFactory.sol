// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "./BribesRewardPool.sol";

/**
 * @title   BribesRewardFactory
 * @author  ConvexFinance -> WombexFinance
 */
contract BribesRewardFactory {
    using Address for address;

    address public immutable operator;

    event RewardPoolCreated(address rewardPool, address depositToken);

    /**
     * @param _operator   Contract operator is Booster
     */
    constructor(address _operator) public {
        operator = _operator;
    }

    /**
     * @notice Create a Managed Reward Pool to handle distribution of all crv/wom mined in a pool
     */
    function CreateBribesRewards(address _stakingToken, address _lptoken, bool _callOperatorOnGetReward) external returns (address) {
        require(msg.sender == operator, "!auth");

        BribesRewardPool rewardPool = new BribesRewardPool(_stakingToken, operator, _lptoken, _callOperatorOnGetReward);

        emit RewardPoolCreated(address(rewardPool), _stakingToken);
        return address(rewardPool);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./vendor/BaseRewardPool4626.sol";

contract BribesRewardPool is BaseRewardPool4626 {
    bool public callOperatorOnGetReward;

    event UpdateBribesConfig(bool callOperatorOnGetReward);
    event UpdateRatioConfig(uint256 duration, uint256 maxRewardRatio);

    constructor(
        address stakingToken_,
        address operator_,
        address lptoken_,
        bool _callOperatorOnGetReward
    ) public BaseRewardPool4626(0, stakingToken_, address(0), operator_, lptoken_) {
        callOperatorOnGetReward = _callOperatorOnGetReward;
    }

    function updateBribesConfig(bool _callOperatorOnGetReward) external {
        require(msg.sender == operator, "!authorized");
        callOperatorOnGetReward = _callOperatorOnGetReward;

        emit UpdateBribesConfig(callOperatorOnGetReward);
    }

    function updateRatioConfig(uint256 _duration, uint256 _newRewardRatio) external {
        require(msg.sender == operator, "!authorized");
        duration = _duration;
        newRewardRatio = _newRewardRatio;

        emit UpdateRatioConfig(_duration, _newRewardRatio);
    }

    function stake(uint256 _amount) public override returns(bool) {
        require(false, "disabled");
        return true;
    }

    function stakeFor(address _for, uint256 _amount) public override returns(bool) {
        require(msg.sender == operator, "!operator");
        return BaseRewardPool.stakeFor(_for, _amount);
    }

    function _getReward(address _account, address _claimTo, bool _lockCvx, address[] memory _claimTokens) internal override returns(bool result) {
        result = BaseRewardPool._getReward(_account, _claimTo, _lockCvx, _claimTokens);
        if (callOperatorOnGetReward) {
            IDeposit(operator).rewardClaimed(0, _account, 0, false);
        }
        return result;
    }

    function withdraw(uint256 amount, bool claim) public override returns(bool) {
        require(false, "disabled");
        return true;
    }

    function _withdrawAndUnwrapTo(uint256 amount, address from, address receiver) internal override returns(bool) {
        require(false, "disabled");
        return true;
    }

    function withdrawAndUnwrapFrom(address _from, uint256 _amount, address _claimRecipient) public returns(bool) {
        require(msg.sender == operator, "!operator");

        BaseRewardPool._getReward(_from, _claimRecipient, false, allRewardTokens);

        _totalSupply = _totalSupply.sub(_amount);
        _balances[_from] = _balances[_from].sub(_amount);

        emit Withdrawn(_from, _amount);

        return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override returns (string memory) {
        return string(
            abi.encodePacked(IERC20Metadata(asset).name(), " Bribes Vault")
        );
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view override returns (string memory) {
        return string(
            abi.encodePacked(IERC20Metadata(asset).symbol(), "-bribes")
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: BaseRewardPool.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./interfaces/Interfaces.sol";
import "./interfaces/MathUtil.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   BaseRewardPool
 * @author  Synthetix -> ConvexFinance -> WombexFinance
 * @notice  Unipool rewards contract that is re-deployed from rFactory for each staking pool.
 * @dev     Changes made here by ConvexFinance are to do with the delayed reward allocation. Curve is queued for
 *          rewards and the distribution only begins once the new rewards are sufficiently large, or the epoch
 *          has ended. Also some changes from WombexFinance.
 */
contract BaseRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable boosterRewardToken;
    uint256 public constant MAX_TOKENS = 100;
    uint256 public duration = 7 days;
    uint256 public newRewardRatio = 830;

    address public operator;
    uint256 public pid;

    mapping(address => uint256) internal _balances;
    uint256 internal _totalSupply;

    struct RewardState {
        address token;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 currentRewards;
        uint256 historicalRewards;
        bool paused;
    }

    mapping(address => RewardState) public tokenRewards;
    address[] public allRewardTokens;

    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    event UpdateOperatorData(address indexed sender, address indexed operator, uint256 indexed pid);
    event UpdateRatioData(address indexed sender, uint256 duration, uint256 newRewardRatio);
    event SetRewardTokenPaused(address indexed sender, address indexed token, bool indexed paused);
    event RewardAdded(address indexed token, uint256 currentRewards, uint256 newRewards);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed token, address indexed user, uint256 reward);
    event Donate(address indexed token, uint256 amount);

    /**
     * @dev This is called directly from RewardFactory
     * @param pid_                  Effectively the pool identifier - used in the Booster
     * @param stakingToken_         Pool LP token
     * @param boosterRewardToken_   Reward token for call booster on queueNewRewards
     * @param operator_             Booster
     */
    constructor(
        uint256 pid_,
        address stakingToken_,
        address boosterRewardToken_,
        address operator_
    ) public {
        pid = pid_;
        stakingToken = IERC20(stakingToken_);
        boosterRewardToken = IERC20(boosterRewardToken_);
        operator = operator_;
    }

    function updateOperatorData(address operator_, uint256 pid_) external {
        require(msg.sender == operator, "!authorized");
        operator = operator_;
        pid = pid_;

        _onOperatorUpdate();

        emit UpdateOperatorData(msg.sender, operator_, pid_);
    }

    function setRewardParams(uint256 duration_, uint256 newRewardRatio_) external {
        require(msg.sender == IBooster(operator).owner(), "!authorized");
        duration = duration_;
        newRewardRatio = newRewardRatio_;

        emit UpdateRatioData(msg.sender, duration_, newRewardRatio_);
    }

    function setRewardTokenPaused(address token_, bool paused_) external {
        require(msg.sender == operator, "!authorized");

        tokenRewards[token_].paused = paused_;

        emit SetRewardTokenPaused(msg.sender, token_, paused_);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    modifier updateReward(address account) {
        uint256 len = allRewardTokens.length;
        for (uint256 i = 0; i < len; i++) {
            RewardState storage rState = tokenRewards[allRewardTokens[i]];

            rState.rewardPerTokenStored = _rewardPerToken(rState);
            rState.lastUpdateTime = _lastTimeRewardApplicable(rState);
            if (account != address(0)) {
                rewards[rState.token][account] = _earned(rState, account);
                userRewardPerTokenPaid[rState.token][account] = rState.rewardPerTokenStored;
            }
        }
        _;
    }

    function lastTimeRewardApplicable(address _token) public view returns (uint256) {
        return _lastTimeRewardApplicable(tokenRewards[_token]);
    }

    function rewardPerToken(address _token) public view returns (uint256) {
        return _rewardPerToken(tokenRewards[_token]);
    }

    function earned(address _token, address _account) public view returns (uint256) {
        return _earned(tokenRewards[_token], _account);
    }

    function claimableRewards(address _account) external view returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = allRewardTokens;
        amounts = new uint256[](allRewardTokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            amounts[i] = _earned(tokenRewards[tokens[i]], _account);
        }
    }

    function stake(uint256 _amount) public virtual returns(bool) {
        _processStake(_amount, msg.sender);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);

        return true;
    }

    function stakeAll() external returns(bool) {
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stake(balance);
        return true;
    }

    function stakeFor(address _for, uint256 _amount) public virtual returns(bool) {
        _processStake(_amount, _for);

        //take away from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_for, _amount);

        return true;
    }

    /**
     * @dev Generic internal staking function that basically does 3 things: update rewards based
     *      on previous balance, trigger also on any child contracts, then update balances.
     * @param _amount    Units to add to the users balance
     * @param _receiver  Address of user who will receive the stake
     */
    function _processStake(uint256 _amount, address _receiver) internal updateReward(_receiver) {
        require(_amount > 0, 'RewardPool : Cannot stake 0');

        _totalSupply = _totalSupply.add(_amount);
        _balances[_receiver] = _balances[_receiver].add(_amount);
    }

    function withdraw(uint256 amount, bool claim)
        public
        virtual
        updateReward(msg.sender)
        returns(bool)
    {
        require(amount > 0, 'RewardPool : Cannot withdraw 0');

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);

        if(claim){
            getReward(msg.sender, false);
        }

        return true;
    }

    function withdrawAndUnwrap(uint256 amount, bool claim) public virtual returns(bool) {
        _withdrawAndUnwrapTo(amount, msg.sender, msg.sender);
        //get rewards too
        if(claim){
            getReward(msg.sender, false);
        }
        return true;
    }

    function _withdrawAndUnwrapTo(uint256 amount, address from, address receiver) internal virtual updateReward(from) returns(bool){
        _totalSupply = _totalSupply.sub(amount);
        _balances[from] = _balances[from].sub(amount);

        //tell operator to withdraw from here directly to user
        IDeposit(operator).withdrawTo(pid,amount,receiver);
        emit Withdrawn(from, amount);

        return true;
    }

    function withdrawAllAndUnwrap(bool claim) external{
        withdrawAndUnwrap(_balances[msg.sender],claim);
    }

    /**
     * @dev Called by a staker to get their allocated rewards
     */
    function getReward() external returns(bool){
        return _getReward(msg.sender, msg.sender, false, allRewardTokens);
    }

    /**
     * @dev Gives a staker their rewards, with the option of claiming extra rewards
     * @param _account     Account for which to claim
     * @param _lockCvx     Get the child rewards too?
     */
    function getReward(address _account, bool _lockCvx) public virtual returns(bool){
        return _getReward(_account, _account, _lockCvx, allRewardTokens);
    }

    /**
     * @dev Gives a staker their rewards, with the option of claiming extra rewards
     * @param _account     Account for which to claim
     * @param _lockCvx     Get the child rewards too?
     */
    function getReward(address _account, bool _lockCvx, address[] memory _claimTokens) public virtual returns(bool){
        return _getReward(_account, _account, _lockCvx, _claimTokens);
    }

    function _getReward(address _account, address _claimTo, bool _lockCvx, address[] memory _claimTokens) internal virtual updateReward(_account) returns(bool) {
        uint256 len = _claimTokens.length;
        for (uint256 i = 0; i < len; i++) {
            RewardState storage rState = tokenRewards[_claimTokens[i]];
            if (rState.paused || rState.lastUpdateTime == 0) {
                continue;
            }

            uint256 reward = _earned(rState, _account);
            if (reward > 0) {
                rewards[rState.token][_account] = 0;
                IERC20(rState.token).safeTransfer(_claimTo, reward);
                if (rState.token == address(boosterRewardToken)) {
                    IDeposit(operator).rewardClaimed(pid, _account, reward, _lockCvx);
                }
                emit RewardPaid(rState.token, _account, reward);
            }
        }
        return true;
    }

    /**
     * @dev Donate some extra rewards to this contract
     */
    function donate(address _token, uint256 _amount) external {
        require(_token != address(boosterRewardToken), "booster_reward_token");
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _amount = IERC20(_token).balanceOf(address(this)).sub(balanceBefore);

        tokenRewards[_token].queuedRewards = tokenRewards[_token].queuedRewards.add(_amount);

        emit Donate(_token, _amount);
    }

    /**
     * @dev Processes queued rewards in isolation, providing the period has finished.
     *      This allows a cheaper way to trigger rewards on low value pools.
     */
    function processIdleRewards() external {
        uint256 len = allRewardTokens.length;
        for (uint256 i = 0; i < len; i++) {
            RewardState storage rState = tokenRewards[allRewardTokens[i]];
            if (block.timestamp >= rState.periodFinish && rState.queuedRewards > 0) {
                _notifyRewardAmount(rState, rState.queuedRewards);
                rState.queuedRewards = 0;
            }
        }
    }

    /**
     * @dev Called by the booster to allocate new Crv/WOM rewards to this pool
     *      Curve is queued for rewards and the distribution only begins once the new rewards are sufficiently
     *      large, or the epoch has ended.
     */
    function queueNewRewards(address _token, uint256 _rewards) external returns(bool){
        require(msg.sender == operator, "!authorized");

        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _rewards);

        _rewards = IERC20(_token).balanceOf(address(this)).sub(balanceBefore);

        RewardState storage rState = tokenRewards[_token];
        if (rState.lastUpdateTime == 0) {
            rState.token = _token;
            allRewardTokens.push(_token);
            require(allRewardTokens.length <= MAX_TOKENS, "!`max_tokens`");
        }
        _rewards = _rewards.add(rState.queuedRewards);

        if (block.timestamp >= rState.periodFinish) {
            _notifyRewardAmount(rState, _rewards);
            rState.queuedRewards = 0;
            return true;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(rState.periodFinish.sub(duration));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rState.rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);

        //uint256 queuedRatio = currentRewards.mul(1000).div(_rewards);
        if(queuedRatio < newRewardRatio){
            _notifyRewardAmount(rState, _rewards);
            rState.queuedRewards = 0;
        }else{
            rState.queuedRewards = _rewards;
        }
        return true;
    }

    function _notifyRewardAmount(RewardState storage _rState, uint256 _reward)
        internal
        updateReward(address(0))
    {
        _rState.historicalRewards = _rState.historicalRewards.add(_reward);
        if (block.timestamp >= _rState.periodFinish) {
            _rState.rewardRate = _reward.div(duration);
        } else {
            uint256 remaining = _rState.periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(_rState.rewardRate);
            _reward = _reward.add(leftover);
            _rState.rewardRate = _reward.div(duration);
        }
        _rState.currentRewards = _reward;
        _rState.lastUpdateTime = block.timestamp;
        _rState.periodFinish = block.timestamp.add(duration);
        emit RewardAdded(_rState.token, _rState.currentRewards, _reward);
    }

    function _lastTimeRewardApplicable(RewardState storage _rState) internal view returns (uint256) {
        return MathUtil.min(block.timestamp, _rState.periodFinish);
    }

    function _earned(RewardState storage _rState, address account) internal view returns (uint256) {
        return
        balanceOf(account)
            .mul(_rewardPerToken(_rState).sub(userRewardPerTokenPaid[_rState.token][account]))
            .div(1e18)
            .add(rewards[_rState.token][account]);
    }

    function _rewardPerToken(RewardState storage _rState) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return _rState.rewardPerTokenStored;
        }
        return
            _rState.rewardPerTokenStored.add(
                _lastTimeRewardApplicable(_rState)
                .sub(_rState.lastUpdateTime)
                .mul(_rState.rewardRate)
                .mul(1e18)
                .div(totalSupply())
            );
    }

    function DURATION() external view returns (uint256) {
        return duration;
    }

    function NEW_REWARD_RATIO() external view returns (uint256) {
        return newRewardRatio;
    }

    function rewardTokensLen() external view returns (uint256) {
        return allRewardTokens.length;
    }

    function rewardTokensList() external view returns (address[] memory) {
        return allRewardTokens;
    }

    function _onOperatorUpdate() internal virtual {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { BaseRewardPool, IDeposit } from "./BaseRewardPool.sol";
import { IERC4626, IERC20Metadata } from "./interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts-0.6/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   BaseRewardPool4626
 * @notice  Simply wraps the BaseRewardPool with the new IERC4626 Vault standard functions.
 * @dev     See https://github.com/fei-protocol/ERC4626/blob/main/src/interfaces/IERC4626.sol#L58
 *          This is not so much a vault as a Reward Pool, therefore asset:share ratio is always 1:1.
 *          To create most utility for this RewardPool, the "asset" has been made to be the crvLP(Wombat LP) token,
 *          as opposed to the cvxLP (wmxLP) token. Therefore, users can easily deposit crvLP(Wombat LP), and it will first
 *          go to the Booster and mint the cvxLP(wmxLP) before performing the normal staking function.
 */
contract BaseRewardPool4626 is BaseRewardPool, ReentrancyGuard, IERC4626 {
    using SafeERC20 for IERC20;

    /**
     * @notice The address of the underlying ERC20 token used for
     * the Vault for accounting, depositing, and withdrawing.
     */
    address public override asset;

    mapping (address => mapping (address => uint256)) private _allowances;

    /**
     * @dev See BaseRewardPool.sol
     */
    constructor(
        uint256 pid_,
        address stakingToken_,
        address rewardToken_,
        address operator_,
        address lptoken_
    ) public BaseRewardPool(pid_, stakingToken_, rewardToken_, operator_) {
        asset = lptoken_;
        IERC20(asset).safeApprove(operator_, type(uint256).max);
    }

    function _onOperatorUpdate() internal override {
        IERC20(asset).safeApprove(operator, 0);
        IERC20(asset).safeApprove(operator, type(uint256).max);
    }

    /**
     * @notice Total amount of the underlying asset that is "managed" by Vault.
     */
    function totalAssets() external view virtual override returns(uint256){
        return totalSupply();
    }

    /**
     * @notice Mints `shares` Vault shares to `receiver`.
     * @dev Because `asset` is not actually what is collected here, first wrap to required token in the booster.
     */
    function deposit(uint256 assets, address receiver) public virtual override nonReentrant returns (uint256) {
        // Transfer "asset" (crvLP) from sender
        IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        // Convert crvLP to cvxLP through normal booster deposit process, but don't stake
        uint256 balBefore = stakingToken.balanceOf(address(this));
        IDeposit(operator).deposit(pid, assets, false);
        uint256 balAfter = stakingToken.balanceOf(address(this));

        require(balAfter.sub(balBefore) >= assets, "!deposit");

        // Perform stake manually, now that the funds have been received
        _processStake(assets, receiver);

        emit Deposit(msg.sender, receiver, assets, assets);
        emit Staked(receiver, assets);
        return assets;
    }

    /**
     * @notice Mints exactly `shares` Vault shares to `receiver`
     * by depositing `assets` of underlying tokens.
     */
    function mint(uint256 shares, address receiver) external virtual override returns (uint256) {
        return deposit(shares, receiver);
    }

    /**
     * @notice Redeems `shares` from `owner` and sends `assets`
     * of underlying tokens to `receiver`.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override nonReentrant returns (uint256) {
        if (msg.sender != owner) {
            _approve(owner, msg.sender, _allowances[owner][msg.sender].sub(assets, "ERC4626: withdrawal amount exceeds allowance"));
        }

        _withdrawAndUnwrapTo(assets, owner, receiver);

        emit Withdraw(msg.sender, receiver, owner, assets, assets);
        return assets;
    }

    /**
     * @notice Redeems `shares` from `owner` and sends `assets`
     * of underlying tokens to `receiver`.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override returns (uint256) {
        return withdraw(shares, receiver, owner);
    }

    /**
     * @notice The amount of shares that the vault would
     * exchange for the amount of assets provided, in an
     * ideal scenario where all the conditions are met.
     */
    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return assets;
    }

    /**
     * @notice The amount of assets that the vault would
     * exchange for the amount of shares provided, in an
     * ideal scenario where all the conditions are met.
     */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return shares;
    }

    /**
     * @notice Total number of underlying assets that can
     * be deposited by `owner` into the Vault, where `owner`
     * corresponds to the input parameter `receiver` of a
     * `deposit` call.
     */
    function maxDeposit(address /* owner */) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their deposit at the current block, given
     * current on-chain conditions.
     */
    function previewDeposit(uint256 assets) external view virtual override returns(uint256){
        return convertToShares(assets);
    }

    /**
     * @notice Total number of underlying shares that can be minted
     * for `owner`, where `owner` corresponds to the input
     * parameter `receiver` of a `mint` call.
     */
    function maxMint(address owner) external view virtual override returns (uint256) {
        return maxDeposit(owner);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their mint at the current block, given
     * current on-chain conditions.
     */
    function previewMint(uint256 shares) external view virtual override returns(uint256){
        return convertToAssets(shares);
    }

    /**
     * @notice Total number of underlying assets that can be
     * withdrawn from the Vault by `owner`, where `owner`
     * corresponds to the input parameter of a `withdraw` call.
     */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     */
    function previewWithdraw(uint256 assets) public view virtual override returns(uint256 shares){
        return convertToShares(assets);
    }

    /**
     * @notice Total number of underlying shares that can be
     * redeemed from the Vault by `owner`, where `owner` corresponds
     * to the input parameter of a `redeem` call.
     */
    function maxRedeem(address owner) external view virtual override returns (uint256) {
        return maxWithdraw(owner);
    }
    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their redeemption at the current block,
     * given current on-chain conditions.
     */
    function previewRedeem(uint256 shares) external view virtual override returns(uint256){
        return previewWithdraw(shares);
    }


    /* ========== IERC20 ========== */

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return string(
            abi.encodePacked(IERC20Metadata(address(stakingToken)).name(), " Vault")
        );
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view virtual override returns (string memory) {
        return string(
            abi.encodePacked(IERC20Metadata(address(stakingToken)).symbol(), "-vault")
        );
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view override returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() public view override(BaseRewardPool, IERC20) returns (uint256) {
        return BaseRewardPool.totalSupply();
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view override(BaseRewardPool, IERC20) returns (uint256) {
        return BaseRewardPool.balanceOf(account);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address /* recipient */, uint256 /* amount */) external override returns (bool) {
        revert("ERC4626: Not supported");
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC4626: approve from the zero address");
        require(spender != address(0), "ERC4626: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     */
    function transferFrom(address /* sender */, address /* recipient */, uint256 /* amount */) external override returns (bool) {
        revert("ERC4626: Not supported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import { IERC20 } from "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";

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
pragma solidity 0.6.12;

import { IERC20Metadata } from "./IERC20Metadata.sol";

/// @title ERC4626 interface
/// See: https://eips.ethereum.org/EIPS/eip-4626

abstract contract IERC4626 is IERC20Metadata {

    /*////////////////////////////////////////////////////////
                      Events
    ////////////////////////////////////////////////////////*/

    /// @notice `caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /// @notice `caller` has exchanged `shares`, owned by `owner`, for
    ///         `assets`, and transferred those `assets` to `receiver`.
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view virtual returns(address);

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() external view virtual returns(uint256);

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Mints `shares` Vault shares to `receiver` by
    /// depositing exactly `assets` of underlying tokens.
    function deposit(uint256 assets, address receiver) external virtual returns(uint256 shares);

    /// @notice Mints exactly `shares` Vault shares to `receiver`
    /// by depositing `assets` of underlying tokens.
    function mint(uint256 shares, address receiver) external virtual returns(uint256 assets);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function withdraw(uint256 assets, address receiver, address owner) external virtual returns(uint256 shares);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function redeem(uint256 shares, address receiver, address owner) external virtual returns(uint256 assets);

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of shares provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view virtual returns(uint256 assets);

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner) external view virtual returns(uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner) external view virtual returns(uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 shares) external view virtual returns(uint256 assets);

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner) external view virtual returns(uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner) external view virtual returns(uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 shares) external view virtual returns(uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterWombat {
    function deposit(uint256 _pid, uint256 _amount) external;
    function balanceOf(address) external view returns(uint256);
    function userInfo(uint256, address) external view returns (uint128 amount, uint128 factor, uint128 rewardDebt, uint128 pendingWom);
    function withdraw(uint256 _pid, uint256 _amount) external;
    function poolLength() external view returns(uint256);
    function poolInfo(uint256 _pid) external view returns (address lpToken, uint96 allocPoint, IMasterWombatRewarder rewarder, uint256 sumOfFactors, uint104 accWomPerShare, uint104 accWomPerFactorShare, uint40 lastRewardTimestamp);
    function migrate(uint256[] calldata _pids) external view;
    function newMasterWombat() external view returns (address);
}

interface IMasterWombatRewarder {
    function rewardTokens() external view returns (address[] memory tokens);
}

interface IBooster {
    function owner() external view returns(address);
}

interface IVeWom {
    function mint(uint256 amount, uint256 lockDays) external returns (uint256 veWomAmount);
    function burn(uint256 slot) external;
    function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
}

interface IVoting{
    function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
    function getVote(uint256) external view returns(bool,bool,uint64,uint64,uint64,uint64,uint256,uint256,uint256,bytes memory);
    function vote_for_gauge_weights(address,uint256) external;
}

interface IMinter{
    function mint(address) external;
    function updateOperator() external;
    function operator() external returns(address);
}

interface ICvxLocker {
    function lock(address _account, uint256 _amount) external;
}

interface IStaker{
    function deposit(address, address) external returns (bool);
    function withdraw(address) external returns (uint256);
    function withdrawLp(address, address, uint256) external returns (bool);
    function withdrawAllLp(address, address) external returns (bool);
    function lock(uint256 _lockDays) external;
    function releaseLock(uint256 _slot) external returns(uint256);
    function getGaugeRewardTokens(address _lptoken, address _gauge) external returns (address[] memory tokens);
    function claimCrv(address, address) external returns (address[] memory tokens);
    function balanceOfPool(address, address) external view returns (uint256);
    function operator() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (bool, bytes memory);
    function setVote(bytes32 hash, bool valid) external;
    function setOperator(address _operator) external;
    function setOwner(address _owner) external;
    function setDepositor(address _depositor) external;
    function lpTokenToPid(address _gauge, address _lptoken) external view returns (uint256);
    function lpTokenPidSet(address _gauge, address _lptoken) external view returns (bool);
}

interface IBoosterEarmark {
    function earmarkRewards(uint256 _pid) external;
    function earmarkIncentive() external view returns (uint256);
    function distributionByTokenLength(address _token) external view returns (uint256);
    function distributionByTokens(address, uint256) external view returns (address, uint256, bool);
    function distributionTokenList() external view returns (address[] memory);
    function updateDistributionByTokens(address _token, address[] memory _distros, uint256[] memory _shares, bool[] memory _callQueue) external;
    function setEarmarkConfig(uint256 _earmarkIncentive) external;
    function transferOwnership(address newOwner) external;
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
}

interface IRewards{
    function pid() external view returns(uint256);
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(address, uint256) external;
    function notifyRewardAmount(uint256) external;
    function setRewardTokenPaused(address, bool) external;
    function updateOperatorData(address, uint256) external;
    function addExtraReward(address) external;
    function extraRewardsLength() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns(address);
    function earned(address account) external view returns (uint256);
    function setRatioData(uint256 duration_, uint256 newRewardRatio_) external;
}

interface ITokenMinter{
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function updateOperator(address) external;
}

interface IDeposit{
    function isShutdown() external view returns(bool);
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
    function rewardClaimed(uint256,address,uint256,bool) external;
    function withdrawTo(uint256,uint256,address) external;
    function claimRewards(uint256,address) external returns(bool);
    function rewardArbitrator() external returns(address);
    function setGaugeRedirect(uint256 _pid) external returns(bool);
    function owner() external returns(address);
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
}

interface ICrvDeposit{
    function deposit(uint256, bool) external;
    function lockIncentive() external view returns(uint256);
}

interface IRewardFactory{
    function setAccess(address,bool) external;
    function CreateCrvRewards(uint256,address,address) external returns(address);
    function CreateTokenRewards(address,address,address) external returns(address);
    function activeRewardCount(address) external view returns(uint256);
    function addActiveReward(address,uint256) external returns(bool);
    function removeActiveReward(address,uint256) external returns(bool);
}

interface IStashFactory{
    function CreateStash(uint256,address,address,uint256) external returns(address);
}

interface ITokenFactory{
    function CreateDepositToken(address) external returns(address);
}

interface IPools{
    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
    function forceAddPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
    function shutdownPool(uint256 _pid) external returns(bool);
    function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
    function poolLength() external view returns (uint256);
    function gaugeMap(address) external view returns(bool);
    function setPoolManager(address _poolM) external;
}

interface IVestedEscrow{
    function fund(address[] calldata _recipient, uint256[] calldata _amount) external returns(bool);
}

interface IRewardDeposit {
    function addReward(address, uint256) external;
}

interface IWETH {
    function deposit() external payable;
}

interface IExtraRewardsDistributor {
    function addReward(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUtil {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}