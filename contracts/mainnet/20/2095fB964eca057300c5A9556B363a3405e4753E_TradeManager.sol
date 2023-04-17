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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./TradeOwner.sol";

contract TradeManager is TradeOwner, ReentrancyGuard {
  using SafeMath  for uint256;
  using SafeERC20 for IERC20;

  enum Status { Unfilled, Filled, Cancelled }

  //events ===========
  event eventCreateNewTrade(
    bytes32 tradeId,
    address user0,
    address token0,
    uint256 token0Amount,
    address[] acceptedTokens,
    uint256[] acceptedAmounts,
    uint8 status,
    uint256 fillCount,
    uint256 token0AmountRemaining,
    address refer
  );

  event eventFillTrade(
    bytes32 tradeId,
    address user0,
    uint8 status,
    uint256 fillCount,
    address filler,
    uint256 token0FillAmount,
    address acceptedToken,
    uint256 acceptedTokenAmountSent
  );

  event eventUpdateAcceptedTokens(
    bytes32 tradeId,
    address user0,
    address[] acceptedTokens,
    uint256[] acceptedAmounts
  );

  event eventCancelTrade(
    bytes32 tradeId,
    address user0,
    address token0,
    uint256 token0Amount,
    uint256 status,
    uint256 fillCount,
    uint256 refundAmount
  );

  struct Filler {
    bool isExist;
    address user;
    address acceptedToken;
    uint256 acceptedTokenAmountSent;
    uint256 token0FillAmount;
  }

  struct TradeCommissions {
    uint256 token0Commission;
    uint256 acceptedTokenCommission;
    uint256 referToken0Commission;
    uint256 referAcceptedTokenCommission;
  }

  struct FillAcceptedObj {
    uint256 acceptedAmount;
    uint256 acceptedTokenAmountSent;
  }

  struct Trade {
    bool    isExist;
    address user0;
    address token0;
    uint256 token0Amount;
    address[] acceptedTokens;
    uint256[] acceptedAmounts;
    Status status;
    uint256 fillCount;
    uint256 token0AmountRemaining;
    address refer;
  }

  mapping(string => Trade)   internal trades;
  mapping(string => Filler)  internal fills;

  constructor() {}

  modifier onlyUser() {
    require(_msgSender() != owner());
    _;
  }

  receive() external payable { }

  fallback() external payable { }

  function createNewTrade(
    bytes32 tradeId,
    address token0,
    uint256 token0Amount,
    address[] memory acceptedTokens,
    uint256[] memory acceptedAmounts,
    address refer
  ) external onlyUser payable nonReentrant {

    require(contractEnabled == true);
    require(token0Amount > 0);
    require(acceptedTokens.length == acceptedAmounts.length);
    require(_validAcceptedTokens(token0, acceptedTokens) == true);
    require(_validAcceptedAmounts(acceptedAmounts) == true);

    string memory tradeKey = _returnTradeKey(tradeId, _msgSender());
    require(trades[tradeKey].isExist != true);

    Trade memory newTrade;
    newTrade.isExist = true;
    newTrade.user0 = _msgSender();
    newTrade.token0 = token0;
    newTrade.token0Amount = token0Amount;
    newTrade.acceptedTokens = acceptedTokens;
    newTrade.acceptedAmounts = acceptedAmounts;
    newTrade.status = Status.Unfilled;
    newTrade.fillCount = 0;
    newTrade.token0AmountRemaining = token0Amount;

    if (token0 == address(0)) {
      require(msg.value >= token0Amount);
    } else {
      // check for tax tokens where amount received != transfer amount
      uint256 balanceBefore = IERC20(token0).balanceOf(address(this));
      IERC20(token0).safeTransferFrom(_msgSender(), address(this), token0Amount);
      uint256 balanceAfter = IERC20(token0).balanceOf(address(this));
      newTrade.token0Amount = balanceAfter.sub(balanceBefore);
      newTrade.token0AmountRemaining = balanceAfter.sub(balanceBefore);
    }

    if (refer != address(0) && referEnabled) {
      newTrade.refer = refer;
    }

    trades[tradeKey] = newTrade;

    emit eventCreateNewTrade(
      tradeId,
      newTrade.user0,
      newTrade.token0,
      newTrade.token0Amount,
      newTrade.acceptedTokens,
      newTrade.acceptedAmounts,
      uint8(newTrade.status),
      newTrade.fillCount,
      newTrade.token0AmountRemaining,
      newTrade.refer
    );
  }

  function fillTrade(
    bytes32 tradeId,
    address user0,
    address acceptedToken,
    uint256 token0FillAmount
  ) external onlyUser payable nonReentrant {

    require(contractEnabled == true);
    string memory tradeKey = _returnTradeKey(tradeId, user0);
    require(trades[tradeKey].isExist);
    require(trades[tradeKey].user0 != _msgSender());
    require(trades[tradeKey].status == Status.Unfilled);
    require(_tokenIsAccepted(acceptedToken, trades[tradeKey].acceptedTokens) == true);

    require(token0FillAmount <= trades[tradeKey].token0AmountRemaining);

    FillAcceptedObj memory fillAcceptedObj;
    fillAcceptedObj.acceptedAmount = _getAcceptedAmount(acceptedToken, trades[tradeKey].acceptedTokens, trades[tradeKey].acceptedAmounts);
    fillAcceptedObj.acceptedTokenAmountSent = fillAcceptedObj.acceptedAmount.mul(token0FillAmount).div(trades[tradeKey].token0Amount);

    // filler must deposit funds
    if (acceptedToken == address(0)) {
      require(msg.value >= fillAcceptedObj.acceptedTokenAmountSent);
    } else {
      // check for tax tokens where amount received != transfer amount
      uint256 balanceBefore = IERC20(acceptedToken).balanceOf(address(this));
      IERC20(acceptedToken).safeTransferFrom(_msgSender(), address(this), fillAcceptedObj.acceptedTokenAmountSent);
      uint256 balanceAfter = IERC20(acceptedToken).balanceOf(address(this));
      fillAcceptedObj.acceptedTokenAmountSent = balanceAfter.sub(balanceBefore);
    }

    string memory fillKey = _returnFillKey(tradeId, trades[tradeKey].fillCount.add(1));
    require(fills[fillKey].isExist != true);

    Filler memory newFiller;
    newFiller.isExist = true;
    newFiller.user = _msgSender();
    newFiller.acceptedToken = acceptedToken;
    newFiller.acceptedTokenAmountSent = fillAcceptedObj.acceptedTokenAmountSent;
    newFiller.token0FillAmount = token0FillAmount;
    fills[fillKey] = newFiller;

    trades[tradeKey].fillCount = trades[tradeKey].fillCount.add(1);
    trades[tradeKey].token0AmountRemaining = trades[tradeKey].token0AmountRemaining.sub(token0FillAmount);

    if (trades[tradeKey].token0AmountRemaining == 0) {
      trades[tradeKey].status = Status.Filled;
    }

    uint256 feeToUse = defaultFee;
    string memory pairKey = _appendAddresses(trades[tradeKey].token0, acceptedToken);
    if (pairs[pairKey].isExist == true) {
      feeToUse = pairs[pairKey].fee;
    }

    TradeCommissions memory tradeCommissions;
    tradeCommissions.token0Commission = token0FillAmount.mul(feeToUse).div(feeDivider);
    tradeCommissions.acceptedTokenCommission = fillAcceptedObj.acceptedTokenAmountSent.mul(feeToUse).div(feeDivider);
    tradeCommissions.referToken0Commission = tradeCommissions.token0Commission.mul(referFee).div(feeDivider);
    tradeCommissions.referAcceptedTokenCommission = tradeCommissions.acceptedTokenCommission.mul(referFee).div(feeDivider);

    if (trades[tradeKey].refer != address(0) && referEnabled) {

      // send to msg sender
      if (trades[tradeKey].token0 == address(0)) {
        payable(_msgSender()).transfer(token0FillAmount.sub(tradeCommissions.token0Commission));
        payable(commissionAddress).transfer(tradeCommissions.token0Commission.sub(tradeCommissions.referToken0Commission));
        payable(trades[tradeKey].refer).transfer(tradeCommissions.referToken0Commission);
      } else {
        IERC20(trades[tradeKey].token0).safeTransfer(_msgSender(), token0FillAmount.sub(tradeCommissions.token0Commission));
        IERC20(trades[tradeKey].token0).safeTransfer(commissionAddress, tradeCommissions.token0Commission.sub(tradeCommissions.referToken0Commission));
        IERC20(trades[tradeKey].token0).safeTransfer(trades[tradeKey].refer, tradeCommissions.referToken0Commission);
      }

      // send to trade owner
      if (acceptedToken == address(0)) {
        payable(trades[tradeKey].user0).transfer(fillAcceptedObj.acceptedTokenAmountSent.sub(tradeCommissions.acceptedTokenCommission));
        payable(commissionAddress).transfer(tradeCommissions.acceptedTokenCommission.sub(tradeCommissions.referAcceptedTokenCommission));
        payable(trades[tradeKey].refer).transfer(tradeCommissions.referAcceptedTokenCommission);
      } else {
        IERC20(acceptedToken).safeTransfer(trades[tradeKey].user0, fillAcceptedObj.acceptedTokenAmountSent.sub(tradeCommissions.acceptedTokenCommission));
        IERC20(acceptedToken).safeTransfer(commissionAddress, tradeCommissions.acceptedTokenCommission.sub(tradeCommissions.referAcceptedTokenCommission));
        IERC20(acceptedToken).safeTransfer(trades[tradeKey].refer, tradeCommissions.referAcceptedTokenCommission);
      }

    } else {
      // send to msg sender
      if (trades[tradeKey].token0 == address(0)) {
        payable(_msgSender()).transfer(token0FillAmount.sub(tradeCommissions.token0Commission));
        payable(commissionAddress).transfer(tradeCommissions.token0Commission);
      } else {
        IERC20(trades[tradeKey].token0).safeTransfer(_msgSender(), token0FillAmount.sub(tradeCommissions.token0Commission));
        IERC20(trades[tradeKey].token0).safeTransfer(commissionAddress, tradeCommissions.token0Commission);
      }

      // send to trade owner
      if (acceptedToken == address(0)) {
        payable(trades[tradeKey].user0).transfer(fillAcceptedObj.acceptedTokenAmountSent.sub(tradeCommissions.acceptedTokenCommission));
        payable(commissionAddress).transfer(tradeCommissions.acceptedTokenCommission);
      } else {
        IERC20(acceptedToken).safeTransfer(trades[tradeKey].user0, fillAcceptedObj.acceptedTokenAmountSent.sub(tradeCommissions.acceptedTokenCommission));
        IERC20(acceptedToken).safeTransfer(commissionAddress, tradeCommissions.acceptedTokenCommission);
      }
    }

    emit eventFillTrade(
      tradeId,
      trades[tradeKey].user0,
      uint8(trades[tradeKey].status),
      trades[tradeKey].fillCount,
      _msgSender(),
      token0FillAmount,
      acceptedToken,
      fillAcceptedObj.acceptedTokenAmountSent
    );
  }

  function updateAcceptedTokens(
    bytes32 tradeId,
    address[] memory acceptedTokens,
    uint256[] memory acceptedAmounts
  ) external onlyUser nonReentrant {

    require(contractEnabled == true);
    string memory tradeKey = _returnTradeKey(tradeId, _msgSender());
    require(trades[tradeKey].isExist);
    require(trades[tradeKey].user0 == _msgSender());
    require(trades[tradeKey].status == Status.Unfilled);
    require(acceptedTokens.length == acceptedAmounts.length);
    require(_validAcceptedTokens(trades[tradeKey].token0, acceptedTokens) == true);
    require(_validAcceptedAmounts(acceptedAmounts) == true);

    trades[tradeKey].acceptedTokens = acceptedTokens;
    trades[tradeKey].acceptedAmounts = acceptedAmounts;

    emit eventUpdateAcceptedTokens(
      tradeId,
      trades[tradeKey].user0,
      acceptedTokens,
      acceptedAmounts
    );
  }

  function cancelTrade(
    bytes32 tradeId
  ) external onlyUser payable nonReentrant {

    require(contractEnabled == true);
    string memory tradeKey = _returnTradeKey(tradeId, _msgSender());
    require(trades[tradeKey].isExist);
    require(trades[tradeKey].status == Status.Unfilled);
    require(trades[tradeKey].user0 == _msgSender());

    trades[tradeKey].status = Status.Cancelled;

    if (trades[tradeKey].token0 == address(0)) {
      payable(_msgSender()).transfer(trades[tradeKey].token0AmountRemaining);
    } else {
      require(IERC20(trades[tradeKey].token0).balanceOf(address(this)) >= trades[tradeKey].token0AmountRemaining);
      IERC20(trades[tradeKey].token0).safeTransfer(address(_msgSender()), trades[tradeKey].token0AmountRemaining);
    }

    uint256 refundAmount = trades[tradeKey].token0AmountRemaining;
    trades[tradeKey].token0AmountRemaining = 0;

    emit eventCancelTrade(
      tradeId,
      trades[tradeKey].user0,
      trades[tradeKey].token0,
      trades[tradeKey].token0Amount,
      uint8(trades[tradeKey].status),
      trades[tradeKey].fillCount,
      refundAmount
    );
  }

  function _tokenIsAccepted(address acceptedToken, address[] memory acceptedTokens) internal pure returns (bool) {
    uint256 arrayLength = acceptedTokens.length;
    for (uint i = 0; i < arrayLength; i++) {
      if (acceptedTokens[i] == acceptedToken) {
        return true;
      }
    }
    return false;
  }

  function _validAcceptedTokens(address token0, address[] memory acceptedTokens) internal view returns (bool) {
    uint256 arrayLength = acceptedTokens.length;
    if (arrayLength < 1 || arrayLength > maxAcceptedTokens) {
      return false;
    }
    for (uint i = 0; i < arrayLength; i++) {
      if (acceptedTokens[i] == token0) {
        return false;
      }
    }
    return true;
  }

  function _validAcceptedAmounts(uint256[] memory acceptedAmounts) internal pure returns (bool) {
    uint256 arrayLength = acceptedAmounts.length;
    for (uint i = 0; i < arrayLength; i++) {
      if (acceptedAmounts[i] == 0) {
        return false;
      }
    }
    return true;
  }

  function _getAcceptedAmount(address acceptedToken, address[] memory acceptedTokens, uint256[] memory acceptedAmounts) internal pure returns (uint256) {
    uint arrayLength = acceptedTokens.length;
    for (uint i = 0; i < arrayLength; i++) {
      if (acceptedTokens[i] == acceptedToken) {
        return acceptedAmounts[i];
      }
    }
    return 0;
  }

  function _returnFillKey(bytes32 tradeId, uint256 fillCount) internal pure returns (string memory) {
    return string(abi.encodePacked(tradeId, '||', fillCount));
  }

  function _returnTradeKey(bytes32 tradeId, address user0) internal pure returns (string memory) {
    return string(abi.encodePacked(tradeId, '||', user0));
  }

  function getTrade(bytes32 tradeId, address user0) public view returns (Trade memory trade) {
    string memory tradeKey = _returnTradeKey(tradeId, user0);
    return trades[tradeKey];
  }

  function getFill(bytes32 tradeId, uint256 fillCount) public view returns (Filler memory fill) {
    string memory fillKey = _returnFillKey(tradeId, fillCount);
    return fills[fillKey];
  }

  function getRequiredAcceptedAmount(
    bytes32 tradeId,
    address user0,
    address acceptedToken,
    uint256 token0FillAmount
  ) public view returns (uint256 acceptedTokenAmountSent) {

    string memory tradeKey = _returnTradeKey(tradeId, user0);
    require(trades[tradeKey].isExist);

    uint256 acceptedAmount = _getAcceptedAmount(acceptedToken, trades[tradeKey].acceptedTokens, trades[tradeKey].acceptedAmounts);
    return acceptedAmount.mul(token0FillAmount).div(trades[tradeKey].token0Amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TradeOwner is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address internal commissionAddress;
  uint256 public defaultFee;
  uint256 public maxAcceptedTokens;
  uint256 public referFee;
  bool internal referEnabled;
  bool internal contractEnabled;
  uint256 constant feeDivider = 10000;

  struct Pair {
    bool isExist;
    uint256 fee;
  }

  mapping(string=>Pair) internal pairs;

  event ChangedCommissionAddress(address commissionAddress);
  event ChangedDefaultFee(uint256 defaultFee);
  event ChangedReferFee(uint256 referFee);
  event ChangedReferEnabled(bool referEnabled);
  event ChangedMaxAcceptedTokens(uint256 maxAcceptedTokens);
  event ChangedContractDisabled(bool contractEnabled);
  event ChangedPairFee(address token0, address token1, uint256 fee);
  event RescueETH(address rescueAddress, uint256 amount);
  event RescueTokens(address token, address rescueAddress, uint256 amount);

  constructor() {
    defaultFee = 50;
    contractEnabled = true;
    maxAcceptedTokens = 3;
    referFee = 2000;
    referEnabled = true;
  }

  function setCommissionAddress(address _commissionAddress) external onlyOwner {
    require(_commissionAddress != address(0));
    commissionAddress = _commissionAddress;
    emit ChangedCommissionAddress(commissionAddress);
  }

  function setDefaultFee(uint256 _fee) external onlyOwner {
    defaultFee = _fee;
    emit ChangedDefaultFee(defaultFee);
  }

  function setReferFee(uint256 _fee) external onlyOwner {
    referFee = _fee;
    emit ChangedReferFee(_fee);
  }

  function setMaxAcceptedTokens(uint256 _max) external onlyOwner {
    require(_max > 0);
    maxAcceptedTokens = _max;
    emit ChangedMaxAcceptedTokens(_max);
  }

  function setContractEnabled(bool _contractEnabled) external onlyOwner {
    contractEnabled = _contractEnabled;
    emit ChangedContractDisabled(contractEnabled);
  }

  function setReferEnabled(bool _referEnabled) external onlyOwner {
    referEnabled = _referEnabled;
    emit ChangedReferEnabled(referEnabled);
  }

  function rescueETH(address rescueAddress, uint256 amount) external onlyOwner payable {
    payable(rescueAddress).transfer(amount);
    emit RescueETH(rescueAddress, amount);
  }

  function rescueTokens(address token, address rescueAddress, uint256 amount) external onlyOwner payable {
    IERC20(token).safeTransfer(rescueAddress, amount);
    emit RescueTokens(token, rescueAddress, amount);
  }

  function setPairFee(address token0, address token1, uint256 fee) external onlyOwner {
    require(fee > 0);
    require(token0 != token1);

    Pair memory newPair;
    newPair.isExist = true;
    newPair.fee = fee;

    string memory pairOne = _appendAddresses(token0, token1);
    string memory pairTwo = _appendAddresses(token1, token0);

    pairs[pairOne] = newPair;
    pairs[pairTwo] = newPair;

    emit ChangedPairFee(token0, token1, fee);
  }

  function _appendAddresses(address token0, address token1) internal pure returns (string memory) {
    return string(abi.encodePacked(token0, '||', token1));
  }

  function getPairFee(address token0, address token1) public view returns (Pair memory pair) {
    string memory str = _appendAddresses(token0, token1);
    return pairs[str];
  }

  function renounceOwnership() public view override onlyOwner {
    revert("cannot renounce ownership");
  }
}