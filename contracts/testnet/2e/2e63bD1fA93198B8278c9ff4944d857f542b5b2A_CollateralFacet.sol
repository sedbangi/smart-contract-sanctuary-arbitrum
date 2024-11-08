// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

error LengthMismatch();
error InvalidParam();
error TooFewSignLens();
error DuplicateSigner();
error InvalidStrategy();
error InvalidSignature();
error InvalidSignerNum();
error InvalidMarkPrice();
error RepeatedSignerAddress();
error InvalidPortfolioMarginForId(uint256 strategyId);
error InvalidPortfolioMarginForHash(bytes32 requestHash);
error PriceOutOfRange(uint256 reportPrice, uint256 anchorPrice);
error AnchorRatioMismatch(uint256 min, uint256 lower, uint256 upper, uint256 max);
error InvalidObservationsTimestamp(uint256 observationsTimestamp, uint256 latestTransmissionTimestamp);
error InvalidAddress(address thrower, address inputAddress);
error InvalidPosition();
error StrategyIsNotActive(uint256 strategyId);

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Constants} from "../../utils/Constants.sol";
import {ICollateral} from "../interfaces/ICollateral.sol";
import {StrategyTypes} from "../libraries/StrategyTypes.sol";
import {ReentrancyGuard} from "../security/ReentrancyGuard.sol";
import {LibAgent} from "../libraries/LibAgent.sol";
import {LibCollateral} from "../libraries/LibCollateral.sol";
import {LibPositionCore} from "../libraries/LibPositionCore.sol";
import {LibMarketPricer} from "../libraries/LibMarketPricer.sol";
import {LibStrategyConfig} from "../libraries/LibStrategyConfig.sol";
import {LibAccessControlEnumerable} from "../libraries/LibAccessControlEnumerable.sol";
import {LibVault} from "../libraries/LibVault.sol";

/**
 * @title DEDERI Strategy Open
 * @author dederi
 * @notice This contract is strategy Open 涵盖增加和减少抵押品.
 */
