// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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
pragma solidity ^0.8.17;

import { DiamondOwnable } from "../helpers/DiamondOwnable.sol";
import { DiamondAccessControl } from "../helpers/DiamondAccessControl.sol";

// Library imports
import { LibCreditUtils } from "../libraries/LibCreditUtils.sol";

//interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Storage imports
import { WithModifiers } from "../libraries/LibStorage.sol";
import { Errors } from "../helpers/Errors.sol";

contract BGCreditAdminFacet is WithModifiers {
    event CreditTypeSet(uint256 creditTypeId, bool state);
    event GFlyPerCreditSet(uint256 amount);
    event MagicPerCreditSet(uint256 amount);
    event TreasuresPerCreditSet(uint256 amount);
    event MagicForLPWithdrawn(uint256 amount);
    event GFlyForLPWithdrawn(uint256 amount);
    event MagicForLPAdded(uint256 amount);
    event GFlyForLPAdded(uint256 amount);
    event LiquidityAdded(uint56 liquidity, uint256 providedMagic, uint256 providedGFly);

    /**
     * @dev Sets the credit types eligible for credit creations given:
     * A list of credit type IDs
     * A list of states (true/false)
     */
    function setCreditTypes(uint256[] memory creditTypeIds, bool[] memory states) external onlyOwner {
        if (creditTypeIds.length != states.length) revert Errors.InvalidArrayLength();
        for (uint256 i = 0; i < creditTypeIds.length; i++) {
            gs().creditTypes[creditTypeIds[i]] = states[i];
            emit CreditTypeSet(creditTypeIds[i], states[i]);
        }
    }

    /**
     * @dev Sets the amount of gFLY to be used when creating a credit
     */
    function setGFlyPerCredit(uint256 amount) external onlyOwner {
        gs().gFlyPerCredit = amount;
        emit GFlyPerCreditSet(amount);
    }

    /**
     * @dev Sets the amount of Magic to be used when creating a credit
     */
    function setMagicPerCredit(uint256 amount) external onlyOwner {
        gs().magicPerCredit = amount;
        emit MagicPerCreditSet(amount);
    }

    /**
     * @dev Sets the amount of Treasures to be used when creating a credit
     */
    function setTreasuresPerCredit(uint256 amount) external onlyOwner {
        gs().treasuresPerCredit = amount;
        emit TreasuresPerCreditSet(amount);
    }

    /**
     * @dev Removes Magic reserved for automatic LP providing
     */
    function removeMagicForLp(uint256 amount) external onlyOwner {
        if (amount > gs().magicForLp) revert Errors.InsufficientMagicForLpAmount();
        gs().magicForLp -= amount;
        IERC20(gs().magic).transfer(msg.sender, amount);
        emit MagicForLPWithdrawn(amount);
    }

    /**
     * @dev Removes gFLY reserved for automatic LP providing
     */
    function removeGFlyForLp(uint256 amount) external onlyOwner {
        if (amount > gs().gFlyForLp) revert Errors.InsufficientGFlyForLpAmount();
        gs().gFlyForLp -= amount;
        IERC20(gs().gFLY).transfer(msg.sender, amount);
        emit GFlyForLPWithdrawn(amount);
    }

    /**
     * @dev Adds magic reserved for automatic LP providing
     */
    function addMagicForLp(uint256 amount) external {
        IERC20(gs().magic).transferFrom(msg.sender, address(this), amount);
        gs().magicForLp += amount;
        emit MagicForLPAdded(amount);
    }

    /**
     * @dev Adds gFLY reserved for automatic LP providing
     */
    function addGFlyForLp(uint256 amount) external {
        IERC20(gs().gFLY).transferFrom(msg.sender, address(this), amount);
        gs().gFlyForLp += amount;
        emit GFlyForLPAdded(amount);
    }

    /**
     * @dev Sets the Magic/gFLY LP receiver address
     */
    function setLpReceiver(address lpReceiver) external onlyOwner {
        if (lpReceiver == address(0)) revert Errors.InvalidAddress();
        gs().lpReceiver = lpReceiver;
    }

    /**
     * @dev Sets the gFLY treshold for LP swaps
     */
    function setgFlyLpTreshold(uint256 gFlyLpTreshold) external onlyOwner {
        gs().gFlyLpTreshold = gFlyLpTreshold;
    }

    /**
     * @dev Sets the Magic treshold for LP swaps
     */
    function setMagicLpTreshold(uint256 magicLpTreshold) external onlyOwner {
        gs().magicLpTreshold = magicLpTreshold;
    }

    /**
     * @dev Sets the BPS denominator
     */
    function setBPSDenominator(uint256 bpsDenominator) external onlyOwner {
        gs().bpsDenominator = bpsDenominator;
    }

    /**
     * @dev Sets the slippage in BPS
     */
    function setSlippageInBPS(uint256 slippageInBPS) external onlyOwner {
        gs().slippageInBPS = slippageInBPS;
    }

    /**
     * @dev Automatically swap Magic and gFLY into LP tokens if the Magic and/or gFLY tresholds are reached.
     * LP tokens are sent to the LP Receiver address
     */
    function swapToLP() external onlyBattleflyBot {
        LibCreditUtils.swapToLP();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import { DiamondOwnable } from "./DiamondOwnable.sol";
import { WithStorage } from "../libraries/LibStorage.sol";

contract DiamondAccessControl is WithStorage, DiamondOwnable {
    function setGuardian(address account, bool state) external onlyOwner {
        gs().guardian[account] = state;
    }

    function isGuardian(address account) external view returns (bool) {
        return gs().guardian[account];
    }

    function setBattleflyBot(address account) external onlyOwner {
        gs().battleflyBot = account;
    }

    function isBattleflyBot(address account) external view returns (bool) {
        return (gs().battleflyBot == account);
    }

    function setSigner(address account, bool state) external onlyOwner {
        gs().signer[account] = state;
    }

    function isSigner(address account) external view returns (bool) {
        return gs().signer[account];
    }

    function setEmissionDepositor(address account, bool state) external onlyOwner {
        gs().emissionDepositor[account] = state;
    }

    function isEmissionDepositor(address account) external view returns (bool) {
        return gs().emissionDepositor[account];
    }

    function setBackendExecutor(address account, bool state) external onlyOwner {
        gs().backendExecutor[account] = state;
    }

    function isBackendExecutor(address account) external view returns (bool) {
        return gs().backendExecutor[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibDiamond } from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import { WithModifiers } from "../libraries/LibStorage.sol";

contract DiamondOwnable is IERC173, WithModifiers {
    function transferOwnership(address account) external onlyOwner {
        LibDiamond.setContractOwner(account);
    }

    function owner() external view override returns (address) {
        return LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Errors {
    error NotGuardian();
    error GamePaused();
    error GameAlreadyUnPaused();
    error UnsupportedCreditType();
    error InvalidArrayLength();
    error IncorrectTreasuresAmount();
    error InvalidAmount();
    error UnsupportedPaymentType();
    error InvalidAddress();
    error InsufficientMagicForLpAmount();
    error InsufficientGFlyForLpAmount();
    error IdenticalAddresses();
    error NotBattleflyBot();

    error NotSoulbound();
    error IncorrectSigner(address signer);
    error NotOwnerOfBattlefly(address account, uint256 tokenId, uint256 tokenType);
    error InvalidTokenType(uint256 tokenId, uint256 tokenType);

    error InvalidEpoch(uint256 epoch, uint256 emissionsEpoch);
    error InvalidProof(bytes32[] merkleProof, bytes32 merkleRoot, bytes32 node);
    error NotEmissionDepositor();

    error NotBackendExecutor();

    error InvalidCurrency();
    error InvalidEthAmount();
    error EthTransferFailed();

    error NotGameV2();
    error InsufficientAmount();
    error SequencerDown();
    error GracePeriodNotOver();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// Storage imports
import { LibStorage, BattleflyGameStorage, PaymentType } from "./LibStorage.sol";
import { Errors } from "../helpers/Errors.sol";

//interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IUniswapV2Router02 } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

library LibCreditUtils {
    event LiquidityAdded(uint256 liquidity, uint256 providedMagic, uint256 providedGFly);

    function gs() internal pure returns (BattleflyGameStorage storage) {
        return LibStorage.gameStorage();
    }

    // create credits
    function createCredit(
        uint256 creditType,
        uint256 amount,
        PaymentType paymentType,
        uint256[] memory treasureIds,
        uint256[] memory treasureAmounts
    ) internal {
        if (amount < 1) revert Errors.InvalidAmount();
        if (!gs().creditTypes[creditType]) revert Errors.UnsupportedCreditType();
        LibCreditUtils.transferFunds(amount, paymentType, treasureIds, treasureAmounts);
    }

    // Upgrade inventory slots
    function upgradeInventorySlot(
        uint256 amount,
        PaymentType paymentType,
        uint256[] memory treasureIds,
        uint256[] memory treasureAmounts
    ) internal {
        if (amount < 1) revert Errors.InvalidAmount();
        LibCreditUtils.transferFunds(amount, paymentType, treasureIds, treasureAmounts);
    }

    // Transfer funds depending on payment type
    function transferFunds(
        uint256 amount,
        PaymentType paymentType,
        uint256[] memory treasureIds,
        uint256[] memory treasureAmounts
    ) internal {
        if (paymentType == PaymentType.TREASURES) {
            //In case of upgrade with Treasures
            LibCreditUtils.processTreasuresPayment(amount, treasureIds, treasureAmounts);
        } else if (paymentType == PaymentType.MAGIC) {
            //In case of upgrade with Magic
            LibCreditUtils.processMagicPayment(amount);
        } else if (paymentType == PaymentType.GFLY) {
            //In case of upgrade with gFLY
            LibCreditUtils.processGFlyPayment(amount);
        } else {
            revert Errors.UnsupportedPaymentType();
        }
    }

    // Process payments with Magic
    function processMagicPayment(uint256 amount) internal {
        uint256 requiredMagic = amount * gs().magicPerCredit;
        IERC20(gs().magic).transferFrom(msg.sender, address(this), requiredMagic);
        gs().magicForLp += requiredMagic;
    }

    // Process payments with gFLY
    function processGFlyPayment(uint256 amount) internal {
        uint256 requiredGFly = amount * gs().gFlyPerCredit;
        IERC20(gs().gFLY).transferFrom(msg.sender, address(this), requiredGFly);
        gs().gFlyForLp += requiredGFly;
    }

    // Process payments with treasures
    function processTreasuresPayment(
        uint256 amount,
        uint256[] memory treasureIds,
        uint256[] memory treasureAmounts
    ) internal {
        if (treasureIds.length != treasureAmounts.length) revert Errors.InvalidArrayLength();
        uint256 requiredTreasures = amount * gs().treasuresPerCredit;
        uint256 receivedTreasures;
        for (uint256 i = 0; i < treasureAmounts.length; i++) {
            receivedTreasures += treasureAmounts[i];
        }
        if (requiredTreasures != receivedTreasures) revert Errors.IncorrectTreasuresAmount();
        IERC1155(gs().treasures).safeBatchTransferFrom(
            msg.sender,
            gs().treasureReceiver,
            treasureIds,
            treasureAmounts,
            "0x0"
        );
    }

    // Automatically swap Magic and gFLY into LP tokens if the Magic and/or gFLY tresholds are reached.
    // LP tokens are sent to the LP Receiver address
    function swapToLP() internal {
        (uint256 reserveMagic, uint256 reserveGFly) = LibCreditUtils.getReserves();
        uint256 magicAmount;
        uint256 gFLYAmount;
        uint256 magicForLp = gs().magicForLp;
        uint256 gFlyForLp = gs().gFlyForLp;
        // Check if we reached the Magic treshold for swaps into LP tokens
        if (magicForLp > 0 && magicForLp >= gs().magicLpTreshold) {
            gFLYAmount = IUniswapV2Router02(gs().magicSwapRouter).quote(magicForLp, reserveMagic, reserveGFly);
            magicAmount = magicForLp;
        }
        // Try another quote for the gFLY token if the gFLY treshold is reached for swaps into LP tokens and
        // the initially proposed quote is not enough to cover it.
        if (gFLYAmount > gFlyForLp && gFlyForLp > 0 && gFlyForLp >= gs().gFlyLpTreshold) {
            magicAmount = IUniswapV2Router02(gs().magicSwapRouter).quote(gFlyForLp, reserveGFly, reserveMagic);
            gFLYAmount = gFlyForLp;
        }
        // Check if we have enough Magic and gFLY to cover the proposed amounts
        if (magicAmount > 0 && gFLYAmount > 0 && magicAmount <= magicForLp && gFLYAmount <= gFlyForLp) {
            IERC20(gs().magic).approve(gs().magicSwapRouter, magicAmount);
            IERC20(gs().gFLY).approve(gs().magicSwapRouter, gFLYAmount);
            uint256 minMagic = (magicAmount * (gs().bpsDenominator - gs().slippageInBPS)) / gs().bpsDenominator;
            uint256 minGFly = (gFLYAmount * (gs().bpsDenominator - gs().slippageInBPS)) / gs().bpsDenominator;
            (uint256 providedMagic, uint256 providedGFly, uint256 liquidity) = IUniswapV2Router02(gs().magicSwapRouter)
                .addLiquidity(
                    gs().magic,
                    gs().gFLY,
                    magicAmount,
                    gFLYAmount,
                    minMagic,
                    minGFly,
                    gs().lpReceiver,
                    block.timestamp
                );
            gs().magicForLp -= providedMagic;
            gs().gFlyForLp -= providedGFly;
            emit LiquidityAdded(liquidity, providedMagic, providedGFly);
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert Errors.IdenticalAddresses();
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert Errors.InvalidAddress();
    }

    // fetches and sorts the reserves for a pair
    function getReserves() internal view returns (uint reserveMagic, uint reserveGFly) {
        (address token0, ) = sortTokens(gs().magic, gs().gFLY);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(gs().magicGFlyLp).getReserves();
        (reserveMagic, reserveGFly) = gs().magic == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibDiamond } from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import { Errors } from "../helpers/Errors.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

enum PaymentType {
    // DO NOT CHANGE ORDER AND ALWAYS ADD AT THE BOTTOM
    MAGIC,
    GFLY,
    TREASURES
}

struct BattleflyGameStorage {
    // DO NOT CHANGE ORDER AND ALWAYS ADD AT THE BOTTOM

    bool paused;
    uint256 gFlyPerCredit;
    uint256 treasuresPerCredit;
    address diamondAddress;
    address gFlyReceiver;
    address treasureReceiver;
    address gFLY;
    address treasures;
    mapping(uint256 => bool) creditTypes;
    mapping(address => bool) guardian;
    address magic;
    uint256 magicPerCredit;
    // automatic Magic/gFLY LP setup
    address magicSwapRouter;
    address magicGFlyLp;
    address lpReceiver;
    uint256 magicForLp;
    uint256 magicLpTreshold;
    uint256 gFlyForLp;
    uint256 gFlyLpTreshold;
    address battleflyBot;
    uint256 bpsDenominator;
    uint256 slippageInBPS;
    address battlefly;
    address soulbound;
    mapping(uint256 => mapping(uint256 => address)) battleflyOwner;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) battlefliesOfOwner;
    mapping(address => bool) signer;
    bytes32 merkleRoot;
    uint256 emissionsEpoch;
    mapping(address => uint256) claimedMagicRNGEmissions;
    address gameV2;
    mapping(address => bool) emissionDepositor;
    mapping(uint256 => uint256) magicRNGEmissionsForProcessingEpoch;
    uint256 processingEpoch;
    mapping(address => bool) backendExecutor;
    address paymentReceiver;
    address usdc;
    uint256 magicReserve;
    uint256 ethReserve;
    uint256 usdcReserve;
    address weth;
    address usdcDataFeedAddress;
    address ethDataFeedAddress;
    address magicDataFeedAddress;
    address sushiswapRouter;
    address sequencerUptimeFeedAddress;
    uint256 sequencerGracePeriod;
    address usdcOriginal;
    uint256 usdcOriginalReserve;
    uint24 usdcToUsdcOriginalPoolFee;
    address uniswapV3Router;
    address uniswapV3Quoter;

    uint256 arbReserve;
    address arbDataFeedAddress;
    address arb;
}

/**
 * All of Battlefly's wastelands storage is stored in a single WastelandStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "battlefly.storage.game")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.wastelandStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.gameStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of Wastelands
    bytes32 constant BATTLEFLY_GAME_STORAGE_POSITION = keccak256("battlefly.storage.game");

    function gameStorage() internal pure returns (BattleflyGameStorage storage gs) {
        bytes32 position = BATTLEFLY_GAME_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.gameStorage()` to just `gs()`.
 *
 * To understand why the storage structs must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function gs() internal pure returns (BattleflyGameStorage storage) {
        return LibStorage.gameStorage();
    }
}

contract WithModifiers is WithStorage {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyGuardian() {
        if (!gs().guardian[msg.sender]) revert Errors.NotGuardian();
        _;
    }

    modifier onlySoulbound() {
        if (msg.sender != gs().soulbound) revert Errors.NotSoulbound();
        _;
    }

    modifier onlyBattleflyBot() {
        if (gs().battleflyBot != msg.sender) revert Errors.NotBattleflyBot();
        _;
    }

    modifier onlyGameV2() {
        if (gs().gameV2 != msg.sender) revert Errors.NotGameV2();
        _;
    }

    modifier onlyEmissionDepositor() {
        if (!gs().emissionDepositor[msg.sender]) revert Errors.NotEmissionDepositor();
        _;
    }

    modifier onlyBackendExecutor() {
        if (!gs().backendExecutor[msg.sender]) revert Errors.NotBackendExecutor();
        _;
    }

    modifier notPaused() {
        if (gs().paused) revert Errors.GamePaused();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}