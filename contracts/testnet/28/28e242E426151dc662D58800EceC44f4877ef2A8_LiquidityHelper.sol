// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPYESwapRouter } from "./interfaces/IPYESwapRouter.sol";
import { IPYESwapFactory } from "./interfaces/IPYESwapFactory.sol";

contract LiquidityHelper is Ownable {

    address public a = 0x9a7ea1928081FDBA6Bc94E94cF71FE70159DB0e2;
    address public b = 0x3fCddd5F101A8f624102d4409fe0E4B7d411F868;
    address public c = 0xE42AE6F6e9938E84a75C3Fd4740D40899759B37c;
    address public w = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3;

    address public pairA;
    address public pairB;
    address public pairC;
    address public pairAB;

    receive() external payable {}

    function add(address router, address factory) external onlyOwner {
        require(pairA == address(0));
        require(pairB == address(0));
        require(pairC == address(0));
        require(pairAB == address(0));
        IERC20(a).approve(router, 20000 ether);
        IERC20(b).approve(router, 20000 ether);
        IERC20(c).approve(router, 1000 ether);

        IPYESwapRouter(router).addLiquidityETH{ value: 1 ether }(
            a, 
            address(0), 
            10000 ether, 
            10000 ether, 
            1 ether, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairA = IPYESwapFactory(factory).getPair(a, w);
        IPYESwapRouter(router).addLiquidityETH{ value: 1 ether }(
            b, 
            address(0), 
            10000 ether, 
            10000 ether, 
            1 ether, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairB = IPYESwapFactory(factory).getPair(b, w);
        IPYESwapRouter(router).addLiquidityETH{ value: 1 ether }(
            c, 
            c, 
            1000 ether, 
            1000 ether, 
            1 ether, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairC = IPYESwapFactory(factory).getPair(c, w);
        IPYESwapRouter(router).addLiquidity(
            a, 
            b,
            address(0), 
            10000 ether, 
            10000 ether, 
            10000 ether, 
            10000 ether, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairAB = IPYESwapFactory(factory).getPair(a, b);
    }

    function remove(address router) external onlyOwner {
        uint256 liqA = IERC20(pairA).balanceOf(address(this));
        IERC20(pairA).approve(router, liqA);
        uint256 liqB = IERC20(pairB).balanceOf(address(this));
        IERC20(pairB).approve(router, liqB);
        uint256 liqC = IERC20(pairC).balanceOf(address(this));
        IERC20(pairC).approve(router, liqC);
        uint256 liqAB = IERC20(pairAB).balanceOf(address(this));
        IERC20(pairAB).approve(router, liqAB);

        IPYESwapRouter(router).removeLiquidityETH(
            a, 
            liqA, 
            0, 
            0, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairA = address(0);
        IPYESwapRouter(router).removeLiquidityETH(
            b, 
            liqB, 
            0, 
            0, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairB = address(0);
        IPYESwapRouter(router).removeLiquidityETH(
            c, 
            liqC, 
            0, 
            0, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairC = address(0);
        IPYESwapRouter(router).removeLiquidity(
            a, 
            b,
            liqAB, 
            0, 
            0, 
            address(this), 
            block.timestamp + 10 minutes
        );
        pairAB = address(0);
    }

    function withdrawETH() external onlyOwner {
        uint256 bal = address(this).balance;
        (bool success, ) = msg.sender.call{ value: bal }("");
        require(success);
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 bal = token.balanceOf(address(this));
        token.transfer(msg.sender, bal);
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPYESwapFactory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(
        address tokenA, 
        address tokenB, 
        bool supportsTokenFee, 
        address feeTaker
    ) external returns (
        address pair
    );

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function routerInitialize(address) external;

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function pairExist(address pair) external view returns (bool);

    function routerAddress() external view returns (address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IPYESwapRouter01 } from "./IPYESwapRouter01.sol";

interface IPYESwapRouter is IPYESwapRouter01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
pragma solidity 0.8.16;

interface IPYESwapRouter01 {

    function addLiquidity(
        address tokenA,
        address tokenB,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        address feeTaker,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

    function getAmountsOut(
        uint256 amountIn, 
        address[] calldata path, 
        uint totalFee
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut, 
        address[] calldata path, 
        uint totalFee
    ) external view returns (uint256[] memory amounts);

    function factory() external view returns (address);

    function WETH() external view returns (address);

    function stables(address token) external view returns (bool);

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