// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
	function getAddress(bytes32 name) external view returns (address);
	function getRequiredAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IAddressResolver.sol";

abstract contract ResolverCache is Initializable {
	IAddressResolver public resolver;
	mapping(bytes32 => address) private _addressCache;

	function __ResolverCache_init(address resolver_) internal onlyInitializing {
		resolver = IAddressResolver(resolver_);
	}

	function getAddress(bytes32 name_) public view returns (address) {
		return _addressCache[name_];
	}

	function getRequiredAddress(bytes32 name_, string memory reason_) public view returns (address) {
		address addr = getAddress(name_);
		require(addr != address(0), reason_);
		return addr;
	}

	function rebuildCache() public virtual {
		bytes32[] memory requiredAddresses = _resolverAddressesRequired();
		for (uint256 i = 0; i < requiredAddresses.length; i++) {
			bytes32 name = requiredAddresses[i];
			address addr = resolver.getRequiredAddress(name, "AddressCache: address not found");
			_addressCache[name] = addr;
		}
	}

	function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = _resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != _addressCache[name] || _addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    function _combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    function _resolverAddressesRequired() internal view virtual returns (bytes32[] memory addresses) {}

    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-solidity-utils/contracts/misc/Constants.sol";
import "@solvprotocol/erc-3525/ERC3525Upgradeable.sol";
import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTConcreteUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IFCFSMultiRepayableConcrete.sol";

abstract contract FCFSMultiRepayableConcrete is IFCFSMultiRepayableConcrete, BaseSFTConcreteUpgradeable {

    mapping(uint256 => SlotRepayInfo) internal _slotRepayInfo;

    mapping(address => uint256) public allocatedCurrencyBalance;

    uint32 internal constant REPAY_RATE_SCALAR = 1e8;

    mapping(uint256 => SlotValueInfo) internal _slotValueInfo;

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepay(txSender_, slot_, currency_, repayCurrencyAmount_);
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        _slotRepayInfo[slot_].currencyBalance += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepayWithBalance(txSender_, slot_, currency_, repayCurrencyAmount_);
        uint256 balance = ERC20(currency_).balanceOf(delegate());
        require(repayCurrencyAmount_ <= balance - allocatedCurrencyBalance[currency_], "MultiRepayableConcrete: insufficient unallocated balance");
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        _slotRepayInfo[slot_].currencyBalance += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function mintOnlyDelegate(uint256 /** tokenId_ */, uint256 slot_, uint256 mintValue_) external virtual override onlyDelegate {
        _slotValueInfo[slot_].slotInitialValue += mintValue_;
        _slotValueInfo[slot_].slotTotalValue += mintValue_;
    }

    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external virtual override onlyDelegate returns (uint256 claimCurrencyAmount_) {
        _beforeClaim(tokenId_, slot_, currency_, claimValue_);
        require(claimValue_ <= claimableValue(tokenId_), "MR: insufficient claimable value");
        _slotValueInfo[slot_].slotTotalValue -= claimValue_;

        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        claimCurrencyAmount_ = claimValue_ * _repayRate(slot_) / (10 ** valueDecimals);
        require(claimCurrencyAmount_ <= _slotRepayInfo[slot_].currencyBalance, "MR: insufficient repaid currency amount");
        allocatedCurrencyBalance[currency_] -= claimCurrencyAmount_;
        _slotRepayInfo[slot_].currencyBalance -= claimCurrencyAmount_;
    }

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external virtual override onlyDelegate {
        _beforeTransfer(fromTokenId_, toTokenId_, fromTokenBalance_, transferValue_);
    }

    function claimableValue(uint256 tokenId_) public view virtual override returns (uint256) {
        uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
        uint256 balance = ERC3525Upgradeable(delegate()).balanceOf(tokenId_);
        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        uint256 dueAmount = balance *  _repayRate(slot) / (10 ** valueDecimals);
        return dueAmount < _slotRepayInfo[slot].currencyBalance ? balance : 
                _slotRepayInfo[slot].currencyBalance * (10 ** valueDecimals) / _repayRate(slot);
    }

    function slotRepaidCurrencyAmount(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].repaidCurrencyAmount;
    }

    function slotCurrencyBalance(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].currencyBalance;
    }

    function slotInitialValue(uint256 slot_) public view virtual override returns (uint256) {
        return _slotValueInfo[slot_].slotInitialValue;
    }

    function slotTotalValue(uint256 slot_) public view virtual override returns (uint256) {
        return _slotValueInfo[slot_].slotTotalValue;
    }

    function _currency(uint256 slot_) internal view virtual returns (address);
    function _repayRate(uint256 slot_) internal view virtual returns (uint256);

    function _beforeRepay(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "FMR: invalid currency");
    }

    function _beforeRepayWithBalance(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "FMR: invalid currency");
    }

    function _beforeClaim(uint256 /** tokenId_ */, uint256 slot_, address currency_, uint256 /** claimValue_ */) internal virtual {
        require(currency_ == _currency(slot_), "FMR: invalid currency");
    }

    function _beforeTransfer(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) internal virtual {}

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTDelegateUpgradeable.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/helpers/ERC20TransferHelper.sol";
import "./IFCFSMultiRepayableDelegate.sol";
import "./IFCFSMultiRepayableConcrete.sol";

