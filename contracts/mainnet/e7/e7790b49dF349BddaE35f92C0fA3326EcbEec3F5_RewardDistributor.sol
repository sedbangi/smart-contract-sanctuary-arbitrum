// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import { IERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import { MerkleProof } from "./MerkleProof.sol";

contract MerkleAirdrop is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * Errors
   */
  error MerkleAirdrop_Initialized();
  error MerkleAirdrop_AlreadyClaimed();
  error MerkleAirdrop_InvalidProof();
  error MerkleAirdrop_CannotInitFutureWeek();
  error MerkleAirdrop_Unauthorized();

  /**
   * Events
   */
  // This event is triggered whenever a call to #claim succeeds.
  event Claimed(uint256 weekNumber, address account, uint256 amount);
  event SetFeeder(address oldFeeder, address newFeeder);
  event Init(uint256 weekNumber, bytes32 merkleRoot);

  /**
   * States
   */

  address public token;
  address public feeder;
  mapping(uint256 => bytes32) public merkleRoot; // merkleRoot mapping by week timestamp
  mapping(uint256 => bool) public initialized;

  // This is a packed array of booleans.
  mapping(uint256 => mapping(address => bool)) public isClaimed; // Track the status is user already claimed in the given weekTimestamp

  /**
   * Modifiers
   */
  modifier onlyFeederOrOwner() {
    if (msg.sender != feeder && msg.sender != owner()) revert MerkleAirdrop_Unauthorized();
    _;
  }

  /**
   * Initialize
   */

  function initialize(address token_, address feeder_) external initializer {
    OwnableUpgradeable.__Ownable_init();

    token = token_;
    feeder = feeder_;
  }

  /**
   * Core Functions
   */

  function init(uint256 weekNumber, bytes32 merkleRoot_) external onlyFeederOrOwner {
    uint256 currentWeekNumber = block.timestamp / (60 * 60 * 24 * 7);
    if (currentWeekNumber <= weekNumber) revert MerkleAirdrop_CannotInitFutureWeek();
    if (initialized[weekNumber]) revert MerkleAirdrop_Initialized();

    merkleRoot[weekNumber] = merkleRoot_;
    initialized[weekNumber] = true;

    emit Init(weekNumber, merkleRoot_);
  }

  function claim(
    uint256 weekNumber,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external {
    _claim(weekNumber, account, amount, merkleProof);
  }

  function bulkClaim(
    uint256[] calldata weekNumbers,
    address[] calldata accounts,
    uint256[] calldata amounts,
    bytes32[][] calldata merkleProof
  ) external {
    uint256 _len = weekNumbers.length;
    for (uint256 i; i < _len; ) {
      _claim(weekNumbers[i], accounts[i], amounts[i], merkleProof[i]);
      unchecked {
        ++i;
      }
    }
  }

  function emergencyWithdraw(address receiver) external onlyOwner {
    IERC20Upgradeable tokenContract = IERC20Upgradeable(token);
    uint256 balance = tokenContract.balanceOf(address(this));
    tokenContract.safeTransfer(receiver, balance);
  }

  /**
   * Internal Functions
   */

  function _claim(
    uint256 weekNumber,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) internal {
    if (isClaimed[weekNumber][account]) revert MerkleAirdrop_AlreadyClaimed();

    // Verify the merkle proof.
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
    if (!MerkleProof.verify(merkleProof, merkleRoot[weekNumber], leaf))
      revert MerkleAirdrop_InvalidProof();

    // Mark it claimed and send the token.
    isClaimed[weekNumber][account] = true;

    IERC20Upgradeable(token).safeTransfer(account, amount);

    emit Claimed(weekNumber, account, amount);
  }

  /**
   * Setter
   */

  function setFeeder(address newFeeder) external onlyOwner {
    emit SetFeeder(feeder, newFeeder);
    feeder = newFeeder;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

library MerkleProof {
  /**
   * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
   * defined by `root`. For this, a `proof` must be provided, containing
   * sibling hashes on the branch from the leaf to the root of the tree. Each
   * pair of leaves and each pair of pre-images are assumed to be sorted.
   */
  function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGmxV2ExchangeRouter {
  function sendWnt(address receiver, uint256 amount) external payable;

  function sendTokens(address token, address receiver, uint256 amount) external payable;

  /// @dev CreateDepositParams struct used in createDeposit to avoid stack too deep.
  /// @param receiver the address to send the market tokens to
  /// @param callbackContract the callback contract
  /// @param uiFeeReceiver the ui fee receiver
  /// @param market the market to deposit into
  /// @param minMarketTokens the minimum acceptable number of liquidity tokens
  /// @param shouldUnwrapNativeToken whether to unwrap the native token when
  /// sending funds back to the user in case the deposit gets cancelled
  /// @param executionFee the execution fee for keepers
  /// @param callbackGasLimit the gas limit for the callbackContract
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

  function createDeposit(CreateDepositParams calldata params) external returns (bytes32);

  /// @dev CreateWithdrawalParams struct used in createWithdrawal to avoid stack too deep.
  /// @param receiver The address that will receive the withdrawal tokens.
  /// @param callbackContract The contract that will be called back.
  /// @param market The market on which the withdrawal will be executed.
  /// @param minLongTokenAmount The minimum amount of long tokens that must be withdrawn.
  /// @param minShortTokenAmount The minimum amount of short tokens that must be withdrawn.
  /// @param shouldUnwrapNativeToken Whether the native token should be unwrapped when executing the withdrawal.
  /// @param executionFee The execution fee for the withdrawal.
  /// @param callbackGasLimit The gas limit for calling the callback contract.
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

  function createWithdrawal(CreateWithdrawalParams calldata params) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGasService {
  function adjustSubsidizedExecutionFeeValue(int256 deltaValueE30) external;

  function subsidizedExecutionFeeValue() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

interface IWNative {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function mint(address to, uint256 value) external;

  function balanceOf(address wallet) external returns (uint256);
}

// SPDX-License-Identifier: LZBL-1.2
// Taken from https://github.com/LayerZero-Labs/LayerZero-v2/blob/982c549236622c6bb9eaa6c65afcf1e0e559b624/protocol/contracts/libs/Transfer.sol
// Modified `pragma solidity ^0.8.20` to `pragma solidity 0.8.18` for compatibility without chaging the codes

pragma solidity 0.8.18;

import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

library Transfer {
  using SafeERC20 for IERC20;

  address internal constant ADDRESS_ZERO = address(0);

  error Transfer_NativeFailed(address _to, uint256 _value);
  error Transfer_ToAddressIsZero();

  function native(address _to, uint256 _value) internal {
    if (_to == ADDRESS_ZERO) revert Transfer_ToAddressIsZero();
    (bool success, ) = _to.call{ value: _value }("");
    if (!success) revert Transfer_NativeFailed(_to, _value);
  }

  function token(address _token, address _to, uint256 _value) internal {
    if (_to == ADDRESS_ZERO) revert Transfer_ToAddressIsZero();
    IERC20(_token).safeTransfer(_to, _value);
  }

  function nativeOrToken(address _token, address _to, uint256 _value) internal {
    if (_token == ADDRESS_ZERO) {
      native(_to, _value);
    } else {
      token(_token, _to, _value);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGmxRewardRouterV2 {
  function mintAndStakeGlp(
    address _token,
    uint256 _amount,
    uint256 _minUsdg,
    uint256 _minGlp
  ) external returns (uint256);

  function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

  function unstakeAndRedeemGlp(
    address _tokenOut,
    uint256 _glpAmount,
    uint256 _minOut,
    address _receiver
  ) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.

pragma solidity 0.8.18;

interface IRewarder {
  function name() external view returns (string memory);

  function rewardToken() external view returns (address);

  function rewardRate() external view returns (uint256);

  function onDeposit(address user, uint256 shareAmount) external;

  function onWithdraw(address user, uint256 shareAmount) external;

  function onHarvest(address user, address receiver) external;

  function pendingReward(address user) external view returns (uint256);

  function feed(uint256 feedAmount, uint256 duration) external;

  function feedWithExpiredAt(uint256 feedAmount, uint256 expiredAt) external;

  function accRewardPerShare() external view returns (uint128);

  function userRewardDebts(address user) external view returns (int256);

  function lastRewardTime() external view returns (uint64);

  function setFeeder(address feeder_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISwitchCollateralRouter {
  function execute(uint256 _amount, address[] calldata _path) external returns (uint256);
  function setDexterOf(address _tokenIn, address _tokenOut, address _switchCollateralExt) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV3Router {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  function exactInputSingle(
    ExactInputSingleParams memory params
  ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IVaultStorage {
  /**
   * Errors
   */
  error IVaultStorage_NotWhiteListed();
  error IVaultStorage_TraderTokenAlreadyExists();
  error IVaultStorage_TraderBalanceRemaining();
  error IVaultStorage_ZeroAddress();
  error IVaultStorage_HLPBalanceRemaining();
  error IVaultStorage_Forbidden();
  error IVaultStorage_TargetNotContract();
  error IVaultStorage_BadLen();
  error IVaultStorage_InvalidAddress();

  /**
   * Functions
   */
  function totalAmount(address _token) external returns (uint256);

  function hlpLiquidityDebtUSDE30() external view returns (uint256);

  function traderBalances(address _trader, address _token) external view returns (uint256 amount);

  function getTraderTokens(address _trader) external view returns (address[] memory);

  function protocolFees(address _token) external view returns (uint256);

  function fundingFeeReserve(address _token) external view returns (uint256);

  function devFees(address _token) external view returns (uint256);

  function hlpLiquidity(address _token) external view returns (uint256);

  function pullToken(address _token) external returns (uint256);

  function addFee(address _token, uint256 _amount) external;

  function addHLPLiquidity(address _token, uint256 _amount) external;

  function withdrawFee(address _token, uint256 _amount, address _receiver) external;

  function removeHLPLiquidity(address _token, uint256 _amount) external;

  function pushToken(address _token, address _to, uint256 _amount) external;

  function addFundingFee(address _token, uint256 _amount) external;

  function removeFundingFee(address _token, uint256 _amount) external;

  function addHlpLiquidityDebtUSDE30(uint256 _value) external;

  function removeHlpLiquidityDebtUSDE30(uint256 _value) external;

  function increaseTraderBalance(address _subAccount, address _token, uint256 _amount) external;

  function decreaseTraderBalance(address _subAccount, address _token, uint256 _amount) external;

  function payHlp(address _trader, address _token, uint256 _amount) external;

  function setServiceExecutors(address _executorAddress, bool _isServiceExecutor) external;

  function borrowFundingFeeFromHlpToTrader(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external;

  function repayFundingFeeDebtFromTraderToHlp(
    address _trader,
    address _token,
    uint256 _fundingFeeAmount,
    uint256 _fundingFeeValue
  ) external;

  function cook(address _token, address _target, bytes calldata _callData) external returns (bytes memory);

  function setStrategyAllowance(address _token, address _strategy, address _target) external;

  function setStrategyFunctionSigAllowance(address _token, address _strategy, bytes4 _target) external;

  function globalBorrowingFeeDebt() external returns (uint256);

  function globalLossDebt() external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// This code is made available under the terms and conditions of the Business Source License 1.1 (BUSL-1.1).
// The act of publishing this code is driven by the aim to promote transparency and facilitate its utilization for educational purposes.
pragma solidity 0.8.18;

import { IERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import { MerkleAirdrop } from "src/airdrop/MerkleAirdrop.sol";

// Interfaces
import { IVaultStorage } from "src/staking/interfaces/IVaultStorage.sol";
import { IUniswapV3Router } from "src/staking/interfaces/IUniswapV3Router.sol";
import { IRewarder } from "src/staking/interfaces/IRewarder.sol";
import { IGmxRewardRouterV2 } from "src/staking/interfaces/IGmxRewardRouterV2.sol";
import { ISwitchCollateralRouter } from "src/staking/interfaces/ISwitchCollateralRouter.sol";
import { IGmxV2ExchangeRouter } from "src/interfaces/gmx-v2/IGmxV2ExchangeRouter.sol";
import { IWNative } from "src/interfaces/IWNative.sol";
import { Transfer as TransferLib } from "src/libraries/Transfer.sol";
import { IGasService } from "src/interfaces/IGasService.sol";
import { IERC20 } from "lib/forge-std/src/interfaces/IERC20.sol";

contract RewardDistributor is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * Events
   */
  event LogSetFeeder(address oldValue, address newValue);
  event LogSetUniV3SwapFee(uint24 oldValue, uint24 newValue);
  event LogProtocolFee(uint256 weekTimestamp, uint256 stakingAmount);
  event LogSetUniFeeBps(address[] rewardTokens, address[] swapTokens, uint24[] uniV3FeeBps);
  event LogSetParams(
    address rewardToken,
    address vaultStorage,
    address poolRouter,
    address rewardRouter,
    address hlpStakingProtocolRevenueRewarder,
    address hmxStakingProtocolRevenueRewarder,
    uint256 plpStakingBps,
    address merkleAirdrop,
    address switchCollateralRouter
  );
  event LogSetReferralRevenueMaxThreshold(uint256 oldThreshold, uint256 newThreshold);
  event LogSetTokenSwapPath(address[] token, address[][] path);
  event LogGMWithdrawalCreated(bytes32 gmxOrderKey, WithdrawalParams withdrawParam);
  event LogSetGmConfigs(address _gmxV2ExchangeRouter, address _gmxV2WithdrawalVault, address _weth);
  event LogSetDistributionBpsParams(
    uint256 hlpStakingBps,
    uint256 protocolOwnedLiquidityBps,
    address protocolOwnedLiquidityTreasury
  );
  event LogSetGasService(address _gasService);
  event LogSetTreasury(address _treasury);

  /**
   * Errors
   */
  error RewardDistributor_NotFeeder();
  error RewardDistributor_BadParams();
  error RewardDistributor_InvalidArray();
  error RewardDistributor_InvalidSwapFee();
  error RewardDistributor_ReferralRevenueExceedMaxThreshold();
  error RewardDistributor_BadReferralRevenueMaxThreshold();
  error RewardDistributor_UnevenTokenSwapPath();

  /**
   * Struct
   */
  struct WithdrawalParams {
    address market;
    uint256 amount;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    uint256 gasLimit;
    bool withdrawProtocolRevenue;
  }

  /**
   * States
   */

  uint256 public constant BPS = 10000;

  /// @dev Token addreses
  address public rewardToken; // the token to be fed to rewarder
  address public sglp;

  /// @dev Pool and its companion addresses
  address public poolRouter;
  address public hlpStakingProtocolRevenueRewarder;

  address public vaultStorage;
  address public feeder;
  MerkleAirdrop public merkleAirdrop;
  IGmxRewardRouterV2 public rewardRouter;

  /// @dev Distribution weights
  uint256 public hlpStakingBps;

  // rewardToken => swapToken => feeBps
  mapping(address => mapping(address => uint24)) public uniswapV3SwapFeeBPSs;

  address public hmxStakingProtocolRevenueRewarder;

  uint256 public referralRevenueMaxThreshold; // in BPS (10000)

  // For SwitchCollateral
  mapping(address token => address[] path) public tokenSwapPath;
  ISwitchCollateralRouter public switchCollateralRouter;

  // GMX V2
  IGmxV2ExchangeRouter public gmxV2ExchangeRouter;
  address public gmxV2WithdrawalVault;
  IWNative public weth;

  uint256 public protocolOwnedLiquidityBps;
  address public protocolOwnedLiquidityTreasury;

  address public treasury;
  IGasService public gasService;

  /**
   * Modifiers
   */
  modifier onlyFeeder() {
    if (msg.sender != feeder) revert RewardDistributor_NotFeeder();
    _;
  }

  /**
   * Initialize
   */

  function initialize(
    address _rewardToken,
    address _vaultStorage,
    address _poolRouter,
    address _sglp,
    IGmxRewardRouterV2 _rewardRouter,
    address _hlpStakingProtocolRevenueRewarder,
    address _hmxStakingProtocolRevenueRewarder,
    uint256 _hlpStakingBps,
    MerkleAirdrop _merkleAirdrop,
    uint256 _referralRevenueMaxThreshold,
    ISwitchCollateralRouter _switchCollateralRouter
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    rewardToken = _rewardToken;
    vaultStorage = _vaultStorage;
    sglp = _sglp;
    poolRouter = _poolRouter;
    rewardRouter = _rewardRouter;
    switchCollateralRouter = _switchCollateralRouter;
    hlpStakingProtocolRevenueRewarder = _hlpStakingProtocolRevenueRewarder;
    hmxStakingProtocolRevenueRewarder = _hmxStakingProtocolRevenueRewarder;
    hlpStakingBps = _hlpStakingBps;
    merkleAirdrop = _merkleAirdrop;

    referralRevenueMaxThreshold = _referralRevenueMaxThreshold;
  }

  /**
   * Core Functions
   */

  function claimAndSwap(address[] memory tokens) external onlyFeeder {
    _claimAndSwap(tokens);
  }

  function feedProtocolRevenue(
    uint256 feedingExpiredAt,
    uint256 weekTimestamp,
    uint256 referralRevenueAmount,
    bytes32 merkleRoot
  ) external onlyFeeder {
    _feedProtocolRevenue(feedingExpiredAt, weekTimestamp, referralRevenueAmount, merkleRoot);
  }

  function claimAndFeedProtocolRevenue(
    address[] memory tokens,
    uint256 feedingExpiredAt,
    uint256 weekTimestamp,
    uint256 referralRevenueAmount,
    bytes32 merkleRoot
  ) external onlyFeeder {
    _claimAndSwap(tokens);
    _feedProtocolRevenue(feedingExpiredAt, weekTimestamp, referralRevenueAmount, merkleRoot);
  }

  /**
   * Internal Functions
   */

  function _claimAndSwap(address[] memory tokens) internal {
    uint256 length = tokens.length;
    for (uint256 i = 0; i < length; ) {
      if (IVaultStorage(vaultStorage).protocolFees(tokens[i]) > 0) {
        // 1. Withdraw protocol revenue
        _withdrawProtocolRevenue(tokens[i]);
      }
      uint256 tokenBalance = IERC20Upgradeable(tokens[i]).balanceOf(address(this));
      if (tokenBalance > 0) {
        // 2. Swap those revenue (along with surplus) to RewardToken Token
        _swapTokenToRewardToken(tokens[i], tokenBalance);
      }

      unchecked {
        i++;
      }
    }
  }

  function _withdrawProtocolRevenue(address _token) internal {
    // Withdraw the all max amount revenue from the pool
    IVaultStorage(vaultStorage).withdrawFee(
      _token,
      IVaultStorage(vaultStorage).protocolFees(_token),
      address(this)
    );
  }

  function _swapTokenToRewardToken(address token, uint256 amount) internal {
    // If no token, no need to swap
    if (amount == 0) return;

    // If token is already reward token, no need to swap
    if (token == rewardToken) return;

    // Use SwitchCollateralRouter for every swap
    IERC20Upgradeable(token).safeTransfer(address(switchCollateralRouter), amount);
    switchCollateralRouter.execute(amount, tokenSwapPath[token]);
  }

  function _feedProtocolRevenue(
    uint256 feedingExpiredAt,
    uint256 weekTimestamp,
    uint256 referralRevenueAmount,
    bytes32 merkleRoot
  ) internal {
    // Transfer referral revenue to merkle airdrop address for distribution
    uint256 totalProtocolRevenue = IERC20Upgradeable(rewardToken).balanceOf(address(this));

    // totalProtocolRevenue * referralRevenueMaxThreshold / 10000 < referralRevenueAmount
    if (totalProtocolRevenue * referralRevenueMaxThreshold < referralRevenueAmount * 10000)
      revert RewardDistributor_ReferralRevenueExceedMaxThreshold();

    if (referralRevenueAmount > 0) {
      merkleAirdrop.init(weekTimestamp, merkleRoot);
      IERC20Upgradeable(rewardToken).safeTransfer(address(merkleAirdrop), referralRevenueAmount);
    }

    // At this point, we got a portion of reward tokens for protocol revenue.
    // Feed reward to both rewarders
    uint256 totalRewardAmount = _feedRewardToRewarders(feedingExpiredAt);

    emit LogProtocolFee(weekTimestamp, totalRewardAmount);
  }

  function _feedRewardToRewarders(uint256 feedingExpiredAt) internal returns (uint256) {
    uint256 totalRewardAmount = IERC20Upgradeable(rewardToken).balanceOf(address(this));

    // Normalize into the decimals of reward token
    // Reward token is stablecoin USDC. We assume 1 USDC = 1 USD here.
    uint256 decimalsDiff = 30 - IERC20(rewardToken).decimals();
    uint256 subsidizedExecutionFeeAmount = gasService.subsidizedExecutionFeeValue() /
      (10 ** decimalsDiff);

    // If we can subsidize, then deduct from the total reward
    if (subsidizedExecutionFeeAmount < totalRewardAmount) {
      unchecked {
        totalRewardAmount -= subsidizedExecutionFeeAmount;
      }
    } else {
      // If the reward is not enough, we don't subsudize at all
      subsidizedExecutionFeeAmount = 0;
    }
    uint256 hlpStakingRewardAmount = (totalRewardAmount * hlpStakingBps) / BPS;
    uint256 protocolOwnedLiquidityAmount = (totalRewardAmount * protocolOwnedLiquidityBps) / BPS;
    uint256 hmxStakingRewardAmount = totalRewardAmount -
      hlpStakingRewardAmount -
      protocolOwnedLiquidityAmount;

    // Approve and feed to HLPStaking
    IERC20Upgradeable(rewardToken).approve(
      hlpStakingProtocolRevenueRewarder,
      hlpStakingRewardAmount
    );
    IRewarder(hlpStakingProtocolRevenueRewarder).feedWithExpiredAt(
      hlpStakingRewardAmount,
      feedingExpiredAt
    );

    // Approve and feed to HMXStaking
    IERC20Upgradeable(rewardToken).approve(
      hmxStakingProtocolRevenueRewarder,
      hmxStakingRewardAmount
    );
    IRewarder(hmxStakingProtocolRevenueRewarder).feedWithExpiredAt(
      hmxStakingRewardAmount,
      feedingExpiredAt
    );

    // Send to Protocol Owned Liquidity treasury
    IERC20Upgradeable(rewardToken).safeTransfer(
      protocolOwnedLiquidityTreasury,
      protocolOwnedLiquidityAmount
    );

    // Send the subsidized execution fee to dev treasury
    if (subsidizedExecutionFeeAmount != 0) {
      gasService.adjustSubsidizedExecutionFeeValue(
        -int256(subsidizedExecutionFeeAmount * (10 ** decimalsDiff))
      );
      IERC20Upgradeable(rewardToken).safeTransfer(treasury, subsidizedExecutionFeeAmount);
    }

    return totalRewardAmount;
  }

  function createGmWithdrawalOrders(
    WithdrawalParams[] calldata _withdrawParams,
    uint256 _executionFee
  ) external payable onlyFeeder returns (bytes32[] memory _gmxOrderKeys) {
    uint256 _withdrawParamsLen = _withdrawParams.length;
    _gmxOrderKeys = new bytes32[](_withdrawParamsLen);

    WithdrawalParams memory _withdrawParam;
    bytes32 _gmxOrderKey;
    for (uint256 i = 0; i < _withdrawParamsLen; ) {
      _withdrawParam = _withdrawParams[i];

      // withdraw GM(x) from protocol revenue
      if (_withdrawParam.withdrawProtocolRevenue) {
        _withdrawProtocolRevenue(_withdrawParam.market);
      }

      // Send GM token to GMX V2 Vault for withdrawal
      IERC20Upgradeable(_withdrawParam.market).safeTransfer(
        gmxV2WithdrawalVault,
        _withdrawParam.amount == 0
          ? IERC20Upgradeable(_withdrawParam.market).balanceOf(address(this))
          : _withdrawParam.amount
      );

      // Taken WETH from caller and send to gmxV2WithdrawalVault for execution fee
      weth.deposit{ value: _executionFee }();
      IERC20Upgradeable(address(weth)).safeTransfer(gmxV2WithdrawalVault, _executionFee);
      // Create a withdrawal order
      _gmxOrderKey = gmxV2ExchangeRouter.createWithdrawal(
        IGmxV2ExchangeRouter.CreateWithdrawalParams({
          receiver: address(this),
          callbackContract: address(0),
          uiFeeReceiver: address(0),
          market: _withdrawParam.market,
          longTokenSwapPath: new address[](0),
          shortTokenSwapPath: new address[](0),
          minLongTokenAmount: _withdrawParam.minLongTokenAmount,
          minShortTokenAmount: _withdrawParam.minShortTokenAmount,
          shouldUnwrapNativeToken: false,
          executionFee: _executionFee,
          callbackGasLimit: _withdrawParam.gasLimit
        })
      );
      // Update returner
      _gmxOrderKeys[i] = _gmxOrderKey;

      emit LogGMWithdrawalCreated(_gmxOrderKey, _withdrawParam);

      unchecked {
        ++i;
      }
    }
  }

  function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
    TransferLib.nativeOrToken(_token, _to, _amount);
  }

  /**
   * Setter
   */

  function setFeeder(address newFeeder) external onlyOwner {
    emit LogSetFeeder(feeder, newFeeder);
    feeder = newFeeder;
  }

  function setUniFeeBps(
    address[] memory rewardTokens,
    address[] memory swapTokens,
    uint24[] memory uniV3FeeBpses
  ) external onlyOwner {
    if (rewardTokens.length != swapTokens.length || swapTokens.length != uniV3FeeBpses.length)
      revert RewardDistributor_InvalidArray();

    uint256 len = rewardTokens.length;
    for (uint256 i = 0; i < len; ) {
      uniswapV3SwapFeeBPSs[rewardTokens[i]][swapTokens[i]] = uniV3FeeBpses[i];

      unchecked {
        ++i;
      }
    }

    emit LogSetUniFeeBps(rewardTokens, swapTokens, uniV3FeeBpses);
  }

  function setParams(
    address _rewardToken,
    address _vaultStorage,
    address _poolRouter,
    address _sglp,
    IGmxRewardRouterV2 _rewardRouter,
    address _hlpStakingProtocolRevenueRewarder,
    address _hmxStakingProtocolRevenueRewarder,
    uint256 _hlpStakingBps,
    MerkleAirdrop _merkleAirdrop,
    ISwitchCollateralRouter _switchCollateralRouter
  ) external onlyOwner {
    if (_hlpStakingBps > BPS) revert RewardDistributor_BadParams();

    rewardToken = _rewardToken;
    vaultStorage = _vaultStorage;
    sglp = _sglp;
    poolRouter = _poolRouter;
    rewardRouter = _rewardRouter;
    hlpStakingProtocolRevenueRewarder = _hlpStakingProtocolRevenueRewarder;
    hmxStakingProtocolRevenueRewarder = _hmxStakingProtocolRevenueRewarder;
    hlpStakingBps = _hlpStakingBps;
    merkleAirdrop = _merkleAirdrop;
    switchCollateralRouter = _switchCollateralRouter;

    emit LogSetParams(
      _rewardToken,
      _vaultStorage,
      _poolRouter,
      address(_rewardRouter),
      _hlpStakingProtocolRevenueRewarder,
      _hmxStakingProtocolRevenueRewarder,
      _hlpStakingBps,
      address(_merkleAirdrop),
      address(_switchCollateralRouter)
    );
  }

  function setDistributionBpsParams(
    uint256 _hlpStakingBps,
    uint256 _protocolOwnedLiquidityBps,
    address _protocolOwnedLiquidityTreasury
  ) external onlyOwner {
    hlpStakingBps = _hlpStakingBps;
    protocolOwnedLiquidityBps = _protocolOwnedLiquidityBps;
    protocolOwnedLiquidityTreasury = _protocolOwnedLiquidityTreasury;

    emit LogSetDistributionBpsParams(
      _hlpStakingBps,
      _protocolOwnedLiquidityBps,
      _protocolOwnedLiquidityTreasury
    );
  }

  function setReferralRevenueMaxThreshold(
    uint256 newReferralRevenueMaxThreshold
  ) external onlyOwner {
    if (newReferralRevenueMaxThreshold > 5000) {
      // should not exceed 50% of total revenue
      revert RewardDistributor_BadReferralRevenueMaxThreshold();
    }
    emit LogSetReferralRevenueMaxThreshold(
      referralRevenueMaxThreshold,
      newReferralRevenueMaxThreshold
    );
    referralRevenueMaxThreshold = newReferralRevenueMaxThreshold;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function setTokenSwapPath(
    address[] calldata token,
    address[][] calldata path
  ) external onlyOwner {
    if (token.length != path.length) {
      revert RewardDistributor_UnevenTokenSwapPath();
    }
    emit LogSetTokenSwapPath(token, path);
    for (uint8 i; i < token.length; i++) {
      tokenSwapPath[token[i]] = path[i];
    }
  }

  function setGmConfigs(
    address _gmxV2ExchangeRouter,
    address _gmxV2WithdrawalVault,
    address _weth
  ) external onlyOwner {
    gmxV2ExchangeRouter = IGmxV2ExchangeRouter(_gmxV2ExchangeRouter);
    gmxV2WithdrawalVault = _gmxV2WithdrawalVault;
    weth = IWNative(_weth);

    emit LogSetGmConfigs(_gmxV2ExchangeRouter, _gmxV2WithdrawalVault, _weth);
  }

  function setGasService(address _gasService) external onlyOwner {
    gasService = IGasService(_gasService);
    emit LogSetGasService(_gasService);
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit LogSetTreasury(_treasury);
  }
}