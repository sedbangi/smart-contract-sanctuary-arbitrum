// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

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
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

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
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
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
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
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
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
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
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
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
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
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
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
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
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
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
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
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
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
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
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
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
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IACLManager
 * @author maneki.finance
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the FlashBorrower role
     * @return The id of the FlashBorrower role
     */
    function FLASH_BORROWER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the Bridge role
     * @return The id of the Bridge role
     */
    function BRIDGE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the AssetListingAdmin role
     * @return The id of the AssetListingAdmin role
     */
    function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new address as FlashBorrower
     * @param borrower The address of the new FlashBorrower
     */
    function addFlashBorrower(address borrower) external;

    /**
     * @notice Removes an address as FlashBorrower
     * @param borrower The address of the FlashBorrower to remove
     */
    function removeFlashBorrower(address borrower) external;

    /**
     * @notice Returns true if the address is FlashBorrower, false otherwise
     * @param borrower The address to check
     * @return True if the given address is FlashBorrower, false otherwise
     */
    function isFlashBorrower(address borrower) external view returns (bool);

    /**
     * @notice Adds a new address as Bridge
     * @param bridge The address of the new Bridge
     */
    function addBridge(address bridge) external;

    /**
     * @notice Removes an address as Bridge
     * @param bridge The address of the bridge to remove
     */
    function removeBridge(address bridge) external;

    /**
     * @notice Returns true if the address is Bridge, false otherwise
     * @param bridge The address to check
     * @return True if the given address is Bridge, false otherwise
     */
    function isBridge(address bridge) external view returns (bool);

    /**
     * @notice Adds a new admin as AssetListingAdmin
     * @param admin The address of the new admin
     */
    function addAssetListingAdmin(address admin) external;

    /**
     * @notice Removes an admin as AssetListingAdmin
     * @param admin The address of the admin to remove
     */
    function removeAssetListingAdmin(address admin) external;

    /**
     * @notice Returns true if the address is AssetListingAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is AssetListingAdmin, false otherwise
     */
    function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title ICreditDelegationToken
 * @author maneki.finance
 * @notice Defines the basic interface for a token supporting credit delegation.
 */
interface ICreditDelegationToken {
    /**
     * @dev Emitted on `approveDelegation` and `borrowAllowance
     * @param fromUser The address of the delegator
     * @param toUser The address of the delegatee
     * @param asset The address of the delegated asset
     * @param amount The amount being delegated
     */
    event BorrowAllowanceDelegated(
        address indexed fromUser,
        address indexed toUser,
        address indexed asset,
        uint256 amount
    );

    /**
     * @notice Delegates borrowing power to a user on the specific debt token.
     * Delegation will still respect the liquidation constraints (even if delegated, a
     * delegatee cannot force a delegator HF to go below 1)
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The maximum amount being delegated.
     */
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @notice Returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return The current allowance of `toUser`
     */
    function borrowAllowance(
        address fromUser,
        address toUser
    ) external view returns (uint256);

