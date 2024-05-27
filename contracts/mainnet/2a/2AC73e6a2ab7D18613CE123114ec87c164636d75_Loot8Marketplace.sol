// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/admin/IEntity.sol";
import "../../interfaces/access/IDAOAuthority.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title An abstract smart contract that defines modifiers for access control checks for 
 * various authorities and also ERC2771 methods to enable and extract data from meta transactions
 * @author 0xtchandragupta
 * @notice This contract can be used to declare and modify roles in the system
 * @dev Only a governor is allowed to change roles
 * @custom:switch It is possible to deploy a completely new Authority contract and set 
    the new address in all relevant contracts
 */

abstract contract DAOAccessControlled is Context {
    
    /* ========== EVENTS ========== */

    event AuthorityUpdated(address indexed authority);

    /* ========== STATE VARIABLES ========== */
    
    IDAOAuthority public authority;    
    uint256[5] __gap; // storage gap

    /* ========== Initializer ========== */

    function _setAuthority(address _authority) internal {        
        authority = IDAOAuthority(_authority);
        emit AuthorityUpdated(_authority);        
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAuthority() {
        require(address(authority) == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyGovernor() {
        require(authority.getAuthorities().governor == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyPolicy() {
        require(authority.getAuthorities().policy == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyAdmin() {
        require(authority.getAuthorities().admin == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyEntityAdmin(address _entity) {
        require(
            IEntity(_entity).getEntityAdminDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyBartender(address _entity) {
        require(
            IEntity(_entity).getBartenderDetails(_msgSender()).isActive,
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyDispatcher() {
        require(authority.getAuthorities().dispatcher == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyCollectionManager() {
        require(authority.getAuthorities().collectionManager == _msgSender(), "UNAUTHORIZED");
        _;
    }

    modifier onlyForwarder() {
        // this modifier must check msg.sender directly (not through _msgSender()!)
        require(isTrustedForwarder(msg.sender), "UNAUTHORIZED");
        _;
    }

    modifier onlyEntityManager(address _entity) {
        require(
            IEntity(_entity).managers(_msgSender()),
            "UNAUTHORIZED"
        );
        _;
    }

    /* ========== GOV ONLY ========== */
    /**
     * @notice This function will change the authority to _newAuthority
     * @dev    Only authorities.governor can change it
     * @param  _newAuthority address Address of the new authority
     */
    function setAuthority(address _newAuthority) external onlyGovernor {
       _setAuthority(_newAuthority);
    }

    /* ========= ERC2771 ============ */
    /**
     * @notice This function will check if a given address is the trusted forwarder on this chain
     * @param  forwarder address Address to be checked
     * @return isForwarder bool true if the address is a forwarder else false
     */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return address(authority) != address(0) && forwarder == authority.getAuthorities().forwarder;
    }

    /// @dev Extracts the address of the actual sender of the meta transaction
    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    /// @dev Extracts the data from the meta transaction message
    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../access/DAOAccessControlled.sol";
import "../../interfaces/user/IUser.sol";
import "../../interfaces/admin/IOwnable.sol";
import "../../interfaces/misc/ICollectionHelper.sol";
import "../../interfaces/misc/ICollectionManager.sol";
import "../../interfaces/finance/IRoyaltyManager.sol";
import "../../interfaces/finance/IRoyaltyEngineV1.sol";
import "../../interfaces/finance/ILoot8Marketplace.sol";
import "../../interfaces/finance/ILoot8MarketplaceVerification.sol";
import "../../interfaces/finance/ISubscriptionManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/** 
 * @title  A marketplace contract used for listing and trading collectibles publicly or privately on the platform
 * @notice This is an upgradeable contract
 * @author 0xtchandragupta
 */
contract Loot8Marketplace is ILoot8Marketplace, Initializable, DAOAccessControlled {

    using SafeERC20 for IERC20;

    /// @notice Unique IDs for new listings
    uint256 public listingIds;
    
    /// @notice Marketplace fee for primary sale
    /// @dev not used anymore, since fee is now referred from royalty manager
    uint256 public mintFee; // 5% = 500 basis points

    /// @notice Marketplace fee for secondary sale
    /// @dev not used anymore, since fee is now referred from royalty manager
    uint256 public saleFee; // 2.5% = 250 basis points

    /// @notice collection manager contract address
    address public collectionManager;

    /// @notice collection helper contract address
    address public collectionHelper;

    /// @notice user contract address
    address public userContract;

    /// @notice signature verification contract address
    address public verifier;

    /// @notice royaltyregistry.xyz Royalty engine contract on chain
    address public royaltyEngine;

    /// @notice LOOT8's receiver for marketplace fees(May be an EOA, multisig or contract)
    /// @dev not used anymore, since recipients are now managed from royalty manager
    address public feeRecipient;

    /// @notice A message that the relayer will sign to indicate that the validation checks have succeeded
    string public constant validationMessage = "VALIDATION CHECKS PASSED";

    /// @notice Listings for sale on the marketplace
    mapping(uint256 => Listing) public listings;

    /// @notice Listings by collection
    mapping(address => uint256[]) public listingsByCollection;

    /// @notice Error Messages
    uint16 NOT_EXIST;
    uint16 SUSPENDED;
    uint16 RETIRED;
    uint16 INVALID_USER;
    uint16 NOT_OWNER;
    uint16 EXIST;
    uint16 LISTING_NOT_EXIST;
    uint16 TOKEN_NOT_APPROVED;
    uint16 PAYMENT_TOKEN_NOT_APPROVED;
    uint16 INSUFFICIENT_BALANCE;
    uint16 COLLECTION_NON_TRADEABLE;
    uint16 PRIVATE_TRADE_NOT_ALLOWED;
    uint16 PUBLIC_TRADE_NOT_ALLOWED;
    uint16 INVALID_VALIDATION_SIGNATURE;
    uint16 VALIDATION_SIGNATURE_EXPIRED;
    uint16 NOT_A_PASSPORT;
    uint16 COLLECTION_NOT_LINKED;
    uint16 PASSPORT_NEEDED;
    uint16 PAYMENT_TOKEN_INVALID;
    uint16 PASSPORT_NOT_OWNED;

    /// @notice errorMessages mapping
    mapping(uint16 => string) private errorMessages;

    /// @notice Valid tokens acceptable as payment for sale
    mapping(address => bool) public validPaymentToken;

    /// @notice feeDenominator for percentage calculations. Specified in basis points
    /// @dev not used anymore, since fee denominator is now referred from royalty manager
    uint96 public constant feeDenominator = 10000;

    /// @notice more errorMessages
    /// @notice not used anymore as fee is now referred from royalty manager
    uint16 MINT_OVERFLOW;
    uint16 SALE_OVERFLOW;

    uint16 SUM_OVERFLOW;
    uint16 ZERO_SELLER_SHARE;
    uint16 PRICE_UNDERFLOW;

    /// @notice Address of the subscription manager contract
    address public subscriptionManager;

    /// @notice more errorMessages
    uint16 FREE_EXPASS;
    /// @dev a contract that stores details about royalties
    address public royaltyManager;

    /** 
     * @notice Initializer for the Loot8Marketplace
     * @param  _authority address Authority contract address
     * @param  _collectionManager address Collection Manager contract address
     * @param  _userContract address User contract address
     * @param  _verifier address Signature verification contract address
     * @param  _royaltyEngine address Royalty engine contract address
     * @param  _feeRecipient address Fee receiver wallet address
     */
    function initialize(
        address _authority,
        address _collectionManager,
        address _userContract,
        address _verifier,
        address _royaltyEngine,
        address _feeRecipient
    ) public initializer {

        DAOAccessControlled._setAuthority(_authority);
        collectionManager = _collectionManager;
        collectionHelper = authority.collectionHelper();
        userContract = _userContract;
        verifier = _verifier;
        royaltyEngine = _royaltyEngine;
        feeRecipient = _feeRecipient;

        NOT_EXIST = 1;
        SUSPENDED = 2;
        RETIRED = 3;
        INVALID_USER = 4;
        NOT_OWNER = 5;
        EXIST = 6;
        LISTING_NOT_EXIST = 7;
        TOKEN_NOT_APPROVED = 8;
        PAYMENT_TOKEN_NOT_APPROVED = 9;
        INSUFFICIENT_BALANCE = 10;
        COLLECTION_NON_TRADEABLE = 11;
        PRIVATE_TRADE_NOT_ALLOWED = 12;
        PUBLIC_TRADE_NOT_ALLOWED = 13;
        INVALID_VALIDATION_SIGNATURE = 14;
        VALIDATION_SIGNATURE_EXPIRED = 15;
        NOT_A_PASSPORT = 16;
        COLLECTION_NOT_LINKED = 17;
        PASSPORT_NEEDED = 18;
        PAYMENT_TOKEN_INVALID = 19;
        PASSPORT_NOT_OWNED = 20;

        errorMessages[NOT_EXIST] = "COLLECTION DOES NOT EXIST";
        errorMessages[SUSPENDED] = "COLLECTIBLE SUSPENDED";
        errorMessages[RETIRED] = "COLLECTION RETIRED";
        errorMessages[INVALID_USER] = "INVALID OR BANNED USER";
        errorMessages[NOT_OWNER] = "LISTER IS NOT THE OWNER";
        errorMessages[EXIST] = "LISTING EXISTS";
        errorMessages[LISTING_NOT_EXIST] = "LISTING DOES NOT EXIST";
        errorMessages[TOKEN_NOT_APPROVED] = "TOKEN NOT APPROVED TO MARKETPLACE";
        errorMessages[PAYMENT_TOKEN_NOT_APPROVED] = "PAYMENT TOKEN NOT APPROVED TO MARKETPLACE";
        errorMessages[INSUFFICIENT_BALANCE] = "INSUFFICIENT BALANCE";
        errorMessages[COLLECTION_NON_TRADEABLE] = "COLLECTION IS NOT TRADEABLE";
        errorMessages[PRIVATE_TRADE_NOT_ALLOWED] = "PRIVATE TRADE NOT ALLOWED";
        errorMessages[PUBLIC_TRADE_NOT_ALLOWED] = "PUBLIC TRADE NOT ALLOWED";
        errorMessages[INVALID_VALIDATION_SIGNATURE] = "INVALID VALIDATION SIGNATURE";
        errorMessages[VALIDATION_SIGNATURE_EXPIRED] = "VALIDATION SIGNATURE EXPIRED";
        errorMessages[NOT_A_PASSPORT] = "NOT A PASSPORT";
        errorMessages[COLLECTION_NOT_LINKED] = "COLLECTION NOT LINKED TO PASSPORT";
        errorMessages[PASSPORT_NEEDED] = "PASSPORT IS NEEDED FOR PRIVATE LISTING";
        errorMessages[PAYMENT_TOKEN_INVALID] = "PAYMENT TOKEN IS INVALID";
        errorMessages[PASSPORT_NOT_OWNED] = "PASSPORT NOT OWNED BY PATRON";

        /// @dev Start ids with 1 as 0 is for existence check
        listingIds++;

    }

    /** 
     * @notice InitializerV2 for the Loot8Marketplace
     */
    function initializeV2() public reinitializer(2) {
        
        MINT_OVERFLOW = 21;
        SALE_OVERFLOW = 22;
        SUM_OVERFLOW = 23;
        ZERO_SELLER_SHARE = 24;
        PRICE_UNDERFLOW = 25;

        errorMessages[MINT_OVERFLOW] = "MINT FEE OVERFLOW";
        errorMessages[SALE_OVERFLOW] = "SALE FEE OVERFLOW";
        errorMessages[SUM_OVERFLOW] = "SUM OVERFLOW";
        errorMessages[ZERO_SELLER_SHARE] = "SELLER SHARE ZERO";
        errorMessages[PRICE_UNDERFLOW] = "PRICE UNDERFLOW";

    }

    /** 
     * @notice InitializerV3 for the Loot8Marketplace
     * @param  _subscriptionManager Subscription Manager contract address
     */
    function initializeV3(address _subscriptionManager) public reinitializer(3) {
        subscriptionManager = _subscriptionManager;
    }

    /** 
     * @notice InitializerV4 for the Loot8Marketplace
     */
    function initializeV4() public reinitializer(4) {
        FREE_EXPASS = 26;
        errorMessages[FREE_EXPASS] = "FREE EXPASS CANNOT BE SOLD ON MARKETPLACE";
    }

    /**
     * @notice InitializerV5 for the Loot8Marketplace 
     * @param  _royaltyManager Royalty Manager contract address
     */
    function initializeV5(address _royaltyManager) public reinitializer(5) {
        royaltyManager = _royaltyManager;
    }

    /** 
     * @notice Checks if a listing of type: _listingType exists in the marketplace for a tokenId:_tokenId from collection: _collection
     * @param  _collection address Primary sale fee specified in basis points
     * @param  _tokenId uint256 Secondary sale fee specified in basis points
     * @param  _listingType ListingType Listing type PRIVATE/PUBLIC/ALL
     * @return _exists bool true if listing exists else false
     * @return _listingId uint256 Id of the Listing if it exists else 0
     */
    function listingExists(address _collection, uint256 _tokenId, ListingType _listingType) public view returns(bool _exists, uint256 _listingId) {
        for(uint256 i = 0; i < listingsByCollection[_collection].length; i++) {
            uint256 listingId = listingsByCollection[_collection][i];
            if(listings[listingId].tokenId == _tokenId && listings[listingId].listingType == _listingType) {
                return (true, listingId);
            }
        }

        return (false, 0);
    }

    /** 
     * @dev Internal helper method to check if a collection: _collection is linked to a passport: _passport
    */
    function _isCollectionLinkedToPassport(address _passport, address _collection) internal view returns(bool) {
        
        address[] memory passportLinkedCollections = ICollectionHelper(collectionHelper).getAllLinkedCollections(_passport);

        for(uint256 i = 0; i < passportLinkedCollections.length; i++) {
            if(passportLinkedCollections[i] == _collection) {
                break;
            }

            if(i == passportLinkedCollections.length - 1) {
                return false;
            }
            
        }

        address[] memory collectionLinkedCollections = ICollectionHelper(collectionHelper).getAllLinkedCollections(_collection);

        for(uint256 i = 0; i < collectionLinkedCollections.length; i++) {
            if(collectionLinkedCollections[i] == _passport) {
                break;
            }

            if(i == collectionLinkedCollections.length - 1) {
                return false;
            }
        }
        
        return true;
        
    }

    /** 
     * @notice Checks if a collection: _collection can be listed publicly or privately
     * @param  _passport address Address of passport for private listing(ZERO address for public listing)
     * @param  _collection address Address of collection to be listed
     * @return isValid bool true if listing is allowed for the give passport: _passport and collection: _collection
     * @dev    This method is called by the validation API endpoint which generates a signature only if this check passes
     */
    function checkItemValidity(address _passport, address _collection) public view returns(bool) {
        
        ICollectionManager _collectionManager = ICollectionManager(collectionManager);
        ICollectionHelper _collectionHelper = ICollectionHelper(collectionHelper);

        /// @dev check if collection exists
        require(_collectionManager.isCollection(_collection), errorMessages[NOT_EXIST]);

        if(_collectionManager.getCollectionType(_collection) == CollectionType.PASSPORT) {
            ICollectionData.CollectionDataAdditional memory _collectionAdditionalData;
            (,,,, _collectionAdditionalData,,,,,) = ICollectionManager(collectionManager).getCollectionInfo(_collection);
            require(_collectionAdditionalData.isPremium, errorMessages[FREE_EXPASS]);
        }

        /// @dev in case of private listings check if collection is linked to the given passport address
        if(_passport != address(0)) {
            require(_collectionManager.isCollection(_passport), errorMessages[NOT_EXIST]);
            (,,,,,,,,, ICollectionData.CollectionType _collectionType) = _collectionManager.getCollectionInfo(_passport);
            require(_collectionType == ICollectionData.CollectionType.PASSPORT, errorMessages[NOT_A_PASSPORT]);
            require(_isCollectionLinkedToPassport(_passport, _collection), errorMessages[COLLECTION_NOT_LINKED]);
        }

        /// @dev check if collection is tradeable
        require(
            _collectionHelper.getMarketplaceConfig(_collection).allowMarketplaceOps, 
            errorMessages[COLLECTION_NON_TRADEABLE]
        );

        return true;
    }

    /** 
     * @notice Checks if a patron: _patron is eligible to list a collection: _collection for a particular listingType
     * @param  _patron address Address of passport for private listing(ZERO address for public listing)
     * @param  _passport address Address of passport for private listing(ZERO address for public listing)
     * @param  _collection address Address of collection to be listed
     * @param  _listingType ListingType PUBLIC or PRIVATE
     * @return isEligible bool true if a trader is eligible to create a listing
     * @dev    This method is called by the validation API endpoint which generates a signature only if this check passes
     */
    function checkTraderEligibility(
        address _patron, 
        address _passport, 
        address _collection, 
        ListingType _listingType
    ) public view returns(bool) {
        /// @dev check is patron is a registered user of LOOT8 who is not banned
        require(IUser(userContract).isValidPermittedUser(_patron), errorMessages[INVALID_USER]);
        
        ICollectionHelper _collectionHelper = ICollectionHelper(collectionHelper);
        
        /// @dev check if PUBLIC trade is allowed for the collection
        if(_listingType == ListingType.PUBLIC) {
            require(
                ICollectionHelper(_collectionHelper).getMarketplaceConfig(_collection).publicTradeAllowed, 
                errorMessages[PUBLIC_TRADE_NOT_ALLOWED]
            );
        } else {
            /// @dev check if PRIVATE trade is allowed for the collection
            require(
                _collectionHelper.getMarketplaceConfig(_collection).privateTradeAllowed,
                errorMessages[PRIVATE_TRADE_NOT_ALLOWED]
            );

            ICollectionManager _collectionManager = ICollectionManager(collectionManager);
            /// @dev in case of PRIVATE trade the patron should hold the passport
            /// @dev the check will only be performed in case passport is on the same chain as Loot8Marketplace
            if(_passport != address(0) && _collectionManager.getCollectionChainId(_passport) == block.chainid) {
                require(IERC721(_passport).balanceOf(_patron) > 0, errorMessages[PASSPORT_NOT_OWNED]);
            }
        }

        return true;
    }

    /** 
     * @dev Internal helper method to verify a signature on a validation message signed by the validation API
     * @dev Components in the validation message are:
     * @dev _patron address Address of the patron
     * @dev _passport address Address of the passport for private listing(ZERO address for public listing)
     * @dev _collection address Address of the collection being traded
     * @dev _tokenId uint256 TokenID being traded
     * @dev _paymentToken address Payment token expected in return for the trade
     * @dev _price uint256 Price of the token
     * @dev _action string buy or sell
     * @dev _listingType ListingType Listing type PUBLIC or PRIVATE
     * @dev _expiry uint256 Expiry timestamp for the signature
     * @dev _signature bytes Signature
     */
    function verifyValidationSignature(
        address _patron,
        address _passport,
        address _collection,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price,
        string memory _action,
        ListingType _listingType,
        uint256 _expiry,
        bytes memory _signature
    ) internal returns(bool){
        ILoot8MarketplaceVerification verifierContract = ILoot8MarketplaceVerification(verifier);

        return verifierContract.verifyAndUpdateNonce(
            _patron,
            _passport,
            _collection,
            _tokenId,
            _paymentToken,
            _price,
            _action,
            _listingType,
            validationMessage,
            _expiry,
            _signature
        );
    }

    /** 
     * @notice List a tokenID: _tokenId from collection: _collection for public or private trade
     * @param  _passport address Address of the passport for private listing(ZERO address for public listing)
     * @param  _collection uint256 Address of the collection being traded
     * @param  _tokenId uint256 TokenID being traded
     * @param  _paymentToken uint256 Payment token expected in return for the trade
     * @param  _price uint256 Price of the token
     * @param  _signature uint256 Signature from validation API
     * @param  _expiry uint256 Expiry for for the listing
     * @param  _listingType ListingType Listing type PUBLIC or PRIVATE
     * @return _listingId uint256 ID of the listing created
     */
    function listCollectible(
        address _passport,
        address _collection, 
        uint256 _tokenId,
        address _paymentToken, 
        uint256 _price, 
        bytes memory _signature,
        uint256 _expiry,
        ListingType _listingType
    ) external returns(uint256 _listingId) {

        /// @dev Passport is neeeded for private listing
        if(_listingType == ListingType.PRIVATE) {
            require(_passport != address(0), errorMessages[PASSPORT_NEEDED]);
        }

        /// @dev minimum price for a listing can be 0.01 tokens
        if(_paymentToken != address(0)) {
            require(_price >= 10**(IERC20Metadata(_paymentToken).decimals() - 2), errorMessages[PRICE_UNDERFLOW]);
        }

        /// @dev signature is valid only till the expiry timestamp
        require(_expiry > block.timestamp, errorMessages[VALIDATION_SIGNATURE_EXPIRED]);

        /// @dev verify the signature
        require(
            verifyValidationSignature(
                _msgSender(), 
                _passport, 
                _collection, 
                _tokenId, 
                _paymentToken,
                _price,
                'list', 
                _listingType,
                _expiry, 
                _signature
            ), errorMessages[INVALID_VALIDATION_SIGNATURE]);

        /// @dev is the payment token for the listing a valid token for trade?
        require(validPaymentToken[_paymentToken], errorMessages[PAYMENT_TOKEN_INVALID]);

        /// @dev lister should be owner of the tokenID being listed
        require(IERC721(_collection).ownerOf(_tokenId) == _msgSender(), errorMessages[NOT_OWNER]);
        
        /// @dev check if a listing for _tokenId from collection: _collection already exists
        (bool exists,) = listingExists(_collection, _tokenId, _listingType);
        require(!exists, errorMessages[EXIST]);

        /// @dev lister should approve the marketplace contract to spend the token on their behalf
        require(IERC721(_collection).getApproved(_tokenId) == address(this), errorMessages[TOKEN_NOT_APPROVED]);

        /// @dev recepient and amount for creator fee
        address payable[] memory _recepients = new address payable[](1);
        uint256[] memory _amounts = new uint256[](1);

        _listingId = listingIds;
        /// @dev Add a listing if all checks successful
        uint256[10] memory __gap;
        listings[_listingId] = Listing({
            id: _listingId,
            seller: _msgSender(),
            passport: _passport,
            collection: _collection,
            tokenId: _tokenId,
            paymentToken: _paymentToken,
            price: _price,
            sellerShare: 0,
            royaltyRecipients: _recepients,
            amounts: _amounts,
            fees: 0,
            listingType: _listingType,
            __gap: __gap
        });

        listingsByCollection[_collection].push(_listingId);

        listingIds++;

        emit ItemListedForSale(_listingId, _collection, _tokenId, _paymentToken, _price, _listingType);
    }

    /** 
     * @dev Internal helper method to delist a collectible
     * @dev _listingId uint256 Listing ID to delist
     * @dev _collection address Collection address
     * @dev _tokenId address TokenID to delist
     */
    function _delistCollectible(uint256 _listingId, address _collection, uint256 _tokenId) internal { 

        for(uint256 i = 0; i < listingsByCollection[_collection].length; i++) {

            if(listingsByCollection[_collection][i] == _listingId) { 
                if(i < listingsByCollection[_collection].length - 1) {
                    listingsByCollection[_collection][i] = listingsByCollection[_collection][listingsByCollection[_collection].length - 1];
                }
                listingsByCollection[_collection].pop();
            }
        }

        delete listings[_listingId];

        emit ItemDelisted(_listingId, _collection, _tokenId);

    }

    /** 
     * @notice Delist a listing with listingId: _listingId
     * @param  _listingId uint256 Listing ID to delist
     * @dev    Only the governor or owner of the listing can delist 
     */
    function delistCollectible(uint256 _listingId) public {
        require(listings[_listingId].id > 0, errorMessages[LISTING_NOT_EXIST]);
        Listing memory listing = listings[_listingId];
        address collection = listing.collection;
        uint256 tokenId = listing.tokenId;

        /// @dev Allowing governor to delist buggy listings
        if(_msgSender() != authority.getAuthorities().governor) {
            require(
            IERC721(collection).ownerOf(tokenId) == _msgSender(),  errorMessages[NOT_OWNER]);
        }

        _delistCollectible(_listingId, collection, tokenId);

    }

    /** 
     * @dev Internal method to exchange tokens on successful sale
    */
    function _exchangeTokens(address _buyer, Listing memory _listing) internal {
        uint256 price = _listing.price;
        address collection = _listing.collection;
        address paymentToken = _listing.paymentToken;

        /// @dev Calculate royalties to be paid
        /// @dev this recalculation is required as royalties may have changed since the time of listing
        (uint256 _feePercent,,,) = IRoyaltyManager(royaltyManager).getRoyalty(collection, IRoyaltyManager.SaleType.SECONDARY);
        uint256 fees = (price * _feePercent) / IRoyaltyManager(royaltyManager).royaltyDenominator();

        /// @dev listing fails if payment of platform fee and royalties results in a zero share for seller
        require(fees < price, errorMessages[ZERO_SELLER_SHARE]);

        /// @dev re-calculate the seller share from total price
        uint256 sellerShare = price - fees;

        /// @dev Update the listing in storage
        Listing storage listing = listings[_listing.id];
        listing.fees = fees;
        listing.sellerShare = sellerShare;

        /// @dev transfer seller share to seller
        IERC20(paymentToken).safeTransferFrom(_buyer, _listing.seller, sellerShare);

        if(fees > 0) {
            IERC20(paymentToken).safeTransferFrom(_buyer, royaltyManager, fees);
            /// @dev split royalties to recipients configured
            IRoyaltyManager(royaltyManager).splitRoyalty(collection, IRoyaltyManager.SaleType.SECONDARY, price, paymentToken);
        }

        /// @dev transfer collectible to buyer
        IERC721(_listing.collection).safeTransferFrom(_listing.seller, _buyer, _listing.tokenId);
    }

    /** 
     * @notice Buys a listing with listingId: _listingId
     * @param  _listingId uint256 Listing ID to buy
     * @param  _signature bytes Signature received from validation API
     * @param  _expiry uint256 timestamp for signature expiry
     */
    function buy(uint256 _listingId, bytes memory _signature, uint256 _expiry) external {
        require(listings[_listingId].id > 0, errorMessages[LISTING_NOT_EXIST]);
        Listing memory listing = listings[_listingId];
        address collection = listing.collection;
        address passport = listing.passport;
        uint256 tokenId = listing.tokenId;
        address paymentToken = listing.paymentToken;
        uint256 price = listing.price;
        ListingType listingType = listing.listingType;

        /// @dev check if payment token required for purchase is still valid
        require(validPaymentToken[paymentToken], "PAYMENT TOKEN IS INVALID");

        /// @dev check if validation signature has not expired
        require(_expiry > block.timestamp, errorMessages[VALIDATION_SIGNATURE_EXPIRED]);

        /// @dev signature verification
        require(
            verifyValidationSignature(
                _msgSender(), 
                passport, 
                collection, 
                tokenId,
                paymentToken,
                price,
                'buy',
                listingType,
                _expiry, 
                _signature
            ), errorMessages[INVALID_VALIDATION_SIGNATURE]
        );

        /// @dev buyer has insufficient balance to purchase this listing
        require(IERC20(paymentToken).balanceOf(_msgSender()) >= price, errorMessages[INSUFFICIENT_BALANCE]);

        /// @dev buyer has approve the payment token to marketplace to be able to purchase this listing
        require(
            IERC20(paymentToken).allowance(_msgSender(), address(this)) >= price, 
            errorMessages[PAYMENT_TOKEN_NOT_APPROVED]
        );

        /// @dev delist the listing on successful purchase
        _delistCollectible(_listingId, collection, tokenId);
        
        /// @dev Unstake tokens for the seller when an EXPASS is sold in the marketplace
        /// @dev Temporarily block execution of these lines on other chains till cross-chain EXPasses are configured
        if(subscriptionManager != address(0) && collectionManager != address(0)) {
            (,,,, ICollectionData.CollectionDataAdditional memory _collectionAdditionalData,,,,, ICollectionData.CollectionType _collectionType) = ICollectionManager(collectionManager).getCollectionInfo(collection);

            if(
                _collectionType == ICollectionData.CollectionType.PASSPORT &&
                _collectionAdditionalData.mintModel == ICollectionData.MintModel.SUBSCRIPTION
            ) {
                ISubscriptionManager(subscriptionManager).unstakeOnMarketplaceSell(collection, tokenId);
            }
        } 

        /// @dev Exchange tokens when all checks pass to complete the purchase
        _exchangeTokens(_msgSender(), listing);

        emit ItemSold(collection, tokenId);

    }

    /** 
     * @notice Fetch a list of all listings for a given collection
     * @param  _collection address Address of collection to fetch listings for
     * @return _listings Listing[] List of listingIds
     */
    function getAllListingsForCollection(address _collection) public view returns(Listing[] memory _listings) {
        uint256[] memory _listingsByCollection = listingsByCollection[_collection];
        _listings = new Listing[](_listingsByCollection.length);
        for(uint256 i = 0; i < _listingsByCollection.length; i++) {
            _listings[i] = listings[_listingsByCollection[i]];
        }
    }

    /** 
     * @notice Add payment token to a list of valid tokens for trading
     * @param  _token address Address of the payment token add
     */
    function addPaymentToken(address _token) external onlyGovernor {
        validPaymentToken[_token] = true;
        emit AddedPaymentToken(_token);
    }

    /** 
     * @notice Remove payment token from a list of valid tokens for trading
     * @param  _token address Address of the payment token to remove
     */
    function removePaymentToken(address _token) external onlyGovernor {
        delete validPaymentToken[_token];
        emit RemovedPaymentToken(_token);
    }

    /** 
     * @notice Get listing details by Id
     * @param  _listingId uint256 Listing Id to fetch details of
     */
    function getListingById(uint256 _listingId) public view returns(Listing memory _listing) {
        return listings[_listingId];
    }

    /** 
     * @notice Sets the royalty manager for Loot8Marketplace
     * @param  _royaltyManager address address of the royalty manager
     */
    function setRoyaltyManager(address _royaltyManager) external onlyGovernor {
        address oldRoyaltyManager = _royaltyManager;
        royaltyManager = _royaltyManager;
        emit SetRoyaltyManager(oldRoyaltyManager, royaltyManager);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IDAOAuthority {

    /*********** EVENTS *************/
    event ChangedGovernor(address _newGovernor);
    event ChangedPolicy(address _newPolicy);
    event ChangedAdmin(address _newAdmin);
    event ChangedForwarder(address _newForwarder);
    event ChangedDispatcher(address _newDispatcher);
    event ChangedCollectionHelper(address _newCollectionHelper);
    event ChangedCollectionManager(address _newCollectionManager);
    event ChangedTokenPriceCalculator(address _newTokenPriceCalculator);

    struct Authorities {
        address governor;
        address policy;
        address admin;
        address forwarder;
        address dispatcher;
        address collectionManager;
        address tokenPriceCalculator;
    }

    function collectionHelper() external view returns(address);
    function getAuthorities() external view returns(Authorities memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/location/ILocationBased.sol";

interface IEntity is ILocationBased {

    /* ========== EVENTS ========== */
    event EntityToggled(address _entity, bool _status);
    event EntityUpdated(address _entity, Area _area, string _dataURI, address _walletAddress);
        
    event EntityDataURIUpdated(string _oldDataURI,  string _newDataURI);    

    event EntityAdminGranted(address _entity, address _entAdmin);
    event BartenderGranted(address _entity, address _bartender);
    event EntityAdminToggled(address _entity, address _entAdmin, bool _status);
    event BartenderToggled(address _entity, address _bartender, bool _status);

    event CollectionWhitelisted(address indexed _entity, address indexed _collection, uint256 indexed _chainId);
    event CollectionDelisted(address indexed _entity, address indexed _collection, uint256 indexed _chainId);

    event UserContractSet(address _newUserContract);

    event ManagerAdded(address _manager);
    event ManagerRemoved(address _manager);

    struct Operator {
        uint256 id;
        bool isActive;

        // Storage Gap
        uint256[5] __gap;
    }

    struct BlacklistDetails {
        // Timestamp after which the patron should be removed from blacklist
        uint256 end;

        // Storage Gap
        uint256[5] __gap;
    }

    struct EntityData {

        // Entity wallet address
        address walletAddress;
        
        // Flag to indicate whether entity is active or not
        bool isActive;

        // Data URI where file containing entity details resides
        string dataURI;

        // name of the entity
        string name;

        // Storage Gap
        uint256[20] __gap;

    }

    function toggleEntity() external returns(bool _status);

    function updateEntity(
        Area memory _area,
        string memory _name,
        string memory _dataURI,
        address _walletAddress
    ) external;

     function updateDataURI(
        string memory _dataURI
    ) external;
    

    function addEntityAdmin(address _entAdmin) external;

    function addBartender(address _bartender) external;

    function toggleEntityAdmin(address _entAdmin) external returns(bool _status);

    function toggleBartender(address _bartender) external returns(bool _status);

    function addPatronToBlacklist(address _patron, uint256 _end) external;

    function removePatronFromBlacklist(address _patron) external;

    function getEntityData() external view returns(EntityData memory);

    function getEntityAdminDetails(address _entAdmin) external view returns(Operator memory);

    function getBartenderDetails(address _bartender) external view returns(Operator memory);

    function getAllEntityAdmins(bool _onlyActive) external view returns(address[] memory);

    function getAllBartenders(bool _onlyActive) external view returns(address[] memory);
    
    function getLocationDetails() external view returns(string[] memory, uint256);

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function managers(address _manager) external returns(bool _isManager);
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ICollectionData {
    
    enum CollectionType {
        ANY,
        PASSPORT,
        OFFER,
        COLLECTION,
        BADGE,
        EVENT,
        PREMIUM_ACCESS,
        GAMEBOARD,
        PRIVATE_CHAT
    }

    enum OfferType {
        NOTANOFFER,
        FEATURED,
        REGULAR 
    }

    enum MintModel {
        REGULAR,
        SUBSCRIPTION
    }

    enum Category {
        OTHER,
        SPORTS,
        MUSIC,
        CELEBRITIES,
        EDUCATORS,
        BUSINESS,
        GAMING,
        ARTIST,
        FOUNDATIONS
    }

    struct CollectionData {

        /// @dev A collectible may optionally be linked to an entity
        /// @dev If its not then this will be address(0)
        address entity;

        /// @notice Flag that checks if a collectible should be minted when a collectible which it is linked to is minted
        /// @dev Eg: Offers/Events that should be airdropped along with passport for them
        /// @dev If true for a linked collectible, mintLinked can be called by the
        /// @dev dispatcher contract to mint collectibles linked to it
        bool mintWithLinked;

        /// @notice Price per collectible in this collection.
        /// @dev 6 decimals precision for FIAT representation. Eg: 24494022 = 24.494022 USD
        /// @dev Token decimals if price is in terms of ERC20 tokens
        uint256 price;

        /// @notice Max Purchase limit for this collection. 
        /// @dev Cannot be greater than maxMint, if an EXPASS is sold as an offer
        uint256 maxPurchase;

        /// @notice Start time from when the Collection will be on offer to patrons
        /// @dev Zero for non-time bound
        uint256 start;

        /// @notice End time from when the Collection will no longer be available for purchase
        /// @dev Zero for non-time bound
        uint256 end;

        /// @notice Flag to indicate the need for check in to place an order
        bool checkInNeeded;

        /// @notice Maximum tokens that can be minted for this collection
        /// @dev Used for passports
        /// @dev Zero for unlimited
        uint256 maxMint;

        /// @notice Type of offer represented by the collection(NOTANOFFER for passports and other collections that don't need to appear as Featured Offer in an EXPASS)
        OfferType offerType;

        /// @notice Non zero when the collection needs some criteria to be fulfilled on a passport
        address passport;

        /// @notice Min reward balance needed to get a collectible of this collection airdropped
        int256 minRewardBalance;

        /// @notice Min visits needed to get a collectible this collection airdropped
        uint256 minVisits;

        /// @notice Min friend visits needed to get a collectible this collection airdropped
        uint256 minFriendVisits;

        /// @notice A cap on the number of messages that a patron can send to a creator in case of PRIVATE_CHAT collection
        uint256 privateMessageCap;

        /// @dev Storage Gap
        uint256[19] __gap;

    }

    struct CollectionDataAdditional {
        /// @notice Max Balance a patron can hold for this collection.
        /// @dev Zero for 1
        uint256 maxBalance;

        /// @notice Is minted only when a linked collection is minted
        bool mintWithLinkedOnly;

        uint256 isCoupon; /// @dev zero = false, nonzero = true.

        MintModel mintModel; /// @dev The mint model for the collection. REGULAR, SUBSCRIPTION, etc.

        /// @notice Used for EXPASSES
        /// @notice Determines if a given collection is free or premium
        bool isPremium;

        /// @notice the category to which the collection belongs, used for filtering
        Category category;

        /// @dev Storage Gap
        uint256[17] __gap;
    }

    struct CollectibleDetails {
        uint256 id;
        uint256 mintTime; // timestamp
        bool isActive;
        int256 rewardBalance; // used for passports only
        uint256 visits; // // used for passports only
        uint256 friendVisits; // used for passports only
        // A flag indicating whether the collectible was redeemed
        // This can be useful in scenarios such as cancellation of orders
        // where the the collectible minted to patron is supposed to be burnt/demarcated
        // in some way when the payment is reversed to patron
        bool redeemed;

        // Storage Gap
        uint256[20] __gap;
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/collections/ICollectionData.sol";

interface ILoot8Marketplace is ICollectionData {

    enum ListingType {
        ALL,
        PUBLIC,
        PRIVATE
    }

    event MarketPlaceFeeSet(uint256 _mintFee, uint256 _saleFee);
    event ItemListedForSale(
        uint256 _listingId, 
        address _collection, 
        uint256 _tokenId, 
        address _paymentToken, 
        uint256 _price, 
        ListingType _listingType
    );
    event ItemDelisted(uint256 _listingId, address _collection, uint256 _tokenId);
    event ItemSold(address _collection, uint256 _tokenId);
    event AddedPaymentToken(address _token);
    event RemovedPaymentToken(address _token);
    event FeeRecepientChanged(address oldFeeRecepient, address feeRecipient);
    event SetRoyaltyManager(address _oldRoyaltyManager, address _royaltyManager);

    struct Listing {
        uint256 id;
        address seller;
        address passport;
        address collection;
        uint256 tokenId;
        address paymentToken;
        uint256 price;
        uint256 sellerShare;
        address payable[] royaltyRecipients;
        uint256[] amounts;
        uint256 fees;
        ListingType listingType;
        
        // Storage gap
        uint256[10] __gap;
    }

    function listingExists(address _collection, uint256 _tokenId, ListingType _listingType) external view returns(bool _exists, uint256 _listingId);
    function checkItemValidity(address _passport, address _collection) external returns(bool);
    function checkTraderEligibility(address _patron, address _passport, address _collection, ListingType _listingType) external view returns(bool);
    function listCollectible(
        address _passport,
        address _collection, 
        uint256 _tokenId,
        address _paymentToken, 
        uint256 _price, 
        bytes memory _signature,
        uint256 _expiry,
        ListingType _listingType
    ) external returns(uint256 _listingId);
    function delistCollectible(uint256 _listingId) external;
    function buy(uint256 _listingId, bytes memory _signature, uint256 _expiry) external;
    function getAllListingsForCollection(address _collection) external view returns(Listing[] memory _listings);
    function addPaymentToken(address _token) external;
    function removePaymentToken(address _token) external;
    function getListingById(uint256 _listingId) external view returns(Listing memory _listing);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../interfaces/finance/ILoot8Marketplace.sol";

interface ILoot8MarketplaceVerification {

    event ValidatorSet(address _validator, address _newValidator);
    event GovernorSet(address _governor, address _newGovernor);

    function setGovernor(address _newGovernor) external;

    function setValidator(address _newValidator) external;

    function getPatronCurrentNonce(address _patron) external view returns(uint256);

    function verify(
        address _patron,
        address _passport,
        address _collection,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price,
        string memory _action,
        ILoot8Marketplace.ListingType _listingType,
        string memory _message,
        uint256 _expiry,
        bytes memory _signature
    ) external view returns (bool);

    function verifyAndUpdateNonce(
        address _patron,
        address _passport,
        address _collection,
        uint256 _tokenId,
        address _paymentToken,
        uint256 _price,
        string memory _action,
        ILoot8Marketplace.ListingType _listingType,
        string memory _message,
        uint256 _expiry,
        bytes memory _signature
    ) external returns (bool);    
}

// SPDX-License-Identifier: MIT
// Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/IRoyaltyEngineV1.sol
pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value)
        external
        returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IRoyaltyManager {
    
    /// @dev possible sale types
    enum SaleType {
        PRIMARY,
        SECONDARY
    }

    enum SplitPhase {
        RECOVERY,
        NORMAL,
        /// @notice this is not an actual phase for an entity. It is only used to specify royalties for collections not associated with an entity
        GENERAL
    }

    /// @dev possible split types
    enum RoyaltyType {
        CREATOR,
        ENTITY,
        PLATFORM
    }

    /// @dev royalty configuration with splits
    struct RoyaltyConfiguration {
        uint256 id;
        
        /// @dev royalty specified in basis points(Eg: 10% = 1000, 80% = 8000, etc.)
        uint256 royalty;

        uint256[5] __gap;
    }

    /// @dev shares with recipients
    struct SplitConfiguration {
        uint256 id;
        /// @dev share of total for each recipient of royalty
        /// @dev all shares to be declared in basis points(Eg: 10% = 1000, 80% = 8000, etc.)
        uint256[] shares;
        address[] recipients;
        uint256[5] __gap;
    }

    event SwitchedPhase(address _entity);
    event MaxRecipientsSet(uint256 _maxRecipients);
    event SetSplitConfiguration(RoyaltyType _type, address _collection, address _entity, SaleType _saleType, SplitPhase _phase, uint256 _splitConfigurationId);
    event RoyaltySet(RoyaltyType _type, address _collection, address _entity, SaleType _saleType, SplitPhase _phase, uint256 _royalty);
    event RoyaltySplitExecuted(address _collection, SaleType _saleType, uint256 _price, address _paymentToken);

    function setMaxRecipients(uint256 _maxRecipients) external;
    function setSplit(
        RoyaltyType _type, 
        address _collection, 
        address _entity, 
        SaleType _saleType, 
        SplitPhase _phase, 
        uint256[] memory _shares, 
        address[] memory _recipients
    ) external returns(uint256 _splitConfigurationId);
    function setSplit(
        RoyaltyType _type, 
        address _collection, 
        address _entity, 
        SaleType _saleType, 
        SplitPhase _phase, 
        uint256 _splitConfigurationId
    ) external;
    function setRoyalty(RoyaltyType _type, address _collection, address _entity, SaleType _saleType, SplitPhase _phase, uint256 _royalty) external;
    function getRoyalty(address _collection, SaleType _saleType) external view returns(
        uint256 _totalRoyalty, 
        RoyaltyConfiguration memory _creatorRoyalty, 
        RoyaltyConfiguration memory _entityRoyalty, 
        RoyaltyConfiguration memory _platformRoyalty    
    );
    function getRoyalty(address _collection, SaleType _saleType, SplitPhase _phase) external view returns(
        uint256 _totalRoyalty, 
        RoyaltyConfiguration memory _creatorRoyalty, 
        RoyaltyConfiguration memory _entityRoyalty, 
        RoyaltyConfiguration memory _platformRoyalty    
    );

    function splitRoyalty(address _collection, SaleType _saleType, uint256 _price, address _paymentToken) external;
    function royaltyDenominator() external view returns(uint256);
    function switchPhase(address _entity) external;
    function getRoyaltyConfiguration(uint256 _configId) external view returns(uint256 _id, uint256 _royalty);
    function getSplitConfiguration(uint256 _configId) external view returns(uint256 _id, uint256[] memory _shares, address[] memory _recipients);
    function royaltyConfigAllowedForCollection(address _collection) external view returns(bool _allowed);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ISubscriptionManager {
    struct SubscriptionConfig {
        address creatorFeeReceiver;
        // in loot8tokenDecimals
        uint256 floorPrice;
        // percentages in basis points in loot8decimals
        uint256 platformFeePercent;
        uint256 peopleFeePercent;
        bool subscriptionEnabled;
        bool subscriptionHasStarted;
        // percentages in basis points in loot8decimals
        uint256 priceRate;
        uint256[4] __gap;
    }

    event Trade(
        address _trader,
        address _collection,
        bool _isBuy,
        uint256 _collectionAmount,
        uint256 _price
    );

    event SubscriptionConfigSet(
        address _collection,
        uint256 _price,
        bool _subscriptionEnabled,
        bool _subscriptionHasStarted
    );

    event SetRoyaltyManager(address _oldRoyaltyManager, address _royaltyManager);

    function setCollectionSubscriptionConfig(
        address _collection,
        address _peopleFeeReceiver,
        uint256 _floorPrice,
        uint256 _priceRate,
        bool _subscriptionEnabled,
        bool _startSubscriptions
    ) external;

    function setSubscriptionEnabled(address _collection, bool _subscriptionEnabled) external;

    function subscribe(address _collection) external;
    function unsubscribe(address _collection, uint256 _tokenId) external;

    function airdropSubscription(address patron, address _collection) external returns(uint256 _collectibleId, string memory _message);
    function passedPreAirdropChecks(address patron, address _collection) external view returns(bool _result, string memory _message);

    function unstakeOnMarketplaceSell(address _collection, uint256 _tokenId) external;

    function isSubscribeable(address _collection) external view returns (bool);
    function hasValidSubscriptionConfig(address _collection) external view returns (bool);

    function getSubscriptionPrice(address _collection, uint256 _supply) external view returns (uint256 _price, uint256 _fees);
    function getUnsubscriptionPrice(address _collection, uint256 _supply) external view returns (uint256 _price);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILocationBased {

    struct Area {
        // Area Co-ordinates.
        // For circular area, points[] length = 1 and radius > 0
        // For arbitrary area, points[] length > 1 and radius = 0
        // For arbitrary areas UI should connect the points with a
        // straight line in the same sequence as specified in the points array
        string[] points; // Each element in this array should be specified in "lat,long" format
        uint256 radius; // Unit: Meters. 2 decimals(5000 = 50 meters)
    }    
    
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ICollectionHelper {
    event ContractURIUpdated(address _collection, string oldContractURI, string _contractURI);
    event CollectionsLinked(address indexed _collectible1, address indexed _collectible2);
    event CollectionsDelinked(address indexed _collectible1, address indexed _collectible2);
    event TradeablitySet(address _collection, bool _privateTradeAllowed, bool _publicTradeAllowed);
    event MarketplaceOpsSet(address _collection, bool _allowMarketplaceOps);

    struct MarketplaceConfig {
        // Is the collection tradeable on a private marketplace
        // Entity Admin may choose to allow or not allow a collection to be traded privately
        bool privateTradeAllowed;

        // Is the collection tradeable on a public marketplace
        // Entity Admin may choose to allow or not allow a collection to be traded publicly
        bool publicTradeAllowed;

        // Is this collection allowed to be traded on the Loot8 marketplace.
        // Governor may choose to allow or not allow a collection to be traded on LOOT8
        bool allowMarketplaceOps;

        uint256[20] __gap;
    }

    function updateContractURI(address _collection, string memory _contractURI) external;
    function calculateRewards(address _collection, uint256 _quantity) external view returns(uint256);
    function linkCollections(address _collection1, address[] calldata _arrayOfCollections) external;
    function delinkCollections(address _collection1, address _collection2) external;
    function areLinkedCollections(address _collection1, address _collection2) external view returns(bool _areLinked);
    function getAllLinkedCollections(address _collection) external view returns (address[] memory);
    function setTradeablity(address _collection, bool _privateTradeAllowed, bool _publicTradeAllowed) external;
    function setAllowMarkeplaceOps(address _collection, bool _allowMarketplaceOps) external;
    function getMarketplaceConfig(address _collection) external view returns(MarketplaceConfig memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/access/IDAOAuthority.sol";
import "../../interfaces/location/ILocationBased.sol";
import "../../interfaces/misc/IExternalCollectionManager.sol";
import "../../interfaces/collections/ICollectionData.sol";


interface ICollectionManager is ICollectionData, ILocationBased {

    event CollectionAdded(address indexed _collection, CollectionType indexed _collectionType);

    event CollectionDataUpdated(address _collection);

    event CollectionRetired(address indexed _collection, CollectionType indexed _collectionType);

    event CollectibleMinted(address indexed _collection, uint256 indexed _collectibleId, CollectionType indexed _collectionType);

    event CollectibleToggled(address indexed _collection, uint256 indexed _collectibleId, bool _status);

    event CreditRewards(address indexed _collection, uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event BurnRewards(address indexed _collection, uint256 indexed _collectibleId, address indexed _patron, uint256 _amount);

    event Visited(address indexed _collection, uint256 indexed _collectibleId);

    event FriendVisited(address indexed _collection, uint256 indexed _collectibleId);

    event CollectionMintWithLinkedToggled(address indexed _collection, bool indexed _mintWithLinked);

    event CollectionWhitelisted(address indexed _passport, address indexed _source, uint256 indexed _chainId);

    event CollectionDelisted(address indexed _passport, address indexed _source, uint256 indexed _chainId);

    function addCollection(
        address _collection,
        uint256 _chainId,
        CollectionType _collectionType,
        CollectionData calldata _collectionData,
        CollectionDataAdditional calldata _collectionDataAdditional,
        Area calldata _area,
        bool _tradability
    ) external;

    function updateCollection(
        address _collection,
        CollectionData calldata _collectionData,
        CollectionDataAdditional calldata _collectionDataAdditional,
        Area calldata _area
    ) external;

    function mintCollectible(
        address _patron,
        address _collection
    ) external returns(uint256 _collectibleId);

    function toggleMintWithLinked(address _collection) external;

    function setCollectibleRedemption(address _collection, uint256 _collectibleId) external;

    function isCollection(address _collection) external view returns(bool);
    
    function isRetired(address _collection, uint256 _collectibleId) external view returns(bool);

    function checkCollectionActive(address _collection) external view returns(bool);

    function getCollectibleDetails(address _collection, uint256 _collectibleId) external view returns(CollectibleDetails memory);

    function getCollectionType(address _collection) external view returns(CollectionType);

    function getCollectionData(address _collection) external view returns(CollectionData memory _collectionData);

    function getLocationDetails(address _collection) external view returns(string[] memory, uint256);

    function getCollectionsForEntity(address _entity, CollectionType _collectionType, bool _onlyActive) external view returns(IExternalCollectionManager.ContractDetails[] memory _entityCollections);

    function getAllCollectionsWithChainId(CollectionType _collectionType, bool _onlyActive) external view returns(IExternalCollectionManager.ContractDetails[] memory _allCollections);
    
    function getAllCollectionsForPatron(CollectionType _collectionType, address _patron, bool _onlyActive) external view returns(address[] memory _allCollections);

    function getCollectionChainId(address _collection) external view returns(uint256);

    function getCollectionInfo(address _collection) external view 
        returns (string memory _name,
        string memory _symbol,
        string memory _dataURI,
        CollectionData memory _data,
        CollectionDataAdditional memory _additionCollectionData,
        bool _isActive,
        string[] memory _areaPoints,
        uint256 _areaRadius,
        address[] memory _linkedCollections,
        CollectionType _collectionType);

    function getAllTokensForPatron(address _collection, address _patron) external view returns(uint256[] memory _patronTokenIds);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/collections/ICollectionData.sol";

interface IExternalCollectionManager is ICollectionData {
    event CollectionWhitelisted(address _passport, address _source, uint256 _chainId);
    event CollectionDelisted(address _passport, address _source, uint256 _chainId);

    struct ContractDetails {
        // Contract address
        address source;

        // ChainId where the contract deployed
        uint256 chainId;

        // Storage Gap
        uint256[5] __gap;
    }

    function whitelistCollection(address _source, uint256 _chainId, address _passport) external;

    function getWhitelistedCollectionsForPassport(address _passport) external view returns(ContractDetails[] memory _wl);

    function delistCollection(address _source, uint256 _chainId, address _passport) external;

    function isWhitelistedCollection(address _collection) external view returns(bool _whitelisted, address _passport);

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IUser {

    /* ========== EVENTS ========== */
    event UserCreated(address indexed _walletAddress, uint256 indexed _userId, string _name);
    event UserRemoved(address indexed _walletAddress);

    event NameChanged(address indexed _user, string _name);
    event AvatarURIChanged(address indexed _user, string _avatarURI);
    event DataURIChanged(address indexed _user, string _dataURI);

    event Banned(address indexed _user);
    event BanLifted(address indexed _user);

    event LinkedExternalAccountForUser(address _user, address _account);
    event DeLinkedExternalAccountForUser(address _user, address _account);

    event ThirdPartyProfileUrlUpdated(address _user);
    event MigratorSet(address _migrator);

    struct UserAttributes {
        uint256 id;
        string name;
        address wallet;
        string avatarURI;
        string dataURI;
        address[] adminAt; // List of entities where user is an Admin
        address[] bartenderAt; // List of entities where user is a bartender
        uint256[20] __gap;
    }

    function register(string memory _name, address walletAddress, string memory _avatarURI, string memory _dataURI) external returns (uint256);

    function batchCreate(
        uint256[] memory _ids,
        string[] memory _names,
        address[] memory _walletAddresses,
        string[] memory _avatarURIs,
        string[] memory _dataURIs
    ) external;
    
    function deregister() external;

    function changeName(string memory _name) external;
    
    function getAllUsers(bool _includeBanned) external view returns(UserAttributes[] memory _users);

    function getBannedUsers() external view returns(UserAttributes[] memory _users);

    function isValidPermittedUser(address _user) external view returns(bool);

    function addEntityToOperatorsList(address _user, address _entity, bool _admin) external;

    function removeEntityFromOperatorsList(address _user, address _entity, bool _admin) external;

    function isUserOperatorAt(address _user, address _entity, bool _admin) external view returns(bool, uint256);

    function linkExternalAccount(address _account, bytes memory _signature) external;

    function delinkExternalAccount(address _account) external;

    function isLinkedAccount(address _user, address _account) external view returns(bool);

    function setMigrator(address _migrator) external;
}