abstract contract FCFSMultiRepayableDelegate is IFCFSMultiRepayableDelegate, BaseSFTDelegateUpgradeable {

    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override nonReentrant {
        IFCFSMultiRepayableConcrete(concrete()).repayOnlyDelegate(_msgSender(), slot_, currency_, repayCurrencyAmount_);
        ERC20TransferHelper.doTransferIn(currency_, _msgSender(), repayCurrencyAmount_);
        emit Repay(slot_, _msgSender(), currency_, repayCurrencyAmount_);
    }

    function repayWithBalance(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override nonReentrant {
        require(allowRepayWithBalance(), "MultiRepayableDelegate: cannot repay with balance");
        IFCFSMultiRepayableConcrete(concrete()).repayWithBalanceOnlyDelegate(_msgSender(), slot_, currency_, repayCurrencyAmount_);
        emit Repay(slot_, _msgSender(), currency_, repayCurrencyAmount_);
    }

    function claimTo(address to_, uint256 tokenId_, address currency_, uint256 claimValue_) external virtual override nonReentrant {
        require(claimValue_ > 0, "MultiRepayableDelegate: claim value is zero");
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "MultiRepayableDelegate: caller is not owner nor approved");
        uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);
        uint256 claimableValue = IFCFSMultiRepayableConcrete(concrete()).claimableValue(tokenId_);
        require(claimValue_ <= claimableValue, "MultiRepayableDelegate: over claim");
        
        uint256 claimCurrencyAmount = IFCFSMultiRepayableConcrete(concrete()).claimOnlyDelegate(tokenId_, slot, currency_, claimValue_);
        
        if (claimValue_ == ERC3525Upgradeable.balanceOf(tokenId_)) {
            ERC3525Upgradeable._burn(tokenId_);
        } else {
            ERC3525Upgradeable._burnValue(tokenId_, claimValue_);
        }
        
        ERC20TransferHelper.doTransferOut(currency_, payable(to_), claimCurrencyAmount);
        emit Claim(to_, tokenId_, claimValue_, currency_, claimCurrencyAmount);
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable) {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);

        if (from_ == address(0) && fromTokenId_ == 0) {
            IFCFSMultiRepayableConcrete(concrete()).mintOnlyDelegate(toTokenId_, slot_, value_);
        } 
        
		if (from_ != address(0) && fromTokenId_ != 0 && to_ != address(0) && toTokenId_ != 0) { 
            IFCFSMultiRepayableConcrete(concrete()).transferOnlyDelegate(fromTokenId_, toTokenId_, 
                ERC3525Upgradeable.balanceOf(fromTokenId_), value_);
		}
    }

    function allowRepayWithBalance() public view virtual returns (bool) {
        return true;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFCFSMultiRepayableConcrete {

    struct SlotRepayInfo {
        uint256 repaidCurrencyAmount;
        uint256 currencyBalance;
    }

	struct SlotValueInfo {
		uint256 slotInitialValue;
		uint256 slotTotalValue;
	}

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 mintValue_) external;
    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external returns (uint256);

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external;
    
    function slotRepaidCurrencyAmount(uint256 slot_) external view returns (uint256);
    function slotCurrencyBalance(uint256 slot_) external view returns (uint256);
    function slotInitialValue(uint256 slot_) external view returns (uint256);
    function slotTotalValue(uint256 slot_) external view returns (uint256);

    function claimableValue(uint256 tokenId_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFCFSMultiRepayableDelegate {
    event Repay(uint256 indexed slot, address indexed payer, address currency, uint256 repayCurrencyAmount);
    event Claim(address indexed to, uint256 indexed tokenId, uint256 claimValue, address currency, uint256 claimCurrencyAmount);

    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function repayWithBalance(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function claimTo(address to_, uint256 tokenId_, address currency_, uint256 claimValue_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISFTIssuableConcrete {
    function createSlotOnlyDelegate(address txSender_, bytes calldata inputSlotInfo_) external returns (uint256 slot_);
    function mintOnlyDelegate(address txSender_, address currency_, address mintTo_, uint256 slot_, uint256 tokenId_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISFTIssuableDelegate {
    function createSlotOnlyIssueMarket(address txSender, bytes calldata inputSlotInfo) external returns(uint256 slot);
	function mintOnlyIssueMarket(address txSender, address currency, address mintTo, uint256 slot, uint256 value) external payable returns(uint256 tokenId);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTConcreteUpgradeable.sol";
import "./ISFTIssuableDelegate.sol";
import "./ISFTIssuableConcrete.sol";

abstract contract SFTIssuableConcrete is ISFTIssuableConcrete, BaseSFTConcreteUpgradeable {

	function __SFTIssuableConcrete_init() internal onlyInitializing {
		__BaseSFTConcrete_init();
	}

	function __SFTIssuableConcrete_init_unchained() internal onlyInitializing {
	}

    function createSlotOnlyDelegate(address txSender_, bytes calldata inputSlotInfo_) external virtual override onlyDelegate returns (uint256 slot_)  {
		slot_  = _createSlot(txSender_, inputSlotInfo_);
		require(slot_ != 0, "SFTIssuableConcrete: invalid slot");
	}

    function mintOnlyDelegate(address txSender_, address currency_, address mintTo_, uint256 slot_, uint256 tokenId_, uint256 amount_) 
		external virtual override onlyDelegate {
		_mint(txSender_, currency_, mintTo_, slot_, tokenId_, amount_);
	}

	function _createSlot(address txSender_, bytes memory inputSlotInfo_) internal virtual returns (uint256 slot_);
	function _mint(address txSender_, address currency_, address mintTo_, uint256 slot_, uint256 tokenId_, uint256 amount_) internal virtual;

	uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-solidity-utils/contracts/misc/Constants.sol";
import "@solvprotocol/contracts-v3-address-resolver/contracts/ResolverCache.sol";
import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTDelegateUpgradeable.sol";
import "./ISFTIssuableDelegate.sol";
import "./ISFTIssuableConcrete.sol";

abstract contract SFTIssuableDelegate is ISFTIssuableDelegate, BaseSFTDelegateUpgradeable, ResolverCache {
	function __SFTIssuableDelegate_init(address resolver_, string memory name_, string memory symbol_, uint8 decimals_, 
		address concrete_, address metadata_, address owner_) internal onlyInitializing {
			__BaseSFTDelegate_init(name_, symbol_, decimals_, concrete_, metadata_, owner_);
			__ResolverCache_init(resolver_);
	}

	function __SFTIssuableDelegate_init_unchained() internal onlyInitializing {
	}

	function createSlotOnlyIssueMarket(address txSender_, bytes calldata inputSlotInfo_) external virtual override nonReentrant returns(uint256 slot_) {
		require(_msgSender() == _issueMarket(), "SFTIssuableDelegate: only issue market");
		slot_ = ISFTIssuableConcrete(concrete()).createSlotOnlyDelegate(txSender_, inputSlotInfo_);
		require(!_slotExists(slot_), "SFTIssuableDelegate: slot already exists");
		ERC3525SlotEnumerableUpgradeable._createSlot(slot_);
		emit CreateSlot(slot_, txSender_, inputSlotInfo_);
	}

	function mintOnlyIssueMarket(address txSender_, address currency_, address mintTo_, uint256 slot_, uint256 value_) external payable virtual override nonReentrant returns(uint256 tokenId_) {
		require(_msgSender() == _issueMarket(), "SFTIssuableDelegate: only issue market");
		tokenId_ = ERC3525Upgradeable._mint(mintTo_, slot_, value_);
		ISFTIssuableConcrete(concrete()).mintOnlyDelegate(txSender_, currency_, mintTo_, slot_, tokenId_, value_);
		emit MintValue(tokenId_, slot_, value_);
	}	

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory) {
		bytes32[] memory existAddresses = super._resolverAddressesRequired();
		bytes32[] memory newAddresses = new bytes32[](1);
		newAddresses[0] = Constants.CONTRACT_ISSUE_MARKET;
		return _combineArrays(existAddresses, newAddresses);
	}

	function _issueMarket() internal view virtual returns (address) {
		return getRequiredAddress(Constants.CONTRACT_ISSUE_MARKET, "SFTIssuableDelegate: issueMarket not set");
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultiRechargeableConcrete {
	struct SlotRechargeInfo {
		uint256 totalValue;      // accumulated minted value
		uint256 rechargedAmount; // accumulated recharged currency amount
	}

	struct TokenClaimInfo {
		uint256 claimedAmount;   // accumulated claimed currency amount
	}

	function rechargeOnlyDelegate(uint256 slot_, address currency_, uint256 rechargeAmount_) external payable;
	function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 value_) external;
	function claimOnlyDelegate(uint256 tokenId_, address currency_, uint256 amount_) external;
	function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromBalance_, uint256 value_) external;
	
	function totalValue(uint256 slot_) external view returns (uint256);
	function rechargedAmount(uint256 slot_) external view returns (uint256);
	function claimedAmount(uint256 tokenId_) external view returns(uint256);
	function claimableAmount(uint256 tokenId_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/erc-3525/ERC3525Upgradeable.sol";
import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTConcreteUpgradeable.sol";
import "./IMultiRechargeableConcrete.sol";

abstract contract MultiRechargeableConcrete is IMultiRechargeableConcrete, BaseSFTConcreteUpgradeable {
	mapping(uint256 => SlotRechargeInfo) private _slotRechargeInfos;
	mapping(uint256 => TokenClaimInfo) private _tokenClaimInfos;

	function rechargeOnlyDelegate(uint256 slot_, address currency_, uint256 rechargeAmount_) external payable virtual override onlyDelegate {
		require(currency_ == _currency(slot_), "MultiRechargeableConcrete: invalid currency");
		_slotRechargeInfos[slot_].rechargedAmount += rechargeAmount_;
	}

	function mintOnlyDelegate(uint256 /** tokenId_ */, uint256 slot_, uint256 value_) external virtual override onlyDelegate {
		require(_slotRechargeInfos[slot_].rechargedAmount == 0, "MultiRechargeableConcrete: already recharged");
		_slotRechargeInfos[slot_].totalValue += value_;
	}

	function claimOnlyDelegate(uint256 tokenId_, address currency_, uint256 amount_) external virtual override onlyDelegate {
		uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
		require(currency_ == _currency(slot), "MultiRechargeableConcrete: currency not supported");

		uint256 claimable = claimableAmount(tokenId_);
		require(amount_ <= claimable, "MultiRechargeableConcrete: insufficient amount to claim");
		_tokenClaimInfos[tokenId_].claimedAmount += amount_;
	}

	function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromBalance_, uint256 transferValue_) external virtual override onlyDelegate {
		uint256 transferClaimedAmount = (transferValue_ * _tokenClaimInfos[fromTokenId_].claimedAmount) / fromBalance_;
		_tokenClaimInfos[fromTokenId_].claimedAmount -= transferClaimedAmount;
		_tokenClaimInfos[toTokenId_].claimedAmount += transferClaimedAmount;
	}

	function claimableAmount(uint256 tokenId_) public view virtual override returns (uint256) {
		uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
		uint256 balance = ERC3525Upgradeable(delegate()).balanceOf(tokenId_);

		SlotRechargeInfo storage slotRechargeInfo = _slotRechargeInfos[slot];
		TokenClaimInfo storage tokenClaimInfo = _tokenClaimInfos[tokenId_];
		return (balance * slotRechargeInfo.rechargedAmount) / slotRechargeInfo.totalValue - tokenClaimInfo.claimedAmount;
	}

	function totalValue(uint256 slot_) public view override returns (uint256) {
		return _slotRechargeInfos[slot_].totalValue;
	}
	function rechargedAmount(uint256 slot_) public view override returns (uint256) {
		return _slotRechargeInfos[slot_].rechargedAmount;
	}
	function claimedAmount(uint256 tokenId_) public view override returns(uint256) {
		return _tokenClaimInfos[tokenId_].claimedAmount;
	}
	
	function _afterRecharge(uint256 slot_, uint256 value_) internal virtual {}
	function _afterClaim(uint256 tokenId_, uint256 value_) internal virtual {}

	function _currency(uint256 slot_) internal view virtual returns (address);

	uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultiRepayableConcrete {

    struct SlotRepayInfo {
        uint256 initialValue;
        uint256 totalValue;
        uint256 repaidCurrencyAmount;
    }

    struct TokenRepayInfo {
        uint256 initialValue;
    }

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 mintValue_) external;
    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external returns (uint256);

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external;
    
    function slotInitialValue(uint256 slot_) external view returns (uint256);
    function slotTotalValue(uint256 slot_) external view returns (uint256);
    function repaidCurrencyAmount(uint256 slot_) external view returns (uint256);

    function tokenInitialValue(uint256 tokenId_) external view returns (uint256);
    function claimableValue(uint256 tokenId_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultiRepayableDelegate {
    event Repay(uint256 indexed slot, address indexed payer, uint256 repayCurrencyAmount);
    event Claim(address indexed to, uint256 indexed tokenId, uint256 claimValue);

    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function repayWithBalance(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable;
    function claimTo(address to_, uint256 tokenId_, address currency_, uint256 claimValue_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-solidity-utils/contracts/misc/Constants.sol";
import "@solvprotocol/erc-3525/ERC3525Upgradeable.sol";
import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTConcreteUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IMultiRepayableConcrete.sol";

abstract contract MultiRepayableConcrete is IMultiRepayableConcrete, BaseSFTConcreteUpgradeable {

    mapping(uint256 => SlotRepayInfo) internal _slotRepayInfo;
    mapping(uint256 => TokenRepayInfo) internal _tokenRepayInfo;

    // currency address => the portion of balance that has been allocated to any slots
    mapping(address => uint256) public allocatedCurrencyBalance;

    uint32 internal constant REPAY_RATE_SCALAR = 1e8;

    function repayOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepay(txSender_, slot_, currency_, repayCurrencyAmount_);
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function repayWithBalanceOnlyDelegate(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override onlyDelegate {
        _beforeRepayWithBalance(txSender_, slot_, currency_, repayCurrencyAmount_);
        uint256 balance = ERC20(currency_).balanceOf(delegate());
        require(repayCurrencyAmount_ <= balance - allocatedCurrencyBalance[currency_], "MultiRepayableConcrete: insufficient unallocated balance");
        _slotRepayInfo[slot_].repaidCurrencyAmount += repayCurrencyAmount_;
        allocatedCurrencyBalance[currency_] += repayCurrencyAmount_;
    }

    function mintOnlyDelegate(uint256 tokenId_, uint256 slot_, uint256 mintValue_) external virtual override onlyDelegate {
        _beforeMint(tokenId_, slot_, mintValue_);
        _slotRepayInfo[slot_].initialValue += mintValue_;
        _slotRepayInfo[slot_].totalValue += mintValue_;
        _tokenRepayInfo[tokenId_].initialValue += mintValue_;
    }

    function claimOnlyDelegate(uint256 tokenId_, uint256 slot_, address currency_, uint256 claimValue_) external virtual override onlyDelegate returns (uint256 claimCurrencyAmount_) {
        _beforeClaim(tokenId_, slot_, currency_, claimValue_);
        _slotRepayInfo[slot_].totalValue -= claimValue_;

        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        uint8 currencyDecimals = ERC20(_currency(slot_)).decimals();
        claimCurrencyAmount_ = claimValue_ * _repayRate(slot_) * (10 ** currencyDecimals) / Constants.FULL_PERCENTAGE / REPAY_RATE_SCALAR / (10 ** valueDecimals);
        allocatedCurrencyBalance[currency_] -= claimCurrencyAmount_;
    }

    function transferOnlyDelegate(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) external virtual override onlyDelegate {
        _beforeTransfer(fromTokenId_, toTokenId_, fromTokenBalance_, transferValue_);
        uint256 transferInitialValue = transferValue_ * _tokenRepayInfo[fromTokenId_].initialValue / fromTokenBalance_;
        _tokenRepayInfo[fromTokenId_].initialValue -= transferInitialValue;
        _tokenRepayInfo[toTokenId_].initialValue += transferInitialValue;
    }

    function slotInitialValue(uint256 slot_) public view returns (uint256) {
        return _slotRepayInfo[slot_].initialValue;
    }
    
    function slotTotalValue(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].totalValue;
    }

    function repaidCurrencyAmount(uint256 slot_) public view virtual override returns (uint256) {
        return _slotRepayInfo[slot_].repaidCurrencyAmount;
    }

    function tokenInitialValue(uint256 tokenId_) public view virtual override returns (uint256) {
        return _tokenRepayInfo[tokenId_].initialValue;
    }

    function claimableValue(uint256 tokenId_) public view virtual override returns (uint256) {
        uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
        uint256 balance = ERC3525Upgradeable(delegate()).balanceOf(tokenId_);
        uint8 valueDecimals = ERC3525Upgradeable(delegate()).valueDecimals();
        uint8 currencyDecimals = ERC20(_currency(slot)).decimals();
        uint256 initialValueOfSlot = _slotRepayInfo[slot].initialValue;
        uint256 initialValueOfToken = tokenInitialValue(tokenId_);

        uint256 slotDueAmount = initialValueOfSlot * _repayRate(slot) * (10 ** currencyDecimals) / Constants.FULL_PERCENTAGE / REPAY_RATE_SCALAR / (10 ** valueDecimals);
        uint256 slotRepaidAmount = repaidCurrencyAmount(slot);
        uint256 tokenTotalClaimableValue = slotRepaidAmount >= slotDueAmount ? initialValueOfToken : initialValueOfToken * slotRepaidAmount / slotDueAmount;

        uint256 tokenClaimedBalance = initialValueOfToken - balance;
        return tokenTotalClaimableValue > tokenClaimedBalance ? tokenTotalClaimableValue - tokenClaimedBalance : 0;
    }

    function _currency(uint256 slot_) internal view virtual returns (address);
    function _repayRate(uint256 slot_) internal view virtual returns (uint256);

    function _beforeRepay(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "MultiRepayableConcrete: invalid currency");
    }

    function _beforeRepayWithBalance(address /** txSender_ */, uint256 slot_, address currency_, uint256 /** repayCurrencyAmount_ */) internal virtual {
        require(currency_ == _currency(slot_), "MultiRepayableConcrete: invalid currency");
    }

    function _beforeMint(uint256 /** tokenId_ */, uint256 slot_, uint256 mintValue_) internal virtual {
        // skip repayment check when minting in the process of transferring from id to address
        if (mintValue_ > 0) {
            require(repaidCurrencyAmount(slot_) == 0, "MultiRepayableConcrete: already repaid");
        }
    }

    function _beforeClaim(uint256 /** tokenId_ */, uint256 slot_, address currency_, uint256 /** claimValue_ */) internal virtual {
        require(currency_ == _currency(slot_), "MultiRepayableConcrete: invalid currency");
    }

    function _beforeTransfer(uint256 fromTokenId_, uint256 toTokenId_, uint256 fromTokenBalance_, uint256 transferValue_) internal virtual {}

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTDelegateUpgradeable.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/helpers/ERC20TransferHelper.sol";
import "./IMultiRepayableDelegate.sol";
import "./IMultiRepayableConcrete.sol";

abstract contract MultiRepayableDelegate is IMultiRepayableDelegate, BaseSFTDelegateUpgradeable {

    function repay(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override nonReentrant {
        IMultiRepayableConcrete(concrete()).repayOnlyDelegate(_msgSender(), slot_, currency_, repayCurrencyAmount_);
        ERC20TransferHelper.doTransferIn(currency_, _msgSender(), repayCurrencyAmount_);
        emit Repay(slot_, _msgSender(), repayCurrencyAmount_);
    }

    function repayWithBalance(uint256 slot_, address currency_, uint256 repayCurrencyAmount_) external payable virtual override nonReentrant {
        require(allowRepayWithBalance(), "MultiRepayableDelegate: cannot repay with balance");
        IMultiRepayableConcrete(concrete()).repayWithBalanceOnlyDelegate(_msgSender(), slot_, currency_, repayCurrencyAmount_);
        emit Repay(slot_, _msgSender(), repayCurrencyAmount_);
    }

    function claimTo(address to_, uint256 tokenId_, address currency_, uint256 claimValue_) external virtual override nonReentrant {
        require(claimValue_ > 0, "MultiRepayableDelegate: claim value is zero");
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "MultiRepayableDelegate: caller is not owner nor approved");
        uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);
        uint256 claimableValue = IMultiRepayableConcrete(concrete()).claimableValue(tokenId_);
        require(claimValue_ <= claimableValue, "MultiRepayableDelegate: over claim");
        
        if (claimValue_ == ERC3525Upgradeable.balanceOf(tokenId_)) {
            ERC3525Upgradeable._burn(tokenId_);
        } else {
            ERC3525Upgradeable._burnValue(tokenId_, claimValue_);
        }
        
        uint256 claimCurrencyAmount = IMultiRepayableConcrete(concrete()).claimOnlyDelegate(tokenId_, slot, currency_, claimValue_);
        ERC20TransferHelper.doTransferOut(currency_, payable(to_), claimCurrencyAmount);
        emit Claim(to_, tokenId_, claimValue_);
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable) {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);

        if (from_ == address(0) && fromTokenId_ == 0) {
            IMultiRepayableConcrete(concrete()).mintOnlyDelegate(toTokenId_, slot_, value_);
        } 
        
		if (from_ != address(0) && fromTokenId_ != 0 && to_ != address(0) && toTokenId_ != 0) { 
            IMultiRepayableConcrete(concrete()).transferOnlyDelegate(fromTokenId_, toTokenId_, 
                ERC3525Upgradeable.balanceOf(fromTokenId_), value_);
		}
    }

    function allowRepayWithBalance() public view virtual returns (bool) {
        return true;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../issuable/ISFTIssuableConcrete.sol";

interface ISFTValueIssuableConcrete is ISFTIssuableConcrete {
    function burnOnlyDelegate(uint256 tokenId, uint256 burnValue) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../issuable/ISFTIssuableDelegate.sol";

interface ISFTValueIssuableDelegate is ISFTIssuableDelegate {
    function mintValueOnlyIssueMarket(address txSender, address currency, uint256 tokenId, uint256 mintValue) external payable;
    function burnOnlyIssueMarket(uint256 tokenId, uint256 burnValue) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTConcreteUpgradeable.sol";
import "./ISFTValueIssuableDelegate.sol";
import "./ISFTValueIssuableConcrete.sol";
import "../issuable/SFTIssuableConcrete.sol";

abstract contract SFTValueIssuableConcrete is ISFTValueIssuableConcrete, SFTIssuableConcrete {

	function __SFTValueIssuableConcrete_init() internal onlyInitializing {
		__SFTIssuableConcrete_init();
	}

	function __SFTValueIssuableConcrete_init_unchained() internal onlyInitializing {
	}

	function burnOnlyDelegate(uint256 tokenId_, uint256 burnValue_) external virtual override onlyDelegate {
		_burn(tokenId_, burnValue_);
	}

	function _burn(uint256 tokenId_, uint256 burnValue_) internal virtual;

	uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@solvprotocol/contracts-v3-solidity-utils/contracts/misc/Constants.sol";
import "@solvprotocol/contracts-v3-address-resolver/contracts/ResolverCache.sol";
import "@solvprotocol/contracts-v3-sft-core/contracts/BaseSFTDelegateUpgradeable.sol";
import "./ISFTValueIssuableDelegate.sol";
import "./ISFTValueIssuableConcrete.sol";
import "../issuable/SFTIssuableDelegate.sol";

error OnlyMarket();

abstract contract SFTValueIssuableDelegate is ISFTValueIssuableDelegate, SFTIssuableDelegate {

	event BurnValue(uint256 indexed tokenId, uint256 burnValue);

	function __SFTValueIssuableDelegate_init(
		address resolver_, string memory name_, string memory symbol_, uint8 decimals_, 
		address concrete_, address metadata_, address owner_
	) internal onlyInitializing {
		__SFTIssuableDelegate_init(resolver_, name_, symbol_, decimals_, concrete_, metadata_, owner_);
	}

	function __SFTValueIssuableDelegate_init_unchained() internal onlyInitializing {
	}

	function mintValueOnlyIssueMarket(
		address txSender_, address currency_, uint256 tokenId_, uint256 mintValue_
	) external payable virtual override nonReentrant {
		if (_msgSender() != _issueMarket()) {
			revert OnlyMarket();
		}

		address owner = ERC3525Upgradeable.ownerOf(tokenId_);
		uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);

		ERC3525Upgradeable._mintValue(tokenId_, mintValue_);
		ISFTIssuableConcrete(concrete()).mintOnlyDelegate(txSender_, currency_, owner, slot, tokenId_, mintValue_);
		emit MintValue(tokenId_, slot, mintValue_);
	}

	function burnOnlyIssueMarket(uint256 tokenId_, uint256 burnValue_) external virtual override nonReentrant {
		if (_msgSender() != _issueMarket()) {
			revert OnlyMarket();
		}

		uint256 actualBurnValue = burnValue_ == 0 ? ERC3525Upgradeable.balanceOf(tokenId_) : burnValue_;
		ISFTValueIssuableConcrete(concrete()).burnOnlyDelegate(tokenId_, actualBurnValue);

		if (burnValue_ == 0) {
			ERC3525Upgradeable._burn(tokenId_);
		} else {
			ERC3525Upgradeable._burnValue(tokenId_, burnValue_);
		}
		emit BurnValue(tokenId_, actualBurnValue);
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/access/OwnControl.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/access/SFTConcreteControl.sol";
import "./interface/IBaseSFTConcrete.sol";

abstract contract BaseSFTConcreteUpgradeable is IBaseSFTConcrete, SFTConcreteControl {

	modifier onlyDelegateOwner {
		require(_msgSender() == OwnControl(delegate()).owner(), "only delegate owner");
		_;
	}

	function __BaseSFTConcrete_init() internal onlyInitializing {
		__SFTConcreteControl_init();
	}

	function isSlotValid(uint256 slot_) external view virtual override returns (bool) {
		return _isSlotValid(slot_);
	}

	function _isSlotValid(uint256 slot_) internal view virtual returns (bool);

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@solvprotocol/erc-3525/ERC3525SlotEnumerableUpgradeable.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/access/ISFTConcreteControl.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/access/SFTDelegateControl.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/access/OwnControl.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/misc/Constants.sol";
import "./interface/IBaseSFTDelegate.sol";
import "./interface/IBaseSFTConcrete.sol";

abstract contract BaseSFTDelegateUpgradeable is IBaseSFTDelegate, ERC3525SlotEnumerableUpgradeable, 
	OwnControl, SFTDelegateControl, ReentrancyGuardUpgradeable {

	event CreateSlot(uint256 indexed _slot, address indexed _creator, bytes _slotInfo);
	event MintValue(uint256 indexed _tokenId, uint256 indexed _slot, uint256 _value);

	function __BaseSFTDelegate_init(
		string memory name_, string memory symbol_, uint8 decimals_, 
		address concrete_, address metadata_, address owner_
	) internal onlyInitializing {
		ERC3525Upgradeable.__ERC3525_init(name_, symbol_, decimals_);
		OwnControl.__OwnControl_init(owner_);
		ERC3525Upgradeable._setMetadataDescriptor(metadata_);

		SFTDelegateControl.__SFTDelegateControl_init(concrete_);
		__ReentrancyGuard_init();

		//address of concrete must be zero when initializing impletion contract avoid failed after upgrade
		if (concrete_ != Constants.ZERO_ADDRESS) {
			ISFTConcreteControl(concrete_).setDelegate(address(this));
		}
	}

	function delegateToConcreteView(bytes calldata data) external view override returns (bytes memory) {
		(bool success, bytes memory returnData) = concrete().staticcall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
	}

	function contractType() external view virtual returns (string memory);

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseSFTConcrete {
    function isSlotValid(uint256 slot_) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseSFTDelegate  {
    function delegateToConcreteView(bytes calldata data) external view returns (bytes memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-solidity-utils/contracts/misc/Constants.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/helpers/ERC20TransferHelper.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/issuable/SFTIssuableConcrete.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/multi-rechargeable/MultiRechargeableConcrete.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/multi-repayable/MultiRepayableConcrete.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IEarnConcrete.sol";

contract EarnConcrete is IEarnConcrete, SFTIssuableConcrete, MultiRepayableConcrete {

    mapping(address => bool) internal _allowCurrencies;
    mapping(uint256 => SlotBaseInfo) internal _slotBaseInfos;
    mapping(uint256 => SlotExtInfo) internal _slotExtInfos;

    function initialize() external initializer {
        __SFTIssuableConcrete_init();
	}

    function setCurrencyOnlyDelegate(address currency_, bool isAllowed_) external override onlyDelegate {
        _setCurrency(currency_, isAllowed_);
    }

	function setInterestRateOnlyDelegate(address txSender_, uint256 slot_, int32 interestRate_) external override onlyDelegate {
        SlotExtInfo storage extInfo = _slotExtInfos[slot_];
        require(extInfo.interestType == InterestType.FLOATING, "EarnConcrete: not floating interest");
        require(txSender_ == extInfo.supervisor, "EarnConcrete: only supervisor");
        require(slotTotalValue(slot_) == slotInitialValue(slot_), "EarnConcrete: already claimed");

        extInfo.interestRate = interestRate_;
        extInfo.isInterestRateSet = true;
    }

    function claimableValue(uint256 tokenId_) public view virtual override returns (uint256) {
        uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
        if (_slotExtInfos[slot].interestType == InterestType.FLOATING && !_slotExtInfos[slot].isInterestRateSet) {
            return 0;
        }
        return super.claimableValue(tokenId_);
    }

    function getSlot(address issuer_, address currency_, uint64 valueDate_, uint64 maturity_, uint64 createTime_, bool transferable_) public view returns (uint256) {
		uint256 chainId;
        assembly { chainId := chainid() }
		return uint256(keccak256(abi.encodePacked(chainId, delegate(), issuer_, currency_, valueDate_, maturity_, createTime_, transferable_)));
	}

    function slotBaseInfo(uint256 slot_) external view override returns (SlotBaseInfo memory) {
        return _slotBaseInfos[slot_];
    }

    function slotExtInfo(uint256 slot_) external view override returns (SlotExtInfo memory) {
        return _slotExtInfos[slot_];
    }

    function _isSlotValid(uint256 slot_) internal view virtual override returns (bool) {
        return _slotBaseInfos[slot_].isValid;
    }

    function _createSlot(address txSender_, bytes memory inputSlotInfo_) internal virtual override returns (uint256 slot_) {
        InputSlotInfo memory input = abi.decode(inputSlotInfo_, (InputSlotInfo));
        _validateSlotInfo(input);

        require(_allowCurrencies[input.currency], "EarnConcrete: currency not allowed");

        SlotBaseInfo memory baseInfo = SlotBaseInfo({
            issuer: txSender_,
            currency: input.currency,
            valueDate: input.valueDate,
            maturity: input.maturity,
            createTime: input.createTime,
            transferable: input.transferable,
            isValid: true
        });

        slot_ = getSlot(txSender_, input.currency, input.valueDate, input.maturity, input.createTime, input.transferable);

        _slotBaseInfos[slot_] = baseInfo;
        _slotExtInfos[slot_] = SlotExtInfo({
            supervisor: input.supervisor,
            issueQuota: input.issueQuota,
            interestType: input.interestType,
            interestRate: input.interestRate,
            isInterestRateSet: input.interestType == InterestType.FIXED,
            externalURI: input.externalURI
        });
    }

    function _mint(address /** txSender_ */, address currency_, address /** mintTo_ */, uint256 slot_, uint256 /** tokenId_ */, uint256 /** amount_ */) internal virtual override {
        SlotBaseInfo storage base = _slotBaseInfos[slot_];
        require(base.isValid, "EarnConcrete: invalid slot");
        require(base.currency == currency_, "EarnConcrete: currency not match");

        uint256 issueQuota = _slotExtInfos[slot_].issueQuota;
        uint256 issuedAmount = MultiRepayableConcrete.slotInitialValue(slot_);
        require(issuedAmount <= issueQuota, "EarnConcrete: issueQuota exceeded");
    }

    function _validateSlotInfo(InputSlotInfo memory input_) internal view virtual {
        require(input_.valueDate > block.timestamp, "EarnConcrete: invalid valueDate");
        require(input_.maturity > input_.valueDate, "EarnConcrete: invalid maturity");
    }

    function isSlotTransferable(uint256 slot_) external view override returns (bool) {
        return _slotBaseInfos[slot_].transferable;
    }

    function isCurrencyAllowed(address currency_) external view returns (bool) {
        return _allowCurrencies[currency_];
    }

    function _setCurrency(address currency_, bool isAllowed_) internal virtual {
        _allowCurrencies[currency_] = isAllowed_;
    }

	function _currency(uint256 slot_) internal view virtual override returns (address) {
        return _slotBaseInfos[slot_].currency;
    }

    function _repayRate(uint256 slot_) internal view virtual override returns (uint256) {
        SlotBaseInfo storage baseInfo = _slotBaseInfos[slot_];
        SlotExtInfo storage extInfo = _slotExtInfos[slot_];

        uint256 scaledFullPercentage = uint256(Constants.FULL_PERCENTAGE) * MultiRepayableConcrete.REPAY_RATE_SCALAR;
        uint256 scaledPositiveInterestRate = 
            (extInfo.interestRate < 0 ? uint256(int256(0 - extInfo.interestRate)) : uint256(int256(extInfo.interestRate))) * 
            MultiRepayableConcrete.REPAY_RATE_SCALAR * (baseInfo.maturity - baseInfo.valueDate) / Constants.SECONDS_PER_YEAR;

        return extInfo.interestRate < 0 ? scaledFullPercentage - scaledPositiveInterestRate : scaledFullPercentage + scaledPositiveInterestRate;
    }

    function _beforeRepayWithBalance(address txSender_, uint256 slot_, address currency_, uint256 repayCurrencyAmount_) internal virtual override {
        super._beforeRepayWithBalance(txSender_, slot_, currency_, repayCurrencyAmount_);
        require(txSender_ == _slotBaseInfos[slot_].issuer, "EarnConcrete: only issuer");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-abilities/contracts/issuable/SFTIssuableDelegate.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/multi-repayable/MultiRepayableDelegate.sol";
import "./IEarnConcrete.sol";

contract EarnDelegate is SFTIssuableDelegate, MultiRepayableDelegate {

    event SetCurrency(address indexed currency, bool isAllowed);
    event SetInterestRate(uint256 indexed slot, int32 interestRate);

    bool private __allowRepayWithBalance;

	function initialize(
        address resolver_, string calldata name_, string calldata symbol_, uint8 decimals_, 
		address concrete_, address descriptor_, address owner_, bool allowRepayWithBalance_
    ) external initializer {
		__SFTIssuableDelegate_init(resolver_, name_, symbol_, decimals_, concrete_, descriptor_, owner_);
        __allowRepayWithBalance = allowRepayWithBalance_;
	}

	function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable, MultiRepayableDelegate) {
        MultiRepayableDelegate._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);

        // untransferable
        if (from_ != address(0) && to_ != address(0)) {
            require(IEarnConcrete(concrete()).isSlotTransferable(slot_), "untransferable");
        }
    }

    function setCurrencyOnlyOwner(address currency_, bool isAllowed_) external onlyOwner {
        IEarnConcrete(concrete()).setCurrencyOnlyDelegate(currency_, isAllowed_);
        emit SetCurrency(currency_, isAllowed_);
    }

    function setInterestRateOnlySupervisor(uint256 slot_, int32 interestRate_) external {
        IEarnConcrete(concrete()).setInterestRateOnlyDelegate(_msgSender(), slot_, interestRate_);
        emit SetInterestRate(slot_, interestRate_);
    }

    function allowRepayWithBalance() public view virtual override returns (bool) {
        return __allowRepayWithBalance;
    }

    function contractType() external view virtual override returns (string memory) {
        return "Closed-end Fund";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEarnConcrete {
	enum InterestType {
		FIXED,
		FLOATING
	}

	struct InputSlotInfo {
		address currency;
		address supervisor;
		uint256 issueQuota;
		InterestType interestType;
		int32 interestRate;
		uint64 valueDate;
		uint64 maturity;
		uint64 createTime;
		bool transferable;
		string externalURI;
	}

	struct SlotBaseInfo {
		address issuer;
		address currency;
		uint64 valueDate;
		uint64 maturity;
		uint64 createTime;
		bool transferable;
		bool isValid;
	}

	struct SlotExtInfo {
		address supervisor;
		uint256 issueQuota;
		InterestType interestType;
		int32 interestRate;
		bool isInterestRateSet;
		string externalURI;
	}

	function slotBaseInfo(uint256 slot_) external returns (SlotBaseInfo memory);
	function slotExtInfo(uint256 slot_) external returns (SlotExtInfo memory);
	function isSlotTransferable(uint256 slot_) external returns (bool);
	function isCurrencyAllowed(address currency_) external returns (bool);

	function setCurrencyOnlyDelegate(address currency_, bool isAllowed_) external;
	function setInterestRateOnlyDelegate(address txSender_, uint256 slot_, int32 interestRate_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundRedemptionConcrete {
	
	struct RedeemInfo {
		bytes32 poolId;
		address currency;
		uint256 createTime;
		uint256 nav;
	}	

	function setRedeemNavOnlyDelegate(uint256 slot_, uint256 nav_) external;

	function getRedeemInfo(uint256 slot_) external view returns (RedeemInfo memory);
	function getRedeemNav(uint256 slot_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundRedemptionDelegate {
	function setRedeemNavOnlyMarket(uint256 slot_, uint256 nav_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-abilities/contracts/value-issuable/SFTValueIssuableConcrete.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/fcfs-multi-repayable/FCFSMultiRepayableConcrete.sol";
import "./IOpenFundRedemptionConcrete.sol";

contract OpenFundRedemptionConcrete is IOpenFundRedemptionConcrete, SFTValueIssuableConcrete, FCFSMultiRepayableConcrete {

    mapping(uint256 => RedeemInfo) internal _redeemInfos;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
    function initialize() external initializer {
        __SFTIssuableConcrete_init();
	}

    function setRedeemNavOnlyDelegate(uint256 slot_, uint256 nav_) external virtual override onlyDelegate {
        _redeemInfos[slot_].nav = nav_;
    }

    function getRedeemInfo(uint256 slot_) external view virtual override returns (RedeemInfo memory) {
        return _redeemInfos[slot_];
    }

	function getRedeemNav(uint256 slot_) external view virtual override returns (uint256) {
        return _redeemInfos[slot_].nav;
    }
	
    function _isSlotValid( uint256 slot_) internal view virtual override returns (bool) {
        return _redeemInfos[slot_].createTime != 0;
    }

    function _createSlot( address /* txSender_ */, bytes memory inputSlotInfo_) internal virtual override returns (uint256 slot_) {
        RedeemInfo memory redeemInfo = abi.decode(inputSlotInfo_, (RedeemInfo));
        require(redeemInfo.poolId != bytes32(0), "OFRC: invalid poolId");
        require(redeemInfo.currency != address(0), "OFRC: invalid currency");
        require(redeemInfo.createTime != 0, "OFRC: invalid createTime");
        slot_ = _getSlot(redeemInfo.poolId, redeemInfo.currency, redeemInfo.createTime);

        // if the slot is already created, do nothing
        if (_redeemInfos[slot_].createTime == 0) {
            _redeemInfos[slot_] = redeemInfo;
        }
    }

    function _getSlot(bytes32 poolId_, address currency_, uint256 createTime_) internal view virtual returns (uint256) {
		uint256 chainId;
        assembly { chainId := chainid() }
		return uint256(keccak256(abi.encodePacked(chainId, delegate(), poolId_, currency_, createTime_)));
    }

    function _mint(
        address /** txSender_ */, address currency_, address /** mintTo_ */, 
        uint256 slot_, uint256 /** tokenId_ */, uint256 /** amount_ */
    ) internal virtual override {
        require(_isSlotValid(slot_), "OFRC: invalid slot");
        require(_redeemInfos[slot_].currency == currency_, "OFRC: invalid currency");
    }

    function _burn(uint256 tokenId_, uint256 burnValue_) internal virtual override {
        uint256 slot = ERC3525Upgradeable(delegate()).slotOf(tokenId_);
        FCFSMultiRepayableConcrete._slotValueInfo[slot].slotTotalValue -= burnValue_;
    }

    function _currency( uint256 slot_) internal view virtual override returns (address) {
        return _redeemInfos[slot_].currency;
    }

    function _repayRate( uint256 slot_) internal view virtual override returns (uint256) {
        return _redeemInfos[slot_].nav;
    }
	

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-abilities/contracts/fcfs-multi-repayable/FCFSMultiRepayableDelegate.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/value-issuable/SFTValueIssuableDelegate.sol";
import "./IOpenFundRedemptionDelegate.sol";
import "./IOpenFundRedemptionConcrete.sol";

contract OpenFundRedemptionDelegate is IOpenFundRedemptionDelegate, SFTValueIssuableDelegate, FCFSMultiRepayableDelegate {

	bytes32 internal constant CONTRACT_OPEN_FUND_MARKET = "OpenFundMarket"; 

    bool private __allowRepayWithBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
	function initialize(
        address resolver_, string calldata name_, string calldata symbol_, uint8 decimals_, 
		address concrete_, address descriptor_, address owner_, bool allowRepayWithBalance_
    ) external initializer {
		__SFTIssuableDelegate_init(resolver_, name_, symbol_, decimals_, concrete_, descriptor_, owner_);
        __allowRepayWithBalance = allowRepayWithBalance_;
	}

	function setRedeemNavOnlyMarket(uint256 slot_, uint256 nav_) external virtual override {
		require(_msgSender() == _issueMarket(), "OFRD: only market");
		IOpenFundRedemptionConcrete(concrete()).setRedeemNavOnlyDelegate(slot_, nav_);
	}

    function allowRepayWithBalance() public view virtual override returns (bool) {
        return __allowRepayWithBalance;
    }

	function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable, FCFSMultiRepayableDelegate) {
        FCFSMultiRepayableDelegate._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory addressNames) {
		addressNames = new bytes32[](1);
		addressNames[0] = CONTRACT_OPEN_FUND_MARKET;
	}

	function _issueMarket() internal view virtual override returns (address) {
		return getRequiredAddress(CONTRACT_OPEN_FUND_MARKET, "OFRD: OpenFundMarket not set");
	}

	function contractType() external view virtual override returns (string memory) {
        return "Open Fund Redemptions";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-earn/contracts/IEarnConcrete.sol";

interface IOpenFundShareConcrete is IEarnConcrete {
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundShareDelegate {
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@solvprotocol/contracts-v3-sft-earn/contracts/EarnConcrete.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/value-issuable/SFTValueIssuableConcrete.sol";
import "./IOpenFundShareConcrete.sol";

error BurnNotAllowed();

contract OpenFundShareConcrete is IOpenFundShareConcrete, EarnConcrete, SFTValueIssuableConcrete {
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
    function _burn(uint256 tokenId_, uint256 burnValue_) internal virtual override {
        uint256 slot = IERC3525Upgradeable(delegate()).slotOf(tokenId_);
        SlotExtInfo storage slotExtInfo = _slotExtInfos[slot];
        if (slotExtInfo.isInterestRateSet) {
            revert BurnNotAllowed();
        }

        if (burnValue_ > 0) {
            uint256 tokenBalance = IERC3525Upgradeable(delegate()).balanceOf(tokenId_);
            uint256 burnTokenInitialValue = burnValue_ * _tokenRepayInfo[tokenId_].initialValue / tokenBalance;
            _tokenRepayInfo[tokenId_].initialValue -= burnTokenInitialValue;

            _slotRepayInfo[slot].initialValue -= burnTokenInitialValue;
            _slotRepayInfo[slot].totalValue -= burnValue_;
        }
    }

    function _beforeMint(uint256 /** tokenId_ */, uint256 /** slot_ */, uint256 /** mintValue_ */) internal virtual override {
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solvprotocol/contracts-v3-sft-earn/contracts/EarnDelegate.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/value-issuable/SFTValueIssuableDelegate.sol";
import "./IOpenFundShareDelegate.sol";
import "./IOpenFundShareConcrete.sol";

contract OpenFundShareDelegate is IOpenFundShareDelegate, EarnDelegate, SFTValueIssuableDelegate {

	bytes32 internal constant CONTRACT_OPEN_FUND_MARKET = "OpenFundMarket"; 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }

	function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override(ERC3525SlotEnumerableUpgradeable, EarnDelegate) {
        EarnDelegate._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory addressNames) {
		addressNames = new bytes32[](1);
		addressNames[0] = CONTRACT_OPEN_FUND_MARKET;
	}

	function _issueMarket() internal view virtual override returns (address) {
		return getRequiredAddress(CONTRACT_OPEN_FUND_MARKET, "OFSD: Market not set");
	}

	function contractType() external view virtual override(BaseSFTDelegateUpgradeable, EarnDelegate) returns (string memory) {
        return "Open Fund Shares";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract AdminControl is Initializable, ContextUpgradeable {

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    address public admin;
    address public pendingAdmin;

    modifier onlyAdmin() {
        require(_msgSender() == admin, "only admin");
        _;
    }

    function __AdminControl_init(address admin_) internal onlyInitializing {
        __AdminControl_init_unchained(admin_);
    }

    function __AdminControl_init_unchained(address admin_) internal onlyInitializing {
        admin = admin_;
        emit NewAdmin(address(0), admin_);
    }

    function setPendingAdmin(address newPendingAdmin_) external virtual onlyAdmin {
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin_);
        pendingAdmin = newPendingAdmin_;        
    }

    function acceptAdmin() external virtual {
        require(_msgSender() == pendingAdmin, "only pending admin");
        emit NewAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

	uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";

abstract contract GovernorControl is AdminControl {
	event NewGovernor(address oldGovernor, address newGovernor);

	address public governor;

	modifier onlyGovernor() {
		require(governor == _msgSender(), "only governor");
		_;
	}

	function __GovernorControl_init(address governor_) internal onlyInitializing {
		__GovernorControl_init_unchained(governor_);
		__AdminControl_init_unchained(_msgSender());
	}

	function __GovernorControl_init_unchained(address governor_) internal onlyInitializing {
		_setGovernor(governor_);
	}

	function setGovernorOnlyAdmin(address newGovernor_) public onlyAdmin {
		_setGovernor(newGovernor_);
	}

	function _setGovernor(address newGovernor_) internal {
		require(newGovernor_ != address(0), "Governor address connot be 0");
		emit NewGovernor(governor, newGovernor_);
		governor = newGovernor_;
	}

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ISFTConcreteControl {
	event NewDelegate(address old_, address new_);

	function setDelegate(address newDelegate_) external;
	function delegate() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISFTDelegateControl {
	event NewConcrete(address old_, address new_);

	function concrete() external view returns (address);
	function setConcreteOnlyAdmin(address newConcrete_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";

abstract contract OwnControl is AdminControl {
	event NewOwner(address oldOwner, address newOwner);

	address public owner;

	modifier onlyOwner() {
		require(owner == _msgSender(), "only owner");
		_;
	}

	function __OwnControl_init(address owner_) internal onlyInitializing {
		__OwnControl_init_unchained(owner_);
		__AdminControl_init_unchained(_msgSender());
	}

	function __OwnControl_init_unchained(address owner_) internal onlyInitializing {
		_setOwner(owner_);
	}

	function setOwnerOnlyAdmin(address newOwner_) public onlyAdmin {
		_setOwner(newOwner_);
	}

	function _setOwner(address newOwner_) internal {
		require(newOwner_ != address(0), "Owner address connot be 0");
		emit NewOwner(owner, newOwner_);
		owner = newOwner_;
	}

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";
import "./ISFTConcreteControl.sol";

abstract contract SFTConcreteControl is ISFTConcreteControl, AdminControl {
    address private _delegate;

    modifier onlyDelegate() {
        require(_msgSender() == _delegate, "only delegate");
        _;
    }

    function __SFTConcreteControl_init() internal onlyInitializing {
        __AdminControl_init_unchained(_msgSender());
        __SFTConcreteControl_init_unchained();
    }

    function __SFTConcreteControl_init_unchained() internal onlyInitializing {}

    function delegate() public view override returns (address) {
        return _delegate;
    }

    function setDelegate(address newDelegate_) external override {
        if (_delegate != address(0)) {
            require(_msgSender() == admin, "only admin");
        }

        emit NewDelegate(_delegate, newDelegate_);
        _delegate = newDelegate_;
    }

	uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdminControl.sol";
import "./ISFTDelegateControl.sol";

abstract contract SFTDelegateControl is ISFTDelegateControl, AdminControl {
    address private _concrete;

    function __SFTDelegateControl_init(address concrete_) internal onlyInitializing {
        __AdminControl_init_unchained(_msgSender());
        __SFTDelegateControl_init_unchained(concrete_);
    }

    function __SFTDelegateControl_init_unchained(address concrete_) internal onlyInitializing {
        _concrete = concrete_;
    }

    function concrete() public view override returns (address) {
        return _concrete;
    }

    function setConcreteOnlyAdmin(address newConcrete_) external override onlyAdmin {
        emit NewConcrete(_concrete, newConcrete_);
        _concrete = newConcrete_;
    }

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../misc/Constants.sol";

interface ERC20Interface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library ERC20TransferHelper {
    function doApprove(address underlying, address spender, uint256 amount) internal {
        require(underlying.code.length > 0, "invalid underlying");
        (bool success, bytes memory data) = underlying.call(
            abi.encodeWithSelector(
                ERC20Interface.approve.selector,
                spender,
                amount
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SAF");
    }

    function doTransferIn(address underlying, address from, uint256 amount) internal {
        if (underlying == Constants.ETH_ADDRESS) {
            // Sanity checks
            require(tx.origin == from || msg.sender == from, "sender mismatch");
            require(msg.value >= amount, "value mismatch");
        } else {
            require(underlying.code.length > 0, "invalid underlying");
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(
                    ERC20Interface.transferFrom.selector,
                    from,
                    address(this),
                    amount
                )
            );
            require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
        }
    }

    function doTransferOut(address underlying, address payable to, uint256 amount) internal {
        if (underlying == Constants.ETH_ADDRESS) {
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success, "STE");
        } else {
            require(underlying.code.length > 0, "invalid underlying");
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(
                    ERC20Interface.transfer.selector,
                    to,
                    amount
                )
            );
            require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
        }
    }

    function getCashPrior(address underlying_) internal view returns (uint256) {
        if (underlying_ == Constants.ETH_ADDRESS) {
            uint256 startingBalance = address(this).balance - msg.value;
            return startingBalance;
        } else {
            ERC20Interface token = ERC20Interface(underlying_);
            return token.balanceOf(address(this));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC721Interface {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ERC3525Interface {
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) external payable;

    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) external payable returns (uint256); 
}

library ERC3525TransferHelper {
    function doTransferIn(
        address underlying,
        address from,
        uint256 tokenId
    ) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.transferFrom(from, address(this), tokenId);
    }

    function doTransferOut(
        address underlying,
        address to,
        uint256 tokenId
    ) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.transferFrom(address(this), to, tokenId);
    }

    function doTransferIn(
        address underlying,
        uint256 fromTokenId,
        uint256 value
    ) internal returns (uint256 newTokenId) {
        ERC3525Interface token = ERC3525Interface(underlying);
        return token.transferFrom(fromTokenId, address(this), value);
    }

    function doTransferOut(
        address underlying,
        uint256 fromTokenId,
        address to,
        uint256 value
    ) internal returns (uint256 newTokenId) {
        ERC3525Interface token = ERC3525Interface(underlying);
        newTokenId = token.transferFrom(fromTokenId, to, value);
    }

    function doTransfer(
        address underlying,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 value
    ) internal {
        ERC3525Interface token = ERC3525Interface(underlying);
        token.transferFrom(fromTokenId, toTokenId, value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Constants {
    uint32 internal constant FULL_PERCENTAGE = 10000;

    uint32 internal constant SECONDS_PER_YEAR = 360 * 24 * 60 * 60;
    
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    bytes32 internal constant CONTRACT_ISSUE_MARKET= "IssueMarket";
    bytes32 internal constant CONTRACT_ISSUE_MARKET_PRICE_STRATEGY_MANAGER = "IMPriceStrategyManager";
    bytes32 internal constant CONTRACT_ISSUE_MARKET_WHITELIST_STRATEGY_MANAGER = "IMWhitelistStrategyManager";
	bytes32 internal constant CONTRACT_ISSUE_MARKET_UNDERWRITER_PROFIT_TOKEN = "IMUnderwriterProfitToken";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./ERC3525Upgradeable.sol";
import "./extensions/IERC3525SlotEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ERC3525SlotEnumerableUpgradeable is Initializable, ContextUpgradeable, ERC3525Upgradeable, IERC3525SlotEnumerableUpgradeable {
    function __ERC3525SlotEnumerable_init(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal onlyInitializing {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC3525SlotEnumerable_init_unchained(
        string memory,
        string memory,
        uint8
    ) internal onlyInitializing {
    }

    struct SlotData {
        uint256 slot;
        uint256[] slotTokens;
    }

    // slot => tokenId => index
    mapping(uint256 => mapping(uint256 => uint256)) private _slotTokensIndex;

    SlotData[] private _allSlots;

    // slot => index
    mapping(uint256 => uint256) private _allSlotsIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC3525Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC3525SlotEnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function slotCount() public view virtual override returns (uint256) {
        return _allSlots.length;
    }

    function slotByIndex(uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525SlotEnumerableUpgradeable.slotCount(), "ERC3525SlotEnumerable: slot index out of bounds");
        return _allSlots[index_].slot;
    }

    function _slotExists(uint256 slot_) internal view virtual returns (bool) {
        return _allSlots.length != 0 && _allSlots[_allSlotsIndex[slot_]].slot == slot_;
    }

    function tokenSupplyInSlot(uint256 slot_) public view virtual override returns (uint256) {
        if (!_slotExists(slot_)) {
            return 0;
        }
        return _allSlots[_allSlotsIndex[slot_]].slotTokens.length;
    }

    function tokenInSlotByIndex(uint256 slot_, uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525SlotEnumerableUpgradeable.tokenSupplyInSlot(slot_), "ERC3525SlotEnumerable: slot token index out of bounds");
        return _allSlots[_allSlotsIndex[slot_]].slotTokens[index_];
    }

    function _tokenExistsInSlot(uint256 slot_, uint256 tokenId_) private view returns (bool) {
        SlotData storage slotData = _allSlots[_allSlotsIndex[slot_]];
        return slotData.slotTokens.length > 0 && slotData.slotTokens[_slotTokensIndex[slot_][tokenId_]] == tokenId_;
    }

    function _createSlot(uint256 slot_) internal virtual {
        require(!_slotExists(slot_), "ERC3525SlotEnumerable: slot already exists");
        SlotData memory slotData = SlotData({
            slot: slot_, 
            slotTokens: new uint256[](0)
        });
        _addSlotToAllSlotsEnumeration(slotData);
        emit SlotChanged(0, 0, slot_);
    }

    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override {
        super._beforeValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);

        if (from_ == address(0) && fromTokenId_ == 0 && !_slotExists(slot_)) {
            _createSlot(slot_);
        }

        //Shh - currently unused
        to_;
        toTokenId_;
        value_;
    }

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual override {
        if (from_ == address(0) && fromTokenId_ == 0 && !_tokenExistsInSlot(slot_, toTokenId_)) {
            _addTokenToSlotEnumeration(slot_, toTokenId_);
        } else if (to_ == address(0) && toTokenId_ == 0 && _tokenExistsInSlot(slot_, fromTokenId_)) {
            _removeTokenFromSlotEnumeration(slot_, fromTokenId_);
        }

        //Shh - currently unused
        value_;

        super._afterValueTransfer(from_, to_, fromTokenId_, toTokenId_, slot_, value_);
    }

    function _addSlotToAllSlotsEnumeration(SlotData memory slotData) private {
        _allSlotsIndex[slotData.slot] = _allSlots.length;
        _allSlots.push(slotData);
    }

    function _addTokenToSlotEnumeration(uint256 slot_, uint256 tokenId_) private {
        SlotData storage slotData = _allSlots[_allSlotsIndex[slot_]];
        _slotTokensIndex[slot_][tokenId_] = slotData.slotTokens.length;
        slotData.slotTokens.push(tokenId_);
    }

    function _removeTokenFromSlotEnumeration(uint256 slot_, uint256 tokenId_) private {
        SlotData storage slotData = _allSlots[_allSlotsIndex[slot_]];
        uint256 lastTokenIndex = slotData.slotTokens.length - 1;
        uint256 lastTokenId = slotData.slotTokens[lastTokenIndex];
        uint256 tokenIndex = _slotTokensIndex[slot_][tokenId_];

        slotData.slotTokens[tokenIndex] = lastTokenId;
        _slotTokensIndex[slot_][lastTokenId] = tokenIndex;

        delete _slotTokensIndex[slot_][tokenId_];
        slotData.slotTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC3525Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC3525ReceiverUpgradeable.sol";
import "./extensions/IERC721EnumerableUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "./extensions/IERC3525MetadataUpgradeable.sol";
import "./periphery/interface/IERC3525MetadataDescriptorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ERC3525Upgradeable is Initializable, ContextUpgradeable, IERC3525MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using StringsUpgradeable for address;
    using StringsUpgradeable for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event SetMetadataDescriptor(address indexed metadataDescriptor);

    struct TokenData {
        uint256 id;
        uint256 slot;
        uint256 balance;
        address owner;
        address approved;
        address[] valueApprovals;
    }

    struct AddressData {
        uint256[] ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(address => bool) approvals;
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    CountersUpgradeable.Counter private _tokenIdGenerator;

    // id => (approval => allowance)
    // @dev _approvedValues cannot be defined within TokenData, cause struct containing mappings cannot be constructed.
    mapping(uint256 => mapping(address => uint256)) private _approvedValues;

    TokenData[] private _allTokens;

    // key: id
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => AddressData) private _addressData;

    IERC3525MetadataDescriptorUpgradeable public metadataDescriptor;

    function __ERC3525_init(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        __ERC3525_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC3525_init_unchained(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
         _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165Upgradeable).interfaceId ||
            interfaceId == type(IERC3525Upgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC3525MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || 
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId;
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses for value.
     */
    function valueDecimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].balance;
    }

    function ownerOf(uint256 tokenId_) public view virtual override returns (address owner_) {
        _requireMinted(tokenId_);
        owner_ = _allTokens[_allTokensIndex[tokenId_]].owner;
        require(owner_ != address(0), "ERC3525: invalid token ID");
    }

    function slotOf(uint256 tokenId_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].slot;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function contractURI() public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructContractURI() :
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, "contract/", StringsUpgradeable.toHexString(address(this)))) : 
                    "";
    }

    function slotURI(uint256 slot_) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructSlotURI(slot_) : 
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, "slot/", slot_.toString())) : 
                    "";
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);
        string memory baseURI = _baseURI();
        return 
            address(metadataDescriptor) != address(0) ? 
                metadataDescriptor.constructTokenURI(tokenId_) : 
                bytes(baseURI).length > 0 ? 
                    string(abi.encodePacked(baseURI, tokenId_.toString())) : 
                    "";
    }

    function approve(uint256 tokenId_, address to_, uint256 value_) public payable virtual override {
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: approve caller is not owner nor approved");

        _approveValue(tokenId_, to_, value_);
    }

    function allowance(uint256 tokenId_, address operator_) public view virtual override returns (uint256) {
        _requireMinted(tokenId_);
        return _approvedValues[tokenId_][operator_];
    }

    function transferFrom(
        uint256 fromTokenId_,
        address to_,
        uint256 value_
    ) public payable virtual override returns (uint256 newTokenId) {
        _spendAllowance(_msgSender(), fromTokenId_, value_);

        newTokenId = _createDerivedTokenId(fromTokenId_);
        _mint(to_, newTokenId, ERC3525Upgradeable.slotOf(fromTokenId_), 0);
        _transferValue(fromTokenId_, newTokenId, value_);
    }

    function transferFrom(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) public payable virtual override {
        _spendAllowance(_msgSender(), fromTokenId_, value_);
        _transferValue(fromTokenId_, toTokenId_, value_);
    }

    function balanceOf(address owner_) public view virtual override returns (uint256 balance) {
        require(owner_ != address(0), "ERC3525: balance query for the zero address");
        return _addressData[owner_].ownedTokens.length;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _transferTokenId(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public payable virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC3525: transfer caller is not owner nor approved");
        _safeTransferTokenId(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public payable virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address to_, uint256 tokenId_) public payable virtual override {
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        require(to_ != owner, "ERC3525: approval to current owner");

        require(
            _msgSender() == owner || ERC3525Upgradeable.isApprovedForAll(owner, _msgSender()),
            "ERC3525: approve caller is not owner nor approved for all"
        );

        _approve(to_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view virtual override returns (address) {
        _requireMinted(tokenId_);
        return _allTokens[_allTokensIndex[tokenId_]].approved;
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual override {
        _setApprovalForAll(_msgSender(), operator_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view virtual override returns (bool) {
        return _addressData[owner_].approvals[operator_];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525Upgradeable.totalSupply(), "ERC3525: global index out of bounds");
        return _allTokens[index_].id;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_) public view virtual override returns (uint256) {
        require(index_ < ERC3525Upgradeable.balanceOf(owner_), "ERC3525: owner index out of bounds");
        return _addressData[owner_].ownedTokens[index_];
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        require(owner_ != operator_, "ERC3525: approve to caller");

        _addressData[owner_].approvals[operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function _isApprovedOrOwner(address operator_, uint256 tokenId_) internal view virtual returns (bool) {
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        return (
            operator_ == owner ||
            ERC3525Upgradeable.isApprovedForAll(owner, operator_) ||
            ERC3525Upgradeable.getApproved(tokenId_) == operator_
        );
    }

    function _spendAllowance(address operator_, uint256 tokenId_, uint256 value_) internal virtual {
        uint256 currentAllowance = ERC3525Upgradeable.allowance(tokenId_, operator_);
        if (!_isApprovedOrOwner(operator_, tokenId_) && currentAllowance != type(uint256).max) {
            require(currentAllowance >= value_, "ERC3525: insufficient allowance");
            _approveValue(tokenId_, operator_, currentAllowance - value_);
        }
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return _allTokens.length != 0 && _allTokens[_allTokensIndex[tokenId_]].id == tokenId_;
    }

    function _requireMinted(uint256 tokenId_) internal view virtual {
        require(_exists(tokenId_), "ERC3525: invalid token ID");
    }

    function _mint(address to_, uint256 slot_, uint256 value_) internal virtual returns (uint256 tokenId) {
        tokenId = _createOriginalTokenId();
        _mint(to_, tokenId, slot_, value_);  
    }

    function _mint(address to_, uint256 tokenId_, uint256 slot_, uint256 value_) internal virtual {
        require(to_ != address(0), "ERC3525: mint to the zero address");
        require(tokenId_ != 0, "ERC3525: cannot mint zero tokenId");
        require(!_exists(tokenId_), "ERC3525: token already minted");

        _beforeValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
        __mintToken(to_, tokenId_, slot_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), to_, 0, tokenId_, slot_, value_);
    }

    function _mintValue(uint256 tokenId_, uint256 value_) internal virtual {
        address owner = ERC3525Upgradeable.ownerOf(tokenId_);
        uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);
        _beforeValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
        __mintValue(tokenId_, value_);
        _afterValueTransfer(address(0), owner, 0, tokenId_, slot, value_);
    }

    function __mintValue(uint256 tokenId_, uint256 value_) private {
        _allTokens[_allTokensIndex[tokenId_]].balance += value_;
        emit TransferValue(0, tokenId_, value_);
    }

    function __mintToken(address to_, uint256 tokenId_, uint256 slot_) private {
        TokenData memory tokenData = TokenData({
            id: tokenId_,
            slot: slot_,
            balance: 0,
            owner: to_,
            approved: address(0),
            valueApprovals: new address[](0)
        });

        _addTokenToAllTokensEnumeration(tokenData);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(address(0), to_, tokenId_);
        emit SlotChanged(tokenId_, 0, slot_);
    }

    function _burn(uint256 tokenId_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, value);

        _clearApprovedValues(tokenId_);
        _removeTokenFromOwnerEnumeration(owner, tokenId_);
        _removeTokenFromAllTokensEnumeration(tokenId_);

        emit TransferValue(tokenId_, 0, value);
        emit SlotChanged(tokenId_, slot, 0);
        emit Transfer(owner, address(0), tokenId_);

        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, value);
    }

    function _burnValue(uint256 tokenId_, uint256 burnValue_) internal virtual {
        _requireMinted(tokenId_);

        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        address owner = tokenData.owner;
        uint256 slot = tokenData.slot;
        uint256 value = tokenData.balance;

        require(value >= burnValue_, "ERC3525: burn value exceeds balance");

        _beforeValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);
        
        tokenData.balance -= burnValue_;
        emit TransferValue(tokenId_, 0, burnValue_);
        
        _afterValueTransfer(owner, address(0), tokenId_, 0, slot, burnValue_);
    }

    function _addTokenToOwnerEnumeration(address to_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = to_;

        _addressData[to_].ownedTokensIndex[tokenId_] = _addressData[to_].ownedTokens.length;
        _addressData[to_].ownedTokens.push(tokenId_);
    }

    function _removeTokenFromOwnerEnumeration(address from_, uint256 tokenId_) private {
        _allTokens[_allTokensIndex[tokenId_]].owner = address(0);

        AddressData storage ownerData = _addressData[from_];
        uint256 lastTokenIndex = ownerData.ownedTokens.length - 1;
        uint256 lastTokenId = ownerData.ownedTokens[lastTokenIndex];
        uint256 tokenIndex = ownerData.ownedTokensIndex[tokenId_];

        ownerData.ownedTokens[tokenIndex] = lastTokenId;
        ownerData.ownedTokensIndex[lastTokenId] = tokenIndex;

        delete ownerData.ownedTokensIndex[tokenId_];
        ownerData.ownedTokens.pop();
    }

    function _addTokenToAllTokensEnumeration(TokenData memory tokenData_) private {
        _allTokensIndex[tokenData_.id] = _allTokens.length;
        _allTokens.push(tokenData_);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId_) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId_];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        TokenData memory lastTokenData = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenData; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenData.id] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId_];
        _allTokens.pop();
    }

    function _approve(address to_, uint256 tokenId_) internal virtual {
        _allTokens[_allTokensIndex[tokenId_]].approved = to_;
        emit Approval(ERC3525Upgradeable.ownerOf(tokenId_), to_, tokenId_);
    }

    function _approveValue(
        uint256 tokenId_,
        address to_,
        uint256 value_
    ) internal virtual {
        require(to_ != address(0), "ERC3525: approve value to the zero address");
        if (!_existApproveValue(to_, tokenId_)) {
            _allTokens[_allTokensIndex[tokenId_]].valueApprovals.push(to_);
        }
        _approvedValues[tokenId_][to_] = value_;

        emit ApprovalValue(tokenId_, to_, value_);
    }

    function _clearApprovedValues(uint256 tokenId_) internal virtual {
        TokenData storage tokenData = _allTokens[_allTokensIndex[tokenId_]];
        uint256 length = tokenData.valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            address approval = tokenData.valueApprovals[i];
            delete _approvedValues[tokenId_][approval];
        }
        delete tokenData.valueApprovals;
    }

    function _existApproveValue(address to_, uint256 tokenId_) internal view virtual returns (bool) {
        uint256 length = _allTokens[_allTokensIndex[tokenId_]].valueApprovals.length;
        for (uint256 i = 0; i < length; i++) {
            if (_allTokens[_allTokensIndex[tokenId_]].valueApprovals[i] == to_) {
                return true;
            }
        }
        return false;
    }

    function _transferValue(
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 value_
    ) internal virtual {
        require(_exists(fromTokenId_), "ERC3525: transfer from invalid token ID");
        require(_exists(toTokenId_), "ERC3525: transfer to invalid token ID");

        TokenData storage fromTokenData = _allTokens[_allTokensIndex[fromTokenId_]];
        TokenData storage toTokenData = _allTokens[_allTokensIndex[toTokenId_]];

        require(fromTokenData.balance >= value_, "ERC3525: insufficient balance for transfer");
        require(fromTokenData.slot == toTokenData.slot, "ERC3525: transfer to token with different slot");

        _beforeValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            value_
        );

        fromTokenData.balance -= value_;
        toTokenData.balance += value_;

        emit TransferValue(fromTokenId_, toTokenId_, value_);

        _afterValueTransfer(
            fromTokenData.owner,
            toTokenData.owner,
            fromTokenId_,
            toTokenId_,
            fromTokenData.slot,
            value_
        );

        require(
            _checkOnERC3525Received(fromTokenId_, toTokenId_, value_, ""),
            "ERC3525: transfer rejected by ERC3525Receiver"
        );
    }

    function _transferTokenId(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        require(ERC3525Upgradeable.ownerOf(tokenId_) == from_, "ERC3525: transfer from invalid owner");
        require(to_ != address(0), "ERC3525: transfer to the zero address");

        uint256 slot = ERC3525Upgradeable.slotOf(tokenId_);
        uint256 value = ERC3525Upgradeable.balanceOf(tokenId_);

        _beforeValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);

        _approve(address(0), tokenId_);
        _clearApprovedValues(tokenId_);

        _removeTokenFromOwnerEnumeration(from_, tokenId_);
        _addTokenToOwnerEnumeration(to_, tokenId_);

        emit Transfer(from_, to_, tokenId_);

        _afterValueTransfer(from_, to_, tokenId_, tokenId_, slot, value);
    }

    function _safeTransferTokenId(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _transferTokenId(from_, to_, tokenId_);
        require(
            _checkOnERC721Received(from_, to_, tokenId_, data_),
            "ERC3525: transfer to non ERC721Receiver"
        );
    }

    function _checkOnERC3525Received( 
        uint256 fromTokenId_, 
        uint256 toTokenId_, 
        uint256 value_, 
        bytes memory data_
    ) internal virtual returns (bool) {
        address to = ERC3525Upgradeable.ownerOf(toTokenId_);
        if (to.isContract()) {
            try IERC165Upgradeable(to).supportsInterface(type(IERC3525ReceiverUpgradeable).interfaceId) returns (bool retval) {
                if (retval) {
                    bytes4 receivedVal = IERC3525ReceiverUpgradeable(to).onERC3525Received(_msgSender(), fromTokenId_, toTokenId_, value_, data_);
                    return receivedVal == IERC3525ReceiverUpgradeable.onERC3525Received.selector;
                } else {
                    return true;
                }
            } catch (bytes memory /** reason */) {
                return true;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from_ address representing the previous owner of the given token ID
     * @param to_ target address that will receive the tokens
     * @param tokenId_ uint256 ID of the token to be transferred
     * @param data_ bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) private returns (bool) {
        if (to_.isContract()) {
            try 
                IERC721ReceiverUpgradeable(to_).onERC721Received(_msgSender(), from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /* solhint-disable */
    function _beforeValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}

    function _afterValueTransfer(
        address from_,
        address to_,
        uint256 fromTokenId_,
        uint256 toTokenId_,
        uint256 slot_,
        uint256 value_
    ) internal virtual {}
    /* solhint-enable */

    function _setMetadataDescriptor(address metadataDescriptor_) internal virtual {
        metadataDescriptor = IERC3525MetadataDescriptorUpgradeable(metadataDescriptor_);
        emit SetMetadataDescriptor(metadataDescriptor_);
    }

    function _createOriginalTokenId() internal virtual returns (uint256) {
         _tokenIdGenerator.increment();
        return _tokenIdGenerator.current();
    }

    function _createDerivedTokenId(uint256 fromTokenId_) internal virtual returns (uint256) {
        fromTokenId_;
        return _createOriginalTokenId();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC721.sol";

/**
 * @title ERC-3525 Semi-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xd5358140.
 */
interface IERC3525 is IERC165, IERC721 {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */ 
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals() external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */
    function balanceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 _tokenId,
        address _operator,
        uint256 _value
    ) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) external payable;

    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving ERC3525 tokens.
     * @dev This function MUST create a new ERC3525 token with the same slot for `_to` to receive
     *  the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

/**
 * @title EIP-3525 token receiver interface
 * @dev Interface for a smart contract that wants to be informed by EIP-3525 contracts when 
 *  receiving values from ANY addresses or EIP-3525 tokens.
 * Note: the EIP-165 identifier for this interface is 0x009ce20b.
 */
interface IERC3525ReceiverUpgradeable {
    /**
     * @notice Handle the receipt of an EIP-3525 token value.
     * @dev An EIP-3525 smart contract MUST check whether this function is implemented by the 
     *  recipient contract, if the recipient contract implements this function, the EIP-3525 
     *  contract MUST call this function after a value transfer (i.e. `transferFrom(uint256,
     *  uint256,uint256,bytes)`).
     *  MUST return 0x009ce20b (i.e. `bytes4(keccak256('onERC3525Received(address,uint256,uint256,
     *  uint256,bytes)'))`) if the transfer is accepted.
     *  MUST revert or return any value other than 0x009ce20b if the transfer is rejected.
     * @param _operator The address which triggered the transfer
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256('onERC3525Received(address,uint256,uint256,uint256,bytes)'))` 
     *  unless the transfer is rejected.
     */
    function onERC3525Received(address _operator, uint256 _fromTokenId, uint256 _toTokenId, uint256 _value, bytes calldata _data) external returns (bytes4);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "./IERC721Upgradeable.sol";

/**
 * @title ERC-3525 Semi-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xd5358140.
 */
interface IERC3525Upgradeable is IERC165Upgradeable, IERC721Upgradeable {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emits when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */ 
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with ERC20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals() external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */
    function balanceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value` amount.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 _tokenId,
        address _operator,
        uint256 _value
    ) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) external payable;

    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving ERC3525 tokens.
     * @dev This function MUST create a new ERC3525 token with the same slot for `_to` to receive
     *  the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the new token created for `_to` which receives the transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/** 
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721 is IERC165 {
    /** 
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external payable;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 *  Note: the ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721ReceiverUpgradeable {
    /** 
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a `transfer`. This function MAY throw to revert and reject the
     *  transfer. Return of other than the magic value MUST result in the
     *  transaction being reverted.
     *  Note: the contract address is always the message sender.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onERC721Received(
        address _operator, 
        address _from, 
        uint256 _tokenId, 
        bytes calldata _data
    ) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/** 
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /** 
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) external view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external payable;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) external view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "../IERC3525Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

/**
 * @title ERC-3525 Semi-Fungible Token Standard, optional extension for metadata
 * @dev Interfaces for any contract that wants to support query of the Uniform Resource Identifier
 *  (URI) for the ERC3525 contract as well as a specified slot.
 *  Because of the higher reliability of data stored in smart contracts compared to data stored in
 *  centralized systems, it is recommended that metadata, including `contractURI`, `slotURI` and
 *  `tokenURI`, be directly returned in JSON format, instead of being returned with a url pointing
 *  to any resource stored in a centralized system.
 *  See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0xe1600902.
 */
interface IERC3525MetadataUpgradeable is IERC3525Upgradeable, IERC721MetadataUpgradeable {
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the current ERC3525 contract.
     * @dev This function SHOULD return the URI for this contract in JSON format, starting with
     *  header `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for contract URI.
     * @return The JSON formatted URI of the current ERC3525 contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the specified slot.
     * @dev This function SHOULD return the URI for `_slot` in JSON format, starting with header
     *  `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for slot URI.
     * @return The JSON formatted URI of `_slot`
     */
    function slotURI(uint256 _slot) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "../IERC3525Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
/**
 * @title ERC-3525 Semi-Fungible Token Standard, optional extension for slot enumeration
 * @dev Interfaces for any contract that wants to support enumeration of slots as well as tokens 
 *  with the same slot.
 *  See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the ERC-165 identifier for this interface is 0x3b741b9e.
 */
interface IERC3525SlotEnumerableUpgradeable is IERC3525Upgradeable, IERC721EnumerableUpgradeable {

    /**
     * @notice Get the total amount of slots stored by the contract.
     * @return The total amount of slots
     */
    function slotCount() external view returns (uint256);

    /**
     * @notice Get the slot at the specified index of all slots stored by the contract.
     * @param _index The index in the slot list
     * @return The slot at `index` of all slots.
     */
    function slotByIndex(uint256 _index) external view returns (uint256);

    /**
     * @notice Get the total amount of tokens with the same slot.
     * @param _slot The slot to query token supply for
     * @return The total amount of tokens with the specified `_slot`
     */
    function tokenSupplyInSlot(uint256 _slot) external view returns (uint256);

    /**
     * @notice Get the token at the specified index of all tokens with the same slot.
     * @param _slot The slot to query tokens with
     * @param _index The index in the token list of the slot
     * @return The token ID at `_index` of all tokens with `_slot`
     */
    function tokenInSlotByIndex(uint256 _slot, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x780e9d63.
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /** 
     * @notice Count NFTs tracked by this contract
     * @return A count of valid NFTs tracked by this contract, where each one of
     *  them has an assigned and queryable owner not equal to the zero address
     */
    function totalSupply() external view returns (uint256);

    /** 
     * @notice Enumerate valid NFTs
     * @dev Throws if `_index` >= `totalSupply()`.
     * @param _index A counter less than `totalSupply()`
     * @return The token identifier for the `_index`th NFT,
     *  (sort order not specified)
     */
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /** 
     * @notice Enumerate NFTs assigned to an owner
     * @dev Throws if `_index` >= `balanceOf(_owner)` or if
     *  `_owner` is the zero address, representing invalid NFTs.
     * @param _owner An address where we are interested in NFTs owned by them
     * @param _index A counter less than `balanceOf(_owner)`
     * @return The token identifier for the `_index`th NFT assigned to `_owner`,
     *  (sort order not specified)
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() external view returns (string memory);

    /**
     * @notice An abbreviated name for NFTs in this contract
     */
    function symbol() external view returns (string memory);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC3525MetadataDescriptorUpgradeable {

    function constructContractURI() external view returns (string memory);

    function constructSlotURI(uint256 slot) external view returns (string memory);
    
    function constructTokenURI(uint256 tokenId) external view returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOpenFundMarketStorage.sol";

interface IOpenFundMarket is IOpenFundMarketStorage {

	event SetCurrency(address indexed currency, bool enabled);
	event AddSFT(address indexed sft, address manager);
	event RemoveSFT(address indexed sft);
	event SetProtocolFeeRate(uint256 oldFeeRate, uint256 newFeeRate);
	event SetProtocolFeeCollector(address oldFeeCollector, address newFeeCollector);

	event CreatePool(bytes32 indexed poolId, address indexed currency, address indexed sft, PoolInfo poolInfo_);
	event RemovePool(bytes32 indexed poolId);
	event UpdateFundraisingEndTime(bytes32 indexed poolId, uint64 oldEndTime, uint64 newEndTime);

	event Subscribe(bytes32 indexed poolId, address indexed buyer, uint256 tokenId, uint256 value, address currency, uint256 nav, uint256 payment);
	event RequestRedeem(bytes32 indexed poolId, address indexed owner, uint256 indexed openFundShareId, uint256 openFundRedemptionId, uint256 redeemValue);
	event RevokeRedeem(bytes32 indexed poolId, address indexed owner, uint256 indexed openFundRedemptionId, uint256 openFundShareId);

	event CloseRedeemSlot(bytes32 indexed poolId, uint256 previousRedeemSlot, uint256 newRedeemSlot);
	event SetSubscribeNav(bytes32 indexed poolId, uint256 indexed time, uint256 nav);
    event SetRedeemNav(bytes32 indexed poolId, uint256 indexed redeemSlot, uint256 nav);

	event SettleCarry(bytes32 indexed poolId, uint256 indexed redeemSlot, address currency, uint256 currencyBalance, uint256 carryAmount);
	event SettleProtocolFee(bytes32 indexed poolId, address currency, uint256 protocolFeeAmount);

    event UpdatePoolInfo(bytes32 indexed poolId, uint16 newCarryRate, address newCarryCollector, uint256 newSubscribeMin, uint256 newSubscribeMax, address newSubscribeNavManager, address newRedeemNavManager);

	struct InputPoolInfo {
		address openFundShare;
        address openFundRedemption;
		address currency;
		uint16 carryRate;
		address vault;
		uint64 valueDate;
		address carryCollector;
		address subscribeNavManager;
        address redeemNavManager;
		address navOracle;
		uint64 createTime;
		address[] whiteList;
		SubscribeLimitInfo subscribeLimitInfo;
	}

    function createPool(InputPoolInfo calldata inputPoolInfo_) external returns (bytes32 poolId_);
	
	function subscribe(bytes32 poolId_, uint256 currentAmount_, uint256 openFundShareId_, uint64 expireTime_) external returns (uint256 value_);

	function requestRedeem(bytes32 poolId_, uint256 openFundShareId_, uint256 openFundRedemptionId_, uint256 value_) external;
	function revokeRedeem(bytes32 poolId_, uint256 openFundRedemptionId_) external;

	function closeCurrentRedeemSlot(bytes32 poolId_) external;
    function setSubscribeNav(bytes32 poolId_, uint256 time_, uint256 nav_) external;
	function setRedeemNav(bytes32 poolId_, uint256 redeemSlot_, uint256 nav_, uint256 currencyBalance_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenFundMarketStorage {
    struct SFTInfo {
        address manager;
        bool isValid;
    }
    struct SubscribeLimitInfo {
        uint256 hardCap;
        uint256 subscribeMin;
        uint256 subscribeMax;
        uint64 fundraisingStartTime;
        uint64 fundraisingEndTime;
    }
    struct PoolSFTInfo {
        address openFundShare;
        address openFundRedemption;
        uint256 openFundShareSlot;
        uint256 latestRedeemSlot;
    }
    struct PoolFeeInfo {
        uint16 carryRate;
        address carryCollector;
        uint64 latestProtocolFeeSettleTime;
    }
    struct ManagerInfo {
        address poolManager;
        address subscribeNavManager;
        address redeemNavManager;
    }
    struct PoolInfo {
        PoolSFTInfo poolSFTInfo;
        PoolFeeInfo poolFeeInfo;
        ManagerInfo managerInfo;
        SubscribeLimitInfo subscribeLimitInfo;
        address vault;
        address currency;
        address navOracle;
        uint64 valueDate;
        bool permissionless;
        uint256 fundraisingAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OFMConstants {
	bytes32 internal constant CONTRACT_OFM = "OpenFundMarket";
    bytes32 internal constant CONTRACT_OFM_NAV_ORACLE = "OFMNavOracle";
	bytes32 internal constant CONTRACT_OFM_WHITELIST_STRATEGY_MANAGER = "OFMWhitelistStrategyManager";
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@solvprotocol/contracts-v3-address-resolver/contracts/ResolverCache.sol";
import "@solvprotocol/contracts-v3-sft-abilities/contracts/value-issuable/ISFTValueIssuableDelegate.sol";
import "@solvprotocol/erc-3525/IERC3525.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/helpers/ERC20TransferHelper.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/helpers/ERC3525TransferHelper.sol";
import "@solvprotocol/contracts-v3-sft-open-fund/contracts/open-fund-shares/OpenFundShareConcrete.sol";
import "@solvprotocol/contracts-v3-sft-open-fund/contracts/open-fund-shares/OpenFundShareDelegate.sol";
import "@solvprotocol/contracts-v3-sft-open-fund/contracts/open-fund-redemptions/IOpenFundRedemptionConcrete.sol";
import "@solvprotocol/contracts-v3-sft-open-fund/contracts/open-fund-redemptions/OpenFundRedemptionConcrete.sol";
import "@solvprotocol/contracts-v3-sft-open-fund/contracts/open-fund-redemptions/OpenFundRedemptionDelegate.sol";
import "@solvprotocol/contracts-v3-sft-earn/contracts/IEarnConcrete.sol";
import "./IOpenFundMarket.sol";
import "./OpenFundMarketStorage.sol";
import "./OFMConstants.sol";
import "./whitelist/IOFMWhitelistStrategyManager.sol";
import "./oracle/INavOracle.sol";

contract OpenFundMarket is IOpenFundMarket, OpenFundMarketStorage, ReentrancyGuardUpgradeable, ResolverCache {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }
    
    function initialize(address resolver_, address governor_) external initializer {
		__GovernorControl_init(governor_);
		__ReentrancyGuard_init();
		__ResolverCache_init(resolver_);
	}

    function createPool(InputPoolInfo calldata inputPoolInfo_) external virtual override nonReentrant returns (bytes32 poolId_) {
        _validateInputPoolInfo(inputPoolInfo_);

        IEarnConcrete.InputSlotInfo memory openFundInputSlotInfo = IEarnConcrete.InputSlotInfo({
            currency: inputPoolInfo_.currency,
            supervisor: inputPoolInfo_.redeemNavManager,
            issueQuota: type(uint256).max,
            interestType: IEarnConcrete.InterestType.FLOATING,
            interestRate: 0,
            valueDate: inputPoolInfo_.valueDate,
            maturity: inputPoolInfo_.subscribeLimitInfo.fundraisingEndTime,
            createTime: inputPoolInfo_.createTime,
            transferable: true,
            externalURI: ""
        });

        uint256 slot = ISFTValueIssuableDelegate(inputPoolInfo_.openFundShare).createSlotOnlyIssueMarket(_msgSender(), abi.encode(openFundInputSlotInfo));
        poolId_ = keccak256(abi.encode(inputPoolInfo_.openFundShare, slot));

        require(poolInfos[poolId_].poolSFTInfo.openFundShareSlot == 0, "OFM: pool already exists");

        PoolInfo memory poolInfo = PoolInfo({
            poolSFTInfo: PoolSFTInfo({
                openFundShare: inputPoolInfo_.openFundShare,
                openFundShareSlot: slot,
                openFundRedemption: inputPoolInfo_.openFundRedemption,
                latestRedeemSlot: 0
            }),
            poolFeeInfo: PoolFeeInfo({
                carryRate: inputPoolInfo_.carryRate,
                carryCollector: inputPoolInfo_.carryCollector,
                latestProtocolFeeSettleTime: inputPoolInfo_.valueDate
            }),
            managerInfo: ManagerInfo ({
                poolManager: _msgSender(),
                subscribeNavManager: inputPoolInfo_.subscribeNavManager,
                redeemNavManager: inputPoolInfo_.redeemNavManager
            }),
            subscribeLimitInfo: inputPoolInfo_.subscribeLimitInfo,
            vault: inputPoolInfo_.vault,
            currency: inputPoolInfo_.currency,
            navOracle: inputPoolInfo_.navOracle,
            valueDate: inputPoolInfo_.valueDate,
            permissionless: inputPoolInfo_.whiteList.length == 0,
            fundraisingAmount: 0
        });

        poolInfos[poolId_] = poolInfo;

        uint256 initialNav = 10 ** ERC20(inputPoolInfo_.currency).decimals();
        INavOracle(inputPoolInfo_.navOracle).setSubscribeNavOnlyMarket(poolId_, block.timestamp, initialNav);
        INavOracle(inputPoolInfo_.navOracle).updateAllTimeHighRedeemNavOnlyMarket(poolId_, initialNav);

        _whitelistStrategyManager().setWhitelist(poolId_, inputPoolInfo_.whiteList);

        emit CreatePool(poolId_, poolInfo.currency, poolInfo.poolSFTInfo.openFundShare, poolInfo);
    }

    function subscribe(bytes32 poolId_, uint256 currencyAmount_, uint256 openFundShareId_, uint64 expireTime_) 
        external virtual override nonReentrant returns (uint256 value_) 
    {
        require(expireTime_ > block.timestamp, "OFM: expired");

        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(poolInfo.permissionless || _whitelistStrategyManager().isWhitelisted(poolId_, _msgSender()), "OFM: not in whitelist");
        require(poolInfo.subscribeLimitInfo.fundraisingStartTime <= block.timestamp, "OFM: fundraising not started");
        require(poolInfo.subscribeLimitInfo.fundraisingEndTime >= block.timestamp, "OFM: fundraising ended");

        uint256 nav;
        if (block.timestamp < poolInfo.valueDate) {
            nav = 10 ** ERC20(poolInfo.currency).decimals();
            // only for first subscribe period
            poolInfo.fundraisingAmount += currencyAmount_;
            require(poolInfo.fundraisingAmount <= poolInfo.subscribeLimitInfo.hardCap, "OFM: hard cap reached");
        } else {
            (nav, ) = INavOracle(poolInfo.navOracle).getSubscribeNav(poolId_, block.timestamp);
        }

        value_ = (currencyAmount_ * ( 10 ** IERC3525(poolInfo.poolSFTInfo.openFundShare).valueDecimals())) / nav;
        require(value_ > 0, "OFM: value cannot be 0");

        uint256 purchasedAmount = purchasedRecords[poolId_][_msgSender()] + currencyAmount_;
		require(purchasedAmount <= poolInfo.subscribeLimitInfo.subscribeMax, "OFM: exceed subscribe max limit");
        require(currencyAmount_ >= poolInfo.subscribeLimitInfo.subscribeMin, "OFM: less than subscribe min limit");
		purchasedRecords[poolId_][_msgSender()] = purchasedAmount;

        uint256 tokenId;
        if (openFundShareId_ == 0) {
            tokenId = ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundShare)
                .mintOnlyIssueMarket(_msgSender(), poolInfo.currency, _msgSender(), poolInfo.poolSFTInfo.openFundShareSlot, value_);
        } else {
            require(IERC3525(poolInfo.poolSFTInfo.openFundShare).slotOf(openFundShareId_) == poolInfo.poolSFTInfo.openFundShareSlot, "OFM: slot not match");
            ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundShare).mintValueOnlyIssueMarket(
                _msgSender(), poolInfo.currency, openFundShareId_, value_
            );
            tokenId = openFundShareId_;
        }
		ERC20TransferHelper.doTransferIn(poolInfo.currency, _msgSender(), currencyAmount_);
        ERC20TransferHelper.doTransferOut(poolInfo.currency, payable(poolInfo.vault), currencyAmount_);

        emit Subscribe(poolId_, _msgSender(), tokenId, value_, poolInfo.currency, nav, currencyAmount_);
    }

    function requestRedeem(bytes32 poolId_, uint256 openFundShareId_, uint256 openFundRedemptionId_, uint256 redeemValue_) external virtual override nonReentrant  {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(block.timestamp > poolInfo.valueDate, "OFM: not yet redeemable");

        //only do it once per pool when the first redeem request comes in
        if (poolInfo.poolSFTInfo.latestRedeemSlot == 0) {
            IOpenFundRedemptionConcrete.RedeemInfo memory redeemInfo = IOpenFundRedemptionConcrete.RedeemInfo({
                poolId: poolId_,
                currency: poolInfo.currency,
                createTime: block.timestamp,
                nav: 0
            });
            poolInfo.poolSFTInfo.latestRedeemSlot = ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundRedemption).createSlotOnlyIssueMarket(_msgSender(), abi.encode(redeemInfo));
            _poolRedeemTokenId[poolInfo.poolSFTInfo.latestRedeemSlot] = ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundShare)
                    .mintOnlyIssueMarket(_msgSender(), poolInfo.currency, address(this), poolInfo.poolSFTInfo.openFundShareSlot, 0);
        }

        require(poolInfo.poolSFTInfo.openFundShareSlot == IERC3525(poolInfo.poolSFTInfo.openFundShare).slotOf(openFundShareId_), "OFM: invalid OpenFundShare slot");

        if (redeemValue_ == IERC3525(poolInfo.poolSFTInfo.openFundShare).balanceOf(openFundShareId_)) {
            ERC3525TransferHelper.doTransferIn(poolInfo.poolSFTInfo.openFundShare, _msgSender(), openFundShareId_);
            IERC3525(poolInfo.poolSFTInfo.openFundShare).transferFrom(openFundShareId_, _poolRedeemTokenId[poolInfo.poolSFTInfo.latestRedeemSlot], redeemValue_);
            ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundShare).burnOnlyIssueMarket(openFundShareId_, 0);
        } else {
            ERC3525TransferHelper.doTransfer(poolInfo.poolSFTInfo.openFundShare, openFundShareId_, _poolRedeemTokenId[poolInfo.poolSFTInfo.latestRedeemSlot], redeemValue_);
        }

        if (openFundRedemptionId_ == 0) {
            openFundRedemptionId_ = ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundRedemption).mintOnlyIssueMarket(_msgSender(), poolInfo.currency, _msgSender(), poolInfo.poolSFTInfo.latestRedeemSlot, redeemValue_);
        } else {
            require(poolInfo.poolSFTInfo.latestRedeemSlot == IERC3525(poolInfo.poolSFTInfo.openFundRedemption).slotOf(openFundRedemptionId_), "OFM: invalid OpenFundRedemption slot");
            ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundRedemption).mintValueOnlyIssueMarket(_msgSender(), poolInfo.currency, openFundRedemptionId_, redeemValue_);
        }

        emit RequestRedeem(poolId_, _msgSender(), openFundShareId_, openFundRedemptionId_, redeemValue_);
    }

    function revokeRedeem(bytes32 poolId_, uint256 openFundRedemptionId_) external virtual override nonReentrant {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");

        uint256 slot = IERC3525(poolInfo.poolSFTInfo.openFundRedemption).slotOf(openFundRedemptionId_);
        require(poolRedeemSlotCloseTime[slot] == 0, "OFM: slot already closed");

        uint256 value = IERC3525(poolInfo.poolSFTInfo.openFundRedemption).balanceOf(openFundRedemptionId_);
        ERC3525TransferHelper.doTransferIn(poolInfo.poolSFTInfo.openFundRedemption, _msgSender(), openFundRedemptionId_);
        OpenFundRedemptionDelegate(poolInfo.poolSFTInfo.openFundRedemption).burnOnlyIssueMarket(openFundRedemptionId_, 0);
        uint256 shareId = ERC3525TransferHelper.doTransferOut(poolInfo.poolSFTInfo.openFundShare, _poolRedeemTokenId[slot], _msgSender(), value);
        emit RevokeRedeem(poolId_, _msgSender(), openFundRedemptionId_, shareId);
    }

    function closeCurrentRedeemSlot(bytes32 poolId_) external virtual override nonReentrant {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(_msgSender() == poolInfo.managerInfo.poolManager, "OFM: only pool manager");
        require(poolInfo.poolSFTInfo.latestRedeemSlot != 0, "OFM: no redeem requests");

        uint256 poolPreviousRedeemSlot = previousRedeemSlot[poolId_];
        if (poolPreviousRedeemSlot > 0) {
            require(block.timestamp - poolRedeemSlotCloseTime[poolPreviousRedeemSlot] >= 24 * 60 * 60, "OFM: redeem period less than 24h");

            OpenFundRedemptionConcrete redemptionConcrete = OpenFundRedemptionConcrete(OpenFundRedemptionDelegate(poolInfo.poolSFTInfo.openFundRedemption).concrete());
            uint256 previousRedeemNav = redemptionConcrete.getRedeemNav(poolPreviousRedeemSlot);
            require(previousRedeemNav > 0, "OFM: previous redeem nav not set");

            uint256 previousSlotTotalValue = redemptionConcrete.slotTotalValue(poolPreviousRedeemSlot);
            uint256 previousSlotCurrencyBalance = redemptionConcrete.slotCurrencyBalance(poolPreviousRedeemSlot);
            uint8 redemptionValueDecimals = OpenFundRedemptionDelegate(poolInfo.poolSFTInfo.openFundRedemption).valueDecimals();
            require(previousSlotCurrencyBalance >= previousSlotTotalValue * previousRedeemNav / (10 ** redemptionValueDecimals), "OFM: previous redeem slot not fully repaid");
        }
        
        IOpenFundRedemptionConcrete.RedeemInfo memory nextRedeemInfo = IOpenFundRedemptionConcrete.RedeemInfo({
            poolId: poolId_,
            currency: poolInfo.currency,
            createTime: block.timestamp,
            nav: 0
        });

        uint256 closingRedeemSlot = poolInfo.poolSFTInfo.latestRedeemSlot;
        poolRedeemSlotCloseTime[closingRedeemSlot] = block.timestamp;
        previousRedeemSlot[poolId_] = closingRedeemSlot;

        poolInfo.poolSFTInfo.latestRedeemSlot = ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundRedemption).createSlotOnlyIssueMarket(_msgSender(), abi.encode(nextRedeemInfo));
        _poolRedeemTokenId[poolInfo.poolSFTInfo.latestRedeemSlot] = ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundShare)
                    .mintOnlyIssueMarket(_msgSender(), poolInfo.currency, address(this), poolInfo.poolSFTInfo.openFundShareSlot, 0);
        emit CloseRedeemSlot(poolId_, closingRedeemSlot, poolInfo.poolSFTInfo.latestRedeemSlot);
    }

    function setSubscribeNav(bytes32 poolId_, uint256 time_, uint256 nav_) external virtual override {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(_msgSender() == poolInfo.managerInfo.subscribeNavManager, "OFM: only subscribe nav manager");
        INavOracle(poolInfo.navOracle).setSubscribeNavOnlyMarket(poolId_, time_, nav_);
        emit SetSubscribeNav(poolId_, time_, nav_);
    }

    function setRedeemNav(bytes32 poolId_, uint256 redeemSlot_, uint256 nav_, uint256 currencyBalance_) external virtual override nonReentrant {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(poolRedeemSlotCloseTime[redeemSlot_] > 0, "OFM: redeem slot not closed");
        require(_msgSender() == poolInfo.managerInfo.redeemNavManager, "OFM: only redeem nav manager");

        uint256 allTimeHighRedeemNav = INavOracle(poolInfo.navOracle).getAllTimeHighRedeemNav(poolId_);
        uint256 carryAmount = nav_ > allTimeHighRedeemNav ? 
                (nav_ - allTimeHighRedeemNav) * poolInfo.poolFeeInfo.carryRate * currencyBalance_ / nav_ / 10000 : 0;

        uint256 protocolFeeAmount = currencyBalance_ * protocolFeeRate * 
                (block.timestamp - poolInfo.poolFeeInfo.latestProtocolFeeSettleTime) / 10000 / (360 * 24 * 60 * 60);

        uint256 settledNav = nav_ * (currencyBalance_ - carryAmount - protocolFeeAmount) / currencyBalance_;

        uint256 mintCarryValue = carryAmount * (10 ** IERC3525(poolInfo.poolSFTInfo.openFundShare).valueDecimals()) / settledNav;
        if (mintCarryValue > 0) {
            ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundShare).mintOnlyIssueMarket(
                _msgSender(), poolInfo.currency, poolInfo.poolFeeInfo.carryCollector, poolInfo.poolSFTInfo.openFundShareSlot, mintCarryValue
            );
        }
        emit SettleCarry(poolId_, redeemSlot_, poolInfo.currency, currencyBalance_, carryAmount);

        _mintProtocolFeeShares(poolId_, protocolFeeAmount, settledNav, 0);

        ISFTValueIssuableDelegate(poolInfo.poolSFTInfo.openFundShare).burnOnlyIssueMarket(_poolRedeemTokenId[redeemSlot_], 0);
        OpenFundRedemptionDelegate(poolInfo.poolSFTInfo.openFundRedemption).setRedeemNavOnlyMarket(redeemSlot_, settledNav);
        INavOracle(poolInfo.navOracle).setSubscribeNavOnlyMarket(poolId_, block.timestamp, settledNav);
        INavOracle(poolInfo.navOracle).updateAllTimeHighRedeemNavOnlyMarket(poolId_, nav_);

        emit SetSubscribeNav(poolId_, block.timestamp, settledNav);
        emit SetRedeemNav(poolId_, redeemSlot_, settledNav);
    }

    function settleProtocolFee(bytes32 poolId_, uint256 feeToTokenId_) external virtual nonReentrant {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        (uint256 nav, ) = INavOracle(poolInfo.navOracle).getSubscribeNav(poolId_, block.timestamp);

        uint256 totalShares = 
                OpenFundShareConcrete(OpenFundShareDelegate(poolInfo.poolSFTInfo.openFundShare).concrete()).
                slotTotalValue(poolInfo.poolSFTInfo.openFundShareSlot);

        uint256 protocolFeeAmount = 
                totalShares * nav * protocolFeeRate * (block.timestamp - poolInfo.poolFeeInfo.latestProtocolFeeSettleTime) / 
                10000 / (360 * 24 * 60 * 60) / (10 ** IERC3525(poolInfo.poolSFTInfo.openFundShare).valueDecimals());

        uint256 settledNav = nav - protocolFeeAmount * (10 ** IERC3525(poolInfo.poolSFTInfo.openFundShare).valueDecimals()) / totalShares;
        
        _mintProtocolFeeShares(poolId_, protocolFeeAmount, settledNav, feeToTokenId_);

        INavOracle(poolInfo.navOracle).setSubscribeNavOnlyMarket(poolId_, block.timestamp, settledNav);
        emit SetSubscribeNav(poolId_, block.timestamp, settledNav);
    }

    function _mintProtocolFeeShares(bytes32 poolId_, uint256 protocolFeeAmount_, uint256 settledNav_, uint256 feeToTokenId_) internal virtual {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        OpenFundShareDelegate openFundShare = OpenFundShareDelegate(poolInfo.poolSFTInfo.openFundShare);
        uint256 mintFeeValue = protocolFeeAmount_ * (10 ** openFundShare.valueDecimals()) / settledNav_;

        if (mintFeeValue > 0) {
            if (feeToTokenId_ == 0) {
                openFundShare.mintOnlyIssueMarket(
                    _msgSender(), poolInfo.currency, protocolFeeCollector, poolInfo.poolSFTInfo.openFundShareSlot, mintFeeValue
                );
            } else {
                require(openFundShare.slotOf(feeToTokenId_) == poolInfo.poolSFTInfo.openFundShareSlot, "OFM: slot not match");
                require(openFundShare.ownerOf(feeToTokenId_) == protocolFeeCollector, "OFM: owner not match");
                openFundShare.mintValueOnlyIssueMarket(
                    _msgSender(), poolInfo.currency, feeToTokenId_, mintFeeValue
                );
            }
        }

        poolInfo.poolFeeInfo.latestProtocolFeeSettleTime = uint64(block.timestamp);
        emit SettleProtocolFee(poolId_, poolInfo.currency, protocolFeeAmount_);
    }

    function removePool(bytes32 poolId_) external virtual nonReentrant {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(_msgSender() == poolInfo.managerInfo.poolManager, "OFM: only pool manager");
        require(poolInfo.fundraisingAmount == 0, "OFM: already subscribed");

        delete poolInfos[poolId_];
        emit RemovePool(poolId_);
    }

    function updateFundraisingEndTime(bytes32 poolId_, uint64 newEndTime_) external virtual nonReentrant {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(_msgSender() == governor || _msgSender() == poolInfo.managerInfo.redeemNavManager, "OFM: only governor or redeem nav manager");
        emit UpdateFundraisingEndTime(poolId_, poolInfo.subscribeLimitInfo.fundraisingEndTime, newEndTime_);
        poolInfo.subscribeLimitInfo.fundraisingEndTime = newEndTime_;
    }


    function updatePoolInfoOnlyGovernor(
        bytes32 poolId_, uint16 carryRate_, address carryCollector_, 
        uint256 subscribeMin_, uint256 subscribeMax_, 
        address subscribeNavManager_, address redeemNavManager_
    ) external virtual onlyGovernor {
        PoolInfo storage poolInfo = poolInfos[poolId_];

        require(
            poolInfo.poolSFTInfo.openFundShareSlot != 0 && 
            carryRate_ <= 10000 && carryCollector_ != address(0) && 
            subscribeMin_ <= subscribeMax_ && 
            subscribeNavManager_ != address(0) && redeemNavManager_ != address(0), 
            "OFM: invalid input"
        );

        poolInfo.poolFeeInfo.carryRate = carryRate_;
        poolInfo.poolFeeInfo.carryCollector = carryCollector_;
        poolInfo.subscribeLimitInfo.subscribeMin = subscribeMin_;
        poolInfo.subscribeLimitInfo.subscribeMax = subscribeMax_;
        poolInfo.managerInfo.subscribeNavManager = subscribeNavManager_;
        poolInfo.managerInfo.redeemNavManager = redeemNavManager_;

        emit UpdatePoolInfo(poolId_, carryRate_, carryCollector_, subscribeMin_, subscribeMax_, subscribeNavManager_, redeemNavManager_);
    }


	function _whitelistStrategyManager() internal view returns (IOFMWhitelistStrategyManager) {
		return IOFMWhitelistStrategyManager(
            getRequiredAddress(
                OFMConstants.CONTRACT_OFM_WHITELIST_STRATEGY_MANAGER, 
                "OFM: WhitelistStrategyManager address not found"
            )
        );
	}

    function setWhitelist(bytes32 poolId_, address[] calldata whitelist_) external virtual {
        PoolInfo storage poolInfo = poolInfos[poolId_];
        require(poolInfo.poolSFTInfo.openFundShareSlot != 0, "OFM: pool does not exist");
        require(_msgSender() == poolInfo.managerInfo.poolManager, "OFM: only manager");
        poolInfo.permissionless = whitelist_.length == 0;
		_whitelistStrategyManager().setWhitelist(poolId_, whitelist_);
	}

    function setCurrencyOnlyGovernor(address currency_, bool enabled_) external virtual onlyGovernor {
        require(currency_ != address(0), "OFM: invalid currency");
		currencies[currency_] = enabled_;
		emit SetCurrency(currency_, enabled_);
	}

    function addSFTOnlyGovernor(address sft_, address manager_) external virtual onlyGovernor {
        require(sft_ != address(0), "OFM: invalid sft");
		sftInfos[sft_] = SFTInfo({
            manager: manager_,
            isValid: true
        });
		emit AddSFT(sft_, manager_);
	}

    function removeSFTOnlyGovernor(address sft_) external virtual onlyGovernor {
        delete sftInfos[sft_];
        emit RemoveSFT(sft_);
    }

    function setProtocolFeeOnlyGovernor(uint256 newFeeRate_, address newFeeCollector_) external virtual onlyGovernor {
        require(newFeeRate_ <= 10000 && newFeeCollector_ != address(0), "OFM: invalid input");
        protocolFeeRate = newFeeRate_;
        protocolFeeCollector = newFeeCollector_;
        emit SetProtocolFeeRate(protocolFeeRate, newFeeRate_);
        emit SetProtocolFeeCollector(protocolFeeCollector, newFeeCollector_);
    }

    function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory requiredAddresses) {
		requiredAddresses = new bytes32[](2);
		requiredAddresses[0] = OFMConstants.CONTRACT_OFM_WHITELIST_STRATEGY_MANAGER;
		requiredAddresses[1] = OFMConstants.CONTRACT_OFM_NAV_ORACLE;
	}

    function _validateInputPoolInfo(InputPoolInfo calldata inputPoolInfo_) internal view virtual {
        require(currencies[inputPoolInfo_.currency], "OFM: invalid currency");
        SFTInfo storage openFundShareInfo = sftInfos[inputPoolInfo_.openFundShare];
        require(openFundShareInfo.isValid, "OFM: invalid share");
        require(openFundShareInfo.manager == address(0) || _msgSender() == openFundShareInfo.manager, "OFM: invalid share manager");

        SFTInfo storage openFundRedemptionInfo = sftInfos[inputPoolInfo_.openFundRedemption];
        require(openFundRedemptionInfo.isValid, "OFM: invalid redemption");
        require(openFundRedemptionInfo.manager == address(0) || _msgSender() == openFundRedemptionInfo.manager, "OFM: invalid redemption manager");

        require(
            IERC3525(inputPoolInfo_.openFundShare).valueDecimals() == IERC3525(inputPoolInfo_.openFundRedemption).valueDecimals(), 
            "OFM: decimals not match"
        );
        
        require(inputPoolInfo_.subscribeLimitInfo.subscribeMin <= inputPoolInfo_.subscribeLimitInfo.subscribeMax, "OFM: invalid min and max");
        require(inputPoolInfo_.subscribeLimitInfo.fundraisingStartTime <= inputPoolInfo_.valueDate, "OFM: invalid valueDate");
        require(inputPoolInfo_.subscribeLimitInfo.fundraisingStartTime <= inputPoolInfo_.subscribeLimitInfo.fundraisingEndTime, "OFM: invalid startTime and endTime");
        require(inputPoolInfo_.subscribeLimitInfo.fundraisingEndTime > block.timestamp, "OFM: invalid endTime");

        require(inputPoolInfo_.vault != address(0), "OFM: invalid vault");
        require(inputPoolInfo_.carryCollector != address(0), "OFM: invalid carryCollector");
        require(inputPoolInfo_.subscribeNavManager != address(0), "OFM: invalid subscribeNavManager");
        require(inputPoolInfo_.redeemNavManager != address(0), "OFM: invalid redeemNavManager");
        require(inputPoolInfo_.carryRate <= 10000, "OFM: invalid carryRate");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@solvprotocol/contracts-v3-solidity-utils/contracts/access/GovernorControl.sol";
import "./IOpenFundMarketStorage.sol";

contract OpenFundMarketStorage is IOpenFundMarketStorage, GovernorControl {
	// keccak256(openFundSFT, openFundSlot)
	mapping(bytes32 => PoolInfo) public poolInfos;

	// keccak256(openFundSFT, openFundSlot) => buyer => purchased amount
	mapping(bytes32 => mapping(address => uint256)) public purchasedRecords;

	// redeemSlot => close time
	mapping(uint256 => uint256) public poolRedeemSlotCloseTime;

	// redeemSlot => openFundTokenId
	mapping(uint256 => uint256) internal _poolRedeemTokenId;

	mapping(address => bool) public currencies;

	mapping(address => SFTInfo) public sftInfos;

	uint256 public protocolFeeRate;
	address public protocolFeeCollector;

	mapping(bytes32 => uint256) public previousRedeemSlot;

	uint256[42] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INavOracle {
	event SetSubscribeNav(bytes32 indexed poolId, uint256 indexed time, uint256 nav);
	event UpdateAllTimeHighRedeemNav(bytes32 indexed poolId, uint256 oldNav, uint256 newNav);

	function setSubscribeNavOnlyMarket(bytes32 poolId_, uint256 time_, uint256 nav_) external;
	function updateAllTimeHighRedeemNavOnlyMarket(bytes32 poolId_, uint256 nav_)  external;
	function getSubscribeNav(bytes32 poolId_, uint256 time_) external view returns (uint256 nav_, uint256 navTime_);
	function getAllTimeHighRedeemNav(bytes32 poolId_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOFMWhitelistStrategyManager {
	function setWhitelist(bytes32 poolId_, address[] calldata whitelist_) external;
	function isWhitelisted(bytes32 poolId_, address buyer_) external view returns (bool);
	function getPoolWhitelistIds(bytes32 poolId_) external view returns (bytes32[] memory);
}