    /**
     * @notice Delegates borrowing power to a user on the specific debt token via ERC712 signature
     * @param delegator The delegator of the credit
     * @param delegatee The delegatee that can use the credit
     * @param value The amount to be delegated
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v The V signature param
     * @param s The S signature param
     * @param r The R signature param
     */
    function delegationWithSig(
        address delegator,
        address delegatee,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title IIncentivesController
 * @author maneki.finance
 * @notice Defines the basic interface for an Aave Incentives Controller.
 * @dev It only contains one single function, needed as a hook on MToken and debtToken transfers.
 */
interface IIncentivesController {
    /**
     * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
     * @dev The units of `totalSupply` and `userBalance` should be the same.
     * @param user The address of the user whose asset balance has changed
     * @param totalSupply The total supply of the asset prior to user balance change
     * @param userBalance The previous user balance prior to balance change
     */
    function handleAction(
        address user,
        uint256 totalSupply,
        uint256 userBalance
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IIncentivesController} from "./IIncentivesController.sol";
import {IPool} from "./IPool.sol";

/**
 * @title IInitializableDebtToken
 * @author maneki.finance
 * @notice Interface for the initialize function common between debt tokens
 */
interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param incentivesController The address of the incentives controller for this MToken
     * @param debtTokenDecimals The decimals of the debt token
     * @param debtTokenName The name of the debt token
     * @param debtTokenSymbol The symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     */
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the debt token.
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this MToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address underlyingAsset,
        IIncentivesController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title   IPool
 * @author  maneki.finance
 * @notice  Defines the basic interface for an Aave Pool.
 * @dev     Based on AaveV3's IPool
 */
interface IPool {
    /****************************************/
    /* Contract Variables */
    /****************************************/

    /**
     * @notice Returns the PUBLIC_LIQUIDATOR address
     * @return The address of the PublicLiquidator
     */
    function PUBLIC_LIQUIDATOR() external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /****************************************/
    /* Events */
    /****************************************/
    /**
     * @dev     Emitted on mintUnbacked()
     * @param   reserve         The address of the underlying asset of the reserve
     * @param   user            The address initiating the supply
     * @param   onBehalfOf      The beneficiary of the supplied assets, receiving the mTokens
     * @param   amount          The amount of supplied assets
     * @param   referralCode    The referral code used
     */
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev     Emitted on backUnbacked()
     * @param   reserve The address of the underlying asset of the reserve
     * @param   backer  The address paying for the backing
     * @param   amount  The amount added as backing
     * @param   fee     The amount paid in fees
     */
    event BackUnbacked(
        address indexed reserve,
        address indexed backer,
        uint256 amount,
        uint256 fee
    );

    /**
     * @dev     Emitted on supply()
     * @param   reserve         The address of the underlying asset of the reserve
     * @param   user            The address initiating the supply
     * @param   onBehalfOf      The beneficiary of the supply, receiving the mTokens
     * @param   amount          The amount supplied
     * @param   referralCode    The referral code used
     */
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev     Emitted on withdraw()
     * @param   reserve The address of the underlying asset being withdrawn
     * @param   user    The address initiating the withdrawal, owner of mTokens
     * @param   to      The address that will receive the underlying
     * @param   amount  The amount to be withdrawn
     */
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev     Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param   reserve             The address of the underlying asset being borrowed
     * @param   user                The address of the user initiating the borrow(), receiving the funds on borrow() or just
     *                              initiator of the transaction on flashLoan()
     * @param   onBehalfOf          The address that will be getting the debt
     * @param   amount              The amount borrowed out
     * @param   interestRateMode    The rate mode: 1 for Stable, 2 for Variable
     * @param   borrowRate          The numeric rate at which the user has borrowed, expressed in ray
     * @param   referralCode        The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev     Emitted on repay()
     * @param   reserve     The address of the underlying asset of the reserve
     * @param   user        The beneficiary of the repayment, getting his debt reduced
     * @param   repayer     The address of the user initiating the repay(), providing the funds
     * @param   amount      The amount repaid
     * @param   useMTokens  True if the repayment is done using mTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useMTokens
    );

    /**
     * @dev     Emitted on swapBorrowRateMode()
     * @param   reserve             The address of the underlying asset of the reserve
     * @param   user                The address of the user swapping his rate mode
     * @param   interestRateMode    The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     */
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev     Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param   asset       The address of the underlying asset of the reserve
     * @param   totalDebt   The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(
        address indexed asset,
        uint256 totalDebt
    );

    /**
     * @dev     Emitted when the user selects a certain asset category for eMode
     * @param   user        The address of the user
     * @param   categoryId  The category id
     */
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev     Emitted on setUserUseReserveAsCollateral()
     * @param   reserve The address of the underlying asset of the reserve
     * @param   user    The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev     Emitted on setUserUseReserveAsCollateral()
     * @param   reserve The address of the underlying asset of the reserve
     * @param   user    The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev     Emitted on rebalanceStableBorrowRate()
     * @param   reserve The address of the underlying asset of the reserve
     * @param   user    The address of the user for which the rebalance has been executed
     */
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev     Emitted on flashLoan()
     * @param   target              The address of the flash loan receiver contract
     * @param   initiator           The address initiating the flash loan
     * @param   asset               The address of the asset being flash borrowed
     * @param   amount              The amount flash borrowed
     * @param   interestRateMode    The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
     * @param   premium             The fee flash borrowed
     * @param   referralCode        The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev     Emitted when a borrower is liquidated.
     * @param   collateralAsset             The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param   debtAsset                   The address of the underlying borrowed asset to be repaid with the liquidation
     * @param   user                        The address of the borrower getting liquidated
     * @param   debtToCover                 The debt amount of borrowed `asset` the liquidator wants to cover
     * @param   liquidatedCollateralAmount  The amount of collateral received by the liquidator
     * @param   liquidator                  The address of the liquidator
     * @param   receiveMToken               True if the liquidators wants to receive the collateral mTokens, `false` if he
     *                                      wants to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveMToken
    );

    /**
     * @dev     Emitted when the state of a reserve is updated.
     * @param   reserve             The address of the underlying asset of the reserve
     * @param   liquidityRate       The next liquidity rate
     * @param   stableBorrowRate    The next stable borrow rate
     * @param   variableBorrowRate  The next variable borrow rate
     * @param   liquidityIndex      The next liquidity index
     * @param   variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev     Emitted when the protocol treasury receives minted mTokens from the accrued interest.
     * @param   reserve         The address of the reserve
     * @param   amountMinted    The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /****************************************/
    /* Upgradability */
    /****************************************/

    /**
     * @notice          Initializes the Pool.
     * @dev             Function is invoked by the proxy contract when the Pool contract is added to the
     *                  PoolAddressesProvider of the market.
     * @dev             Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
     * @param           provider  The address of the PoolAddressesProvider
     */
    function initialize(IPoolAddressesProvider provider) external;

    /****************************************/
    /* Onwards Incentives & Underlying Yield Distribution */
    /****************************************/

    /**
     * @notice  Set the yield distributor on the yield generating MToken, and initializes
     *          it if it wasn't initialized yet
     * @dev     Only callable by PoolConfigurator
     * @param   _mToken              The address of the MToken to update its yield distributor
     * @param   _yieldDistributor    The address of the yield distributor
     */
    function setMTokenYieldDistributor(
        address _mToken,
        address _yieldDistributor
    ) external;

    /****************************************/
    /* User Actions */
    /****************************************/

    /**
     * @notice  Supplies an `amount` of underlying asset into the reserve, receiving in return overlying mTokens.
     *          - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param   asset           The address of the underlying asset to supply
     * @param   amount          The amount to be supplied
     * @param   onBehalfOf      The address that will receive the mTokens, same as msg.sender if the user
     *                          wants to receive them on his own wallet, or a different address if the beneficiary
     *                          of mTokens is a different wallet
     * @param   referralCode    Code used to register the integrator originating the operation, for potential rewards.
     *                          0 if the action is executed directly by the user, without any middle-man
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice  Supply with transfer approval of asset to be supplied done via permit function
     *          see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param   asset           The address of the underlying asset to supply
     * @param   amount          The amount to be supplied
     * @param   onBehalfOf      The address that will receive the mTokens, same as msg.sender if the user
     *                          wants to receive them on his own wallet, or a different address if the beneficiary
     *                          of mTokens is a different wallet
     * @param   deadline        The deadline timestamp that the permit is valid
     * @param   referralCode    Code used to register the integrator originating the operation, for potential rewards.
     *                          0 if the action is executed directly by the user, without any middle-man
     * @param   permitV         The V parameter of ERC712 permit sig
     * @param   permitR         The R parameter of ERC712 permit sig
     * @param   permitS         The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice  Withdraws an `amount` of underlying asset from the reserve, burning the equivalent mTokens owned
     *          E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param   asset   The address of the underlying asset to withdraw
     * @param   amount  The underlying amount to be withdrawn
     *                  - Send the value type(uint256).max in order to withdraw the whole mToken balance
     * @param   to      The address that will receive the underlying, same as msg.sender if the user
     *                  wants to receive it on his own wallet, or a different address if the beneficiary is a
     *                  different wallet
     * @return  The final amount withdrawn
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice  Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     *          already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     *          corresponding debt token (StableDebtToken or VariableDebtToken)
     *          - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *          and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param   asset               The address of the underlying asset to borrow
     * @param   amount              The amount to be borrowed
     * @param   interestRateMode    The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param   referralCode        The code used to register the integrator originating the operation, for potential rewards.
     *                              0 if the action is executed directly by the user, without any middle-man
     * @param   onBehalfOf          The address of the user who will receive the debt. Should be the address of the
     *                              borrower itself calling the function if he wants to borrow against his own collateral, or
     *                              the address of the credit delegator if he has been given credit delegation allowance
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice  Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     *          - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param   asset               The address of the borrowed underlying asset previously borrowed
     * @param   amount              The amount to repay
     *                              - Send the value type(uint256).max in order to repay the whole debt for `asset` on
     *                              the specific `debtMode`
     * @param   interestRateMode    The interest rate mode at of the debt the user wants to repay: 1 for Stable,
     *                              2 for Variable
     * @param   onBehalfOf          The address of the user who will get his debt reduced/removed. Should be the address
     *                              of the user calling the function if he wants to reduce/remove his own debt, or the
     *                              address of any other other borrower whose debt should be removed
     * @return  The final amount repaid
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice  Repay with transfer approval of asset to be repaid done via permit function
     *          see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param   asset               The address of the borrowed underlying asset previously borrowed
     * @param   amount              The amount to repay
     *                              - Send the value type(uint256).max in order to repay the whole debt for `asset` on the
     *                              specific `debtMode`
     * @param   interestRateMode    The interest rate mode at of the debt the user wants to repay: 1 for Stable,
     *                              2 for Variable
     * @param   onBehalfOf          Address of the user who will get his debt reduced/removed. Should be the address of the
     *                              user calling the function if he wants to reduce/remove his own debt, or the address of
     *                              any other other borrower whose debt should be removed
     * @param   deadline            The deadline timestamp that the permit is valid
     * @param   permitV             The V parameter of ERC712 permit sig
     * @param   permitR             The R parameter of ERC712 permit sig
     * @param   permitS             The S parameter of ERC712 permit sig
     * @return  The final amount repaid
     */
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice  Repays a borrowed `amount` on a specific reserve using the reserve mTokens, burning the
     *          equivalent debt tokens
     *          - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev     Passing uint256.max as amount will clean up any residual mToken dust balance, if the user mToken
     *          balance is not enough to cover the whole debt
     * @param   asset               The address of the borrowed underlying asset previously borrowed
     * @param   amount              The amount to repay
     *                              - Send the value type(uint256).max in order to repay the whole debt for `asset`
     *                              on the specific `debtMode`
     * @param   interestRateMode    The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return  The final amount repaid
     */
    function repayWithMTokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice  Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param   asset               The address of the underlying asset borrowed
     * @param   interestRateMode    The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     */
    function swapBorrowRateMode(
        address asset,
        uint256 interestRateMode
    ) external;

    /**
     * @notice  Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     *          - Users can be rebalanced if the following conditions are satisfied:
     *          1. Usage ratio is above 95%
     *           2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *          much has been borrowed at a stable rate and suppliers are not earning enough
     * @param   asset   The address of the underlying asset borrowed
     * @param   user    The address of the user to be rebalanced
     */
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice  Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param   asset           The address of the underlying asset supplied
     * @param   useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     */
    function setUserUseReserveAsCollateral(
        address asset,
        bool useAsCollateral
    ) external;

    /**
     * @notice  Allows a user to use the protocol in eMode
     * @param   categoryId  The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice  Supplies an `amount` of underlying asset into the reserve, receiving in return overlying mTokens.
     *          - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev     Deprecated: Use the `supply` function instead
     * @param   asset           The address of the underlying asset to supply
     * @param   amount          The amount to be supplied
     * @param   onBehalfOf      The address that will receive the mTokens, same as msg.sender if the user
     *                          wants to receive them on his own wallet, or a different address if the beneficiary
     *                          of mTokens is a different wallet
     * @param   referralCode    Code used to register the integrator originating the operation, for potential rewards.
     *                          0 if the action is executed directly by the user, without any middle-man
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /****************************************/
    /* User Info */
    /****************************************/

    /**
     * @notice  Returns the user account data across all the reserves
     * @param   user                        The address of the user
     * @return  totalCollateralBase         The total collateral of the user in the base currency used by the price feed
     * @return  totalDebtBase               The total debt of the user in the base currency used by the price feed
     * @return  availableBorrowsBase        The borrowing power left of the user in the base currency used by the price feed
     * @return  currentLiquidationThreshold The liquidation threshold of the user
     * @return  ltv                         The loan to value of The user
     * @return  healthFactor                The current health factor of the user
     */
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice  Returns the configuration of the user across all the reserves
     * @param   user    The user address
     * @return  The configuration of the user
     */
    function getUserConfiguration(
        address user
    ) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice  Returns the eMode the user is using
     * @param   user    The address of the user
     * @return  The eMode id
     */
    function getUserEMode(address user) external view returns (uint256);

    /****************************************/
    /* Reserves Info */
    /****************************************/
    /**
     * @notice  Returns the maximum number of reserves supported to be listed in this Pool
     * @return  The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice  Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return  The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        returns (uint256);

    /**
     * @notice  Returns the state and configuration of the reserve
     * @param   asset   The address of the underlying asset of the reserve
     * @return  The state and configuration data of the reserve
     */
    function getReserveData(
        address asset
    ) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice  Returns the configuration of the reserve
     * @param   asset   The address of the underlying asset of the reserve
     * @return  The configuration of the reserve
     */
    function getConfiguration(
        address asset
    ) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice  Returns the address of the underlying asset of a reserve by the reserve id as
     *          stored in the DataTypes.ReserveData struct
     * @param   id  The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return  The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice  Returns the list of the underlying assets of all the initialized reserves
     * @dev     It does not include dropped reserves
     * @return  The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice  Returns the normalized income of the reserve
     * @param   asset The address of the underlying asset of the reserve
     * @return  The reserve's normalized income
     */
    function getReserveNormalizedIncome(
        address asset
    ) external view returns (uint256);

    /**
     * @notice  Returns the normalized variable debt per unit of asset
     * @dev     WARNING: This function is intended to be used primarily by the protocol itself to get a
     *          "dynamic" variable index based on time, current stored index and virtual rate at the current
     *          moment (approx. a borrower would get if opening a position). This means that is always used in
     *          combination with variable debt supply/balances.
     *          If using this function externally, consider that is possible to have an increasing normalized
     *          variable debt that is not equivalent to how the variable debt index would be updated in storage
     *          (e.g. only updates with non-zero variable debt supply)
     * @param   asset   The address of the underlying asset of the reserve
     * @return  The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(
        address asset
    ) external view returns (uint256);

    /**
     * @notice  Returns the data of an eMode category
     * @param   id  The id of the category
     * @return  The configuration data of the category
     */
    function getEModeCategoryData(
        uint8 id
    ) external view returns (DataTypes.EModeCategory memory);

    /****************************************/
    /* Reserves */
    /****************************************/

    /**
     * @notice  Initializes a reserve, activating it, assigning an mToken and debt tokens and an
     *          interest rate strategy
     * @dev     Only callable by the PoolConfigurator contract
     * @param   asset                       The address of the underlying asset of the reserve
     * @param   mTokenAddress               The address of the mToken that will be assigned to the reserve
     * @param   stableDebtAddress           The address of the StableDebtToken that will be assigned to the reserve
     * @param   variableDebtAddress         The address of the VariableDebtToken that will be assigned to the reserve
     * @param   interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function initReserve(
        address asset,
        address mTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice  Drop a reserve
     * @dev     Only callable by the PoolConfigurator contract
     * @param   asset   The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    /**
     * @notice  Updates the address of the interest rate strategy contract
     * @dev     Only callable by the PoolConfigurator contract
     * @param   asset               The address of the underlying asset of the reserve
     * @param   rateStrategyAddress The address of the interest rate strategy contract
     */
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    /**
     * @notice  Sets the configuration bitmap of the reserve as a whole
     * @dev     Only callable by the PoolConfigurator contract
     * @param   asset           The address of the underlying asset of the reserve
     * @param   configuration   The new configuration bitmap
     */
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external;

    /**
     * @notice  Configures a new category for the eMode.
     * @dev     In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
     *          The category 0 is reserved as it's the default for volatile assets
     * @param   id      The id of the category
     * @param   config  The configuration of the category
     */
    function configureEModeCategory(
        uint8 id,
        DataTypes.EModeCategory memory config
    ) external;

    /**
     * @notice  Resets the isolation mode total debt of the given asset to zero
     * @dev     It requires the given asset has zero debt ceiling
     * @param   asset   The address of the underlying asset to reset the isolationModeTotalDebt
     */
    function resetIsolationModeTotalDebt(address asset) external;

    /****************************************/
    /* MTokens */
    /****************************************/

    /**
     * @notice  Validates and finalizes an mToken transfer
     * @dev     Only callable by the overlying mToken of the `asset`
     * @param   asset               The address of the underlying asset of the mToken
     * @param   from                The user from which the mTokens are transferred
     * @param   to                  The user receiving the mTokens
     * @param   amount              The amount being transferred/withdrawn
     * @param   balanceFromBefore   The mToken balance of the `from` user before the transfer
     * @param   balanceToBefore     The mToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /****************************************/
    /* Liquidations */
    /****************************************/

    /**
     * @notice  Sets the address of the PublicLiquidator on Pool
     * @dev     If PublicLiquidator is address(0), liquidations works as normal.
     *          WHen PublicLiquidator is set, all liquidations need to go through
     *          PublicLiquidator contract. For specific tokenomics design purpose.
     * @dev     Only callable by PoolConfigurator
     * @param   _publicLiquidator   The address of the PublicLiquidator contract
     */

    function setPublicLiquidator(address _publicLiquidator) external;

    /**
     * @notice  Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     *          - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated,
     *          and receives a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param   collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param   debtAsset       The address of the underlying borrowed asset to be repaid with the liquidation
     * @param   user            The address of the borrower getting liquidated
     * @param   debtToCover     The debt amount of borrowed `asset` the liquidator wants to cover
     * @param   receiveMToken   True if the liquidators wants to receive the collateral mTokens, `false` if he wants
     *                          to receive the underlying collateral asset directly
     * @dev     If PublicLiquidator is set, all liquidations must go through it instead, for specific tokenomics design
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveMToken
    ) external;

    /****************************************/
    /* Flashloans */
    /****************************************/

    /**
     * @notice  Updates flash loan premiums. Flash loan premium consists of two parts:
     *          - A part is sent to mToken holders as extra, one time accumulated interest
     *          - A part is collected by the protocol treasury
     * @dev     The total premium is calculated on the total borrowed amount
     * @dev     The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev     Only callable by the PoolConfigurator contract
     * @param   flashLoanPremiumTotal       The total premium, expressed in bps
     * @param   flashLoanPremiumToProtocol  The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(
        uint128 flashLoanPremiumTotal,
        uint128 flashLoanPremiumToProtocol
    ) external;

    /**
     * @notice  Returns the total fee on flash loans
     * @return  The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice  Returns the part of the flashloan fees sent to protocol
     * @return  The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice  View function to check whether given address is flashloan priviledged
     * @param   _flashloanCaller    The address of the flashloan caller
     */

    function isFlashloanPrivilege(
        address _flashloanCaller
    ) external view returns (bool);

    function setFlashloanPrivilege(
        address _callerAddress,
        bool _isPrivileged
    ) external;

    /**
     * @notice  Allows smartcontracts to access the liquidity of the pool within one transaction,
     *          as long as the amount taken plus a fee is returned.
     * @dev     IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     *          into consideration.
     * @param   receiverAddress     The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param   assets              The addresses of the assets being flash-borrowed
     * @param   amounts             The amounts of the assets being flash-borrowed
     * @param   interestRateModes   Types of the debt to open if the flash loan is not returned:
     *                              0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *                              1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *                              2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param   onBehalfOf          The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param   params              Variadic packed params to pass to the receiver as extra information
     * @param   referralCode        The code used to register the integrator originating the operation, for potential rewards.
     *                              0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice  Allows smartcontracts to access the liquidity of the pool within one transaction,
     *          as long as the amount taken plus a fee is returned.
     * @dev     IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     *          into consideration. For further details please visit https://docs.aave.com/developers/
     * @param   receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param   asset           The address of the asset being flash-borrowed
     * @param   amount          The amount of the asset being flash-borrowed
     * @param   params          Variadic packed params to pass to the receiver as extra information
     * @param   referralCode    The code used to register the integrator originating the operation, for potential rewards.
     *                          0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /****************************************/
    /* Bridge */
    /****************************************/

    /**
     * @notice  Updates the protocol fee on the bridging
     * @param   bridgeProtocolFee   The part of the premium sent to the protocol treasury
     */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice  Returns the part of the bridge fees sent to protocol
     * @return  The bridge fee sent to the protocol treasury
     */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice  Mints an `amount` of mTokens to the `onBehalfOf`
     * @param   asset           The address of the underlying asset to mint
     * @param   amount          The amount to mint
     * @param   onBehalfOf      The address that will receive the mTokens
     * @param   referralCode    Code used to register the integrator originating the operation, for potential rewards.
     *                          0 if the action is executed directly by the user, without any middle-man
     */
    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice  Back the current unbacked underlying with `amount` and pay `fee`.
     * @param   asset   The address of the underlying asset to back
     * @param   amount  The amount to back
     * @param   fee     The amount paid in fees
     * @return  The backed amount
     */
    function backUnbacked(
        address asset,
        uint256 amount,
        uint256 fee
    ) external returns (uint256);

    /****************************************/
    /* Treasury */
    /****************************************/

    /**
     * @notice  Mints the assets accrued through the reserve factor to the treasury in the form of mTokens
     * @param   assets  The list of reserves for which the minting needs to be executed
     */
    function mintToTreasury(address[] calldata assets) external;

    /****************************************/
    /* Miscellaneous */
    /****************************************/

    /**
     * @notice  Delegates the call from Pool to another contract
     * @dev     Only callable by PoolConfigurator
     * @param   _target Address of the target contract
     * @param   _data   The calldata to pass along with the call
     */
    function delegateCall(
        address _target,
        bytes memory _data
    ) external payable returns (bool success, bytes memory resultData);

    /**
     * @notice  Rescue and transfer tokens locked in this contract
     * @param   token   The address of the token
     * @param   to      The address of the recipient
     * @param   amount  The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title   IPoolAddressesProvider
 * @author  maneki.finance
 * @notice  Defines the basic interface for a Pool Addresses Provider
 * @dev     Based on AaveV3's IPoolAddressesProvider
 */
interface IPoolAddressesProvider {
    /**
     * @dev     Emitted when the market identifier is updated.
     * @param   oldMarketId The old id of the market
     * @param   newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev     Emitted when the pool is updated.
     * @param   oldAddress The old address of the Pool
     * @param   newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev     Emitted when the pool configurator is updated.
     * @param   oldAddress The old address of the PoolConfigurator
     * @param   newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the price oracle is updated.
     * @param   oldAddress The old address of the PriceOracle
     * @param   newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the ACL manager is updated.
     * @param   oldAddress The old address of the ACLManager
     * @param   newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the ACL admin is updated.
     * @param   oldAddress The old address of the ACLAdmin
     * @param   newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the price oracle sentinel is updated.
     * @param   oldAddress The old address of the PriceOracleSentinel
     * @param   newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the pool data provider is updated.
     * @param   oldAddress The old address of the PoolDataProvider
     * @param   newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when a new proxy is created.
     * @param   id The identifier of the proxy
     * @param   proxyAddress The address of the created proxy contract
     * @param   implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev     Emitted when a new non-proxied contract address is registered.
     * @param   id The identifier of the contract
     * @param   oldAddress The address of the old contract
     * @param   newAddress The address of the new contract
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the implementation of the proxy registered with id is updated
     * @param   id The identifier of the contract
     * @param   proxyAddress The address of the proxy contract
     * @param   oldImplementationAddress The address of the old implementation contract
     * @param   newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice  Returns the id of the Maneki market to which this contract points to.
     * @return  The market id
     */
    function getMarketId() external view returns (string memory);

    /**
     * @notice  Associates an id with a specific PoolAddressesProvider.
     * @dev     This can be used to create an onchain registry of PoolAddressesProviders to
     *          identify and validate multiple Maneki markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice  Returns an address by its identifier.
     * @dev     The returned address might be an EOA or a contract, potentially proxied
     * @dev     It returns ZERO if there is no registered address with the given id
     * @param   id The id
     * @return  The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice  General function to update the implementation of a proxy registered with
     *          certain `id`. If there is no proxy registered, it will instantiate one and
     *          set as implementation the `newImplementationAddress`.
     * @dev     IMPORTANT Use this function carefully, only for ids that don't have an explicit
     *          setter function, in order to avoid unexpected consequences
     * @param   id The id
     * @param   newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(
        bytes32 id,
        address newImplementationAddress
    ) external;

    /**
     * @notice  Sets an address for an id replacing the address saved in the addresses map.
     * @dev     IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param   id The id
     * @param   newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice  Returns the address of the Pool proxy.
     * @return  The Pool proxy address
     */
    function getPool() external view returns (address);

    /**
     * @notice  Updates the implementation of the Pool, or creates a proxy
     *          setting the new `pool` implementation when the function is called for the first time.
     * @param   newPoolImpl The new Pool implementation
     */
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice  Returns the address of the PoolConfigurator proxy.
     * @return  The PoolConfigurator proxy address
     */
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice  Updates the implementation of the PoolConfigurator, or creates a proxy
     *          setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param   newPoolConfiguratorImpl The new PoolConfigurator implementation
     */
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice  Returns the address of the price oracle.
     * @return  The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice  Updates the address of the price oracle.
     * @param   newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice  Returns the address of the ACL manager.
     * @return  The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice  Updates the address of the ACL manager.
     * @param   newAclManager The address of the new ACLManager
     */
    function setACLManager(address newAclManager) external;

    /**
     * @notice  Returns the address of the ACL admin.
     * @return  The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice  Updates the address of the ACL admin.
     * @param   newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice  Returns the address of the price oracle sentinel.
     * @return  The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice  Updates the address of the price oracle sentinel.
     * @param   newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice  Returns the address of the data provider.
     * @return  The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice  Updates the address of the data provider.
     * @param   newDataProvider The address of the new DataProvider
     */
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";

/**
 * @title IStableDebtToken
 * @author maneki.finance
 * @notice Defines the interface for the stable debt token
 * @dev It does not inherit from IERC20 to save in code size
 */
interface IStableDebtToken is IInitializableDebtToken {
    /**
     * @dev Emitted when new stable debt is minted
     * @param user The address of the user who triggered the minting
     * @param onBehalfOf The recipient of stable debt tokens
     * @param amount The amount minted (user entered amount + balance increase from interest)
     * @param currentBalance The balance of the user based on the previous balance and balance increase from interest
     * @param balanceIncrease The increase in balance since the last action of the user 'onBehalfOf'
     * @param newRate The rate of the debt after the minting
     * @param avgStableRate The next average stable rate after the minting
     * @param newTotalSupply The next total supply of the stable debt token after the action
     */
    event Mint(
        address indexed user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 newRate,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new stable debt is burned
     * @param from The address from which the debt will be burned
     * @param amount The amount being burned (user entered amount - balance increase from interest)
     * @param currentBalance The balance of the user based on the previous balance and balance increase from interest
     * @param balanceIncrease The increase in balance since the last action of 'from'
     * @param avgStableRate The next average stable rate after the burning
     * @param newTotalSupply The next total supply of the stable debt token after the action
     */
    event Burn(
        address indexed from,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @notice Mints debt token to the `onBehalfOf` address.
     * @dev The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt tokens to mint
     * @param rate The rate of the debt being minted
     * @return True if it is the first borrow, false otherwise
     * @return The total stable debt
     * @return The average stable borrow rate
     */
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 rate
    ) external returns (bool, uint256, uint256);

    /**
     * @notice Burns debt of `user`
     * @dev The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest the user earned
     * @param from The address from which the debt will be burned
     * @param amount The amount of debt tokens getting burned
     * @return The total stable debt
     * @return The average stable borrow rate
     */
    function burn(
        address from,
        uint256 amount
    ) external returns (uint256, uint256);

    /**
     * @notice Returns the average rate of all the stable rate loans.
     * @return The average stable rate
     */
    function getAverageStableRate() external view returns (uint256);

    /**
     * @notice Returns the stable rate of the user debt
     * @param user The address of the user
     * @return The stable rate of the user
     */
    function getUserStableRate(address user) external view returns (uint256);

    /**
     * @notice Returns the timestamp of the last update of the user
     * @param user The address of the user
     * @return The timestamp
     */
    function getUserLastUpdated(address user) external view returns (uint40);

    /**
     * @notice Returns the principal, the total supply, the average stable rate and the timestamp for the last update
     * @return The principal
     * @return The total supply
     * @return The average stable rate
     * @return The timestamp of the last update
     */
    function getSupplyData()
        external
        view
        returns (uint256, uint256, uint256, uint40);

    /**
     * @notice Returns the timestamp of the last update of the total supply
     * @return The timestamp
     */
    function getTotalSupplyLastUpdated() external view returns (uint40);

    /**
     * @notice Returns the total supply and the average stable rate
     * @return The total supply
     * @return The average rate
     */
    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Returns the principal debt balance of the user
     * @return The debt balance of the user since the last burn/mint action
     */
    function principalBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of this stableDebtToken (E.g. WETH for stableDebtWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title VersionedInitializable
 * @author maneki.finance, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     */
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     */
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

/**
 * @title   Errors library
 * @author  maneki.finance
 * @notice  Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev     Based on AaveV3's Errors.sol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "Caller not Pool Admin";
    string public constant CALLER_NOT_EMERGENCY_ADMIN =
        "Caller not Emergency Admin";
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN =
        "Caller not Pool or Emergency Admin";
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN =
        "Caller not Risk or Pool Admin";
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN =
        "Caller not Asset Listing or Pool Admin";
    string public constant CALLER_NOT_BRIDGE = "Caller not Bridge";
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED =
        "Pool Addresses Provider not registered";
    string public constant INVALID_ADDRESSES_PROVIDER_ID =
        "Invalid Pool Addresses Provider ID";
    string public constant NOT_CONTRACT = "Address is not a contract";
    string public constant CALLER_NOT_POOL_CONFIGURATOR =
        "Caller not Pool Configurator";
    string public constant CALLER_NOT_ATOKEN = "Caller not MToken";
    string public constant INVALID_ADDRESSES_PROVIDER =
        "Invalid Pool Addresses Provider address";
    string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN =
        "Invalid flashloan executor return value";
    string public constant RESERVE_ALREADY_ADDED = "Reserve already added";
    string public constant NO_MORE_RESERVES_ALLOWED =
        "Maximum amount of reserves reached";
    string public constant EMODE_CATEGORY_RESERVED =
        "Zero eMode category is reserved for volatile heterogeneous assets";
    string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT =
        "Invalid eMode category assignment to asset";
    string public constant RESERVE_LIQUIDITY_NOT_ZERO =
        "The liquidity of the reserve needs to be 0";
    string public constant FLASHLOAN_PREMIUM_INVALID =
        "Invalid flashloan premium";
    string public constant INVALID_RESERVE_PARAMS =
        "Invalid risk parameters for the reserve";
    string public constant INVALID_EMODE_CATEGORY_PARAMS =
        "Invalid risk parameters for the eMode category";
    string public constant BRIDGE_PROTOCOL_FEE_INVALID =
        "Invalid bridge protocol fee";
    string public constant CALLER_MUST_BE_POOL =
        "The caller of this function must be a pool";
    string public constant INVALID_MINT_AMOUNT = "Invalid amount to mint";
    string public constant INVALID_BURN_AMOUNT = "Invalid amount to burn";
    string public constant INVALID_AMOUNT = "Amount must be greater than 0";
    string public constant RESERVE_INACTIVE =
        "Action requires an active reserve";
    string public constant RESERVE_FROZEN = "Reserve is frozen";
    string public constant RESERVE_PAUSED = "Reserve is paused";
    string public constant BORROWING_NOT_ENABLED = "Borrowing is not enabled";
    string public constant STABLE_BORROWING_NOT_ENABLED =
        "Stable borrowing not enabled";
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE =
        "Cannot withdraw more than available user balance";
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED =
        "Invalid interest rate mode";
    string public constant COLLATERAL_BALANCE_IS_ZERO =
        "The collateral balance is 0";
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "Health factor is lesser than the liquidation threshold";
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW =
        "Not enough collateral to cover new borrow";
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY =
        "Collateral is (mostly) the same currency that is being borrowed";
    string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE =
        "Amount is greater than the max loan size in stable rate mode'";
    string public constant NO_DEBT_OF_SELECTED_TYPE =
        "User does not have debt on selected reserve to repay";
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF =
        "To repay on behalf of a user an explicit amount to repay is needed";
    string public constant NO_OUTSTANDING_STABLE_DEBT =
        "User does not have outstanding stable rate debt on selected reserve";
    string public constant NO_OUTSTANDING_VARIABLE_DEBT =
        "User does not have outstanding variable rate debt on selected reserve";
    string public constant UNDERLYING_BALANCE_ZERO =
        "The underlying balance needs to be greater than 0'";
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET =
        "Interest rate rebalance conditions were not met";
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD =
        "Health factor is not below the threshold";
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED =
        "The collateral chosen cannot be liquidated";
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER =
        "User did not borrow the specified currency";
    string public constant INCONSISTENT_FLASHLOAN_PARAMS =
        "Inconsistent flashloan parameters";
    string public constant BORROW_CAP_EXCEEDED = "Borrow cap is exceeded";
    string public constant SUPPLY_CAP_EXCEEDED = "Supply cap is exceeded";
    string public constant UNBACKED_MINT_CAP_EXCEEDED =
        "Unbacked mint cap is exceeded";
    string public constant DEBT_CEILING_EXCEEDED = "Debt ceiling is exceeded";
    string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO =
        "Claimable rights over underlying not zero (mToken supply or accruedToTreasury)";
    string public constant STABLE_DEBT_NOT_ZERO =
        "Stable debt supply is not zero";
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO =
        "Variable debt supply is not zero";
    string public constant LTV_VALIDATION_FAILED = "Ltv validation failed";
    string public constant INCONSISTENT_EMODE_CATEGORY =
        "Inconsistent eMode category";
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED =
        "Price oracle sentinel validation failed";
    string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION =
        "Asset is not borrowable in isolation mode";
    string public constant RESERVE_ALREADY_INITIALIZED =
        "Reserve has already been initialized";
    string public constant USER_IN_ISOLATION_MODE = "User is in isolation mode";
    string public constant INVALID_LTV =
        "Invalid ltv parameter for the reserve";
    string public constant INVALID_LIQ_THRESHOLD =
        "Invalid liquidity threshold parameter for the reserve";
    string public constant INVALID_LIQ_BONUS =
        "Invalid liquidity bonus parameter for the reserve";
    string public constant INVALID_DECIMALS =
        "Invalid decimals parameter of the underlying asset of the reserve";
    string public constant INVALID_RESERVE_FACTOR =
        "Invalid reserve factor parameter for the reserve";
    string public constant INVALID_BORROW_CAP =
        "Invalid borrow cap for the reserve";
    string public constant INVALID_SUPPLY_CAP =
        "Invalid supply cap for the reserve";
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE =
        "Invalid liquidation protocol fee for the reserve";
    string public constant INVALID_EMODE_CATEGORY =
        "Invalid eMode category for the reserve";
    string public constant INVALID_UNBACKED_MINT_CAP =
        "Invalid unbacked mint cap for the reserve";
    string public constant INVALID_DEBT_CEILING =
        "Invalid debt ceiling for the reserve";
    string public constant INVALID_RESERVE_INDEX = "Invalid reserve index";
    string public constant ACL_ADMIN_CANNOT_BE_ZERO =
        "ACL admin cannot be set to the zero address";
    string public constant INCONSISTENT_PARAMS_LENGTH =
        "Inconsistent parameters length";
    string public constant ZERO_ADDRESS_NOT_VALID = "Zero address not valid";
    string public constant INVALID_EXPIRATION = "Invalid expiration";
    string public constant INVALID_SIGNATURE = "Invalid signature";
    string public constant OPERATION_NOT_SUPPORTED = "Operation not supported";
    string public constant DEBT_CEILING_NOT_ZERO = "Debt ceiling is not zero";
    string public constant ASSET_NOT_LISTED = "Asset is not listed";
    string public constant INVALID_OPTIMAL_USAGE_RATIO =
        "Invalid optimal usage ratio";
    string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO =
        "Invalid optimal stable to total debt ratio";
    string public constant UNDERLYING_CANNOT_BE_RESCUED =
        "The underlying asset cannot be rescued";
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED =
        "Reserve has already been added to reserve list";
    string public constant POOL_ADDRESSES_DO_NOT_MATCH =
        "The token implementation pool address and the pool address provided by the initializing pool do not match";
    string public constant STABLE_BORROWING_ENABLED =
        "Stable borrowing is enabled";
    string public constant SILOED_BORROWING_VIOLATION =
        "User is trying to borrow multiple assets including a siloed one";
    string public constant RESERVE_DEBT_NOT_ZERO =
        "The total debt of the reserve needs to be 0";
    string public constant FLASHLOAN_DISABLED =
        "FlashLoaning for this asset is disabled";
    string public constant REBASING_DISTRIBUTOR_CANNOT_BE_ZERO =
        "Rebasing Distributor cannot be zero address";
    string public constant REBASING_DISTRIBUTOR_ALREADY_SET =
        "Rebasing Distributor already set";
    string public constant DELEGATE_CALL_FAILED = "Delegate call failed";
    string public constant ONLY_PUBLIC_LIQUIDATOR_ALLOWED =
        "Only PublicLiquidator allowed to liquidate";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {WadRayMath} from "./WadRayMath.sol";

/**
 * @title MathUtils library
 * @author maneki.finance
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     */
    function calculateLinearInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) internal view returns (uint256) {
        //solium-disable-next-line
        uint256 result = rate *
            (block.timestamp - uint256(lastUpdateTimestamp));
        unchecked {
            result = result / SECONDS_PER_YEAR;
        }

        return WadRayMath.RAY + result;
    }

    /**
     * @dev Function to calculate the interest using a compounded interest rate formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     *
     *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     *
     * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
     * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
     * error per different time periods
     *
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate compounded during the timeDelta, in ray
     */
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        //solium-disable-next-line
        uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

        if (exp == 0) {
            return WadRayMath.RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo =
                rate.rayMul(rate) /
                (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
            basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return
            WadRayMath.RAY +
            (rate * exp) /
            SECONDS_PER_YEAR +
            secondTerm +
            thirdTerm;
    }

    /**
     * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
     * @param rate The interest rate (in ray)
     * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
     * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
     */
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) internal view returns (uint256) {
        return
            calculateCompoundedInterest(
                rate,
                lastUpdateTimestamp,
                block.timestamp
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

/**
 * @title WadRayMath library
 * @author maneki.finance
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //mToken address
        address mTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked mTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address mTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveMToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useMTokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address mToken;
    }

    struct InitReserveParams {
        address asset;
        address mTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../../libraries/aave-upgradeability/VersionedInitializable.sol";
import {ICreditDelegationToken} from "../../../interfaces/ICreditDelegationToken.sol";
import {EIP712Base} from "./EIP712Base.sol";

/**
 * @title DebtTokenBase
 * @author maneki.finance
 * @notice Base contract for different types of debt tokens, like StableDebtToken or VariableDebtToken
 */
abstract contract DebtTokenBase is
    VersionedInitializable,
    EIP712Base,
    Context,
    ICreditDelegationToken
{
    // Map of borrow allowances (delegator => delegatee => borrowAllowanceAmount)
    mapping(address => mapping(address => uint256)) internal _borrowAllowances;

    // Credit Delegation Typehash
    bytes32 public constant DELEGATION_WITH_SIG_TYPEHASH =
        keccak256(
            "DelegationWithSig(address delegatee,uint256 value,uint256 nonce,uint256 deadline)"
        );

    address internal _underlyingAsset;

    /**
     * @dev Constructor.
     */
    constructor() EIP712Base() {
        // Intentionally left blank
    }

    /// @inheritdoc ICreditDelegationToken
    function approveDelegation(
        address delegatee,
        uint256 amount
    ) external override {
        _approveDelegation(_msgSender(), delegatee, amount);
    }

    /**
     * @dev Maneki.finance added to allow delegator to decrease delegatee's allowances
     */
    function decreaseCreditDelegation(
        address delegatee,
        uint256 amount
    ) external {
        _decreaseBorrowAllowance(_msgSender(), delegatee, amount);
    }

    /**
     * @dev Maneki.finance added to allow delegator removing a delegatee
     */
    function removeCreditDelegation(address delegatee) external {
        uint256 currentDelegationAmount = _borrowAllowances[_msgSender()][
            delegatee
        ];
        _decreaseBorrowAllowance(
            _msgSender(),
            delegatee,
            currentDelegationAmount
        );
    }

    /// @inheritdoc ICreditDelegationToken
    function delegationWithSig(
        address delegator,
        address delegatee,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(delegator != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        //solium-disable-next-line
        require(block.timestamp <= deadline, Errors.INVALID_EXPIRATION);
        uint256 currentValidNonce = _nonces[delegator];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        DELEGATION_WITH_SIG_TYPEHASH,
                        delegatee,
                        value,
                        currentValidNonce,
                        deadline
                    )
                )
            )
        );
        require(
            delegator == ecrecover(digest, v, r, s),
            Errors.INVALID_SIGNATURE
        );
        _nonces[delegator] = currentValidNonce + 1;
        _approveDelegation(delegator, delegatee, value);
    }

    /// @inheritdoc ICreditDelegationToken
    function borrowAllowance(
        address fromUser,
        address toUser
    ) external view override returns (uint256) {
        return _borrowAllowances[fromUser][toUser];
    }

    /**
     * @notice Updates the borrow allowance of a user on the specific debt token.
     * @param delegator The address delegating the borrowing power
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The allowance amount being delegated.
     */
    function _approveDelegation(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal {
        _borrowAllowances[delegator][delegatee] = amount;
        emit BorrowAllowanceDelegated(
            delegator,
            delegatee,
            _underlyingAsset,
            amount
        );
    }

    /**
     * @notice Decreases the borrow allowance of a user on the specific debt token.
     * @param delegator The address delegating the borrowing power
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The amount to subtract from the current allowance
     */
    function _decreaseBorrowAllowance(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal {
        uint256 newAllowance = _borrowAllowances[delegator][delegatee] - amount;

        _borrowAllowances[delegator][delegatee] = newAllowance;

        emit BorrowAllowanceDelegated(
            delegator,
            delegatee,
            _underlyingAsset,
            newAllowance
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

/**
 * @title EIP712Base
 * @author maneki.finance
 * @notice Base contract implementation of EIP712.
 */
abstract contract EIP712Base {
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // Map of address nonces (address => nonce)
    mapping(address => uint256) internal _nonces;

    bytes32 internal _domainSeparator;
    uint256 internal immutable _chainId;

    /**
     * @dev Constructor.
     */
    constructor() {
        _chainId = block.chainid;
    }

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        if (block.chainid == _chainId) {
            return _domainSeparator;
        }
        return _calculateDomainSeparator();
    }

    /**
     * @notice Returns the nonce value for address specified as parameter
     * @param owner The address for which the nonce is being returned
     * @return The nonce value for the input address`
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @notice Compute the current domain separator
     * @return The domain separator for the token
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    keccak256(bytes(_EIP712BaseId())),
                    keccak256(EIP712_REVISION),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @notice Returns the user readable name of signing domain (e.g. token name)
     * @return The name of the signing domain
     */
    function _EIP712BaseId() internal view virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IIncentivesController} from "../../../interfaces/IIncentivesController.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IACLManager} from "../../../interfaces/IACLManager.sol";

/**
 * @title IncentivizedERC20
 * @author maneki.finance, inspired by the Openzeppelin ERC20 implementation
 * @notice Basic ERC20 implementation
 */
abstract contract IncentivizedERC20 is Context, IERC20Metadata {
    using WadRayMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     */
    modifier onlyPoolAdmin() {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     */
    modifier onlyPool() {
        require(_msgSender() == address(POOL), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    /**
     * @dev UserState - additionalData is a flexible field.
     * MTokens and VariableDebtTokens use this field store the index of the
     * user's last supply/withdrawal/borrow/repayment. StableDebtTokens use
     * this field to store the user's stable rate.
     */
    struct UserState {
        uint128 balance;
        uint128 additionalData;
    }
    // Map of users address and their state data (userAddress => userStateData)
    mapping(address => UserState) internal _userState;

    // Map of allowances (delegator => delegatee => allowanceAmount)
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    IIncentivesController internal _incentivesController;
    IPoolAddressesProvider internal immutable _addressesProvider;
    IPool public immutable POOL;

    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param decimals_ The number of decimals of the token
     */
    constructor(
        IPool pool,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _addressesProvider = pool.ADDRESSES_PROVIDER();
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        POOL = pool;
    }

    /// @inheritdoc IERC20Metadata
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _userState[account].balance;
    }

    /**
     * @notice Returns the address of the Incentives Controller contract
     * @return The address of the Incentives Controller
     */
    function getIncentivesController()
        external
        view
        virtual
        returns (IIncentivesController)
    {
        return _incentivesController;
    }

    /**
     * @notice Sets a new Incentives Controller
     * @param controller the new Incentives controller
     */
    function setIncentivesController(
        IIncentivesController controller
    ) external onlyPoolAdmin {
        _incentivesController = controller;
    }

    /// @inheritdoc IERC20
    function transfer(
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        uint128 castAmount = amount.toUint128();
        _transfer(_msgSender(), recipient, castAmount);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(
        address owner,
        address spender
    ) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(
        address spender,
        uint256 amount
    ) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        uint128 castAmount = amount.toUint128();
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - castAmount
        );
        _transfer(sender, recipient, castAmount);
        return true;
    }

    /**
     * @notice Increases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     * @return `true`
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @notice Decreases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param subtractedValue The amount being subtracted to the allowance
     * @return `true`
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @notice Transfers tokens between two users and apply incentives if defined.
     * @param sender The source address
     * @param recipient The destination address
     * @param amount The amount getting transferred
     */
    function _transfer(
        address sender,
        address recipient,
        uint128 amount
    ) internal virtual {
        uint128 oldSenderBalance = _userState[sender].balance;
        _userState[sender].balance = oldSenderBalance - amount;
        uint128 oldRecipientBalance = _userState[recipient].balance;
        _userState[recipient].balance = oldRecipientBalance + amount;

        IIncentivesController incentivesControllerLocal = _incentivesController;
        if (address(incentivesControllerLocal) != address(0)) {
            uint256 currentTotalSupply = _totalSupply;
            incentivesControllerLocal.handleAction(
                sender,
                currentTotalSupply,
                uint256(_userState[sender].balance)
            );
            if (sender != recipient) {
                incentivesControllerLocal.handleAction(
                    recipient,
                    currentTotalSupply,
                    uint256(_userState[recipient].balance)
                );
            }
        }
    }

    /**
     * @notice Approve `spender` to use `amount` of `owner`s balance
     * @param owner The address owning the tokens
     * @param spender The address approved for spending
     * @param amount The amount of tokens to approve spending of
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Update the name of the token
     * @param newName The new name for the token
     */
    function _setName(string memory newName) internal {
        _name = newName;
    }

    /**
     * @notice Update the symbol for the token
     * @param newSymbol The new symbol for the token
     */
    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    /**
     * @notice Update the number of decimals for the token
     * @param newDecimals The new number of decimals for the token
     */
    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VersionedInitializable} from "../libraries/aave-upgradeability/VersionedInitializable.sol";
import {MathUtils} from "../libraries/math/MathUtils.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IIncentivesController} from "../../interfaces/IIncentivesController.sol";
import {IInitializableDebtToken} from "../../interfaces/IInitializableDebtToken.sol";
import {IStableDebtToken} from "../../interfaces/IStableDebtToken.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {EIP712Base} from "./base/EIP712Base.sol";
import {DebtTokenBase} from "./base/DebtTokenBase.sol";
import {IncentivizedERC20} from "./base/IncentivizedERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title StableDebtToken
 * @author maneki.finance
 * @notice Implements a stable debt token to track the borrowing positions of users
 * at stable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 */
contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
    using WadRayMath for uint256;
    using SafeCast for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    // Map of users address and the timestamp of their last update (userAddress => lastUpdateTimestamp)
    mapping(address => uint40) internal _timestamps;

    uint128 internal _avgStableRate;

    // Timestamp of the last update of the total supply
    uint40 internal _totalSupplyTimestamp;

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(
        IPool pool
    )
        DebtTokenBase()
        IncentivizedERC20(
            pool,
            "STABLE_DEBT_TOKEN_IMPL",
            "STABLE_DEBT_TOKEN_IMPL",
            0
        )
    {
        // Intentionally left blank
    }

    /// @inheritdoc IInitializableDebtToken
    function initialize(
        IPool initializingPool,
        address underlyingAsset,
        IIncentivesController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external override initializer {
        require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
        _setName(debtTokenName);
        _setSymbol(debtTokenSymbol);
        _setDecimals(debtTokenDecimals);

        _underlyingAsset = underlyingAsset;
        _incentivesController = incentivesController;

        _domainSeparator = _calculateDomainSeparator();

        emit Initialized(
            underlyingAsset,
            address(POOL),
            address(incentivesController),
            debtTokenDecimals,
            debtTokenName,
            debtTokenSymbol,
            params
        );
    }

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /// @inheritdoc IStableDebtToken
    function getAverageStableRate()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _avgStableRate;
    }

    /// @inheritdoc IStableDebtToken
    function getUserLastUpdated(
        address user
    ) external view virtual override returns (uint40) {
        return _timestamps[user];
    }

    /// @inheritdoc IStableDebtToken
    function getUserStableRate(
        address user
    ) external view virtual override returns (uint256) {
        return _userState[user].additionalData;
    }

    /// @inheritdoc IERC20
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        uint256 accountBalance = super.balanceOf(account);
        uint256 stableRate = _userState[account].additionalData;
        if (accountBalance == 0) {
            return 0;
        }
        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            stableRate,
            _timestamps[account]
        );
        return accountBalance.rayMul(cumulatedInterest);
    }

    struct MintLocalVars {
        uint256 previousSupply;
        uint256 nextSupply;
        uint256 amountInRay;
        uint256 currentStableRate;
        uint256 nextStableRate;
        uint256 currentAvgStableRate;
    }

    /// @inheritdoc IStableDebtToken
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 rate
    ) external virtual override onlyPool returns (bool, uint256, uint256) {
        MintLocalVars memory vars;

        if (user != onBehalfOf) {
            _decreaseBorrowAllowance(onBehalfOf, user, amount);
        }

        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(onBehalfOf);

        vars.previousSupply = totalSupply();
        vars.currentAvgStableRate = _avgStableRate;
        vars.nextSupply = _totalSupply = vars.previousSupply + amount;

        vars.amountInRay = amount.wadToRay();

        vars.currentStableRate = _userState[onBehalfOf].additionalData;
        vars.nextStableRate = (vars.currentStableRate.rayMul(
            currentBalance.wadToRay()
        ) + vars.amountInRay.rayMul(rate)).rayDiv(
                (currentBalance + amount).wadToRay()
            );

        _userState[onBehalfOf].additionalData = vars.nextStableRate.toUint128();

        //solium-disable-next-line
        _totalSupplyTimestamp = _timestamps[onBehalfOf] = uint40(
            block.timestamp
        );

        // Calculates the updated average stable rate
        vars.currentAvgStableRate = _avgStableRate = (
            (vars.currentAvgStableRate.rayMul(vars.previousSupply.wadToRay()) +
                rate.rayMul(vars.amountInRay)).rayDiv(
                    vars.nextSupply.wadToRay()
                )
        ).toUint128();

        uint256 amountToMint = amount + balanceIncrease;
        _mint(onBehalfOf, amountToMint, vars.previousSupply);

        emit Transfer(address(0), onBehalfOf, amountToMint);
        emit Mint(
            user,
            onBehalfOf,
            amountToMint,
            currentBalance,
            balanceIncrease,
            vars.nextStableRate,
            vars.currentAvgStableRate,
            vars.nextSupply
        );

        return (
            currentBalance == 0,
            vars.nextSupply,
            vars.currentAvgStableRate
        );
    }

    /// @inheritdoc IStableDebtToken
    function burn(
        address from,
        uint256 amount
    ) external virtual override onlyPool returns (uint256, uint256) {
        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(from);

        uint256 previousSupply = totalSupply();
        uint256 nextAvgStableRate = 0;
        uint256 nextSupply = 0;
        uint256 userStableRate = _userState[from].additionalData;

        // Since the total supply and each single user debt accrue separately,
        // there might be accumulation errors so that the last borrower repaying
        // might actually try to repay more than the available debt supply.
        // In this case we simply set the total supply and the avg stable rate to 0
        if (previousSupply <= amount) {
            _avgStableRate = 0;
            _totalSupply = 0;
        } else {
            nextSupply = _totalSupply = previousSupply - amount;
            uint256 firstTerm = uint256(_avgStableRate).rayMul(
                previousSupply.wadToRay()
            );
            uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

            // For the same reason described above, when the last user is repaying it might
            // happen that user rate * user balance > avg rate * total supply. In that case,
            // we simply set the avg rate to 0
            if (secondTerm >= firstTerm) {
                nextAvgStableRate = _totalSupply = _avgStableRate = 0;
            } else {
                nextAvgStableRate = _avgStableRate = (
                    (firstTerm - secondTerm).rayDiv(nextSupply.wadToRay())
                ).toUint128();
            }
        }

        if (amount == currentBalance) {
            _userState[from].additionalData = 0;
            _timestamps[from] = 0;
        } else {
            //solium-disable-next-line
            _timestamps[from] = uint40(block.timestamp);
        }
        //solium-disable-next-line
        _totalSupplyTimestamp = uint40(block.timestamp);

        if (balanceIncrease > amount) {
            uint256 amountToMint = balanceIncrease - amount;
            _mint(from, amountToMint, previousSupply);
            emit Transfer(address(0), from, amountToMint);
            emit Mint(
                from,
                from,
                amountToMint,
                currentBalance,
                balanceIncrease,
                userStableRate,
                nextAvgStableRate,
                nextSupply
            );
        } else {
            uint256 amountToBurn = amount - balanceIncrease;
            _burn(from, amountToBurn, previousSupply);
            emit Transfer(from, address(0), amountToBurn);
            emit Burn(
                from,
                amountToBurn,
                currentBalance,
                balanceIncrease,
                nextAvgStableRate,
                nextSupply
            );
        }

        return (nextSupply, nextAvgStableRate);
    }

    /**
     * @notice Calculates the increase in balance since the last user interaction
     * @param user The address of the user for which the interest is being accumulated
     * @return The previous principal balance
     * @return The new principal balance
     * @return The balance increase
     */
    function _calculateBalanceIncrease(
        address user
    ) internal view returns (uint256, uint256, uint256) {
        uint256 previousPrincipalBalance = super.balanceOf(user);

        if (previousPrincipalBalance == 0) {
            return (0, 0, 0);
        }

        uint256 newPrincipalBalance = balanceOf(user);

        return (
            previousPrincipalBalance,
            newPrincipalBalance,
            newPrincipalBalance - previousPrincipalBalance
        );
    }

    /// @inheritdoc IStableDebtToken
    function getSupplyData()
        external
        view
        override
        returns (uint256, uint256, uint256, uint40)
    {
        uint256 avgRate = _avgStableRate;
        return (
            super.totalSupply(),
            _calcTotalSupply(avgRate),
            avgRate,
            _totalSupplyTimestamp
        );
    }

    /// @inheritdoc IStableDebtToken
    function getTotalSupplyAndAvgRate()
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 avgRate = _avgStableRate;
        return (_calcTotalSupply(avgRate), avgRate);
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _calcTotalSupply(_avgStableRate);
    }

    /// @inheritdoc IStableDebtToken
    function getTotalSupplyLastUpdated()
        external
        view
        override
        returns (uint40)
    {
        return _totalSupplyTimestamp;
    }

    /// @inheritdoc IStableDebtToken
    function principalBalanceOf(
        address user
    ) external view virtual override returns (uint256) {
        return super.balanceOf(user);
    }

    /// @inheritdoc IStableDebtToken
    function UNDERLYING_ASSET_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }

    /**
     * @notice Calculates the total supply
     * @param avgRate The average rate at which the total supply increases
     * @return The debt balance of the user since the last burn/mint action
     */
    function _calcTotalSupply(uint256 avgRate) internal view returns (uint256) {
        uint256 principalSupply = super.totalSupply();

        if (principalSupply == 0) {
            return 0;
        }

        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            avgRate,
            _totalSupplyTimestamp
        );

        return principalSupply.rayMul(cumulatedInterest);
    }

    /**
     * @notice Mints stable debt tokens to a user
     * @param account The account receiving the debt tokens
     * @param amount The amount being minted
     * @param oldTotalSupply The total supply before the minting event
     */
    function _mint(
        address account,
        uint256 amount,
        uint256 oldTotalSupply
    ) internal {
        uint128 castAmount = amount.toUint128();
        uint128 oldAccountBalance = _userState[account].balance;
        _userState[account].balance = oldAccountBalance + castAmount;

        if (address(_incentivesController) != address(0)) {
            _incentivesController.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    /**
     * @notice Burns stable debt tokens of a user
     * @param account The user getting his debt burned
     * @param amount The amount being burned
     * @param oldTotalSupply The total supply before the burning event
     */
    function _burn(
        address account,
        uint256 amount,
        uint256 oldTotalSupply
    ) internal {
        uint128 castAmount = amount.toUint128();
        uint128 oldAccountBalance = _userState[account].balance;
        _userState[account].balance = oldAccountBalance - castAmount;

        if (address(_incentivesController) != address(0)) {
            _incentivesController.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    /// @inheritdoc EIP712Base
    function _EIP712BaseId() internal view override returns (string memory) {
        return name();
    }

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     */
    function transfer(
        address,
        uint256
    ) external virtual override returns (bool) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function allowance(
        address,
        address
    ) external view virtual override returns (uint256) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function approve(
        address,
        uint256
    ) external virtual override returns (bool) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external virtual override returns (bool) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function increaseAllowance(
        address,
        uint256
    ) external virtual override returns (bool) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function decreaseAllowance(
        address,
        uint256
    ) external virtual override returns (bool) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }
}