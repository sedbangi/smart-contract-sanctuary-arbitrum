/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

// UAPE - A one-stop launchpad for all upcoming Metaverse, AI and GameFi projects on Arbitrum.
// Telegram Portal: @UAPEOfficial

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
        // See: https://github.com/OpenZeppelin/x/sa/fe/ma/rs/pull/522
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
     * x_s_af_e/m_ar_s
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

contract UAPE is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping (address => bool) private _isSniper;
    mapping (address => bool) private _liquidityHolders;
   
    uint256 private startingSupply = 1_000_000_000; //1 Billion
   
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * 10**_decimalsMul;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "UAPE";
    string private _symbol = "UAPE";
    
    uint256 public _reflectFee = 0; // All taxes are divided by 100 for more accuracy.
    uint256 private _previousReflectFee = _reflectFee;
    uint256 private maxReflectFee = 10000;
    
    uint256 public _liquidityFee = 300; // All taxes are divided by 100 for more accuracy.
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private maxLiquidityFee = 10000;

    uint256 public _marketingFee = 400; // All taxes are divided by 100 for more accuracy.
    uint256 private _previousMarketingFee = _marketingFee;
    uint256 private maxMarketingFee = 10000;

    uint256 private masterTaxDivisor = 10000; // All tax calculations are divided by this number.

    IRouter02 public dexRouter;
    address public lpPair;

    // SUSHI ROUTER
    address private _routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    address public burnAddress = 0xFC5445951FF30f8b48B550FAF2c9052ACFeF1c20;
    address payable private _marketingWallet = payable(0xFC5445951FF30f8b48B550FAF2c9052ACFeF1c20);
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    // Max TX amount is 1% of the total supply.
    uint256 private maxTxPercent = 100; // Less fields to edit
    uint256 private maxTxDivisor = 10000;
    uint256 private _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    uint256 public maxTxAmountUI = (startingSupply * maxTxPercent) / maxTxDivisor; // Actual amount for UI's
    // Maximum wallet size is 1% of the total supply.
    uint256 private maxWalletPercent = 100; // Less fields to edit
    uint256 private maxWalletDivisor = 10000;
    uint256 private _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
    uint256 private _previousMaxWalletSize = _maxWalletSize;
    uint256 public maxWalletSizeUI = (startingSupply * maxWalletPercent) / maxWalletDivisor; // Actual amount for UI's
    // 0.05% of Total Supply
    uint256 private numTokensSellToAddToLiquidity = (_tTotal * 5) / 10000;

    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private immutable snipeBlockAmt;
    uint256 public snipersCaught = 0;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SniperCaught(address sniperAddress);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (uint256 _snipeBlockAmt) payable {
        _tOwned[_msgSender()] = _tTotal;
        _rOwned[_msgSender()] = _rTotal;

        // Set the amount of blocks to count a sniper.
        snipeBlockAmt = _snipeBlockAmt;

        IRouter02 _dexRouter = IRouter02(_routerAddress);
        lpPair = IFactoryV2(_dexRouter.factory())
            .createPair(address(this), _dexRouter.WETH());

        dexRouter = _dexRouter;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _liquidityHolders[owner()] = true;
        _isExcluded[address(this)] = true;
        _excluded.push(address(this));
        _isExcluded[owner()] = true;
        _excluded.push(owner());
        _isExcluded[burnAddress] = true;
        _excluded.push(burnAddress);
        _isExcluded[_marketingWallet] = true;
        _excluded.push(_marketingWallet);
        _isExcluded[lpPair] = true;
        _excluded.push(lpPair);

        // Approve the owner for PancakeSwap, timesaver.
        _approve(_msgSender(), _routerAddress, _tTotal);

        _isSniper[0xE4882975f933A199C92b5A925C9A8fE65d599Aa8] = true;
        _isSniper[0x86C70C4a3BC775FB4030448c9fdb73Dc09dd8444] = true;
        _isSniper[0xa4A25AdcFCA938aa030191C297321323C57148Bd] = true;
        _isSniper[0x20C00AFf15Bb04cC631DB07ee9ce361ae91D12f8] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transferBatch(address[] calldata recipients, uint256[] calldata amounts) public returns (bool) {
        require(recipients.length == amounts.length, 
        "Must be matching argument lengths");
        
        uint256 length = recipients.length;
        
        for (uint i = 0; i < length; i++) {
            require(transfer(recipients[i], amounts[i]));
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function setLPPair(address pair) external onlyOwner {
        lpPair = pair;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setSniperProtectionEnabled(bool enabled) external onlyOwner() {
        require(enabled != sniperProtection, "Already set.");
        sniperProtection = enabled;
    }
    
    function setTaxFeePercent(uint256 reflectFee) external onlyOwner() {
        require(reflectFee <= maxReflectFee); // Prevents owner from abusing fees.
        _reflectFee = reflectFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee <= maxLiquidityFee); // Prevents owner from abusing fees.
        _liquidityFee = liquidityFee;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        require(marketingFee <= maxMarketingFee); // Prevents owner from abusing fees.
        _marketingFee = marketingFee;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 10000); // Cannot set lower than 0.01%
        _maxTxAmount = _tTotal.mul(percent).div(divisor);
        maxTxAmountUI = startingSupply.mul(percent).div(divisor);
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner() {
        require(divisor <= 1000); // Cannot set lower than 0.1%
        _maxWalletSize = _tTotal.mul(percent).div(divisor);
        maxWalletSizeUI = startingSupply.mul(percent).div(divisor);
    }

    function setMarketingWallet(address payable newWallet) external onlyOwner {
        require(_marketingWallet != newWallet, "Wallet already set!");
        _marketingWallet = payable(newWallet);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != burnAddress
            && to != address(0)
            && from != address(this);
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
     //to recieve ETH from dexRouter when swaping
    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from
,        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_hasLimits(from, to))
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        if(_hasLimits(from, to)
            && to != _routerAddress 
            && to != lpPair
        ) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (!inSwapAndLiquify
            && to == lpPair
            && swapAndLiquifyEnabled
        ) {
            if (overMinTokenBalance) {
                contractTokenBalance = numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }
        }
        
        bool takeFee = true;
        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        if (_marketingFee + _liquidityFee == 0)
            return;
        uint256 toMarketing = contractTokenBalance.mul(_marketingFee).div(_marketingFee.add(_liquidityFee));
        uint256 toLiquify = contractTokenBalance.sub(toMarketing);

        // split the contract balance into halves
        uint256 half = toLiquify.div(2);
        uint256 otherHalf = toLiquify.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        uint256 toSwapForEth = half.add(toMarketing);
        swapTokensForEth(toSwapForEth);

        // how much ETH did we just swap into?
        uint256 fromSwap = address(this).balance.sub(initialBalance);
        uint256 liquidityBalance = fromSwap.mul(half).div(toSwapForEth);

        addLiquidity(otherHalf, liquidityBalance);

        emit SwapAndLiquify(half, liquidityBalance, otherHalf);

        _marketingWallet.transfer(fromSwap.sub(liquidityBalance));
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap lpPair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            burnAddress,
            block.timestamp
        );
    }

    function _tokenTransfer(address from, address to, uint256 amount,bool takeFee) private {
        // Failsafe, disable the whole system if needed.
        if (sniperProtection){
            // If sender is a sniper address, reject the transfer.
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            // Check if this is the liquidity adding tx to startup.
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                    if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                        revert("Only owner can transfer at this time.");
                    }
            } else {
                if (_liqAddBlock > 0 
                    && from == lpPair 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }
            }
        }

        if(!takeFee)
            removeAllFee();
        
        _finalizeTransfer(from, to, amount);
        
        if(!takeFee)
            restoreAllFee();
    }

    function _finalizeTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);  
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }

        if (tLiquidity > 0)
            _takeLiquidity(sender, tLiquidity);
        if (rFee > 0 || tFee > 0)
            _takeReflect(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }


    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeReflect(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity); // Transparency is the key to success.
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectFee).div(masterTaxDivisor);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee.add(_marketingFee)).div(masterTaxDivisor);
    }

    function removeAllFee() private {
        if(_reflectFee == 0 && _liquidityFee == 0) return;
        
        _previousReflectFee = _reflectFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;

        _reflectFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
    }
    
    function restoreAllFee() private {
        _reflectFee = _previousReflectFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
    }

    function withdrawETH (address payable recipient, uint256 amount) public onlyOwner {
        (bool succeed, bytes memory data) = recipient.call{value: amount}("");
        require(succeed, "Failed to withdraw ETH");
    }
}