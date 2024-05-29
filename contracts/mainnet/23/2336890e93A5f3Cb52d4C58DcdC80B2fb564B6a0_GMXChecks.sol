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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILendingVault {

  /* ======================= STRUCTS ========================= */

  struct Borrower {
    // Debt share of the borrower in this vault
    uint256 debt;
    // The last timestamp borrower borrowed from this vault
    uint256 lastUpdatedAt;
  }

  struct InterestRate {
    // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
    uint256 baseRate;
    // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    uint256 multiplier;
    // Multiplier after hitting a specified utilization point (kink2) in 1e18
    uint256 jumpMultiplier;
    // Utilization point at which the interest rate is fixed in 1e18
    uint256 kink1;
    // Utilization point at which the jump multiplier is applied in 1e18
    uint256 kink2;
  }

  function totalBorrows() external view returns (uint256);
  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPRPerBorrower(address borrower) external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function approvedBorrower(address borrower) external view returns (bool);
  function approvedBorrowers() external view returns (address[] memory);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(
    address borrower,
    InterestRate memory newInterestRate
  ) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyPause() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateMaxInterestRate(
    address borrower,
    InterestRate memory newMaxInterestRate
  ) external;
  function updateTreasury(address newTreasury) external;
  function updateMaxBorrowers(uint256 newMaxBorrowers) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function updateTokenToDenominatorToken(address token, address dt) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGMXOracle {
  struct MarketPoolValueInfoProps {
    int256 poolValue;
    int256 longPnl;
    int256 shortPnl;
    int256 netPnl;

    uint256 longTokenAmount;
    uint256 shortTokenAmount;
    uint256 longTokenUsd;
    uint256 shortTokenUsd;

    uint256 totalBorrowingFees;
    uint256 borrowingFeePoolFactor;

    uint256 impactPoolAmount;
  }

  function getAmountsOut(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenIn,
    uint256 amountIn
  ) external view returns (uint256);

  function getAmountsIn(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenOut,
    uint256 amountsOut
  ) external view returns (uint256);

  function getMarketTokenInfo(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bytes32 pnlFactorType,
    bool maximize
  ) external view returns (
    int256,
    MarketPoolValueInfoProps memory
  );

  function getLpTokenReserves(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);

  function getLpTokenAmount(
    uint256 givenValue,
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);

  function updateDataStore(address newDataStore) external;
  function updateSyntheticReader(address newSyntheticReader) external;
  function updateChainlinkOracle(address newChainlinkOracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDeposit {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account depositing liquidity
  // @param receiver the address to send the liquidity tokens to
  // @param callbackContract the callback contract
  // @param uiFeeReceiver the ui fee receiver
  // @param market the market to deposit to
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param initialLongTokenAmount the amount of long tokens to deposit
  // @param initialShortTokenAmount the amount of short tokens to deposit
  // @param minMarketTokens the minimum acceptable number of liquidity tokens
  // @param updatedAtBlock the block that the deposit was last updated at
  // sending funds back to the user in case the deposit gets cancelled
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  struct Numbers {
    uint256 initialLongTokenAmount;
    uint256 initialShortTokenAmount;
    uint256 minMarketTokens;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IEvent {
  struct Props {
    AddressItems addressItems;
    UintItems uintItems;
    IntItems intItems;
    BoolItems boolItems;
    Bytes32Items bytes32Items;
    BytesItems bytesItems;
    StringItems stringItems;
  }

  struct AddressItems {
    AddressKeyValue[] items;
    AddressArrayKeyValue[] arrayItems;
  }

  struct UintItems {
    UintKeyValue[] items;
    UintArrayKeyValue[] arrayItems;
  }

  struct IntItems {
    IntKeyValue[] items;
    IntArrayKeyValue[] arrayItems;
  }

  struct BoolItems {
    BoolKeyValue[] items;
    BoolArrayKeyValue[] arrayItems;
  }

  struct Bytes32Items {
    Bytes32KeyValue[] items;
    Bytes32ArrayKeyValue[] arrayItems;
  }

  struct BytesItems {
    BytesKeyValue[] items;
    BytesArrayKeyValue[] arrayItems;
  }

  struct StringItems {
    StringKeyValue[] items;
    StringArrayKeyValue[] arrayItems;
  }

  struct AddressKeyValue {
    string key;
    address value;
  }

  struct AddressArrayKeyValue {
    string key;
    address[] value;
  }

  struct UintKeyValue {
    string key;
    uint256 value;
  }

  struct UintArrayKeyValue {
    string key;
    uint256[] value;
  }

  struct IntKeyValue {
    string key;
    int256 value;
  }

  struct IntArrayKeyValue {
    string key;
    int256[] value;
  }

  struct BoolKeyValue {
    string key;
    bool value;
  }

  struct BoolArrayKeyValue {
    string key;
    bool[] value;
  }

  struct Bytes32KeyValue {
    string key;
    bytes32 value;
  }

  struct Bytes32ArrayKeyValue {
    string key;
    bytes32[] value;
  }

  struct BytesKeyValue {
    string key;
    bytes value;
  }

  struct BytesArrayKeyValue {
    string key;
    bytes[] value;
  }

  struct StringKeyValue {
    string key;
    string value;
  }

  struct StringArrayKeyValue {
    string key;
    string[] value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IExchangeRouter {
  struct CreateDepositParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minMarketTokens;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateWithdrawalParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateOrderParams {
    CreateOrderParamsAddresses addresses;
    CreateOrderParamsNumbers numbers;
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    bool isLong;
    bool shouldUnwrapNativeToken;
    bytes32 referralCode;
  }

  struct CreateOrderParamsAddresses {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  struct CreateOrderParamsNumbers {
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
  }

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  function sendWnt(address receiver, uint256 amount) external payable;

  function sendTokens(
    address token,
    address receiver,
    uint256 amount
  ) external payable;

  function createDeposit(
    CreateDepositParams calldata params
  ) external payable returns (bytes32);

  function createWithdrawal(
    CreateWithdrawalParams calldata params
  ) external payable returns (bytes32);

  function createOrder(
    CreateOrderParams calldata params
  ) external payable returns (bytes32);

  function cancelDeposit(bytes32 key) external payable;

  function cancelWithdrawal(bytes32 key) external payable;

  function cancelOrder(bytes32 key) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOrder {
  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  // to help further differentiate orders
  enum SecondaryOrderType {
    None,
    Adl
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account of the order
  // @param receiver the receiver for any token transfers
  // this field is meant to allow the output of an order to be
  // received by an address that is different from the creator of the
  // order whether this is for swaps or whether the account is the owner
  // of a position
  // for funding fees and claimable collateral, the funds are still
  // credited to the owner of the position indicated by order.account
  // @param callbackContract the contract to call for callbacks
  // @param uiFeeReceiver the ui fee receiver
  // @param market the trading market
  // @param initialCollateralToken for increase orders, initialCollateralToken
  // is the token sent in by the user, the token will be swapped through the
  // specified swapPath, before being deposited into the position as collateral
  // for decrease orders, initialCollateralToken is the collateral token of the position
  // withdrawn collateral from the decrease of the position will be swapped
  // through the specified swapPath
  // for swaps, initialCollateralToken is the initial token sent for the swap
  // @param swapPath an array of market addresses to swap through
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  // @param sizeDeltaUsd the requested change in position size
  // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
  // is the amount of the initialCollateralToken sent in by the user
  // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
  // collateralToken to withdraw
  // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
  // in for the swap
  // @param orderType the order type
  // @param triggerPrice the trigger price for non-market orders
  // @param acceptablePrice the acceptable execution price for increase / decrease orders
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  // @param minOutputAmount the minimum output amount for decrease orders and swaps
  // note that for decrease orders, multiple tokens could be received, for this reason, the
  // minOutputAmount value is treated as a USD value for validation in decrease orders
  // @param updatedAtBlock the block at which the order was last updated
  struct Numbers {
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
    uint256 updatedAtBlock;
  }

  // @param isLong whether the order is for a long or short
  // @param shouldUnwrapNativeToken whether to unwrap native tokens before
  // transferring to the user
  // @param isFrozen whether the order is frozen
  struct Flags {
    bool isLong;
    bool shouldUnwrapNativeToken;
    bool isFrozen;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWithdrawal {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account The account to withdraw for.
  // @param receiver The address that will receive the withdrawn tokens.
  // @param callbackContract The contract that will be called back.
  // @param uiFeeReceiver The ui fee receiver.
  // @param market The market on which the withdrawal will be executed.
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param marketTokenAmount The amount of market tokens that will be withdrawn.
  // @param minLongTokenAmount The minimum amount of long tokens that must be withdrawn.
  // @param minShortTokenAmount The minimum amount of short tokens that must be withdrawn.
  // @param updatedAtBlock The block at which the withdrawal was last updated.
  // @param executionFee The execution fee for the withdrawal.
  // @param callbackGasLimit The gas limit for calling the callback contract.
  struct Numbers {
    uint256 marketTokenAmount;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { GMXTypes } from  "../../../strategy/gmx/GMXTypes.sol";

interface IGMXVault {
  function store() external view returns (GMXTypes.Store memory);
  function deposit(GMXTypes.DepositParams memory dp) external payable;
  function depositNative(GMXTypes.DepositParams memory dp) external payable;
  function processDeposit(uint256 lpAmtReceived) external;
  function processDepositCancellation() external;
  function processDepositFailure(uint256 executionFee) external payable;
  function processDepositFailureLiquidityWithdrawal(
    uint256 tokenAReceived,
    uint256 tokenBReceived,
    uint256 executionFee
  ) external payable;
  function processDepositFailureLiquidityWithdrawalOrderExecuted(
    uint256 oTokenReceived
  ) external;
  function processDepositFailureLiquidityWithdrawalOrderCancelled() external;
  function processDepositFailureLiquidityWithdrawalOrderFrozen() external;

  function withdraw(GMXTypes.WithdrawParams memory wp) external payable;
  function processWithdraw(
    uint256 tokenAReceived,
    uint256 tokenBReceived,
    uint256 executionFee
  ) external payable;
  function processWithdrawOrderExecuted(uint256 oTokenReceived) external;
  function processWithdrawOrderCancelled() external;
  function processWithdrawOrderFrozen() external;
  function processWithdrawCancellation() external;
  function processWithdrawFailure(uint256 executionFee) external payable;
  function processWithdrawFailureLiquidityAdded(uint256 lpAmtReceived) external;

  function rebalanceAdd(
    GMXTypes.RebalanceAddParams memory rap
  ) external payable;
  function processRebalanceAdd(uint256 lpAmtReceived) external;
  function processRebalanceAddCancellation() external;

  function rebalanceRemove(
    GMXTypes.RebalanceRemoveParams memory rrp
  ) external payable;
  function processRebalanceRemove(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external;
  function processRebalanceRemoveCancellation() external;
  function rebalanceClose() external;

  function compound(GMXTypes.CompoundParams memory cp) external payable;
  function processCompound(uint256 lpAmtReceived) external;
  function processCompoundCancellation() external;
  function compoundLP() external;

  function emergencyPause() external;
  function emergencyRepay() external payable;
  function processEmergencyRepay(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external;
  function emergencyBorrow() external;
  function emergencyResume() external payable;
  function processEmergencyResume(uint256 lpAmtReceived) external;
  function processEmergencyResumeCancellation() external;
  function emergencyClose() external;
  function emergencyWithdraw(uint256 shareAmt) external;
  function emergencyStatusChange(GMXTypes.Status status) external;

  function updateKeeper(address keeper) external;
  function updateTreasury(address treasury) external;
  function updateSwapRouter(address swapRouter) external;
  function updateLendingVaults(
    address newTokenALendingVault,
    address newTokenBLendingVault
  ) external;
  function updateCallback(address callback) external;
  function updateFeePerSecond(uint256 feePerSecond) external;
  function updateParameterLimits(
    uint256 newLeverage,
    uint256 debtRatioStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external;
  function updateMinVaultSlippage(uint256 minVaultSlippage) external;
  function updateLiquiditySlippage(uint256 liquiditySlippage) external;
  function updateSwapSlippage(uint256 swapSlippage) external;
  function updateCallbackGasLimit(uint256 callbackGasLimit) external;
  function updateChainlinkOracle(address addr) external;
  function updateGMXOracle(address addr) external;
  function updateGMXExchangeRouter(address addr) external;
  function updateGMXRouter(address addr) external;
  function updateGMXDepositVault(address addr) external;
  function updateGMXWithdrawalVault(address addr) external;
  function updateGMXOrderVault(address addr) external;
  function updateGMXRoleStore(address addr) external;
  function updateMinAssetValue(uint256 value) external;
  function updateMaxAssetValue(uint256 value) external;

  function externalCall(
    address addr,
    string memory signature,
    bytes memory args
  ) external returns (bytes memory);

  function mintFee() external;
  function mint(address to, uint256 amt) external;
  function burn(address to, uint256 amt) external;

  function emitProcessEvent(
    GMXTypes.CallbackType callbackType,
    bytes32 depositKey,
    bytes32 withdrawKey,
    bytes32 orderKey,
    uint256 lpAmtReceived,
    uint256 tokenAReceived,
    uint256 tokenBReceived,
    uint256 oTokenReceived
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ISwap {
  struct SwapParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in; in token decimals
    uint256 amountIn;
    // Amount of token out; in token decimals
    uint256 amountOut;
    // Slippage tolerance swap; e.g. 3 = 0.03%
    uint256 slippage;
    // Swap deadline timestamp
    uint256 deadline;
  }

  function swapExactTokensForTokens(
    SwapParams memory sp
  ) external returns (uint256);

  function swapTokensForExactTokens(
    SwapParams memory sp
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWNT {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IDeposit } from "../../interfaces/protocols/gmx/IDeposit.sol";
import { IWithdrawal } from "../../interfaces/protocols/gmx/IWithdrawal.sol";
import { IEvent } from "../../interfaces/protocols/gmx/IEvent.sol";
import { IOrder } from "../../interfaces/protocols/gmx/IOrder.sol";
import { Errors } from "../../utils/Errors.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";

/**
  * @title GMXChecks
  * @author Steadefi
  * @notice Re-usable library functions for require function checks for Steadefi leveraged vaults
*/
library GMXChecks {

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice Checks before native token deposit
    * @param self GMXTypes.Store
    * @param dp GMXTypes.DepositParams
  */
  function beforeNativeDepositChecks(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp
  ) external view {
    if (dp.token != address(self.WNT))
      revert Errors.InvalidNativeTokenAddress();

    if (
      address(self.tokenA) != address(self.WNT) &&
      address(self.tokenB) != address(self.WNT)
    ) revert Errors.OnlyNonNativeDepositToken();

    if (dp.amt == 0) revert Errors.EmptyDepositAmount();

    if (dp.amt + dp.executionFee != msg.value)
      revert Errors.DepositAndExecutionFeeDoesNotMatchMsgValue();
  }

  /**
    * @notice Checks before token deposit
    * @param self GMXTypes.Store
    * @param depositValue USD value in 1e18
  */
  function beforeDepositChecks(
    GMXTypes.Store storage self,
    uint256 depositValue
  ) external view {
    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (
      self.depositCache.depositParams.token != address(self.tokenA) &&
      self.depositCache.depositParams.token != address(self.tokenB) &&
      self.depositCache.depositParams.token != address(self.lpToken)
    ) {
      revert Errors.InvalidDepositToken();
    }

    if (self.depositCache.depositParams.amt == 0)
      revert Errors.InsufficientDepositAmount();

    if (self.depositCache.depositParams.slippage < self.minVaultSlippage)
      revert Errors.InsufficientVaultSlippageAmount();

    if (depositValue == 0)
      revert Errors.InsufficientDepositValue();

    if (depositValue < self.minAssetValue)
      revert Errors.InsufficientDepositValue();

    if (depositValue > self.maxAssetValue)
      revert Errors.ExcessiveDepositValue();

    if (depositValue > GMXReader.additionalCapacity(self))
      revert Errors.InsufficientLendingLiquidity();

    if (GMXReader.equityValue(self) == 0 && IERC20(address(self.vault)).totalSupply() > 0)
      revert Errors.DepositNotAllowedWhenEquityIsZero();
  }

  /**
    * @notice Checks before processing deposit
    * @param self GMXTypes.Store
  */
  function beforeProcessDepositChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks after deposit
    * @param self GMXTypes.Store
  */
  function afterDepositChecks(
    GMXTypes.Store storage self
  ) external view {
    // Guards: revert if lpAmt did not increase at all
    if (GMXReader.lpAmt(self) <= self.depositCache.healthParams.lpAmtBefore)
      revert Errors.InsufficientLPTokensMinted();

    // Guards: check that debt ratio is within step change range
    if (!_isWithinStepChange(
      self.depositCache.healthParams.debtRatioBefore,
      GMXReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Slippage: Check whether user received enough shares as expected
    if (self.depositCache.sharesToUser < self.depositCache.minSharesAmt)
      revert Errors.InsufficientSharesMinted();
  }

  /**
    * @notice Checks before processing deposit cancellation
    * @param self GMXTypes.Store
  */
  function beforeProcessDepositCancellationChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after deposit check failure
    * @param self GMXTypes.Store
  */
  function beforeProcessAfterDepositFailureChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after deposit failure's liquidity withdrawn
    * @param self GMXTypes.Store
  */
  function beforeProcessAfterDepositFailureLiquidityWithdrawal(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after deposit failure's liquidity withdrawn and order created
    * @param self GMXTypes.Store
  */
  function beforeProcessAfterDepositFailureLiquidityWithdrawalOrderExecuted(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit_Failed_Order_Created)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after deposit failure's liquidity withdrawn and order created
    * @param self GMXTypes.Store
  */
  function beforeProcessAfterDepositFailureLiquidityWithdrawalOrderCancelled(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit_Failed_Order_Created)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after deposit failure's liquidity withdrawn and order created
    * @param self GMXTypes.Store
  */
  function beforeProcessAfterDepositFailureLiquidityWithdrawalOrderFrozen(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit_Failed_Order_Created)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before vault withdrawal
    * @param self GMXTypes.Store

  */
  function beforeWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (
      self.withdrawCache.withdrawParams.token != address(self.tokenA) &&
      self.withdrawCache.withdrawParams.token != address(self.tokenB)
    ) {
      revert Errors.InvalidWithdrawToken();
    }

    if (self.withdrawCache.withdrawParams.shareAmt == 0)
      revert Errors.EmptyWithdrawAmount();

    if (
      self.withdrawCache.withdrawParams.shareAmt >
      IERC20(address(self.vault)).balanceOf(self.withdrawCache.user)
    ) revert Errors.InsufficientWithdrawBalance();

    if (self.withdrawCache.withdrawValue > self.maxAssetValue)
      revert Errors.ExcessiveWithdrawValue();

    if (self.withdrawCache.withdrawParams.slippage < self.minVaultSlippage)
      revert Errors.InsufficientVaultSlippageAmount();

    if (self.withdrawCache.withdrawParams.executionFee != msg.value)
      revert Errors.InvalidExecutionFeeAmount();
  }

  /**
    * @notice Checks before processing vault withdrawal
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing vault withdrawal after order executed
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawOrderExecutedChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw_Order_Created)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

    /**
    * @notice Checks before processing vault withdrawal after order cancelled
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawOrderCancelled(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw_Order_Created)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

    /**
    * @notice Checks before processing vault withdrawal after order frozen
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawOrderFrozen(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw_Order_Created)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks after token withdrawal
    * @param self GMXTypes.Store
  */
  function afterWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    // Guards: revert if lpAmt did not decrease at all
    if (GMXReader.lpAmt(self) >= self.withdrawCache.healthParams.lpAmtBefore)
      revert Errors.InsufficientLPTokensBurned();

    // Guards: revert if equity did not decrease at all
    if (
      self.withdrawCache.healthParams.equityAfter >=
      self.withdrawCache.healthParams.equityBefore
    ) revert Errors.InvalidEquityAfterWithdraw();

    // Guards: check that debt ratio is within step change range
    if (!_isWithinStepChange(
      self.withdrawCache.healthParams.debtRatioBefore,
      GMXReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Check that user received enough assets as expected
    if (self.withdrawCache.assetsToUser < self.withdrawCache.minAssetsAmt)
      revert Errors.InsufficientAssetsReceived();
  }

  /**
    * @notice Checks before processing withdrawal cancellation
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawCancellationChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after withdrawal failure
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawFailureChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after withdraw failure's liquidity added
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawFailureLiquidityAdded(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before rebalancing
    * @param self GMXTypes.Store
    * @param rebalanceType GMXTypes.RebalanceType
  */
  function beforeRebalanceChecks(
    GMXTypes.Store storage self,
    GMXTypes.RebalanceType rebalanceType
  ) external view {
    if (
      self.status != GMXTypes.Status.Open &&
      self.status != GMXTypes.Status.Rebalance_Open
    ) revert Errors.NotAllowedInCurrentVaultStatus();

    // Check that rebalance type is Delta or Debt
    // And then check that rebalance conditions are met
    // Note that Delta rebalancing requires vault's delta strategy to be Neutral as well
    if (rebalanceType == GMXTypes.RebalanceType.Delta && self.delta == GMXTypes.Delta.Neutral) {
      if (
        self.rebalanceCache.healthParams.deltaBefore <= self.deltaUpperLimit &&
        self.rebalanceCache.healthParams.deltaBefore >= self.deltaLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    } else if (rebalanceType == GMXTypes.RebalanceType.Debt) {
      if (
        self.rebalanceCache.healthParams.debtRatioBefore <= self.debtRatioUpperLimit &&
        self.rebalanceCache.healthParams.debtRatioBefore >= self.debtRatioLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    } else {
       revert Errors.InvalidRebalanceParameters();
    }
  }

  /**
    * @notice Checks before processing of rebalancing add or remove
    * @param self GMXTypes.Store
  */
  function beforeProcessRebalanceChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status != GMXTypes.Status.Rebalance_Add &&
      self.status != GMXTypes.Status.Rebalance_Remove
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks after rebalancing add or remove
    * @param self GMXTypes.Store
  */
  function afterRebalanceChecks(
    GMXTypes.Store storage self
  ) external view {
    // Guards: check that delta is within limits for Neutral strategy
    if (self.delta == GMXTypes.Delta.Neutral) {
      int256 _delta = GMXReader.delta(self);

      if (
        _delta > self.deltaUpperLimit ||
        _delta < self.deltaLowerLimit
      ) revert Errors.InvalidDelta();
    }

    // Guards: check that debt is within limits for Long/Neutral strategy
    uint256 _debtRatio = GMXReader.debtRatio(self);

    if (
      _debtRatio > self.debtRatioUpperLimit ||
      _debtRatio < self.debtRatioLowerLimit
    ) revert Errors.InvalidDebtRatio();
  }

  /**
    * @notice Checks before forcefully closing rebalance
    * @param self GMXTypes.Store
  */
  function beforeRebalanceCloseChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Rebalance_Open)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before compound
    * @param self GMXTypes.Store
  */
  function beforeCompoundChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status != GMXTypes.Status.Open
    ) revert Errors.NotAllowedInCurrentVaultStatus();

    if (self.compoundCache.depositValue == 0)
      revert Errors.InsufficientDepositAmount();
  }

  /**
    * @notice Checks before processing compound
    * @param self GMXTypes.Store
  */
  function beforeProcessCompoundChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Compound)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing compound cancellation
    * @param self GMXTypes.Store
  */
  function beforeProcessCompoundCancellationChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Compound)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before compound
    * @param self GMXTypes.Store
  */
  function beforeCompoundLPChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status != GMXTypes.Status.Open
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency pausing of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyPauseChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status == GMXTypes.Status.Paused ||
      self.status == GMXTypes.Status.Resume ||
      self.status == GMXTypes.Status.Repaid ||
      self.status == GMXTypes.Status.Closed
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency repaying of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyRepayChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Paused)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing emergency pausing of vault
    * @param self GMXTypes.Store
  */
  function beforeProcessEmergencyRepayChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Repay)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency re-borrowing assets of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyBorrowChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Repaid)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before resuming vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyResumeChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Paused)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing resuming of vault
    * @param self GMXTypes.Store
  */
  function beforeProcessEmergencyResumeChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Resume)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing resume cancellation of vault
    * @param self GMXTypes.Store
  */
  function beforeProcessEmergencyResumeCancellationChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Resume)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency closure of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyCloseChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Repaid)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before a withdrawal during emergency closure
    * @param self GMXTypes.Store
    * @param shareAmt Amount of shares to burn
  */
  function beforeEmergencyWithdrawChecks(
    GMXTypes.Store storage self,
    uint256 shareAmt
  ) external view {
    if (self.status != GMXTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (shareAmt == 0)
      revert Errors.EmptyWithdrawAmount();

    if (shareAmt > IERC20(address(self.vault)).balanceOf(msg.sender))
      revert Errors.InsufficientWithdrawBalance();
  }

  /**
    * @notice Checks before emergency status change
    * @param self GMXTypes.Store
  */
  function beforeEmergencyStatusChangeChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status == GMXTypes.Status.Open ||
      self.status == GMXTypes.Status.Repaid ||
      self.status == GMXTypes.Status.Closed
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before shares are minted
    * @param self GMXTypes.Store
  */
  function beforeMintFeeChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status == GMXTypes.Status.Paused || self.status == GMXTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /* ================== INTERNAL FUNCTIONS =================== */

  /**
    * @notice Check if values are within threshold range
    * @param valueBefore Previous value
    * @param valueAfter New value
    * @param threshold Tolerance threshold; 100 = 1%
    * @return boolean Whether value after is within threshold range
  */
  function _isWithinStepChange(
    uint256 valueBefore,
    uint256 valueAfter,
    uint256 threshold
  ) internal pure returns (bool) {
    // To bypass initial vault deposit
    if (valueBefore == 0)
      return true;

    return (
      valueAfter >= valueBefore * (10000 - threshold) / 10000 &&
      valueAfter <= valueBefore * (10000 + threshold) / 10000
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { GMXTypes } from "./GMXTypes.sol";

/**
  * @title GMXReader
  * @author Steadefi
  * @notice Re-usable library functions for reading data and values for Steadefi leveraged vaults
*/
library GMXReader {
  using SafeCast for uint256;

  /* =================== CONSTANTS FUNCTIONS ================= */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function svTokenValue(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 equityValue_ = equityValue(self);
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    return equityValue_ * SAFE_MULTIPLIER / (totalSupply_ + pendingFee(self));
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function pendingFee(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    uint256 _secondsFromLastCollection = block.timestamp - self.lastFeeCollected;
    return (totalSupply_ * self.feePerSecond * _secondsFromLastCollection) / SAFE_MULTIPLIER;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function valueToShares(
    GMXTypes.Store storage self,
    uint256 value,
    uint256 currentEquity
  ) public view returns (uint256) {
    uint256 _sharesSupply = IERC20(address(self.vault)).totalSupply() + pendingFee(self);
    if (_sharesSupply == 0 || currentEquity == 0) return value;
    return value * _sharesSupply / currentEquity;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function convertToUsdValue(
    GMXTypes.Store storage self,
    address token,
    uint256 amt
  ) public view returns (uint256) {
    return (amt * self.chainlinkOracle.consultIn18Decimals(token))
      / (10 ** IERC20Metadata(token).decimals());
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function tokenWeights(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    // Get amounts of tokenA and tokenB in liquidity pool in token decimals
    (uint256 _reserveA, uint256 _reserveB) = self.gmxOracle.getLpTokenReserves(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB)
    );

    // Get value of tokenA and tokenB in 1e18
    uint256 _tokenAValue = convertToUsdValue(self, address(self.tokenA), _reserveA);
    uint256 _tokenBValue = convertToUsdValue(self, address(self.tokenB), _reserveB);

    uint256 _totalLpValue = _tokenAValue + _tokenBValue;

    return (
      _tokenAValue * SAFE_MULTIPLIER / _totalLpValue,
      _tokenBValue * SAFE_MULTIPLIER / _totalLpValue
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function assetValue(GMXTypes.Store storage self) public view returns (uint256) {
    return lpAmt(self) * self.gmxOracle.getLpTokenValue(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB),
      true,
      false
    ) / SAFE_MULTIPLIER;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function debtValue(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt) = debtAmt(self);
    return (
      convertToUsdValue(self, address(self.tokenA), _tokenADebtAmt),
      convertToUsdValue(self, address(self.tokenB), _tokenBDebtAmt)
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function equityValue(GMXTypes.Store storage self) public view returns (uint256) {
    (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt) = debtAmt(self);

    uint256 assetValue_ = assetValue(self);

    uint256 _debtValue = convertToUsdValue(self, address(self.tokenA), _tokenADebtAmt)
      + convertToUsdValue(self, address(self.tokenB), _tokenBDebtAmt);

    // in underflow condition return 0
    unchecked {
      if (assetValue_ < _debtValue) return 0;
      return assetValue_ - _debtValue;
    }
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function assetAmt(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    (uint256 _reserveA, uint256 _reserveB) = self.gmxOracle.getLpTokenReserves(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB)
    );

    return (
      _reserveA * SAFE_MULTIPLIER * lpAmt(self) / self.lpToken.totalSupply() / SAFE_MULTIPLIER,
      _reserveB * SAFE_MULTIPLIER * lpAmt(self) / self.lpToken.totalSupply() / SAFE_MULTIPLIER
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @dev Delta Long will never borrow tokenA, Delta Short will never borrow tokenB
    * @dev We return the values accordingly based on the strategy type to ensure no errors
    * occur due to a tokenLendingVault being address(0)
    * @param self GMXTypes.Store
  */
  function debtAmt(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    if (self.delta == GMXTypes.Delta.Long) {
      return (
        0,
        self.tokenBLendingVault.maxRepay(address(self.vault))
      );
    }
    else if (self.delta == GMXTypes.Delta.Short) {
      return (
        self.tokenALendingVault.maxRepay(address(self.vault)),
        0
      );
    }
    else {
      return (
        self.tokenALendingVault.maxRepay(address(self.vault)),
        self.tokenBLendingVault.maxRepay(address(self.vault))
      );
    }
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function lpAmt(GMXTypes.Store storage self) public view returns (uint256) {
    return self.lpAmt;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function leverage(GMXTypes.Store storage self) public view returns (uint256) {
    if (assetValue(self) == 0 || equityValue(self) == 0) return 0;
    return assetValue(self) * SAFE_MULTIPLIER / equityValue(self);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function delta(GMXTypes.Store storage self) public view returns (int256) {
    (uint256 _tokenAAmt,) = assetAmt(self);
    (uint256 _tokenADebtAmt,) = debtAmt(self);
    uint256 equityValue_ = equityValue(self);

    if (_tokenAAmt == 0 && _tokenADebtAmt == 0) return 0;
    if (equityValue_ == 0) return 0;

    bool _isPositive = _tokenAAmt >= _tokenADebtAmt;

    uint256 _unsignedDelta = _isPositive ?
      _tokenAAmt - _tokenADebtAmt :
      _tokenADebtAmt - _tokenAAmt;

    int256 signedDelta = (_unsignedDelta
      * self.chainlinkOracle.consultIn18Decimals(address(self.tokenA))
      / equityValue_).toInt256();

    if (_isPositive) return signedDelta;
    else return -signedDelta;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function debtRatio(GMXTypes.Store storage self) public view returns (uint256) {
    (uint256 _tokenADebtValue, uint256 _tokenBDebtValue) = debtValue(self);
    if (assetValue(self) == 0) return 0;
    return (_tokenADebtValue + _tokenBDebtValue) * SAFE_MULTIPLIER / assetValue(self);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function additionalCapacity(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 _additionalCapacity;

    // Long strategy only borrows short token (typically stablecoin)
    if (self.delta == GMXTypes.Delta.Long) {
      _additionalCapacity = convertToUsdValue(
        self,
        address(self.tokenB),
        self.tokenBLendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER / (self.leverage - 1e18);
    }

    // Short strategy only borrows long token
    if (self.delta == GMXTypes.Delta.Short) {
      _additionalCapacity = convertToUsdValue(
        self,
        address(self.tokenA),
        self.tokenALendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER / (self.leverage - 1e18);
    }

    // Neutral strategy borrows both long (typical volatile) and short token (typically stablecoin)
    // Amount of long token to borrow is equivalent to deposited value x leverage x longTokenWeight
    // Amount of short token to borrow is remaining borrow value AFTER borrowing long token
    // ---------------------------------------------------------------------------------------------
    // E.g: 3x Neutral ETH-USDC with weight of ETH being 55%, USDC 45%
    // A $1 equity deposit should result in a $2 borrow for a total of $3 assets
    // Amount of ETH to borrow would be $3 x 55% = $1.65 worth of ETH
    // Amount of USDC to borrow would be $3 (asset) - $1.65 (ETH borrowed) - $1 (equity) = $0.35
    // ---------------------------------------------------------------------------------------------
    // Note that for Neutral strategies, vault's leverage has to be 3x and above.
    // A 2x leverage neutral strategy may not work to correctly to borrow enough long token to hedge
    // while still adhering to the correct leverage factor.
    // Note also that tokenBWeight and leverage factor may result in a negative _maxTokenBLending
    // For e.g. if tokenBWeight drops to 33% with leverage being 3x, _maxTokenBLending would be less
    // than 1.0 and based on the code logic below it will underflow. The proper way to resolve
    // this issue is to increase the leverage factor so that we can properly borrow enough to hedge
    // tokenA while also adhering to the correct leverage factor.
    if (self.delta == GMXTypes.Delta.Neutral) {
      (uint256 _tokenAWeight, uint256 _tokenBWeight) = tokenWeights(self);

      uint256 _maxTokenALending = convertToUsdValue(
        self,
        address(self.tokenA),
        self.tokenALendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER
        / (self.leverage * _tokenAWeight / SAFE_MULTIPLIER);

      uint256 _maxTokenBLending = convertToUsdValue(
        self,
        address(self.tokenB),
        self.tokenBLendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER
        / (self.leverage * _tokenBWeight / SAFE_MULTIPLIER - 1e18);

      _additionalCapacity = _maxTokenALending > _maxTokenBLending ? _maxTokenBLending : _maxTokenALending;
    }

    return _additionalCapacity;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function capacity(GMXTypes.Store storage self) public view returns (uint256) {
    return additionalCapacity(self) + equityValue(self);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWNT } from "../../interfaces/tokens/IWNT.sol";
import { ILendingVault } from "../../interfaces/lending/ILendingVault.sol";
import { IGMXVault } from "../../interfaces/strategy/gmx/IGMXVault.sol";
import { IChainlinkOracle } from "../../interfaces/oracles/IChainlinkOracle.sol";
import { IGMXOracle } from "../../interfaces/oracles/IGMXOracle.sol";
import { IExchangeRouter } from "../../interfaces/protocols/gmx/IExchangeRouter.sol";
import { ISwap } from "../../interfaces/swap/ISwap.sol";

/**
  * @title GMXTypes
  * @author Steadefi
  * @notice Re-usable library of Types struct definitions for Steadefi leveraged vaults
*/
library GMXTypes {

  /* ======================= STRUCTS ========================= */

  struct Store {
    // Status of the vault
    Status status;
    // Should emergency pause as soon as possible
    bool shouldEmergencyPause;

    // Amount of LP tokens that vault accounts for as total assets
    uint256 lpAmt;

    // Timestamp when vault last collected management fee
    uint256 lastFeeCollected;
    // Keeper address that receives some execution fees for callback execution
    address payable keeper;

    // Target leverage of the vault in 1e18
    uint256 leverage;
    // Delta strategy
    Delta delta;
    // Management fee per second in % in 1e18
    uint256 feePerSecond;
    // Treasury address
    address treasury;

    // Guards: change threshold for debtRatio change after deposit/withdraw
    uint256 debtRatioStepThreshold; // in 1e4; e.g. 500 = 5%
    // Guards: upper limit of debt ratio after rebalance
    uint256 debtRatioUpperLimit; // in 1e18; 69e16 = 0.69 = 69%
    // Guards: lower limit of debt ratio after rebalance
    uint256 debtRatioLowerLimit; // in 1e18; 61e16 = 0.61 = 61%
    // Guards: upper limit of delta after rebalance
    int256 deltaUpperLimit; // in 1e18; 15e16 = 0.15 = +15%
    // Guards: lower limit of delta after rebalance
    int256 deltaLowerLimit; // in 1e18; -15e16 = -0.15 = -15%
    // Guards: Minimum vault slippage for vault shares/assets in 1e4; e.g. 100 = 1%
    uint256 minVaultSlippage;
    // Slippage for adding/removing liquidity in 1e4; e.g. 100 = 1%
    uint256 liquiditySlippage;
    // Slippage for swaps in 1e4; e.g. 100 = 1%
    uint256 swapSlippage;
    // GMX callback gas limit setting
    uint256 callbackGasLimit;
    // Minimum asset value per vault deposit/withdrawal
    uint256 minAssetValue;
    // Maximum asset value per vault deposit/withdrawal
    uint256 maxAssetValue;

    // Token A in this strategy; long token + index token
    IERC20 tokenA;
    // Token B in this strategy; short token
    IERC20 tokenB;
    // LP token of this strategy; market token
    IERC20 lpToken;
    // Native token for this chain (e.g. WETH, WAVAX, WBNB, etc.)
    IWNT WNT;
    // Reward token (e.g. ARB)
    IERC20 rewardToken;

    // Token A lending vault
    ILendingVault tokenALendingVault;
    // Token B lending vault
    ILendingVault tokenBLendingVault;

    // Vault address
    IGMXVault vault;
    // Callback contract address
    address callback;

    // Chainlink Oracle contract address
    IChainlinkOracle chainlinkOracle;
    // GMX Oracle contract address
    IGMXOracle gmxOracle;

    // GMX exchange router contract address
    IExchangeRouter exchangeRouter;
    // GMX router contract address
    address router;
    // GMX deposit vault address
    address depositVault;
    // GMX withdrawal vault address
    address withdrawalVault;
    // GMX order vault address
    address orderVault;
    // GMX role store address
    address roleStore;

    // Swap router for this vault
    ISwap swapRouter;

    // DepositCache
    DepositCache depositCache;
    // WithdrawCache
    WithdrawCache withdrawCache;
    // RebalanceCache
    RebalanceCache rebalanceCache;
    // CompoundCache
    CompoundCache compoundCache;
    // OrderCache
    OrderCache orderCache;
  }

  struct DepositCache {
    // Address of user
    address payable user;
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // Minimum amount of shares expected in 1e18
    uint256 minSharesAmt;
    // Actual amount of shares minted in 1e18
    uint256 sharesToUser;
    // Amount of LP tokens that vault received in 1e18
    uint256 lpAmtReceived;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // Withdraw key from GMX in bytes32; filled by deposit failure event occurs
    bytes32 withdrawKey;
    // Amount of tokenA that vault received in 1e18; filled by deposit failure event occurs
    uint256 tokenAAmtInVault;
    // Amount of tokenB that vault received in 1e18; filled by deposit failure event occurs
    uint256 tokenBAmtInVault;
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct WithdrawCache {
    // Address of user
    address payable user;
    // Ratio of shares out of total supply of shares to burn
    uint256 shareRatio;
    // Amount of LP to remove liquidity from
    uint256 lpAmt;
    // Withdrawal value in 1e18
    uint256 withdrawValue;
    // Minimum amount of assets that user receives
    uint256 minAssetsAmt;
    // Actual amount of assets that user receives
    uint256 assetsToUser;
    // Amount of tokenA that vault received in 1e18
    uint256 tokenAReceived;
    // Amount of tokenB that vault received in 1e18
    uint256 tokenBReceived;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // Deposit key from GMX in bytes32; filled by withdrawal failure event occurs
    bytes32 depositKey;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // RepayParams
    RepayParams repayParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct CompoundCache {
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // CompoundParams
    CompoundParams compoundParams;
  }

  struct OrderCache {
    // Order key from GMX in bytes32
    bytes32 orderKey;
    // OrderParams
    OrderParams orderParams;
  }

  struct RebalanceCache {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // BorrowParams
    BorrowParams borrowParams;
    // LP amount to remove in 1e18
    uint256 lpAmtToRemove;
    // HealthParams
    HealthParams healthParams;
  }

  struct DepositParams {
    // Address of token depositing; can be tokenA, tokenB or lpToken
    address token;
    // Amount of token to deposit in token decimals
    uint256 amt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct WithdrawParams {
    // Amount of shares to burn in 1e18
    uint256 shareAmt;
    // Address of token to withdraw to; could be tokenA, tokenB
    address token;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
  }

  struct OrderParams {
    // Token to be swapped
    address token;
    // Amount of token to be swapped
    uint256 amt;
    // Execution fee sent to GMX for creating an order
    uint256 executionFee;
  }

  struct CompoundParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in
    uint256 amtIn;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct RebalanceAddParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // BorrowParams
    BorrowParams borrowParams;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct RebalanceRemoveParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // LP amount to remove in 1e18
    uint256 lpAmtToRemove;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct BorrowParams {
    // Amount of tokenA to borrow in tokenA decimals
    uint256 borrowTokenAAmt;
    // Amount of tokenB to borrow in tokenB decimals
    uint256 borrowTokenBAmt;
  }

  struct RepayParams {
    // Amount of tokenA to repay in tokenA decimals
    uint256 repayTokenAAmt;
    // Amount of tokenB to repay in tokenB decimals
    uint256 repayTokenBAmt;
  }

  struct HealthParams {
    // LP token balance in 1e18
    uint256 lpAmtBefore;
    // Token A asset amount before in 1e18
    uint256 tokenAAssetAmtBefore;
    // Token B asset amount before in 1e18
    uint256 tokenBAssetAmtBefore;
    // Token A debt amount before in 1e18
    uint256 tokenADebtAmtBefore;
    // Token B debt amount before in 1e18
    uint256 tokenBDebtAmtBefore;
    // USD value of equity in 1e18
    uint256 equityBefore;
    // Debt ratio in 1e18
    uint256 debtRatioBefore;
    // Delta in 1e18
    int256 deltaBefore;
    // USD value of equity in 1e18
    uint256 equityAfter;
    // svToken value before in 1e18
    uint256 svTokenValueBefore;
    // // svToken value after in 1e18
    uint256 svTokenValueAfter;
  }

  struct AddLiquidityParams {
    // Amount of tokenA to add liquidity
    uint256 tokenAAmt;
    // Amount of tokenB to add liquidity
    uint256 tokenBAmt;
    // Minimum market tokens to receive in 1e18
    uint256 minMarketTokenAmt;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct RemoveLiquidityParams {
    // Amount of lpToken to remove liquidity
    uint256 lpAmt;
    // Array of market token in array to swap tokenA to other token in market
    address[] tokenASwapPath;
    // Array of market token in array to swap tokenB to other token in market
    address[] tokenBSwapPath;
    // Minimum amount of tokenA to receive in token decimals
    uint256 minTokenAAmt;
    // Minimum amount of tokenB to receive in token decimals
    uint256 minTokenBAmt;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
  }

  /* ========== ENUM ========== */

  enum Status {
    // 0) Vault is open
    Open,
    // 1) User is depositing to vault
    Deposit,
    // 2) User deposit to vault failure
    Deposit_Failed,
    // 4) User deposit to vault failure process with a swap order created
    Deposit_Failed_Order_Created,
    // 5) User is withdrawing from vault
    Withdraw,
    // 6) User is withdrawing from vault with a swap order created
    Withdraw_Order_Created,
    // 7) User withdrawal from vault failure
    Withdraw_Failed,
    // 8) Vault is rebalancing delta or debt with more hedging
    Rebalance_Add,
    // 9) Vault is rebalancing delta or debt with less hedging
    Rebalance_Remove,
    // 10) Vault has rebalanced but still requires more rebalancing
    Rebalance_Open,
    // 11) Vault is compounding
    Compound,
    // 12) Vault is paused
    Paused,
    // 13) Vault is repaying
    Repay,
    // 14) Vault is repaying with a swap order created
    Repay_Order_Created,
    // 15) Vault has repaid all debt after pausing
    Repaid,
    // 16) Vault is resuming
    Resume,
    // 17) Vault is closed after repaying debt
    Closed
  }

  enum Delta {
    // Neutral delta strategy; aims to hedge tokenA exposure
    Neutral,
    // Long delta strategy; aims to correlate with tokenA exposure
    Long,
    // Short delta strategy; aims to overhedge tokenA exposure
    Short
  }

  enum RebalanceType {
    // Rebalance delta; mostly borrowing/repay tokenA
    Delta,
    // Rebalance debt ratio; mostly borrowing/repay tokenB
    Debt
  }

  enum CallbackType {
    // 0
    ProcessDeposit,
    // 1
    ProcessRebalanceAdd,
    // 2
    ProcessCompound,
    // 3
    ProcessWithdrawFailureLiquidityAdded,
    // 4 TODO
    ProcessWithdrawFailureLiquidityAddedOrderCreated,
    // 4
    ProcessEmergencyResume,
    // 5
    ProcessDepositCancellation,
    // 6
    ProcessRebalanceAddCancellation,
    // 7
    ProcessCompoundCancellation,
    // 8
    ProcessEmergencyResumeCancellation,
    // 9
    ProcessWithdraw,
    // 10
    ProcessRebalanceRemove,
    // 11
    ProcessDepositFailureLiquidityWithdrawal,
    // 12
    ProcessEmergencyRepay,
    // 13
    ProcessWithdrawCancellation,
    // 14
    ProcessRebalanceRemoveCancellation
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ===================== AUTHORIZATION ===================== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyCallbackAllowed();
  error OnlyBorrowerAllowed();
  error OnlyYieldBoosterAllowed();
  error OnlyMinterAllowed();
  error OnlyTokenManagerAllowed();

  /* ======================== GENERAL ======================== */

  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();
  error ReceiverNotApproved();
  error ExternalCallFailed();

  /* ========================= ORACLE ======================== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ======================== LENDING ======================== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();
  error InvalidInterestRateModel();
  error InterestRateModelExceeded();
  error ApprovedBorrowersExceededMaximum();
  error PerformanceFeeExceeded();
  error ApproveBorrowerFailure();
  error RevokeBorrowerFailure();

  /* ===================== VAULT GENERAL ===================== */

  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientVaultSlippageAmount();
  error NotAllowedInCurrentVaultStatus();
  error AddressNotAllowed();

  /* ===================== VAULT DEPOSIT ===================== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InsufficientDepositValue();
  error ExcessiveDepositValue();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositNotAllowedWhenEquityIsZero();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();

  /* ===================== VAULT WITHDRAW ==================== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error ExcessiveWithdrawValue();
  error InsufficientWithdrawBalance();
  error InvalidEquityAfterWithdraw();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();
  error NoAssetsToEmergencyRefund();

  /* ==================== VAULT REBALANCE ==================== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();
  error InvalidRebalanceParameters();

  /* ==================== VAULT CALLBACKS ==================== */

  error InvalidCallbackHandler();
  error DepositExecutionUnmatchedCallback();
  error DepositCancellationUnmatchedCallback();
  error WithdrawalExecutionUnmatchedCallback();
  error WithdrawalCancellationUnmatchedCallback();
  error OrderExecutionUnmatchedCallback();
  error OrderCancellationUnmatchedCallback();
  error OrderFrozenUnmatchedCallback();

  /* ========================= FARMS ========================== */

  error FarmDoesNotExist();
  error FarmNotActive();
  error EndTimeMustBeGreaterThanCurrentTime();
  error MaxMultiplierMustBeGreaterThan1x();
  error InsufficientRewardsBalance();
  error InvalidRate();
  error InvalidEsSDYSplit();

  /* ========================= TOKENS ========================= */

  error RedeemEntryDoesNotExist();
  error InvalidRedeemAmount();
  error InvalidRedeemDuration();
  error VestingPeriodNotOver();
  error InvalidAmount();
  error UnauthorisedAllocateAmount();
  error InvalidRatioValues();
  error DeallocationFeeTooHigh();
  error TransferNotAllowed();
  error InvalidUpdateTransferWhitelistAddress();

  /* ========================= BRIDGE ========================= */

  error OnlyNetworkAllowed();
  error InvalidFeeToken();
  error InsufficientFeeTokenBalance();

  /* ========================= CLAIMS ========================= */

  error AddressAlreadyClaimed();
  error MerkleVerificationFailed();
  error EpochNotFound();

  /* ========================= DISITRBUTOR ========================= */

  error InvalidNumberOfVaults();
}