contract CollateralFacet is ICollateral, ReentrancyGuard {
    using LibCollateral for LibCollateral.Layout;

    error StrategyCollateralNoEnough();

    /**
     * @notice StrategyCollateralAdded
     * @param strategyId 策略Id
     */
    event StrategyCollateralAdded(uint256 strategyId);

    /**
     * @notice StrategyCollateralReduceRequested
     * @param requestHash 减少抵押品的请求hash
     * @param requestParams 减少抵押品的请求结构体
     */
    event StrategyCollateralReduceRequested(
        bytes32 requestHash,
        StrategyTypes.DecreaseStrategyCollateralRequest requestParams
    );

    /**
     * @notice StrategyCollateralReduceExecuted
     * @param requestHash 减少抵押品的请求hash
     * @param strategyId 减少抵押品的策略Id
     */
    event StrategyCollateralReduceExecuted(bytes32 requestHash, uint256 strategyId);

    /**
     * @notice Execute Increase Strategy Collateral by user
     * @param strategyId The current strategy ID
     * @param collateralAmount 要增加的抵押品金额
     * @custom:event emits a StrategyIncrease event
     */
    function increaseStrategyCollateral(uint256 strategyId, uint256 collateralAmount) external nonReentrant {
        // 验证owner和是否激活
        address admin = LibAgent._getAdminAndUpdate(msg.sender);
        StrategyTypes.StrategyAllData memory strategy = LibPositionCore._getStrategyAllData(strategyId);
        LibStrategyConfig._ensureAdminAndActive(strategy, admin);

        // 调用nft合约更新抵押品
        LibCollateral._increaseStrategyCollateral(strategyId, collateralAmount);

        // 发出事件
        emit StrategyCollateralAdded(strategyId);
    }

    /**
     * @notice Execute Decrease Strategy Collateral by user
     * @param strategyId The current strategy ID
     * @param collateralAmount 要减少的抵押品金额
     * @custom:event emits a StrategyIncrease event
     */
    function decreaseStrategyCollateral(uint256 strategyId, uint256 collateralAmount) external {
        LibCollateral.Layout storage l = LibCollateral.layout();

        // 验证owner和是否激活
        address admin = LibAgent._getAdminAndUpdate(msg.sender);
        StrategyTypes.StrategyAllData memory strategy = LibPositionCore._getStrategyAllData(strategyId);
        LibStrategyConfig._ensureAdminAndActive(strategy, admin);

        bytes32 requestHash = LibStrategyConfig._getRequestHashAndUpdateNonce(admin);

        // 设置请求参数
        l.userDSCRequest[requestHash].owner = admin;
        l.userDSCRequest[requestHash].strategyId = strategyId;
        l.userDSCRequest[requestHash].collateralAmount = collateralAmount;

        // 发出事件
        emit StrategyCollateralReduceRequested(requestHash, l.userDSCRequest[requestHash]);
    }

    /**
     * @notice Execute Decrease Strategy Collateral
     * @param requestHash 执行减少策略保证金的请求hash
     * @custom:access Only KEEPER_ROLE
     * @custom:event emits a StrategyDecrease event
     */
    function executeDecreaseStrategyCollateral(bytes32 requestHash) external nonReentrant {
        LibAccessControlEnumerable.checkRole(Constants.KEEPER_ROLE);
        LibCollateral.Layout storage l = LibCollateral.layout();
        StrategyTypes.DecreaseStrategyCollateralRequest memory requestParam = l.userDSCRequest[requestHash];
        StrategyTypes.StrategyAllData memory strategy = LibPositionCore._getStrategyAllData(requestParam.strategyId);
        LibStrategyConfig._ensureAdminAndActive(strategy, requestParam.owner);

        uint256 withdrawableCash = LibCollateral._checkStrategy(requestHash, strategy);
        if (withdrawableCash < requestParam.collateralAmount) {
            revert StrategyCollateralNoEnough();
        }
        // 减少抵押品
        uint256 processedCollateralAmount = LibCollateral._decreaseStrategyCollateral(
            requestParam.strategyId,
            requestParam.collateralAmount
        );

        // 更新总账户：可用和不可用余额
        LibVault._marginIncrease(requestParam.owner, requestParam.collateralAmount);

        // 循环计算抵押品总价值，并与维持保证金进行比较
        // LibMarketPricer._checkCollateralSufficiency(processedCollateralAmount, requestHash, false);

        emit StrategyCollateralReduceExecuted(requestHash, requestParam.strategyId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

/**
 * @dev Interface for chainlink price feeds used by Dederi
 */
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function getRoundData(
        uint80 _roundId
    ) external view returns (uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "../libraries/StrategyTypes.sol";

interface ICollateral {}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

interface IDiamondCut {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and optionally execute
     * a function with delegatecall
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     * _calldata is executed with delegatecall on _init
     **/
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibAccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.AccessControlEnumerable");

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        return l.roles[role].members[account];
    }

    function grantRole(bytes32 role, address account) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        if (!hasRole(role, account)) {
            l.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
            l.roleMembers[role].add(account);
        }
    }

    function revokeRole(bytes32 role, address account) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        if (hasRole(role, account)) {
            l.roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            l.roleMembers[role].remove(account);
        }
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        LibAccessControlEnumerable.Layout storage l = LibAccessControlEnumerable.layout();
        bytes32 previousAdminRole = l.roles[role].adminRole;
        l.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

library LibAgent {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.Agent");

    using BitMaps for BitMaps.BitMap;

    struct Layout {
        /// @notice /* agent */ /* admin */
        mapping(address => address) pendingAgentToAdmin;
        /// @notice Associates agents with their corresponding admins /* agent */ /* admin */
        mapping(address => address) agentToAdmin;
        /// @notice Keeps a record of whether an agent has ever acted as an admin.
        //        mapping(address => bool) adminHistory;
        BitMaps.BitMap adminHistory;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice If the address of the admin is the zero address,
    /// it signifies that this address serves as the admin address, and its status should be recorded.
    function _getAdminAndUpdate(address _account) internal returns (address) {
        LibAgent.Layout storage l = LibAgent.layout();
        address admin = l.agentToAdmin[_account];
        if (admin == address(0)) {
            _updateAdminHistory(l, _account);
            return _account;
        } else {
            return admin;
        }
    }

    /// @notice Update the address status.
    function _updateAdminHistory(LibAgent.Layout storage l, address _account) internal {
        uint256 _accountId = uint256(uint160(_account));
        if (!l.adminHistory.get(_accountId)) {
            l.adminHistory.set(_accountId);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library LibBaseConfig {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.BaseConfig");

    struct Layout {
        uint256 takerFeeRate;
        uint256 makerFeeRate;
        uint256 minTakerFee;
        uint256 minMakerFee;
        uint256 futureSettlementFeeRate;
        uint256 optionSettlementFeeRate;
        uint256 optionSettleAmountMaxFeeRate;
        uint256 imRFQFactor;
        uint256 minIM;
        uint256 imTradeFactor;
        uint256 transferIMFactor;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibStrategyConfig} from "./LibStrategyConfig.sol";
import {LibPositionCore} from "./LibPositionCore.sol";
import {LibMarketPricer} from "../libraries/LibMarketPricer.sol";
import {LibMarginOracle} from "../libraries/LibMarginOracle.sol";

library LibCollateral {
    using LibPositionCore for LibPositionCore.Layout;
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.Collateral");

    error InvalidCollateral(address collateralToken, uint256 collateralAmount);
    error CollateralDuplicates(address token);

    struct Layout {
        /**
         * @notice Official mapping of cTokens -> Market metadata
         * @dev Used e.g. to determine if a market is supported
         */
        mapping(address => StrategyTypes.Market) markets;
        /// @notice 所有市场的标的资产地址
        address[] allMarkets;
        /// @notice 减少保证金请求中需要的参数
        mapping(bytes32 => StrategyTypes.DecreaseStrategyCollateralRequest) userDSCRequest;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice 增加抵押品
     * @param tokenId 当前策略Id
     * @param collateralAmount 待增加的抵押品信息
     */
    function _increaseStrategyCollateral(uint256 tokenId, uint256 collateralAmount) internal {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[tokenId];
        originalStrategy.collateralAmount += collateralAmount;
    }

    /**
     * @notice 减少抵押品
     * @param tokenId 当前策略Id
     * @param collateralAmount 待减少的抵押品信息
     */
    function _decreaseStrategyCollateral(uint256 tokenId, uint256 collateralAmount) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        // 获取策略抵押品
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[tokenId];
        originalStrategy.collateralAmount -= collateralAmount;
        return originalStrategy.collateralAmount;
    }

    function _checkStrategy(
        bytes32 requestHash,
        StrategyTypes.StrategyAllData memory strategy
    ) internal view returns (uint256) {
        // int256 withdrawableCash =
        StrategyTypes.MarginItemWithHash memory marginByHash = LibMarginOracle._getPortfolioMarginInfoByHash(
            requestHash
        );
        int256 availableBalance = LibMarketPricer._getAvailableBalance(strategy.collateralAmount, strategy.realisedPnl);
        int256 unrealizedPnl = marginByHash.futureUnrealizedPnl + marginByHash.optionValue;
        int256 equity = LibMarketPricer._getEquity(strategy, unrealizedPnl);
        int256 withdrawableCash = (availableBalance > equity ? equity : availableBalance) -
            int256(strategy.unsettled) -
            int256(marginByHash.im);
        if (withdrawableCash > 0) {
            return uint256(withdrawableCash);
        }
        return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "../interfaces/IDiamondCut.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

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
        // Used in ReentrancyGuard
        uint256 status;
        bool paused;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            bytes4[] memory _functionSelectors = _diamondCut[facetIndex].functionSelectors;
            require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
            unchecked {
                facetIndex++;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                selectorIndex++;
            }
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            unchecked {
                selectorIndex++;
            }
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                selectorIndex++;
            }
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
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
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {InvalidPortfolioMarginForId, InvalidPortfolioMarginForHash} from "../errors/GenericErrors.sol";
import "../interfaces/IAggregatorV3.sol";
import "./StrategyTypes.sol";

library LibMarginOracle {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.MarginOracle");

    struct Signer {
        bool active;
        // Index of oracle in s_signersList
        uint8 index;
    }

    struct Layout {
        uint256 signerNum;
        mapping(bytes32 => StrategyTypes.MarginItemWithHash) portfolioMarginInfoByHash;
        mapping(uint256 => StrategyTypes.MarginItemWithId) portfolioMarginInfoById;
        mapping(address /* signer address */ => Signer) s_signers;
        // s_signersList contains the signing address of each oracle
        address[] s_signersList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice 通过request hash 获取组合保证金
    function _getPortfolioMarginInfoByHash(
        bytes32 requestHash
    ) internal view returns (StrategyTypes.MarginItemWithHash memory) {
        LibMarginOracle.Layout storage l = LibMarginOracle.layout();
        StrategyTypes.MarginItemWithHash memory strategyItem = l.portfolioMarginInfoByHash[requestHash];
        if (strategyItem.updateAt != block.timestamp) {
            revert InvalidPortfolioMarginForHash(requestHash);
        }
        return strategyItem;
    }

    /// @notice 通过策略id 获取组合保证金
    function _getPortfolioMarginInfoByStrategyId(
        uint256 strategyId
    ) internal view returns (StrategyTypes.MarginItemWithId memory) {
        LibMarginOracle.Layout storage l = LibMarginOracle.layout();
        StrategyTypes.MarginItemWithId memory strategyItem = l.portfolioMarginInfoById[strategyId];
        if (strategyItem.updateAt != block.timestamp) {
            revert InvalidPortfolioMarginForId(strategyId);
        }
        return (strategyItem);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibMarginOracle} from "./LibMarginOracle.sol";
import {LibSpotPriceOracle} from "./LibSpotPriceOracle.sol";
import {LibBaseConfig} from "./LibBaseConfig.sol";
import {LibMarkPriceOracle} from "./LibMarkPriceOracle.sol";

library LibMarketPricer {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.MarketPricer");

    uint256 public constant EXP_SCALE = 1e18;
    error InsufficientCollateral(uint256 correct, uint256 incorrect);
    struct Layout {
        uint256 abc;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /////////////
    // Getters //
    /////////////

    /// @notice 获取系统预估IM
    // function _getEstimatedIM(bytes32 requestHash) internal view returns (uint256) {
    //     (uint256 im, ) = LibMarginOracle._getPortfolioMarginInfoByHash(requestHash);
    //     // EstimatedIM=max(115\%系统预估IM,400USDC)
    //     return uintMax((115 * im) / 100, 400e18);
    // }

    // /**
    //  * @notice 检查抵押品是否足够，不正确revert
    //  * @param collateralAmount 用于查询maker的地址和相关保证金
    //  * @param requestHash 用于查询taker的地址和相关保证金
    //  * @param isIM 是否比较初始保证金
    //  */
    // function _checkCollateralSufficiency(uint256 collateralAmount, bytes32 requestHash, bool isIM) internal view {
    //     uint256 usdcValue = collateralAmount;
    //     // 这里后面要改成通用的
    //     (uint256 im, uint256 mm) = LibMarginOracle._getPortfolioMarginInfoByHash(requestHash);

    //     if (isIM) {
    //         if (usdcValue < im) {
    //             revert InsufficientCollateral(im, usdcValue);
    //         }
    //     } else {
    //         if (usdcValue < mm) {
    //             revert InsufficientCollateral(mm, usdcValue);
    //         }
    //     }
    // }

    function _checkCollateralEnough(uint256 newCashIn, uint256 collateralAmount) internal pure {
        uint256 usdcValue = collateralAmount;
        if (usdcValue < newCashIn) {
            revert InsufficientCollateral(newCashIn, usdcValue);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function uintMax(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function _getPremium(StrategyTypes.Option[] memory option) internal pure returns (int256 premium) {
        uint256 len = option.length;
        for (uint256 i = 0; i < len; ) {
            premium += option[i].premium;
            unchecked {
                ++i;
            }
        }
    }

    function _getFutureUnrealizedPnl(StrategyTypes.Future[] memory future) internal pure returns (int256 pnl) {
        uint256 len = future.length;
        for (uint256 i = 0; i < len; ) {
            if (future[i].isActive) {
                // 获取 mark price
                //uint 转 int
                //use _safeCast library
                uint256 markPrice;
                pnl += (int256(markPrice) - int256(future[i].entryPrice)) * int256(future[i].size);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _getOptionUnrealizedPnl(StrategyTypes.Option[] memory option) internal pure returns (int256 pnl) {
        uint256 len = option.length;
        for (uint256 i = 0; i < len; ) {
            if (option[i].isActive) {
                // 获取 mark price
                //uint 转 int
                //use _safeCast library
                uint256 markPrice;
                pnl += (int256(markPrice) - int256(option[i].strikePrice)) * int256(option[i].size);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _getFuturePredictUnrealizedPnl(StrategyTypes.Future[] memory future) internal view returns (int256 pnl) {
        uint256 len = future.length;
        for (uint256 i = 0; i < len; ) {
            //uint 转 int
            //use _safeCast library
            uint256 _markPrice = LibMarkPriceOracle._getMarkPrice(future[i].positionId);
            pnl += ((int256(_markPrice) - int256(future[i].entryPrice)) * int256(future[i].size)) / 1e18;
            unchecked {
                ++i;
            }
        }
    }

    function _getOptionPredictUnrealizedPnl(StrategyTypes.Option[] memory option) internal view returns (int256 pnl) {
        uint256 len = option.length;
        for (uint256 i = 0; i < len; ) {
            //uint 转 int
            //use __safeCast library
            uint256 _markPrice = LibMarkPriceOracle._getMarkPrice(option[i].positionId);
            pnl += ((int256(_markPrice) - int256(option[i].strikePrice)) * int256(option[i].size)) / 1e18;
            unchecked {
                ++i;
            }
        }
    }

    function _getEquity(
        StrategyTypes.StrategyAllData memory strategy,
        int256 unrealizePnl
    ) internal pure returns (int256 equity) {
        int256 availableBalance = _getAvailableBalance(strategy.collateralAmount, strategy.realisedPnl);
        // int256 futureUnrealizedPnl = _getFutureUnrealizedPnl(strategy.future);
        // int256 optionValue = _getOptionUnrealizedPnl(strategy.option);
        equity = availableBalance + unrealizePnl;
        equity = availableBalance;
    }

    function _getAvailableBalance(
        uint256 collateralAmount,
        int256 realisedPnl
    ) internal pure returns (int256 availableBalance) {
        uint256 depositedCash = collateralAmount;
        availableBalance = int256(depositedCash) + realisedPnl;
    }

    function _getNewCashWithCreateStrategy(
        uint256 estimatedIM,
        uint256 fee,
        int256 predictUnrealizedPnl,
        StrategyTypes.Option[] memory option
    ) internal pure returns (uint256 newCash) {
        //值的定义
        uint256 newCashIn1;
        uint256 newCashIn2;
        int256 premium = _getPremium(option);

        //todo 把之前删除的预估 im 系数补上
        newCashIn1 = (premium - int256(fee)) < 0 ? uint256(0 - premium + int256(fee)) : 0;
        newCashIn2 = (int(estimatedIM + fee) - predictUnrealizedPnl) > 0
            ? uint256(int(estimatedIM + fee) - predictUnrealizedPnl)
            : 0;
        newCash = newCashIn1 > newCashIn2 ? newCashIn1 : newCashIn2;
    }

    function _getNewCashWithCreateStrategyAndMerge(
        uint256 oldStrategyEstimatedIM,
        uint256 estimatedIM,
        uint256 fee,
        int256 predictUnrealizedPnl,
        int256 unrealizedPnl,
        StrategyTypes.StrategyRequest memory newStrategy,
        StrategyTypes.StrategyAllData memory oldStrategy
    ) internal pure returns (uint256 newCash) {
        uint256 newCashIn1 = _getNewCash1(oldStrategyEstimatedIM, fee, newStrategy, oldStrategy);
        uint256 newCashIn2 = _getNewCash2(estimatedIM, fee, predictUnrealizedPnl, unrealizedPnl, oldStrategy);
        newCash = newCashIn1 > newCashIn2 ? newCashIn1 : newCashIn2;
    }

    function _getNewCash1(
        uint256 oldStrategyEstimatedIM,
        uint256 fee,
        StrategyTypes.StrategyRequest memory newStrategy,
        StrategyTypes.StrategyAllData memory oldStrategy
    ) internal pure returns (uint256 newCash1) {
        int256 premium = _getPremium(newStrategy.option);
        int256 availableBalance = _getAvailableBalance(oldStrategy.collateralAmount, oldStrategy.realisedPnl);

        int256 cash = premium - int(fee) + availableBalance + int256(oldStrategyEstimatedIM);
        newCash1 = cash < 0 ? uint256(0 - cash) : 0;
    }

    function _getNewCash2(
        uint256 estimatedIM,
        uint256 fee,
        int256 predictUnrealizedPnl,
        int256 unrealizedPnl,
        StrategyTypes.StrategyAllData memory oldStrategy
    ) internal pure returns (uint256 newCash2) {
        // int256 premium = _getPremium(newStrategy.option);
        //获取 maker fee
        // int predictUnrealizedPnl = _getStrategyPredictUnrealizedPnl(newStrategy.option, newStrategy.future);
        int256 equity = _getEquity(oldStrategy, unrealizedPnl);

        int256 cash = int256(estimatedIM) + int256(fee) - predictUnrealizedPnl - equity;
        newCash2 = cash < 0 ? uint256(0 - cash) : 0;
    }

    function _getStrategyPredictUnrealizedPnl(
        StrategyTypes.Option[] memory option,
        StrategyTypes.Future[] memory future
    ) internal view returns (int256 predictUnrealizedPnl) {
        int256 futurePredictUnrealizdPnl = _getFuturePredictUnrealizedPnl(future);
        int256 optionPredictUnrealizdPnl = _getOptionPredictUnrealizedPnl(option);
        return futurePredictUnrealizdPnl + optionPredictUnrealizdPnl;
    }

    function _getNewCashWithSellStrategy(
        uint256 strategyEstimatedIM,
        uint256 fee,
        int256 unrealizedPnl,
        StrategyTypes.StrategyAllData memory strategy
    ) internal pure returns (int256) {
        int256 availableBalance = _getAvailableBalance(strategy.collateralAmount, strategy.realisedPnl);
        int256 equity = _getEquity(strategy, unrealizedPnl);
        return intMax(-availableBalance, (int256(strategyEstimatedIM) * 95) / 100 - equity) + int256(fee);
    }

    function intMax(int256 x, int256 y) internal pure returns (int256) {
        return (x > y) ? x : y;
    }

    function intMin(int256 x, int256 y) internal pure returns (int256) {
        return (x < y) ? x : y;
    }

    function _getMakerFee(
        StrategyTypes.Option[] memory option,
        StrategyTypes.Future[] memory future
    ) internal view returns (uint256) {
        LibBaseConfig.Layout memory baseConfigLayout = LibBaseConfig.layout();
        uint256 makerFeeRate = baseConfigLayout.makerFeeRate;
        uint256 size;
        uint256 optionLen = option.length;
        for (uint256 i; i < optionLen; ) {
            uint256 spotPrice = LibSpotPriceOracle._getUnderlyingPrice(option[i].underlying);
            size = size + ((option[i].size * spotPrice) / 1e18);
            unchecked {
                ++i;
            }
        }

        uint256 futureLen = future.length;
        for (uint256 i; i < futureLen; ) {
            size = size + ((future[i].size * future[i].entryPrice) / 1e18);
            unchecked {
                ++i;
            }
        }

        uint256 makerFee = (size * makerFeeRate) / 100000;
        return uintMax(makerFee, 20 * 1e18);
    }

    function _getTakerFee(
        StrategyTypes.Option[] memory option,
        StrategyTypes.Future[] memory future
    ) internal view returns (uint256) {
        LibBaseConfig.Layout memory baseConfigLayout = LibBaseConfig.layout();
        uint256 takerFeeRate = baseConfigLayout.takerFeeRate;
        uint256 size;
        uint256 optionLen = option.length;
        for (uint256 i; i < optionLen; ) {
            uint256 spotPrice = LibSpotPriceOracle._getUnderlyingPrice(option[i].underlying);
            size = size + ((option[i].size * spotPrice) / 1e18);
            unchecked {
                ++i;
            }
        }

        uint256 futureLen = future.length;
        for (uint256 i; i < futureLen; ) {
            size = size + ((future[i].size * future[i].entryPrice) / 1e18);
            unchecked {
                ++i;
            }
        }

        uint256 takerFee = (size * takerFeeRate) / 100000;
        return uintMax(takerFee, 20 * 1e18);
    }

    function _getNewCashWithLiquidation(
        uint256 strategyEstimatedIM,
        int256 predictUnrealizedPnl,
        StrategyTypes.LiquidateStrategyRequest memory liquidationStrategy
    ) internal pure returns (int256) {
        int256 premium = _getPremium(liquidationStrategy.option);

        int newCash2 = int256(strategyEstimatedIM) - predictUnrealizedPnl;
        int256 newCash = intMax(premium, newCash2);
        return intMax(0, newCash);
    }

    function _getNewCashWithLiquidationAndMerge(
        uint256 newStrategyEstimatedIM,
        uint256 mergeStrategyEstimatedIM,
        int256 predictUnrealizedPnl,
        int256 unrealizedPnl,
        StrategyTypes.LiquidateStrategyRequest memory liquidationStrategy,
        StrategyTypes.StrategyAllData memory mergeStrategy
    ) internal pure returns (int256) {
        int256 premium = _getPremium(liquidationStrategy.option);
        int256 equity = _getEquity(mergeStrategy, unrealizedPnl);
        int256 avaliableBalance = _getAvailableBalance(mergeStrategy.collateralAmount, mergeStrategy.realisedPnl);
        int256 newCash1 = premium - avaliableBalance + int256(mergeStrategyEstimatedIM);
        int256 newCash2 = int256(newStrategyEstimatedIM) + premium - predictUnrealizedPnl - equity;
        return intMax(newCash1, newCash2);
    }

    function _isLiquidation(
        uint256 estimatedMM,
        int256 unrealizedPnl,
        StrategyTypes.StrategyAllData memory strategy
    ) internal pure returns (bool) {
        int256 equity = _getEquity(strategy, unrealizedPnl);
        return ((int256(estimatedMM) * 100) / equity) > 100 ? true : false;
    }

    function _getNewCashWithSpliStrategy(
        uint256 estimatedAIM,
        uint256 estimatedBIM,
        int256 strategyAUnrealizedPnl,
        int256 strategyBUnrealizedPnl,
        StrategyTypes.StrategyAllData memory strategyA,
        StrategyTypes.StrategyAllData memory strategyB
    ) internal pure returns (int256 newCashA, int256 newCashB) {
        newCashA = intMax(
            0,
            intMax(int256(estimatedAIM), int256(estimatedAIM) - _getEquity(strategyA, strategyAUnrealizedPnl)) -
                _getAvailableBalance(strategyA.collateralAmount, strategyA.realisedPnl)
        );
        newCashB = intMax(int256(estimatedBIM), int256(estimatedBIM) - _getEquity(strategyB, strategyBUnrealizedPnl));
    }
    // function getWithdrawCash(
    //     int256 strategyEstimatedIM,
    //     StrategyTypes.Strategy memory strategy
    // ) internal view returns (int256) {
    //     int256 equity = _getEquity(strategy);
    //     int256 availableBalance = _getAvailableBalance(strategy.collaterals, strategy.realisedPnl);
    //     int256 minBalance = intMin(equity, availableBalance);
    //     int256 withdrawCash = minBalance - strategy.unsettled - strategyEstimatedIM;
    // }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {InvalidMarkPrice} from "../errors/GenericErrors.sol";

library LibMarkPriceOracle {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.MarkPriceOracle");

    struct Signer {
        bool active;
        // Index of oracle in s_signersList
        uint8 index;
    }

    struct Layout {
        uint256 signerNum;
        mapping(uint256 => StrategyTypes.MarkPriceItemWithId) markPriceById;
        mapping(address /* signer address */ => Signer) s_signers;
        // s_signersList contains the signing address of each oracle
        address[] s_signersList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _getMarkPrice(uint256 positionId) internal view returns (uint256) {
        LibMarkPriceOracle.Layout storage l = LibMarkPriceOracle.layout();
        StrategyTypes.MarkPriceItemWithId memory item = l.markPriceById[positionId];
        if (item.updateAt != block.timestamp) {
            revert InvalidMarkPrice();
        }
        return (item.price);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibCollateral} from "./LibCollateral.sol";
import {Constants} from "../../utils/Constants.sol";
import {LibStrategyConfig} from "./LibStrategyConfig.sol";
import {IStrategyNFT} from "../../interfaces/IStrategyNFT.sol";
import {StrategyIsNotActive} from "../errors/GenericErrors.sol";
import {LibMarketPricer} from "../libraries/LibMarketPricer.sol";
import {LibMarginOracle} from "../libraries/LibMarginOracle.sol";

library LibPositionCore {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.PositionCore");

    error OutOfLegLimit(uint256 num);
    error InvalidCollateral(address collateralToken, uint256 collateralAmount);
    // Splitting
    error SplittingUnapprovedStrategy(address thrower, address caller, uint256 strategyId);
    // Merging
    error MergingUnapprovedStrategy(address thrower, address caller, uint256 strategyId);

    struct Layout {
        uint256 currentPositionId;
        IStrategyNFT strategyNFT;
        mapping(uint256 => StrategyTypes.StrategyData) strategies;
        mapping(uint256 => StrategyTypes.PositionData) positions;
        mapping(uint256 => StrategyTypes.Option) optionPositions;
        mapping(uint256 => StrategyTypes.Future) futurePositions;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @dev Returns an Strategy struct of a given strategyId
    function _getStrategy(uint256 strategyId) internal view returns (StrategyTypes.StrategyData memory) {
        return LibPositionCore.layout().strategies[strategyId];
    }

    /// @dev Returns an Strategy struct of a given strategyId
    function _getStrategyWithOwner(
        uint256 strategyId
    ) internal view returns (StrategyTypes.StrategyDataWithOwner memory) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData memory strategy = l.strategies[strategyId];

        return
            StrategyTypes.StrategyDataWithOwner({
                strategyId: strategy.strategyId,
                collateralAmount: strategy.collateralAmount,
                timestamp: strategy.timestamp,
                unsettled: strategy.unsettled,
                positionIds: strategy.positionIds,
                realisedPnl: strategy.realisedPnl,
                isActive: strategy.isActive,
                owner: l.strategyNFT.ownerOfNotRevert(strategyId) // if owner = zero addr , not notify invalid owner
            });
    }

    function _getStrategyAllData(
        uint256 strategyId
    ) internal view returns (StrategyTypes.StrategyAllData memory strategyData) {
        StrategyTypes.StrategyDataWithOwner memory strategy = _getStrategyWithOwner(strategyId);
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        uint256 len = strategy.positionIds.length;
        uint256 opLen;
        uint256 fuLen;
        for (uint256 i; i < len; ) {
            StrategyTypes.PositionData memory positionData = l.positions[strategy.positionIds[i]];
            if (positionData.assetType == StrategyTypes.AssetType.OPTION) {
                opLen++;
            } else {
                fuLen++;
            }
            unchecked {
                ++i;
            }
        }

        strategyData.option = new StrategyTypes.Option[](opLen);
        strategyData.future = new StrategyTypes.Future[](fuLen);

        uint256 j;
        uint256 k;
        for (uint256 i; i < len; ) {
            StrategyTypes.PositionData memory positionData = l.positions[strategy.positionIds[i]];
            if (positionData.assetType == StrategyTypes.AssetType.OPTION) {
                StrategyTypes.Option storage option = l.optionPositions[strategy.positionIds[i]];
                strategyData.option[j] = option;
                unchecked {
                    ++j;
                }
            } else {
                StrategyTypes.Future storage future = l.futurePositions[strategy.positionIds[i]];
                strategyData.future[k] = future;
                unchecked {
                    ++k;
                }
            }
            unchecked {
                ++i;
            }
        }

        strategyData.strategyId = strategy.strategyId;
        strategyData.collateralAmount = strategy.collateralAmount;
        strategyData.timestamp = strategy.timestamp;
        strategyData.unsettled = strategy.unsettled;
        strategyData.realisedPnl = strategy.realisedPnl;
        strategyData.isActive = strategy.isActive;
        strategyData.owner = strategy.owner;
    }

    /// @dev 获取接下来的仓位ID
    function _getCurrentPositionId() internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        ++l.currentPositionId;
        return l.currentPositionId;
    }

    /// @dev 从某个storage数组中移除某个key
    function _removePositionId(uint256[] storage ids, uint256 id) internal {
        uint256 idLen = ids.length;
        for (uint256 i; i < idLen; ) {
            if (ids[i] == id) {
                ids[i] = ids[idLen - 1];
                // Remove last element from array
                ids.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Mint 内部函数
     * @param to 接收方
     * @param newTokenId 是否指定tokenId，当参数为0表示不指定，反之指定
     */
    function _mintInternal(address to, uint256 newTokenId) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        return l.strategyNFT.mintWithId(to, newTokenId);
    }

    /// @notice 调用StrategyNFT
    function _burn(uint256 tokenId) internal {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        l.strategyNFT.burn(tokenId);
    }

    function _controlCreateStrategy(
        StrategyTypes.StrategyRequest memory _strategy,
        uint256 unsettle,
        int256 realisedPnl
    ) internal returns (uint256 strategyId) {
        if (_strategy.mergeId > 0) {
            _handleCreateAndMerge(_strategy, unsettle, realisedPnl);
            strategyId = _strategy.mergeId;
        } else {
            strategyId = _handleCreateStrategy(_strategy, unsettle, realisedPnl);
        }
    }

    /// @notice 创建nft 仓位数据
    function _handleCreateStrategy(
        StrategyTypes.StrategyRequest memory _strategy,
        uint256 unsettle,
        int256 realisedPnl
    ) internal returns (uint256 strategyId) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        // mint nft
        uint256 tokenId = _mintInternal(_strategy.owner, 0);
        // 创建策略
        l.strategies[tokenId].strategyId = tokenId;
        l.strategies[tokenId].collateralAmount = _strategy.collateralAmount;
        l.strategies[tokenId].timestamp = _strategy.timestamp;
        l.strategies[tokenId].isActive = true;
        l.strategies[tokenId].unsettled = unsettle;
        l.strategies[tokenId].realisedPnl += realisedPnl;

        // 创建option
        uint256 optionLen = _strategy.option.length;
        for (uint256 i; i < optionLen; ) {
            uint256 newPositionId = _getCurrentPositionId();
            // note: positionIds push
            l.strategies[tokenId].positionIds.push(newPositionId);

            l.positions[newPositionId].positionId = newPositionId;
            l.positions[newPositionId].assetType = StrategyTypes.AssetType.OPTION;

            StrategyTypes.Option memory option_ = _strategy.option[i];
            l.optionPositions[newPositionId].positionId = newPositionId;
            l.optionPositions[newPositionId].underlying = option_.underlying;
            l.optionPositions[newPositionId].strikePrice = option_.strikePrice;
            l.optionPositions[newPositionId].premium = option_.premium;
            l.optionPositions[newPositionId].expiryTime = option_.expiryTime;
            l.optionPositions[newPositionId].size = option_.size;
            l.optionPositions[newPositionId].optionType = option_.optionType;

            unchecked {
                ++i;
            }
        }
        // 创建future
        uint256 futureLen = _strategy.future.length;
        for (uint256 i; i < futureLen; ) {
            uint256 newPositionId = _getCurrentPositionId();
            // note: positionIds push
            l.strategies[tokenId].positionIds.push(newPositionId);

            l.positions[newPositionId].positionId = newPositionId;
            l.positions[newPositionId].assetType = StrategyTypes.AssetType.FUTURE;

            StrategyTypes.Future memory future_ = _strategy.future[i];
            l.futurePositions[newPositionId].positionId = newPositionId;
            l.futurePositions[newPositionId].underlying = future_.underlying;
            l.futurePositions[newPositionId].entryPrice = future_.entryPrice;
            l.futurePositions[newPositionId].expiryTime = future_.expiryTime;
            l.futurePositions[newPositionId].size = future_.size;
            l.futurePositions[newPositionId].isLong = future_.isLong;

            unchecked {
                ++i;
            }
        }
        return tokenId;
    }

    function _handleSplitStrategy(
        StrategyTypes.SpiltStrategyRequest memory requestParam
    ) internal returns (uint256 tokenIdA, uint256 tokenIdB) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[requestParam.strategyId];

        // A 用之前的保证金 B 用可用余额 不够的从账户中划转

        //

        // 设置原来的状态为false，并且burn 原来的
        originalStrategy.isActive = false;
        _burn(requestParam.strategyId);

        // mint 新的 A 和 B 并返回
        // address owner = l.strategyNFT.ownerOf(originalStrategy.strategyId);
        tokenIdA = _mintInternal(requestParam.owner, 0);
        tokenIdB = _mintInternal(requestParam.owner, 0);

        StrategyTypes.StrategyData storage strategyA;
        strategyA = l.strategies[tokenIdA];
        strategyA.strategyId = tokenIdA;
        strategyA.timestamp = block.timestamp;
        // strategyA.realisedPnl;
        strategyA.isActive = true;

        uint256 originalLen = originalStrategy.positionIds.length;
        uint256 newlySpiltLen = requestParam.positionIds.length;
        newlySpiltLen;
        // 构造A的仓位id列表
        for (uint256 i; i < originalLen; ) {
            uint256 originalPositionId = originalStrategy.positionIds[i];
            for (uint256 j; j < originalLen; ) {
                uint256 newlyPositionId = requestParam.positionIds[i];
                if (originalPositionId != newlyPositionId) {
                    strategyA.positionIds.push(originalPositionId);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        strategyA.collateralAmount = originalStrategy.collateralAmount + requestParam.originalCollateralsToTopUpAmount;

        StrategyTypes.StrategyData storage strategyB;
        strategyB = l.strategies[tokenIdB];
        strategyB.strategyId = tokenIdB;
        strategyB.timestamp = block.timestamp;
        // strategyB.realisedPnl;
        strategyB.isActive = true;
        strategyB.positionIds = requestParam.positionIds;
        strategyB.collateralAmount = originalStrategy.collateralAmount + requestParam.newlySplitCollateralAmount;
    }

    /// @dev 查看2个期权是否为相反方向，相反则为true，反之为false
    function _isOppositeDirection(
        StrategyTypes.Option memory firstOption,
        StrategyTypes.Option memory nextOption
    ) internal pure returns (bool) {
        if (
            (firstOption.optionType == StrategyTypes.OptionType.LONG_CALL &&
                nextOption.optionType == StrategyTypes.OptionType.SHORT_CALL) ||
            (firstOption.optionType == StrategyTypes.OptionType.SHORT_CALL &&
                nextOption.optionType == StrategyTypes.OptionType.LONG_CALL) ||
            (firstOption.optionType == StrategyTypes.OptionType.LONG_PUT &&
                nextOption.optionType == StrategyTypes.OptionType.SHORT_PUT) ||
            (firstOption.optionType == StrategyTypes.OptionType.SHORT_PUT &&
                nextOption.optionType == StrategyTypes.OptionType.LONG_PUT)
        ) {
            return true;
        }
        return false;
    }

    /// @notice 合并相同方向的期权
    function _mergeOptionsOfSameDirection(
        StrategyTypes.Option memory firstOption,
        StrategyTypes.Option memory nextOption
    ) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        uint256 positionId = _getCurrentPositionId();
        StrategyTypes.PositionData storage newPosition = l.positions[positionId];
        newPosition.positionId = positionId;
        newPosition.isActive = true;
        newPosition.assetType = StrategyTypes.AssetType.OPTION;

        // 构建optionData
        StrategyTypes.Option storage newOption = l.optionPositions[positionId];
        newOption.positionId = positionId;
        newOption.underlying = firstOption.underlying;
        newOption.expiryTime = firstOption.expiryTime;
        newOption.premium = firstOption.premium + nextOption.premium;
        newOption.strikePrice = firstOption.strikePrice;
        newOption.size = firstOption.size + nextOption.size;
        newOption.optionType = firstOption.optionType;
        return positionId;
    }

    /// @dev 合并相反方向的期权
    function _mergeOptionsOfOppositeDirection(
        StrategyTypes.Option memory firstOption,
        StrategyTypes.Option memory nextOption
    ) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        uint256 positionId = _getCurrentPositionId();
        StrategyTypes.PositionData storage newPosition = l.positions[positionId];
        newPosition.positionId = positionId;
        newPosition.isActive = true;
        newPosition.assetType = StrategyTypes.AssetType.OPTION;

        // 构建optionData
        StrategyTypes.Option storage newOption = l.optionPositions[positionId];
        newOption.positionId = positionId;
        newOption.underlying = firstOption.underlying;
        newOption.expiryTime = firstOption.expiryTime;
        newOption.premium = firstOption.premium + nextOption.premium;
        newOption.strikePrice = firstOption.strikePrice;
        // 保留size差值
        newOption.size = firstOption.size > nextOption.size
            ? firstOption.size - nextOption.size
            : nextOption.size - firstOption.size;
        // 采取size大的作为新方向
        newOption.optionType = firstOption.size > nextOption.size ? firstOption.optionType : nextOption.optionType;
        return positionId;
    }

    /// @dev 合并相同方向的期货
    function _mergeFuturesOfSameDirection(
        StrategyTypes.Future memory firstFuture,
        StrategyTypes.Future memory nextFuture
    ) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        uint256 positionId = _getCurrentPositionId();
        StrategyTypes.Future storage future;
        future = l.futurePositions[positionId];

        StrategyTypes.PositionData storage position;
        position = l.positions[positionId];
        position.positionId = positionId;
        position.assetType = StrategyTypes.AssetType.FUTURE;

        future.positionId = positionId;
        future.underlying = firstFuture.underlying;
        future.expiryTime = firstFuture.expiryTime;
        future.isLong = firstFuture.isLong;
        future.size = firstFuture.size + nextFuture.size;
        uint256 entryPrice = (firstFuture.entryPrice * firstFuture.size + nextFuture.entryPrice * nextFuture.size) /
            (firstFuture.size + nextFuture.size);

        future.entryPrice = entryPrice;
        future.isActive = true;

        return positionId;
    }

    /// @dev 合并相反方向的期货
    /// todo 完全平仓时可能会产生 pnl，这部分需要计算
    function _mergeFuturesOfOppositeDirection(
        StrategyTypes.Future memory firstFuture,
        StrategyTypes.Future memory nextFuture
    ) internal returns (uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        uint256 positionId = _getCurrentPositionId();
        StrategyTypes.Future storage future;
        future = l.futurePositions[positionId];

        StrategyTypes.PositionData storage position;
        position = l.positions[positionId];
        position.positionId = positionId;
        position.assetType = StrategyTypes.AssetType.FUTURE;

        future.positionId = positionId;
        future.underlying = firstFuture.underlying;
        future.expiryTime = firstFuture.expiryTime;
        future.isLong = firstFuture.isLong;
        if (firstFuture.size > nextFuture.size) {
            future.isLong = firstFuture.isLong;
            future.size = firstFuture.size - nextFuture.size;
            uint256 price = (((firstFuture.entryPrice - nextFuture.entryPrice) * firstFuture.size) /
                (firstFuture.size + nextFuture.size)) + nextFuture.entryPrice;
            future.entryPrice = price;
        } else {
            future.isLong = nextFuture.isLong;
            future.size = nextFuture.size - firstFuture.size;
            uint256 price = (((nextFuture.entryPrice - firstFuture.entryPrice) * nextFuture.size) /
                (firstFuture.size + nextFuture.size)) + firstFuture.entryPrice;
            future.entryPrice = price;
        }
        future.isActive = true;

        return positionId;
    }

    /**
     * @notice 加腿+合并
     * @dev 只有StrategyManager可以调用
     * @param requestParam 请求参数
     * @return bool 如果可以完全抵消，返回真；反之返回假。
     */
    function _handleCreateAndMerge(
        StrategyTypes.StrategyRequest memory requestParam,
        uint256 unsettle,
        int256 realisedPnl
    ) internal returns (bool) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[requestParam.mergeId];
        originalStrategy.unsettled = unsettle;
        originalStrategy.realisedPnl += realisedPnl;
        // 比较option
        uint256 newOptionsLen = requestParam.option.length;
        uint256 newFuturesLen = requestParam.future.length;
        for (uint256 i; i < newOptionsLen; ) {
            for (uint256 j; j < originalStrategy.positionIds.length; ) {
                StrategyTypes.Option memory firstOption = requestParam.option[i];
                StrategyTypes.Option memory nextOption = l.optionPositions[originalStrategy.positionIds[j]];
                // 验证期权到期日和行权价
                if (
                    firstOption.underlying == nextOption.underlying &&
                    firstOption.expiryTime == nextOption.expiryTime &&
                    firstOption.strikePrice == nextOption.strikePrice
                ) {
                    if (firstOption.optionType == nextOption.optionType) {
                        // 如果是相同期权类型 相加
                        // 构建positionData
                        uint256 positionId = _mergeOptionsOfSameDirection(firstOption, nextOption);

                        originalStrategy.positionIds.push(positionId);
                        // 移除旧的，添加新的
                        _removePositionId(originalStrategy.positionIds, nextOption.positionId);
                        originalStrategy.positionIds.push(positionId);
                        break;
                    } else {
                        if (_isOppositeDirection(firstOption, nextOption)) {
                            // 如果是相反方向，size相同则可以抵消
                            if (firstOption.size == nextOption.size) {
                                _removePositionId(originalStrategy.positionIds, nextOption.positionId);
                            } else {
                                // 当期权在不同方向也无法抵消，判断期权类型该是那个方向
                                // 构建positionData
                                uint256 positionId = _mergeOptionsOfOppositeDirection(firstOption, nextOption);

                                // 移除旧的，添加新的
                                _removePositionId(originalStrategy.positionIds, nextOption.positionId);
                                originalStrategy.positionIds.push(positionId);
                            }
                        }
                    }
                } else {
                    //无法合并时就是加腿
                    _handleIncreaseOptionPositions(requestParam.mergeId, firstOption);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        // 比较future
        for (uint256 i; i < newFuturesLen; ) {
            for (uint256 j; j < originalStrategy.positionIds.length; ) {
                StrategyTypes.Future memory firstFuture = requestParam.future[i];
                StrategyTypes.Future memory nextFuture = l.futurePositions[originalStrategy.positionIds[j]];
                // 验证期权到期日和行权价
                if (firstFuture.expiryTime == nextFuture.expiryTime) {
                    if (firstFuture.isLong == nextFuture.isLong) {
                        // 如果是相同期货方向 相加
                        uint256 positionId = _mergeFuturesOfSameDirection(firstFuture, nextFuture);

                        // 移除旧的，添加新的
                        _removePositionId(originalStrategy.positionIds, nextFuture.positionId);
                        originalStrategy.positionIds.push(positionId);
                        break;
                    } else {
                        uint256 positionId = _mergeFuturesOfOppositeDirection(firstFuture, nextFuture);

                        // 移除旧的，添加新的
                        _removePositionId(originalStrategy.positionIds, nextFuture.positionId);
                        originalStrategy.positionIds.push(positionId);
                    }
                } else {
                    //todo 不可以合并的应该加腿
                    _handleIncreaseFuturePositions(requestParam.mergeId, firstFuture);
                }

                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        // 添加抵押品
        originalStrategy.collateralAmount += requestParam.collateralAmount;
        // 校验腿数量
        uint256 mergeLen = originalStrategy.positionIds.length;
        if (mergeLen == 0) {
            return true;
        } else {
            if (mergeLen > Constants.LEG_LIMIT) {
                revert OutOfLegLimit(mergeLen);
            }
        }
        return false;
    }

    /**
     * @notice 合并策略
     * @dev Only ACTIVE strategies can be owned by users, so status does not need to be checked.
     * @param requestParam 请求参数
     * @return bool 如果可以完全抵消，返回真；反之返回假。
     * @return uint256 如果为0，说明策略完全抵消。
     */
    function _handleMergeStrategies(
        StrategyTypes.MergeStrategyRequest memory requestParam
    ) internal returns (bool, uint256) {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        // 注意：合并前提是用户创建策略时候内部的腿策略没有要合并的，这样合并逻辑可以减少逻辑节省gas
        // 第一个
        StrategyTypes.StrategyData storage firstStrategy = l.strategies[requestParam.firstStrategyId];
        // 第二个
        StrategyTypes.StrategyData storage nextStrategy = l.strategies[requestParam.secondStrategyId];

        // 遍历策略下的仓位
        uint256 firstStrategyPositionsLen = firstStrategy.positionIds.length;
        uint256 nextStrategyPositionsLen = nextStrategy.positionIds.length;
        // 完全抵消是否就不需要mint
        uint256 currentTokenId = l.strategyNFT.currentTokenId();
        uint256 mergeStrategyId = currentTokenId++;
        // 构造新的合并策略storage
        StrategyTypes.StrategyData storage mergeStrategy = l.strategies[mergeStrategyId];

        // 先把合并的总仓位id放在数组中 这个逻辑和下面标注A合并了-》标注C

        for (uint256 j; j < nextStrategyPositionsLen; ) {
            StrategyTypes.PositionData memory nextStrategyPosition = l.positions[nextStrategy.positionIds[j]];
            if (!nextStrategyPosition.isActive) {
                break;
            } else {
                mergeStrategy.positionIds.push(nextStrategy.positionIds[j]);
            }
        }

        for (uint256 i; i < firstStrategyPositionsLen; ) {
            StrategyTypes.PositionData storage firstStrategyPosition = l.positions[firstStrategy.positionIds[i]];
            // 标注A
            if (!firstStrategyPosition.isActive) {
                break;
            } else {
                // 标注C
                mergeStrategy.positionIds.push(firstStrategy.positionIds[i]);
            }
            for (uint256 j; j < nextStrategyPositionsLen; ) {
                // 如果是已标记为可以合并的再次循环就跳过
                StrategyTypes.PositionData storage nextStrategyPosition = l.positions[nextStrategy.positionIds[j]];
                if (!nextStrategyPosition.isActive) {
                    break;
                }
                if (firstStrategyPosition.assetType == nextStrategyPosition.assetType) {
                    // 处理期权
                    if (firstStrategyPosition.assetType == StrategyTypes.AssetType.OPTION) {
                        StrategyTypes.Option memory firstOption = l.optionPositions[firstStrategy.positionIds[i]];
                        StrategyTypes.Option memory nextOption = l.optionPositions[nextStrategy.positionIds[j]];
                        // 验证期权到期日和行权价
                        if (
                            firstOption.expiryTime == nextOption.expiryTime &&
                            firstOption.strikePrice == nextOption.strikePrice
                        ) {
                            // 验证期权类型
                            if (firstOption.optionType == nextOption.optionType) {
                                // 如果是相同期权类型 相加
                                // 构建positionData
                                uint256 positionId = _mergeOptionsOfSameDirection(firstOption, nextOption);

                                mergeStrategy.positionIds.push(positionId);
                                // 移除旧的，添加新的
                                _removePositionId(mergeStrategy.positionIds, firstOption.positionId);
                                _removePositionId(mergeStrategy.positionIds, nextOption.positionId);
                                mergeStrategy.positionIds.push(positionId);
                                break;
                            } else {
                                if (_isOppositeDirection(firstOption, nextOption)) {
                                    // 如果是相反方向，size相同则可以抵消
                                    if (firstOption.size == nextOption.size) {
                                        // 相互抵消，移除腿id
                                        _removePositionId(mergeStrategy.positionIds, firstOption.positionId);
                                        _removePositionId(mergeStrategy.positionIds, nextOption.positionId);
                                    } else {
                                        // 当期权在不同方向也无法抵消，判断期权类型该是那个方向
                                        // 构建positionData
                                        uint256 positionId = _mergeOptionsOfOppositeDirection(firstOption, nextOption);

                                        // 移除旧的，添加新的
                                        _removePositionId(mergeStrategy.positionIds, firstOption.positionId);
                                        _removePositionId(mergeStrategy.positionIds, nextOption.positionId);
                                        mergeStrategy.positionIds.push(positionId);
                                    }
                                    // 在此括号下的策略可以合并，不过他是相反方向，因此可以使用break
                                    break;
                                }
                            }
                        }
                    } else {
                        // 处理期货
                        // 验证是否为多头还是空头以及到期日
                        StrategyTypes.Future storage firstFuture = l.futurePositions[firstStrategy.positionIds[i]];
                        StrategyTypes.Future storage nextFuture = l.futurePositions[nextStrategy.positionIds[j]];
                        if (firstFuture.expiryTime == nextFuture.expiryTime) {
                            // 验证期货 假如是相同方向
                            if (firstFuture.isLong == firstFuture.isLong) {
                                // 如果仓位方向相同
                                uint256 positionId = _mergeFuturesOfSameDirection(firstFuture, nextFuture);
                                _removePositionId(mergeStrategy.positionIds, firstFuture.positionId);
                                _removePositionId(mergeStrategy.positionIds, nextFuture.positionId);
                                mergeStrategy.positionIds.push(positionId);
                                break;
                            } else {
                                //todo 如果仓位方向相反且能完全合并轧仓，这时候需要计算出他们的 pnl，若为正放在 unsettled 里面，为负放在 unrealizedPnl里面
                                // 如果仓位方向相反
                                uint256 positionId = _mergeFuturesOfOppositeDirection(firstFuture, nextFuture);
                                _removePositionId(mergeStrategy.positionIds, firstFuture.positionId);
                                _removePositionId(mergeStrategy.positionIds, nextFuture.positionId);
                                mergeStrategy.positionIds.push(positionId);
                            }
                        }
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        // 处理完之后将这2个策略设置为未激活，然后burn掉2个nft
        firstStrategy.isActive = false;
        nextStrategy.isActive = false;
        _burn(firstStrategy.strategyId);
        _burn(nextStrategy.strategyId);

        // 如果合并后的策略是可以完全抵消：我就删除此结构体storage
        // currentTokenId--(不做)
        // 删除strategies
        uint256 mergeLen = mergeStrategy.positionIds.length;
        if (mergeLen == 0) {
            delete l.strategies[mergeStrategyId];
            return (true, 0);
        } else {
            // 验证腿数量
            if (mergeLen > Constants.LEG_LIMIT) {
                revert OutOfLegLimit(mergeLen);
            } else {
                // 更新合并策略storage剩余部分
                mergeStrategy.strategyId = mergeStrategyId;
                mergeStrategy.isActive = true;
                //mergeStrategy.realisedPnl；
                //mergeStrategy.timestamp;
                mergeStrategy.collateralAmount += firstStrategy.collateralAmount;
                mergeStrategy.collateralAmount += nextStrategy.collateralAmount;
                mergeStrategy.collateralAmount += requestParam.collateralAmount;

                // 如果不完全抵消
                // 我需要把nft mint 出来，需要传token id; 我要把2个策略的抵押品部分和新加进来的抵押品部分合并
                _mintInternal(requestParam.owner, mergeStrategyId);
            }
        }
        return (false, mergeStrategyId);
    }

    function _handleIncreaseOptionPositions(uint256 strategyId, StrategyTypes.Option memory option) internal {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[strategyId];
        if (!originalStrategy.isActive) {
            revert StrategyIsNotActive(originalStrategy.strategyId);
        }
        uint256 newPositionId = _getCurrentPositionId();
        // note: positionIds push
        originalStrategy.positionIds.push(newPositionId);

        StrategyTypes.PositionData storage position;
        position = l.positions[newPositionId];
        position.positionId = newPositionId;
        position.assetType = StrategyTypes.AssetType.OPTION;

        StrategyTypes.Option storage option1;
        option1 = l.optionPositions[newPositionId];
        option1.positionId = newPositionId;
        option1.underlying = option.underlying;
        option1.strikePrice = option.strikePrice;
        option1.premium = option.premium;
        option1.expiryTime = option.expiryTime;
        option1.size = option.size;
        option1.optionType = option.optionType;
        option1.isActive = true;
    }

    function _handleIncreaseFuturePositions(uint256 strategyId, StrategyTypes.Future memory future) internal {
        LibPositionCore.Layout storage l = LibPositionCore.layout();
        StrategyTypes.StrategyData storage originalStrategy = l.strategies[strategyId];
        if (!originalStrategy.isActive) {
            revert StrategyIsNotActive(originalStrategy.strategyId);
        }
        uint256 newPositionId = _getCurrentPositionId();
        // note: positionIds push
        originalStrategy.positionIds.push(newPositionId);

        StrategyTypes.PositionData storage position;
        position = l.positions[newPositionId];
        position.positionId = newPositionId;
        position.assetType = StrategyTypes.AssetType.FUTURE;

        StrategyTypes.Future storage future1;
        future1 = l.futurePositions[newPositionId];
        future1.positionId = newPositionId;
        future1.underlying = future.underlying;
        future1.entryPrice = future.entryPrice;
        future1.expiryTime = future.expiryTime;
        future1.size = future.size;
        future1.isLong = future.isLong;
        future1.isActive = true;
    }

    function _getPremium(StrategyTypes.Option[] memory option) internal pure returns (int256 amount) {
        uint256 optionLen = option.length;
        for (uint256 i; i < optionLen; ) {
            //收到权利金为正，支付权利金为负
            amount += option[i].premium;
            unchecked {
                ++i;
            }
        }
        return amount;
    }

    function _checkStrategy(
        StrategyTypes.StrategyRequest memory strategy,
        bytes32 requestHash,
        bool isTaker
    ) internal view returns (uint256 fee) {
        if (isTaker) {
            fee = LibMarketPricer._getTakerFee(strategy.option, strategy.future);
        } else {
            fee = LibMarketPricer._getMakerFee(strategy.option, strategy.future);
        }

        StrategyTypes.MarginItemWithHash memory marginByHash = LibMarginOracle._getPortfolioMarginInfoByHash(
            requestHash
        );
        int256 predictUnrealizedPnl = marginByHash.futurePredictUnrealizedPnl + marginByHash.optionValueToBeTraded;
        uint256 newCashIn;
        if (strategy.mergeId != 0) {
            // 检查策略owner和是否激活
            StrategyTypes.StrategyAllData memory mergeStrategy = LibPositionCore._getStrategyAllData(strategy.mergeId);
            LibStrategyConfig._ensureAdminAndActive(mergeStrategy, mergeStrategy.owner);
            StrategyTypes.MarginItemWithId memory marginById = LibMarginOracle._getPortfolioMarginInfoByStrategyId(
                strategy.mergeId
            );
            int256 unrealizedPnl = marginById.futureUnrealizedPnl + marginById.optionValue;
            newCashIn = LibMarketPricer._getNewCashWithCreateStrategyAndMerge(
                marginById.im,
                marginByHash.im,
                fee,
                predictUnrealizedPnl,
                unrealizedPnl,
                strategy,
                mergeStrategy
            );
        } else {
            newCashIn = LibMarketPricer._getNewCashWithCreateStrategy(
                marginByHash.im,
                fee,
                predictUnrealizedPnl,
                strategy.option
            );
        }
        LibMarketPricer._checkCollateralEnough(newCashIn, strategy.collateralAmount);
    }

    function _getPositionIdsFromStrategy(
        StrategyTypes.Option[] memory option,
        StrategyTypes.Future[] memory future
    ) internal pure returns (uint256[] memory positionIds) {
        uint256 optionLen = option.length;
        uint256 futureLen = future.length;
        positionIds = new uint256[](optionLen + futureLen);
        uint256 j;
        
        for (uint256 i; i < optionLen; ) {
            positionIds[j] = option[i].positionId;
            unchecked {
                ++j;
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < futureLen; ) {
            positionIds[j] = future[i].positionId;
            unchecked {
                ++j;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _getFuturePrice(
        StrategyTypes.Future[] memory future
    ) internal pure returns (uint256[] memory futurePrice) {
        uint256 fuLen = future.length;
        for (uint256 i = 0; i < fuLen; ) {
            futurePrice[i] = future[i].entryPrice;
            unchecked {
                ++i;
            }
        }
    }

    function _getMakerFuturePnl(
        StrategyTypes.Future[] memory makerFuture,
        StrategyTypes.Future[] memory takerFuture
    ) internal pure returns (int256 futurePnl) {
        uint256[] memory makerFuturePrice = _getFuturePrice(makerFuture);
        uint256[] memory takerFuturePrice = _getFuturePrice(takerFuture);
        uint256 len = makerFuture.length;
        for (uint i; i < len; ) {
            futurePnl += (int256(makerFuturePrice[i]) - int256(takerFuturePrice[i])) * int256(makerFuture[i].size);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {LibStrategyConfig} from "./LibStrategyConfig.sol";

library LibSpotPriceOracle {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.SpotPriceOracle");

    struct TokenFeedConfig {
        /// @notice Underlying token address, which can't be a null address
        /// @notice Used to check if a token is supported
        /// @notice 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for Native
        address asset;
        /// @notice Chainlink feed address
        address feed;
        /// @notice Price expiration period of this asset
        uint256 maxStalePeriod;
    }

    struct PriceDataItem {
        uint256 price; // USDC-rate, multiplied by 1e18.
        uint256 observationsTimestamp; // when were observations made offchain
        uint256 transmissionTimestamp; // when was report received onchain
    }

    struct Layout {
        /// @notice The highest ratio of the new price to the anchor price that will still trigger the price to be updated
        uint256 upperBoundAnchorRatio;
        /// @notice The lowest ratio of the new price to the anchor price that will still trigger the price to be updated
        uint256 lowerBoundAnchorRatio;
        /// @notice Token config by assets
        mapping(address => TokenFeedConfig) tokenFeedConfigs;
        /// @notice Manually set an override price, useful under extenuating conditions such as price feed failure
        mapping(address => PriceDataItem) priceData;
        bool isEnable;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    error SpotOracle__PriceExpired();

    /////////////
    // Getters //
    /////////////

    /**
     * @notice Get the underlying price of a listed underlying token asset 获取实时的价格，如果不是当前区块直接revert
     * @param asset Address of the asset
     * @return price Price in USDC, with 18 decimals of precision
     */
    function _getUnderlyingPrice(address asset) internal view returns (uint256) {
        LibSpotPriceOracle.Layout storage l = LibSpotPriceOracle.layout();
        LibStrategyConfig.Layout storage cl = LibStrategyConfig.layout();
        if (asset == cl.usdcToken) {
            return 1e18;
        }
        PriceDataItem memory priceData = l.priceData[asset];

        if (priceData.transmissionTimestamp != block.timestamp) {
            revert SpotOracle__PriceExpired();
        }
        return priceData.price;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {Constants} from "../../utils/Constants.sol";
import {TimestampCheck} from "../../utils/TimestampCheck.sol";
import {InvalidStrategy, StrategyIsNotActive} from "../errors/GenericErrors.sol";

library LibStrategyConfig {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.StrategyConfig");

    error OnlyStrategyOwner(address owner, address admin);
    error PositionIdDuplicates(uint256 id);
    error OnlySupportCollateralToken(address token);
    // signature
    error InvalidSignature();
    error SignatureAlreadyUsed(address user);
    // market
    error MarketNotListed();

    struct Layout {
        /// @notice 支持的抵押品
        // mapping(address => bool) isSupportCollateralToken;
        /**
         * @notice Official mapping of cTokens -> Market metadata
         * @dev Used e.g. to determine if a market is supported
         */
        mapping(address => StrategyTypes.Market) markets;
        /// @notice 所有市场的标的资产地址
        address[] allMarkets;
        /// @notice usdc token 地址
        address usdcToken;
        /// @notice weth 地址
        address wrappedNativeToken;
        /// @notice 用户对应的admin nonce，用于生成某个admin唯一的requestHash
        mapping(address => uint256) userNonce;
        mapping(address => mapping(bytes32 => bool)) usedSignatureHash;
        /// @notice 开仓，开仓加腿合并，平仓等请求中需要的参数
        mapping(bytes32 => StrategyTypes.StrategyRequest) userRequestStrategy;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Reverts if the signature is used
    function _checkSignatureExists(address user, bytes memory signature) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        bytes32 userSigHash = keccak256(signature);
        if (l.usedSignatureHash[user][userSigHash]) {
            revert SignatureAlreadyUsed(user);
        }
        // // Mark the signature as used
        l.usedSignatureHash[user][userSigHash] = true;
    }

    /// @notice Reverts if the caller is not support collateral
    // function _ensureSupportCollateral(address _token) internal view {
    //     if (!LibStrategyConfig.layout().isSupportCollateralToken[_token]) {
    //         revert OnlySupportCollateralToken(_token);
    //     }
    // }

    /// @notice Reverts if the market is not listed
    function _ensureListed(address token) internal view {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();

        if (!l.markets[token].isListed) {
            revert MarketNotListed();
        }
    }

    /// @notice Reverts if the caller is not admin or strategy is not active
    function _ensureAdminAndActive(StrategyTypes.StrategyAllData memory strategy, address _admin) internal pure {
        if (_admin != strategy.owner) {
            revert OnlyStrategyOwner(strategy.owner,_admin);
        }
        if (!strategy.isActive) {
            revert StrategyIsNotActive(strategy.strategyId);
        }
    }

    /**
     * @notice 先获取requestHash，然后更新nonce
     * @param user 用户地址
     * @return requestHash 返回requestHash
     */
    function _getRequestHashAndUpdateNonce(address user) internal returns (bytes32 requestHash) {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        requestHash = keccak256(abi.encode(user, l.userNonce[user]));
        l.userNonce[user] += 1;
    }

    /// @notice 检查是否可以有可以合并的
    function _validateMergeabilityOfStrategy(StrategyTypes.StrategyRequest memory strategy) internal pure {
        uint256 optionLen = strategy.option.length;
        uint256 futureLen = strategy.option.length;
        address underlying;
        if (optionLen > 0) {
            underlying = strategy.option[0].underlying;
        } else if (futureLen > 0) {
            underlying = strategy.future[0].underlying;
        }
        for (uint256 i; i < optionLen; ) {
            for (uint256 j = i + 1; j < optionLen; ) {
                bool isCanBeMerged = _checkOptionPositionMergeability(
                    strategy.option[i],
                    strategy.option[j],
                    underlying
                );
                // 这里是true表示可以合并的话报错
                if (isCanBeMerged) {
                    revert InvalidStrategy();
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        for (uint256 i = 0; i < futureLen; ) {
            for (uint256 j = i + 1; j < futureLen; ) {
                bool isCanBeMerged = _checkFuturePositionMergeability(
                    strategy.future[i],
                    strategy.future[j],
                    underlying
                );
                // 这里是true表示可以合并的话报错
                if (isCanBeMerged) {
                    revert InvalidStrategy();
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice 验证2个角色的策略是否完成相反
    function _validateOppositeStrategies(
        StrategyTypes.StrategyRequest memory makerStrategy,
        StrategyTypes.StrategyRequest memory takerStrategy
    ) internal view returns (bool) {
        uint256 makerOptionLen = makerStrategy.option.length;
        uint256 makerFutureLen = makerStrategy.future.length;
        uint256 takerOptionLen = takerStrategy.option.length;
        uint256 takerFutureLen = takerStrategy.future.length;
        uint256 makerLen = makerOptionLen + makerFutureLen;
        uint256 takerLen = takerOptionLen + takerFutureLen;

        // 验证策略腿数量和期权腿数量（期货腿数量包含在内，无需验证）
        if (makerLen != takerLen || makerOptionLen != takerOptionLen || takerLen > Constants.LEG_LIMIT) {
            return false;
        }

        for (uint256 i; i < makerOptionLen; ) {
            // 验证这个标的资产是否支持
            _ensureListed(makerStrategy.option[i].underlying);
            // 验证期权仓位是否相反 true 表示相反，false表示相同
            bool isOpposite = _isOppositeOptionPosition(makerStrategy.option[i], takerStrategy.option[i]);
            if (!isOpposite) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < makerFutureLen; ) {
            // 验证这个标的资产是否支持
            _ensureListed(makerStrategy.future[i].underlying);
            // 验证期权仓位是否相反
            bool isOpposite = _isOppositeFuturePosition(makerStrategy.future[i], takerStrategy.future[i]);
            if (!isOpposite) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }

    function _checkFuturePositionMergeability(
        StrategyTypes.Future memory future1,
        StrategyTypes.Future memory future2,
        address underlying
    ) internal pure returns (bool) {
        if (future1.underlying != underlying) {
            return true;
        }
        bytes32 future1Hash = keccak256(abi.encode(future1.underlying, future1.expiryTime));
        bytes32 future2Hash = keccak256(abi.encode(future2.underlying, future2.expiryTime));
        if (future1Hash == future2Hash) {
            return true;
        }

        // if (!TimestampCheck.isFridayEightAM(future1.expiryTime)) {
        //     return false;
        // }
        return false;
    }

    /// @notice 检查期权仓位数组是否存在可以合并的仓位
    function _checkOptionPositionMergeability(
        StrategyTypes.Option memory option1,
        StrategyTypes.Option memory option2,
        address underlying
    ) internal pure returns (bool) {
        //这里不合并是因为当前版本只支持单策略单币种
        if (option1.underlying != underlying) {
            return false;
        }
        //  premium 需要是相反方向，因此加个“-”符号
        bytes32 option1Hash = keccak256(abi.encode(option1.underlying, option1.strikePrice, option1.expiryTime));
        bytes32 option2Hash = keccak256(abi.encode(option2.underlying, option2.strikePrice, option2.expiryTime));
        //todo 这里还少了一个比较，longcall 和 longcall，shortcall 和 shortcall
        if (option1.optionType == StrategyTypes.OptionType.LONG_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_CALL) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_CALL) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_PUT) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_PUT) {
                if (option1Hash == option2Hash) {
                    return true;
                }
            }
        }
        // if (!TimestampCheck.isFridayEightAM(option1.expiryTime)) {
        //     return false;
        // }
        return false;
    }

    // @notice 检查2个角色对应的期权仓位是否完全相反
    function _isOppositeOptionPosition(
        StrategyTypes.Option memory option1,
        StrategyTypes.Option memory option2
    ) internal pure returns (bool) {
        //  premium 需要是相反方向，因此加个“-”符号
        bytes32 option1Hash = keccak256(
            abi.encode(option1.underlying, option1.strikePrice, -option1.premium, option1.size, option1.expiryTime)
        );
        bytes32 option2Hash = keccak256(
            abi.encode(option2.underlying, option2.strikePrice, option2.premium, option2.size, option2.expiryTime)
        );
        if (option1Hash != option2Hash) {
            return false;
        }

        // 2 个 option hash 进行比较了，因此这里无需比较
        //        int256 premium = option1.premium + option2.premium;
        //        if (premium != 0) {
        //            return false;
        //        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_CALL) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_CALL) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_CALL) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.LONG_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.SHORT_PUT) {
                return false;
            }
        }
        if (option1.optionType == StrategyTypes.OptionType.SHORT_PUT) {
            if (option2.optionType != StrategyTypes.OptionType.LONG_PUT) {
                return false;
            }
        }
        //判断开仓的时间点是不是我们规定的时间点
        if (!TimestampCheck.isFridayEightAM(option1.expiryTime)) {
            return false;
        }
        return true;
    }

    // @notice 检查2个角色对应的期货仓位是否完全相反
    function _isOppositeFuturePosition(
        StrategyTypes.Future memory future1,
        StrategyTypes.Future memory future2
    ) internal pure returns (bool) {
        // 期货方向设置为相反
        bytes32 future1Hash = keccak256(
            abi.encode(future1.underlying, future1.entryPrice, future1.size, future1.expiryTime, future1.isLong)
        );
        bytes32 future2Hash = keccak256(
            abi.encode(future2.underlying, future2.entryPrice, future2.size, future2.expiryTime, !future2.isLong)
        );
        if (future1Hash != future2Hash) {
            return false;
        }
        if (!TimestampCheck.isFridayEightAM(future1.expiryTime)) {
            return false;
        }

        return true;
    }

    /// @notice 此函数用于检查腿 ID 数组中是否存在重复的腿 ID，如果有重复，将触发错误。
    function _checkPositionIdDuplicates(uint256[] memory ids) internal pure {
        uint256 idsLen = ids.length;
        for (uint256 i; i < idsLen; ) {
            for (uint256 j = i + 1; j < idsLen; ) {
                if (ids[i] == ids[j]) {
                    revert PositionIdDuplicates(ids[i]);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice 设置开仓时的userRequst 参数
    function _updateUserRequestStrategy(bytes32 requestId, StrategyTypes.StrategyRequest memory _strategy) internal {
        LibStrategyConfig.Layout storage l = LibStrategyConfig.layout();
        l.userRequestStrategy[requestId].owner = _strategy.owner;
        l.userRequestStrategy[requestId].collateralAmount = _strategy.collateralAmount;
        l.userRequestStrategy[requestId].timestamp = _strategy.timestamp;
        l.userRequestStrategy[requestId].mergeId = _strategy.mergeId;
        l.userRequestStrategy[requestId].owner = _strategy.owner;

        uint256 optionLen = _strategy.option.length;
        for (uint256 i; i < optionLen; ) {
            StrategyTypes.Option memory option_ = _strategy.option[i];
            l.userRequestStrategy[requestId].option.push(option_);
            unchecked {
                ++i;
            }
        }

        uint256 futureLen = _strategy.future.length;
        for (uint256 i; i < futureLen; ) {
            StrategyTypes.Future memory future_ = _strategy.future[i];
            l.userRequestStrategy[requestId].future.push(future_);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import {StrategyTypes} from "./StrategyTypes.sol";
import {LibStrategyConfig} from "./LibStrategyConfig.sol";

library LibVault {
    bytes32 internal constant STORAGE_SLOT = keccak256("dederi.contracts.storage.Vault");

    struct UserBalance {
        /// @notice dederi 总账户余额
        uint256 balance;
        /// @notice 需要链下调用更改 unSettledBalance，若为 0 则没有锁住的资产，提现时加判断，需要通过 pnl 来获取这个值
        uint256 unsettledBalance;
    }
    struct Layout {
        uint256 protocolFee;
        mapping(address => UserBalance) userBalance;
        //        ISwapRouter swapRouter;
    }

    error Vault__AlreadyInitialized();
    error Vault__BalanceNotEnough();

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice 将可用余额划转到策略账户中
    function _marginDecrease(address user, uint256 collateralAmount) internal {
        LibVault.Layout storage l = LibVault.layout();
        l.userBalance[user].balance -= collateralAmount;
    }

    /// @notice 将抵押品划转到账户可用余额中
    function _marginIncrease(address user, uint256 collateralAmount) internal {
        LibVault.Layout storage l = LibVault.layout();
        l.userBalance[user].balance += collateralAmount;
    }

    function _lockBalanceUpdate(address receiver, uint256 amount) internal {
        LibVault.Layout storage l = LibVault.layout();
        l.userBalance[receiver].unsettledBalance += amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library StrategyTypes {
    enum AssetType {
        OPTION,
        FUTURE
    }

    enum OptionType {
        LONG_CALL,
        LONG_PUT,
        SHORT_CALL,
        SHORT_PUT
    }

    ///////////////////
    // Internal Data //
    ///////////////////

    struct Option {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // option strike price (with 18 decimals)
        uint256 strikePrice;
        int256 premium;
        // option expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        // option type
        OptionType optionType;
        bool isActive;
    }

    struct Future {
        uint256 positionId;
        // underlying asset address
        address underlying;
        // (with 18 decimals)
        uint256 entryPrice;
        // future expiry timestamp
        uint256 expiryTime;
        // order size
        uint256 size;
        bool isLong;
        bool isActive;
    }

    struct PositionData {
        uint256 positionId;
        AssetType assetType;
        bool isActive;
    }

    struct StrategyData {
        uint256 strategyId;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        uint256[] positionIds;
        bool isActive;
    }

    struct StrategyDataWithOwner {
        uint256 strategyId;
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        uint256[] positionIds;
        bool isActive;
        address owner;
    }

    struct StrategyAllData {
        uint256 strategyId;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 unsettled;
        int256 realisedPnl;
        bool isActive;
        address owner;
        Option[] option;
        Future[] future;
    }

    struct Strategy {
        address owner;
        // usdc 计价的抵押品余额
        uint256 collateralAmount;
        uint256 timestamp;
        int256 realisedPnl;
        // 合并的id：如果为0，表示不合并；有值进行验证并合并
        uint256 mergeId;
        bool isActive;
        Option[] option;
        Future[] future;
    }

    struct DecreaseStrategyCollateralRequest {
        address owner;
        uint256 strategyId;
        uint256 collateralAmount;
    }

    struct MergeStrategyRequest {
        address owner;
        uint256 firstStrategyId;
        uint256 secondStrategyId;
        uint256 collateralAmount;
    }

    struct SpiltStrategyRequest {
        address owner;
        uint256 strategyId;
        uint256[] positionIds;
        uint256 originalCollateralsToTopUpAmount;
        uint256 originalSplitCollateralAmount;
        uint256 newlySplitCollateralAmount;
    }

    struct LiquidateStrategyRequest {
        uint256 strategyId;
        uint256 mergeId;
        uint256 collateralAmount;
        address owner;
        Future[] future;
        Option[] option;
    }

    struct StrategyRequest {
        address owner;
        uint256 collateralAmount;
        uint256 timestamp;
        uint256 mergeId;
        Option[] option;
        Future[] future;
    }

    struct SellStrategyRequest {
        uint256 strategyId;
        uint256 collateralAmount;
        // uint256[] positionIds;
        address receiver;
        address owner;
        Option[] option;
        Future[] future;
    }

    struct ADLStrategyRequest {
        uint256 strategyId;
        uint256 positionId;
    }

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        // 保证金缩水率
        uint256 marginScale;
        // 合约乘数
        // 上限
        // 下限
    }

    ///////////////////
    // Margin Oracle //
    ///////////////////

    struct MarginItemWithId {
        uint256 strategyId;
        uint256 im;
        uint256 mm;
        int256 futureUnrealizedPnl;
        int256 futurePredictUnrealizedPnl;
        int256 optionValue; // 已有期权价值的盈利或亏损
        int256 optionValueToBeTraded; // 新开期权价值的盈利或亏损
        uint256 updateAt;
    }

    struct MarginItemWithHash {
        bytes32 requestHash;
        uint256 im;
        uint256 mm;
        int256 futureUnrealizedPnl;
        int256 futurePredictUnrealizedPnl;
        int256 optionValue; // 已有期权价值的盈利或亏损
        int256 optionValueToBeTraded; // 新开期权价值的盈利或亏损
        uint256 updateAt;
    }

    ///////////////////
    //   Mark Price  //
    ///////////////////

    struct MarkPriceItemWithId {
        uint256 positionId;
        uint256 price;
        uint256 updateAt;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier nonReentrant() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.status != _ENTERED, "ReentrancyGuard: reentrant call");
        ds.status = _ENTERED;
        _;
        ds.status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.19;

import "../diamond/libraries/StrategyTypes.sol";

interface IInStrategyNFT {
    /**
     * @notice Mint nft to recipient.
     * @param to The recipient address.
     */
    function mint(address to) external returns (uint256);

    function mintWithId(address to, uint256 tokenId) external returns (uint256);

    function burn(uint256 tokenId) external;

    function currentTokenId() external returns (uint256);

    function transferByStrategyManager(address from, address to, uint256 tokenId) external;
}

interface IStrategyNFT is IInStrategyNFT {
    //////////
    // View //
    //////////

    function ownerOf(uint256 tokenId) external view returns (address);

    function ownerOfNotRevert(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

library Constants {
    /*-------------------------------- Role --------------------------------*/
    // 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    // 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // 0xfc425f2263d0df187444b70e47283d622c70181c5baebb1306a01edba1ce184c
    bytes32 internal constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    // 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab
    bytes32 internal constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    // 0x8227712ef8ad39d0f26f06731ef0df8665eb7ada7f41b1ee089adf3c238862a2
    bytes32 internal constant MONITOR_ROLE = keccak256("MONITOR_ROLE");

    // eip 712 type hash
    // 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f
    bytes32 internal constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // struct type hash
    //keccak256("StrategyRequest(address owner,uint256 collateralAmount,uint256 timestamp,uint256 mergeId,Option[] option,Future[] future)Future(uint256 positionId,address underlying,uint256 entryPrice,uint256 expiryTime,uint256 size,bool isLong,bool isActive)Option(uint256 positionId,address underlying,uint256 strikePrice,int256 premium,uint256 expiryTime,uint256 size,uint256 optionType,bool isActive)");
    bytes32 public constant STRATEGY_REQUEST_TYPE_HASH =
        0xd3064c8ea492a12d694a85b1787ddd3f7037857a3ed1c74415588464b5ce1a21;

    //keccak256("Future(uint256 positionId,address underlying,uint256 entryPrice,uint256 expiryTime,uint256 size,bool isLong,bool isActive)");
    bytes32 public constant FUTURE_TYPE_HASH = 0xcdff66689589cd15845093f3be135b778815fc2b8dfa35ff5112e645191afe86;

    //keccak256("Option(uint256 positionId,address underlying,uint256 strikePrice,int256 premium,uint256 expiryTime,uint256 size,uint256 optionType,bool isActive)");
    bytes32 public constant OPTION_TYPE_HASH = 0xbc63504838568be333400315a4bfe079d052fe27fe59b4bdac11192ccbca3e47;

    // time lock
    uint256 public constant TIME_LOCK_DELAY = 2 hours;
    uint256 public constant TIME_LOCK_GRACE_PERIOD = 12 hours;
    // mark price oracle or margin oracle
    uint256 public constant MAX_SIGNER_NUM = 9;
    // spot price oracle
    uint256 internal constant MIN_BOUND_ANCHOR_RATIO = 0.8e18;
    uint256 internal constant MAX_BOUND_ANCHOR_RATIO = 1.2e18;
    // position core
    uint256 internal constant LEG_LIMIT = 8;

    /// @notice A common scaling factor to maintain precision
    uint256 internal constant EXP_SCALE = 1e18;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

library TimestampCheck {
    function isFridayEightAM(uint256 timestamp) internal pure returns (bool) {
        // 获取当前区块的时间戳
        uint256 currentTimestamp = timestamp;

        // 计算当前时间戳对应的周几（0表示星期天，6表示星期六）
        uint256 currentDay = (currentTimestamp / 1 days + 4) % 7;

        // 计算当前时间戳对应的小时
        uint256 currentHour = (currentTimestamp / 1 hours) % 24;

        // 判断是否为每周五北京时间下午4点
        return currentDay == 5 && currentHour == 8;
    }

    function isDailyEightAM(uint256 timestamp) internal pure returns (bool) {
        // 获取当前区块的时间戳
        uint256 currentTimestamp = timestamp;

        // 计算当前时间戳对应的小时
        uint256 currentHour = (currentTimestamp / 1 hours) % 24;

        // 判断是否为北京时间下午4点
        return currentHour == 8;
    }
}