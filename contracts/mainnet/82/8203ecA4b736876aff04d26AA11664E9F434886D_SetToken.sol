// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
     * Requirements:
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
     * Requirements:
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
    function _setupDecimals(uint8 decimals_) internal virtual {
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

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {ISetToken} from "./ISetToken.sol";

interface IBasicIssuanceModule {
    function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    ) external returns (address[] memory, uint256[] memory);

    function redeem(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

interface IController {
    function addSet(address _setToken) external;

    function feeRecipient() external view returns (address);

    function getModuleFee(
        address _module,
        uint256 _feeType
    ) external view returns (uint256);

    function isModule(address _module) external view returns (bool);

    function isSet(address _setToken) external view returns (bool);

    function isSystemContract(
        address _contractAddress
    ) external view returns (bool);

    function resourceId(uint256 _id) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

interface IIntegrationRegistry {
    function addIntegration(
        address _module,
        string memory _id,
        address _wrapper
    ) external;

    function getIntegrationAdapter(
        address _module,
        string memory _id
    ) external view returns (address);

    function getIntegrationAdapterWithHash(
        address _module,
        bytes32 _id
    ) external view returns (address);

    function isValidIntegration(
        address _module,
        string memory _id
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {ISetToken} from "./ISetToken.sol";

interface IManagerIssuanceHook {
    function invokePreIssueHook(
        ISetToken _setToken,
        uint256 _issueQuantity,
        address _sender,
        address _to
    ) external;

    function invokePreRedeemHook(
        ISetToken _setToken,
        uint256 _redeemQuantity,
        address _sender,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @title IModule
 * @author Set Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a SetToken to notify that this module was removed from the Set token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @title IOracle
 * @author Set Protocol
 *
 * Interface for operating with any external Oracle that returns uint256 or
 * an adapting contract that converts oracle output to uint256
 */
interface IOracle {
    /**
     * @return  Current price of asset represented in uint256, typically a preciseUnit where 10^18 = 1.
     */
    function read() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @title IOracleAdapter
 * @author Set Protocol
 *
 * Interface for calling an oracle adapter.
 */
interface IOracleAdapter {
    /**
     * Function for retrieving a price that requires sourcing data from outside protocols to calculate.
     *
     * @param  _assetOne    First asset in pair
     * @param  _assetTwo    Second asset in pair
     * @return                  Boolean indicating if oracle exists
     * @return              Current price of asset represented in uint256
     */
    function getPrice(
        address _assetOne,
        address _assetTwo
    ) external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    /* ============ Functions ============ */

    function getPrice(
        address _assetOne,
        address _assetTwo
    ) external view returns (uint256);

    function masterQuoteAsset() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {
    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /* ============ Functions ============ */

    function addComponent(address _component) external;

    function removeComponent(address _component) external;

    function editDefaultPositionUnit(
        address _component,
        int256 _realUnit
    ) external;

    function addExternalPositionModule(
        address _component,
        address _positionModule
    ) external;

    function removeExternalPositionModule(
        address _component,
        address _positionModule
    ) external;

    function editExternalPositionUnit(
        address _component,
        address _positionModule,
        int256 _realUnit
    ) external;

    function editExternalPositionData(
        address _component,
        address _positionModule,
        bytes calldata _data
    ) external;

    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;

    function burn(address _account, uint256 _quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address _module) external;

    function removeModule(address _module) external;

    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);

    function moduleStates(address _module) external view returns (ModuleState);

    function getModules() external view returns (address[] memory);

    function getDefaultPositionRealUnit(
        address _component
    ) external view returns (int256);

    function getExternalPositionRealUnit(
        address _component,
        address _positionModule
    ) external view returns (int256);

    function getComponents() external view returns (address[] memory);

    function getExternalPositionModules(
        address _component
    ) external view returns (address[] memory);

    function getExternalPositionData(
        address _component,
        address _positionModule
    ) external view returns (bytes memory);

    function isExternalPositionModule(
        address _component,
        address _module
    ) external view returns (bool);

    function isComponent(address _component) external view returns (bool);

    function positionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(
        address _component
    ) external view returns (int256);

    function isInitializedModule(address _module) external view returns (bool);

    function isPendingModule(address _module) external view returns (bool);

    function isLocked() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {ISetToken} from "../interfaces/ISetToken.sol";

interface ISetValuer {
    function calculateSetTokenValuation(
        ISetToken _setToken,
        address _quoteAsset
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/21/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {
    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(
        address[] memory A,
        address a
    ) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
     * Returns true if the value is present in the list. Uses indexOf internally.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns isIn for the first occurrence starting from index 0
     */
    function contains(
        address[] memory A,
        address a
    ) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Returns true if there are 2 elements that are the same in an array
     * @param A The input array to search
     * @return Returns boolean for the first occurrence of a duplicate
     */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(
        address[] memory A,
        address a
    ) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A, ) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a) internal {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) {
                A[index] = A[lastIndex];
            }
            A.pop();
        }
    }

    /**
     * Removes specified index from array
     * @param A The input array to search
     * @param index The index to remove
     * @return Returns the new array and the removed entry
     */
    function pop(
        address[] memory A,
        uint256 index
    ) internal pure returns (address[] memory, address) {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(
        address[] memory A,
        address[] memory B
    ) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(
        address[] memory A,
        uint[] memory B
    ) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(
        address[] memory A,
        bool[] memory B
    ) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(
        address[] memory A,
        string[] memory B
    ) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(
        address[] memory A,
        address[] memory B
    ) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(
        address[] memory A,
        bytes[] memory B
    ) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::leastSignificantBit: zero");

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
    using SafeMath for uint256;

    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    ) internal {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(_token, _from, _to, _quantity);

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 * - 12/13/21: Added preciseDivCeil (int overloads) function
 * - 12/13/21: Added abs function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;

    // The number One in precise units.
    uint256 internal constant PRECISE_UNIT = 10 ** 18;
    int256 internal constant PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
     * returned. When `b` is 0, method reverts with divide-by-zero error.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");

        a = a.mul(PRECISE_UNIT_INT);
        int256 c = a.div(b);

        if (a % b != 0) {
            // a ^ b == 0 case is covered by the previous if statement, hence it won't resolve to --c
            (a ^ b > 0) ? ++c : --c;
        }

        return c;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(
        int256 a,
        int256 b
    ) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(
        int256 a,
        int256 b
    ) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
     * @dev Performs the power on a specified value, reverts on overflow.
     */
    function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++) {
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(
        uint256 a,
        uint256 b,
        uint256 range
    ) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }

    /**
     * Returns the absolute value of int256 `a` as a uint256
     */
    function abs(int256 a) internal pure returns (uint) {
        return a >= 0 ? a.toUint256() : a.mul(-1).toUint256();
    }

    /**
     * Returns the negation of a
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a > MIN_INT_256, "Inversion overflow");
        return -a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import "./BitMath.sol";

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(
        int24 tick
    ) private pure returns (int16 wordPos, uint256 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint256(tick % 256);
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0); // ensure that the tick is spaced
        (int16 wordPos, uint256 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint256 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed -
                    int24(bitPos - BitMath.mostSignificantBit(masked))) *
                    tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint256 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed +
                    1 +
                    int24(BitMath.leastSignificantBit(masked) - bitPos)) *
                    tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) *
                    tickSpacing;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title UnitConversionUtils
 * @author Set Protocol
 *
 * Utility functions to convert PRECISE_UNIT values to and from other decimal units
 */
library UnitConversionUtils {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * @dev Converts a uint256 PRECISE_UNIT quote quantity into an alternative decimal format.
     *
     * This method is borrowed from PerpProtocol's `lushan` repo in lib/SettlementTokenMath
     *
     * @param _amount       PRECISE_UNIT amount to convert from
     * @param _decimals     Decimal precision format to convert to
     * @return              Input converted to alternative decimal precision format
     */
    function fromPreciseUnitToDecimals(
        uint256 _amount,
        uint8 _decimals
    ) internal pure returns (uint256) {
        return _amount.div(10 ** (18 - uint(_decimals)));
    }

    /**
     * @dev Converts an int256 PRECISE_UNIT quote quantity into an alternative decimal format.
     *
     * This method is borrowed from PerpProtocol's `lushan` repo in lib/SettlementTokenMath
     *
     * @param _amount       PRECISE_UNIT amount to convert from
     * @param _decimals     Decimal precision format to convert to
     * @return              Input converted to alternative decimal precision format
     */
    function fromPreciseUnitToDecimals(
        int256 _amount,
        uint8 _decimals
    ) internal pure returns (int256) {
        return _amount.div(int256(10 ** (18 - uint(_decimals))));
    }

    /**
     * @dev Converts an arbitrarily decimalized quantity into a int256 PRECISE_UNIT quantity.
     *
     * @param _amount       Non-PRECISE_UNIT amount to convert
     * @param _decimals     Decimal precision of amount being converted to PRECISE_UNIT
     * @return              Input converted to int256 PRECISE_UNIT decimal format
     */
    function toPreciseUnitsFromDecimals(
        int256 _amount,
        uint8 _decimals
    ) internal pure returns (int256) {
        return _amount.mul(int256(10 ** (18 - (uint(_decimals)))));
    }

    /**
     * @dev Converts an arbitrarily decimalized quantity into a uint256 PRECISE_UNIT quantity.
     *
     * @param _amount       Non-PRECISE_UNIT amount to convert
     * @param _decimals     Decimal precision of amount being converted to PRECISE_UNIT
     * @return              Input converted to uint256 PRECISE_UNIT decimal format
     */
    function toPreciseUnitsFromDecimals(
        uint256 _amount,
        uint8 _decimals
    ) internal pure returns (uint256) {
        return _amount.mul(10 ** (18 - (uint(_decimals))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

library ValuePosition {
    // info stored for each user's bid value
    struct Info {
        // the amount of bid owned by this position
        int256 virtualAmount;
        // bid assets or rewards be claimed, status success or failed
        bool claimed;
    }

    function get(
        mapping(bytes32 => Info) storage self,
        uint256 serialId,
        address owner,
        int24 tick
    ) internal view returns (ValuePosition.Info storage position) {
        position = self[keccak256(abi.encodePacked(serialId, owner, tick))];
    }

    function add(
        Info storage self,
        int256 virtualAmount
    ) internal returns (int256 virtualAmountAfter) {
        int256 virtualAmountBefore = self.virtualAmount;
        virtualAmountAfter = virtualAmountBefore + virtualAmount;
        self.virtualAmount = virtualAmountAfter;
    }

    function sub(
        Info storage self,
        int256 virtualAmount
    ) internal returns (int256 virtualAmountAfter) {
        int256 virtualAmountBefore = self.virtualAmount;
        virtualAmountAfter = virtualAmountBefore - virtualAmount;
        self.virtualAmount = virtualAmountAfter;
    }

    function setClaimed(Info storage self) internal {
        self.claimed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// mock class using BasicToken
contract StandardTokenMock is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    function mint() external {
        _mint(msg.sender, 1_000_000 * 10 ** uint256(decimals()));
    }

    function mintWithAmount(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";
import {AddressArrayUtils} from "../lib/AddressArrayUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {StandardTokenMock} from "./StandardTokenMock.sol";


contract TokenFaucet is Ownable {
    using AddressArrayUtils for address[];

    address[] public components;
    uint256 public amount;

    constructor() public {
        amount = 100_000;
    }

    receive() external payable {
        address payable _toPayable = payable(msg.sender);
        (bool sent, ) = _toPayable.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        _mint2Account(msg.sender);
    }

    function setAmount(uint256 _amount) external onlyOwner {
        amount = _amount;
    }

    function addComponents(address[] memory _components) external onlyOwner {
        components = components.extend(_components);
    }

    function addComponent(address _component) external onlyOwner {
        components.push(_component);
    }

    function removeComponent(address _component) external onlyOwner {
        components.removeStorage(_component);
    }

    function mint2Accounts(address[] memory _accounts) external {
        for (uint i = 0; i < _accounts.length; i++) {
            _mint2Account(_accounts[i]);
        }
    }

    function _mint2Account(address _account) internal {
        for (uint i = 0; i < components.length; i++) {
            uint256 _amount = amount * 10**uint256(StandardTokenMock(components[i]).decimals());
            StandardTokenMock(components[i]).mintWithAmount(_amount);
            StandardTokenMock(components[i]).transfer(_account, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AddressArrayUtils} from "../lib/AddressArrayUtils.sol";

/**
 * @title Controller
 * @author Set Protocol
 *
 * Contract that houses state for approvals and system contracts such as added Sets,
 * modules, factories, resources (like price oracles), and protocol fee configurations.
 */
contract Controller is Ownable {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event FactoryAdded(address indexed _factory);
    event FactoryRemoved(address indexed _factory);
    event FeeEdited(
        address indexed _module,
        uint256 indexed _feeType,
        uint256 _feePercentage
    );
    event FeeRecipientChanged(address _newFeeRecipient);
    event ModuleAdded(address indexed _module);
    event ModuleRemoved(address indexed _module);
    event ResourceAdded(address indexed _resource, uint256 _id);
    event ResourceRemoved(address indexed _resource, uint256 _id);
    event SetAdded(address indexed _setToken, address indexed _factory);
    event SetRemoved(address indexed _setToken);

    /* ============ Modifiers ============ */

    /**
     * Throws if function is called by any address other than a valid factory.
     */
    modifier onlyFactory() {
        require(isFactory[msg.sender], "Only valid factories can call");
        _;
    }

    modifier onlyInitialized() {
        require(isInitialized, "Contract must be initialized.");
        _;
    }

    /* ============ State Variables ============ */

    // List of enabled Sets
    address[] public sets;
    // List of enabled factories of SetTokens
    address[] public factories;
    // List of enabled Modules; Modules extend the functionality of SetTokens
    address[] public modules;
    // List of enabled Resources; Resources provide data, functionality, or
    // permissions that can be drawn upon from Module, SetTokens or factories
    address[] public resources;

    // Mappings to check whether address is valid Set, Factory, Module or Resource
    mapping(address => bool) public isSet;
    mapping(address => bool) public isFactory;
    mapping(address => bool) public isModule;
    mapping(address => bool) public isResource;

    // Mapping of modules to fee types to fee percentage. A module can have multiple feeTypes
    // Fee is denominated in precise unit percentages (100% = 1e18, 1% = 1e16)
    mapping(address => mapping(uint256 => uint256)) public fees;

    // Mapping of resource ID to resource address, which allows contracts to fetch the correct
    // resource while providing an ID
    mapping(uint256 => address) public resourceId;

    // Recipient of protocol fees
    address public feeRecipient;

    // Return true if the controller is initialized
    bool public isInitialized;

    /* ============ Constructor ============ */

    /**
     * Initializes the initial fee recipient on deployment.
     *
     * @param _feeRecipient          Address of the initial protocol fee recipient
     */
    constructor(address _feeRecipient) public {
        feeRecipient = _feeRecipient;
    }

    /* ============ External Functions ============ */

    /**
     * Initializes any predeployed factories, modules, and resources post deployment. Note: This function can
     * only be called by the owner once to batch initialize the initial system contracts.
     *
     * @param _factories             List of factories to add
     * @param _modules               List of modules to add
     * @param _resources             List of resources to add
     * @param _resourceIds           List of resource IDs associated with the resources
     */
    function initialize(
        address[] memory _factories,
        address[] memory _modules,
        address[] memory _resources,
        uint256[] memory _resourceIds
    ) external onlyOwner {
        require(!isInitialized, "Controller is already initialized");
        require(
            _resources.length == _resourceIds.length,
            "Array lengths do not match."
        );

        factories = _factories;
        modules = _modules;
        resources = _resources;

        // Loop through and initialize isModule, isFactory, and isResource mapping
        for (uint256 i = 0; i < _factories.length; i++) {
            require(_factories[i] != address(0), "Zero address submitted.");
            isFactory[_factories[i]] = true;
        }
        for (uint256 i = 0; i < _modules.length; i++) {
            require(_modules[i] != address(0), "Zero address submitted.");
            isModule[_modules[i]] = true;
        }

        for (uint256 i = 0; i < _resources.length; i++) {
            require(_resources[i] != address(0), "Zero address submitted.");
            require(
                resourceId[_resourceIds[i]] == address(0),
                "Resource ID already exists"
            );
            isResource[_resources[i]] = true;
            resourceId[_resourceIds[i]] = _resources[i];
        }

        // Set to true to only allow initialization once
        isInitialized = true;
    }

    /**
     * PRIVILEGED FACTORY FUNCTION. Adds a newly deployed SetToken as an enabled SetToken.
     *
     * @param _setToken               Address of the SetToken contract to add
     */
    function addSet(address _setToken) external onlyInitialized onlyFactory {
        require(!isSet[_setToken], "Set already exists");

        isSet[_setToken] = true;

        sets.push(_setToken);

        emit SetAdded(_setToken, msg.sender);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a Set
     *
     * @param _setToken               Address of the SetToken contract to remove
     */
    function removeSet(address _setToken) external onlyInitialized onlyOwner {
        require(isSet[_setToken], "Set does not exist");

        sets = sets.remove(_setToken);

        isSet[_setToken] = false;

        emit SetRemoved(_setToken);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a factory
     *
     * @param _factory               Address of the factory contract to add
     */
    function addFactory(address _factory) external onlyInitialized onlyOwner {
        require(!isFactory[_factory], "Factory already exists");

        isFactory[_factory] = true;

        factories.push(_factory);

        emit FactoryAdded(_factory);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a factory
     *
     * @param _factory               Address of the factory contract to remove
     */
    function removeFactory(
        address _factory
    ) external onlyInitialized onlyOwner {
        require(isFactory[_factory], "Factory does not exist");

        factories = factories.remove(_factory);

        isFactory[_factory] = false;

        emit FactoryRemoved(_factory);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a module
     *
     * @param _module               Address of the module contract to add
     */
    function addModule(address _module) external onlyInitialized onlyOwner {
        require(!isModule[_module], "Module already exists");

        isModule[_module] = true;

        modules.push(_module);

        emit ModuleAdded(_module);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a module
     *
     * @param _module               Address of the module contract to remove
     */
    function removeModule(address _module) external onlyInitialized onlyOwner {
        require(isModule[_module], "Module does not exist");

        modules = modules.remove(_module);

        isModule[_module] = false;

        emit ModuleRemoved(_module);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a resource
     *
     * @param _resource               Address of the resource contract to add
     * @param _id                     New ID of the resource contract
     */
    function addResource(
        address _resource,
        uint256 _id
    ) external onlyInitialized onlyOwner {
        require(!isResource[_resource], "Resource already exists");

        require(resourceId[_id] == address(0), "Resource ID already exists");

        isResource[_resource] = true;

        resourceId[_id] = _resource;

        resources.push(_resource);

        emit ResourceAdded(_resource, _id);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a resource
     *
     * @param _id               ID of the resource contract to remove
     */
    function removeResource(uint256 _id) external onlyInitialized onlyOwner {
        address resourceToRemove = resourceId[_id];

        require(resourceToRemove != address(0), "Resource does not exist");

        resources = resources.remove(resourceToRemove);

        delete resourceId[_id];

        isResource[resourceToRemove] = false;

        emit ResourceRemoved(resourceToRemove, _id);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a fee to a module
     *
     * @param _module               Address of the module contract to add fee to
     * @param _feeType              Type of the fee to add in the module
     * @param _newFeePercentage     Percentage of fee to add in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function addFee(
        address _module,
        uint256 _feeType,
        uint256 _newFeePercentage
    ) external onlyInitialized onlyOwner {
        require(isModule[_module], "Module does not exist");

        require(
            fees[_module][_feeType] == 0,
            "Fee type already exists on module"
        );

        fees[_module][_feeType] = _newFeePercentage;

        emit FeeEdited(_module, _feeType, _newFeePercentage);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit a fee in an existing module
     *
     * @param _module               Address of the module contract to edit fee
     * @param _feeType              Type of the fee to edit in the module
     * @param _newFeePercentage     Percentage of fee to edit in the module (denominated in preciseUnits eg 1% = 1e16)
     */
    function editFee(
        address _module,
        uint256 _feeType,
        uint256 _newFeePercentage
    ) external onlyInitialized onlyOwner {
        require(isModule[_module], "Module does not exist");

        require(
            fees[_module][_feeType] != 0,
            "Fee type does not exist on module"
        );

        fees[_module][_feeType] = _newFeePercentage;

        emit FeeEdited(_module, _feeType, _newFeePercentage);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to edit the protocol fee recipient
     *
     * @param _newFeeRecipient      Address of the new protocol fee recipient
     */
    function editFeeRecipient(
        address _newFeeRecipient
    ) external onlyInitialized onlyOwner {
        require(_newFeeRecipient != address(0), "Address must not be 0");

        feeRecipient = _newFeeRecipient;

        emit FeeRecipientChanged(_newFeeRecipient);
    }

    /* ============ External Getter Functions ============ */

    function getModuleFee(
        address _moduleAddress,
        uint256 _feeType
    ) external view returns (uint256) {
        return fees[_moduleAddress][_feeType];
    }

    function getFactories() external view returns (address[] memory) {
        return factories;
    }

    function getModules() external view returns (address[] memory) {
        return modules;
    }

    function getResources() external view returns (address[] memory) {
        return resources;
    }

    function getSets() external view returns (address[] memory) {
        return sets;
    }

    /**
     * Check if a contract address is a module, Set, resource, factory or controller
     *
     * @param  _contractAddress           The contract address to check
     */
    function isSystemContract(
        address _contractAddress
    ) external view returns (bool) {
        return (isSet[_contractAddress] ||
            isModule[_contractAddress] ||
            isResource[_contractAddress] ||
            isFactory[_contractAddress] ||
            _contractAddress == address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import {IController} from "../interfaces/IController.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IntegrationRegistry
 * @author Set Protocol
 *
 * The IntegrationRegistry holds state relating to the Modules and the integrations they are connected with.
 * The state is combined into a single Registry to allow governance updates to be aggregated to one contract.
 */
contract IntegrationRegistry is Ownable {
    /* ============ Events ============ */

    event IntegrationAdded(
        address indexed _module,
        address indexed _adapter,
        string _integrationName
    );
    event IntegrationRemoved(
        address indexed _module,
        address indexed _adapter,
        string _integrationName
    );
    event IntegrationEdited(
        address indexed _module,
        address _newAdapter,
        string _integrationName
    );

    /* ============ State Variables ============ */

    // Address of the Controller contract
    IController public controller;

    // Mapping of module => integration identifier => adapter address
    mapping(address => mapping(bytes32 => address)) private integrations;

    /* ============ Constructor ============ */

    /**
     * Initializes the controller
     *
     * @param _controller          Instance of the controller
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ External Functions ============ */

    /**
     * GOVERNANCE FUNCTION: Add a new integration to the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     * @param  _adapter      Address of the adapter contract to add
     */
    function addIntegration(
        address _module,
        string memory _name,
        address _adapter
    ) public onlyOwner {
        bytes32 hashedName = _nameHash(_name);
        require(controller.isModule(_module), "Must be valid module.");
        require(
            integrations[_module][hashedName] == address(0),
            "Integration exists already."
        );
        require(_adapter != address(0), "Adapter address must exist.");

        integrations[_module][hashedName] = _adapter;

        emit IntegrationAdded(_module, _adapter, _name);
    }

    /**
     * GOVERNANCE FUNCTION: Batch add new adapters. Reverts if exists on any module and name
     *
     * @param  _modules      Array of addresses of the modules associated with integration
     * @param  _names        Array of human readable strings identifying the integration
     * @param  _adapters     Array of addresses of the adapter contracts to add
     */
    function batchAddIntegration(
        address[] memory _modules,
        string[] memory _names,
        address[] memory _adapters
    ) external onlyOwner {
        // Storing modules count to local variable to save on invocation
        uint256 modulesCount = _modules.length;

        require(modulesCount > 0, "Modules must not be empty");
        require(
            modulesCount == _names.length,
            "Module and name lengths mismatch"
        );
        require(
            modulesCount == _adapters.length,
            "Module and adapter lengths mismatch"
        );

        for (uint256 i = 0; i < modulesCount; i++) {
            // Add integrations to the specified module. Will revert if module and name combination exists
            addIntegration(_modules[i], _names[i], _adapters[i]);
        }
    }

    /**
     * GOVERNANCE FUNCTION: Edit an existing integration on the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     * @param  _adapter      Address of the adapter contract to edit
     */
    function editIntegration(
        address _module,
        string memory _name,
        address _adapter
    ) public onlyOwner {
        bytes32 hashedName = _nameHash(_name);

        require(controller.isModule(_module), "Must be valid module.");
        require(
            integrations[_module][hashedName] != address(0),
            "Integration does not exist."
        );
        require(_adapter != address(0), "Adapter address must exist.");

        integrations[_module][hashedName] = _adapter;

        emit IntegrationEdited(_module, _adapter, _name);
    }

    /**
     * GOVERNANCE FUNCTION: Batch edit adapters for modules. Reverts if module and
     * adapter name don't map to an adapter address
     *
     * @param  _modules      Array of addresses of the modules associated with integration
     * @param  _names        Array of human readable strings identifying the integration
     * @param  _adapters     Array of addresses of the adapter contracts to add
     */
    function batchEditIntegration(
        address[] memory _modules,
        string[] memory _names,
        address[] memory _adapters
    ) external onlyOwner {
        // Storing name count to local variable to save on invocation
        uint256 modulesCount = _modules.length;

        require(modulesCount > 0, "Modules must not be empty");
        require(
            modulesCount == _names.length,
            "Module and name lengths mismatch"
        );
        require(
            modulesCount == _adapters.length,
            "Module and adapter lengths mismatch"
        );

        for (uint256 i = 0; i < modulesCount; i++) {
            // Edits integrations to the specified module. Will revert if module and name combination does not exist
            editIntegration(_modules[i], _names[i], _adapters[i]);
        }
    }

    /**
     * GOVERNANCE FUNCTION: Remove an existing integration on the registry
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     */
    function removeIntegration(
        address _module,
        string memory _name
    ) external onlyOwner {
        bytes32 hashedName = _nameHash(_name);
        require(
            integrations[_module][hashedName] != address(0),
            "Integration does not exist."
        );

        address oldAdapter = integrations[_module][hashedName];
        delete integrations[_module][hashedName];

        emit IntegrationRemoved(_module, oldAdapter, _name);
    }

    /* ============ External Getter Functions ============ */

    /**
     * Get integration adapter address associated with passed human readable name
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable adapter name
     *
     * @return               Address of adapter
     */
    function getIntegrationAdapter(
        address _module,
        string memory _name
    ) external view returns (address) {
        return integrations[_module][_nameHash(_name)];
    }

    /**
     * Get integration adapter address associated with passed hashed name
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _nameHash     Hash of human readable adapter name
     *
     * @return               Address of adapter
     */
    function getIntegrationAdapterWithHash(
        address _module,
        bytes32 _nameHash
    ) external view returns (address) {
        return integrations[_module][_nameHash];
    }

    /**
     * Check if adapter name is valid
     *
     * @param  _module       The address of the module associated with the integration
     * @param  _name         Human readable string identifying the integration
     *
     * @return               Boolean indicating if valid
     */
    function isValidIntegration(
        address _module,
        string memory _name
    ) external view returns (bool) {
        return integrations[_module][_nameHash(_name)] != address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * Hashes the string and returns a bytes32 value
     */
    function _nameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(bytes(_name));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {ISetToken} from "../../interfaces/ISetToken.sol";

/**
 * @title Invoke
 * @author Set Protocol
 *
 * A collection of common utility functions for interacting with the SetToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the SetToken to set approvals of the ERC20 token to a spender.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the SetToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        ISetToken _setToken,
        address _token,
        address _spender,
        uint256 _quantity
    ) internal {
        bytes memory callData = abi.encodeWithSignature(
            "approve(address,uint256)",
            _spender,
            _quantity
        );
        _setToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    ) internal {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature(
                "transfer(address,uint256)",
                _to,
                _quantity
            );
            _setToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     * The new SetToken balance must equal the existing balance less the quantity transferred
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    ) internal {
        if (_quantity > 0) {
            // Retrieve current balance of token for the SetToken
            uint256 existingBalance = IERC20(_token).balanceOf(
                address(_setToken)
            );

            Invoke.invokeTransfer(_setToken, _token, _to, _quantity);

            // Get new balance of transferred token for SetToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_setToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the SetToken to unwrap the passed quantity of WETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(
        ISetToken _setToken,
        address _weth,
        uint256 _quantity
    ) internal {
        bytes memory callData = abi.encodeWithSignature(
            "withdraw(uint256)",
            _quantity
        );
        _setToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the SetToken to wrap the passed quantity of ETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(
        ISetToken _setToken,
        address _weth,
        uint256 _quantity
    ) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _setToken.invoke(_weth, _quantity, callData);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {ISetToken} from "../../interfaces/ISetToken.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title IssuanceValidationUtils
 * @author Set Protocol
 *
 * A collection of utility functions to help during issuance/redemption of SetToken.
 */
library IssuanceValidationUtils {
    using SafeMath for uint256;
    using SafeCast for int256;
    using PreciseUnitMath for uint256;

    /**
     * Validates component transfer IN to SetToken during issuance/redemption. Reverts if Set is undercollateralized post transfer.
     * NOTE: Call this function immediately after transfer IN but before calling external hooks (if any).
     *
     * @param _setToken             Instance of the SetToken being issued/redeemed
     * @param _component            Address of component being transferred in/out
     * @param _initialSetSupply     Initial SetToken supply before issuance/redemption
     * @param _componentQuantity    Amount of component transferred into SetToken
     */
    function validateCollateralizationPostTransferInPreHook(
        ISetToken _setToken,
        address _component,
        uint256 _initialSetSupply,
        uint256 _componentQuantity
    ) internal view {
        uint256 newComponentBalance = IERC20(_component).balanceOf(
            address(_setToken)
        );

        uint256 defaultPositionUnit = _setToken
            .getDefaultPositionRealUnit(address(_component))
            .toUint256();

        require(
            // Use preciseMulCeil to increase the lower bound and maintain over-collateralization
            newComponentBalance >=
                _initialSetSupply.preciseMulCeil(defaultPositionUnit).add(
                    _componentQuantity
                ),
            "Invalid transfer in. Results in undercollateralization"
        );
    }

    /**
     * Validates component transfer OUT of SetToken during issuance/redemption. Reverts if Set is undercollateralized post transfer.
     *
     * @param _setToken         Instance of the SetToken being issued/redeemed
     * @param _component        Address of component being transferred in/out
     * @param _finalSetSupply   Final SetToken supply after issuance/redemption
     */
    function validateCollateralizationPostTransferOut(
        ISetToken _setToken,
        address _component,
        uint256 _finalSetSupply
    ) internal view {
        uint256 newComponentBalance = IERC20(_component).balanceOf(
            address(_setToken)
        );

        uint256 defaultPositionUnit = _setToken
            .getDefaultPositionRealUnit(address(_component))
            .toUint256();

        require(
            // Use preciseMulCeil to increase lower bound and maintain over-collateralization
            newComponentBalance >=
                _finalSetSupply.preciseMulCeil(defaultPositionUnit),
            "Invalid transfer out. Results in undercollateralization"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AddressArrayUtils} from "../../lib/AddressArrayUtils.sol";
import {ExplicitERC20} from "../../lib/ExplicitERC20.sol";
import {IController} from "../../interfaces/IController.sol";
import {IModule} from "../../interfaces/IModule.sol";
import {ISetToken} from "../../interfaces/ISetToken.sol";
import {Invoke} from "./Invoke.sol";
import {Position} from "./Position.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";
import {ResourceIdentifier} from "./ResourceIdentifier.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Set Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for ISetToken;
    using Position for ISetToken;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidSet(ISetToken _setToken) {
        _validateOnlyManagerAndValidSet(_setToken);
        _;
    }

    modifier onlySetManager(ISetToken _setToken, address _caller) {
        _validateOnlySetManager(_setToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedSet(ISetToken _setToken) {
        _validateOnlyValidAndInitializedSet(_setToken);
        _;
    }

    /**
     * Throws if the sender is not a SetToken's module or module not enabled
     */
    modifier onlyModule(ISetToken _setToken) {
        _validateOnlyModule(_setToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the SetToken is valid
     */
    modifier onlyValidAndPendingSet(ISetToken _setToken) {
        _validateOnlyValidAndPendingSet(_setToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    ) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(
        string memory _integrationName
    ) internal view returns (address) {
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(
        bytes32 _integrationHash
    ) internal view returns (address) {
        address adapter = controller
            .getIntegrationRegistry()
            .getIntegrationAdapterWithHash(address(this), _integrationHash);

        require(adapter != address(0), "Must be valid adapter");
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(
        uint256 _feeIndex,
        uint256 _quantity
    ) internal view returns (uint256) {
        uint256 feePercentage = controller.getModuleFee(
            address(this),
            _feeIndex
        );
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _setToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromSetToken(
        ISetToken _setToken,
        address _token,
        uint256 _feeQuantity
    ) internal {
        if (_feeQuantity > 0) {
            _setToken.strictInvokeTransfer(
                _token,
                controller.feeRecipient(),
                _feeQuantity
            );
        }
    }

    /**
     * Returns true if the module is in process of initialization on the SetToken
     */
    function isSetPendingInitialization(
        ISetToken _setToken
    ) internal view returns (bool) {
        return _setToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the SetToken's manager
     */
    function isSetManager(
        ISetToken _setToken,
        address _toCheck
    ) internal view returns (bool) {
        return _setToken.manager() == _toCheck;
    }

    /**
     * Returns true if SetToken must be enabled on the controller
     * and module is registered on the SetToken
     */
    function isSetValidAndInitialized(
        ISetToken _setToken
    ) internal view returns (bool) {
        return
            controller.isSet(address(_setToken)) &&
            _setToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns (bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must SetToken manager and SetToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidSet(
        ISetToken _setToken
    ) internal view {
        require(
            isSetManager(_setToken, msg.sender),
            "Must be the SetToken manager"
        );
        require(
            isSetValidAndInitialized(_setToken),
            "Must be a valid and initialized SetToken"
        );
    }

    /**
     * Caller must SetToken manager
     */
    function _validateOnlySetManager(
        ISetToken _setToken,
        address _caller
    ) internal view {
        require(
            isSetManager(_setToken, _caller),
            "Must be the SetToken manager"
        );
    }

    /**
     * SetToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedSet(
        ISetToken _setToken
    ) internal view {
        require(
            isSetValidAndInitialized(_setToken),
            "Must be a valid and initialized SetToken"
        );
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(ISetToken _setToken) internal view {
        require(
            _setToken.moduleStates(msg.sender) ==
                ISetToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * SetToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingSet(
        ISetToken _setToken
    ) internal view {
        require(
            controller.isSet(address(_setToken)),
            "Must be controller-enabled SetToken"
        );
        require(
            isSetPendingInitialization(_setToken),
            "Must be pending initialization"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {ISetToken} from "../../interfaces/ISetToken.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title Position
 * @author Set Protocol
 *
 * Collection of helper functions for handling and updating SetToken Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the SetToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(
        ISetToken _setToken,
        address _component
    ) internal view returns (bool) {
        return _setToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the SetToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(
        ISetToken _setToken,
        address _component
    ) internal view returns (bool) {
        return _setToken.getExternalPositionModules(_component).length > 0;
    }

    /**
     * Returns whether the SetToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(
        ISetToken _setToken,
        address _component,
        uint256 _unit
    ) internal view returns (bool) {
        return
            _setToken.getDefaultPositionRealUnit(_component) >=
            _unit.toInt256();
    }

    /**
     * Returns whether the SetToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        ISetToken _setToken,
        address _component,
        address _positionModule,
        uint256 _unit
    ) internal view returns (bool) {
        return
            _setToken.getExternalPositionRealUnit(
                _component,
                _positionModule
            ) >= _unit.toInt256();
    }

    /**
     * If the position does not exist, create a new Position and add to the SetToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
     * components where needed (in light of potential external positions).
     *
     * @param _setToken           Address of SetToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(
        ISetToken _setToken,
        address _component,
        uint256 _newUnit
    ) internal {
        bool isPositionFound = hasDefaultPosition(_setToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.removeComponent(_component);
            }
        }

        _setToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position.
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _setToken         SetToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        ISetToken _setToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    ) internal {
        if (_newUnit != 0) {
            if (!_setToken.isComponent(_component)) {
                _setToken.addComponent(_component);
                _setToken.addExternalPositionModule(_component, _module);
            } else if (
                !_setToken.isExternalPositionModule(_component, _module)
            ) {
                _setToken.addExternalPositionModule(_component, _module);
            }
            _setToken.editExternalPositionUnit(_component, _module, _newUnit);
            _setToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (
                _setToken.getExternalPositionRealUnit(_component, _module) != 0
            ) {
                address[] memory positionModules = _setToken
                    .getExternalPositionModules(_component);
                if (
                    _setToken.getDefaultPositionRealUnit(_component) == 0 &&
                    positionModules.length == 1
                ) {
                    require(
                        positionModules[0] == _module,
                        "External positions must be 0 to remove component"
                    );
                    _setToken.removeComponent(_component);
                }
                _setToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(
        uint256 _setTokenSupply,
        uint256 _positionUnit
    ) internal pure returns (uint256) {
        return _setTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(
        uint256 _setTokenSupply,
        uint256 _totalNotional
    ) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_setTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _setToken           Address of the SetToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(
        ISetToken _setToken,
        address _component
    ) internal view returns (uint256) {
        int256 positionUnit = _setToken.getDefaultPositionRealUnit(_component);
        return _setToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _setToken                 Address of the SetToken
     * @param _component                Address of the component
     * @param _setTotalSupply           Current SetToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        ISetToken _setToken,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    ) internal returns (uint256, uint256, uint256) {
        uint256 currentBalance = IERC20(_component).balanceOf(
            address(_setToken)
        );
        uint256 positionUnit = _setToken
            .getDefaultPositionRealUnit(_component)
            .toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _setTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_setToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes SetToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of SetToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _setTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    ) internal pure returns (uint256) {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(
            _prePositionUnit.preciseMul(_setTokenSupply)
        );
        return
            _postTotalNotional.sub(airdroppedAmount).preciseDiv(
                _setTokenSupply
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {IController} from "../../interfaces/IController.sol";
import {IIntegrationRegistry} from "../../interfaces/IIntegrationRegistry.sol";
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {ISetValuer} from "../../interfaces/ISetValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {
    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 internal constant INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 internal constant PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 internal constant SET_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(
        IController _controller
    ) internal view returns (IIntegrationRegistry) {
        return
            IIntegrationRegistry(
                _controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID)
            );
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(
        IController _controller
    ) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(
        IController _controller
    ) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IController} from "../../interfaces/IController.sol";
import {ISetToken} from "../../interfaces/ISetToken.sol";

/**
 * @title  SetTokenAccessible
 * @author Set Protocol
 *
 * Abstract class that houses permissioning of module for SetTokens.
 */
abstract contract SetTokenAccessible is Ownable {
    /* ============ Events ============ */

    /**
     * @dev Emitted on updateAllowedSetToken()
     * @param _setToken SetToken being whose allowance to initialize this module is being updated
     * @param _added    true if added false if removed
     */
    event SetTokenStatusUpdated(
        ISetToken indexed _setToken,
        bool indexed _added
    );

    /**
     * @dev Emitted on updateAnySetAllowed()
     * @param _anySetAllowed    true if any set is allowed to initialize this module, false otherwise
     */
    event AnySetAllowedUpdated(bool indexed _anySetAllowed);

    /* ============ Modifiers ============ */

    // @dev If anySetAllowed is true or _setToken is registered in allowedSetTokens, modifier succeeds.
    // Reverts otherwise.
    modifier onlyAllowedSet(ISetToken _setToken) {
        if (!anySetAllowed) {
            require(allowedSetTokens[_setToken], "Not allowed SetToken");
        }
        _;
    }

    /* ============ State Variables ============ */

    // Address of the controller
    IController private controller;

    // Mapping of SetToken to boolean indicating if SetToken is on allow list. Updateable by governance
    mapping(ISetToken => bool) public allowedSetTokens;

    // Boolean that returns if any SetToken can initialize this module. If false, then subject to allow list.
    // Updateable by governance.
    bool public anySetAllowed;

    /* ============ Constructor ============ */

    /**
     * Set controller state variable
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ External Functions ============ */

    /**
     * @dev GOVERNANCE ONLY: Enable/disable ability of a SetToken to initialize this module.
     *
     * @param _setToken             Instance of the SetToken
     * @param _status               Bool indicating if _setToken is allowed to initialize this module
     */
    function updateAllowedSetToken(
        ISetToken _setToken,
        bool _status
    ) public onlyOwner {
        require(
            controller.isSet(address(_setToken)) || allowedSetTokens[_setToken],
            "Invalid SetToken"
        );
        allowedSetTokens[_setToken] = _status;
        emit SetTokenStatusUpdated(_setToken, _status);
    }

    /**
     * @dev GOVERNANCE ONLY: Toggle whether ANY SetToken is allowed to initialize this module.
     *
     * @param _anySetAllowed             Bool indicating if ANY SetToken is allowed to initialize this module
     */
    function updateAnySetAllowed(bool _anySetAllowed) public onlyOwner {
        anySetAllowed = _anySetAllowed;
        emit AnySetAllowedUpdated(_anySetAllowed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Invoke} from "../lib/Invoke.sol";
import {Position} from "../lib/Position.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";
import {ISetToken} from "../../interfaces/ISetToken.sol";
import {ModuleBase} from "../lib/ModuleBase.sol";
import {IController} from "../../interfaces/IController.sol";
import {AddressArrayUtils} from "../../lib/AddressArrayUtils.sol";
import {TickBitmap} from "../../lib/TickBitmap.sol";
import {ValuePosition} from "../../lib/ValuePosition.sol";

contract AuctionRebalanceModule is ModuleBase, ReentrancyGuard {
    using Invoke for ISetToken;
    using Position for ISetToken.Position;
    using Position for ISetToken;
    using PreciseUnitMath for int256;
    using TickBitmap for mapping(int16 => uint256);
    using ValuePosition for ValuePosition.Info;
    using ValuePosition for mapping(bytes32 => ValuePosition.Info);
    using AddressArrayUtils for address[];

    /* ============ Enums ============ */
    enum RebalanceStatus {
        NONE, // Indicates no rebalance action can be taken
        PROGRESSING,
        SUCCESSED,
        FAILURED
    }

    /* ============ Constants ============ */

    int24 public constant MAXTICK = 4096; // Change 32767 -> 4096, Worst-case calculations: If tick 3072 requires a gas consumption of 12,000,000
    uint256 public constant MINI_DURATION = 30 minutes; // Minimum duration of the auction
    /* ============ Immutable ============ */
    int256 public immutable VIRTUAL_BASE_AMOUNT; // Just base for caculate

    /* ============ State Variables ============ */

    mapping(ISetToken => uint256) public serialIds; // For recording rebalance serial, start at No 1.
    mapping(ISetToken => mapping(uint256 => RebalanceInfo))
        public rebalanceInfos; // Recorded all rebalance info.
    mapping(ISetToken => mapping(uint256 => mapping(int16 => uint256)))
        public tickBitmaps;

    mapping(ISetToken => mapping(uint256 => int24)) public maxTicks; // Each setup balance maximum tick record.
    mapping(ISetToken => mapping(bytes32 => ValuePosition.Info))
        private _valuePositions; // Storage user amount in tick and status claimed
    mapping(ISetToken => mapping(uint256 => mapping(int24 => int256)))
        private _virtualAmountsOnTicks; // The total amount reserved on each tick
    // This variable can only be set if it is overrecruited
    mapping(ISetToken => mapping(uint256 => int256))
        private _exactTickAboveGetProportion; // The percentage of tokens that users who are bid at exact tick will be able to acquire 10% = 0.1*10**18
    mapping(ISetToken => mapping(uint256 => int24)) private _winningBidTick; // Price win the bid. If win tick = 0, bid may not get full. _totalVirtualAmount will be sign.

    /* ============ Structs ============ */
    struct RebalanceInfo {
        RebalanceStatus status; // Status.
        uint256 rebalanceStartTime; // Unix timestamp marking the start of the rebalance.
        uint256 rebalanceDuration; // Duration of the rebalance in seconds, exp 3 days.
        uint256 prohibitedCancellationDuration; // The duration of the prohibition on cancellation before the end of the auction
        address[] rebalanceComponents; // List of component tokens involved in the rebalance.
        int256[] rebalanceAmounts; // List of component tokens rebalance amounts, maybe nagtive.
        int256 minBidVirtualAmount; // Minimum sets required for each bid.
        int256 priceSpacing;
        int256 minBasePrice; // Can be nagtive. Decimal 10**18.
        int24 maxTick; // Allows users bid max ticks
        // _totalVirtualAmount > VIRTUAL_BASE_AMOUNT: overrecruited.
        int256 _totalVirtualAmount; //  When the bid is not completed, the final total virtual amount. Also save gas.
    }

    /* ============ Modifiers ============ */

    modifier onlyAllowedBidTime(ISetToken _setToken) {
        _validateOnlyAllowedBidTimeOrStatus(_setToken);
        _;
    }

    modifier onlyAllowedCancelTime(ISetToken _setToken) {
        _validateOnlyAllowedCancelTimeOrStatus(_setToken);
        _;
    }
    /* ============ Events ============ */
    event AuctionSetuped(address indexed _setToken, uint256 _serialId);

    // If the auction result is successful, the winning tick will have a value
    event AuctionResultSet(
        address indexed _setToken,
        uint256 _serialId,
        bool _isSuccess,
        int24 _winTick
    );
    event Bid(
        address indexed _setToken,
        address indexed _account,
        uint256 _serialId,
        int24 _tick,
        int256 _virtualAmount
    );
    event CancelBid(
        address indexed _setToken,
        address indexed _account,
        uint256 _serialId,
        int24 _tick,
        int256 _virtualAmount
    );
    event Claim(
        address indexed _setToken,
        address indexed _account,
        uint256 _serialId,
        int24 _tick
    );

    /* ============ Constructor ============ */
    constructor(IController _controller) public ModuleBase(_controller) {
        VIRTUAL_BASE_AMOUNT = PreciseUnitMath.preciseUnitInt();
    }

    /* ============ External Functions ============ */

    /**
     * @notice  The manager initiates the auction.
     * @dev     After opening the auction, unlocking sets does not need to be considered.
     * @param   _setToken  The target sets contract address of the operation.
     * @param   _rebalanceComponents  The token address that needs to be auctioned.
     * @param   _rebalanceAmounts  The number of auctions, the positive number is for the tokens sold, and the negative number is the revenue tokens.
     * @param   _rebalanceStartTime  The time when the auction started.
     * @param   _rebalanceDuration  Auction duration, in seconds.
     * @param   _prohibitedCancellationDuration  // The duration of the prohibition on cancellation before the end of the auction.
     * @param   _targetAmountsSets  The minimum number of sets expected to be received.
     * @param   _minBidVirtualAmount  The minimum number of sets required at a time.
     * @param   _priceSpacing  Price Minimum Interval.
     * @param   _maxTick  Price Minimum Interval.
     */

    function setupAuction(
        ISetToken _setToken,
        address[] memory _rebalanceComponents,
        int256[] memory _rebalanceAmounts,
        uint256 _rebalanceStartTime,
        uint256 _rebalanceDuration,
        uint256 _prohibitedCancellationDuration,
        int256 _targetAmountsSets,
        int256 _minBidVirtualAmount,
        int256 _priceSpacing,
        int24 _maxTick
    ) external nonReentrant onlyManagerAndValidSet(_setToken) {
        require(_rebalanceStartTime > block.timestamp,"The start time must be in the future");
        require(_rebalanceDuration >= MINI_DURATION, "The duration must be greater than the minimum duration");
        require(_prohibitedCancellationDuration <= _rebalanceDuration, "The prohibition of cancellation shall not be greater than the total duration");
        require(
            _rebalanceComponents.length > 0,
            "Must have at least 1 component"
        );
        require(
            _rebalanceComponents.length == _rebalanceAmounts.length,
            "Component and unit lengths must be the same"
        );
        require(_priceSpacing > 0, "Price spcacing must be bigger than 0");
        require(_minBidVirtualAmount > 0, "Min virtual amount must be bigger than 0");
        require(_maxTick <= MAXTICK, "Tick must less than MAXTICK");
        require(
            VIRTUAL_BASE_AMOUNT % _minBidVirtualAmount == 0,
            "Must be available in equal portions"
        );
        int256 portion = VIRTUAL_BASE_AMOUNT / _minBidVirtualAmount;
        for (uint256 i = 0; i < _rebalanceAmounts.length; i++) {
            require(
                _rebalanceAmounts[i] % portion == 0,
                "Must be divisible by the number of portion"
            );
        }
        require(_setToken.isLocked(), "Sets should be locked");
        uint256 serialId = serialIds[_setToken];
        require(
            rebalanceInfos[_setToken][serialId].status !=
                RebalanceStatus.PROGRESSING,
            "Latest bid is progressing"
        );
        serialId = serialId.add(1);
        serialIds[_setToken] = serialId;

        RebalanceInfo storage info = rebalanceInfos[_setToken][serialId];
        info.status = RebalanceStatus.PROGRESSING;
        info.rebalanceStartTime = _rebalanceStartTime;
        info.rebalanceDuration = _rebalanceDuration;
        info.prohibitedCancellationDuration = _prohibitedCancellationDuration;
        info.rebalanceComponents = _rebalanceComponents;
        info.rebalanceAmounts = _rebalanceAmounts;
        info.minBidVirtualAmount = _minBidVirtualAmount;
        info.priceSpacing = _priceSpacing;
        info.maxTick = _maxTick;
        info.minBasePrice = _targetAmountsSets.preciseDiv(VIRTUAL_BASE_AMOUNT);
        emit AuctionSetuped(address(_setToken), serialId);
    }

    /**
     * @notice  The auction failed.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     */
    function setAuctionResultFailed(
        ISetToken _setToken
    ) external nonReentrant onlyManagerAndValidSet(_setToken) {
        _excutionBidResult(_setToken, false);
    }

    /**
     * @notice  Confirm the success of the auction after the auction is closed.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     */
    function setAuctionResultSuccess(
        ISetToken _setToken
    ) external nonReentrant onlyManagerAndValidSet(_setToken) {
        _excutionBidResult(_setToken, true);
    }

    /**
     * @notice  Auctions are conducted in bulk.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _ticks  The minimum price is used as the criterion to interval the number of spaces.
     * @param   _virtualAmounts  The number of auctions can be taken as a percentage.
     */
    function batchBid(
        ISetToken _setToken,
        int24[] memory _ticks,
        int256[] memory _virtualAmounts
    )
        external
        nonReentrant
        onlyValidAndInitializedSet(_setToken)
        onlyAllowedBidTime(_setToken)
    {
        require(_ticks.length > 0, "Must have at least 1 tick");
        require(
            _ticks.length == _virtualAmounts.length,
            "Ticks and virtualAmounts lengths must be the same"
        );
        for (uint256 i = 0; i < _ticks.length; i++) {
            _bid(_setToken, _ticks[i], _virtualAmounts[i]);
        }
    }

    /**
     * @notice  The user participates in the operation of the auction during the auction phase.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _tick  The minimum price is used as the criterion to interval the number of spaces.
     * @param   _virtualAmount  The number of auctions can be taken as a percentage.
     */
    function bid(
        ISetToken _setToken,
        int24 _tick,
        int256 _virtualAmount
    )
        external
        nonReentrant
        onlyValidAndInitializedSet(_setToken)
        onlyAllowedBidTime(_setToken)
    {
        _bid(_setToken, _tick, _virtualAmount);
    }

    /**
     * @notice  Cancel in bulk.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _ticks  The minimum price is used as the criterion to interval the number of spaces.
     */
    function batchCancelBid(
        ISetToken _setToken,
        int24[] memory _ticks
    )
        external
        nonReentrant
        onlyValidAndInitializedSet(_setToken)
        onlyAllowedCancelTime(_setToken)
    {
        require(_ticks.length > 0, "Must have at least 1 tick");
        for (uint256 i = 0; i < _ticks.length; i++) {
            _cancelBid(_setToken, _ticks[i]);
        }
    }

    /**
     * @notice  While the auction is in progress, the user can choose to cancel the auction and return the mortgage for the auction.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _tick  The minimum price is used as the criterion to interval the number of spaces.
     */
    function cancelBid(
        ISetToken _setToken,
        int24 _tick
    )
        external
        nonReentrant
        onlyValidAndInitializedSet(_setToken)
        onlyAllowedCancelTime(_setToken)
    {
        _cancelBid(_setToken, _tick);
    }

    // There is no check of setToken legitimacy here
    // The expectation is that you will be able to claim historical transactions even if the module is removed
    /**
     * @notice  Perform claim operations in batches.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _serialIds  The serial number of the auction, in increments.
     * @param   _ticks  The minimum price is used as the criterion to interval the number of spaces.
     */
    function batchClaim(
        ISetToken _setToken,
        uint256[] memory _serialIds,
        int24[] memory _ticks
    ) external nonReentrant {
        require(_serialIds.length > 0, "Must have at least 1 serial id");
        require(
            _serialIds.length == _ticks.length,
            "Ticks and serial ids lengths must be the same"
        );
        for (uint256 i = 0; i < _serialIds.length; i++) {
            _claim(_setToken, _serialIds[i], _ticks[i]);
        }
    }

    /**
     * @notice  Collect the auction results, and return the auction if the auction does not win the bid or the auction fails.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _serialId  The serial number of the auction, in increments.
     * @param   _tick  The minimum price is used as the criterion to interval the number of spaces.
     */
    function claim(
        ISetToken _setToken,
        uint256 _serialId,
        int24 _tick
    ) external nonReentrant {
        _claim(_setToken, _serialId, _tick);
    }

    /**
     * @notice  If you want to start the auction, you need to lock the sets in advance, and unlock them when the auction ends, which needs to be operated by the manager.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     */
    function lock(
        ISetToken _setToken
    ) external onlyManagerAndValidSet(_setToken) {
        // lock the SetToken
        _setToken.lock();
    }

    /**
     * @notice  If you want to start the auction, you need to lock the sets in advance, and unlock them when the auction ends, which needs to be operated by the manager.
     * @dev     There is no need to check if the previous auction has ended.
     * @param   _setToken  The target sets contract address of the operation..
     */
    function unlock(
        ISetToken _setToken
    ) external onlyManagerAndValidSet(_setToken) {
        // Unlock the SetToken
        _setToken.unlock();
    }

    /**
     * @notice  Initialize the module.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     */
    function initialize(
        ISetToken _setToken
    )
        external
        onlySetManager(_setToken, msg.sender)
        onlyValidAndPendingSet(_setToken)
    {
        _setToken.initializeModule();
    }

    /**
     * @notice  .
     * @dev     .
     */
    function removeModule() external override {
        ISetToken setToken = ISetToken(msg.sender);
        uint256 serialId = serialIds[setToken];
        require(
            rebalanceInfos[setToken][serialId].status !=
                RebalanceStatus.PROGRESSING,
            "Latest bid is progressing"
        );
    }

    /* ============ External View Functions ============ */

    /**
     * @notice  Get the contract address and quantity of the auction.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation.
     * @param   _serialId  The serial number of the auction, in increments.
     * @return  components  The token address that needs to be auctioned.
     * @return  amounts  The number of auctions, the positive number is for the tokens sold, and the negative number is the revenue tokens.
     */
    function getAuctionComponentsAndAmounts(
        ISetToken _setToken,
        uint256 _serialId
    )
        external
        view
        returns (address[] memory components, int256[] memory amounts)
    {
        RebalanceInfo memory info = rebalanceInfos[_setToken][_serialId];
        components = info.rebalanceComponents;
        amounts = info.rebalanceAmounts;
    }

    /**
     * @notice  Get the number of sets or rewards based on the virtual quantity of the target.
     * @dev     The specific transfer amount of the user is not recorded, and for the convenience of refund, it has been exchanged, and the user's amount is added by 1 here
     * @param   _setToken  The target sets contract address of the operation.
     * @param   _serialId  The serial number of the auction, in increments.
     * @param   _tick  The minimum price is used as the criterion to interval the number of spaces.
     * @param   _virtualAmount  The fictitious amount is a proportion, convenient to calculate, and the base is a standard unit.
     * @return  amount  If the amount is positive, it needs to be transferred, and if it is negative, it is the amount of rewards.
     */
    function getRequiredOrRewardsSetsAmountsOnTickForBid(
        ISetToken _setToken,
        uint256 _serialId,
        int24 _tick,
        int256 _virtualAmount
    ) external view returns (int256 amount) {
        require(_virtualAmount > 0, "Virtual amount must be positive number");
        require(_tick >= 0, "Tick need be bigger than 0");
        RebalanceInfo memory info = rebalanceInfos[_setToken][_serialId];
        amount = _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
            info.minBasePrice,
            info.priceSpacing,
            _tick,
            _virtualAmount
        );
    }

    /**
     * @notice  Get the actual number of auction tokens based on the target virtual quantity.
     * @dev     The specific transfer amount of the user is not recorded, and for the convenience of refund, it has been exchanged, and the user's amount is added by 1 here
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _serialId  The serial number of the auction, in increments.
     * @param   _virtualAmount  The fictitious amount is a proportion, convenient to calculate, and the base is a standard unit.
     * @return  components  List of addresses of components for tranfer or send.
     * @return  amounts  If the amount is positive, contract send to user, and if it is negative, user send to contract.
     */
    function getRequiredOrRewardComponentsAndAmountsForBid(
        ISetToken _setToken,
        uint256 _serialId,
        int256 _virtualAmount
    )
        external
        view
        returns (address[] memory components, int256[] memory amounts)
    {
        require(_virtualAmount > 0, "Virtual amount must be positive number");
        RebalanceInfo memory info = rebalanceInfos[_setToken][_serialId];
        components = info.rebalanceComponents;
        int256[] memory rebalanceAmounts = info.rebalanceAmounts;
        uint256 componentsLength = components.length;
        amounts = new int256[](componentsLength);
        for (uint256 i = 0; i < componentsLength; i++) {
            amounts[i] = rebalanceAmounts[i].preciseMul(_virtualAmount);
        }
    }

    /**
     * @notice  Get the tick that won the bid.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _serialId  The serial number of the auction, in increments.
     * @return  winTick  Winning bid tick.
     */
    function getFinalWinningTick(
        ISetToken _setToken,
        uint256 _serialId
    ) external view returns (int24 winTick) {
        // not check valid
        winTick = _winningBidTick[_setToken][_serialId];
    }

    /**
     * @notice  Dynamically calculates the tick that wins the bid in real time.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _serialId  The serial number of the auction, in increments.
     * @return  winTick  .
     * @return  totalVirtualAmount  .
     * @return  lastTickVirtualAmount  .
     */
    function getPreCalculatedWinningTick(
        ISetToken _setToken,
        uint256 _serialId
    )
        external
        view
        returns (
            int24 winTick,
            int256 totalVirtualAmount,
            int256 lastTickVirtualAmount
        )
    {
        (
            winTick,
            totalVirtualAmount,
            lastTickVirtualAmount
        ) = _searchWinningBidTick(_setToken, _serialId);
    }

    /**
     * @notice  Get the total number of bids a user has made on a tick.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation..
     * @param   _serialId  The serial number of the auction, in increments.
     * @param   _account  Bidder account address.
     * @param   _tick  The minimum price is used as the criterion to interval the number of spaces.
     * @return  int256  Returns the total amount the user invested on a tick.
     */
    function getAccountTotalVirtualAmountOnTick(
        ISetToken _setToken,
        uint256 _serialId,
        address _account,
        int24 _tick
    ) external view returns (int256) {
        return
            _getAccountVirtualAmountOnTick(
                _setToken,
                _serialId,
                _account,
                _tick
            );
    }

    /**
     * @notice  Get the total number of bids on a tick.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation.
     * @param   _serialId  The serial number of the auction, in increments.
     * @param   _tick  The minimum price is used as the criterion to interval the number of spaces.
     * @return  int256  Returns the total number of bids on a tick.
     */
    function getTotalVirtualAmountsOnTick(
        ISetToken _setToken,
        uint256 _serialId,
        int24 _tick
    ) external view returns (int256) {
        return _virtualAmountsOnTicks[_setToken][_serialId][_tick];
    }

    /**
     * @notice  Get the proportion of users who actually win bids.
     * @dev     .
     * @param   _setToken  The target sets contract address of the operation.
     * @param   _serialId  The serial number of the auction, in increments.
     * @param   _account  Bidder account address.
     * @param   _tick  The minimum price is used as the criterion to interval the number of spaces.
     * @return  int256  Returns the number of virtual bids won by actual users.
     */
    function getActualBiddedVirtualAmount(
        ISetToken _setToken,
        uint256 _serialId,
        address _account,
        int24 _tick
    ) external view returns (int256) {
        require(_tick >= 0, "Tick need be bigger than 0");
        (
            int24 winTick,
            int256 totalVirtualAmount,
            int256 lastTickVirtualAmount
        ) = _searchWinningBidTick(_setToken, _serialId);
        int256 exactTickProportion = VIRTUAL_BASE_AMOUNT;
        if (totalVirtualAmount > VIRTUAL_BASE_AMOUNT && winTick == _tick) {
            int256 overBidVirtualAmount = totalVirtualAmount.sub(
                VIRTUAL_BASE_AMOUNT
            );
            exactTickProportion = lastTickVirtualAmount
                .sub(overBidVirtualAmount)
                .preciseDiv(lastTickVirtualAmount);
        }
        if (_tick < winTick) {
            return 0;
        }
        int256 accountVirtualAmount = _getAccountVirtualAmountOnTick(
            _setToken,
            _serialId,
            _account,
            _tick
        );
        return accountVirtualAmount.preciseMul(exactTickProportion);
    }

    /* ============ Internal Functions ============ */

    function _bid(
        ISetToken _setToken,
        int24 _tick,
        int256 _virtualAmount
    ) internal {
        require(_tick >= 0, "Tick need be bigger than 0");
        uint256 serialId = serialIds[_setToken];
        RebalanceInfo storage info = rebalanceInfos[_setToken][serialId];
        require(_tick <= info.maxTick, "Tick too big");
        require(
            _virtualAmount >= info.minBidVirtualAmount &&
                _virtualAmount % info.minBidVirtualAmount == 0,
            "Virtual quantity not meeting the requirements"
        );

        int256 setsTokenAmountNeeded = _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
                info.minBasePrice,
                info.priceSpacing,
                _tick,
                _virtualAmount
            );

        // tranfer token if needed
        _transferBidSets(_setToken, msg.sender, setsTokenAmountNeeded);
        _transferBidToken(
            msg.sender,
            _virtualAmount,
            info.rebalanceComponents,
            info.rebalanceAmounts
        );

        ValuePosition.Info storage _valuePosition = _valuePositions[_setToken]
            .get(serialId, msg.sender, _tick);
        _valuePosition.add(_virtualAmount);

        mapping(int16 => uint256) storage tickBitmap = tickBitmaps[_setToken][
            serialId
        ];
        // make sure this tick 0
        (int24 next, bool inited) = tickBitmap.nextInitializedTickWithinOneWord(
            _tick,
            1,
            true
        );
        if (!(inited && next == _tick)) {
            tickBitmap.flipTick(_tick, 1);
        }
        _updateTotalVirtualAmountsOnTick(
            _setToken,
            serialId,
            _tick,
            _virtualAmount
        );
        _updateMaxTick(_setToken, serialId, _tick);
        emit Bid(
            address(_setToken),
            msg.sender,
            serialId,
            _tick,
            _virtualAmount
        );
    }

    function _cancelBid(ISetToken _setToken, int24 _tick) internal {
        require(_tick >= 0, "Tick need be bigger than 0");
        uint256 serialId = serialIds[_setToken];
        ValuePosition.Info storage _valuePosition = _valuePositions[_setToken]
            .get(serialId, msg.sender, _tick);
        int256 virtualAmount = _valuePosition.virtualAmount;
        _valuePosition.sub(virtualAmount);
        require(virtualAmount > 0, "There is no corresponding asset");
        RebalanceInfo memory info = rebalanceInfos[_setToken][serialId];
        int256 setsTokenAmountNeeded = _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
                info.minBasePrice,
                info.priceSpacing,
                _tick,
                virtualAmount
            );

        _rollbackBidSets(_setToken, msg.sender, setsTokenAmountNeeded);
        _rollbackBidToken(
            msg.sender,
            virtualAmount,
            info.rebalanceComponents,
            info.rebalanceAmounts
        );
        int256 afterRollback = _updateTotalVirtualAmountsOnTick(
            _setToken,
            serialId,
            _tick,
            virtualAmount.neg()
        );

        if (afterRollback == 0) {
            mapping(int16 => uint256) storage tickBitmap = tickBitmaps[
                _setToken
            ][serialId];
            tickBitmap.flipTick(_tick, 1);
            int24 maxtick = maxTicks[_setToken][serialId];
            if (maxtick == _tick){
                int24 currentTick = maxtick;
                while (true) {
                    (int24 next, bool inited) = tickBitmap.nextInitializedTickWithinOneWord(currentTick, 1, true);
                    if (inited) {
                        maxTicks[_setToken][serialId] = next;
                        break;
                    }
                    currentTick = next - 1;
                    if (currentTick < 0) {
                        maxTicks[_setToken][serialId] = 0;
                        break;
                    }
                }
            }
        }
        emit CancelBid(
            address(_setToken),
            msg.sender,
            serialId,
            _tick,
            virtualAmount
        );
    }

    function _claim(
        ISetToken _setToken,
        uint256 _serialId,
        int24 _tick
    ) internal {
        require(_tick >= 0, "Tick need be bigger than 0");
        RebalanceInfo memory info = rebalanceInfos[_setToken][_serialId];
        require(
            info.status == RebalanceStatus.SUCCESSED ||
                info.status == RebalanceStatus.FAILURED,
            "Bid's status must be finished status"
        );

        ValuePosition.Info storage _valuePosition = _valuePositions[_setToken]
            .get(_serialId, msg.sender, _tick);
        require(!_valuePosition.claimed, "Already been claimed");
        int256 virtualAmount = _valuePosition.virtualAmount;
        require(virtualAmount > 0, "There is no corresponding asset");
        _valuePosition.claimed = true;

        if (info.status == RebalanceStatus.FAILURED) {
            _bidRollbackAllAssets(
                _setToken,
                _serialId,
                msg.sender,
                _tick,
                virtualAmount
            );
        } else if (info.status == RebalanceStatus.SUCCESSED) {
            _bidSuccessClaimRewards(
                _setToken,
                _serialId,
                msg.sender,
                _tick,
                virtualAmount
            );
        }
        emit Claim(address(_setToken), msg.sender, _serialId, _tick);
    }

    function _bidRollbackAllAssets(
        ISetToken _setToken,
        uint256 _serialId,
        address _account,
        int24 _tick,
        int256 _virtualAmount
    ) internal {
        RebalanceInfo memory info = rebalanceInfos[_setToken][_serialId];
        int256 setsTokenAmountNeeded = _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
                info.minBasePrice,
                info.priceSpacing,
                _tick,
                _virtualAmount
            );
        _rollbackBidSets(_setToken, _account, setsTokenAmountNeeded);
        _rollbackBidToken(
            _account,
            _virtualAmount,
            info.rebalanceComponents,
            info.rebalanceAmounts
        );
    }

    function _bidSuccessClaimRewards(
        ISetToken _setToken,
        uint256 _serialId,
        address _account,
        int24 _tick,
        int256 _virtualAmount
    ) internal {
        RebalanceInfo memory info = rebalanceInfos[_setToken][_serialId];
        int256 setsTokenAmountNeeded = _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
                info.minBasePrice,
                info.priceSpacing,
                _tick,
                _virtualAmount
            );
        int24 winTick = _winningBidTick[_setToken][_serialId];

        if (_tick < winTick) {
            // no win bid
            _rollbackBidSets(_setToken, _account, setsTokenAmountNeeded);
            _rollbackBidToken(
                _account,
                _virtualAmount,
                info.rebalanceComponents,
                info.rebalanceAmounts
            );
        } else {
            int256 bidPrice = _caculateTargetPriceWithTick(
                info.minBasePrice,
                info.priceSpacing,
                _tick
            );
            if (
                info._totalVirtualAmount > VIRTUAL_BASE_AMOUNT &&
                winTick == _tick
            ) {
                // Percentage of winning bids, rounded down
                int256 proportion = _exactTickAboveGetProportion[_setToken][
                    _serialId
                ];
                int256 biddedVirtualAmount = proportion.preciseMul(
                    _virtualAmount
                );
                if (bidPrice > 0) {
                    _rollbackBidSets(
                        _setToken,
                        _account,
                        setsTokenAmountNeeded
                            .sub(setsTokenAmountNeeded.preciseMul(proportion))
                            .sub(1)
                    );
                } else {
                    _rollbackBidSets(
                        _setToken,
                        _account,
                        -setsTokenAmountNeeded.preciseMul(proportion)
                    );
                }
                _rollbackBidToken(
                    _account,
                    _virtualAmount.sub(biddedVirtualAmount).sub(1),
                    info.rebalanceComponents,
                    info.rebalanceAmounts
                );
                _sentTokenRewards(
                    _account,
                    biddedVirtualAmount,
                    info.rebalanceComponents,
                    info.rebalanceAmounts
                );
            } else {
                // For more accurate calculations, calculated separately, easier to understand
                int256 ultimatelyConsumedSets = _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
                        info.minBasePrice,
                        info.priceSpacing,
                        winTick,
                        _virtualAmount
                    );
                int256 rollbackSetsAmount = setsTokenAmountNeeded.sub(
                    ultimatelyConsumedSets
                );
                if (bidPrice < 0) {
                    rollbackSetsAmount = rollbackSetsAmount.sub(
                        setsTokenAmountNeeded
                    );
                }
                _rollbackBidSets(_setToken, _account, rollbackSetsAmount);
                _sentTokenRewards(
                    _account,
                    _virtualAmount,
                    info.rebalanceComponents,
                    info.rebalanceAmounts
                );
            }
        }
    }

    function _rollbackBidSets(
        ISetToken _setToken,
        address _account,
        int256 _amount
    ) internal {
        if (_amount > 0) {
            IERC20(_setToken).transfer(_account, uint256(_amount));
        }
    }

    function _rollbackBidToken(
        address _account,
        int256 _virtualAmount,
        address[] memory _components,
        int256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _components.length; i++) {
            int256 totalAmount = _amounts[i];
            if (totalAmount < 0) {
                int256 amount2Transfer = totalAmount.preciseMul(_virtualAmount);
                IERC20(_components[i]).transfer(
                    _account,
                    amount2Transfer.abs()
                );
            }
        }
    }

    function _sentTokenRewards(
        address _account,
        int256 _virtualAmount,
        address[] memory _components,
        int256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _components.length; i++) {
            int256 totalAmount = _amounts[i];
            if (totalAmount > 0) {
                int256 amount2Transfer = totalAmount.preciseMul(_virtualAmount);

                IERC20(_components[i]).transfer(
                    _account,
                    amount2Transfer.toUint256()
                );
            }
        }
    }

    function _transferBidSets(
        ISetToken _setToken,
        address _account,
        int256 _amount
    ) internal {
        if (_amount > 0) {
            transferFrom(_setToken, _account, address(this), uint256(_amount));
        }
    }

    // each component tranfer if amount < 0
    function _transferBidToken(
        address _account,
        int256 _virtualAmount,
        address[] memory _components,
        int256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _components.length; i++) {
            int256 totalAmount = _amounts[i];
            if (totalAmount < 0) {
                int256 amount2Transfer = totalAmount.preciseMul(_virtualAmount);
                transferFrom(
                    IERC20(_components[i]),
                    _account,
                    address(this),
                    amount2Transfer.abs()
                );
            }
        }
    }

    function _excutionBidResult(ISetToken _setToken, bool validated) internal {
        uint256 serialId = serialIds[_setToken];
        RebalanceInfo storage info = rebalanceInfos[_setToken][serialId];
        require(
            info.status == RebalanceStatus.PROGRESSING,
            "Auction status must be progressing"
        );
        int24 winTickRecord;
        if (validated) {
            require(
                info.rebalanceStartTime + info.rebalanceDuration <=
                    block.timestamp,
                "Not excution time"
            );
            (
                int24 winTick,
                int256 totalVirtualAmount,
                int256 lastTickVirtualAmount
            ) = _searchWinningBidTick(_setToken, serialId);

            winTickRecord = winTick;
            if (totalVirtualAmount > VIRTUAL_BASE_AMOUNT) {
                int256 overBidVirtualAmount = totalVirtualAmount.sub(
                    VIRTUAL_BASE_AMOUNT
                );
                _exactTickAboveGetProportion[_setToken][
                    serialId
                ] = lastTickVirtualAmount.sub(overBidVirtualAmount).preciseDiv(
                    lastTickVirtualAmount
                );
            }
            info._totalVirtualAmount = totalVirtualAmount;
            info.status = RebalanceStatus.SUCCESSED;
            _winningBidTick[_setToken][serialId] = winTick;
            // for caculate
            if (totalVirtualAmount > VIRTUAL_BASE_AMOUNT) {
                totalVirtualAmount = VIRTUAL_BASE_AMOUNT;
            }

            int256 ultimatelyConsumedSets = _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
                    info.minBasePrice,
                    info.priceSpacing,
                    winTick,
                    totalVirtualAmount
                );

            _transferTokenAndUpdatePositionState(
                _setToken,
                ultimatelyConsumedSets,
                totalVirtualAmount,
                info.rebalanceComponents,
                info.rebalanceAmounts
            );
        } else {
            info.status = RebalanceStatus.FAILURED;
            // Do nothing
        }
        emit AuctionResultSet(
            address(_setToken),
            serialId,
            validated,
            winTickRecord
        );
    }

    function _disposeSetToken(ISetToken _setToken, int256 _amount) internal {
        if (_amount > 0) {
            // burn
            _setToken.burn(address(this), uint256(_amount));
        } else if (_amount < 0) {
            // mint
            _setToken.mint(address(this), _amount.abs());
        }
    }

    function _searchWinningBidTick(
        ISetToken _setToken,
        uint256 _serialId
    ) internal view returns (int24, int256, int256) {
        int24 maxTick = maxTicks[_setToken][_serialId];
        mapping(int16 => uint256) storage tickBitmap = tickBitmaps[_setToken][
            _serialId
        ];
        int24 currentTick = maxTick;
        int24 winTick = maxTick;
        int256 totalVirtualAmount = 0;
        int256 lastTickVirtualAmount = 0;
        // if tick < 0, bid not full the pool. if tick >=0 and totalVirtualAmount >= VIRTUAL_BASE_AMOUNT, bid success.
        while (totalVirtualAmount < VIRTUAL_BASE_AMOUNT) {
            (int24 next, bool inited) = tickBitmap
                .nextInitializedTickWithinOneWord(currentTick, 1, true);
            // Went through all the ticks and didn't get full
            if (inited) {
                lastTickVirtualAmount = _virtualAmountsOnTicks[_setToken][
                    _serialId
                ][next];
                totalVirtualAmount += lastTickVirtualAmount; // if user cancel bid, virtual amount maybe zero.
                winTick = next;
            }
            currentTick = next - 1;
            if (currentTick < 0) {
                winTick = 0;
                break;
            }
        }
        return (winTick, totalVirtualAmount, lastTickVirtualAmount);
    }

    function _transferTokenAndUpdatePositionState(
        ISetToken _setToken,
        int256 _setsAmount,
        int256 _virtualAmount,
        address[] memory _components,
        int256[] memory _amounts
    ) internal {
        uint256 preSetTotalSupply = _setToken.totalSupply();

        for (uint256 i = 0; i < _components.length; i++) {
            address component = _components[i];
            int256 transferAmount = _amounts[i].preciseMul(_virtualAmount);
            uint256 preTokenBalance = IERC20(component).balanceOf(
                address(_setToken)
            );
            if (transferAmount > 0) {
                _setToken.invokeTransfer(
                    component,
                    address(this),
                    uint256(transferAmount)
                );
            } else {
                IERC20(component).transfer(
                    address(_setToken),
                    transferAmount.abs()
                );
            }
            _setToken.calculateAndEditDefaultPosition(
                component,
                preSetTotalSupply,
                preTokenBalance
            );
        }

        _disposeSetToken(_setToken, _setsAmount);
        uint256 currentSetTotalSupply = _setToken.totalSupply();
        int256 newPositionMultiplier = _setToken
            .positionMultiplier()
            .mul(preSetTotalSupply.toInt256())
            .div(currentSetTotalSupply.toInt256());
        _setToken.editPositionMultiplier(newPositionMultiplier);
    }

    function _updateTotalVirtualAmountsOnTick(
        ISetToken _setToken,
        uint256 _serialId,
        int24 _tick,
        int256 _virtualAmount
    ) internal returns (int256 totalVirtualAmountAfter) {
        int256 totalVirtualAmountBefore = _virtualAmountsOnTicks[_setToken][
            _serialId
        ][_tick];
        totalVirtualAmountAfter = totalVirtualAmountBefore + _virtualAmount;
        require(totalVirtualAmountAfter >= 0, "Nerver less than zero");
        _virtualAmountsOnTicks[_setToken][_serialId][
            _tick
        ] = totalVirtualAmountAfter;
    }

    function _getAccountVirtualAmountOnTick(
        ISetToken _setToken,
        uint256 _serialId,
        address _account,
        int24 _tick
    ) internal view returns (int256) {
        ValuePosition.Info memory _valuePosition = _valuePositions[_setToken]
            .get(_serialId, _account, _tick);
        return _valuePosition.virtualAmount;
    }

    function _caculateRequiredOrRewardsSetsAmountsOnTickForBid(
        int256 minBasePrice,
        int256 _priceSpacing,
        int24 _tick,
        int256 _virtualAmount
    ) internal pure returns (int256) {
        int256 targetPrice = _caculateTargetPriceWithTick(
            minBasePrice,
            _priceSpacing,
            _tick
        );
        return _virtualAmount.preciseMul(targetPrice);
    }

    function _caculateTargetPriceWithTick(
        int256 minBasePrice,
        int256 _priceSpacing,
        int24 _tick
    ) internal pure returns (int256) {
        return minBasePrice.add(int256(_tick).mul(_priceSpacing));
    }

    function _updateMaxTick(
        ISetToken _setToken,
        uint256 _serialId,
        int24 _tick
    ) internal {
        int24 lastTick = maxTicks[_setToken][_serialId];
        if (lastTick < _tick) {
            maxTicks[_setToken][_serialId] = _tick;
        }
    }

    /* ============== Modifier Helpers =============== */

    function _validateOnlyAllowedBidTimeOrStatus(
        ISetToken _setToken
    ) internal view {
        uint256 id = serialIds[_setToken];
        RebalanceInfo memory info = rebalanceInfos[_setToken][id];
        require(
            info.status == RebalanceStatus.PROGRESSING,
            "Bid's status must be progressing"
        );
        require(
            info.rebalanceStartTime <= block.timestamp &&
                info.rebalanceStartTime + info.rebalanceDuration >
                block.timestamp,
            "Not bidding time"
        );
    }

    function _validateOnlyAllowedCancelTimeOrStatus(
        ISetToken _setToken
    ) internal view {
        uint256 id = serialIds[_setToken];
        RebalanceInfo memory info = rebalanceInfos[_setToken][id];
        require(
            info.status == RebalanceStatus.PROGRESSING,
            "Bid's status must be progressing"
        );
        require(
            info.rebalanceStartTime <= block.timestamp &&
                info.rebalanceStartTime + info.rebalanceDuration - info.prohibitedCancellationDuration >
                block.timestamp,
            "Not cancel time"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IController} from "../../interfaces/IController.sol";
import {IManagerIssuanceHook} from "../../interfaces/IManagerIssuanceHook.sol";
import {Invoke} from "../lib/Invoke.sol";
import {ISetToken} from "../../interfaces/ISetToken.sol";
import {ModuleBase} from "../lib/ModuleBase.sol";
import {Position} from "../lib/Position.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title BasicIssuanceModule
 * @author Set Protocol
 *
 * Module that enables issuance and redemption functionality on a SetToken. This is a module that is
 * required to bring the totalSupply of a Set above 0.
 */
contract BasicIssuanceModule is ModuleBase, ReentrancyGuard {
    using Invoke for ISetToken;
    using Position for ISetToken.Position;
    using Position for ISetToken;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;

    /* ============ Events ============ */

    event SetTokenIssued(
        address indexed _setToken,
        address indexed _issuer,
        address indexed _to,
        address _hookContract,
        uint256 _quantity
    );
    event SetTokenRedeemed(
        address indexed _setToken,
        address indexed _redeemer,
        address indexed _to,
        uint256 _quantity
    );

    /* ============ State Variables ============ */

    // Mapping of SetToken to Issuance hook configurations
    mapping(ISetToken => IManagerIssuanceHook) public managerIssuanceHook;

    /* ============ Constructor ============ */

    /**
     * Set state controller state variable
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public ModuleBase(_controller) {}

    /* ============ External Functions ============ */

    /**
     * Deposits the SetToken's position components into the SetToken and mints the SetToken of the given quantity
     * to the specified _to address. This function only handles Default Positions (positionState = 0).
     *
     * @param _setToken             Instance of the SetToken contract
     * @param _quantity             Quantity of the SetToken to mint
     * @param _to                   Address to mint SetToken to
     */
    function issue(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external nonReentrant onlyValidAndInitializedSet(_setToken) {
        require(_quantity > 0, "Issue quantity must be > 0");

        address hookContract = _callPreIssueHooks(
            _setToken,
            _quantity,
            msg.sender,
            _to
        );

        (
            address[] memory components,
            uint256[] memory componentQuantities
        ) = getRequiredComponentUnitsForIssue(_setToken, _quantity);

        // For each position, transfer the required underlying to the SetToken
        for (uint256 i = 0; i < components.length; i++) {
            // Transfer the component to the SetToken
            transferFrom(
                IERC20(components[i]),
                msg.sender,
                address(_setToken),
                componentQuantities[i]
            );
        }

        // Mint the SetToken
        _setToken.mint(_to, _quantity);

        emit SetTokenIssued(
            address(_setToken),
            msg.sender,
            _to,
            hookContract,
            _quantity
        );
    }

    /**
     * Redeems the SetToken's positions and sends the components of the given
     * quantity to the caller. This function only handles Default Positions (positionState = 0).
     *
     * @param _setToken             Instance of the SetToken contract
     * @param _quantity             Quantity of the SetToken to redeem
     * @param _to                   Address to send component assets to
     */
    function redeem(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external nonReentrant onlyValidAndInitializedSet(_setToken) {
        require(_quantity > 0, "Redeem quantity must be > 0");

        // Burn the SetToken - ERC20's internal burn already checks that the user has enough balance
        _setToken.burn(msg.sender, _quantity);

        // For each position, invoke the SetToken to transfer the tokens to the user
        address[] memory components = _setToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            require(
                !_setToken.hasExternalPosition(component),
                "Only default positions are supported"
            );

            uint256 unit = _setToken
                .getDefaultPositionRealUnit(component)
                .toUint256();

            // Use preciseMul to round down to ensure overcollateration when small redeem quantities are provided
            uint256 componentQuantity = _quantity.preciseMul(unit);

            // Instruct the SetToken to transfer the component to the user
            _setToken.strictInvokeTransfer(component, _to, componentQuantity);
        }

        emit SetTokenRedeemed(address(_setToken), msg.sender, _to, _quantity);
    }

    /**
     * Initializes this module to the SetToken with issuance-related hooks. Only callable by the SetToken's manager.
     * Hook addresses are optional. Address(0) means that no hook will be called
     *
     * @param _setToken             Instance of the SetToken to issue
     * @param _preIssueHook         Instance of the Manager Contract with the Pre-Issuance Hook function
     */
    function initialize(
        ISetToken _setToken,
        IManagerIssuanceHook _preIssueHook
    )
        external
        onlySetManager(_setToken, msg.sender)
        onlyValidAndPendingSet(_setToken)
    {
        managerIssuanceHook[_setToken] = _preIssueHook;

        _setToken.initializeModule();
    }

    /**
     * Reverts as this module should not be removable after added. Users should always
     * have a way to redeem their Sets
     */
    function removeModule() external override {
        revert("The BasicIssuanceModule module cannot be removed");
    }

    /* ============ External Getter Functions ============ */

    /**
     * Retrieves the addresses and units required to mint a particular quantity of SetToken.
     *
     * @param _setToken             Instance of the SetToken to issue
     * @param _quantity             Quantity of SetToken to issue
     * @return address[]            List of component addresses
     * @return uint256[]            List of component units required to issue the quantity of SetTokens
     */
    function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    )
        public
        view
        onlyValidAndInitializedSet(_setToken)
        returns (address[] memory, uint256[] memory)
    {
        address[] memory components = _setToken.getComponents();

        uint256[] memory notionalUnits = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            require(
                !_setToken.hasExternalPosition(components[i]),
                "Only default positions are supported"
            );

            notionalUnits[i] = _setToken
                .getDefaultPositionRealUnit(components[i])
                .toUint256()
                .preciseMulCeil(_quantity);
        }

        return (components, notionalUnits);
    }

    /* ============ Internal Functions ============ */

    /**
     * If a pre-issue hook has been configured, call the external-protocol contract. Pre-issue hook logic
     * can contain arbitrary logic including validations, external function calls, etc.
     */
    function _callPreIssueHooks(
        ISetToken _setToken,
        uint256 _quantity,
        address _caller,
        address _to
    ) internal returns (address) {
        IManagerIssuanceHook preIssueHook = managerIssuanceHook[_setToken];
        if (address(preIssueHook) != address(0)) {
            preIssueHook.invokePreIssueHook(_setToken, _quantity, _caller, _to);
            return address(preIssueHook);
        }

        return address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AddressArrayUtils} from "../lib/AddressArrayUtils.sol";
import {IController} from "../interfaces/IController.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IOracleAdapter} from "../interfaces/IOracleAdapter.sol";
import {PreciseUnitMath} from "../lib/PreciseUnitMath.sol";

/**
 * @title PriceOracle
 * @author Set Protocol
 *
 * Contract that returns the price for any given asset pair. Price is retrieved either directly from an oracle,
 * calculated using common asset pairs, or uses external data to calculate price.
 * Note: Prices are returned in preciseUnits (i.e. 18 decimals of precision)
 */
contract PriceOracle is Ownable {
    using PreciseUnitMath for uint256;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event PairAdded(
        address indexed _assetOne,
        address indexed _assetTwo,
        address _oracle
    );
    event PairRemoved(
        address indexed _assetOne,
        address indexed _assetTwo,
        address _oracle
    );
    event PairEdited(
        address indexed _assetOne,
        address indexed _assetTwo,
        address _newOracle
    );
    event AdapterAdded(address _adapter);
    event AdapterRemoved(address _adapter);
    event MasterQuoteAssetEdited(address _newMasterQuote);

    /* ============ State Variables ============ */

    // Address of the Controller contract
    IController public controller;

    // Mapping between assetA/assetB and its associated Price Oracle
    // Asset 1 -> Asset 2 -> IOracle Interface
    mapping(address => mapping(address => IOracle)) public oracles;

    // Token address of the bridge asset that prices are derived from if the specified pair price is missing
    address public masterQuoteAsset;

    // List of IOracleAdapters used to return prices of third party protocols (e.g. Uniswap, Compound, Balancer)
    address[] public adapters;

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     * @param _masterQuoteAsset       Address of asset that can be used to link unrelated asset pairs
     * @param _adapters               List of adapters used to price assets created by other protocols
     * @param _assetOnes              List of first asset in pair, index i maps to same index in assetTwos and oracles
     * @param _assetTwos              List of second asset in pair, index i maps to same index in assetOnes and oracles
     * @param _oracles                List of oracles, index i maps to same index in assetOnes and assetTwos
     */
    constructor(
        IController _controller,
        address _masterQuoteAsset,
        address[] memory _adapters,
        address[] memory _assetOnes,
        address[] memory _assetTwos,
        IOracle[] memory _oracles
    ) public {
        controller = _controller;
        masterQuoteAsset = _masterQuoteAsset;
        adapters = _adapters;
        require(
            _assetOnes.length == _assetTwos.length &&
                _assetTwos.length == _oracles.length,
            "Array lengths do not match."
        );

        for (uint256 i = 0; i < _assetOnes.length; i++) {
            oracles[_assetOnes[i]][_assetTwos[i]] = _oracles[i];
        }
    }

    /* ============ External Functions ============ */

    /**
     * SYSTEM-ONLY PRIVELEGE: Find price of passed asset pair, if possible. The steps it takes are:
     *  1) Check to see if a direct or inverse oracle of the pair exists,
     *  2) If not, use masterQuoteAsset to link pairs together (i.e. BTC/ETH and ETH/USDC
     *     could be used to calculate BTC/USDC).
     *  3) If not, check oracle adapters in case one or more of the assets needs external protocol data
     *     to price.
     *  4) If all steps fail, revert.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return                  Price of asset pair to 18 decimals of precision
     */
    function getPrice(
        address _assetOne,
        address _assetTwo
    ) external view returns (uint256) {
        require(
            controller.isSystemContract(msg.sender),
            "PriceOracle.getPrice: Caller must be system contract."
        );

        bool priceFound;
        uint256 price;

        (priceFound, price) = _getDirectOrInversePrice(_assetOne, _assetTwo);

        if (!priceFound) {
            (priceFound, price) = _getPriceFromMasterQuote(
                _assetOne,
                _assetTwo
            );
        }

        if (!priceFound) {
            (priceFound, price) = _getPriceFromAdapters(_assetOne, _assetTwo);
        }

        require(priceFound, "PriceOracle.getPrice: Price not found.");

        return price;
    }

    /**
     * GOVERNANCE FUNCTION: Add new asset pair oracle.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @param _oracle           Address of asset pair's oracle
     */
    function addPair(
        address _assetOne,
        address _assetTwo,
        IOracle _oracle
    ) external onlyOwner {
        require(
            address(oracles[_assetOne][_assetTwo]) == address(0),
            "PriceOracle.addPair: Pair already exists."
        );
        oracles[_assetOne][_assetTwo] = _oracle;

        emit PairAdded(_assetOne, _assetTwo, address(_oracle));
    }

    /**
     * GOVERNANCE FUNCTION: Edit an existing asset pair's oracle.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @param _oracle           Address of asset pair's new oracle
     */
    function editPair(
        address _assetOne,
        address _assetTwo,
        IOracle _oracle
    ) external onlyOwner {
        require(
            address(oracles[_assetOne][_assetTwo]) != address(0),
            "PriceOracle.editPair: Pair doesn't exist."
        );
        oracles[_assetOne][_assetTwo] = _oracle;

        emit PairEdited(_assetOne, _assetTwo, address(_oracle));
    }

    /**
     * GOVERNANCE FUNCTION: Remove asset pair's oracle.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     */
    function removePair(
        address _assetOne,
        address _assetTwo
    ) external onlyOwner {
        require(
            address(oracles[_assetOne][_assetTwo]) != address(0),
            "PriceOracle.removePair: Pair doesn't exist."
        );
        IOracle oldOracle = oracles[_assetOne][_assetTwo];
        delete oracles[_assetOne][_assetTwo];

        emit PairRemoved(_assetOne, _assetTwo, address(oldOracle));
    }

    /**
     * GOVERNANCE FUNCTION: Add new oracle adapter.
     *
     * @param _adapter         Address of new adapter
     */
    function addAdapter(address _adapter) external onlyOwner {
        require(
            !adapters.contains(_adapter),
            "PriceOracle.addAdapter: Adapter already exists."
        );
        adapters.push(_adapter);

        emit AdapterAdded(_adapter);
    }

    /**
     * GOVERNANCE FUNCTION: Remove oracle adapter.
     *
     * @param _adapter         Address of adapter to remove
     */
    function removeAdapter(address _adapter) external onlyOwner {
        require(
            adapters.contains(_adapter),
            "PriceOracle.removeAdapter: Adapter does not exist."
        );
        adapters = adapters.remove(_adapter);

        emit AdapterRemoved(_adapter);
    }

    /**
     * GOVERNANCE FUNCTION: Change the master quote asset.
     *
     * @param _newMasterQuoteAsset         New address of master quote asset
     */
    function editMasterQuoteAsset(
        address _newMasterQuoteAsset
    ) external onlyOwner {
        masterQuoteAsset = _newMasterQuoteAsset;

        emit MasterQuoteAssetEdited(_newMasterQuoteAsset);
    }

    /* ============ External View Functions ============ */

    /**
     * Returns an array of adapters
     */
    function getAdapters() external view returns (address[] memory) {
        return adapters;
    }

    /* ============ Internal Functions ============ */

    /**
     * Check if direct or inverse oracle exists. If so return that price along with boolean indicating
     * it exists. Otherwise return boolean indicating oracle doesn't exist.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return bool             Boolean indicating if oracle exists
     * @return uint256          Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getDirectOrInversePrice(
        address _assetOne,
        address _assetTwo
    ) internal view returns (bool, uint256) {
        IOracle directOracle = oracles[_assetOne][_assetTwo];
        bool hasDirectOracle = address(directOracle) != address(0);

        // Check asset1 -> asset 2. If exists, then return value
        if (hasDirectOracle) {
            return (true, directOracle.read());
        }

        IOracle inverseOracle = oracles[_assetTwo][_assetOne];
        bool hasInverseOracle = address(inverseOracle) != address(0);

        // If not, check asset 2 -> asset 1. If exists, then return 1 / asset1 -> asset2
        if (hasInverseOracle) {
            return (true, _calculateInversePrice(inverseOracle));
        }

        return (false, 0);
    }

    /**
     * Try to calculate asset pair price by getting each asset in the pair's price relative to master
     * quote asset. Both prices must exist otherwise function returns false and no price.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return bool             Boolean indicating if oracle exists
     * @return uint256          Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getPriceFromMasterQuote(
        address _assetOne,
        address _assetTwo
    ) internal view returns (bool, uint256) {
        (bool priceFoundOne, uint256 assetOnePrice) = _getDirectOrInversePrice(
            _assetOne,
            masterQuoteAsset
        );

        (bool priceFoundTwo, uint256 assetTwoPrice) = _getDirectOrInversePrice(
            _assetTwo,
            masterQuoteAsset
        );

        if (priceFoundOne && priceFoundTwo) {
            return (true, assetOnePrice.preciseDiv(assetTwoPrice));
        }

        return (false, 0);
    }

    /**
     * Scan adapters to see if one or more of the assets needs external protocol data to be priced. If
     * does not exist return false and no price.
     *
     * @param _assetOne         Address of first asset in pair
     * @param _assetTwo         Address of second asset in pair
     * @return bool             Boolean indicating if oracle exists
     * @return uint256          Price of asset pair to 18 decimal precision (if exists, otherwise 0)
     */
    function _getPriceFromAdapters(
        address _assetOne,
        address _assetTwo
    ) internal view returns (bool, uint256) {
        for (uint256 i = 0; i < adapters.length; i++) {
            (bool priceFound, uint256 price) = IOracleAdapter(adapters[i])
                .getPrice(_assetOne, _assetTwo);

            if (priceFound) {
                return (priceFound, price);
            }
        }

        return (false, 0);
    }

    /**
     * Calculate inverse price of passed oracle. The inverse price is 1 (or 1e18) / inverse price
     *
     * @param _inverseOracle        Address of oracle to invert
     * @return uint256              Inverted price of asset pair to 18 decimal precision
     */
    function _calculateInversePrice(
        IOracle _inverseOracle
    ) internal view returns (uint256) {
        uint256 inverseValue = _inverseOracle.read();

        return PreciseUnitMath.preciseUnit().preciseDiv(inverseValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {IController} from "../interfaces/IController.sol";
import {IModule} from "../interfaces/IModule.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";
import {Position} from "./lib/Position.sol";
import {PreciseUnitMath} from "../lib/PreciseUnitMath.sol";
import {AddressArrayUtils} from "../lib/AddressArrayUtils.sol";

/**
 * @title SetToken
 * @author Set Protocol
 *
 * ERC20 Token contract that allows privileged modules to make modifications to its positions and invoke function calls
 * from the SetToken.
 */
contract SetToken is ERC20 {
    using SafeMath for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for int256;
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Constants ============ */

    /*
        The PositionState is the status of the Position, whether it is Default (held on the SetToken)
        or otherwise held on a separate smart contract (whether a module or external source).
        There are issues with cross-usage of enums, so we are defining position states
        as a uint8.
    */
    uint8 internal constant DEFAULT = 0;
    uint8 internal constant EXTERNAL = 1;

    /* ============ Events ============ */

    event Invoked(
        address indexed _target,
        uint indexed _value,
        bytes _data,
        bytes _returnValue
    );
    event ModuleAdded(address indexed _module);
    event ModuleRemoved(address indexed _module);
    event ModuleInitialized(address indexed _module);
    event ManagerEdited(address _newManager, address _oldManager);
    event PendingModuleRemoved(address indexed _module);
    event PositionMultiplierEdited(int256 _newMultiplier);
    event ComponentAdded(address indexed _component);
    event ComponentRemoved(address indexed _component);
    event DefaultPositionUnitEdited(
        address indexed _component,
        int256 _realUnit
    );
    event ExternalPositionUnitEdited(
        address indexed _component,
        address indexed _positionModule,
        int256 _realUnit
    );
    event ExternalPositionDataEdited(
        address indexed _component,
        address indexed _positionModule,
        bytes _data
    );
    event PositionModuleAdded(
        address indexed _component,
        address indexed _positionModule
    );
    event PositionModuleRemoved(
        address indexed _component,
        address indexed _positionModule
    );
    event Lock(address indexed _locker, bool _isLocked);
    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not a SetToken's module or module not enabled
     */
    modifier onlyModule() {
        // Internal function used to reduce bytecode size
        _validateOnlyModule();
        _;
    }

    /**
     * Throws if the sender is not the SetToken's manager
     */
    modifier onlyManager() {
        _validateOnlyManager();
        _;
    }

    /**
     * Throws if SetToken is locked and called by any account other than the locker.
     */
    modifier whenLockedOnlyLocker() {
        _validateWhenLockedOnlyLocker();
        _;
    }

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    // The manager has the privelege to add modules, remove, and set a new manager
    address public manager;

    // A module that has locked other modules from privileged functionality, typically required
    // for multi-block module actions such as auctions
    address public locker;

    // List of initialized Modules; Modules extend the functionality of SetTokens
    address[] public modules;

    // Modules are initialized from NONE -> PENDING -> INITIALIZED through the
    // addModule (called by manager) and initialize  (called by module) functions
    mapping(address => ISetToken.ModuleState) public moduleStates;

    // When locked, only the locker (a module) can call privileged functionality
    // Typically utilized if a module (e.g. Auction) needs multiple transactions to complete an action
    // without interruption
    bool public isLocked;

    // List of components
    address[] public components;

    // Mapping that stores all Default and External position information for a given component.
    // Position quantities are represented as virtual units; Default positions are on the top-level,
    // while external positions are stored in a module array and accessed through its externalPositions mapping
    mapping(address => ISetToken.ComponentPosition) private componentPositions;

    // The multiplier applied to the virtual position unit to achieve the real/actual unit.
    // This multiplier is used for efficiently modifying the entire position units (e.g. streaming fee)
    int256 public positionMultiplier;

    /* ============ Constructor ============ */

    /**
     * When a new SetToken is created, initializes Positions in default state and adds modules into pending state.
     * All parameter validations are on the SetTokenCreator contract. Validations are performed already on the
     * SetTokenCreator. Initiates the positionMultiplier as 1e18 (no adjustments).
     *
     * @param _components             List of addresses of components for initial Positions
     * @param _units                  List of units. Each unit is the # of components per 10^18 of a SetToken
     * @param _modules                List of modules to enable. All modules must be approved by the Controller
     * @param _controller             Address of the controller
     * @param _manager                Address of the manager
     * @param _name                   Name of the SetToken
     * @param _symbol                 Symbol of the SetToken
     */
    constructor(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        IController _controller,
        address _manager,
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
        controller = _controller;
        manager = _manager;
        positionMultiplier = PreciseUnitMath.preciseUnitInt();
        components = _components;

        // Modules are put in PENDING state, as they need to be individually initialized by the Module
        for (uint256 i = 0; i < _modules.length; i++) {
            moduleStates[_modules[i]] = ISetToken.ModuleState.PENDING;
        }

        // Positions are put in default state initially
        for (uint256 j = 0; j < _components.length; j++) {
            componentPositions[_components[j]].virtualUnit = _units[j];
        }
    }

    /* ============ External Functions ============ */

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that allows a module to make an arbitrary function
     * call to any contract.
     *
     * @param _target                 Address of the smart contract to call
     * @param _value                  Quantity of Ether to provide the call (typically 0)
     * @param _data                   Encoded function selector and arguments
     * @return _returnValue           Bytes encoded return value
     */
    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyModule
        whenLockedOnlyLocker
        returns (bytes memory _returnValue)
    {
        _returnValue = _target.functionCallWithValue(_data, _value);

        emit Invoked(_target, _value, _data, _returnValue);

        return _returnValue;
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that adds a component to the components array.
     */
    function addComponent(
        address _component
    ) external onlyModule whenLockedOnlyLocker {
        require(!isComponent(_component), "Must not be component");

        components.push(_component);

        emit ComponentAdded(_component);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that removes a component from the components array.
     */
    function removeComponent(
        address _component
    ) external onlyModule whenLockedOnlyLocker {
        components.removeStorage(_component);

        emit ComponentRemoved(_component);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that edits a component's virtual unit. Takes a real unit
     * and converts it to virtual before committing.
     */
    function editDefaultPositionUnit(
        address _component,
        int256 _realUnit
    ) external onlyModule whenLockedOnlyLocker {
        int256 virtualUnit = _convertRealToVirtualUnit(_realUnit);

        componentPositions[_component].virtualUnit = virtualUnit;

        emit DefaultPositionUnitEdited(_component, _realUnit);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that adds a module to a component's externalPositionModules array
     */
    function addExternalPositionModule(
        address _component,
        address _positionModule
    ) external onlyModule whenLockedOnlyLocker {
        require(
            !isExternalPositionModule(_component, _positionModule),
            "Module already added"
        );

        componentPositions[_component].externalPositionModules.push(
            _positionModule
        );

        emit PositionModuleAdded(_component, _positionModule);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that removes a module from a component's
     * externalPositionModules array and deletes the associated externalPosition.
     */
    function removeExternalPositionModule(
        address _component,
        address _positionModule
    ) external onlyModule whenLockedOnlyLocker {
        componentPositions[_component].externalPositionModules.removeStorage(
            _positionModule
        );

        delete componentPositions[_component].externalPositions[
            _positionModule
        ];

        emit PositionModuleRemoved(_component, _positionModule);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that edits a component's external position virtual unit.
     * Takes a real unit and converts it to virtual before committing.
     */
    function editExternalPositionUnit(
        address _component,
        address _positionModule,
        int256 _realUnit
    ) external onlyModule whenLockedOnlyLocker {
        int256 virtualUnit = _convertRealToVirtualUnit(_realUnit);

        componentPositions[_component]
            .externalPositions[_positionModule]
            .virtualUnit = virtualUnit;

        emit ExternalPositionUnitEdited(_component, _positionModule, _realUnit);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Low level function that edits a component's external position data
     */
    function editExternalPositionData(
        address _component,
        address _positionModule,
        bytes calldata _data
    ) external onlyModule whenLockedOnlyLocker {
        componentPositions[_component]
            .externalPositions[_positionModule]
            .data = _data;

        emit ExternalPositionDataEdited(_component, _positionModule, _data);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Modifies the position multiplier. This is typically used to efficiently
     * update all the Positions' units at once in applications where inflation is awarded (e.g. subscription fees).
     */
    function editPositionMultiplier(
        int256 _newMultiplier
    ) external onlyModule whenLockedOnlyLocker {
        _validateNewMultiplier(_newMultiplier);

        positionMultiplier = _newMultiplier;

        emit PositionMultiplierEdited(_newMultiplier);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Increases the "account" balance by the "quantity".
     */
    function mint(
        address _account,
        uint256 _quantity
    ) external onlyModule whenLockedOnlyLocker {
        _mint(_account, _quantity);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Decreases the "account" balance by the "quantity".
     * _burn checks that the "account" already has the required "quantity".
     */
    function burn(
        address _account,
        uint256 _quantity
    ) external onlyModule whenLockedOnlyLocker {
        _burn(_account, _quantity);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. When a SetToken is locked, only the locker can call privileged functions.
     */
    function lock() external onlyModule {
        require(!isLocked, "Must not be locked");
        locker = msg.sender;
        isLocked = true;
        emit Lock(msg.sender, true);
    }

    /**
     * PRIVELEGED MODULE FUNCTION. Unlocks the SetToken and clears the locker
     */
    function unlock() external onlyModule {
        require(isLocked, "Must be locked");
        require(locker == msg.sender, "Must be locker");
        delete locker;
        isLocked = false;
        emit Lock(msg.sender, false);
    }

    /**
     * MANAGER ONLY. Adds a module into a PENDING state; Module must later be initialized via
     * module's initialize function
     */
    function addModule(address _module) external onlyManager {
        require(
            moduleStates[_module] == ISetToken.ModuleState.NONE,
            "Module must not be added"
        );
        require(controller.isModule(_module), "Must be enabled on Controller");

        moduleStates[_module] = ISetToken.ModuleState.PENDING;

        emit ModuleAdded(_module);
    }

    /**
     * MANAGER ONLY. Removes a module from the SetToken. SetToken calls removeModule on module itself to confirm
     * it is not needed to manage any remaining positions and to remove state.
     */
    function removeModule(address _module) external onlyManager {
        require(!isLocked, "Only when unlocked");
        require(
            moduleStates[_module] == ISetToken.ModuleState.INITIALIZED,
            "Module must be added"
        );

        IModule(_module).removeModule();

        moduleStates[_module] = ISetToken.ModuleState.NONE;

        modules.removeStorage(_module);

        emit ModuleRemoved(_module);
    }

    /**
     * MANAGER ONLY. Removes a pending module from the SetToken.
     */
    function removePendingModule(address _module) external onlyManager {
        require(!isLocked, "Only when unlocked");
        require(
            moduleStates[_module] == ISetToken.ModuleState.PENDING,
            "Module must be pending"
        );

        moduleStates[_module] = ISetToken.ModuleState.NONE;

        emit PendingModuleRemoved(_module);
    }

    /**
     * Initializes an added module from PENDING to INITIALIZED state. Can only call when unlocked.
     * An address can only enter a PENDING state if it is an enabled module added by the manager.
     * Only callable by the module itself, hence msg.sender is the subject of update.
     */
    function initializeModule() external {
        require(!isLocked, "Only when unlocked");
        require(
            moduleStates[msg.sender] == ISetToken.ModuleState.PENDING,
            "Module must be pending"
        );

        moduleStates[msg.sender] = ISetToken.ModuleState.INITIALIZED;
        modules.push(msg.sender);

        emit ModuleInitialized(msg.sender);
    }

    /**
     * MANAGER ONLY. Changes manager; We allow null addresses in case the manager wishes to wind down the SetToken.
     * Modules may rely on the manager state, so only changable when unlocked
     */
    function setManager(address _manager) external onlyManager {
        require(!isLocked, "Only when unlocked");
        address oldManager = manager;
        manager = _manager;

        emit ManagerEdited(_manager, oldManager);
    }

    /* ============ External Getter Functions ============ */

    function getComponents() external view returns (address[] memory) {
        return components;
    }

    function getDefaultPositionRealUnit(
        address _component
    ) public view returns (int256) {
        return
            _convertVirtualToRealUnit(_defaultPositionVirtualUnit(_component));
    }

    function getExternalPositionRealUnit(
        address _component,
        address _positionModule
    ) public view returns (int256) {
        return
            _convertVirtualToRealUnit(
                _externalPositionVirtualUnit(_component, _positionModule)
            );
    }

    function getExternalPositionModules(
        address _component
    ) external view returns (address[] memory) {
        return _externalPositionModules(_component);
    }

    function getExternalPositionData(
        address _component,
        address _positionModule
    ) external view returns (bytes memory) {
        return _externalPositionData(_component, _positionModule);
    }

    function getModules() external view returns (address[] memory) {
        return modules;
    }

    function isComponent(address _component) public view returns (bool) {
        return components.contains(_component);
    }

    function isExternalPositionModule(
        address _component,
        address _module
    ) public view returns (bool) {
        return _externalPositionModules(_component).contains(_module);
    }

    /**
     * Only ModuleStates of INITIALIZED modules are considered enabled
     */
    function isInitializedModule(address _module) external view returns (bool) {
        return moduleStates[_module] == ISetToken.ModuleState.INITIALIZED;
    }

    /**
     * Returns whether the module is in a pending state
     */
    function isPendingModule(address _module) external view returns (bool) {
        return moduleStates[_module] == ISetToken.ModuleState.PENDING;
    }

    /**
     * Returns a list of Positions, through traversing the components. Each component with a non-zero virtual unit
     * is considered a Default Position, and each externalPositionModule will generate a unique position.
     * Virtual units are converted to real units. This function is typically used off-chain for data presentation purposes.
     */
    function getPositions()
        external
        view
        returns (ISetToken.Position[] memory)
    {
        ISetToken.Position[] memory positions = new ISetToken.Position[](
            _getPositionCount()
        );
        uint256 positionCount = 0;

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];

            // A default position exists if the default virtual unit is > 0
            if (_defaultPositionVirtualUnit(component) > 0) {
                positions[positionCount] = ISetToken.Position({
                    component: component,
                    module: address(0),
                    unit: getDefaultPositionRealUnit(component),
                    positionState: DEFAULT,
                    data: ""
                });

                positionCount++;
            }

            address[] memory externalModules = _externalPositionModules(
                component
            );
            for (uint256 j = 0; j < externalModules.length; j++) {
                address currentModule = externalModules[j];

                positions[positionCount] = ISetToken.Position({
                    component: component,
                    module: currentModule,
                    unit: getExternalPositionRealUnit(component, currentModule),
                    positionState: EXTERNAL,
                    data: _externalPositionData(component, currentModule)
                });

                positionCount++;
            }
        }

        return positions;
    }

    /**
     * Returns the total Real Units for a given component, summing the default and external position units.
     */
    function getTotalComponentRealUnits(
        address _component
    ) external view returns (int256) {
        int256 totalUnits = getDefaultPositionRealUnit(_component);

        address[] memory externalModules = _externalPositionModules(_component);
        for (uint256 i = 0; i < externalModules.length; i++) {
            // We will perform the summation no matter what, as an external position virtual unit can be negative
            totalUnits = totalUnits.add(
                getExternalPositionRealUnit(_component, externalModules[i])
            );
        }

        return totalUnits;
    }

    receive() external payable {} // solium-disable-line quotes

    /* ============ Internal Functions ============ */

    function _defaultPositionVirtualUnit(
        address _component
    ) internal view returns (int256) {
        return componentPositions[_component].virtualUnit;
    }

    function _externalPositionModules(
        address _component
    ) internal view returns (address[] memory) {
        return componentPositions[_component].externalPositionModules;
    }

    function _externalPositionVirtualUnit(
        address _component,
        address _module
    ) internal view returns (int256) {
        return
            componentPositions[_component]
                .externalPositions[_module]
                .virtualUnit;
    }

    function _externalPositionData(
        address _component,
        address _module
    ) internal view returns (bytes memory) {
        return componentPositions[_component].externalPositions[_module].data;
    }

    /**
     * Takes a real unit and divides by the position multiplier to return the virtual unit. Negative units will
     * be rounded away from 0 so no need to check that unit will be rounded down to 0 in conversion.
     */
    function _convertRealToVirtualUnit(
        int256 _realUnit
    ) internal view returns (int256) {
        int256 virtualUnit = _realUnit.conservativePreciseDiv(
            positionMultiplier
        );

        // This check ensures that the virtual unit does not return a result that has rounded down to 0
        if (_realUnit > 0 && virtualUnit == 0) {
            revert("Real to Virtual unit conversion invalid");
        }

        // This check ensures that when converting back to realUnits the unit won't be rounded down to 0
        if (_realUnit > 0 && _convertVirtualToRealUnit(virtualUnit) == 0) {
            revert("Virtual to Real unit conversion invalid");
        }

        return virtualUnit;
    }

    /**
     * Takes a virtual unit and multiplies by the position multiplier to return the real unit
     */
    function _convertVirtualToRealUnit(
        int256 _virtualUnit
    ) internal view returns (int256) {
        return _virtualUnit.conservativePreciseMul(positionMultiplier);
    }

    /**
     * To prevent virtual to real unit conversion issues (where real unit may be 0), the
     * product of the positionMultiplier and the lowest absolute virtualUnit value (across default and
     * external positions) must be greater than 0.
     */
    function _validateNewMultiplier(int256 _newMultiplier) internal view {
        int256 minVirtualUnit = _getPositionsAbsMinimumVirtualUnit();

        require(
            minVirtualUnit.conservativePreciseMul(_newMultiplier) > 0,
            "New multiplier too small"
        );
    }

    /**
     * Loops through all of the positions and returns the smallest absolute value of
     * the virtualUnit.
     *
     * @return Min virtual unit across positions denominated as int256
     */
    function _getPositionsAbsMinimumVirtualUnit()
        internal
        view
        returns (int256)
    {
        // Additional assignment happens in the loop below
        uint256 minimumUnit = uint256(-1);

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];

            // A default position exists if the default virtual unit is > 0
            uint256 defaultUnit = _defaultPositionVirtualUnit(component)
                .toUint256();
            if (defaultUnit > 0 && defaultUnit < minimumUnit) {
                minimumUnit = defaultUnit;
            }

            address[] memory externalModules = _externalPositionModules(
                component
            );
            for (uint256 j = 0; j < externalModules.length; j++) {
                address currentModule = externalModules[j];

                uint256 virtualUnit = _absoluteValue(
                    _externalPositionVirtualUnit(component, currentModule)
                );
                if (virtualUnit > 0 && virtualUnit < minimumUnit) {
                    minimumUnit = virtualUnit;
                }
            }
        }

        return minimumUnit.toInt256();
    }

    /**
     * Gets the total number of positions, defined as the following:
     * - Each component has a default position if its virtual unit is > 0
     * - Each component's external positions module is counted as a position
     */
    function _getPositionCount() internal view returns (uint256) {
        uint256 positionCount;
        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];

            // Increment the position count if the default position is > 0
            if (_defaultPositionVirtualUnit(component) > 0) {
                positionCount++;
            }

            // Increment the position count by each external position module
            address[] memory externalModules = _externalPositionModules(
                component
            );
            if (externalModules.length > 0) {
                positionCount = positionCount.add(externalModules.length);
            }
        }

        return positionCount;
    }

    /**
     * Returns the absolute value of the signed integer value
     * @param _a Signed interger value
     * @return Returns the absolute value in uint256
     */
    function _absoluteValue(int256 _a) internal pure returns (uint256) {
        return _a >= 0 ? _a.toUint256() : (-_a).toUint256();
    }

    /**
     * Due to reason error bloat, internal functions are used to reduce bytecode size
     *
     * Module must be initialized on the SetToken and enabled by the controller
     */
    function _validateOnlyModule() internal view {
        require(
            moduleStates[msg.sender] == ISetToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    function _validateOnlyManager() internal view {
        require(msg.sender == manager, "Only manager can call");
    }

    function _validateWhenLockedOnlyLocker() internal view {
        if (isLocked) {
            require(
                msg.sender == locker,
                "When locked, only the locker can call"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IController} from "../interfaces/IController.sol";
import {SetToken} from "./SetToken.sol";
import {AddressArrayUtils} from "../lib/AddressArrayUtils.sol";

/**
 * @title SetTokenCreator
 * @author Set Protocol
 *
 * SetTokenCreator is a smart contract used to deploy new SetToken contracts. The SetTokenCreator
 * is a Factory contract that is enabled by the controller to create and register new SetTokens.
 */
contract SetTokenCreator {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event SetTokenCreated(
        address indexed _setToken,
        address _manager,
        string _name,
        string _symbol
    );

    /* ============ State Variables ============ */

    // Instance of the controller smart contract
    IController public controller;

    /* ============ Functions ============ */

    /**
     * @param _controller          Instance of the controller
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /**
     * Creates a SetToken smart contract and registers the SetToken with the controller. The SetTokens are composed
     * of positions that are instantiated as DEFAULT (positionState = 0) state.
     *
     * @param _components             List of addresses of components for initial Positions
     * @param _units                  List of units. Each unit is the # of components per 10^18 of a SetToken
     * @param _modules                List of modules to enable. All modules must be approved by the Controller
     * @param _manager                Address of the manager
     * @param _name                   Name of the SetToken
     * @param _symbol                 Symbol of the SetToken
     * @return address                Address of the newly created SetToken
     */
    function create(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        address _manager,
        string memory _name,
        string memory _symbol
    ) external returns (address) {
        require(_components.length > 0, "Must have at least 1 component");
        require(
            _components.length == _units.length,
            "Component and unit lengths must be the same"
        );
        require(
            !_components.hasDuplicate(),
            "Components must not have a duplicate"
        );
        require(_modules.length > 0, "Must have at least 1 module");
        require(_manager != address(0), "Manager must not be empty");

        for (uint256 i = 0; i < _components.length; i++) {
            require(
                _components[i] != address(0),
                "Component must not be null address"
            );
            require(_units[i] > 0, "Units must be greater than 0");
        }

        for (uint256 j = 0; j < _modules.length; j++) {
            require(controller.isModule(_modules[j]), "Must be enabled module");
        }

        // Creates a new SetToken instance
        SetToken setToken = new SetToken(
            _components,
            _units,
            _modules,
            controller,
            _manager,
            _name,
            _symbol
        );

        // Registers Set with controller
        controller.addSet(address(setToken));

        emit SetTokenCreated(address(setToken), _manager, _name, _symbol);

        return address(setToken);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {IController} from "../interfaces/IController.sol";
import {ISetToken} from "../interfaces/ISetToken.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {PreciseUnitMath} from "../lib/PreciseUnitMath.sol";
import {Position} from "./lib/Position.sol";
import {ResourceIdentifier} from "./lib/ResourceIdentifier.sol";

/**
 * @title SetValuer
 * @author Set Protocol
 *
 * Contract that returns the valuation of SetTokens using price oracle data used in contracts
 * that are external to the system.
 *
 * Note: Prices are returned in preciseUnits (i.e. 18 decimals of precision)
 */
contract SetValuer {
    using PreciseUnitMath for int256;
    using PreciseUnitMath for uint256;
    using Position for ISetToken;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Instance of the Controller contract
    IController public controller;

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ External Functions ============ */

    /**
     * Gets the valuation of a SetToken using data from the price oracle. Reverts
     * if no price exists for a component in the SetToken. Note: this works for external
     * positions and negative (debt) positions.
     *
     * Note: There is a risk that the valuation is off if airdrops aren't retrieved or
     * debt builds up via interest and its not reflected in the position
     *
     * @param _setToken        SetToken instance to get valuation
     * @param _quoteAsset      Address of token to quote valuation in
     *
     * @return                 SetToken valuation in terms of quote asset in precise units 1e18
     */
    function calculateSetTokenValuation(
        ISetToken _setToken,
        address _quoteAsset
    ) external view returns (uint256) {
        IPriceOracle priceOracle = controller.getPriceOracle();
        address masterQuoteAsset = priceOracle.masterQuoteAsset();
        address[] memory components = _setToken.getComponents();
        int256 valuation;

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            // Get component price from price oracle. If price does not exist, revert.
            uint256 componentPrice = priceOracle.getPrice(
                component,
                masterQuoteAsset
            );

            int256 aggregateUnits = _setToken.getTotalComponentRealUnits(
                component
            );

            // Normalize each position unit to preciseUnits 1e18 and cast to signed int
            uint256 unitDecimals = ERC20(component).decimals();
            uint256 baseUnits = 10 ** unitDecimals;
            int256 normalizedUnits = aggregateUnits.preciseDiv(
                baseUnits.toInt256()
            );

            // Calculate valuation of the component. Debt positions are effectively subtracted
            valuation = normalizedUnits
                .preciseMul(componentPrice.toInt256())
                .add(valuation);
        }

        if (masterQuoteAsset != _quoteAsset) {
            uint256 quoteToMaster = priceOracle.getPrice(
                _quoteAsset,
                masterQuoteAsset
            );
            valuation = valuation.preciseDiv(quoteToMaster.toInt256());
        }

        return valuation.toUint256();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @title ERC20Viewer
 *
 * Interfaces for fetching multiple ERC20 state in a single read
 */
contract ERC20Viewer {
    
    /**
     * @notice  Fetches token symbols names decimals for each tokenAddress
     * @dev     .
     * @param   _tokenAddresses  Addresses of ERC20 contracts
     */
    function batchFetchBaseInfos(address[] calldata _tokenAddresses) public view returns(string [] memory, string [] memory, uint8[] memory) {
        // Cache length of addresses to fetch 
        uint256 addressesCount = _tokenAddresses.length;
        // Instantiate output array in memory
        string [] memory symbols = new string[](addressesCount);
        string [] memory names = new string[](addressesCount);
        uint8[] memory decimals = new uint8[](addressesCount);
        for (uint256 i = 0; i < addressesCount; i++) {
            symbols[i] = ERC20(address(_tokenAddresses[i])).symbol();
            names[i] = ERC20(address(_tokenAddresses[i])).name();
            decimals[i] = ERC20(address(_tokenAddresses[i])).decimals();
        }
        return (symbols, names, decimals);
    }

    /*
     * Fetches token balances for each tokenAddress, tokenOwner pair
     *
     * @param  _tokenAddresses    Addresses of ERC20 contracts
     * @param  _ownerAddresses    Addresses of users sequential to tokenAddress
     * @return  uint256[]         Array of balances for each ERC20 contract passed in
     */
    function batchFetchBalancesOf(
        address[] calldata _tokenAddresses,
        address[] calldata _ownerAddresses
    )
        public
        view
        returns (uint256[] memory)
    {
        // Cache length of addresses to fetch balances for
        uint256 addressesCount = _tokenAddresses.length;

        // Instantiate output array in memory
        uint256[] memory balances = new uint256[](addressesCount);

        // Cycle through contract addresses array and fetching the balance of each for the owner
        for (uint256 i = 0; i < addressesCount; i++) {
            balances[i] = ERC20(address(_tokenAddresses[i])).balanceOf(_ownerAddresses[i]);
        }

        return balances;
    }

    /*
     * Fetches token allowances for each tokenAddress, tokenOwner tuple
     *
     * @param  _tokenAddresses      Addresses of ERC20 contracts
     * @param  _ownerAddresses      Addresses of owner sequential to tokenAddress
     * @param  _spenderAddresses    Addresses of spenders sequential to tokenAddress
     * @return  uint256[]           Array of allowances for each ERC20 contract passed in
     */
    function batchFetchAllowances(
        address[] calldata _tokenAddresses,
        address[] calldata _ownerAddresses,
        address[] calldata _spenderAddresses
    )
        public
        view
        returns (uint256[] memory)
    {
        // Cache length of addresses to fetch allowances for
        uint256 addressesCount = _tokenAddresses.length;

        // Instantiate output array in memory
        uint256[] memory allowances = new uint256[](addressesCount);

        // Cycle through contract addresses array and fetching the balance of each for the owner
        for (uint256 i = 0; i < addressesCount; i++) {
            allowances[i] = ERC20(address(_tokenAddresses[i])).allowance(_ownerAddresses[i], _spenderAddresses[i]);
        }

        return allowances;
    }
}