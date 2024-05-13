/// SPDX-License-Identifier: MIT
/**
/// KvantCoin (KTC)
/// https://t.me/kvantcoin
/// https://twitter.com/kvantshop
/// https://kvant.shop/
*/
pragma solidity >=0.8.25;
/// 
import "./LiquidityBlock.sol";
import "./SwapBlock.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
/// 
contract KvantCoin is ERC20, LiquidityBlock, SwapBlock {
    using SafeMath for uint256;
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    ///
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    ///
    constructor(uint256 _totalSupply) ERC20("KvantCoin", "KTC") {
        _mint(msg.sender, _totalSupply);
    }
    ///
    function setRule(
        bool _limited, 
        address _uniswapV2Pair, 
        uint256 _maxHoldingAmount, 
        uint256 _minHoldingAmount
        ) external onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }
    ///
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
        ///
        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbid");
        }
    }
    ///
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
///
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
///
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
/// 
contract ERC20 is Ownable, IERC20, IERC20Metadata {
/// File @openzeppelin/contracts/token/ERC20/[email protected]
/// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)
    using SafeMath for uint256;
    ///
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    ///
    uint256 private _totalSupply;
    ///
    string private _name;
    string private _symbol;
    ///
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    ///
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    ///
    /**
     * @dev Returns the name of the token.
     */
    ///
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    ///
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    ///
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    ///
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    ///
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    ///
    /**
     * @dev See {IERC20-totalSupply}.
     */
    ///
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    ///
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
        ) public view virtual override returns (uint256) {
        return _balances[account];
    }
    ///
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    ///
    function transfer(
        address recipient, 
        uint256 amount)
         public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    ///
    /**
     * @dev See {IERC20-allowance}.
     */
    ///
    function allowance(
        address owner, 
        address spender
        ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    ///
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    ///
    function approve(
        address spender, 
        uint256 amount
        ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    ///
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
    ///
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        ///
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        ///
        return true;
    }
    ///
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
    ///
    function increaseAllowance(
        address spender, 
        uint256 addedValue
        ) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    ///
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
    ///
    function decreaseAllowance(
        address spender, 
        uint256 subtractedValue
        ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    ///
    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ///
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        ///
        _beforeTokenTransfer(sender, recipient, amount);
        ///
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        ///
        emit Transfer(sender, recipient, amount);
        ///
        _afterTokenTransfer(sender, recipient, amount);
    }
    ///
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    ///
    function _mint(
        address account, 
        uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        ///
        _beforeTokenTransfer(address(0), account, amount);
        ///
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        ///
        _afterTokenTransfer(address(0), account, amount);
    }
    ///
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
    ///
    function _burn(
        address account, 
        uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        ///
        _beforeTokenTransfer(account, address(0), amount);
        ///
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        ///
        emit Transfer(account, address(0), amount);
        ///
        _afterTokenTransfer(account, address(0), amount);
    }
    ///
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
    ///
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        ///
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    ///
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    ///
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    ///
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    ///
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
/// library SafeMath
library SafeMath {
    function add(
        uint256 a, 
        uint256 b
        ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    ///
    function sub(
        uint256 a, 
        uint256 b
        ) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    ///
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    ///
    function mul(
        uint256 a, 
        uint256 b
        ) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    ///
    function div(
        uint256 a, 
        uint256 b
        ) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    ///
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
/// contract SwapBlock
import "./Ownable.sol";
import "./SafeMath.sol";
///
contract SwapBlock is Ownable {
    using SafeMath for uint256;
    ///
    mapping(address=>bool) addressesLiquidity;
    mapping(address=>bool) addressesIgnoreTax;
    ///
    uint256[] private percentsTaxBuy;
    uint256[] private percentsTaxSell;
    uint256[] private percentsTaxTransfer;
    ///
    address[] private addressesTaxBuy;
    address[] private addressesTaxSell;
    address[] private addressesTaxTransfer;
    ///
    function getTaxSum(uint256[] memory _percentsTax) internal pure returns (uint256) {
        uint256 TaxSum = 0;
        for (uint i; i < _percentsTax.length; i++) {
            TaxSum = TaxSum.add(_percentsTax[i]);
        }
        return TaxSum;
    }
    ///
    function getPercentsTaxBuy() public view returns (uint256[] memory) {
        return percentsTaxBuy;
    }
    ///
    function getPercentsTaxSell() public view returns (uint256[] memory) {
        return percentsTaxSell;
    }
    ///
    function getPercentsTaxTransfer() public view returns (uint256[] memory) {
        return percentsTaxTransfer;
    }
    ///
    function getAddressesTaxBuy() public view returns (address[] memory) {
        return addressesTaxBuy;
    }
    ///
    function getAddressesTaxSell() public view returns (address[] memory) {
        return addressesTaxSell;
    }
    ///
    function getAddressesTaxTransfer() public view returns (address[] memory) {
        return addressesTaxTransfer;
    }
    ///
    function checkAddressLiquidity(address _addressLiquidity) external view returns (bool) {
        return addressesLiquidity[_addressLiquidity];
    }
    ///
    function addAddressLiquidity(address _addressLiquidity) public onlyOwner {
        addressesLiquidity[_addressLiquidity] = true;
    }
    ///
    function removeAddressLiquidity (address _addressLiquidity) public onlyOwner {
        addressesLiquidity[_addressLiquidity] = false;
    }
    ///
    function checkAddressIgnoreTax(address _addressIgnoreTax) external view returns (bool) {
        return addressesIgnoreTax[_addressIgnoreTax];
    }
    ///
    function addAddressIgnoreTax(address _addressIgnoreTax) public onlyOwner {
        addressesIgnoreTax[_addressIgnoreTax] = true;
    }
    ///
    function removeAddressIgnoreTax (address _addressIgnoreTax) public onlyOwner {
        addressesIgnoreTax[_addressIgnoreTax] = false;
    }
    ///
    function setTaxBuy(uint256[] memory _percentsTaxBuy, address[] memory _addressesTaxBuy) public onlyOwner {
        require(_percentsTaxBuy.length == _addressesTaxBuy.length, "_percentsTaxBuy.length != _addressesTaxBuy.length");
        ///
        uint256 TaxSum = getTaxSum(_percentsTaxBuy);
        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit
        ///
        percentsTaxBuy = _percentsTaxBuy;
        addressesTaxBuy = _addressesTaxBuy;
    }
    ///
    function setTaxSell(uint256[] memory _percentsTaxSell, address[] memory _addressesTaxSell) public onlyOwner {
        require(_percentsTaxSell.length == _addressesTaxSell.length, "_percentsTaxSell.length != _addressesTaxSell.length");
        ///
        uint256 TaxSum = getTaxSum(_percentsTaxSell);
        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit
        ///
        percentsTaxSell = _percentsTaxSell;
        addressesTaxSell = _addressesTaxSell;
    }
    ///
    function setTaxTransfer(uint256[] memory _percentsTaxTransfer, address[] memory _addressesTaxTransfer) public onlyOwner {
        require(_percentsTaxTransfer.length == _addressesTaxTransfer.length, "_percentsTaxTransfer.length != _addressesTaxTransfer.length");
        ///
        uint256 TaxSum = getTaxSum(_percentsTaxTransfer);
        require(TaxSum <= 20, "TaxSum > 20"); // Set the maximum tax limit
        ///
        percentsTaxTransfer = _percentsTaxTransfer;
        addressesTaxTransfer = _addressesTaxTransfer;
    }
    ///
    function showTaxBuy() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxBuy, addressesTaxBuy);
    }
    ///
    function showTaxSell() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxSell, addressesTaxSell);
    }
    ///
    function showTaxTransfer() public view returns (uint[] memory, address[] memory) {
        return (percentsTaxTransfer, addressesTaxTransfer);
    }
    ///
    function showTaxBuySum() public view returns (uint) {
        return getTaxSum(percentsTaxBuy);
    }
    ///
    function showTaxSellSum() public view returns (uint) {
        return getTaxSum(percentsTaxSell);
    }
    ///
    function showTaxTransferSum() public view returns (uint) {
        return getTaxSum(percentsTaxTransfer);
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
///
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
/// contract LiquidityBlock
contract LiquidityBlock is Ownable {
    using SafeMath for uint256;
    receive() external payable {}
    fallback() external payable {}
    ///
    function addFirstLiquidity(address _addressSwapV2Router) public onlyOwner {
        address addressToken = address(this);
        uint256 amountTokens = IERC20(address(this)).balanceOf(address(this));
        uint256 amountETH = address(this).balance;
        ///
        require(IERC20(addressToken).approve(_addressSwapV2Router, amountTokens), "approve failed");
        IUniswapV2Router02(_addressSwapV2Router).addLiquidityETH{value: amountETH}(
            addressToken,
            amountTokens,
            amountTokens,
            amountETH,
            msg.sender,
            block.timestamp
        );
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
/// File @openzeppelin/contracts/access/[email protected]
/// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
import "./Context.sol";
///
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
 ///
abstract contract Ownable is Context {
    address private _owner;
    ///
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    ///
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }
    ///
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    ///
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    ///
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
    ///
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    ///
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

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
///
interface IUniswapV2Router02 {
/// interface IUniswapV2Router01
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    ///
    function factory() external pure returns (address);
    ///
    function WETH() external pure returns (address);
    ///
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
///
interface IERC20 {
//  File @openzeppelin/contracts/token/ERC20/[email protected]
/// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    ///
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(
        address account
        ) external view returns (uint256);
    ///
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient, 
        uint256 amount
        ) external returns (bool);
    ///
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner, 
        address spender
        ) external view returns (uint256);
    ///
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     */
    function approve(
        address spender, 
        uint256 amount
        ) external returns (bool);
    ///
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
    ///
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value);
    ///
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint256 value);
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
///
import "./IERC20.sol";
///
interface IERC20Metadata is IERC20 {
// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]
/// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);
    ///
    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
    ///
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
/// 
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
///
abstract contract Context {
/// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    ///
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}