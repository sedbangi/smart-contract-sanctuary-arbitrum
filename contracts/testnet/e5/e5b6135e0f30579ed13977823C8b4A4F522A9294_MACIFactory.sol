// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract AnyOldERC20Token is ERC20 {
  constructor(uint256 initialSupply)
    public
    ERC20('Any old ERC20 token', 'AOE')
  {
    _mint(msg.sender, initialSupply);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';

// Import ownable from OpenZeppelin contracts

import 'maci-contracts/sol/MACI.sol';
import 'maci-contracts/sol/MACISharedObjs.sol';
import 'maci-contracts/sol/gatekeepers/SignUpGatekeeper.sol';
import 'maci-contracts/sol/initialVoiceCreditProxy/InitialVoiceCreditProxy.sol';

import './userRegistry/IUserRegistry.sol';
import './recipientRegistry/IRecipientRegistry.sol';
import './MACIFactory.sol';
import './FundingRound.sol';
import './OwnableUpgradeable.sol';

contract ClrFund is OwnableUpgradeable, MACISharedObjs {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for ERC20;

  // State
  address public coordinator;

  ERC20 public nativeToken;
  MACIFactory public maciFactory;
  IUserRegistry public userRegistry;
  IRecipientRegistry public recipientRegistry;
  PubKey public coordinatorPubKey;

  EnumerableSet.AddressSet private fundingSources;
  FundingRound[] private rounds;

  // Events
  event FundingSourceAdded(address _source);
  event FundingSourceRemoved(address _source);
  event RoundStarted(address _round);
  event RoundFinalized(address _round);
  event TokenChanged(address _token);
  event CoordinatorChanged(address _coordinator);

  function init(
    MACIFactory _maciFactory
  ) 
    external
  {
    __Ownable_init();
    maciFactory = _maciFactory;
  }

  /**
    * @dev Set registry of verified users.
    * @param _userRegistry Address of a user registry.
    */
  function setUserRegistry(IUserRegistry _userRegistry)
    external
    onlyOwner
  {
    userRegistry = _userRegistry;
  }

  /**
    * @dev Set recipient registry.
    * @param _recipientRegistry Address of a recipient registry.
    */
  function setRecipientRegistry(IRecipientRegistry _recipientRegistry)
    external
    onlyOwner
  {
    recipientRegistry = _recipientRegistry;
    (,, uint256 maxVoteOptions) = maciFactory.maxValues();
    recipientRegistry.setMaxRecipients(maxVoteOptions);
  }

  /**
    * @dev Add matching funds source.
    * @param _source Address of a funding source.
    */
  function addFundingSource(address _source)
    external
    onlyOwner
  {
    bool result = fundingSources.add(_source);
    require(result, 'Factory: Funding source already added');
    emit FundingSourceAdded(_source);
  }

  /**
    * @dev Remove matching funds source.
    * @param _source Address of the funding source.
    */
  function removeFundingSource(address _source)
    external
    onlyOwner
  {
    bool result = fundingSources.remove(_source);
    require(result, 'Factory: Funding source not found');
    emit FundingSourceRemoved(_source);
  }

  function getCurrentRound()
    public
    view
    returns (FundingRound _currentRound)
  {
    if (rounds.length == 0) {
      return FundingRound(address(0));
    }
    return rounds[rounds.length - 1];
  }

  function setMaciParameters(
    uint8 _stateTreeDepth,
    uint8 _messageTreeDepth,
    uint8 _voteOptionTreeDepth,
    uint8 _tallyBatchSize,
    uint8 _messageBatchSize,
    SnarkVerifier _batchUstVerifier,
    SnarkVerifier _qvtVerifier,
    uint256 _signUpDuration,
    uint256 _votingDuration
  )
    external
    onlyOwner
  {
    maciFactory.setMaciParameters(
      _stateTreeDepth,
      _messageTreeDepth,
      _voteOptionTreeDepth,
      _tallyBatchSize,
      _messageBatchSize,
      _batchUstVerifier,
      _qvtVerifier,
      _signUpDuration,
      _votingDuration
    );
  }

  /**
    * @dev Deploy new funding round.
    */
  function deployNewRound()
    external
    onlyOwner
  {
    require(maciFactory.owner() == address(this), 'Factory: MACI factory is not owned by FR factory');
    require(address(userRegistry) != address(0), 'Factory: User registry is not set');
    require(address(recipientRegistry) != address(0), 'Factory: Recipient registry is not set');
    require(address(nativeToken) != address(0), 'Factory: Native token is not set');
    require(coordinator != address(0), 'Factory: No coordinator');
    FundingRound currentRound = getCurrentRound();
    require(
      address(currentRound) == address(0) || currentRound.isFinalized(),
      'Factory: Current round is not finalized'
    );
    // Make sure that the max number of recipients is set correctly
    (,, uint256 maxVoteOptions) = maciFactory.maxValues();
    recipientRegistry.setMaxRecipients(maxVoteOptions);
    // Deploy funding round and MACI contracts
    FundingRound newRound = new FundingRound(
      nativeToken,
      userRegistry,
      recipientRegistry,
      coordinator
    );
    rounds.push(newRound);
    MACI maci = maciFactory.deployMaci(
      SignUpGatekeeper(newRound),
      InitialVoiceCreditProxy(newRound),
      coordinator,
      coordinatorPubKey
    );
    newRound.setMaci(maci);
    emit RoundStarted(address(newRound));
  }

  /**
    * @dev Get total amount of matching funds.
    */
  function getMatchingFunds(ERC20 token)
    external
    view
    returns (uint256)
  {
    uint256 matchingPoolSize = token.balanceOf(address(this));
    for (uint256 index = 0; index < fundingSources.length(); index++) {
      address fundingSource = fundingSources.at(index);
      uint256 allowance = token.allowance(fundingSource, address(this));
      uint256 balance = token.balanceOf(fundingSource);
      uint256 contribution = allowance < balance ? allowance : balance;
      matchingPoolSize += contribution;
    }
    return matchingPoolSize;
  }

  /**
    * @dev Transfer funds from matching pool to current funding round and finalize it.
    * @param _totalSpent Total amount of spent voice credits.
    * @param _totalSpentSalt The salt.
    */
  function transferMatchingFunds(
    uint256 _totalSpent,
    uint256 _totalSpentSalt
  )
    external
    onlyOwner
  {
    FundingRound currentRound = getCurrentRound();
    require(address(currentRound) != address(0), 'Factory: Funding round has not been deployed');
    ERC20 roundToken = currentRound.nativeToken();
    // Factory contract is the default funding source
    uint256 matchingPoolSize = roundToken.balanceOf(address(this));
    if (matchingPoolSize > 0) {
      roundToken.safeTransfer(address(currentRound), matchingPoolSize);
    }
    // Pull funds from other funding sources
    for (uint256 index = 0; index < fundingSources.length(); index++) {
      address fundingSource = fundingSources.at(index);
      uint256 allowance = roundToken.allowance(fundingSource, address(this));
      uint256 balance = roundToken.balanceOf(fundingSource);
      uint256 contribution = allowance < balance ? allowance : balance;
      if (contribution > 0) {
        roundToken.safeTransferFrom(fundingSource, address(currentRound), contribution);
      }
    }
    currentRound.finalize(_totalSpent, _totalSpentSalt);
    emit RoundFinalized(address(currentRound));
  }

  /**
    * @dev Cancel current round.
    */
   function cancelCurrentRound()
    external
    onlyOwner
  {
    FundingRound currentRound = getCurrentRound();
    require(address(currentRound) != address(0), 'Factory: Funding round has not been deployed');
    require(!currentRound.isFinalized(), 'Factory: Current round is finalized');
    currentRound.cancel();
    emit RoundFinalized(address(currentRound));
  }

  /**
    * @dev Set token in which contributions are accepted.
    * @param _token Address of the token contract.
    */
  function setToken(address _token)
    external
    onlyOwner
  {
    nativeToken = ERC20(_token);
    emit TokenChanged(_token);
  }

  /**
    * @dev Set coordinator's address and public key.
    * @param _coordinator Coordinator's address.
    * @param _coordinatorPubKey Coordinator's public key.
    */
  function setCoordinator(
    address _coordinator,
    PubKey memory _coordinatorPubKey
  )
    external
    onlyOwner
  {
    coordinator = _coordinator;
    coordinatorPubKey = _coordinatorPubKey;
    emit CoordinatorChanged(_coordinator);
  }

  function coordinatorQuit()
    external
    onlyCoordinator
  {
    // The fact that they quit is obvious from
    // the address being 0x0
    coordinator = address(0);
    coordinatorPubKey = PubKey(0, 0);
    FundingRound currentRound = getCurrentRound();
    if (address(currentRound) != address(0) && !currentRound.isFinalized()) {
      currentRound.cancel();
      emit RoundFinalized(address(currentRound));
    }
    emit CoordinatorChanged(address(0));
  }

  modifier onlyCoordinator() {
    require(msg.sender == coordinator, 'Factory: Sender is not the coordinator');
    _;
  }
}

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.6.12;
import './MACIFactory.sol';
import './ClrFund.sol';

contract CloneFactory { // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract ClrFundDeployer is CloneFactory { 
    
    address public template;
    mapping (address => bool) public clrfunds;
    uint clrId = 0;
    ClrFund private clrfund; // funding factory contract
    
    constructor(address _template) public {
        template = _template;
    }
    
    event NewInstance(address indexed clrfund);
    event Register(address indexed clrfund, string metadata);
     
    function deployFund(
      MACIFactory _maciFactory
    ) public returns (address) {
        ClrFund clrfund = ClrFund(createClone(template));
        
        clrfund.init(
            _maciFactory
        );
       
        emit NewInstance(address(clrfund));
        
        return address(clrfund);
    }
    
    function registerInstance(
        address _clrFundAddress,
        string memory _metadata
      ) public returns (bool) {
          
      clrfund = ClrFund(_clrFundAddress);
      
      require(clrfunds[_clrFundAddress] == false, 'ClrFund: metadata already registered');

      clrfunds[_clrFundAddress] = true;
      
      clrId = clrId + 1;
      emit Register(_clrFundAddress, _metadata);
      return true;
      
    }
    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import 'maci-contracts/sol/MACI.sol';
import 'maci-contracts/sol/MACISharedObjs.sol';
import 'maci-contracts/sol/gatekeepers/SignUpGatekeeper.sol';
import 'maci-contracts/sol/initialVoiceCreditProxy/InitialVoiceCreditProxy.sol';

import './userRegistry/IUserRegistry.sol';
import './recipientRegistry/IRecipientRegistry.sol';

contract FundingRound is Ownable, MACISharedObjs, SignUpGatekeeper, InitialVoiceCreditProxy {
  using SafeERC20 for ERC20;

  // Constants
  uint256 private constant MAX_VOICE_CREDITS = 10 ** 9;  // MACI allows 2 ** 32 voice credits max
  uint256 private constant MAX_CONTRIBUTION_AMOUNT = 10 ** 4;  // In tokens
  uint256 private constant ALPHA_PRECISION = 10 ** 18; // to account for loss of precision in division
  uint8   private constant LEAVES_PER_NODE = 5; // leaves per node of the tally result tree

  // Structs
  struct ContributorStatus {
    uint256 voiceCredits;
    bool isRegistered;
  }

  struct RecipientStatus {
    // Has the recipient claimed funds?
    bool fundsClaimed;
    // Is the tally result verified
    bool tallyVerified;
    // Tally result
    uint256 tallyResult;
  }

  // State
  uint256 public voiceCreditFactor;
  uint256 public contributorCount;
  uint256 public matchingPoolSize;
  uint256 public totalSpent;
  uint256 public totalVotes;
  bool public isFinalized = false;
  bool public isCancelled = false;

  address public coordinator;
  MACI public maci;
  ERC20 public nativeToken;
  IUserRegistry public userRegistry;
  IRecipientRegistry public recipientRegistry;
  string public tallyHash;

  // The alpha used in quadratic funding formula
  uint256 public alpha = 0;

  // Total number of tally results verified, should match total recipients before finalize
  uint256 public totalTallyResults = 0;
  uint256 public totalVotesSquares = 0;
  mapping(uint256 => RecipientStatus) public recipients;
  mapping(address => ContributorStatus) public contributors;

  // Events
  event Contribution(address indexed _sender, uint256 _amount);
  event ContributionWithdrawn(address indexed _contributor);
  event FundsClaimed(uint256 indexed _voteOptionIndex, address indexed _recipient, uint256 _amount);
  event TallyPublished(string _tallyHash);
  event Voted(address indexed _contributor);
  event TallyResultsAdded(uint256 indexed _voteOptionIndex, uint256 _tally);

  modifier onlyCoordinator() {
    require(msg.sender == coordinator, 'FundingRound: Sender is not the coordinator');
    _;
  }

  /**
    * @dev Set round parameters.
    * @param _nativeToken Address of a token which will be accepted for contributions.
    * @param _userRegistry Address of the registry of verified users.
    * @param _recipientRegistry Address of the recipient registry.
    * @param _coordinator Address of the coordinator.
    */
  constructor(
    ERC20 _nativeToken,
    IUserRegistry _userRegistry,
    IRecipientRegistry _recipientRegistry,
    address _coordinator
  )
    public
  {
    nativeToken = _nativeToken;
    voiceCreditFactor = (MAX_CONTRIBUTION_AMOUNT * uint256(10) ** nativeToken.decimals()) / MAX_VOICE_CREDITS;
    voiceCreditFactor = voiceCreditFactor > 0 ? voiceCreditFactor : 1;
    userRegistry = _userRegistry;
    recipientRegistry = _recipientRegistry;
    coordinator = _coordinator;
  }

  /**
    * @dev Link MACI instance to this funding round.
    */
  function setMaci(
    MACI _maci
  )
    external
    onlyOwner
  {
    require(address(maci) == address(0), 'FundingRound: Already linked to MACI instance');
    require(
      _maci.calcSignUpDeadline() > block.timestamp,
      'FundingRound: Signup deadline must be in the future'
    );
    maci = _maci;
  }

  /**
    * @dev Contribute tokens to this funding round.
    * @param pubKey Contributor's public key.
    * @param amount Contribution amount.
    */
  function contribute(
    PubKey calldata pubKey,
    uint256 amount
  )
    external
  {
    require(address(maci) != address(0), 'FundingRound: MACI not deployed');
    require(contributorCount < maci.maxUsers(), 'FundingRound: Contributor limit reached');
    require(block.timestamp < maci.calcSignUpDeadline(), 'FundingRound: Contribution period ended');
    require(!isFinalized, 'FundingRound: Round finalized');
    require(amount > 0, 'FundingRound: Contribution amount must be greater than zero');
    require(amount <= MAX_VOICE_CREDITS * voiceCreditFactor, 'FundingRound: Contribution amount is too large');
    require(contributors[msg.sender].voiceCredits == 0, 'FundingRound: Already contributed');
    uint256 voiceCredits = amount / voiceCreditFactor;
    contributors[msg.sender] = ContributorStatus(voiceCredits, false);
    contributorCount += 1;
    bytes memory signUpGatekeeperData = abi.encode(msg.sender, voiceCredits);
    bytes memory initialVoiceCreditProxyData = abi.encode(msg.sender);
    nativeToken.safeTransferFrom(msg.sender, address(this), amount);
    maci.signUp(
      pubKey,
      signUpGatekeeperData,
      initialVoiceCreditProxyData
    );
    emit Contribution(msg.sender, amount);
  }

  /**
    * @dev Register user for voting.
    * This function is part of SignUpGatekeeper interface.
    * @param _data Encoded address of a contributor.
    */
  function register(
    address /* _caller */,
    bytes memory _data
  )
    override
    public
  {
    require(msg.sender == address(maci), 'FundingRound: Only MACI contract can register voters');
    address user = abi.decode(_data, (address));
    bool verified = userRegistry.isVerifiedUser(user);
    require(verified, 'FundingRound: User has not been verified');
    require(contributors[user].voiceCredits > 0, 'FundingRound: User has not contributed');
    require(!contributors[user].isRegistered, 'FundingRound: User already registered');
    contributors[user].isRegistered = true;
  }

  /**
    * @dev Get the amount of voice credits for a given address.
    * This function is a part of the InitialVoiceCreditProxy interface.
    * @param _data Encoded address of a user.
    */
  function getVoiceCredits(
    address /* _caller */,
    bytes memory _data
  )
    override
    public
    view
    returns (uint256)
  {
    address user = abi.decode(_data, (address));
    uint256 initialVoiceCredits = contributors[user].voiceCredits;
    require(initialVoiceCredits > 0, 'FundingRound: User does not have any voice credits');
    return initialVoiceCredits;
  }

  /**
    * @dev Submit a batch of messages along with corresponding ephemeral public keys.
    */
  function submitMessageBatch(
    Message[] calldata _messages,
    PubKey[] calldata _encPubKeys
  )
    external
  {
    uint256 batchSize = _messages.length;
    for (uint8 i = 0; i < batchSize; i++) {
      maci.publishMessage(_messages[i], _encPubKeys[i]);
    }
    emit Voted(msg.sender);
  }

  /**
    * @dev Withdraw contributed funds for a list of contributors if the round has been cancelled.
    */
  function withdrawContributions(address[] memory _contributors)
    public
    returns (bool[] memory result)
  {
    require(isCancelled, 'FundingRound: Round not cancelled');

    result = new bool[](_contributors.length);
    // Reconstruction of exact contribution amount from VCs may not be possible due to a loss of precision
    for (uint256 i = 0; i < _contributors.length; i++) {
      address contributor = _contributors[i];
      uint256 amount = contributors[contributor].voiceCredits * voiceCreditFactor;
      if (amount > 0) {
        contributors[contributor].voiceCredits = 0;
        nativeToken.safeTransfer(contributor, amount);
        emit ContributionWithdrawn(contributor);
        result[i] = true;
      } else {
        result[i] = false;
      }
    }
  }

  /**
    * @dev Withdraw contributed funds by the caller.
    */
  function withdrawContribution()
    external
  {
    address[] memory msgSender = new address[](1);
    msgSender[0] = msg.sender;

    bool[] memory results = withdrawContributions(msgSender);
    require(results[0], 'FundingRound: Nothing to withdraw');
  }

  /**
    * @dev Publish the IPFS hash of the vote tally. Only coordinator can publish.
    * @param _tallyHash IPFS hash of the vote tally.
    */
  function publishTallyHash(string calldata _tallyHash)
    external
    onlyCoordinator
  {
    require(!isFinalized, 'FundingRound: Round finalized');
    require(bytes(_tallyHash).length != 0, 'FundingRound: Tally hash is empty string');
    tallyHash = _tallyHash;
    emit TallyPublished(_tallyHash);
  }

  /**
    * @dev Calculate the alpha for the capital constrained quadratic formula
    *  in page 17 of https://arxiv.org/pdf/1809.06421.pdf
    * @param _budget Total budget of the round to be distributed
    * @param _totalVotesSquares Total of the squares of votes
    * @param _totalSpent Total amount of spent voice credits
   */
  function calcAlpha(
    uint256 _budget,
    uint256 _totalVotesSquares,
    uint256 _totalSpent
  )
    public
    view
    returns (uint256 _alpha)
  {
    // make sure budget = contributions + matching pool
    uint256 contributions = _totalSpent * voiceCreditFactor;
    require(_budget >= contributions, 'FundingRound: Invalid budget');

    // guard against division by zero when fewer than 1 contributor for each project
    require(_totalVotesSquares > _totalSpent, "FundingRound: Total quadratic votes must be greater than total spent voice credits");

    return  (_budget - contributions) * ALPHA_PRECISION /
            (voiceCreditFactor * (_totalVotesSquares - _totalSpent));
  }

  /**
    * @dev Get the total amount of votes from MACI,
    * verify the total amount of spent voice credits across all recipients,
    * calculate the quadratic alpha value,
    * and allow recipients to claim funds.
    * @param _totalSpent Total amount of spent voice credits.
    * @param _totalSpentSalt The salt.
    */
  function finalize(
    uint256 _totalSpent,
    uint256 _totalSpentSalt
  )
    external
    onlyOwner
  {
    require(!isFinalized, 'FundingRound: Already finalized');
    require(address(maci) != address(0), 'FundingRound: MACI not deployed');
    require(maci.calcVotingDeadline() < block.timestamp, 'FundingRound: Voting has not been finished');
    require(!maci.hasUntalliedStateLeaves(), 'FundingRound: Votes has not been tallied');
    require(bytes(tallyHash).length != 0, 'FundingRound: Tally hash has not been published');

    // make sure we have received all the tally results
    (,, uint8 voteOptionTreeDepth) = maci.treeDepths();
    uint256 totalResults = uint256(LEAVES_PER_NODE) ** uint256(voteOptionTreeDepth);
    require(totalTallyResults == totalResults, 'FundingRound: Incomplete tally results');

    totalVotes = maci.totalVotes();
    // If nobody voted, the round should be cancelled to avoid locking of matching funds
    require(totalVotes > 0, 'FundingRound: No votes');
    bool verified = maci.verifySpentVoiceCredits(_totalSpent, _totalSpentSalt);
    require(verified, 'FundingRound: Incorrect total amount of spent voice credits');
    totalSpent = _totalSpent;
    // Total amount of spent voice credits is the size of the pool of direct rewards.
    // Everything else, including unspent voice credits and downscaling error,
    // is considered a part of the matching pool
    uint256 budget = nativeToken.balanceOf(address(this));
    matchingPoolSize = budget - totalSpent * voiceCreditFactor;

    alpha = calcAlpha(budget, totalVotesSquares, totalSpent);

    isFinalized = true;
  }

  /**
    * @dev Cancel funding round.
    */
  function cancel()
    external
    onlyOwner
  {
    require(!isFinalized, 'FundingRound: Already finalized');
    isFinalized = true;
    isCancelled = true;
  }

  /**
    * @dev Get allocated token amount (without verification).
    * @param _tallyResult The result of vote tally for the recipient.
    * @param _spent The amount of voice credits spent on the recipient.
    */
  function getAllocatedAmount(
    uint256 _tallyResult,
    uint256 _spent
  )
    public
    view
    returns (uint256)
  {
    // amount = ( alpha * (quadratic votes)^2 + (precision - alpha) * totalSpent ) / precision
    uint256 quadratic = alpha * voiceCreditFactor * _tallyResult * _tallyResult;
    uint256 linear = (ALPHA_PRECISION - alpha) * voiceCreditFactor * _spent;
    return (quadratic + linear) / ALPHA_PRECISION;
  }

  /**
    * @dev Claim allocated tokens.
    * @param _voteOptionIndex Vote option index.
    * @param _spent The amount of voice credits spent on the recipients.
    * @param _spentProof Proof of correctness for the amount of spent credits.
    * @param _spentSalt Salt.
    */
  function claimFunds(
    uint256 _voteOptionIndex,
    uint256 _spent,
    uint256[][] calldata _spentProof,
    uint256 _spentSalt
  )
    external
  {
    require(isFinalized, 'FundingRound: Round not finalized');
    require(!isCancelled, 'FundingRound: Round has been cancelled');
    require(!recipients[_voteOptionIndex].fundsClaimed, 'FundingRound: Funds already claimed');
    recipients[_voteOptionIndex].fundsClaimed = true;

    {
      // create scope to avoid 'stack too deep' error
      (,, uint8 voteOptionTreeDepth) = maci.treeDepths();
      bool spentVerified = maci.verifyPerVOSpentVoiceCredits(
        voteOptionTreeDepth,
        _voteOptionIndex,
        _spent,
        _spentProof,
        _spentSalt
      );
      require(spentVerified, 'FundingRound: Incorrect amount of spent voice credits');
    }

    uint256 startTime = maci.signUpTimestamp();
    address recipient = recipientRegistry.getRecipientAddress(
      _voteOptionIndex,
      startTime,
      startTime + maci.signUpDurationSeconds() + maci.votingDurationSeconds()
    );
    if (recipient == address(0)) {
      // Send funds back to the matching pool
      recipient = owner();
    }
    uint256 tallyResult = recipients[_voteOptionIndex].tallyResult;
    uint256 allocatedAmount = getAllocatedAmount(tallyResult, _spent);
    nativeToken.safeTransfer(recipient, allocatedAmount);
    emit FundsClaimed(_voteOptionIndex, recipient, allocatedAmount);
  }

  /**
    * @dev Add and verify tally votes and calculate sum of tally squares for alpha calculation.
    * @param _voteOptionTreeDepth Vote option tree depth
    * @param _voteOptionIndex Vote option index.
    * @param _tallyResult The results of vote tally for the recipients.
    * @param _tallyResultProof Proofs of correctness of the vote tally results.
    * @param _tallyResultSalt Salt.
    */
  function _addTallyResult(
    uint8 _voteOptionTreeDepth,
    uint256 _voteOptionIndex,
    uint256 _tallyResult,
    uint256[][] calldata _tallyResultProof,
    uint256 _tallyResultSalt
  )
    private
  {
    RecipientStatus storage recipient = recipients[_voteOptionIndex];
    require(!recipient.tallyVerified, 'FundingRound: Vote results already verified');

    bool resultVerified = maci.verifyTallyResult(
      _voteOptionTreeDepth,
      _voteOptionIndex,
      _tallyResult,
      _tallyResultProof,
      _tallyResultSalt
    );
    require(resultVerified, 'FundingRound: Incorrect tally result');

    recipient.tallyVerified = true;
    recipient.tallyResult = _tallyResult;
    totalVotesSquares = totalVotesSquares + (_tallyResult * _tallyResult);
    totalTallyResults++;
    emit TallyResultsAdded(_voteOptionIndex, _tallyResult);
  }

  /**
    * @dev Add and verify tally results by batch.
    * @param _voteOptionTreeDepth Vote option tree depth.
    * @param _voteOptionIndices Vote option index.
    * @param _tallyResults The results of vote tally for the recipients.
    * @param _tallyResultProofs Proofs of correctness of the vote tally results.
    * @param _tallyResultSalt Salt.
    */
  function addTallyResultsBatch(
    uint8 _voteOptionTreeDepth,
    uint256[] calldata _voteOptionIndices,
    uint256[] calldata _tallyResults,
    uint256[][][] calldata _tallyResultProofs,
    uint256 _tallyResultSalt
  )
    external
    onlyCoordinator
  {
    require(!maci.hasUntalliedStateLeaves(), 'FundingRound: Votes have not been tallied');
    require(!isFinalized, 'FundingRound: Already finalized');

    for (uint256 i = 0; i < _voteOptionIndices.length; i++) {
      _addTallyResult(
        _voteOptionTreeDepth,
        _voteOptionIndices[i],
        _tallyResults[i],
        _tallyResultProofs[i],
        _tallyResultSalt
      );
    }
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';

import 'maci-contracts/sol/MACI.sol';
import 'maci-contracts/sol/MACISharedObjs.sol';
import 'maci-contracts/sol/gatekeepers/SignUpGatekeeper.sol';
import 'maci-contracts/sol/initialVoiceCreditProxy/InitialVoiceCreditProxy.sol';

import './userRegistry/IUserRegistry.sol';
import './recipientRegistry/IRecipientRegistry.sol';
import './MACIFactory.sol';
import './FundingRound.sol';

contract FundingRoundFactory is Ownable, MACISharedObjs {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for ERC20;

  // State
  address public coordinator;

  ERC20 public nativeToken;
  MACIFactory public maciFactory;
  IUserRegistry public userRegistry;
  IRecipientRegistry public recipientRegistry;
  PubKey public coordinatorPubKey;

  EnumerableSet.AddressSet private fundingSources;
  FundingRound[] public rounds;

  // Events
  event FundingSourceAdded(address _source);
  event FundingSourceRemoved(address _source);
  event RoundStarted(address _round);
  event RoundFinalized(address _round);
  event TokenChanged(address _token);
  event CoordinatorChanged(address _coordinator);

  constructor(
    MACIFactory _maciFactory
  )
    public
  {
    maciFactory = _maciFactory;
  }

  /**
    * @dev Set registry of verified users.
    * @param _userRegistry Address of a user registry.
    */
  function setUserRegistry(IUserRegistry _userRegistry)
    external
    onlyOwner
  {
    userRegistry = _userRegistry;
  }

  /**
    * @dev Set recipient registry.
    * @param _recipientRegistry Address of a recipient registry.
    */
  function setRecipientRegistry(IRecipientRegistry _recipientRegistry)
    external
    onlyOwner
  {
    recipientRegistry = _recipientRegistry;
    (,, uint256 maxVoteOptions) = maciFactory.maxValues();
    recipientRegistry.setMaxRecipients(maxVoteOptions);
  }

  /**
    * @dev Add matching funds source.
    * @param _source Address of a funding source.
    */
  function addFundingSource(address _source)
    external
    onlyOwner
  {
    bool result = fundingSources.add(_source);
    require(result, 'Factory: Funding source already added');
    emit FundingSourceAdded(_source);
  }

  /**
    * @dev Remove matching funds source.
    * @param _source Address of the funding source.
    */
  function removeFundingSource(address _source)
    external
    onlyOwner
  {
    bool result = fundingSources.remove(_source);
    require(result, 'Factory: Funding source not found');
    emit FundingSourceRemoved(_source);
  }

  function getCurrentRound()
    public
    view
    returns (FundingRound _currentRound)
  {
    if (rounds.length == 0) {
      return FundingRound(address(0));
    }
    return rounds[rounds.length - 1];
  }

  function setMaciParameters(
    uint8 _stateTreeDepth,
    uint8 _messageTreeDepth,
    uint8 _voteOptionTreeDepth,
    uint8 _tallyBatchSize,
    uint8 _messageBatchSize,
    SnarkVerifier _batchUstVerifier,
    SnarkVerifier _qvtVerifier,
    uint256 _signUpDuration,
    uint256 _votingDuration
  )
    external
    onlyOwner
  {
    maciFactory.setMaciParameters(
      _stateTreeDepth,
      _messageTreeDepth,
      _voteOptionTreeDepth,
      _tallyBatchSize,
      _messageBatchSize,
      _batchUstVerifier,
      _qvtVerifier,
      _signUpDuration,
      _votingDuration
    );
  }

  /**
    * @dev Deploy new funding round.
    */
  function deployNewRound()
    external
    onlyOwner
  {
    require(maciFactory.owner() == address(this), 'Factory: MACI factory is not owned by FR factory');
    require(address(userRegistry) != address(0), 'Factory: User registry is not set');
    require(address(recipientRegistry) != address(0), 'Factory: Recipient registry is not set');
    require(address(nativeToken) != address(0), 'Factory: Native token is not set');
    require(coordinator != address(0), 'Factory: No coordinator');
    FundingRound currentRound = getCurrentRound();
    require(
      address(currentRound) == address(0) || currentRound.isFinalized(),
      'Factory: Current round is not finalized'
    );
    // Make sure that the max number of recipients is set correctly
    (,, uint256 maxVoteOptions) = maciFactory.maxValues();
    recipientRegistry.setMaxRecipients(maxVoteOptions);
    // Deploy funding round and MACI contracts
    FundingRound newRound = new FundingRound(
      nativeToken,
      userRegistry,
      recipientRegistry,
      coordinator
    );
    rounds.push(newRound);
    MACI maci = maciFactory.deployMaci(
      SignUpGatekeeper(newRound),
      InitialVoiceCreditProxy(newRound),
      coordinator,
      coordinatorPubKey
    );
    newRound.setMaci(maci);
    emit RoundStarted(address(newRound));
  }

  /**
    * @dev Get total amount of matching funds.
    */
  function getMatchingFunds(ERC20 token)
    external
    view
    returns (uint256)
  {
    uint256 matchingPoolSize = token.balanceOf(address(this));
    for (uint256 index = 0; index < fundingSources.length(); index++) {
      address fundingSource = fundingSources.at(index);
      uint256 allowance = token.allowance(fundingSource, address(this));
      uint256 balance = token.balanceOf(fundingSource);
      uint256 contribution = allowance < balance ? allowance : balance;
      matchingPoolSize += contribution;
    }
    return matchingPoolSize;
  }

  /**
    * @dev Transfer funds from matching pool to current funding round and finalize it.
    * @param _totalSpent Total amount of spent voice credits.
    * @param _totalSpentSalt The salt.
    */
  function transferMatchingFunds(
    uint256 _totalSpent,
    uint256 _totalSpentSalt
  )
    external
    onlyOwner
  {
    FundingRound currentRound = getCurrentRound();
    require(address(currentRound) != address(0), 'Factory: Funding round has not been deployed');
    ERC20 roundToken = currentRound.nativeToken();
    // Factory contract is the default funding source
    uint256 matchingPoolSize = roundToken.balanceOf(address(this));
    if (matchingPoolSize > 0) {
      roundToken.safeTransfer(address(currentRound), matchingPoolSize);
    }
    // Pull funds from other funding sources
    for (uint256 index = 0; index < fundingSources.length(); index++) {
      address fundingSource = fundingSources.at(index);
      uint256 allowance = roundToken.allowance(fundingSource, address(this));
      uint256 balance = roundToken.balanceOf(fundingSource);
      uint256 contribution = allowance < balance ? allowance : balance;
      if (contribution > 0) {
        roundToken.safeTransferFrom(fundingSource, address(currentRound), contribution);
      }
    }
    currentRound.finalize(_totalSpent, _totalSpentSalt);
    emit RoundFinalized(address(currentRound));
  }

  /**
    * @dev Cancel current round.
    */
   function cancelCurrentRound()
    external
    onlyOwner
  {
    FundingRound currentRound = getCurrentRound();
    require(address(currentRound) != address(0), 'Factory: Funding round has not been deployed');
    require(!currentRound.isFinalized(), 'Factory: Current round is finalized');
    currentRound.cancel();
    emit RoundFinalized(address(currentRound));
  }

  /**
    * @dev Set token in which contributions are accepted.
    * @param _token Address of the token contract.
    */
  function setToken(address _token)
    external
    onlyOwner
  {
    nativeToken = ERC20(_token);
    emit TokenChanged(_token);
  }

  /**
    * @dev Set coordinator's address and public key.
    * @param _coordinator Coordinator's address.
    * @param _coordinatorPubKey Coordinator's public key.
    */
  function setCoordinator(
    address _coordinator,
    PubKey memory _coordinatorPubKey
  )
    external
    onlyOwner
  {
    coordinator = _coordinator;
    coordinatorPubKey = _coordinatorPubKey;
    emit CoordinatorChanged(_coordinator);
  }

  function coordinatorQuit()
    external
    onlyCoordinator
  {
    // The fact that they quit is obvious from
    // the address being 0x0
    coordinator = address(0);
    coordinatorPubKey = PubKey(0, 0);
    FundingRound currentRound = getCurrentRound();
    if (address(currentRound) != address(0) && !currentRound.isFinalized()) {
      currentRound.cancel();
      emit RoundFinalized(address(currentRound));
    }
    emit CoordinatorChanged(address(0));
  }

  modifier onlyCoordinator() {
    require(msg.sender == coordinator, 'Factory: Sender is not the coordinator');
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'maci-contracts/sol/MACI.sol';
import 'maci-contracts/sol/MACIParameters.sol';
import 'maci-contracts/sol/MACISharedObjs.sol';
import 'maci-contracts/sol/gatekeepers/SignUpGatekeeper.sol';
import 'maci-contracts/sol/initialVoiceCreditProxy/InitialVoiceCreditProxy.sol';

contract MACIFactory is Ownable, MACIParameters, MACISharedObjs {
  // Constants
  uint256 private constant STATE_TREE_BASE = 2;
  uint256 private constant MESSAGE_TREE_BASE = 2;
  uint256 private constant VOTE_OPTION_TREE_BASE = 5;

  // State
  TreeDepths public treeDepths;
  BatchSizes public batchSizes;
  MaxValues public maxValues;
  SnarkVerifier public batchUstVerifier;
  SnarkVerifier public qvtVerifier;
  uint256 public signUpDuration;
  uint256 public votingDuration;

  // Events
  event MaciParametersChanged();
  event MaciDeployed(address _maci);

  constructor(
    uint8 _stateTreeDepth,
    uint8 _messageTreeDepth,
    uint8 _voteOptionTreeDepth,
    uint8 _tallyBatchSize,
    uint8 _messageBatchSize,
    SnarkVerifier _batchUstVerifier,
    SnarkVerifier _qvtVerifier,
    uint256 _signUpDuration,
    uint256 _votingDuration
  )
    public
  {
    _setMaciParameters(
      _stateTreeDepth,
      _messageTreeDepth,
      _voteOptionTreeDepth,
      _tallyBatchSize,
      _messageBatchSize,
      _batchUstVerifier,
      _qvtVerifier,
      _signUpDuration,
      _votingDuration
    );
  }

  function _setMaciParameters(
    uint8 _stateTreeDepth,
    uint8 _messageTreeDepth,
    uint8 _voteOptionTreeDepth,
    uint8 _tallyBatchSize,
    uint8 _messageBatchSize,
    SnarkVerifier _batchUstVerifier,
    SnarkVerifier _qvtVerifier,
    uint256 _signUpDuration,
    uint256 _votingDuration
  )
    internal
  {
    treeDepths = TreeDepths(_stateTreeDepth, _messageTreeDepth, _voteOptionTreeDepth);
    batchSizes = BatchSizes(_tallyBatchSize, _messageBatchSize);
    maxValues = MaxValues(
      STATE_TREE_BASE ** treeDepths.stateTreeDepth - 1,
      MESSAGE_TREE_BASE ** treeDepths.messageTreeDepth - 1,
      VOTE_OPTION_TREE_BASE ** treeDepths.voteOptionTreeDepth - 1
    );
    batchUstVerifier = _batchUstVerifier;
    qvtVerifier = _qvtVerifier;
    signUpDuration = _signUpDuration;
    votingDuration = _votingDuration;
  }

  /**
    * @dev Set MACI parameters.
    */
  function setMaciParameters(
    uint8 _stateTreeDepth,
    uint8 _messageTreeDepth,
    uint8 _voteOptionTreeDepth,
    uint8 _tallyBatchSize,
    uint8 _messageBatchSize,
    SnarkVerifier _batchUstVerifier,
    SnarkVerifier _qvtVerifier,
    uint256 _signUpDuration,
    uint256 _votingDuration
  )
    external
    onlyOwner
  {
    require(
      _voteOptionTreeDepth >= treeDepths.voteOptionTreeDepth,
      'MACIFactory: Vote option tree depth can not be decreased'
    );
    _setMaciParameters(
      _stateTreeDepth,
      _messageTreeDepth,
      _voteOptionTreeDepth,
      _tallyBatchSize,
      _messageBatchSize,
      _batchUstVerifier,
      _qvtVerifier,
      _signUpDuration,
      _votingDuration
    );
    emit MaciParametersChanged();
  }

  /**
    * @dev Deploy new MACI instance.
    */
  function deployMaci(
    SignUpGatekeeper _signUpGatekeeper,
    InitialVoiceCreditProxy _initialVoiceCreditProxy,
    address _coordinator,
    PubKey calldata _coordinatorPubKey
  )
    external
    onlyOwner
    returns (MACI _maci)
  {
    _maci = new MACI(
      treeDepths,
      batchSizes,
      maxValues,
      _signUpGatekeeper,
      batchUstVerifier,
      qvtVerifier,
      signUpDuration,
      votingDuration,
      _initialVoiceCreditProxy,
      _coordinatorPubKey,
      _coordinator
    );
    emit MaciDeployed(address(_maci));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// NOTE: had to copy contracts over since OZ uses a higher pragma than we do in the one's they maintain.

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, 'Initializable: contract is already initialized');

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import './IRecipientRegistry.sol';

/**
 * @dev Abstract contract containing common methods for recipient registries.
 */
abstract contract BaseRecipientRegistry is IRecipientRegistry {

  // Structs
  struct Recipient {
    address addr;
    uint256 index;
    uint256 addedAt;
    uint256 removedAt;
  }

  // State
  address public controller;
  uint256 public maxRecipients;
  mapping(bytes32 => Recipient) internal recipients;
  bytes32[] private removed;
  // Slot 0 corresponds to index 1
  // Each slot contains a history of recipients who occupied it
  bytes32[][] private slots;

  /**
    * @dev Set maximum number of recipients.
    * @param _maxRecipients Maximum number of recipients.
    * @return True if operation is successful.
    */
  function setMaxRecipients(uint256 _maxRecipients)
    override
    external
    returns (bool)
  {
    require(
      _maxRecipients >= maxRecipients,
      'RecipientRegistry: Max number of recipients can not be decreased'
    );
    if (controller != msg.sender) {
      // This allows other clrfund instances to use the registry
      // but only controller can actually increase the limit.
      return false;
    }
    maxRecipients = _maxRecipients;
    return true;
  }

  /**
    * @dev Register recipient as eligible for funding allocation.
    * @param _recipientId The ID of recipient.
    * @param _recipient The address that receives funds.
    * @return Recipient index.
    */
  function _addRecipient(bytes32 _recipientId, address _recipient)
    internal
    returns (uint256)
  {
    require(maxRecipients > 0, 'RecipientRegistry: Recipient limit is not set');
    require(recipients[_recipientId].index == 0, 'RecipientRegistry: Recipient already registered');
    uint256 recipientIndex = 0;
    uint256 nextRecipientIndex = slots.length + 1;
    if (nextRecipientIndex <= maxRecipients) {
      // Assign next index in sequence
      recipientIndex = nextRecipientIndex;
      bytes32[] memory history = new bytes32[](1);
      history[0] = _recipientId;
      slots.push(history);
    } else {
      // Assign one of the vacant recipient indexes
      require(removed.length > 0, 'RecipientRegistry: Recipient limit reached');
      bytes32 removedRecipient = removed[removed.length - 1];
      removed.pop();
      recipientIndex = recipients[removedRecipient].index;
      slots[recipientIndex - 1].push(_recipientId);
    }
    recipients[_recipientId] = Recipient(_recipient, recipientIndex, block.timestamp, 0);
    return recipientIndex;
  }

  /**
    * @dev Remove recipient from the registry.
    * @param _recipientId The ID of recipient.
    */
  function _removeRecipient(bytes32 _recipientId)
    internal
  {
    require(recipients[_recipientId].index != 0, 'RecipientRegistry: Recipient is not in the registry');
    require(recipients[_recipientId].removedAt == 0, 'RecipientRegistry: Recipient already removed');
    recipients[_recipientId].removedAt = block.timestamp;
    removed.push(_recipientId);
  }

  /**
    * @dev Get recipient address by index.
    * @param _index Recipient index.
    * @param _startTime The start time of the funding round.
    * @param _endTime The end time of the funding round.
    * @return Recipient address.
    */
  function getRecipientAddress(
    uint256 _index,
    uint256 _startTime,
    uint256 _endTime
  )
    override
    external
    view
    returns (address)
  {
    if (_index == 0 || _index > slots.length) {
      return address(0);
    }
    bytes32[] memory history = slots[_index - 1];
    if (history.length == 0) {
      // Slot is not occupied
      return address(0);
    }
    address prevRecipientAddress = address(0);
    for (uint256 idx = history.length; idx > 0; idx--) {
      bytes32 recipientId = history[idx - 1];
      Recipient memory recipient = recipients[recipientId];
      if (recipient.addedAt > _endTime) {
        // Recipient added after the end of the funding round, skip
        continue;
      }
      else if (recipient.removedAt != 0 && recipient.removedAt <= _startTime) {
        // Recipient had been already removed when the round started
        // Stop search because subsequent items were removed even earlier
        return prevRecipientAddress;
      }
      // This recipient is valid, but the recipient who occupied
      // this slot before also needs to be checked.
      prevRecipientAddress = recipient.addr;
    }
    return prevRecipientAddress;
  }

  /**
    * @dev Get recipient count.
    * @return count of active recipients in the registry.
    */
  function getRecipientCount() public view returns(uint256) {
      return slots.length - removed.length;
  }

  /**
   * @dev Make a unique recipient id for different registries
   * @param _registry Recipient registry address
   * @param _recipient Recipient address
   * @param _metadata Recipient metadata
   * @return recipient id
   */
   function makeRecipientId(address _registry, address _recipient, string calldata _metadata)
    internal
    pure
    returns(bytes32)
  {
    return keccak256(abi.encodePacked(_registry, _recipient, _metadata));
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

/**
 *  @dev Interface for Kleros Generalized TCR.
 */
interface IKlerosGTCR {

  event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

  event ItemSubmitted(
    bytes32 indexed _itemID,
    address indexed _submitter,
    uint indexed _evidenceGroupID,
    bytes _data
  );

  function getItemInfo(bytes32 _itemID) external view returns (bytes memory, uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Interface of the recipient registry.
 *
 * This contract must do the following:
 *
 * - Add recipients to the registry.
 * - Allow only legitimate recipients into the registry.
 * - Assign an unique index to each recipient.
 * - Limit the maximum number of entries according to a parameter set by the funding round factory.
 * - Remove invalid entries.
 * - Prevent indices from changing during the funding round.
 * - Find address of a recipient by their unique index.
 */
interface IRecipientRegistry {

  function setMaxRecipients(uint256 _maxRecipients) external returns (bool);

  function getRecipientAddress(uint256 _index, uint256 _startBlock, uint256 _endBlock) external view returns (address);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import 'solidity-rlp/contracts/RLPReader.sol';

import './BaseRecipientRegistry.sol';
import './IKlerosGTCR.sol';

/**
 * @dev Recipient registry that uses Kleros GTCR to validate recipients.
 */
contract KlerosGTCRAdapter is BaseRecipientRegistry {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  // Constants
  // As defined in https://github.com/kleros/tcr/blob/v2.0.0/contracts/GeneralizedTCR.sol
  uint256 private constant STATUS_ABSENT = 0;
  uint256 private constant STATUS_REGISTERED = 1;

  // State
  IKlerosGTCR public tcr;

  // Events
  event RecipientAdded(
    bytes32 indexed _tcrItemId,
    bytes _metadata,
    uint256 _index,
    uint256 _timestamp
  );
  event RecipientRemoved(
    bytes32 indexed _tcrItemId,
    uint256 _timestamp
  );

  /**
    * @dev Deploy the registry.
    * @param _tcr Address of the Kleros Generalized TCR.
    * @param _controller Controller address. Normally it's a funding round factory contract.
    */
  constructor(
    IKlerosGTCR _tcr,
    address _controller
  )
    public
  {
    tcr = _tcr;
    controller = _controller;
  }

  /**
    * @dev Register recipient as eligible for funding allocation.
    * @param _tcrItemId The ID of the TCR item.
    */
  function addRecipient(bytes32 _tcrItemId)
    external
  {
    (bytes memory rlpData, uint256 status,) = tcr.getItemInfo(_tcrItemId);
    require(status == STATUS_REGISTERED, 'RecipientRegistry: Item not found in TCR');
    RLPReader.RLPItem[] memory recipientData = rlpData.toRlpItem().toList();
    // Recipient address is at index 1
    address recipientAddress = recipientData[1].toAddress();
    uint256 recipientIndex = _addRecipient(_tcrItemId, recipientAddress);
    emit RecipientAdded(_tcrItemId, rlpData, recipientIndex, block.timestamp);
  }

  /**
    * @dev Remove recipient from the registry.
    * @param _tcrItemId The ID of the TCR item.
    */
  function removeRecipient(bytes32 _tcrItemId)
    external
  {
    (,uint256 status,) = tcr.getItemInfo(_tcrItemId);
    require(status == STATUS_ABSENT, 'RecipientRegistry: Item is not removed from TCR');
    _removeRecipient(_tcrItemId);
    emit RecipientRemoved(_tcrItemId, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 *  @title GeneralizedTCR
 *  This contract is a curated registry for any types of items. Just like a TCR contract it features the request-challenge protocol and appeal fees crowdfunding.
 *  Adapted from https://github.com/kleros/tcr/blob/v2.0.0/contracts/GeneralizedTCR.sol
 */
contract KlerosGTCRMock is Ownable {

  enum Status {
    Absent, // The item is not in the registry.
    Registered, // The item is in the registry.
    RegistrationRequested, // The item has a request to be added to the registry.
    ClearingRequested // The item has a request to be removed from the registry.
  }

  struct Item {
    bytes data; // The data describing the item.
    Status status; // The current status of the item.
    Request[] requests; // List of status change requests made for the item in the form requests[requestID].
  }

  struct Request {
    bool disputed; // True if a dispute was raised.
  }

  bytes32[] public itemList; // List of IDs of all submitted items.
  mapping(bytes32 => Item) public items; // Maps the item ID to its data in the form items[_itemID].
  mapping(bytes32 => uint) public itemIDtoIndex; // Maps an item's ID to its position in the list in the form itemIDtoIndex[itemID].

  /**
   * @dev To be emitted when meta-evidence is submitted.
   * @param _metaEvidenceID Unique identifier of meta-evidence.
   * @param _evidence A link to the meta-evidence JSON.
   */
  event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

  /**
   *  @dev Emitted when a party makes a request, raises a dispute or when a request is resolved.
   *  @param _itemID The ID of the affected item.
   *  @param _requestIndex The index of the request.
   *  @param _roundIndex The index of the round.
   *  @param _disputed Whether the request is disputed.
   *  @param _resolved Whether the request is executed.
   */
  event ItemStatusChange(
    bytes32 indexed _itemID,
    uint indexed _requestIndex,
    uint indexed _roundIndex,
    bool _disputed,
    bool _resolved
  );

  /**
   *  @dev Emitted when someone submits an item for the first time.
   *  @param _itemID The ID of the new item.
   *  @param _submitter The address of the requester.
   *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
   *  @param _data The item data.
   */
  event ItemSubmitted(
    bytes32 indexed _itemID,
    address indexed _submitter,
    uint indexed _evidenceGroupID,
    bytes _data
  );

  /**
   *  @dev Deploy the arbitrable curated registry.
   *  @param _registrationMetaEvidence The URI of the meta evidence object for registration requests.
   *  @param _clearingMetaEvidence The URI of the meta evidence object for clearing requests.
   */
  constructor(
    string memory _registrationMetaEvidence,
    string memory _clearingMetaEvidence
  ) public {
    emit MetaEvidence(0, _registrationMetaEvidence);
    emit MetaEvidence(1, _clearingMetaEvidence);
  }

  /** @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
   *  @param _item The data describing the item.
   */
  function addItem(bytes calldata _item) external payable onlyOwner {
    bytes32 itemID = keccak256(_item);
    require(items[itemID].status == Status.Absent, 'Item must be absent to be added.');
    Item storage item = items[itemID];
    item.data = _item;
    item.status = Status.Registered;
    itemList.push(itemID);
    itemIDtoIndex[itemID] = itemList.length - 1;
    emit ItemSubmitted(itemID, msg.sender, 0, item.data);
    emit ItemStatusChange(itemID, 0, 0, false, true);
  }

  /** @dev Submit a request to remove an item from the list. Accepts enough ETH to cover the deposit, reimburses the rest.
   *  @param _itemID The ID of the item to remove.
   */
  function removeItem(bytes32 _itemID) external payable onlyOwner {
    require(items[_itemID].status == Status.Registered, 'Item must be registered to be removed.');
    Item storage item = items[_itemID];
    item.status = Status.Absent;
    emit ItemStatusChange(_itemID, 0, 0, true, true);
  }

  /** @dev Returns item's information. Includes length of requests array.
   *  @param _itemID The ID of the queried item.
   *  @return data The data describing the item.
   *  @return status The current status of the item.
   *  @return numberOfRequests Length of list of status change requests made for the item.
   */
  function getItemInfo(bytes32 _itemID)
    external
    view
    returns (
      bytes memory data,
      Status status,
      uint numberOfRequests
    )
  {
    Item storage item = items[_itemID];
    return (
      item.data,
      item.status,
      item.requests.length
    );
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

import './BaseRecipientRegistry.sol';

/**
 * @dev Recipient registry with optimistic execution of registrations and removals.
 */
contract OptimisticRecipientRegistry is Ownable, BaseRecipientRegistry {

  // Enums
  enum RequestType {
    Registration,
    Removal
  }

  // Structs
  struct Request {
    RequestType requestType;
    address payable requester;
    uint256 submissionTime;
    uint256 deposit;
    address recipientAddress; // Only for registration requests
    string recipientMetadata; // Only for registration requests
  }

  // State
  uint256 public baseDeposit;
  uint256 public challengePeriodDuration;
  mapping(bytes32 => Request) private requests;

  // Events
  event RequestSubmitted(
    bytes32 indexed _recipientId,
    RequestType indexed _type,
    address _recipient,
    string _metadata,
    uint256 _timestamp
  );
  event RequestResolved(
    bytes32 indexed _recipientId,
    RequestType indexed _type,
    bool indexed _rejected,
    uint256 _recipientIndex, // Only for accepted registration requests
    uint256 _timestamp
  );

  /**
    * @dev Deploy the registry.
    * @param _baseDeposit Deposit required to add or remove item.
    * @param _challengePeriodDuration The time owner has to challenge a request (seconds).
    * @param _controller Controller address. Normally it's a funding round factory contract.
    */
  constructor(
    uint256 _baseDeposit,
    uint256 _challengePeriodDuration,
    address _controller
  )
    public
  {
    baseDeposit = _baseDeposit;
    challengePeriodDuration = _challengePeriodDuration;
    controller = _controller;
  }

  /**
    * @dev Change base deposit.
    */
  function setBaseDeposit(uint256 _baseDeposit)
    external
    onlyOwner
  {
    baseDeposit = _baseDeposit;
  }

  /**
    * @dev Change challenge period duration.
    */
  function setChallengePeriodDuration(uint256 _challengePeriodDuration)
    external
    onlyOwner
  {
    challengePeriodDuration = _challengePeriodDuration;
  }

  /**
    * @dev Submit recipient registration request.
    * @param _recipient The address that receives funds.
    * @param _metadata The metadata info of the recipient.
    */
  function addRecipient(address _recipient, string calldata _metadata)
    external
    payable
  {
    require(_recipient != address(0), 'RecipientRegistry: Recipient address is zero');
    require(bytes(_metadata).length != 0, 'RecipientRegistry: Metadata info is empty string');
    bytes32 recipientId = makeRecipientId(address(this), _recipient, _metadata);
    require(recipients[recipientId].index == 0, 'RecipientRegistry: Recipient already registered');
    require(requests[recipientId].submissionTime == 0, 'RecipientRegistry: Request already submitted');
    require(msg.value == baseDeposit, 'RecipientRegistry: Incorrect deposit amount');
    requests[recipientId] = Request(
      RequestType.Registration,
      msg.sender,
      block.timestamp,
      msg.value,
      _recipient,
      _metadata
    );
    emit RequestSubmitted(
      recipientId,
      RequestType.Registration,
      _recipient,
      _metadata,
      block.timestamp
    );
  }

  /**
    * @dev Submit recipient removal request.
    * @param _recipientId The ID of recipient.
    */
  function removeRecipient(bytes32 _recipientId)
    external
    payable
  {
    require(recipients[_recipientId].index != 0, 'RecipientRegistry: Recipient is not in the registry');
    require(recipients[_recipientId].removedAt == 0, 'RecipientRegistry: Recipient already removed');
    require(requests[_recipientId].submissionTime == 0, 'RecipientRegistry: Request already submitted');
    require(msg.value == baseDeposit, 'RecipientRegistry: Incorrect deposit amount');
    requests[_recipientId] = Request(
      RequestType.Removal,
      msg.sender,
      block.timestamp,
      msg.value,
      address(0),
      ''
    );
    emit RequestSubmitted(
      _recipientId,
      RequestType.Removal,
      address(0),
      '',
      block.timestamp
    );
  }

  /**
    * @dev Reject request.
    * @param _recipientId The ID of recipient.
    * @param _beneficiary Address to which the deposit should be transferred.
    */
  function challengeRequest(bytes32 _recipientId, address payable _beneficiary)
    external
    onlyOwner
    returns (bool)
  {
    Request memory request = requests[_recipientId];
    require(request.submissionTime != 0, 'RecipientRegistry: Request does not exist');
    delete requests[_recipientId];
    bool isSent = _beneficiary.send(request.deposit);
    emit RequestResolved(
      _recipientId,
      request.requestType,
      true,
      0,
      block.timestamp
    );
    return isSent;
  }

  /**
    * @dev Execute request.
    * @param _recipientId The ID of recipient.
    */
  function executeRequest(bytes32 _recipientId)
    external
    returns (bool)
  {
    Request memory request = requests[_recipientId];
    require(request.submissionTime != 0, 'RecipientRegistry: Request does not exist');
    if (msg.sender != owner()) {
      require(
        block.timestamp - request.submissionTime >= challengePeriodDuration,
        'RecipientRegistry: Challenge period is not over'
      );
    }
    uint256 recipientIndex = 0;
    if (request.requestType == RequestType.Removal) {
      _removeRecipient(_recipientId);
    } else {
      // WARNING: Could revert if no slots are available or if recipient limit is not set
      recipientIndex = _addRecipient(_recipientId, request.recipientAddress);
    }
    delete requests[_recipientId];
    bool isSent = request.requester.send(request.deposit);
    emit RequestResolved(
      _recipientId,
      request.requestType,
      false,
      recipientIndex,
      block.timestamp
    );
    return isSent;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

import './BaseRecipientRegistry.sol';

/**
 * @dev Recipient registry with permissioned execution of registrations and removals.
 */
contract PermissionedRecipientRegistry is Ownable, BaseRecipientRegistry {

  // Enums
  enum RequestType {
    Registration,
    Removal
  }

  // Structs
  struct Request {
    RequestType requestType;
    address payable requester;
    uint256 submissionTime;
    uint256 deposit;
    address recipientAddress; // Only for registration requests
    string recipientMetadata; // Only for registration requests
  }

  // State
  uint256 public baseDeposit;
  uint256 public challengePeriodDuration;
  mapping(bytes32 => Request) private requests;

  // Events
  event RequestSubmitted(
    bytes32 indexed _recipientId,
    RequestType indexed _type,
    address _recipient,
    string _metadata,
    uint256 _timestamp
  );
  event RequestResolved(
    bytes32 indexed _recipientId,
    RequestType indexed _type,
    bool indexed _rejected,
    uint256 _recipientIndex, // Only for accepted registration requests
    uint256 _timestamp
  );

  /**
    * @dev Deploy the registry.
    * @param _baseDeposit Deposit required to add or remove item.
    * @param _challengePeriodDuration The time owner has to challenge a request (seconds).
    * @param _controller Controller address. Normally it's a funding round factory contract.
    */
  constructor(
    uint256 _baseDeposit,
    uint256 _challengePeriodDuration,
    address _controller
  )
    public
  {
    baseDeposit = _baseDeposit;
    challengePeriodDuration = _challengePeriodDuration;
    controller = _controller;
  }

  /**
    * @dev Change base deposit.
    */
  function setBaseDeposit(uint256 _baseDeposit)
    external
    onlyOwner
  {
    baseDeposit = _baseDeposit;
  }

  /**
    * @dev Change challenge period duration.
    */
  function setChallengePeriodDuration(uint256 _challengePeriodDuration)
    external
    onlyOwner
  {
    challengePeriodDuration = _challengePeriodDuration;
  }

  /**
    * @dev Submit recipient registration request.
    * @param _recipient The address that receives funds.
    * @param _metadata The metadata info of the recipient.
    */
  function addRecipient(address _recipient, string calldata _metadata)
    external
    payable
  {
    require(_recipient != address(0), 'RecipientRegistry: Recipient address is zero');
    require(bytes(_metadata).length != 0, 'RecipientRegistry: Metadata info is empty string');
    bytes32 recipientId = makeRecipientId(address(this), _recipient, _metadata);
    require(recipients[recipientId].index == 0, 'RecipientRegistry: Recipient already registered');
    require(requests[recipientId].submissionTime == 0, 'RecipientRegistry: Request already submitted');
    require(msg.value == baseDeposit, 'RecipientRegistry: Incorrect deposit amount');
    requests[recipientId] = Request(
      RequestType.Registration,
      msg.sender,
      block.timestamp,
      msg.value,
      _recipient,
      _metadata
    );
    emit RequestSubmitted(
      recipientId,
      RequestType.Registration,
      _recipient,
      _metadata,
      block.timestamp
    );
  }

  /**
    * @dev Submit recipient removal request.
    * @param _recipientId The ID of recipient.
    */
  function removeRecipient(bytes32 _recipientId)
    external
    payable
  {
    require(recipients[_recipientId].index != 0, 'RecipientRegistry: Recipient is not in the registry');
    require(recipients[_recipientId].removedAt == 0, 'RecipientRegistry: Recipient already removed');
    require(requests[_recipientId].submissionTime == 0, 'RecipientRegistry: Request already submitted');
    require(msg.value == baseDeposit, 'RecipientRegistry: Incorrect deposit amount');
    requests[_recipientId] = Request(
      RequestType.Removal,
      msg.sender,
      block.timestamp,
      msg.value,
      address(0),
      ''
    );
    emit RequestSubmitted(
      _recipientId,
      RequestType.Removal,
      address(0),
      '',
      block.timestamp
    );
  }

  /**
    * @dev Reject request.
    * @param _recipientId The ID of recipient.
    * @param _beneficiary Address to which the deposit should be transferred.
    */
  function challengeRequest(bytes32 _recipientId, address payable _beneficiary)
    external
    onlyOwner
    returns (bool)
  {
    Request memory request = requests[_recipientId];
    require(request.submissionTime != 0, 'RecipientRegistry: Request does not exist');
    delete requests[_recipientId];
    bool isSent = _beneficiary.send(request.deposit);
    emit RequestResolved(
      _recipientId,
      request.requestType,
      true,
      0,
      block.timestamp
    );
    return isSent;
  }

  /**
    * @dev Execute request.
    * @param _recipientId The ID of recipient.
    */
  function executeRequest(bytes32 _recipientId)
    external
    onlyOwner
    returns (bool)
  {
    Request memory request = requests[_recipientId];
    require(request.submissionTime != 0, 'RecipientRegistry: Request does not exist');
    uint256 recipientIndex = 0;
    if (request.requestType == RequestType.Removal) {
      _removeRecipient(_recipientId);
    } else {
      // WARNING: Could revert if no slots are available or if recipient limit is not set
      recipientIndex = _addRecipient(_recipientId, request.recipientAddress);
    }
    delete requests[_recipientId];
    bool isSent = request.requester.send(request.deposit);
    emit RequestResolved(
      _recipientId,
      request.requestType,
      false,
      recipientIndex,
      block.timestamp
    );
    return isSent;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

import './BaseRecipientRegistry.sol';

/**
 * @dev A simple recipient registry managed by a trusted entity.
 */
contract SimpleRecipientRegistry is Ownable, BaseRecipientRegistry {

  // Events
  event RecipientAdded(
    bytes32 indexed _recipientId,
    address _recipient,
    string _metadata,
    uint256 _index,
    uint256 _timestamp
  );
  event RecipientRemoved(
    bytes32 indexed _recipientId,
    uint256 _timestamp
  );

  /**
    * @dev Deploy the registry.
    * @param _controller Controller address. Normally it's a funding round factory contract.
    */
  constructor(
    address _controller
  )
    public
  {
    controller = _controller;
  }

  /**
    * @dev Register recipient as eligible for funding allocation.
    * @param _recipient The address that receives funds.
    * @param _metadata The metadata info of the recipient.
    */
  function addRecipient(address _recipient, string calldata _metadata)
    external
    onlyOwner
  {
    require(_recipient != address(0), 'RecipientRegistry: Recipient address is zero');
    require(bytes(_metadata).length != 0, 'RecipientRegistry: Metadata info is empty string');
    bytes32 recipientId = makeRecipientId(address(this), _recipient, _metadata);
    uint256 recipientIndex = _addRecipient(recipientId, _recipient);
    emit RecipientAdded(recipientId, _recipient, _metadata, recipientIndex, block.timestamp);
  }

  /**
    * @dev Remove recipient from the registry.
    * @param _recipientId The ID of recipient.
    */
  function removeRecipient(bytes32 _recipientId)
    external
    onlyOwner
  {
    _removeRecipient(_recipientId);
    emit RecipientRemoved(_recipientId, block.timestamp);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

contract BrightIdSponsor {
    event Sponsor(address indexed addr);

    /**
     * @dev sponsor a BrightId user by emitting an event
     * that a BrightId node is listening for
     */
    function sponsor(address addr) public {
        emit Sponsor(addr);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import './IUserRegistry.sol';
import './BrightIdSponsor.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract BrightIdUserRegistry is Ownable, IUserRegistry {
    string private constant ERROR_NEWER_VERIFICATION = 'NEWER VERIFICATION REGISTERED BEFORE';
    string private constant ERROR_NOT_AUTHORIZED = 'NOT AUTHORIZED';
    string private constant ERROR_INVALID_VERIFIER = 'INVALID VERIFIER';
    string private constant ERROR_INVALID_CONTEXT = 'INVALID CONTEXT';
    string private constant ERROR_INVALID_SPONSOR = 'INVALID SPONSOR';

    bytes32 public context;
    address public verifier;
    BrightIdSponsor public brightIdSponsor;

    struct Verification {
        uint256 time;
    }
    mapping(address => Verification) public verifications;

    event SetBrightIdSettings(bytes32 context, address verifier);

    event Registered(address indexed addr, uint256 timestamp);
    event SponsorChanged(address sponsor);

    /**
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     * @param _sponsor Contract address that emits BrightID sponsor event
     */
    constructor(bytes32 _context, address _verifier, address _sponsor) public {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);
        require(_sponsor != address(0), ERROR_INVALID_SPONSOR);

        context = _context;
        verifier = _verifier;
        brightIdSponsor = BrightIdSponsor(_sponsor);
    }

    /**
     * @notice Sponsor a BrightID user by context id
     * @param addr BrightID context id
     */
    function sponsor(address addr) public {
        brightIdSponsor.sponsor(addr);
    }

    /**
     * @notice Set BrightID settings
     * @param _context BrightID context used for verifying users
     * @param _verifier BrightID verifier address that signs BrightID verifications
     */
    function setSettings(bytes32 _context, address _verifier) external onlyOwner {
        // ecrecover returns zero on error
        require(_verifier != address(0), ERROR_INVALID_VERIFIER);

        context = _context;
        verifier = _verifier;
        emit SetBrightIdSettings(_context, _verifier);
    }

    /**
     * @notice Set BrightID sponsor
     * @param _sponsor Contract address that emits BrightID sponsor event
     */
    function setSponsor(address _sponsor) external onlyOwner {
        require(_sponsor != address(0), ERROR_INVALID_SPONSOR);

        brightIdSponsor = BrightIdSponsor(_sponsor);
        emit SponsorChanged(_sponsor);
    }

    /**
     * @notice Check a user is verified or not
     * @param _user BrightID context id used for verifying users
     */
    function isVerifiedUser(address _user)
      override
      external
      view
      returns (bool)
    {
        Verification memory verification = verifications[_user];
        return verification.time > 0;
    }

    /**
     * @notice Register a user by BrightID verification
     * @param _context The context used in the users verification
     * @param _addr The address used by this user in this context
     * @param _verificationHash sha256 of the verification expression
     * @param _timestamp The BrightID node's verification timestamp
     * @param _v Component of signature
     * @param _r Component of signature
     * @param _s Component of signature
     */
    function register(
        bytes32 _context,
        address _addr,
        bytes32 _verificationHash,
        uint _timestamp,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(context == _context, ERROR_INVALID_CONTEXT);
        require(verifications[_addr].time < _timestamp, ERROR_NEWER_VERIFICATION);

        bytes32 message = keccak256(abi.encodePacked(_context, _addr, _verificationHash, _timestamp));
        address signer = ecrecover(message, _v, _r, _s);
        require(verifier == signer, ERROR_NOT_AUTHORIZED);

        verifications[_addr].time = _timestamp;

        emit Registered(_addr, _timestamp);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

/**
 * @dev Interface of the registry of verified users.
 */
interface IUserRegistry {

  function isVerifiedUser(address _user) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

import './IUserRegistry.sol';
import {MerkleProof} from "../utils/cryptography/MerkleProof.sol";


/**
 * @dev A merkle user registry add users to the registry based on 
 * a successful verification against the merkle root set by
 * the funding round coordinator.
 */
contract MerkleUserRegistry is Ownable, IUserRegistry {

  // verified users grouped by merkleRoot
  // merkleRoot -> user -> status
  mapping(bytes32 => mapping(address => bool)) private users;

  // merkle root
  bytes32 public merkleRoot;

  // ipfs hash of the merkle tree file
  string public merkleHash;

  // Events
  event UserAdded(address indexed _user, bytes32 indexed merkleRoot);
  event MerkleRootChanged(bytes32 indexed root, string ipfsHash);

  /**
    * @dev Set the merkle root used to verify users
    * @param root Merkle root
    * @param ipfsHash The IPFS hash of the merkle tree file
   */
  function setMerkleRoot(bytes32 root, string calldata ipfsHash) external onlyOwner {
    require(root != bytes32(0), 'MerkleUserRegistry: Merkle root is zero');
    require(bytes(ipfsHash).length != 0, 'MerkleUserRegistry: Merkle hash is empty string');

    merkleRoot = root;
    merkleHash = ipfsHash;

    emit MerkleRootChanged(root, ipfsHash);
  }

  /**
    * @dev Add verified unique user to the registry.
    */
  function addUser(address _user, bytes32[] calldata proof)
    external
  {
    require(merkleRoot != bytes32(0), 'MerkleUserRegistry: Merkle root is not initialized');
    require(_user != address(0), 'MerkleUserRegistry: User address is zero');
    require(!users[merkleRoot][_user], 'MerkleUserRegistry: User already verified');

    // verifies user against the merkle root
    bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encode(_user))));
    bool verified = MerkleProof.verifyCalldata(proof, merkleRoot, leaf);
    require(verified, 'MerkleUserRegistry: User is not authorized');

    users[merkleRoot][_user] = true;
    emit UserAdded(_user, merkleRoot);
    
  }

  /**
    * @dev Check if the user is verified.
    */
  function isVerifiedUser(address _user)
    override
    external
    view
    returns (bool)
  {
    return users[merkleRoot][_user];
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

import './IUserRegistry.sol';

/**
 * @dev A simple user registry managed by a trusted entity.
 */
contract SimpleUserRegistry is Ownable, IUserRegistry {

  mapping(address => bool) private users;

  // Events
  event UserAdded(address indexed _user);
  event UserRemoved(address indexed _user);

  /**
    * @dev Add verified unique user to the registry.
    */
  function addUser(address _user)
    external
    onlyOwner
  {
    require(_user != address(0), 'UserRegistry: User address is zero');
    require(!users[_user], 'UserRegistry: User already verified');
    users[_user] = true;
    emit UserAdded(_user);
  }

  /**
    * @dev Remove user from the registry.
    */
  function removeUser(address _user)
    external
    onlyOwner
  {
    require(users[_user], 'UserRegistry: User is not in the registry');
    delete users[_user];
    emit UserRemoved(_user);
  }

  /**
    * @dev Check if the user is verified.
    */
  function isVerifiedUser(address _user)
    override
    external
    view
    returns (bool)
  {
    return users[_user];
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/access/Ownable.sol';

import './IUserRegistry.sol';

import {RLPReader} from "solidity-rlp/contracts/RLPReader.sol";
import {StateProofVerifier} from "../utils/cryptography/StateProofVerifier.sol";


/**
 * @dev A user registry that verifies users based on ownership of a token
 * at a specific block snapshot
 */
contract SnapshotUserRegistry is Ownable, IUserRegistry {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for bytes;

  enum Status {
    Unverified,
    Verified,
    Rejected
  }

  // User must hold this token at a specific block to be added to this registry
  address public token;

  // block hash of the snapshot block
  bytes32 public blockHash;

  // The storage root for the token at a specified block
  bytes32 public storageRoot;

  // The slot index for the token balance
  uint256 public storageSlot;

  // The minimum balance the user must hold to be verified 
  uint256 public minBalance = 1;

  // verified users
  // blockHash -> user -> status
  mapping(bytes32 => mapping(address => Status)) public users;
  
  // Events
  event UserAdded(address indexed _user, bytes32 indexed blockHash);
  event MinBalanceChanged(uint256 newBalance);
  event StorageRootChanged(address indexed _token, bytes32 indexed _blockHash, uint256 storageSlot);

  /**
  * @dev Set the storage root for the token contract at a specific block
  * @param _tokenAddress Token address
  * @param _blockHash Block hash
  * @param _stateRoot Block state root
  * @param _slotIndex slot index of the token balances storage
  * @param _accountProofRlpBytes RLP encoded accountProof from eth_getProof
  */
  function setStorageRoot(
    address      _tokenAddress,
    bytes32      _blockHash,
    bytes32      _stateRoot,
    uint256      _slotIndex,
    bytes memory _accountProofRlpBytes
  )
    external
    onlyOwner
  {
    require(_tokenAddress != address(0), 'SnapshotUserRegistry: Token address is zero');
    require(_blockHash != bytes32(0), 'SnapshotUserRegistry: Block hash is zero');
    require(_stateRoot != bytes32(0), 'SnapshotUserRegistry: State root is zero');

    RLPReader.RLPItem[] memory proof = _accountProofRlpBytes.toRlpItem().toList();
    bytes32 addressHash = keccak256(abi.encodePacked(uint160(_tokenAddress)));

    StateProofVerifier.Account memory account = StateProofVerifier.extractAccountFromProof(
        addressHash,
        _stateRoot,
        proof
    );

    token = _tokenAddress;
    blockHash = _blockHash;
    storageRoot = account.storageRoot;
    storageSlot = _slotIndex;

    emit StorageRootChanged(token, blockHash, storageSlot);
  }

  /**
    * @dev Add a verified user to the registry.
    * @param _user user account address
    * @param storageProofRlpBytes RLP-encoded storage proof from eth_getProof
    */
  function addUser(
    address _user,
    bytes memory storageProofRlpBytes
  )
    external
  {
    require(storageRoot != bytes32(0), 'SnapshotUserRegistry: Registry is not initialized');
    require(_user != address(0), 'SnapshotUserRegistry: User address is zero');
    require(users[blockHash][_user] == Status.Unverified, 'SnapshotUserRegistry: User already added');

    RLPReader.RLPItem[] memory proof = storageProofRlpBytes.toRlpItem().toList();

    bytes32 userSlotHash = keccak256(abi.encodePacked(uint256(uint160(_user)), storageSlot));
    bytes32 proofPath = keccak256(abi.encodePacked(userSlotHash));
    StateProofVerifier.SlotValue memory slotValue = StateProofVerifier.extractSlotValueFromProof(proofPath, storageRoot, proof);
    require(slotValue.exists, 'SnapshotUserRegistry: User is not qualified');
    require(slotValue.value >= minBalance , 'SnapshotUserRegistry: User did not meet the minimum balance requirement');
    
    users[blockHash][_user] = Status.Verified;
    emit UserAdded(_user, blockHash);
  }

  /**
    * @dev Check if the user is verified.
    */
  function isVerifiedUser(address _user)
    override
    external
    view
    returns (bool)
  {
    return users[blockHash][_user] == Status.Verified;
  }

  /**
   * @dev Change the minimum balance a user must hold to be verified
   * @param newMinBalance The new minimum balance
   */
  function setMinBalance(uint256 newMinBalance) external onlyOwner {
    require(newMinBalance > 0, 'SnapshotUserRegistry: The minimum balance must be greater than 0');
    
    minBalance = newMinBalance;

    emit MinBalanceChanged(minBalance);
  }
}

// SPDX-License-Identifier: MIT

/**
 * Modified from https://github.com/lidofinance/curve-merkle-oracle/blob/main/contracts/MerklePatriciaProofVerifier.sol
 * git commit hash 1033b3e84142317ffd8f366b52e489d5eb49c73f
 */
pragma solidity ^0.6.12;

import {RLPReader} from "solidity-rlp/contracts/RLPReader.sol";


library MerklePatriciaProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @dev Validates a Merkle-Patricia-Trie proof.
    ///      If the proof proves the inclusion of some key-value pair in the
    ///      trie, the value is returned. Otherwise, i.e. if the proof proves
    ///      the exclusion of a key from the trie, an empty byte array is
    ///      returned.
    /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
    /// @param path is the key of the node whose inclusion/exclusion we are
    ///        proving.
    /// @param stack is the stack of MPT nodes (starting with the root) that
    ///        need to be traversed during verification.
    /// @return value whose inclusion is proved or an empty byte array for
    ///         a proof of exclusion
    function extractProofValue(
        bytes32 rootHash,
        bytes memory path,
        RLPReader.RLPItem[] memory stack
    ) internal pure returns (bytes memory value) {
        bytes memory mptKey = _decodeNibbles(path, 0);
        uint256 mptKeyOffset = 0;

        bytes32 nodeHashHash;
        RLPReader.RLPItem[] memory node;

        RLPReader.RLPItem memory rlpValue;

        if (stack.length == 0) {
            // Root hash of empty Merkle-Patricia-Trie
            require(rootHash == 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421, "MerklePatriciaProofVerifier: Invalid empty root hash");
            return new bytes(0);
        }

        // Traverse stack of nodes starting at root.
        for (uint256 i = 0; i < stack.length; i++) {

            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.

            // The root node is hashed with Keccak-256 ...
            if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
                revert("MerklePatriciaProofVerifier: Invalid first root hash");
            }
            // ... whereas all other nodes are hashed with the MPT
            // hash function.
            if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
                revert("MerklePatriciaProofVerifier: Invalid node hash");
            }
            // We verified that stack[i] has the correct hash, so we
            // may safely decode it.
            node = stack[i].toList();

            if (node.length == 2) {
                // Extension or Leaf node

                bool isLeaf;
                bytes memory nodeKey;
                (isLeaf, nodeKey) = _merklePatriciaCompactDecode(node[0].toBytes());

                uint256 prefixLength = _sharedPrefixLength(mptKeyOffset, mptKey, nodeKey);
                mptKeyOffset += prefixLength;

                if (prefixLength < nodeKey.length) {
                    // Proof claims divergent extension or leaf. (Only
                    // relevant for proofs of exclusion.)
                    // An Extension/Leaf node is divergent iff it "skips" over
                    // the point at which a Branch node should have been had the
                    // excluded key been included in the trie.
                    // Example: Imagine a proof of exclusion for path [1, 4],
                    // where the current node is a Leaf node with
                    // path [1, 3, 3, 7]. For [1, 4] to be included, there
                    // should have been a Branch node at [1] with a child
                    // at 3 and a child at 4.

                    // Sanity check
                    if (i < stack.length - 1) {
                        // divergent node must come last in proof
                        revert("MerklePatriciaProofVerifier: divergent node must come last in the proof");
                    }

                    return new bytes(0);
                }

                if (isLeaf) {
                    // Sanity check
                    if (i < stack.length - 1) {
                        // leaf node must come last in proof
                        revert("MerklePatriciaProofVerifier: leaf node must come last in the proof");
                    }

                    if (mptKeyOffset < mptKey.length) {
                        return new bytes(0);
                    }

                    rlpValue = node[1];
                    return rlpValue.toBytes();
                } else { // extension
                    // Sanity check
                    if (i == stack.length - 1) {
                        // shouldn't be at last level
                        revert("MerklePatriciaProofVerifier: unexpected last level for extension");
                    }

                    if (!node[1].isList()) {
                        // rlp(child) was at least 32 bytes. node[1] contains
                        // Keccak256(rlp(child)).
                        nodeHashHash = node[1].payloadKeccak256();
                    } else {
                        // rlp(child) was less than 32 bytes. node[1] contains
                        // rlp(child).
                        nodeHashHash = node[1].rlpBytesKeccak256();
                    }
                }
            } else if (node.length == 17) {
                // Branch node

                if (mptKeyOffset != mptKey.length) {
                    // we haven't consumed the entire path, so we need to look at a child
                    uint8 nibble = uint8(mptKey[mptKeyOffset]);
                    mptKeyOffset += 1;
                    if (nibble >= 16) {
                        // each element of the path has to be a nibble
                        revert("MerklePatriciaProofVerifier: Each element of the path has to be a nibble");
                    }

                    if (_isEmptyBytesequence(node[nibble])) {
                        // Sanity
                        if (i != stack.length - 1) {
                            // leaf node should be at last level
                            revert("MerklePatriciaProofVerifier: leaf node should be at the last level");
                        }

                        return new bytes(0);
                    } else if (!node[nibble].isList()) {
                        nodeHashHash = node[nibble].payloadKeccak256();
                    } else {
                        nodeHashHash = node[nibble].rlpBytesKeccak256();
                    }
                } else {
                    // we have consumed the entire mptKey, so we need to look at what's contained in this node.

                    // Sanity
                    if (i != stack.length - 1) {
                        // should be at last level
                        revert("MerklePatriciaProofVerifier: Should be at the last level");
                    }

                    return node[16].toBytes();
                }
            }
        }
    }


    /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the RLP item.
    ///      Merkle-Patricia-Tries use a weird "hash function" that outputs
    ///      *variable-length* hashes: If the item is shorter than 32 bytes,
    ///      the MPT hash is the item. Otherwise, the MPT hash is the
    ///      Keccak-256 hash of the item.
    ///      The easiest way to compare variable-length byte sequences is
    ///      to compare their Keccak-256 hashes.
    /// @param item The RLP item to be hashed.
    /// @return Keccak-256(MPT-hash(item))
    function _mptHashHash(RLPReader.RLPItem memory item) private pure returns (bytes32) {
        if (item.len < 32) {
            return item.rlpBytesKeccak256();
        } else {
            return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
        }
    }

    function _isEmptyBytesequence(RLPReader.RLPItem memory item) private pure returns (bool) {
        if (item.len != 1) {
            return false;
        }
        uint8 b;
        uint256 memPtr = item.memPtr;
        assembly {
            b := byte(0, mload(memPtr))
        }
        return b == 0x80 /* empty byte string */;
    }


    function _merklePatriciaCompactDecode(bytes memory compact) private pure returns (bool isLeaf, bytes memory nibbles) {
        require(compact.length > 0);
        uint256 firstNibble = uint8(compact[0]) >> 4 & 0xF;
        uint256 skipNibbles;
        if (firstNibble == 0) {
            skipNibbles = 2;
            isLeaf = false;
        } else if (firstNibble == 1) {
            skipNibbles = 1;
            isLeaf = false;
        } else if (firstNibble == 2) {
            skipNibbles = 2;
            isLeaf = true;
        } else if (firstNibble == 3) {
            skipNibbles = 1;
            isLeaf = true;
        } else {
            // Not supposed to happen!
            revert("MerklePatriciaProofVerifier: Unexpected firstNibble value");
        }
        return (isLeaf, _decodeNibbles(compact, skipNibbles));
    }


    function _decodeNibbles(bytes memory compact, uint256 skipNibbles) private pure returns (bytes memory nibbles) {
        require(compact.length > 0);

        uint256 length = compact.length * 2;
        require(skipNibbles <= length);
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1((uint8(compact[i/2]) >> 4) & 0xF);
            } else {
                nibbles[nibblesLength] = bytes1((uint8(compact[i/2]) >> 0) & 0xF);
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }


    function _sharedPrefixLength(uint256 xsOffset, bytes memory xs, bytes memory ys) private pure returns (uint256) {
        uint256 i;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }
}

// SPDX-License-Identifier: MIT
// Modified from OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.6.12;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {RLPReader} from "solidity-rlp/contracts/RLPReader.sol";
import {MerklePatriciaProofVerifier} from "./MerklePatriciaProofVerifier.sol";

/**
 * @title A helper library for verification of Merkle Patricia account and state proofs.
 *
 * Modified from https://github.com/lidofinance/curve-merkle-oracle/blob/main/contracts/StateProofVerifier.sol
 * git commit hash 1033b3e84142317ffd8f366b52e489d5eb49c73f
 *
 */
library StateProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    struct Account {
        bool exists;
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct SlotValue {
        bool exists;
        uint256 value;
    }

    /**
     * @notice Verifies Merkle Patricia proof of an account and extracts the account fields.
     *
     * @param _addressHash Keccak256 hash of the address corresponding to the account.
     * @param _stateRootHash MPT root hash of the Ethereum state trie.
     */
    function extractAccountFromProof(
        bytes32 _addressHash, // keccak256(abi.encodePacked(address))
        bytes32 _stateRootHash,
        RLPReader.RLPItem[] memory _proof
    )
        internal pure returns (Account memory)
    {
        bytes memory acctRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
            _stateRootHash,
            abi.encodePacked(_addressHash),
            _proof
        );

        Account memory account;

        if (acctRlpBytes.length == 0) {
            return account;
        }

        RLPReader.RLPItem[] memory acctFields = acctRlpBytes.toRlpItem().toList();
        require(acctFields.length == 4, "ProofVerifier: Invalid account length");

        account.exists = true;
        account.nonce = acctFields[0].toUint();
        account.balance = acctFields[1].toUint();
        account.storageRoot = bytes32(acctFields[2].toUint());
        account.codeHash = bytes32(acctFields[3].toUint());

        return account;
    }


    /**
     * @notice Verifies Merkle Patricia proof of a slot and extracts the slot's value.
     *
     * @param _slotHash Keccak256 hash of the slot position.
     * @param _storageRootHash MPT root hash of the account's storage trie.
     */
    function extractSlotValueFromProof(
        bytes32 _slotHash,
        bytes32 _storageRootHash,
        RLPReader.RLPItem[] memory _proof
    )
        internal pure returns (SlotValue memory)
    {
        bytes memory valueRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
            _storageRootHash,
            abi.encodePacked(_slotHash),
            _proof
        );

        SlotValue memory value;

        if (valueRlpBytes.length != 0) {
            value.exists = true;
            value.value = valueRlpBytes.toRlpItem().toUint();
        }

        return value;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import { SnarkConstants } from "./SnarkConstants.sol";
import { Hasher } from "./Hasher.sol";

contract ComputeRoot is Hasher {

    uint8 private constant LEAVES_PER_NODE = 5;

    function computeEmptyRoot(uint8 _treeLevels, uint256 _zeroValue) public pure returns (uint256) {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= 32,
            "ComputeRoot: _treeLevels must be between 0 and 33"
        );

        uint256 currentZero = _zeroValue;
        for (uint8 i = 1; i < _treeLevels; i++) {
            uint256 hashed = hashLeftRight(currentZero, currentZero);
            currentZero = hashed;
        }

        return hashLeftRight(currentZero, currentZero);
    }

    function computeEmptyQuinRoot(uint8 _treeLevels, uint256 _zeroValue) public pure returns (uint256) {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= 32,
            "ComputeRoot: _treeLevels must be between 0 and 33"
        );

        uint256 currentZero = _zeroValue;

        for (uint8 i = 0; i < _treeLevels; i++) {

            uint256[LEAVES_PER_NODE] memory z;

            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                z[j] = currentZero;
            }

            currentZero = hash5(z);
        }

        return currentZero;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import { Hasher } from "./Hasher.sol";
import { MACISharedObjs } from "./MACISharedObjs.sol";

contract DomainObjs is Hasher, MACISharedObjs {
    struct StateLeaf {
        PubKey pubKey;
        uint256 voteOptionTreeRoot;
        uint256 voiceCreditBalance;
        uint256 nonce;
    }

    function hashStateLeaf(StateLeaf memory _stateLeaf) public pure returns (uint256) {
        uint256[5] memory plaintext;
        plaintext[0] = _stateLeaf.pubKey.x;
        plaintext[1] = _stateLeaf.pubKey.y;
        plaintext[2] = _stateLeaf.voteOptionTreeRoot;
        plaintext[3] = _stateLeaf.voiceCreditBalance;
        plaintext[4] = _stateLeaf.nonce;

        return hash5(plaintext);
    }

    function hashMessage(Message memory _message) public pure returns (uint256) {
        uint256[] memory plaintext = new uint256[](MESSAGE_DATA_LENGTH + 1);

        plaintext[0] = _message.iv;

        for (uint8 i=0; i < MESSAGE_DATA_LENGTH; i++) {
            plaintext[i+1] = _message.data[i];
        }

        return hash11(plaintext);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract SignUpGatekeeper {
    function register(address _user, bytes memory _data) virtual public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import {PoseidonT3, PoseidonT6} from "./Poseidon.sol";

import {SnarkConstants} from "./SnarkConstants.sol";

/*
 * Poseidon hash functions for 2, 5, and 11 input elements.
 */
contract Hasher is SnarkConstants {
    function hash5(uint256[5] memory array) public pure returns (uint256) {
        return PoseidonT6.poseidon(array);
    }

    function hash11(uint256[] memory array) public pure returns (uint256) {
        uint256[] memory input11 = new uint256[](11);
        uint256[5] memory first5;
        uint256[5] memory second5;
        for (uint256 i = 0; i < array.length; i++) {
            input11[i] = array[i];
        }

        for (uint256 i = array.length; i < 11; i++) {
            input11[i] = 0;
        }

        for (uint256 i = 0; i < 5; i++) {
            first5[i] = input11[i];
            second5[i] = input11[i + 5];
        }

        uint256[2] memory first2;
        first2[0] = PoseidonT6.poseidon(first5);
        first2[1] = PoseidonT6.poseidon(second5);
        uint256[2] memory second2;
        second2[0] = PoseidonT3.poseidon(first2);
        second2[1] = input11[10];
        return PoseidonT3.poseidon(second2);
    }

    function hashLeftRight(uint256 _left, uint256 _right)
        public
        pure
        returns (uint256)
    {
        uint256[2] memory input;
        input[0] = _left;
        input[1] = _right;
        return PoseidonT3.poseidon(input);
    }
}

// SPDX-License-Identifier: MIT

/*
 * Semaphore - Zero-knowledge signaling on Ethereum
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of Semaphore.
 *
 * Semaphore is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Semaphore is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Semaphore.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

import { SnarkConstants } from "./SnarkConstants.sol";
import { Hasher } from "./Hasher.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleZeros } from "./MerkleBinaryMaci.sol";

contract IncrementalMerkleTree is Ownable, Hasher, MerkleZeros {
    // The maximum tree depth
    uint8 internal constant MAX_DEPTH = 32;

    // The tree depth
    uint8 internal treeLevels;

    // The number of inserted leaves
    uint256 internal nextLeafIndex = 0;

    // The Merkle root
    uint256 public root;

    // Allows you to compute the path to the element (but it's not the path to
    // the elements). Caching these values is essential to efficient appends.
    uint256[MAX_DEPTH] internal filledSubtrees;

    // Whether the contract has already seen a particular Merkle tree root
    mapping (uint256 => bool) public rootHistory;

    event LeafInsertion(uint256 indexed leaf, uint256 indexed leafIndex);

    string constant ERROR_LEAF_TOO_LARGE = "E01";
    string constant ERROR_TREE_FULL = "E02";
    string constant ERROR_INVALID_LEVELS = "E03";
    string constant ERROR_INVALID_ZERO = "E04";

    constructor(uint8 _treeLevels, uint256 _zeroValue, bool _isPreCalc) public {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= MAX_DEPTH,
            ERROR_INVALID_LEVELS
        );
        
        if (_isPreCalc) {
            // Use pre-calculated zero values (see MerkleZeros.sol.template)
            populateZeros();
            require(_zeroValue == zeros[0], ERROR_INVALID_ZERO);
            treeLevels = _treeLevels;

            root = zeros[_treeLevels];
        } else {
            /*
               To initialise the Merkle tree, we need to calculate the Merkle root
               assuming that each leaf is the zero value.

                H(H(a,b), H(c,d))
                 /             \
                H(a,b)        H(c,d)
                 /   \        /    \
                a     b      c      d

               `zeros` and `filledSubtrees` will come in handy later when we do
               inserts or updates. e.g when we insert a value in index 1, we will
               need to look up values from those arrays to recalculate the Merkle
               root.
             */
            treeLevels = _treeLevels;

            zeros[0] = _zeroValue;

            uint256 currentZero = _zeroValue;
            for (uint8 i = 1; i < _treeLevels; i++) {
                uint256 hashed = hashLeftRight(currentZero, currentZero);
                zeros[i] = hashed;
                currentZero = hashed;
            }

            root = hashLeftRight(currentZero, currentZero);
        }
    }

    /*
     * Inserts a leaf into the Merkle tree and updates the root and filled
     * subtrees.
     * @param _leaf The value to insert. It must be less than the snark scalar
     *              field or this function will throw.
     * @return The leaf index.
     */
    function insertLeaf(uint256 _leaf) public onlyOwner returns (uint256) {
        require(_leaf < SNARK_SCALAR_FIELD, ERROR_LEAF_TOO_LARGE);

        uint256 currentIndex = nextLeafIndex;

        uint256 depth = uint256(treeLevels);
        require(currentIndex < uint256(2) ** depth, ERROR_TREE_FULL);

        uint256 currentLevelHash = _leaf;
        uint256 left;
        uint256 right;

        for (uint8 i = 0; i < treeLevels; i++) {
            // if current_index is 5, for instance, over the iterations it will
            // look like this: 5, 2, 1, 0, 0, 0 ...

            if (currentIndex % 2 == 0) {
                // For later values of `i`, use the previous hash as `left`, and
                // the (hashed) zero value for `right`
                left = currentLevelHash;
                right = zeros[i];

                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);

            // equivalent to currentIndex /= 2;
            currentIndex >>= 1;
        }

        root = currentLevelHash;
        rootHistory[root] = true;

        uint256 n = nextLeafIndex;
        nextLeafIndex += 1;

        emit LeafInsertion(_leaf, n);

        return currentIndex;
    }
}

// SPDX-License-Identifier: MIT

/*
 * MACI - Minimum Anti-Collusion Infrastructure
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of MACI.
 *
 * MACI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MACI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MACI.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

import { SnarkConstants } from "./SnarkConstants.sol";
import { Hasher } from "./Hasher.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * An incremental Merkle tree which supports up to 5 leaves per node.
 */
contract IncrementalQuinTree is Ownable, Hasher {
    // The maximum tree depth
    uint8 internal constant MAX_DEPTH = 32;

    // The number of leaves per node
    uint8 internal constant LEAVES_PER_NODE = 5;

    // The tree depth
    uint8 internal treeLevels;

    // The number of inserted leaves
    uint256 internal nextLeafIndex = 0;

    // The Merkle root
    uint256 public root;

    // The zero value per level
    mapping (uint256 => uint256) internal zeros;

    // Allows you to compute the path to the element (but it's not the path to
    // the elements). Caching these values is essential to efficient appends.
    mapping (uint256 => mapping (uint256 => uint256)) internal filledSubtrees;

    // Whether the contract has already seen a particular Merkle tree root
    mapping (uint256 => bool) public rootHistory;

    event LeafInsertion(uint256 indexed leaf, uint256 indexed leafIndex);

    /*
     * Stores the Merkle root and intermediate values (the Merkle path to the
     * the first leaf) assuming that all leaves are set to _zeroValue.
     * @param _treeLevels The number of levels of the tree
     * @param _zeroValue The value to set for every leaf. Ideally, this should
     *                   be a nothing-up-my-sleeve value, so that nobody can
     *                   say that the deployer knows the preimage of an empty
     *                   leaf.
     */
    constructor(uint8 _treeLevels, uint256 _zeroValue) public {
        // Limit the Merkle tree to MAX_DEPTH levels
        require(
            _treeLevels > 0 && _treeLevels <= MAX_DEPTH,
            "IncrementalQuinTree: _treeLevels must be between 0 and 33"
        );
        
        /*
           To initialise the Merkle tree, we need to calculate the Merkle root
           assuming that each leaf is the zero value.

           `zeros` and `filledSubtrees` will come in handy later when we do
           inserts or updates. e.g when we insert a value in index 1, we will
           need to look up values from those arrays to recalculate the Merkle
           root.
         */
        treeLevels = _treeLevels;

        uint256 currentZero = _zeroValue;

        // hash5 requires a uint256[] memory input, so we have to use temp
        uint256[LEAVES_PER_NODE] memory temp;

        for (uint8 i = 0; i < _treeLevels; i++) {
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                temp[j] = currentZero;
            }

            zeros[i] = currentZero;
            currentZero = hash5(temp);
        }

        root = currentZero;
    }

    /*
     * Inserts a leaf into the Merkle tree and updates its root.
     * Also updates the cached values which the contract requires for efficient
     * insertions.
     * @param _leaf The value to insert. It must be less than the snark scalar
     *              field or this function will throw.
     * @return The leaf index.
     */
    function insertLeaf(uint256 _leaf) public onlyOwner returns (uint256) {
        require(
            _leaf < SNARK_SCALAR_FIELD,
            "IncrementalQuinTree: insertLeaf argument must be < SNARK_SCALAR_FIELD"
        );

        // Ensure that the tree is not full
        require(
            nextLeafIndex < uint256(LEAVES_PER_NODE) ** uint256(treeLevels),
            "IncrementalQuinTree: tree is full"
        );

        uint256 currentIndex = nextLeafIndex;

        uint256 currentLevelHash = _leaf;

        // hash5 requires a uint256[] memory input, so we have to use temp
        uint256[LEAVES_PER_NODE] memory temp;

        // The leaf's relative position within its node
        uint256 m = currentIndex % LEAVES_PER_NODE;

        for (uint8 i = 0; i < treeLevels; i++) {
            // If the leaf is at relative index 0, zero out the level in
            // filledSubtrees
            if (m == 0) {
                for (uint8 j = 1; j < LEAVES_PER_NODE; j ++) {
                    filledSubtrees[i][j] = zeros[i];
                }
            }

            // Set the leaf in filledSubtrees
            filledSubtrees[i][m] = currentLevelHash;

            // Hash the level
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                temp[j] = filledSubtrees[i][j];
            }
            currentLevelHash = hash5(temp);

            currentIndex /= LEAVES_PER_NODE;
            m = currentIndex % LEAVES_PER_NODE;
        }

        root = currentLevelHash;

        rootHistory[root] = true;

        uint256 n = nextLeafIndex;
        nextLeafIndex += 1;

        emit LeafInsertion(_leaf, n);

        return currentIndex;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract InitialVoiceCreditProxy {
    function getVoiceCredits(address _user, bytes memory _data) virtual public view returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import { DomainObjs } from './DomainObjs.sol';
import { IncrementalQuinTree } from "./IncrementalQuinTree.sol";
import { IncrementalMerkleTree } from "./IncrementalMerkleTree.sol";
import { SignUpGatekeeper } from "./gatekeepers/SignUpGatekeeper.sol";
import { InitialVoiceCreditProxy } from './initialVoiceCreditProxy/InitialVoiceCreditProxy.sol';
import { SnarkConstants } from './SnarkConstants.sol';
import { ComputeRoot } from './ComputeRoot.sol';
import { MACIParameters } from './MACIParameters.sol';
import { VerifyTally } from './VerifyTally.sol';

interface SnarkVerifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] calldata input
    ) external view returns (bool);
}

contract MACI is DomainObjs, ComputeRoot, MACIParameters, VerifyTally {

    // A nothing-up-my-sleeve zero value
    // Should be equal to 8370432830353022751713833565135785980866757267633941821328460903436894336785
    uint256 ZERO_VALUE = uint256(keccak256(abi.encodePacked('Maci'))) % SNARK_SCALAR_FIELD;

    // Verifier Contracts
    SnarkVerifier internal batchUstVerifier;
    SnarkVerifier internal qvtVerifier;

    // The number of messages which the batch update state tree snark can
    // process per batch
    uint8 public messageBatchSize;

    // The number of state leaves to tally per batch via the vote tally snark
    uint8 public tallyBatchSize;

    // The tree that tracks the sign-up messages.
    IncrementalMerkleTree public messageTree;

    // The tree that tracks each user's public key and votes
    IncrementalMerkleTree public stateTree;

    uint256 public originalSpentVoiceCreditsCommitment = hashLeftRight(0, 0);
    uint256 public originalCurrentResultsCommitment;

    // To store the Merkle root of a tree with 5 **
    // _treeDepths.voteOptionTreeDepth leaves of value 0
    uint256 public emptyVoteOptionTreeRoot;

    // The maximum number of leaves, minus one, of meaningful vote options.
    uint256 public voteOptionsMaxLeafIndex;

    // The total sum of votes
    uint256 public totalVotes;

    // Cached results of 2 ** depth - 1 where depth is the state tree depth and
    // message tree depth
    uint256 public messageTreeMaxLeafIndex;

    // The maximum number of signups allowed
    uint256 public maxUsers;

    // The maximum number of messages allowed
    uint256 public maxMessages;

    // When the contract was deployed. We assume that the signup period starts
    // immediately upon deployment.
    uint256 public signUpTimestamp;

    // Duration of the sign-up and voting periods, in seconds. If these values
    // are set to 0, the contract will be in debug mode - that is, only the
    // coordinator may sign up and publish messages. This makes it possible to
    // submit a large number of signups and messages without having to do so
    // before the signup and voting deadlines.
    uint256 public signUpDurationSeconds;
    uint256 public votingDurationSeconds;

    // Address of the SignUpGatekeeper, a contract which determines whether a
    // user may sign up to vote
    SignUpGatekeeper public signUpGatekeeper;

    // The contract which provides the values of the initial voice credit
    // balance per user
    InitialVoiceCreditProxy public initialVoiceCreditProxy;

    // The coordinator's public key
    PubKey public coordinatorPubKey;

    uint256 public numSignUps = 0;
    uint256 public numMessages = 0;

    TreeDepths public treeDepths;

    bool public hasUnprocessedMessages = true;

    address public coordinatorAddress;

    //----------------------
    // Storage variables that can be reset by coordinatorReset()

    // The Merkle root of the state tree after each signup. Note that
    // batchProcessMessage() will not update the state tree. Rather, it will
    // directly update stateRoot if given a valid proof and public signals.
    uint256 public stateRoot;
    uint256 public stateRootBeforeProcessing;

    // The current message batch index
    uint256 public currentMessageBatchIndex;

    // The batch # for proveVoteTallyBatch
    uint256 public currentQvtBatchNum;

    // To store hashLeftRight(Merkle root of 5 ** voteOptionTreeDepth zeros, 0)
    uint256 public currentResultsCommitment;

    // To store hashLeftRight(0, 0). We precompute it here to save gas.
    uint256 public currentSpentVoiceCreditsCommitment;

    // To store hashLeftRight(Merkle root of 5 ** voteOptionTreeDepth zeros, 0)
    uint256 public currentPerVOSpentVoiceCreditsCommitment;
    //----------------------


    string constant ERROR_PUBLIC_SIGNAL_TOO_LARGE = "E01";
    string constant ERROR_INVALID_BATCH_UST_PROOF = "E02";
    string constant ERROR_INVALID_TALLY_PROOF = "E03";
    string constant ERROR_ONLY_COORDINATOR = "E04";
    string constant ERROR_ALL_BATCHES_TALLIED = "E05";
    string constant ERROR_CURRENT_MESSAGE_BATCH_OUT_OF_RANGE = "E06";
    string constant ERROR_NO_SIGNUPS = "E07";
    string constant ERROR_INVALID_ECDH_PUBKEYS_LENGTH = "E08";
    string constant ERROR_NO_MORE_MESSAGES = "E09";
    string constant ERROR_INVALID_MAX_USERS_OR_MESSAGES = "E10";
    string constant ERROR_SIGNUP_PERIOD_PASSED = "E11";
    string constant ERROR_SIGNUP_PERIOD_NOT_OVER = "E12";
    string constant ERROR_VOTING_PERIOD_PASSED = "E13";
    string constant ERROR_VOTING_PERIOD_NOT_OVER = "E14";

    // Events
    event SignUp(
        PubKey _userPubKey,
        uint256 _stateIndex,
        uint256 _voiceCreditBalance
    );

    event PublishMessage(
        Message _message,
        PubKey _encPubKey
    );

    constructor(
        TreeDepths memory _treeDepths,
        BatchSizes memory _batchSizes,
        MaxValues memory _maxValues,
        SignUpGatekeeper _signUpGatekeeper,
        SnarkVerifier _batchUstVerifier,
        SnarkVerifier _qvtVerifier,
        uint256 _signUpDurationSeconds,
        uint256 _votingDurationSeconds,
        InitialVoiceCreditProxy _initialVoiceCreditProxy,
        PubKey memory _coordinatorPubKey,
        address _coordinatorAddress
    ) public {
        coordinatorAddress = _coordinatorAddress;

        treeDepths = _treeDepths;

        tallyBatchSize = _batchSizes.tallyBatchSize;
        messageBatchSize = _batchSizes.messageBatchSize;

        // Set the verifier contracts
        batchUstVerifier = _batchUstVerifier;
        qvtVerifier = _qvtVerifier;

        // Set the sign-up duration
        signUpTimestamp = block.timestamp;
        signUpDurationSeconds = _signUpDurationSeconds;
        votingDurationSeconds = _votingDurationSeconds;
        
        // Set the sign-up gatekeeper contract
        signUpGatekeeper = _signUpGatekeeper;
        
        // Set the initial voice credit balance proxy
        initialVoiceCreditProxy = _initialVoiceCreditProxy;

        // Set the coordinator's public key
        coordinatorPubKey = _coordinatorPubKey;

        // Calculate and cache the max number of leaves for each tree.
        // They are used as public inputs to the batch update state tree snark.
        messageTreeMaxLeafIndex = uint256(2) ** _treeDepths.messageTreeDepth - 1;

        // Check and store the maximum number of signups
        // It is the user's responsibility to ensure that the state tree depth
        // is just large enough and not more, or they will waste gas.
        uint256 stateTreeMaxLeafIndex = uint256(2) ** _treeDepths.stateTreeDepth - 1;
        maxUsers = _maxValues.maxUsers;

        // The maximum number of messages
        require(
            _maxValues.maxUsers <= stateTreeMaxLeafIndex ||
            _maxValues.maxMessages <= messageTreeMaxLeafIndex,
            ERROR_INVALID_MAX_USERS_OR_MESSAGES
        );
        maxMessages = _maxValues.maxMessages;

        // The maximum number of leaves, minus one, of meaningful vote options.
        // This allows the snark to do a no-op if the user votes for an option
        // which has no meaning attached to it
        voteOptionsMaxLeafIndex = _maxValues.maxVoteOptions;

        // Create the message tree
        messageTree = new IncrementalMerkleTree(_treeDepths.messageTreeDepth, ZERO_VALUE, true);

        // Calculate and store the empty vote option tree root. This value must
        // be set before we call hashedBlankStateLeaf() later
        emptyVoteOptionTreeRoot = calcEmptyVoteOptionTreeRoot(_treeDepths.voteOptionTreeDepth);

        // Calculate and store a commitment to 5 ** voteOptionTreeDepth zeros,
        // and a salt of 0.
        originalCurrentResultsCommitment = hashLeftRight(emptyVoteOptionTreeRoot, 0);

        currentResultsCommitment = originalCurrentResultsCommitment;

        currentSpentVoiceCreditsCommitment = originalSpentVoiceCreditsCommitment;
        currentPerVOSpentVoiceCreditsCommitment = originalCurrentResultsCommitment;

        // Compute the hash of a blank state leaf
        uint256 h = hashedBlankStateLeaf();

        // Create the state tree
        stateTree = new IncrementalMerkleTree(_treeDepths.stateTreeDepth, h, false);

        // Make subsequent insertions start from leaf #1, as leaf #0 is only
        // updated with random data if a command is invalid.
        stateTree.insertLeaf(h);
    }

    /*
     * Returns the deadline to sign up.
     */
    function calcSignUpDeadline() public view returns (uint256) {
        return signUpTimestamp + signUpDurationSeconds;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is before the sign-up deadline.
     */
    modifier isBeforeSignUpDeadline() {
        if (signUpDurationSeconds != 0) {
            require(block.timestamp < calcSignUpDeadline(), ERROR_SIGNUP_PERIOD_PASSED);
        }
        _;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is after or equal to the sign-up deadline.
     */
    modifier isAfterSignUpDeadline() {
        if (signUpDurationSeconds != 0) {
            require(block.timestamp >= calcSignUpDeadline(), ERROR_SIGNUP_PERIOD_NOT_OVER);
        }
        _;
    }

    /*
     * Returns the deadline to vote
     */
    function calcVotingDeadline() public view returns (uint256) {
        return calcSignUpDeadline() + votingDurationSeconds;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is before the voting deadline.
     */
    modifier isBeforeVotingDeadline() {
        if (votingDurationSeconds != 0) {
            require(block.timestamp < calcVotingDeadline(), ERROR_VOTING_PERIOD_PASSED);
        }
        _;
    }

    /*
     * Ensures that the calling function only continues execution if the
     * current block time is after or equal to the voting deadline.
     */
    modifier isAfterVotingDeadline() {
        if (votingDurationSeconds != 0) {
            require(block.timestamp >= calcVotingDeadline(), ERROR_VOTING_PERIOD_NOT_OVER);
        }
        _;
    }

    /*
     * Allows a user who is eligible to sign up to do so. The sign-up
     * gatekeeper will prevent double sign-ups or ineligible users from signing
     * up. This function will only succeed if the sign-up deadline has not
     * passed. It also inserts a fresh state leaf into the state tree.
     * @param _userPubKey The user's desired public key.
     * @param _signUpGatekeeperData Data to pass to the sign-up gatekeeper's
     *     register() function. For instance, the POAPGatekeeper or
     *     SignUpTokenGatekeeper requires this value to be the ABI-encoded
     *     token ID.
     */
    function signUp(
        PubKey memory _userPubKey,
        bytes memory _signUpGatekeeperData,
        bytes memory _initialVoiceCreditProxyData
    ) 
    isBeforeSignUpDeadline
    public {

        if (signUpDurationSeconds == 0) {
            require(
                msg.sender == coordinatorAddress,
                "MACI: only the coordinator can submit signups in debug mode"
            );
        }

        require(numSignUps < maxUsers, "MACI: maximum number of signups reached");

        // Register the user via the sign-up gatekeeper. This function should
        // throw if the user has already registered or if ineligible to do so.
        signUpGatekeeper.register(msg.sender, _signUpGatekeeperData);

        uint256 voiceCreditBalance = initialVoiceCreditProxy.getVoiceCredits(
            msg.sender,
            _initialVoiceCreditProxyData
        );

        // The limit on voice credits is 2 ^ 32 which is hardcoded into the
        // UpdateStateTree circuit, specifically at check that there are
        // sufficient voice credits (using GreaterEqThan(32)).
        require(voiceCreditBalance <= 4294967296, "MACI: too many voice credits");

        // Create, hash, and insert a fresh state leaf
        StateLeaf memory stateLeaf = StateLeaf({
            pubKey: _userPubKey,
            voteOptionTreeRoot: emptyVoteOptionTreeRoot,
            voiceCreditBalance: voiceCreditBalance,
            nonce: 0
        });

        uint256 hashedLeaf = hashStateLeaf(stateLeaf);

        // Insert the leaf
        stateTree.insertLeaf(hashedLeaf);

        // Update a copy of the state tree root
        stateRoot = getStateTreeRoot();

        numSignUps ++;

        // numSignUps is equal to the state index of the leaf which was just
        // added to the state tree above
        emit SignUp(_userPubKey, numSignUps, voiceCreditBalance);
    }

    /*
     * Allows anyone to publish a message (an encrypted command and signature).
     * This function also inserts it into the message tree.
     * @param _message The message to publish
     * @param _encPubKey An epheremal public key which can be combined with the
     *     coordinator's private key to generate an ECDH shared key which which was
     *     used to encrypt the message.
     */
    function publishMessage(
        Message memory _message,
        PubKey memory _encPubKey
    ) 
    isBeforeVotingDeadline
    public {
        if (signUpDurationSeconds == 0) {
            require(
                msg.sender == coordinatorAddress,
                "MACI: only the coordinator can publish messages in debug mode"
            );
        }

        require(numMessages < maxMessages, "MACI: message limit reached");

        // Calculate leaf value
        uint256 leaf = hashMessage(_message);

        // Insert the new leaf into the message tree
        messageTree.insertLeaf(leaf);

        currentMessageBatchIndex = (numMessages / messageBatchSize) * messageBatchSize;

        numMessages ++;

        emit PublishMessage(_message, _encPubKey);
    }

    /*
     * A helper function to convert an array of 8 uint256 values into the a, b,
     * and c array values that the zk-SNARK verifier's verifyProof accepts.
     */
    function unpackProof(
        uint256[8] memory _proof
    ) public pure returns (
        uint256[2] memory,
        uint256[2][2] memory,
        uint256[2] memory
    ) {

        return (
            [_proof[0], _proof[1]],
            [
                [_proof[2], _proof[3]],
                [_proof[4], _proof[5]]
            ],
            [_proof[6], _proof[7]]
        );
    }

    /*
     * A helper function to create the publicSignals array from meaningful
     * parameters.
     * @param _newStateRoot The new state root after all messages are processed
     * @param _ecdhPubKeys The public key used to generated the ECDH shared key
     *                     to decrypt the message
     */
    function genBatchUstPublicSignals(
        uint256 _newStateRoot,
        PubKey[] memory _ecdhPubKeys
    ) public view returns (uint256[] memory) {

        uint256 messageBatchEndIndex;
        if (currentMessageBatchIndex + messageBatchSize <= numMessages) {
            messageBatchEndIndex = currentMessageBatchIndex + messageBatchSize - 1;
        } else {
            messageBatchEndIndex = numMessages - 1;
        }

        uint256[] memory publicSignals = new uint256[](12 + messageBatchSize * 3);

        publicSignals[0] = _newStateRoot;
        publicSignals[1] = coordinatorPubKey.x;
        publicSignals[2] = coordinatorPubKey.y;
        publicSignals[3] = voteOptionsMaxLeafIndex;
        publicSignals[4] = messageTree.root();
        publicSignals[5] = currentMessageBatchIndex;
        publicSignals[6] = messageBatchEndIndex;
        publicSignals[7] = numSignUps;


        for (uint8 i = 0; i < messageBatchSize; i++) {
            uint8 x = 8 + i * 2;
            uint8 y = x + 1;
            publicSignals[x] = _ecdhPubKeys[i].x;
            publicSignals[y] = _ecdhPubKeys[i].y;
        }

        return publicSignals;
    }

    /*
     * Update the stateRoot if the batch update state root proof is
     * valid.
     * @param _newStateRoot The new state root after all messages are processed
     * @param _ecdhPubKeys The public key used to generated the ECDH shared key
     *                     to decrypt the message
     * @param _proof The zk-SNARK proof
     */
    function batchProcessMessage(
        uint256 _newStateRoot,
        PubKey[] memory _ecdhPubKeys,
        uint256[8] memory _proof
    ) 
    isAfterVotingDeadline
    public {
        // Ensure that the current batch index is within range
        require(
            hasUnprocessedMessages,
            ERROR_NO_MORE_MESSAGES
        );
        
        require(
            _ecdhPubKeys.length == messageBatchSize,
            ERROR_INVALID_ECDH_PUBKEYS_LENGTH
        );

        // Ensure that currentMessageBatchIndex is within range
        require(
            currentMessageBatchIndex <= messageTreeMaxLeafIndex,
            ERROR_CURRENT_MESSAGE_BATCH_OUT_OF_RANGE
        );

        // Assemble the public inputs to the snark
        uint256[] memory publicSignals = genBatchUstPublicSignals(
            _newStateRoot,
            _ecdhPubKeys
        );

        // Ensure that each public input is within range of the snark scalar
        // field.
        // TODO: consider having more granular revert reasons
        // TODO: this check is already performed in the verifier contract
        for (uint8 i = 0; i < publicSignals.length; i++) {
            require(
                publicSignals[i] < SNARK_SCALAR_FIELD,
                ERROR_PUBLIC_SIGNAL_TOO_LARGE
            );
        }

        // Unpack the snark proof
        (
            uint256[2] memory a,
            uint256[2][2] memory b,
            uint256[2] memory c
        ) = unpackProof(_proof);

        // Verify the proof
        require(
            batchUstVerifier.verifyProof(a, b, c, publicSignals),
            ERROR_INVALID_BATCH_UST_PROOF
        );

        // Increase the message batch start index to ensure that each message
        // batch is processed in order
        if (currentMessageBatchIndex == 0) {
            hasUnprocessedMessages = false;
        } else {
            currentMessageBatchIndex -= messageBatchSize;
        }

        // Update the state root
        stateRoot = _newStateRoot;
        if (stateRootBeforeProcessing == 0) {
            stateRootBeforeProcessing = stateRoot;
        }
    }

    /*
     * Returns the public signals required to verify a quadratic vote tally
     * snark.
     */
    function genQvtPublicSignals(
        uint256 _intermediateStateRoot,
        uint256 _newResultsCommitment,
        uint256 _newSpentVoiceCreditsCommitment,
        uint256 _newPerVOSpentVoiceCreditsCommitment,
        uint256 _totalVotes
    ) public view returns (uint256[] memory) {

        uint256[] memory publicSignals = new uint256[](10);

        publicSignals[0] = _newResultsCommitment;
        publicSignals[1] = _newSpentVoiceCreditsCommitment;
        publicSignals[2] = _newPerVOSpentVoiceCreditsCommitment;
        publicSignals[3] = _totalVotes;
        publicSignals[4] = stateRoot;
        publicSignals[5] = currentQvtBatchNum;
        publicSignals[6] = _intermediateStateRoot;
        publicSignals[7] = currentResultsCommitment;
        publicSignals[8] = currentSpentVoiceCreditsCommitment;
        publicSignals[9] = currentPerVOSpentVoiceCreditsCommitment;

        return publicSignals;
    }
    
    function hashedBlankStateLeaf() public view returns (uint256) {
        // The pubkey is the first Pedersen base point from iden3's circomlib
        StateLeaf memory stateLeaf = StateLeaf({
            pubKey: PubKey({
                x: 10457101036533406547632367118273992217979173478358440826365724437999023779287,
                y: 19824078218392094440610104313265183977899662750282163392862422243483260492317
            }),
            voteOptionTreeRoot: emptyVoteOptionTreeRoot,
            voiceCreditBalance: 0,
            nonce: 0
        });

        return hashStateLeaf(stateLeaf);
    }

    function hasUntalliedStateLeaves() public view returns (bool) {
        return currentQvtBatchNum < (1 + (numSignUps / tallyBatchSize));
    }

    /*
     * Tally the next batch of state leaves.
     * @param _intermediateStateRoot The intermediate state root, which is
     *     generated from the current batch of state leaves 
     * @param _newResultsCommitment A hash of the tallied results so far
     *     (cumulative)
     * @param _proof The zk-SNARK proof
     */
    function proveVoteTallyBatch(
        uint256 _intermediateStateRoot,
        uint256 _newResultsCommitment,
        uint256 _newSpentVoiceCreditsCommitment,
        uint256 _newPerVOSpentVoiceCreditsCommitment,
        uint256 _totalVotes,
        uint256[8] memory _proof
    ) 
    public {

        require(numSignUps > 0, ERROR_NO_SIGNUPS);
        uint256 totalBatches = 1 + (numSignUps / tallyBatchSize);

        // Ensure that the batch # is within range
        require(
            currentQvtBatchNum < totalBatches,
            ERROR_ALL_BATCHES_TALLIED
        );

        // Generate the public signals
        // public 'input' signals = [output signals, public inputs]
        uint256[] memory publicSignals = genQvtPublicSignals(
            _intermediateStateRoot,
            _newResultsCommitment,
            _newSpentVoiceCreditsCommitment,
            _newPerVOSpentVoiceCreditsCommitment,
            _totalVotes
        );

        // Ensure that each public input is within range of the snark scalar
        // field.
        // TODO: consider having more granular revert reasons
        for (uint8 i = 0; i < publicSignals.length; i++) {
            require(
                publicSignals[i] < SNARK_SCALAR_FIELD,
                ERROR_PUBLIC_SIGNAL_TOO_LARGE
            );
        }

        // Unpack the snark proof
        (
            uint256[2] memory a,
            uint256[2][2] memory b,
            uint256[2] memory c
        ) = unpackProof(_proof);

        // Verify the proof
        bool isValid = qvtVerifier.verifyProof(a, b, c, publicSignals);

        require(isValid == true, ERROR_INVALID_TALLY_PROOF);

        // Save the commitment to the new results for the next batch
        currentResultsCommitment = _newResultsCommitment;

        // Save the commitment to the total spent voice credits for the next batch
        currentSpentVoiceCreditsCommitment = _newSpentVoiceCreditsCommitment;

        // Save the commitment to the per voice credit spent voice credits for the next batch
        currentPerVOSpentVoiceCreditsCommitment = _newPerVOSpentVoiceCreditsCommitment;

        // Save the total votes
        totalVotes = _totalVotes;

        // Increment the batch #
        currentQvtBatchNum ++;
    }

    /*
     * Reset the storage variables which change during message processing and
     * vote tallying. Does not affect any signups or messages. This is useful
     * if the client-side process/tally code has a bug that causes an invalid
     * state transition.
     */
    function coordinatorReset() public {
        require(msg.sender == coordinatorAddress, ERROR_ONLY_COORDINATOR);

        hasUnprocessedMessages = true;
        stateRoot = stateRootBeforeProcessing;
        if (numMessages % messageBatchSize == 0) {
            currentMessageBatchIndex = numMessages - messageBatchSize;
        } else {
            currentMessageBatchIndex = (numMessages / messageBatchSize) * messageBatchSize;
        }
        currentQvtBatchNum = 0;

        currentResultsCommitment = originalCurrentResultsCommitment;
        currentSpentVoiceCreditsCommitment = originalSpentVoiceCreditsCommitment;
        currentPerVOSpentVoiceCreditsCommitment = originalCurrentResultsCommitment;

        totalVotes = 0;
    }

    /*
     * Verify the result of the vote tally using a Merkle proof and the salt.
     */
    function verifyTallyResult(
        uint8 _depth,
        uint256 _index,
        uint256 _leaf,
        uint256[][] memory _pathElements,
        uint256 _salt
    ) public view returns (bool) {
        uint256 computedRoot = computeMerkleRootFromPath(
            _depth,
            _index,
            _leaf,
            _pathElements
        );

        uint256 computedCommitment = hashLeftRight(computedRoot, _salt);
        return computedCommitment == currentResultsCommitment;
    }

    /*
     * Verify the number of voice credits spent for a particular vote option
     * using a Merkle proof and the salt.
     */
    function verifyPerVOSpentVoiceCredits(
        uint8 _depth,
        uint256 _index,
        uint256 _leaf,
        uint256[][] memory _pathElements,
        uint256 _salt
    ) public view returns (bool) {
        uint256 computedRoot = computeMerkleRootFromPath(
            _depth,
            _index,
            _leaf,
            _pathElements
        );

        uint256 computedCommitment = hashLeftRight(computedRoot, _salt);
        return computedCommitment == currentPerVOSpentVoiceCreditsCommitment;
    }

    /*
     * Verify the total number of spent voice credits.
     * @param _spent The value to verify
     * @param _salt The salt which is hashed with the value to generate the
     *              commitment to the spent voice credits.
     */
    function verifySpentVoiceCredits(
        uint256 _spent,
        uint256 _salt
    ) public view returns (bool) {
        uint256 computedCommitment = hashLeftRight(_spent, _salt);
        return computedCommitment == currentSpentVoiceCreditsCommitment;
    }

    function calcEmptyVoteOptionTreeRoot(uint8 _levels) public pure returns (uint256) {
        return computeEmptyQuinRoot(_levels, 0);
    }

    function getMessageTreeRoot() public view returns (uint256) {
        return messageTree.root();
    }

    function getStateTreeRoot() public view returns (uint256) {
        return stateTree.root();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract MACIParameters {
    // This structs help to reduce the number of parameters to the constructor
    // and avoid a stack overflow error during compilation
    struct TreeDepths {
        uint8 stateTreeDepth;
        uint8 messageTreeDepth;
        uint8 voteOptionTreeDepth;
    }

    struct BatchSizes {
        uint8 tallyBatchSize;
        uint8 messageBatchSize;
    }

    struct MaxValues {
        uint256 maxUsers;
        uint256 maxMessages;
        uint256 maxVoteOptions;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract MACISharedObjs {
    uint8 constant MESSAGE_DATA_LENGTH = 10;
    struct Message {
        uint256 iv;
        uint256[MESSAGE_DATA_LENGTH] data;
    }

    struct PubKey {
        uint256 x;
        uint256 y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract MerkleZeros {
    uint256[33] internal zeros;

    // Binary tree zeros (Keccack hash of 'Maci')
    function populateZeros() internal {
        zeros[0] = uint256(8370432830353022751713833565135785980866757267633941821328460903436894336785);
        zeros[1] = uint256(13883108378505681706501741077199723943829197421795883447299356576923144768890);
        zeros[2] = uint256(15419121528227002346615807695865368688447806543310218580451656713665933966440);
        zeros[3] = uint256(6318262337906428951291657677634338300639543013249211096760913778778957055324);
        zeros[4] = uint256(17768974272065709481357540291486641669761745417382244600494648537227290564775);
        zeros[5] = uint256(1030673773521289386438564854581137730704523062376261329171486101180288653537);
        zeros[6] = uint256(2456832313683926177308273721786391957119973242153180895324076357329047000368);
        zeros[7] = uint256(8719489529991410281576768848178751308798998844697260960510058606396118487868);
        zeros[8] = uint256(1562826620410077272445821684229580081819470607145780146992088471567204924361);
        zeros[9] = uint256(2594027261737512958249111386518678417918764295906952540494120924791242533396);
        zeros[10] = uint256(7454652670930646290900416353463196053308124896106736687630886047764171239135);
        zeros[11] = uint256(5636576387316613237724264020484439958003062686927585603917058282562092206685);
        zeros[12] = uint256(6668187911340361678685285736007075111202281125695563765600491898900267193410);
        zeros[13] = uint256(11734657993452490720698582048616543923742816272311967755126326688155661525563);
        zeros[14] = uint256(13463263143201754346725031241082259239721783038365287587742190796879610964010);
        zeros[15] = uint256(7428603293293611296009716236093531014060986236553797730743998024965500409844);
        zeros[16] = uint256(3220236805148173410173179641641444848417275827082321553459407052920864882112);
        zeros[17] = uint256(5702296734156546101402281555025360809782656712426280862196339683480526959100);
        zeros[18] = uint256(18054517726590450486276822815339944904333304893252063892146748222745553261079);
        zeros[19] = uint256(15845875411090302918698896692858436856780638250734551924718281082237259235021);
        zeros[20] = uint256(15856603049544947491266127020967880429380981635456797667765381929897773527801);
        zeros[21] = uint256(16947753390809968528626765677597268982507786090032633631001054889144749318212);
        zeros[22] = uint256(4409871880435963944009375001829093050579733540305802511310772748245088379588);
        zeros[23] = uint256(3999924973235726549616800282209401324088787314476870617570702819461808743202);
        zeros[24] = uint256(5910085476731597359542102744346894725393370185329725031545263392891885548800);
        zeros[25] = uint256(8329789525184689042321668445575725185257025982565085347238469712583602374435);
        zeros[26] = uint256(21731745958669991600655184668442493750937309130671773804712887133863507145115);
        zeros[27] = uint256(13908786229946466860099145463206281117295829828306413881947857340025780878375);
        zeros[28] = uint256(2746378384965515118858350021060497341885459652705230422460541446030288889144);
        zeros[29] = uint256(4024247518003740702537513711866227003187955635058512298109553363285388770811);
        zeros[30] = uint256(13465368596069181921705381841358161201578991047593533252870698635661853557810);
        zeros[31] = uint256(1901585547727445451328488557530824986692473576054582208711800336656801352314);
        zeros[32] = uint256(3444131905730490180878137209421656122704458854785641062326389124060978485990);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library PoseidonT3 {
    function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}


library PoseidonT6 {
    function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT

/*
 * Semaphore - Zero-knowledge signaling on Ethereum
 * Copyright (C) 2020 Barry WhiteHat <[email protected]>, Kobi
 * Gurkan <[email protected]> and Koh Wei Jie ([email protected])
 *
 * This file is part of Semaphore.
 *
 * Semaphore is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Semaphore is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Semaphore.  If not, see <http://www.gnu.org/licenses/>.
 */

pragma solidity ^0.6.12;

contract SnarkConstants {
    // The scalar field
    uint256 internal constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import { Hasher } from "./Hasher.sol";

contract VerifyTally is Hasher {

    uint8 private constant LEAVES_PER_NODE = 5;

    function computeMerkleRootFromPath(
        uint8 _depth,
        uint256 _index,
        uint256 _leaf,
        uint256[][] memory _pathElements
    ) public pure returns (uint256) {
        uint256 pos = _index % LEAVES_PER_NODE;
        uint256 current = _leaf;
        uint8 k;

        uint256[LEAVES_PER_NODE] memory level;

        for (uint8 i = 0; i < _depth; i ++) {
            for (uint8 j = 0; j < LEAVES_PER_NODE; j ++) {
                if (j == pos) {
                    level[j] = current;
                } else {
                    if (j > pos) {
                        k = j - 1;
                    } else {
                        k = j;
                    }
                    level[j] = _pathElements[i][k];
                }
            }

            _index /= LEAVES_PER_NODE;
            pos = _index % LEAVES_PER_NODE;
            current = hash5(level);
        }

        return current;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity >=0.5.10 <0.9.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param the RLP item.
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
     * @param the RLP item containing the encoded list.
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(uint256 src, uint256 dest, uint256 len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}