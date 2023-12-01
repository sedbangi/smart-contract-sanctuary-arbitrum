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

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../IAdapter.sol";

import "../../lib/weth/WethExchange.sol";
import "../../lib/uniswapv2/NewUniswapV2.sol";
import "../../lib/uniswapv3/UniswapV3.sol";
import "../../lib/kyberdmm/KyberDmm.sol";
import "../../lib/balancerv2/BalancerV2.sol";
import "../../lib/curve/Curve.sol";
import "../../lib/curve/CurveV2.sol";
import "../../lib/saddle/SaddleAdapter.sol";
import "../../lib/gmx/GMX.sol";
import "../../lib/dodo/DODO.sol";
import "../..//lib/dodov2/DODOV2.sol";
import "../../lib/aave-v3/AaveV3.sol";
import "../../lib/augustus-rfq/AugustusRFQ.sol";
import "../../lib/hashflow/HashFlow.sol";

/**
 * @dev This contract will route call to different exchanges
 * 1 - WETH
 * 2 - UniswapV2Forks
 * 3 - UniswapV3
 * 4 - KyberDMM
 * 5 - BalancerV2
 * 6 - Curve
 * 7 - CurveV2
 * 8 - Saddle
 * 9 - GMX
 * 10 - DODO
 * 11 - DODOV2
 * 12 - AaveV3
 * 13 - AugustusRFQ
 * 14 - HashFlow
 * The above are the indexes
 */
