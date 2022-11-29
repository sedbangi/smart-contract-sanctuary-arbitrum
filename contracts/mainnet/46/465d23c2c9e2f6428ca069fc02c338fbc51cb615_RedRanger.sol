/**
 *Submitted for verification at Arbiscan on 2022-11-29
*/

// File: RedRanger.sol



// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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



// File: @openzeppelin/contracts/token/ERC20/IERC20.sol





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



// File: @openzeppelin/contracts/utils/Context.sol





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



// File: @openzeppelin/contracts/access/Ownable.sol





// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)



pragma solidity ^0.8.0;





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



// File: contracts/3_Ballot.sol



//SPDX-License-Identifier: MIT



pragma solidity ^0.8.14;









contract RedRanger is IERC20, Ownable {

    using SafeMath for uint256;





    string constant _name = "RedRanger";

    string constant _symbol = "RRR";

    uint8 constant _decimals = 9;



    uint256 _totalSupply = 100000000 * (10**_decimals);



    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;



    mapping(address => bool) isFeeExempt;

    // allowed users to do transactions before trading enable

    mapping(address => bool) isAuthorized;

    mapping(address => bool) pairs;



    // buy fees

    uint256 public buyMarketingFee = 3;

    uint256 public buyBuyBackFee = 3;

    // sell fees

    uint256 public sellMarketingFee = 3;

    uint256 public selBuyBackFee = 3;



    address public marketingFeeReceiver =

        0xef4e443b473A5E5a2579bd6524F57b3E8425D966;

    address public buyBackFeeReceiver =

        0xef4e443b473A5E5a2579bd6524F57b3E8425D966;



    bool public tradingOpen = false;



    constructor() {



        address deployer = 0xef4e443b473A5E5a2579bd6524F57b3E8425D966;

        isFeeExempt[deployer] = true;



        isAuthorized[deployer] = true;



        _balances[deployer] = _totalSupply;



        transferOwnership(deployer);

        emit Transfer(address(0), deployer, _totalSupply);

    }



    receive() external payable {}



    function totalSupply() external view override returns (uint256) {

        return _totalSupply;

    }



    function name() public pure returns (string memory) {

        return _name;

    }



    function symbol() public pure returns (string memory) {

        return _symbol;

    }



    function decimals() public pure returns (uint8) {

        return _decimals;

    }



    function currentBalance() public view returns (uint256) {

        return address(this).balance;

    }



    function balanceOf(address account) public view override returns (uint256) {

        return _balances[account];

    }



    function allowance(address holder, address spender)

        external

        view

        override

        returns (uint256)

    {

        return _allowances[holder][spender];

    }



    function approve(address spender, uint256 amount)

        public

        override

        returns (bool)

    {

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;

    }



    function _approve(

        address owner,

        address spender,

        uint256 amount

    ) internal virtual {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");



        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }



    function approveMax(address spender) external returns (bool) {

        return approve(spender, type(uint256).max);

    }



    function transfer(address recipient, uint256 amount)

        external

        override

        returns (bool)

    {

        return _transferFrom(msg.sender, recipient, amount);

    }



    function transferFrom(

        address sender,

        address recipient,

        uint256 amount

    ) external override returns (bool) {

        if (_allowances[sender][msg.sender] != type(uint256).max) {

            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]

                .sub(amount, "Insufficient Allowance");

        }



        return _transferFrom(sender, recipient, amount);

    }



    function _transferFrom(

        address sender,

        address recipient,

        uint256 amount

    ) internal returns (bool) {

        if (!isAuthorized[sender]) {

            require(tradingOpen, "Trading not open yet");

        }



        //Exchange tokens

        _balances[sender] = _balances[sender].sub(

            amount,

            "Insufficient Balance"

        );



        uint256 amountReceived = shouldTakeFee(sender, recipient)

            ? takeFee(sender, amount, recipient)

            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);



        emit Transfer(sender, recipient, amountReceived);

        return true;

    }



    function _basicTransfer(

        address sender,

        address recipient,

        uint256 amount

    ) internal returns (bool) {

        _balances[sender] = _balances[sender].sub(

            amount,

            "Insufficient Balance"

        );

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);

        return true;

    }



    function shouldTakeFee(address sender, address to)

        internal

        view

        returns (bool)

    {

        if (isFeeExempt[sender] || isFeeExempt[to]) {

            return false;

        } else {

            return true;

        }

    }



    function takeFee(

        address sender,

        uint256 amount,

        address to

    ) internal returns (uint256) {

        uint256 marketingFee = 0;

        uint256 buyBackFee = 0;



        if (pairs[to]) {

            marketingFee = amount.mul(buyMarketingFee).div(100);

            buyBackFee = amount.mul(buyBuyBackFee).div(100);

        } else {

            marketingFee = amount.mul(sellMarketingFee).div(100);

            buyBackFee = amount.mul(selBuyBackFee).div(100);

        }

        if (marketingFee > 0) {

            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver]

                .add(marketingFee);

            emit Transfer(sender, marketingFeeReceiver, marketingFee);

        }



        if (buyBackFee > 0) {

            _balances[buyBackFeeReceiver] = _balances[buyBackFeeReceiver].add(

                buyBackFee

            );

            emit Transfer(sender, buyBackFeeReceiver, buyBackFee);

        }



        return amount.sub(marketingFee).sub(buyBackFee);

    }



    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {

        uint256 amountBNB = address(this).balance;

        payable(msg.sender).transfer((amountBNB * amountPercentage) / 100);

    }



    function updateBuyFees(uint256 marketing, uint256 buyBack)

        public

        onlyOwner

    {

        buyMarketingFee = marketing;

        buyBuyBackFee = buyBack;

    }



    function updateSellFees(uint256 marketing, uint256 buyBack)

        public

        onlyOwner

    {

        sellMarketingFee = marketing;

        selBuyBackFee = buyBack;

    }



    // switch Trading

    function enableTrading() public onlyOwner {

        tradingOpen = true;

    }



    function whitelistPreSale(address _preSale) public onlyOwner {

        isFeeExempt[_preSale] = true;

        isAuthorized[_preSale] = true;

    }



    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {

        isFeeExempt[holder] = exempt;

    }



    function changeMarketingWallet(address _marketingFeeReceiver)

        external

        onlyOwner

    {

        marketingFeeReceiver = _marketingFeeReceiver;

    }



    function changeBuyBackWallet(address newWallet) external onlyOwner {

        buyBackFeeReceiver = newWallet;

    }



    function addPair(address _pai, bool _status) external onlyOwner {

        pairs[_pai] = _status;

    }

}