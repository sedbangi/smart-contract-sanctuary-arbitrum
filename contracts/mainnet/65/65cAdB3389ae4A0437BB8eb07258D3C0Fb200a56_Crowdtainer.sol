// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// -----------------------------------------------
//  Safety margins to avoid impractical values
// -----------------------------------------------
// @notice Safety time buffer to avoid expiration time too close to the opening time.
uint256 constant SAFETY_TIME_RANGE = 10 minutes;
// @notice Maximum value for referral discounts and rewards
uint256 constant SAFETY_MAX_REFERRAL_RATE = 50;
// @notice Maximum number of items per type on each purchase/join.
uint256 constant MAX_NUMBER_OF_PURCHASED_ITEMS = 200;
// @notice Maximum time the service provider has to react after campaigm reaches target, 
// otherwise the campaign can be still put into failed state, in case of unresponsive service providers.
uint256 constant MAX_UNRESPONSIVE_TIME = 30 days;

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// @dev External dependencies
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// @dev Internal dependencies
import "./ICrowdtainer.sol";
import "./Errors.sol";
import "./Constants.sol";

interface AuthorizationGateway {
    function getSignedJoinApproval(
        address crowdtainerAddress,
        address addr,
        uint256[] calldata quantities,
        bool _enableReferral,
        address _referrer
    ) external view returns (bytes memory signature);
}

/**
 * @title Crowdtainer contract
 * @author Crowdtainer.eth
 */