contract ArbitrumAdapter01 is
    IAdapter,
    WethExchange,
    NewUniswapV2,
    UniswapV3,
    KyberDmm,
    BalancerV2,
    Curve,
    CurveV2,
    SaddleAdapter,
    GMX,
    DODO,
    DODOV2,
    AaveV3,
    AugustusRFQ,
    HashFlow
{
    using SafeMath for uint256;

    constructor(
        address _weth,
        address _dodoErc20ApproveProxy,
        uint256 _dodoSwapLimitOverhead,
        uint16 _aaveV3RefCode,
        address _aaveV3Pool,
        address _aaveV3WethGateway
    )
        public
        WethProvider(_weth)
        DODO(_dodoErc20ApproveProxy, _dodoSwapLimitOverhead)
        DODOV2(_dodoSwapLimitOverhead, _dodoErc20ApproveProxy)
        AaveV3(_aaveV3RefCode, _aaveV3Pool, _aaveV3WethGateway)
    {}

    function initialize(bytes calldata data) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    ) external payable override {
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].index == 1) {
                //swap on WETH
                swapOnWETH(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000));
            } else if (route[i].index == 2) {
                //swap on uniswapV2Fork
                swapOnUniswapV2Fork(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].payload);
            } else if (route[i].index == 3) {
                //swap on uniswapv3
                swapOnUniswapV3(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 4) {
                //swap on KyberDmm
                swapOnKyberDmm(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 5) {
                //swap on BalancerV2
                swapOnBalancerV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 6) {
                //swap on curve
                swapOnCurve(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 7) {
                //swap on CurveV2
                swapOnCurveV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 8) {
                //swap on Saddle
                swapOnSaddle(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 9) {
                //swap on GMX
                swapOnGMX(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].targetExchange);
            } else if (route[i].index == 10) {
                //swap on DODO
                swapOnDodo(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 11) {
                //swap on DODOV2
                swapOnDodoV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 12) {
                //swap on AaveV3
                swapOnAaveV3(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].payload);
            } else if (route[i].index == 13) {
                //swap on augustusRFQ
                swapOnAugustusRFQ(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 14) {
                // swap on HashFlow
                swapOnHashFlow(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else {
                revert("Index not supported");
            }
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../lib/Utils.sol";

interface IAdapter {
    /**
     * @dev Certain adapters needs to be initialized.
     * This method will be called from Augustus
     */
    function initialize(bytes calldata data) external;

    /**
     * @dev The function which performs the swap on an exchange.
     * @param fromToken Address of the source token
     * @param toToken Address of the destination token
     * @param fromAmount Amount of source tokens to be swapped
     * @param networkFee NOT USED - Network fee to be used in this router
     * @param route Route to be followed
     */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    ) external payable;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./ITokenTransferProxy.sol";

contract AugustusStorage {
    struct FeeStructure {
        uint256 partnerShare;
        bool noPositiveSlippage;
        bool positiveSlippageToUser;
        uint16 feePercent;
        string partnerId;
        bytes data;
    }

    ITokenTransferProxy internal tokenTransferProxy;
    address payable internal feeWallet;

    mapping(address => FeeStructure) internal registeredPartners;

    mapping(bytes4 => address) internal selectorVsRouter;
    mapping(bytes32 => bool) internal adapterInitialized;
    mapping(bytes32 => bytes) internal adapterVsData;

    mapping(bytes32 => bytes) internal routerData;
    mapping(bytes32 => bool) internal routerInitialized;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";

import "../../AugustusStorage.sol";

interface IAaveV3WETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

interface IAaveV3Pool {
    function supply(
        IERC20 asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        IERC20 asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract AaveV3 {
    struct AaveData {
        address aToken;
    }

    uint16 public immutable aaveV3RefCode;
    address public immutable aaveV3Pool;
    address public immutable aaveV3WethGateway;

    constructor(
        uint16 _refCode,
        address _pool,
        address _wethGateway
    ) public {
        aaveV3RefCode = _refCode;
        aaveV3Pool = _pool;
        aaveV3WethGateway = _wethGateway;
    }

    function swapOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveV3(fromToken, toToken, fromAmount, payload);
    }

    function buyOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveV3(fromToken, toToken, fromAmount, payload);
    }

    function _swapOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes memory payload
    ) private {
        AaveData memory data = abi.decode(payload, (AaveData));

        if (address(fromToken) == address(data.aToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                Utils.approve(aaveV3WethGateway, address(fromToken), fromAmount);
                IAaveV3WETHGateway(aaveV3WethGateway).withdrawETH(aaveV3Pool, fromAmount, address(this));
            } else {
                Utils.approve(aaveV3Pool, address(fromToken), fromAmount);
                IAaveV3Pool(aaveV3Pool).withdraw(toToken, fromAmount, address(this));
            }
        } else if (address(toToken) == address(data.aToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                IAaveV3WETHGateway(aaveV3WethGateway).depositETH{ value: fromAmount }(
                    aaveV3Pool,
                    address(this),
                    aaveV3RefCode
                );
            } else {
                Utils.approve(aaveV3Pool, address(fromToken), fromAmount);
                IAaveV3Pool(aaveV3Pool).supply(fromToken, fromAmount, address(this), aaveV3RefCode);
            }
        } else {
            revert("Invalid aToken");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAugustusRFQ.sol";
import "../Utils.sol";
import "../WethProvider.sol";
import "../weth/IWETH.sol";

abstract contract AugustusRFQ is WethProvider {
    using SafeMath for uint256;

    struct AugustusRFQData {
        IAugustusRFQ.OrderInfo[] orderInfos;
    }

    function swapOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            Utils.approve(exchange, WETH, fromAmount);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmount);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(data.orderInfos, fromAmount, address(this));

        if (address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }

    function buyOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmountMax,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmountMax }();
            Utils.approve(exchange, WETH, fromAmountMax);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmountMax);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(data.orderInfos, toAmount, address(this));

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

interface IAugustusRFQ {
    struct Order {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        address makerAsset;
        address takerAsset;
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    // makerAsset and takerAsset are Packed structures
    // 0 - 159 bits are address
    // 160 - 161 bits are tokenType (0 ERC20, 1 ERC1155, 2 ERC721)
    struct OrderNFT {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        uint256 makerAsset;
        uint256 makerAssetId; // simply ignored in case of ERC20s
        uint256 takerAsset;
        uint256 takerAssetId; // simply ignored in case of ERC20s
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    struct OrderInfo {
        Order order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    struct OrderNFTInfo {
        OrderNFT order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    /**
     @dev Allows taker to fill complete RFQ order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrder(Order calldata order, bytes calldata signature) external;

    /**
     @dev Allows taker to fill Limit order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrderNFT(OrderNFT calldata order, bytes calldata signature) external;

    /**
     @dev Same as fillOrder but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Same as fillOrderNFT but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Allows taker to partially fill an order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Allows taker to partially fill an NFT order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrderNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrder` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTarget` but it allows to pass permit
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermit(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderNFT` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTargetNFT` but it allows to pass token permits
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermitNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Partial fill multiple orders
     @param orderInfos OrderInfo to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTarget(OrderInfo[] calldata orderInfos, address target) external;

    /**
     @dev batch fills orders until the takerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param takerFillAmount total taker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderTakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 takerFillAmount,
        address target
    ) external;

    /**
     @dev batch fills orders until the makerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param makerFillAmount total maker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderMakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 makerFillAmount,
        address target
    ) external;

    /**
     @dev Partial fill multiple NFT orders
     @param orderInfos Info about each order to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTargetNFT(OrderNFTInfo[] calldata orderInfos, address target) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";
import "./IBalancerV2Vault.sol";

contract BalancerV2 {
    using SafeMath for uint256;

    struct BalancerV2Data {
        IBalancerV2Vault.BatchSwapStep[] swaps;
        address[] assets;
        IBalancerV2Vault.FundManagement funds;
        int256[] limits;
        uint256 deadline;
    }

    function swapOnBalancerV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address vault,
        bytes calldata payload
    ) internal {
        BalancerV2Data memory data = abi.decode(payload, (BalancerV2Data));

        uint256 totalAmount;
        for (uint256 i = 0; i < data.swaps.length; ++i) {
            totalAmount = totalAmount.add(data.swaps[i].amount);
        }

        // This will only work for a direct swap on balancer
        if (totalAmount != fromAmount) {
            for (uint256 i = 0; i < data.swaps.length; ++i) {
                data.swaps[i].amount = data.swaps[i].amount.mul(fromAmount).div(totalAmount);
            }
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IBalancerV2Vault(vault).batchSwap{ value: fromAmount }(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                data.swaps,
                data.assets,
                data.funds,
                data.limits,
                data.deadline
            );
        } else {
            Utils.approve(vault, address(fromToken), fromAmount);
            IBalancerV2Vault(vault).batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                data.swaps,
                data.assets,
                data.funds,
                data.limits,
                data.deadline
            );
        }
    }

    function buyOnBalancerV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address vault,
        bytes calldata payload
    ) internal {
        BalancerV2Data memory data = abi.decode(payload, (BalancerV2Data));

        if (address(fromToken) == Utils.ethAddress()) {
            IBalancerV2Vault(vault).batchSwap{ value: fromAmount }(
                IBalancerV2Vault.SwapKind.GIVEN_OUT,
                data.swaps,
                data.assets,
                data.funds,
                data.limits,
                data.deadline
            );
        } else {
            Utils.approve(vault, address(fromToken), fromAmount);
            IBalancerV2Vault(vault).batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_OUT,
                data.swaps,
                data.assets,
                data.funds,
                data.limits,
                data.deadline
            );
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";

interface IBalancerV2Vault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICurve.sol";
import "../Utils.sol";

contract Curve {
    struct CurveData {
        int128 i;
        int128 j;
        uint256 deadline;
        bool underlyingSwap;
    }

    function swapOnCurve(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        CurveData memory curveData = abi.decode(payload, (CurveData));

        Utils.approve(address(exchange), address(fromToken), fromAmount);

        if (curveData.underlyingSwap) {
            ICurvePool(exchange).exchange_underlying(curveData.i, curveData.j, fromAmount, 1);
        } else {
            if (address(fromToken) == Utils.ethAddress()) {
                ICurveEthPool(exchange).exchange{ value: fromAmount }(curveData.i, curveData.j, fromAmount, 1);
            } else {
                ICurvePool(exchange).exchange(curveData.i, curveData.j, fromAmount, 1);
            }
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICurveV2.sol";
import "../Utils.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";

abstract contract CurveV2 is WethProvider {
    enum CurveV2SwapType {
        EXCHANGE,
        EXCHANGE_UNDERLYING,
        EXCHANGE_GENERIC_FACTORY_ZAP
    }

    struct CurveV2Data {
        uint256 i;
        uint256 j;
        address originalPoolAddress;
        CurveV2SwapType swapType;
    }

    constructor() {}

    function swapOnCurveV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        CurveV2Data memory curveV2Data = abi.decode(payload, (CurveV2Data));

        address _fromToken = address(fromToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            _fromToken = WETH;
        }

        Utils.approve(address(exchange), address(_fromToken), fromAmount);
        if (curveV2Data.swapType == CurveV2SwapType.EXCHANGE) {
            ICurveV2Pool(exchange).exchange(curveV2Data.i, curveV2Data.j, fromAmount, 1);
        } else if (curveV2Data.swapType == CurveV2SwapType.EXCHANGE_UNDERLYING) {
            ICurveV2Pool(exchange).exchange_underlying(curveV2Data.i, curveV2Data.j, fromAmount, 1);
        } else if (curveV2Data.swapType == CurveV2SwapType.EXCHANGE_GENERIC_FACTORY_ZAP) {
            IGenericFactoryZap(exchange).exchange(
                curveV2Data.originalPoolAddress,
                curveV2Data.i,
                curveV2Data.j,
                fromAmount,
                1
            );
        }

        if (address(toToken) == Utils.ethAddress()) {
            uint256 receivedAmount = Utils.tokenBalance(WETH, address(this));
            IWETH(WETH).withdraw(receivedAmount);
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function underlying_coins(int128 index) external view returns (address);

    function coins(int128 index) external view returns (address);
}

interface IPoolV3 {
    function underlying_coins(uint256 index) external view returns (address);

    function coins(uint256 index) external view returns (address);
}

interface ICurvePool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;
}

interface ICurveEthPool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable;
}

interface ICompoundPool {
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ICurveV2Pool {
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy
    ) external;
}

interface IGenericFactoryZap {
    function exchange(
        address _pool,
        uint256 i,
        uint256 j,
        uint256 _dx,
        uint256 _min_dy
    ) external;
}

interface ICurveV2EthPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy,
        bool useEth
    ) external payable;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./IDODO.sol";

contract DODO {
    struct DODOData {
        address[] dodoPairs;
        uint256 directions;
    }

    address public immutable erc20ApproveProxy;
    uint256 public immutable dodoSwapLimitOverhead;

    constructor(address _erc20ApproveProxy, uint256 _swapLimitOverhead) public {
        dodoSwapLimitOverhead = _swapLimitOverhead;
        erc20ApproveProxy = _erc20ApproveProxy;
    }

    function swapOnDodo(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        DODOData memory dodoData = abi.decode(payload, (DODOData));

        Utils.approve(erc20ApproveProxy, address(fromToken), fromAmount);

        IDODO(exchange).dodoSwapV1{ value: address(fromToken) == Utils.ethAddress() ? fromAmount : 0 }(
            address(fromToken),
            address(toToken),
            fromAmount,
            1,
            dodoData.dodoPairs,
            dodoData.directions,
            false,
            block.timestamp + dodoSwapLimitOverhead
        );
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IDODO {
    function dodoSwapV1(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";
import "./IDODOV2Proxy.sol";

contract DODOV2 {
    uint256 public immutable dodoV2SwapLimitOverhead;
    address public immutable dodoErc20ApproveProxy;

    struct DODOV2Data {
        address[] dodoPairs;
        uint256 directions;
    }

    constructor(uint256 _dodoV2SwapLimitOverhead, address _dodoErc20ApproveProxy) public {
        dodoV2SwapLimitOverhead = _dodoV2SwapLimitOverhead;
        dodoErc20ApproveProxy = _dodoErc20ApproveProxy;
    }

    function swapOnDodoV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        DODOV2Data memory dodoData = abi.decode(payload, (DODOV2Data));

        if (address(fromToken) == Utils.ethAddress()) {
            IDODOV2Proxy(exchange).dodoSwapV2ETHToToken{ value: fromAmount }(
                address(toToken),
                1,
                dodoData.dodoPairs,
                dodoData.directions,
                false,
                block.timestamp + dodoV2SwapLimitOverhead
            );
        } else if (address(toToken) == Utils.ethAddress()) {
            Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

            IDODOV2Proxy(exchange).dodoSwapV2TokenToETH(
                address(fromToken),
                fromAmount,
                1,
                dodoData.dodoPairs,
                dodoData.directions,
                false,
                block.timestamp + dodoV2SwapLimitOverhead
            );
        } else {
            Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

            IDODOV2Proxy(exchange).dodoSwapV2TokenToToken(
                address(fromToken),
                address(toToken),
                fromAmount,
                1,
                dodoData.dodoPairs,
                dodoData.directions,
                false,
                block.timestamp + dodoV2SwapLimitOverhead
            );
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IDODOV2Proxy {
    function dodoSwapV2ETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../Utils.sol";
import "./IVault.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";

abstract contract GMX is WethProvider {
    using SafeERC20 for IERC20;

    function swapOnGMX(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        IERC20(_fromToken).safeTransfer(exchange, fromAmount);
        IVault(exchange).swap(_fromToken, _toToken, address(this));

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IVault {
    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQuote {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }
}

interface IHashFlowRouter {
    function tradeRFQT(IQuote.RFQTQuote calldata quote) external payable;
}

contract HashFlow {
    struct HashFlowData {
        address pool;
        address quoteToken;
        address externalAccount;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function buyOnHashFlow(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxFromAmount,
        uint256 toAmount,
        address targetExchange,
        bytes calldata payload
    ) internal {
        HashFlowData memory data = abi.decode(payload, (HashFlowData));

        require(data.quoteTokenAmount >= toAmount, "HashFlow quoteTokenAmount < toAmount");

        if (address(fromToken) == Utils.ethAddress()) {
            IHashFlowRouter(targetExchange).tradeRFQT{ value: data.baseTokenAmount }(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(0),
                    quoteToken: address(toToken),
                    effectiveBaseTokenAmount: maxFromAmount > data.baseTokenAmount
                        ? data.baseTokenAmount
                        : maxFromAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        } else {
            Utils.approve(targetExchange, address(fromToken), data.baseTokenAmount);

            IHashFlowRouter(targetExchange).tradeRFQT(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(fromToken),
                    quoteToken: data.quoteToken,
                    effectiveBaseTokenAmount: maxFromAmount > data.baseTokenAmount
                        ? data.baseTokenAmount
                        : maxFromAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        }
    }

    function swapOnHashFlow(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        HashFlowData memory data = abi.decode(payload, (HashFlowData));

        if (address(fromToken) == Utils.ethAddress()) {
            IHashFlowRouter(exchange).tradeRFQT{ value: data.baseTokenAmount }(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(0),
                    quoteToken: address(toToken),
                    effectiveBaseTokenAmount: fromAmount > data.baseTokenAmount ? data.baseTokenAmount : fromAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        } else {
            Utils.approve(exchange, address(fromToken), data.baseTokenAmount);

            IHashFlowRouter(exchange).tradeRFQT(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(fromToken),
                    quoteToken: data.quoteToken,
                    effectiveBaseTokenAmount: fromAmount > data.baseTokenAmount ? data.baseTokenAmount : fromAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDMMExchangeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";
import "./IKyberDmmRouter.sol";

abstract contract KyberDmm is WethProvider {
    uint256 constant MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    struct KyberDMMData {
        address[] poolPath;
        IERC20[] path;
    }

    function swapOnKyberDmm(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        KyberDMMData memory data = abi.decode(payload, (KyberDMMData));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        IDMMExchangeRouter(exchange).swapExactTokensForTokens(
            fromAmount,
            1,
            data.poolPath,
            data.path,
            address(this),
            MAX_INT // deadline
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ISwap {
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwap.sol";

contract SaddleAdapter {
    struct SaddleData {
        uint8 i;
        uint8 j;
        uint256 deadline;
    }

    function swapOnSaddle(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        SaddleData memory data = abi.decode(payload, (SaddleData));

        Utils.approve(address(exchange), address(fromToken), fromAmount);

        ISwap(exchange).swap(data.i, data.j, fromAmount, 1, data.deadline);
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "./NewUniswapV2Lib.sol";
import "../Utils.sol";
import "../weth/IWETH.sol";

abstract contract NewUniswapV2 {
    using SafeMath for uint256;

    // Pool bits are 255-161: fee, 160: direction flag, 159-0: address
    uint256 constant FEE_OFFSET = 161;
    uint256 constant DIRECTION_FLAG = 0x0000000000000000000000010000000000000000000000000000000000000000;

    struct UniswapV2Data {
        address weth;
        uint256[] pools;
    }

    function swapOnUniswapV2Fork(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        UniswapV2Data memory data = abi.decode(payload, (UniswapV2Data));
        _swapOnUniswapV2Fork(address(fromToken), fromAmount, data.weth, data.pools);
    }

    function buyOnUniswapFork(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountInMax,
        uint256 amountOut,
        bytes calldata payload
    ) internal {
        UniswapV2Data memory data = abi.decode(payload, (UniswapV2Data));

        _buyOnUniswapFork(address(fromToken), amountInMax, amountOut, data.weth, data.pools);
    }

    function _buyOnUniswapFork(
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut,
        address weth,
        uint256[] memory pools
    ) private returns (uint256 tokensSold) {
        uint256 pairs = pools.length;

        require(pairs != 0, "At least one pool required");

        uint256[] memory amounts = new uint256[](pairs + 1);

        amounts[pairs] = amountOut;

        for (uint256 i = pairs; i != 0; --i) {
            uint256 p = pools[i - 1];
            amounts[i - 1] = NewUniswapV2Lib.getAmountIn(
                amounts[i],
                address(p),
                p & DIRECTION_FLAG == 0,
                p >> FEE_OFFSET
            );
        }

        tokensSold = amounts[0];
        require(tokensSold <= amountInMax, "UniswapV2Router: INSUFFICIENT_INPUT_AMOUNT");
        bool tokensBoughtEth;

        if (tokenIn == Utils.ethAddress()) {
            IWETH(weth).deposit{ value: tokensSold }();
            require(IWETH(weth).transfer(address(pools[0]), tokensSold));
        } else {
            TransferHelper.safeTransfer(tokenIn, address(pools[0]), tokensSold);
            tokensBoughtEth = weth != address(0);
        }

        for (uint256 i = 0; i < pairs; ++i) {
            uint256 p = pools[i];
            (uint256 amount0Out, uint256 amount1Out) = p & DIRECTION_FLAG == 0
                ? (uint256(0), amounts[i + 1])
                : (amounts[i + 1], uint256(0));
            IUniswapV2Pair(address(p)).swap(
                amount0Out,
                amount1Out,
                i + 1 == pairs ? address(this) : address(pools[i + 1]),
                ""
            );
        }

        if (tokensBoughtEth) {
            IWETH(weth).withdraw(amountOut);
        }
    }

    function _swapOnUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        address weth,
        uint256[] memory pools
    ) private returns (uint256 tokensBought) {
        uint256 pairs = pools.length;

        require(pairs != 0, "At least one pool required");

        bool tokensBoughtEth;

        if (tokenIn == Utils.ethAddress()) {
            IWETH(weth).deposit{ value: amountIn }();
            require(IWETH(weth).transfer(address(pools[0]), amountIn));
        } else {
            TransferHelper.safeTransfer(tokenIn, address(pools[0]), amountIn);
            tokensBoughtEth = weth != address(0);
        }

        tokensBought = amountIn;

        for (uint256 i = 0; i < pairs; ++i) {
            uint256 p = pools[i];
            address pool = address(p);
            bool direction = p & DIRECTION_FLAG == 0;

            tokensBought = NewUniswapV2Lib.getAmountOut(tokensBought, pool, direction, p >> FEE_OFFSET);
            (uint256 amount0Out, uint256 amount1Out) = direction
                ? (uint256(0), tokensBought)
                : (tokensBought, uint256(0));
            IUniswapV2Pair(pool).swap(
                amount0Out,
                amount1Out,
                i + 1 == pairs ? address(this) : address(pools[i + 1]),
                ""
            );
        }

        if (tokensBoughtEth) {
            IWETH(weth).withdraw(tokensBought);
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./IUniswapV2Pair.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library NewUniswapV2Lib {
    using SafeMath for uint256;

    function getReservesByPair(address pair, bool direction)
        internal
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (reserveIn, reserveOut) = direction ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountOut(
        uint256 amountIn,
        address pair,
        bool direction,
        uint256 fee
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Lib: INSUFFICIENT_INPUT_AMOUNT");
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, direction);
        uint256 amountInWithFee = amountIn.mul(fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = uint256(numerator / denominator);
    }

    function getAmountIn(
        uint256 amountOut,
        address pair,
        bool direction,
        uint256 fee
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Lib: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, direction);
        require(reserveOut > amountOut, "UniswapV2Lib: reserveOut should be greater than amountOut");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";

interface ISwapRouterUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function refundETH() external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwapRouterUniV3.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";

abstract contract UniswapV3 is WethProvider {
    struct UniswapV3Data {
        bytes path;
        uint256 deadline;
    }

    function swapOnUniswapV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        UniswapV3Data memory data = abi.decode(payload, (UniswapV3Data));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterUniV3(exchange).exactInput(
            ISwapRouterUniV3.ExactInputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountIn: fromAmount,
                amountOutMinimum: 1
            })
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function buyOnUniswapV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        UniswapV3Data memory data = abi.decode(payload, (UniswapV3Data));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterUniV3(exchange).exactOutput(
            ISwapRouterUniV3.ExactOutputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountOut: toAmount,
                amountInMaximum: fromAmount
            })
        );

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}

/*solhint-disable avoid-low-level-calls */
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ITokenTransferProxy.sol";
import { IBalancerV2Vault } from "./balancerv2/IBalancerV2Vault.sol";

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    enum CurveSwapType {
        EXCHANGE,
        EXCHANGE_UNDERLYING,
        EXCHANGE_GENERIC_FACTORY_ZAP
    }

    /**
     * @param fromToken Address of the source token
     * @param fromAmount Amount of source tokens to be swapped
     * @param toAmount Minimum destination token amount expected out of this swap
     * @param expectedAmount Expected amount of destination tokens without slippage
     * @param beneficiary Beneficiary address
     * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
     * @param path Route to be taken for this swap to take place
     */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct DirectUniV3 {
        address fromToken;
        address toToken;
        address exchange;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 feePercent;
        uint256 deadline;
        address payable partner;
        bool isApproved;
        address payable beneficiary;
        bytes path;
        bytes permit;
        bytes16 uuid;
    }

    struct DirectCurveV1 {
        address fromToken;
        address toToken;
        address exchange;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 feePercent;
        int128 i;
        int128 j;
        address payable partner;
        bool isApproved;
        CurveSwapType swapType;
        address payable beneficiary;
        bool needWrapNative;
        bytes permit;
        bytes16 uuid;
    }

    struct DirectCurveV2 {
        address fromToken;
        address toToken;
        address exchange;
        address poolAddress;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 feePercent;
        uint256 i;
        uint256 j;
        address payable partner;
        bool isApproved;
        CurveSwapType swapType;
        address payable beneficiary;
        bool needWrapNative;
        bytes permit;
        bytes16 uuid;
    }

    struct DirectBalancerV2 {
        IBalancerV2Vault.BatchSwapStep[] swaps;
        address[] assets;
        IBalancerV2Vault.FundManagement funds;
        int256[] limits;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        uint256 deadline;
        uint256 feePercent;
        address vault;
        address payable partner;
        bool isApproved;
        address payable beneficiary;
        bytes permit;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(abi.encodePacked(IERC20PermitLegacy.permit.selector, permit));
            require(success, "Permit failed");
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
            require(result, "Transfer ETH failed");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;

    function withdraw(uint256 amount) external virtual;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IWETH.sol";
import "../Utils.sol";
import "../WethProvider.sol";

abstract contract WethExchange is WethProvider {
    function swapOnWETH(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnWeth(fromToken, toToken, fromAmount);
    }

    function buyOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnWeth(fromToken, toToken, fromAmount);
    }

    function _swapOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) private {
        address weth = WETH;

        if (address(fromToken) == weth) {
            require(address(toToken) == Utils.ethAddress(), "Destination token should be ETH");
            IWETH(weth).withdraw(fromAmount);
        } else if (address(fromToken) == Utils.ethAddress()) {
            require(address(toToken) == weth, "Destination token should be weth");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            revert("Invalid fromToken");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

contract WethProvider {
    /*solhint-disable var-name-mixedcase*/
    address public immutable WETH;

    /*solhint-enable var-name-mixedcase*/

    constructor(address weth) public {
        WETH = weth;
    }
}