contract Crowdtainer is ICrowdtainer, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // -----------------------------------------------
    //  Main project state
    // -----------------------------------------------
    CrowdtainerState public crowdtainerState;

    /// @notice Owner of this contract.
    /// @dev Has permissions to call: initialize(), join() and leave() functions. These functions are optionally
    /// @dev gated so that an owner contract can do special accounting (such as an EIP721-compliant contract as its owner).
    address public owner;

    /// @notice The entity or person responsible for the delivery of this crowdtainer project.
    /// @dev Allowed to call getPaidAndDeliver(), abortProject() and set signer address.
    address public shippingAgent;

    /// @notice Maps wallets that joined this Crowdtainer to the values they paid to join.
    mapping(address => uint256) public costForWallet;

    /// @notice Maps accounts to accumulated referral rewards.
    mapping(address => uint256) public accumulatedRewardsOf;

    /// @notice Total rewards claimable for project.
    uint256 public accumulatedRewards;

    /// @notice Maps referee to referrer.
    mapping(address => address) public referrerOfReferee;

    uint256 public referralEligibilityValue;

    /// @notice Wether an account has opted into being elibible for referral rewards.
    mapping(address => bool) public enableReferral;

    /// @notice Maps the total discount for each user.
    mapping(address => uint256) public discountForUser;

    /// @notice The total value raised/accumulated by this contract.
    uint256 public totalValueRaised;

    /// @notice Address owned by shipping agent to sign authorization transactions.
    address private signer;

    /// @notice Mapping of addresses to random nonces; Used for transaction replay protection.
    mapping(address => mapping(bytes32 => bool)) public usedNonces;

    /// @notice URL templates to the service provider's gateways that implement the CCIP-read protocol.
    string[] public urls;

    uint256 internal oneUnit; // Smallest unit based on erc20 decimals.

    // -----------------------------------------------
    //  Modifiers
    // -----------------------------------------------
    /**
     * @dev If the Crowdtainer contract has an "owner" contract (such as Vouchers721.sol), this modifier will
     * enforce that only the owner can call this function. If no owner is assigned (is address(0)), then the
     * restriction is not applied, in which case msg.sender checks are performed by the owner.
     */
    modifier onlyOwner() {
        if (owner == address(0)) {
            // This branch means this contract is being used as a stand-alone contract, not managed/owned by a EIP-721/1155 contract
            // E.g.: A Crowdtainer instance interacted directly by an EOA.
            _;
            return;
        }
        requireMsgSender(owner);
        _;
    }

    /**
     * @dev Throws if called in state other than the specified.
     */
    modifier onlyInState(CrowdtainerState requiredState) {
        requireState(requiredState);
        _;
    }

    modifier onlyActive() {
        requireActive();
        _;
    }

    // Auxiliary modifier functions, used to save deployment cost.
    function requireState(CrowdtainerState requiredState) internal view {
        if (crowdtainerState != requiredState)
            revert Errors.InvalidOperationFor({state: crowdtainerState});
        require(crowdtainerState == requiredState);
    }

    function requireMsgSender(address requiredAddress) internal view {
        if (msg.sender != requiredAddress)
            revert Errors.CallerNotAllowed({
                expected: requiredAddress,
                actual: msg.sender
            });
        require(msg.sender == requiredAddress);
    }

    function requireActive() internal view {
        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );
        if (block.timestamp > expireTime)
            revert Errors.CrowdtainerExpired(block.timestamp, expireTime);
    }

    /// @notice Address used for signing authorizations. This allows for arbitrary
    /// off-chain mechanisms to apply law-based restrictions and/or combat bots squatting offered items.
    /// @notice If signer equals to address(0), no restriction is applied.
    function getSigner() external view returns (address) {
        return signer;
    }

    function setSigner(address _signer) external {
        requireMsgSender(shippingAgent);
        signer = _signer;
        emit SignerChanged(signer);
    }

    function setUrls(string[] memory _urls) external {
        requireMsgSender(shippingAgent);
        urls = _urls;
        emit CCIPURLChanged(urls);
    }

    // -----------------------------------------------
    //  Values set by initialize function
    // -----------------------------------------------
    /// @notice Time after which it is possible to join this Crowdtainer.
    uint256 public openingTime;
    /// @notice Time after which it is no longer possible for the service or product provider to withdraw funds.
    uint256 public expireTime;
    /// @notice Minimum amount in ERC20 units required for Crowdtainer to be considered to be successful.
    uint256 public targetMinimum;
    /// @notice Amount in ERC20 units after which no further participation is possible.
    uint256 public targetMaximum;
    /// @notice The price for each unit type.
    /// @dev The price should be given in the number of smallest unit for precision (e.g 10^18 == 1 DAI).
    uint256[] public unitPricePerType;
    /// @notice Half of the value act as a discount for a new participant using an existing referral code, and the other
    /// half is given for the participant making a referral. The former is similar to the 'cash discount device' in stamp era,
    /// while the latter is a reward for contributing to the Crowdtainer by incentivising participation from others.
    uint256 public referralRate;
    /// @notice Address of the ERC20 token used for payment.
    IERC20 public token;
    /// @notice URI string pointing to the legal terms and conditions ruling this project.
    string public legalContractURI;

    // -----------------------------------------------
    //  Events
    // -----------------------------------------------

    /// @notice Emmited when the signer changes.
    event SignerChanged(address indexed newSigner);

    /// @notice Emmited when CCIP-read URLs changes.
    event CCIPURLChanged(string[] indexed newUrls);

    /// @notice Emmited when a Crowdtainer is created.
    event CrowdtainerCreated(
        address indexed owner,
        address indexed shippingAgent
    );

    /// @notice Emmited when a Crowdtainer is initialized.
    event CrowdtainerInitialized(
        address indexed _owner,
        IERC20 _token,
        uint256 _openingTime,
        uint256 _expireTime,
        uint256 _targetMinimum,
        uint256 _targetMaximum,
        uint256[] _unitPricePerType,
        uint256 _referralRate,
        uint256 _referralEligibilityValue,
        string _legalContractURI,
        address _signer
    );

    /// @notice Emmited when a user joins, signalling participation intent.
    event Joined(
        address indexed wallet,
        uint256[] quantities,
        address indexed referrer,
        uint256 finalCost, // @dev with discount applied
        uint256 appliedDiscount,
        bool referralEnabled
    );

    event Left(address indexed wallet, uint256 withdrawnAmount);

    event RewardsClaimed(address indexed wallet, uint256 withdrawnAmount);

    event FundsClaimed(address indexed wallet, uint256 withdrawnAmount);

    event CrowdtainerInDeliveryStage(
        address indexed shippingAgent,
        uint256 totalValueRaised
    );

    // -----------------------------------------------
    // Contract functions
    // -----------------------------------------------

    /**
     * @notice Initializes a Crowdtainer.
     * @param _owner The contract owning this Crowdtainer instance, if any (address(0x0) for no owner).
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     */
    function initialize(
        address _owner,
        CampaignData calldata _campaignData
    ) external initializer onlyInState(CrowdtainerState.Uninitialized) {
        owner = _owner;

        // @dev: Sanity checks
        if (address(_campaignData.token) == address(0))
            revert Errors.TokenAddressIsZero();

        if (address(_campaignData.shippingAgent) == address(0))
            revert Errors.ShippingAgentAddressIsZero();

        if (
            _campaignData.referralEligibilityValue > _campaignData.targetMinimum
        )
            revert Errors.ReferralMinimumValueTooHigh({
                received: _campaignData.referralEligibilityValue,
                maximum: _campaignData.targetMinimum
            });

        if (_campaignData.referralRate % 2 != 0)
            revert Errors.ReferralRateNotMultipleOfTwo();

        // @dev: Expiration time should not be too close to the opening time
        if (
            _campaignData.expireTime <
            _campaignData.openingTime + SAFETY_TIME_RANGE
        ) revert Errors.ClosingTimeTooEarly();

        if (_campaignData.targetMaximum == 0)
            revert Errors.InvalidMaximumTarget();

        if (_campaignData.targetMinimum == 0)
            revert Errors.InvalidMinimumTarget();

        if (_campaignData.targetMinimum > _campaignData.targetMaximum)
            revert Errors.MinimumTargetHigherThanMaximum();

        uint256 _oneUnit = 10 ** IERC20Metadata(_campaignData.token).decimals();

        for (uint256 i = 0; i < _campaignData.unitPricePerType.length; i++) {
            if (_campaignData.unitPricePerType[i] < _oneUnit) {
                revert Errors.PriceTooLow();
            }
        }

        if (_campaignData.referralRate > SAFETY_MAX_REFERRAL_RATE)
            revert Errors.InvalidReferralRate({
                received: _campaignData.referralRate,
                maximum: SAFETY_MAX_REFERRAL_RATE
            });

        shippingAgent = _campaignData.shippingAgent;
        signer = _campaignData.signer;
        openingTime = _campaignData.openingTime;
        expireTime = _campaignData.expireTime;
        targetMinimum = _campaignData.targetMinimum;
        targetMaximum = _campaignData.targetMaximum;
        unitPricePerType = _campaignData.unitPricePerType;
        referralRate = _campaignData.referralRate;
        referralEligibilityValue = _campaignData.referralEligibilityValue;
        token = IERC20(_campaignData.token);
        legalContractURI = _campaignData.legalContractURI;
        oneUnit = _oneUnit;

        crowdtainerState = CrowdtainerState.Funding;

        emit CrowdtainerInitialized(
            owner,
            token,
            openingTime,
            expireTime,
            targetMinimum,
            targetMaximum,
            unitPricePerType,
            referralRate,
            referralEligibilityValue,
            legalContractURI,
            signer
        );
    }

    function numberOfProducts() external view returns (uint256) {
        return unitPricePerType.length;
    }

    /**
     * @notice Join the Crowdtainer project.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet interactions more friendly, by requiring fewer parameters for projects with referral system disabled.
     * @dev Requires IERC20 permit.
     */
    function join(address _wallet, uint256[] calldata _quantities) public {
        join(_wallet, _quantities, false, address(0));
    }

    /**
     * @notice Join the Crowdtainer project with optional referral and discount.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @dev Requires IERC20 permit.
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _wallet,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer
    )
        public
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        if (signer != address(0)) {
            // See https://eips.ethereum.org/EIPS/eip-3668
            revert Errors.OffchainLookup(
                address(this), // sender
                urls, // gateway urls
                abi.encodeWithSelector(
                    AuthorizationGateway.getSignedJoinApproval.selector,
                    address(this),
                    _wallet,
                    _quantities,
                    _enableReferral,
                    _referrer
                ), // parameters/data for the gateway (callData)
                Crowdtainer.joinWithSignature.selector, // 4-byte callback function selector
                abi.encode(_wallet, _quantities, _enableReferral, _referrer) // parameters for the contract callback function
            );
        }

        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        _join(_wallet, _quantities, _enableReferral, _referrer);
    }

    /**
     * @notice Allows joining by means of CCIP-READ (EIP-3668).
     * @param result (uint64, bytes) of signature validity and the signature itself.
     * @param extraData ABI encoded parameters for _join() method.
     *
     * @dev Requires IRC20 permit.
     */
    function joinWithSignature(
        bytes calldata result, // off-chain signed payload
        bytes calldata extraData // retained by client, passed for verification in this function
    )
        external
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        require(signer != address(0));

        // decode extraData provided by client
        (
            address _wallet,
            uint256[] memory _quantities,
            bool _enableReferral,
            address _referrer
        ) = abi.decode(extraData, (address, uint256[], bool, address));

        if (_quantities.length != unitPricePerType.length) {
            revert Errors.InvalidProductNumberAndPrices();
        }

        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        // Get signature from server response
        (
            address contractAddress,
            uint64 epochExpiration,
            bytes32 nonce,
            bytes memory signature
        ) = abi.decode(result, (address, uint64, bytes32, bytes));

        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                contractAddress,
                _wallet,
                _quantities,
                _enableReferral,
                _referrer,
                epochExpiration,
                nonce
            )
        );

        require(
            signaturePayloadValid(
                contractAddress,
                messageDigest,
                signer,
                epochExpiration,
                nonce,
                signature
            )
        );
        usedNonces[signer][nonce] = true;

        _join(_wallet, _quantities, _enableReferral, _referrer);
    }

    function signaturePayloadValid(
        address contractAddress,
        bytes32 messageDigest,
        address expectedPublicKey,
        uint64 expiration,
        bytes32 nonce,
        bytes memory signature
    ) internal view returns (bool) {
        address recoveredPublicKey = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageDigest)
        ).recover(signature);

        if (recoveredPublicKey != expectedPublicKey) {
            revert Errors.InvalidSignature();
        }
        if (contractAddress != address(this)) {
            revert Errors.InvalidSignature();
        }

        if (expiration <= block.timestamp) {
            revert Errors.SignatureExpired(uint64(block.timestamp), expiration);
        }

        if (usedNonces[expectedPublicKey][nonce]) {
            revert Errors.NonceAlreadyUsed(expectedPublicKey, nonce);
        }

        return true;
    }

    function _join(
        address _wallet,
        uint256[] memory _quantities,
        bool _enableReferral,
        address _referrer
    ) internal {
        enableReferral[_wallet] = _enableReferral;

        if (_quantities.length != unitPricePerType.length) {
            revert Errors.InvalidProductNumberAndPrices();
        }

        // @dev Check if wallet didn't already join
        if (costForWallet[_wallet] != 0) revert Errors.UserAlreadyJoined();

        // @dev Calculate cost
        uint256 finalCost;

        for (uint256 i = 0; i < _quantities.length; i++) {
            if (_quantities[i] > MAX_NUMBER_OF_PURCHASED_ITEMS)
                revert Errors.ExceededNumberOfItemsAllowed({
                    received: _quantities[i],
                    maximum: MAX_NUMBER_OF_PURCHASED_ITEMS
                });

            finalCost += unitPricePerType[i] * _quantities[i];
        }

        if (finalCost < oneUnit) {
            revert Errors.InvalidNumberOfQuantities();
        }

        if (_enableReferral && finalCost < referralEligibilityValue)
            revert Errors.MinimumPurchaseValueForReferralNotMet({
                received: finalCost,
                minimum: referralEligibilityValue
            });

        // @dev Apply discounts to `finalCost` if applicable.
        bool eligibleForDiscount;
        // @dev Verify validity of given `referrer`
        if (_referrer != address(0) && referralRate > 0) {
            // @dev Check if referrer participated
            if (costForWallet[_referrer] == 0) {
                revert Errors.ReferralInexistent();
            }

            if (!enableReferral[_referrer]) {
                revert Errors.ReferralDisabledForProvidedCode();
            }

            eligibleForDiscount = true;
        }

        uint256 discount;

        if (eligibleForDiscount) {
            // @dev Two things happens when a valid referral code is given:
            //    1 - Half of the referral rate is applied as a discount to the current order.
            //    2 - Half of the referral rate is credited to the referrer.

            // @dev Calculate the discount value
            discount = (finalCost * referralRate) / 100 / 2;

            // @dev 1- Apply discount
            finalCost -= discount;
            discountForUser[_wallet] += discount;

            // @dev 2- Apply reward for referrer
            accumulatedRewardsOf[_referrer] += discount;
            accumulatedRewards += discount;

            referrerOfReferee[_wallet] = _referrer;
        }

        costForWallet[_wallet] = finalCost;

        // increase total value accumulated by this contract
        totalValueRaised += finalCost;

        // @dev Check if the purchase order doesn't exceed the goal's `targetMaximum`.
        if (totalValueRaised > targetMaximum)
            revert Errors.PurchaseExceedsMaximumTarget({
                received: totalValueRaised,
                maximum: targetMaximum
            });

        // @dev transfer required funds into this contract
        token.safeTransferFrom(_wallet, address(this), finalCost);

        emit Joined(
            _wallet,
            _quantities,
            _referrer,
            finalCost,
            discount,
            _enableReferral
        );
    }

    /**
     * @notice Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @notice Calling this method signals that the participant is no longer interested in the project.
     * @param _wallet The wallet that is leaving the Crowdtainer.
     * @dev Only allowed if the respective Crowdtainer is in active `Funding` state.
     */
    function leave(
        address _wallet
    )
        external
        onlyOwner
        onlyInState(CrowdtainerState.Funding)
        onlyActive
        nonReentrant
    {
        if (owner == address(0)) {
            requireMsgSender(_wallet);
        }

        uint256 withdrawalTotal = costForWallet[_wallet];

        // @dev Subtract formerly given referral rewards originating from this account.
        address referrer = referrerOfReferee[_wallet];
        if (referrer != address(0)) {
            accumulatedRewardsOf[referrer] -= discountForUser[_wallet];
        }

        /* @dev If this wallet's referral was used, then it is no longer possible to leave().
         *      This is to discourage users from joining just to generate discount codes.
         *      E.g.: A user uses two different wallets, the first joins to generate a discount code for him/herself to be used in
         *      the second wallet, and then immediatelly leaves the pool from the first wallet, leaving the second wallet with a full discount. */
        if (accumulatedRewardsOf[_wallet] > 0) {
            revert Errors.CannotLeaveDueAccumulatedReferralCredits();
        }

        totalValueRaised -= costForWallet[_wallet];
        accumulatedRewards -= discountForUser[_wallet];

        costForWallet[_wallet] = 0;
        discountForUser[_wallet] = 0;
        referrerOfReferee[_wallet] = address(0);
        enableReferral[_wallet] = false;

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransfer(_wallet, withdrawalTotal);

        emit Left(_wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by the service provider to signal commitment to ship service or product by withdrawing/receiving the payment.
     */
    function getPaidAndDeliver()
        public
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        requireMsgSender(shippingAgent);
        uint256 availableForAgent = totalValueRaised - accumulatedRewards;

        if (totalValueRaised < targetMinimum) {
            revert Errors.MinimumTargetNotReached(
                targetMinimum,
                totalValueRaised
            );
        }

        crowdtainerState = CrowdtainerState.Delivery;

        // @dev transfer the owed funds from this contract to the service provider.
        token.safeTransfer(shippingAgent, availableForAgent);

        emit CrowdtainerInDeliveryStage(shippingAgent, availableForAgent);
    }

    /**
     * @notice Function used by project deployer to signal that it is no longer possible to the ship service or product.
     *         This puts the project into `Failed` state and participants can withdraw their funds.
     */
    function abortProject()
        public
        onlyInState(CrowdtainerState.Funding)
        nonReentrant
    {
        requireMsgSender(shippingAgent);
        crowdtainerState = CrowdtainerState.Failed;
    }

    /**
     * @notice Function used by participants to withdraw funds from a failed/expired project.
     */
    function claimFunds() public {
        claimFunds(msg.sender);
    }

    /**
     * @notice Function to withdraw funds from a failed/expired project back to the participant, with sponsored transaction.
     */
    function claimFunds(address wallet) public nonReentrant {
        uint256 withdrawalTotal = costForWallet[wallet];

        if (withdrawalTotal == 0) {
            revert Errors.InsufficientBalance();
        }

        if (block.timestamp < openingTime)
            revert Errors.OpeningTimeNotReachedYet(
                block.timestamp,
                openingTime
            );

        if (crowdtainerState == CrowdtainerState.Uninitialized)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        if (crowdtainerState == CrowdtainerState.Delivery)
            revert Errors.InvalidOperationFor({state: crowdtainerState});

        // The first interaction with this function 'nudges' the state to `Failed` if
        // the project didn't reach the goal in time, or if service provider is unresponsive.
        if (block.timestamp > expireTime && totalValueRaised < targetMinimum) {
            crowdtainerState = CrowdtainerState.Failed;
        } else if (block.timestamp > expireTime + MAX_UNRESPONSIVE_TIME) {
            crowdtainerState = CrowdtainerState.Failed;
        }

        if (crowdtainerState != CrowdtainerState.Failed)
            revert Errors.CantClaimFundsOnActiveProject();

        // Reaching this line means the project failed either due expiration or explicit transition from `abortProject()`.

        costForWallet[wallet] = 0;
        discountForUser[wallet] = 0;
        referrerOfReferee[wallet] = address(0);

        // @dev transfer the owed funds from this contract back to the user.
        token.safeTransfer(wallet, withdrawalTotal);

        emit FundsClaimed(wallet, withdrawalTotal);
    }

    /**
     * @notice Function used by participants to withdraw referral rewards from a successful project.
     */
    function claimRewards() public {
        claimRewards(msg.sender);
    }

    /**
     * @notice Function to withdraw referral rewards from a successful project, with sponsored transaction.
     */
    function claimRewards(
        address _wallet
    ) public nonReentrant onlyInState(CrowdtainerState.Delivery) {
        uint256 totalRewards = accumulatedRewardsOf[_wallet];
        accumulatedRewardsOf[_wallet] = 0;

        token.safeTransfer(_wallet, totalRewards);

        emit RewardsClaimed(_wallet, totalRewards);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./States.sol";

library Errors {
    // -----------------------------------------------
    //  Vouchers
    // -----------------------------------------------
    // @notice: The provided crowdtainer does not exist.
    error CrowdtainerInexistent();
    // @notice: Invalid token id.
    error InvalidTokenId(uint256 tokenId);
    // @notice: Prices lower than 1 * 1^6 not supported.
    error PriceTooLow();
    // @notice: Attempted to join with all product quantities set to zero.
    error InvalidNumberOfQuantities();
    // @notice: Account cannot be of address(0).
    error AccountAddressIsZero();
    // @notice: Metadata service contract cannot be of address(0).
    error MetadataServiceAddressIsZero();
    // @notice: Accounts and ids lengths do not match.
    error AccountIdsLengthMismatch();
    // @notice: ID's and amounts lengths do not match.
    error IDsAmountsLengthMismatch();
    // @notice: Cannot set approval for the same account.
    error CannotSetApprovalForSelf();
    // @notice: Caller is not owner or has correct permission.
    error AccountNotOwner();
    // @notice: Only the shipping agent is able to set a voucher/tokenId as "claimed".
    error SetClaimedOnlyAllowedByShippingAgent();
    // @notice: Cannot transfer someone else's tokens.
    error UnauthorizedTransfer();
    // @notice: Insufficient balance.
    error InsufficientBalance();
    // @notice: Quantities input length doesn't match number of available products.
    error InvalidProductNumberAndPrices();
    // @notice: Can't make transfers in given state.
    error TransferNotAllowed(address crowdtainer, CrowdtainerState state);
    // @notice: No further participants possible in a given Crowdtainer.
    error MaximumNumberOfParticipantsReached(
        uint256 maximum,
        address crowdtainer
    );
    // Used to apply off-chain verifications/rules per CCIP-read (EIP-3668),
    // see https://eips.ethereum.org/EIPS/eip-3668 for description.
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    error CCIP_Read_InvalidOperation();
    error SignatureExpired(uint64 current, uint64 expires);
    error NonceAlreadyUsed(address wallet, bytes32 nonce);
    error InvalidSignature();
    // Errors that occur inside external function calls, provided without decoding.
    error CrowdtainerLowLevelError(bytes reason);

    // -----------------------------------------------
    //  Initialization with invalid parameters
    // -----------------------------------------------
    // @notice: Contract initialized without owner address can't be set to having one.
    error OwnerAddressIsZero();
    // @notice: Cannot initialize with token of address(0).
    error TokenAddressIsZero();
    // @notice: Shipping agent can't have address(0).
    error ShippingAgentAddressIsZero();
    // @notice: Initialize called with closing time is less than one hour away from the opening time.
    error ClosingTimeTooEarly();
    // @notice: Initialize called with invalid number of maximum units to be sold (0).
    error InvalidMaximumTarget();
    // @notice: Initialize called with invalid number of minimum units to be sold (less than maximum sold units).
    error InvalidMinimumTarget();
    // @notice: Initialize called with invalid minimum and maximum targets (minimum value higher than maximum).
    error MinimumTargetHigherThanMaximum();
    // @notice: Initialize called with invalid referral rate.
    error InvalidReferralRate(uint256 received, uint256 maximum);
    // @notice: Referral rate not multiple of 2.
    error ReferralRateNotMultipleOfTwo();
    // @notice: Refferal minimum value for participation can't be higher than project's minimum target.
    error ReferralMinimumValueTooHigh(uint256 received, uint256 maximum);

    // -----------------------------------------------
    //  Authorization
    // -----------------------------------------------
    // @notice: Method not authorized for caller (message sender).
    error CallerNotAllowed(address expected, address actual);

    // -----------------------------------------------
    //  Join() operation
    // -----------------------------------------------
    // @notice: The given referral was not found thus can't be used to claim a discount.
    error ReferralInexistent();
    // @notice: Purchase exceed target's maximum goal.
    error PurchaseExceedsMaximumTarget(uint256 received, uint256 maximum);
    // @notice: Number of items purchased per type exceeds maximum allowed.
    error ExceededNumberOfItemsAllowed(uint256 received, uint256 maximum);
    // @notice: Wallet already used to join project.
    error UserAlreadyJoined();
    // @notice: Referral is not enabled for the given code/wallet.
    error ReferralDisabledForProvidedCode();
    // @notice: Participant can't participate in referral if the minimum purchase value specified by the service provider is not met.
    error MinimumPurchaseValueForReferralNotMet(
        uint256 received,
        uint256 minimum
    );

    // -----------------------------------------------
    //  Leave() operation
    // -----------------------------------------------
    // @notice: It is not possible to leave when the user has referrals enabled, has been referred and gained rewards.
    error CannotLeaveDueAccumulatedReferralCredits();

    // -----------------------------------------------
    //  GetPaidAndDeliver() operation
    // -----------------------------------------------
    // @notice: GetPaidAndDeliver can't be called on a expired project.
    error CrowdtainerExpired(uint256 timestamp, uint256 expiredTime);
    // @notice: Not enough funds were raised.
    error MinimumTargetNotReached(uint256 minimum, uint256 actual);
    // @notice: The project is not active yet.
    error OpeningTimeNotReachedYet(uint256 timestamp, uint256 openingTime);

    // -----------------------------------------------
    //  ClaimFunds() operation
    // -----------------------------------------------
    // @notice: Can't be called if the project is still active.
    error CantClaimFundsOnActiveProject();

    // -----------------------------------------------
    //  State transition
    // -----------------------------------------------
    // @notice: Method can't be invoked at current state.
    error InvalidOperationFor(CrowdtainerState state);

    // -----------------------------------------------
    //  Other Invariants
    // -----------------------------------------------
    // @notice: Payable receive function called, but we don't accept Eth for payment.
    error ContractDoesNotAcceptEther();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "./Constants.sol";
import "./States.sol";

// @notice:  Data defining all rules and values of a Crowdtainer instance.
struct CampaignData {
    // Ethereum Address that represents the product or service provider.
    address shippingAgent;
    // Address used for signing authorizations.
    address signer;
    // Funding opening time.
    uint256 openingTime;
    // Time after which the owner can no longer withdraw funds.
    uint256 expireTime;
    // Amount in ERC20 units required for project to be considered to be successful.
    uint256 targetMinimum;
    // Amount in ERC20 units after which no further participation is possible.
    uint256 targetMaximum;
    // Array with price of each item, in ERC2O units. Zero is an invalid value and will throw.
    uint256[] unitPricePerType;
    // Percentage used for incentivising participation. Half the amount goes to the referee, and the other half to the referrer.
    uint256 referralRate;
    // The minimum purchase value required to be eligible to participate in referral rewards.
    uint256 referralEligibilityValue;
    // Address of the ERC20 token used for payment.
    address token;
    // URI string pointing to the legal terms and conditions ruling this project.
    string legalContractURI;
}

// @notice: EIP-712 / ERC-2612 permit data structure.
struct SignedPermit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @dev Interface for Crowdtainer instances.
 */
interface ICrowdtainer {
    /**
     * @dev Initializes a Crowdtainer.
     * @param _owner The contract owning this Crowdtainer instance, if any (address(0x0) for no owner).
     * @param _campaignData Data defining all rules and values of this Crowdtainer instance.
     */
    function initialize(
        address _owner,
        CampaignData calldata _campaignData
    ) external;

    function crowdtainerState() external view returns (CrowdtainerState);

    function shippingAgent() external view returns (address);

    function numberOfProducts() external view returns (uint256);

    function unitPricePerType(uint256) external view returns (uint256);

    /**
     * @notice Join the Crowdtainer project.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     *
     * @dev This method is present to make wallet interactions more friendly, by requiring fewer parameters for projects with referral system disabled.
     * @dev Requires IERC20 permit.
     */
    function join(address _wallet, uint256[] calldata _quantities) external;

    /**
     * @notice Join the Crowdtainer project with optional referral and discount.
     * @param _wallet The wallet that is joining the Crowdtainer. Must be the msg.sender if Crowdtainer owner is address(0x0).
     * @param _quantities Array with the number of units desired for each product.
     * @param _enableReferral Informs whether the user would like to be eligible to collect rewards for being referred.
     * @param _referrer Optional referral code to be used to claim a discount.
     *
     * @dev Requires IERC20 permit.
     * @dev referrer is the wallet address of a previous participant.
     * @dev if `enableReferral` is true, and the user decides to leave after the wallet has been used to claim a discount,
     *       then the full value can't be claimed if deciding to leave the project.
     * @dev A same user is not allowed to increase the order amounts (i.e., by calling join multiple times).
     *      To 'update' an order, the user must first 'leave' then join again with the new values.
     */
    function join(
        address _wallet,
        uint256[] calldata _quantities,
        bool _enableReferral,
        address _referrer
    ) external;

    /*
     * @dev Leave the Crowdtainer and withdraw deposited funds given when joining.
     * @note Calling this method signals that the user is no longer interested in participating.
     * @note Only allowed if the respective Crowdtainer is in active `Funding` state.
     * @param _wallet The wallet that is leaving the Crowdtainer.
     */
    function leave(address _wallet) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

enum CrowdtainerState {
    Uninitialized,
    Funding,
    Delivery,
    Failed
}