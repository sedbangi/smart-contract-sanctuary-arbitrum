// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import './strategies/ArbStrategy.sol';

contract ArbFromTokens is ArbStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    // state variables
    mapping(address => mapping(address => uint)) public userInfo;

    /**
     * @dev Deposit native token
     */
    function deposit() external payable nonReentrant {
        _require(msg.value > 0, Errors.NO_AMOUNT);
        userInfo[address(0)][_msgSender()] += msg.value;
    }

    /**
     * @dev Deposit erc20 token
     * @param token Token address to deposit
     * @param amount Token amount to deposit
     */
    function depositToken(address token, uint amount) external nonReentrant {
        _require(amount > 0, Errors.NO_AMOUNT);
        userInfo[token][_msgSender()] += amount;
        IERC20Upgradeable(token).safeTransferFrom(_msgSender(), address(this), amount);
    }

    /**
     * @dev Swap tokens with univ2
     * @param amountIn Amount in
     * @param uniV2Buy Address of univ2 router to buy tokens from ETH
     * @param pathBuy Array of tokens to buy tokens from ETH in univ2
     * @param uniV2Sell Address of univ2 router to sell tokens for ETH
     * @param pathSell Array of tokens to sell tokens for ETH in univ2
     * @param deadline The deadline timestamp
     */
    function arbFromTokensWithUniV2(
        uint256 amountIn,
        address uniV2Buy,
        address[] memory pathBuy,
        address uniV2Sell,
        address[] memory pathSell,
        uint256 deadline
    ) external nonReentrant whenNotPaused onlyWhitelist {
        // Buy the tokens
        address buyStrategy = getUniV2Strategy(uniV2Buy);
        address sellStrategy = getUniV2Strategy(uniV2Sell);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(pathBuy[0]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), amountIn);
        tokenIn.safeTransfer(buyStrategy, amountIn);
        IUniV2Strategy(buyStrategy).swapExactTokensForTokens(uniV2Buy, amountIn, 0, pathBuy, sellStrategy, deadline);
        // Sell the tokens
        IUniV2Strategy(sellStrategy).swapExactTokensForTokens(
            uniV2Sell,
            IERC20Upgradeable(pathBuy[pathBuy.length - 1]).balanceOf(sellStrategy),
            0,
            pathSell,
            address(this),
            deadline
        );

        _ensureProfit(amountIn, tokenIn);
    }

    /**
     * @dev Swap tokens with vault and univ2
     * If selector is 0, buy tokens with univ2 and sell tokens with vault.
     * Otherwise, buy tokens with vault and sell tokens with univ2.
     * @param amountIn Amount in
     * @param uniV2 Address of univ2 router to buy tokens
     * @param path Array of tokens to buy tokens in univ2
     * @param vault Address of vault
     * @param swaps BatchSwapStep struct in vault
     * @param assets An array of tokens which are used in the batch swap. This is referenced from within swaps
     * @param deadline The deadline timestamp
     * @param selector Selector of the swap method
     */
    function arbFromTokensWithVaultAndUniV2(
        uint256 amountIn,
        address uniV2,
        address[] memory path,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint256 selector
    ) external nonReentrant whenNotPaused onlyWhitelist {
        if (selector == 0) swapTokensUniV2AndVault(amountIn, uniV2, path, vault, swaps, assets, deadline);
        else swapTokensVaultAndUniV2(uniV2, path, vault, swaps, assets, deadline);
    }

    /**
     * @dev Swap tokens with 1inch and vault
     * If selector is 0, buy tokens with vault and sell tokens with 1inch.
     * Otherwise, buy tokens with 1inch and sell tokens with vault.
     * @param oneInch Address of 1inch router
     * @param executor Aggregation executor that executes calls described in data
     * @param desc Swap description in 1inch
     * @param data Encoded calls that caller should execute in between of swaps
     * @param vault Address of vault
     * @param swaps BatchSwapStep struct in vault
     * @param assets An array of tokens which are used in the batch swap. This is referenced from within swaps
     * @param deadline The deadline timestamp
     * @param selector Selector of the swap method
     */
    function arbFromTokensWith1InchAndVault(
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory desc,
        bytes memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint256 selector
    ) external nonReentrant whenNotPaused onlyWhitelist {
        if (selector == 0) swapTokensVaultAnd1Inch(oneInch, executor, desc, data, vault, swaps, assets, deadline);
        else swapTokens1InchAndVault(oneInch, executor, desc, data, vault, swaps, assets, deadline);
    }

    /**
     * @dev Swap tokens with univ3swap of 1inch and vault
     * If selector is 0, buy tokens with vault and sell tokens with univ3swap of 1inch.
     * Otherwise, buy tokens with univ3swap of 1inch and sell tokens with vault.
     * @param oneInch Address of 1inch router
     * @param uniV3Swap UnisV3Swap struct of 1inch
     * @param vault Address of vault
     * @param swaps BatchSwapStep struct in vault
     * @param assets An array of tokens which are used in the batch swap. This is referenced from within swaps
     * @param deadline The deadline timestamp
     * @param selector Selector of the swap method
     */
    function arbFromTokensWith1InchUniV3AndVault(
        address oneInch,
        I1InchStrategy.UniV3SwapTo memory uniV3Swap,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint256 selector
    ) external nonReentrant whenNotPaused onlyWhitelist {
        if (selector == 0) swapTokensVaultAnd1InchUniV3(oneInch, uniV3Swap, vault, swaps, assets, deadline);
        else swapTokens1InchUniV3AndVault(oneInch, uniV3Swap, vault, swaps, assets, deadline);
    }

    /**
     * @dev Swap tokens with firebird and vault
     * If selector is 0, buy tokens with vault and sell tokens with firebird.
     * Otherwise, buy tokens with firebird and sell tokens with vault.
     * @param fireBird Address of firebird router
     * @param caller Aggregation caller that executes calls described in data for firebird
     * @param desc Swap descrption in firebird
     * @param data Encoded calls that caller should execute in between of swaps for firebird
     * @param vault Address of vault
     * @param swaps BatchSwapStep struct in vault
     * @param assets An array of tokens which are used in the batch swap. This is referenced from within swaps
     * @param deadline The deadline timestamp
     * @param selector Selector of the swap method
     */
    function arbFromTokensWithFireBirdAndVault(
        address fireBird,
        IAggregationExecutor caller,
        IFireBirdRouter.SwapDescription memory desc,
        bytes memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint deadline,
        uint256 selector
    ) external nonReentrant whenNotPaused {
        if (selector == 0) swapTokensVaultAndFireBird(fireBird, caller, desc, data, vault, swaps, assets, deadline);
        else swapTokensFireBirdAndVault(fireBird, caller, desc, data, vault, swaps, assets, deadline);
    }

    /**
     * @dev Swap tokens with firebird and 1inch
     * If selector is 0, buy tokens with 1inch and sell tokens with firebird.
     * Otherwise, buy tokens with firebird and sell tokens with 1inch.
     * @param fireBird Address of firebird router
     * @param caller Aggregation caller that executes calls described in data for firebird
     * @param descFireBird Swap descrption in firebird
     * @param dataFireBird Encoded calls that caller should execute in between of swaps for firebird
     * @param oneInch Address of 1inch router
     * @param executor Aggregation executor that executes calls described in data
     * @param descInch Swap description in 1inch
     * @param dataInch Encoded calls that caller should execute in between of swaps
     */
    function arbFromTokensWithFireBirdAnd1Inch(
        address fireBird,
        IAggregationExecutor caller,
        IFireBirdRouter.SwapDescription memory descFireBird,
        bytes memory dataFireBird,
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory descInch,
        bytes memory dataInch,
        uint selector
    ) external nonReentrant whenNotPaused {
        if (selector == 0)
            swapTokens1InchAndFireBird(
                fireBird,
                caller,
                descFireBird,
                dataFireBird,
                oneInch,
                executor,
                descInch,
                dataInch
            );
        else
            swapTokensFireBirdAnd1Inch(
                fireBird,
                caller,
                descFireBird,
                dataFireBird,
                oneInch,
                executor,
                descInch,
                dataInch
            );
    }

    /**
     * @dev Swap tokens with odos and vault
     * If selector is 0, buy tokens with vault and sell tokens with odos.
     * Otherwise, buy tokens with odos and sell tokens with vault.
     * @param odos Address of odos router
     * @param tokenInfo All information about the tokens being swapped
     * @param data Encoded data for swapCompact
     * @param vault Address of vault
     * @param swaps BatchSwapStep struct in vault
     * @param assets An array of tokens which are used in the batch swap. This is referenced from within swaps
     * @param deadline The deadline timestamp
     * @param selector Selector of the swap method
     */
    function arbFromTokensWithOdosAndVault(
        address odos,
        IOdosRouter.swapTokenInfo memory tokenInfo,
        bytes memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint selector
    ) external nonReentrant whenNotPaused {
        if (selector == 0) swapTokensVaultAndOdos(odos, tokenInfo, data, vault, swaps, assets, deadline);
        else swapTokensOdosAndVault(odos, tokenInfo, data, vault, swaps, assets, deadline);
    }

    /**
     * @dev Swap tokens with odos and vault
     * If selector is 0, buy tokens with vault and sell tokens with paraswap.
     * Otherwise, buy tokens with paraswap and sell tokens with vault.
     */
    function arbFromTokensWithParaAndVault(
        address para,
        Utils.SimpleData memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint selector
    ) external nonReentrant whenNotPaused {
        if (selector == 0) swapTokensVaultAndPara(para, data, vault, swaps, assets, deadline);
        else swapTokensParaAndVault(para, data, vault, swaps, assets, deadline);
    }

    /**
     * @dev Buy tokens with univ2 and sell tokens with vault
     */
    function swapTokensUniV2AndVault(
        uint256 amountIn,
        address uniV2Buy,
        address[] memory pathBuy,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assetsSell,
        uint256 deadline
    ) private {
        // Buy tokens
        address buyStrategy = getUniV2Strategy(uniV2Buy);
        address sellStrategy = getVaultStrategy(vaultSell);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(pathBuy[0]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), amountIn);
        tokenIn.safeTransfer(buyStrategy, amountIn);
        IUniV2Strategy(buyStrategy).swapExactTokensForTokens(uniV2Buy, amountIn, 0, pathBuy, sellStrategy, deadline);
        // Sell tokens
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        swapsSell[0].amount = IERC20Upgradeable(assetsSell[swapsSell[0].assetInIndex]).balanceOf(sellStrategy);
        IVaultStrategy(sellStrategy).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assetsSell,
            fundsSell,
            getLimitsForVault(assetsSell.length),
            deadline
        );

        _ensureProfit(amountIn, tokenIn);
    }

    /**
     * @dev Buy tokens with vault and sell tokens with univ2
     */
    function swapTokensVaultAndUniV2(
        address uniV2Sell,
        address[] memory pathSell,
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assetsBuy,
        uint256 deadline
    ) private {
        // Buy tokens
        address buyStrategy = getVaultStrategy(vaultBuy);
        address sellStrategy = getUniV2Strategy(uniV2Sell);
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        IERC20Upgradeable tokenIn = IERC20Upgradeable(assetsBuy[swapsBuy[0].assetInIndex]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), swapsBuy[0].amount);
        tokenIn.safeTransfer(buyStrategy, swapsBuy[0].amount);
        IVaultStrategy(buyStrategy).batchSwap(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assetsBuy,
            fundsBuy,
            getLimitsForVault(assetsBuy.length),
            deadline
        );
        // Sell tokens
        uint sellIn = IERC20Upgradeable(assetsBuy[swapsBuy[swapsBuy.length - 1].assetOutIndex]).balanceOf(sellStrategy);
        IUniV2Strategy(sellStrategy).swapExactTokensForTokens(uniV2Sell, sellIn, 0, pathSell, address(this), deadline);

        _ensureProfit(swapsBuy[0].amount, tokenIn);
    }

    /**
     * @dev Buy tokens with vault and sell tokens with 1inch
     */
    function swapTokensVaultAnd1Inch(
        address oneInchSell,
        IAggregationExecutor executorSell,
        I1InchRouter.SwapDescription memory descSell,
        bytes memory data,
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assetsBuy,
        uint256 deadline
    ) private {
        // Buy tokens
        address buyStrategy = getVaultStrategy(vaultBuy);
        address sellStrategy = get1InchStrategy(oneInchSell);
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        IERC20Upgradeable tokenIn = IERC20Upgradeable(assetsBuy[swapsBuy[0].assetInIndex]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), swapsBuy[0].amount);
        tokenIn.safeTransfer(buyStrategy, swapsBuy[0].amount);
        IVaultStrategy(buyStrategy).batchSwap(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assetsBuy,
            fundsBuy,
            getLimitsForVault(assetsBuy.length),
            deadline
        );
        // Sell tokens
        descSell.amount = descSell.srcToken.balanceOf(sellStrategy);
        I1InchStrategy(sellStrategy).swap(oneInchSell, executorSell, descSell, ZERO_BYTES, data);

        _ensureProfit(swapsBuy[0].amount, tokenIn);
    }

    /**
     * @dev Buy tokens with 1inch and sell tokens with vault
     */
    function swapTokens1InchAndVault(
        address oneInchBuy,
        IAggregationExecutor executorBuy,
        I1InchRouter.SwapDescription memory descBuy,
        bytes memory data,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assetsSell,
        uint256 deadline
    ) private {
        // Buy tokens
        address buyStrategy = get1InchStrategy(oneInchBuy);
        address sellStrategy = getVaultStrategy(vaultSell);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(address(descBuy.srcToken));
        tokenIn.safeTransferFrom(_msgSender(), address(this), descBuy.amount);
        tokenIn.safeTransfer(buyStrategy, descBuy.amount);
        I1InchStrategy(buyStrategy).swap(oneInchBuy, executorBuy, descBuy, ZERO_BYTES, data);
        // Sell tokens
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        swapsSell[0].amount = IERC20Upgradeable(assetsSell[swapsSell[0].assetInIndex]).balanceOf(sellStrategy);
        IVaultStrategy(sellStrategy).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assetsSell,
            fundsSell,
            getLimitsForVault(assetsSell.length),
            deadline
        );

        _ensureProfit(descBuy.amount, tokenIn);
    }

    /**
     * @dev Buy tokens with vault and sell tokens with univ3swap of 1inch
     */
    function swapTokensVaultAnd1InchUniV3(
        address oneInchSell,
        I1InchStrategy.UniV3SwapTo memory uniV3SwapSell,
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assetsBuy,
        uint256 deadline
    ) private {
        // Buy tokens
        address buyStrategy = getVaultStrategy(vaultBuy);
        address sellStrategy = get1InchStrategy(oneInchSell);
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        IERC20Upgradeable tokenIn = IERC20Upgradeable(assetsBuy[swapsBuy[0].assetInIndex]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), swapsBuy[0].amount);
        tokenIn.safeTransfer(buyStrategy, swapsBuy[0].amount);
        IVaultStrategy(buyStrategy).batchSwap(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assetsBuy,
            fundsBuy,
            getLimitsForVault(assetsBuy.length),
            deadline
        );
        // Sell tokens
        I1InchStrategy.UniV3SwapTo memory _u = uniV3SwapSell;
        _u.amount = IERC20Upgradeable(_u.srcToken).balanceOf(sellStrategy);
        I1InchStrategy(sellStrategy).uniswapV3SwapTo(oneInchSell, _u);

        _ensureProfit(swapsBuy[0].amount, tokenIn);
    }

    /**
     * @dev Buy tokens with univ3swap of 1inch and sell tokens with vault
     */
    function swapTokens1InchUniV3AndVault(
        address oneInchBuy,
        I1InchStrategy.UniV3SwapTo memory uniV3SwapBuy,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assetsSell,
        uint256 deadline
    ) private {
        // Buy tokens
        address buyStrategy = get1InchStrategy(oneInchBuy);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(uniV3SwapBuy.srcToken);
        tokenIn.safeTransferFrom(_msgSender(), address(this), uniV3SwapBuy.amount);
        tokenIn.safeTransfer(buyStrategy, uniV3SwapBuy.amount);
        I1InchStrategy(buyStrategy).uniswapV3SwapTo(oneInchBuy, uniV3SwapBuy);
        // Sell tokens
        address sellStrategy = getVaultStrategy(vaultSell);
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        swapsSell[0].amount = IERC20Upgradeable(assetsSell[swapsSell[0].assetInIndex]).balanceOf(sellStrategy);
        IVaultStrategy(sellStrategy).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assetsSell,
            fundsSell,
            getLimitsForVault(assetsSell.length),
            deadline
        );

        _ensureProfit(uniV3SwapBuy.amount, tokenIn);
    }

    /**
     * @dev Buy tokens with vault and sell tokens with firebird
     */
    function swapTokensVaultAndFireBird(
        address fireBird,
        IAggregationExecutor caller,
        IFireBirdRouter.SwapDescription memory desc,
        bytes memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint deadline
    ) private {
        // Buy tokens
        address buyStrategy = getVaultStrategy(vault);
        address sellStrategy = getFireBirdStrategy(fireBird);
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        IERC20Upgradeable tokenIn = IERC20Upgradeable(assets[swaps[0].assetInIndex]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), swaps[0].amount);
        tokenIn.safeTransfer(buyStrategy, swaps[0].amount);
        IVaultStrategy(buyStrategy).batchSwap(
            vault,
            IVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            fundsBuy,
            getLimitsForVault(assets.length),
            deadline
        );
        // Sell tokens
        desc.amount = desc.srcToken.balanceOf(sellStrategy);
        IFireBirdStrategy(sellStrategy).swap(fireBird, caller, desc, data);

        _ensureProfit(swaps[0].amount, tokenIn);
    }

    /**
     * @dev Buy tokens with firebird and sell tokens with vault
     */
    function swapTokensFireBirdAndVault(
        address fireBird,
        IAggregationExecutor caller,
        IFireBirdRouter.SwapDescription memory desc,
        bytes memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint deadline
    ) private {
        // Buy tokens
        address buyStrategy = getFireBirdStrategy(fireBird);
        address sellStrategy = getVaultStrategy(vault);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(address(desc.srcToken));
        tokenIn.safeTransferFrom(_msgSender(), address(this), desc.amount);
        tokenIn.safeTransfer(buyStrategy, desc.amount);
        IFireBirdStrategy(buyStrategy).swap(fireBird, caller, desc, data);
        // Sell tokens
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        swaps[0].amount = desc.dstToken.balanceOf(sellStrategy);
        IVaultStrategy(sellStrategy).batchSwap(
            vault,
            IVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            fundsSell,
            getLimitsForVault(assets.length),
            deadline
        );

        _ensureProfit(desc.amount, tokenIn);
    }

    /**
     * @dev Buy tokens with 1inch and sell tokens with firebird
     */
    function swapTokens1InchAndFireBird(
        address fireBird,
        IAggregationExecutor caller,
        IFireBirdRouter.SwapDescription memory descFireBird,
        bytes memory dataFireBird,
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory descInch,
        bytes memory dataInch
    ) private {
        // Buy tokens
        address buyStrategy = get1InchStrategy(oneInch);
        address sellStrategy = getFireBirdStrategy(fireBird);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(address(descInch.srcToken));
        tokenIn.safeTransferFrom(_msgSender(), address(this), descInch.amount);
        tokenIn.safeTransfer(buyStrategy, descInch.amount);
        I1InchStrategy(buyStrategy).swap(oneInch, executor, descInch, ZERO_BYTES, dataInch);
        // Sell tokens
        descFireBird.amount = IERC20Upgradeable(address(descFireBird.srcToken)).balanceOf(sellStrategy);
        IFireBirdStrategy(sellStrategy).swap(fireBird, caller, descFireBird, dataFireBird);

        _ensureProfit(descInch.amount, tokenIn);
    }

    /**
     * @dev Buy tokens with firebird and sell tokens with 1inch
     */
    function swapTokensFireBirdAnd1Inch(
        address fireBird,
        IAggregationExecutor caller,
        IFireBirdRouter.SwapDescription memory descFireBird,
        bytes memory dataFireBird,
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory descInch,
        bytes memory dataInch
    ) private {
        // Buy tokens
        address buyStrategy = get1InchStrategy(oneInch);
        address sellStrategy = getFireBirdStrategy(fireBird);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(address(descFireBird.srcToken));
        tokenIn.safeTransferFrom(_msgSender(), address(this), descFireBird.amount);
        tokenIn.safeTransfer(buyStrategy, descFireBird.amount);
        IFireBirdStrategy(sellStrategy).swap(fireBird, caller, descFireBird, dataFireBird);
        // Sell tokens
        descInch.amount = descInch.srcToken.balanceOf(sellStrategy);
        I1InchStrategy(buyStrategy).swap(oneInch, executor, descInch, ZERO_BYTES, dataInch);

        _ensureProfit(descFireBird.amount, tokenIn);
    }

    /**
     * @dev Buy tokens with vault and sell tokens with odos
     */
    function swapTokensVaultAndOdos(
        address odos,
        IOdosRouter.swapTokenInfo memory tokenInfo,
        bytes memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline
    ) private {
        address buyStrategy = getVaultStrategy(vault);
        address sellStrategy = getOdosStrategy(odos);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(assets[swaps[0].assetInIndex]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), swaps[0].amount);
        tokenIn.safeTransfer(buyStrategy, swaps[0].amount);

        // Buy tokens
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        IVaultStrategy(buyStrategy).batchSwap(
            vault,
            IVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            fundsBuy,
            getLimitsForVault(assets.length),
            deadline
        );

        // Sell tokens
        tokenInfo.inputAmount = IERC20Upgradeable(tokenInfo.inputToken).balanceOf(sellStrategy);
        bytes32 newAmountBytes = bytes32(tokenInfo.inputAmount);
        uint8 length = uint8(data[48]); // 48th byte marks the length of `tokenInfo.inputToken`
        for (uint8 i = 0; i < length; i++) {
            data[49 + i] = newAmountBytes[32 - length + i];
        }
        IOdosStrategy(sellStrategy).swapCompact(odos, tokenInfo, data);

        _ensureProfit(swaps[0].amount, tokenIn);
    }

    /**
     * @dev Buy tokens with odos and sell tokens with vault
     */
    function swapTokensOdosAndVault(
        address odos,
        IOdosRouter.swapTokenInfo memory tokenInfo,
        bytes memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline
    ) private {
        address buyStrategy = getOdosStrategy(odos);
        address sellStrategy = getVaultStrategy(vault);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(tokenInfo.inputToken);
        tokenIn.safeTransferFrom(_msgSender(), address(this), tokenInfo.inputAmount);
        tokenIn.safeTransfer(buyStrategy, tokenInfo.inputAmount);

        // Buy tokens
        IOdosStrategy(buyStrategy).swapCompact(odos, tokenInfo, data);

        // Sell tokens
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        swaps[0].amount = IERC20Upgradeable(tokenInfo.outputToken).balanceOf(sellStrategy);
        IVaultStrategy(sellStrategy).batchSwap(
            vault,
            IVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            fundsSell,
            getLimitsForVault(assets.length),
            deadline
        );

        _ensureProfit(tokenInfo.inputAmount, tokenIn);
    }

    /**
     * @dev Buy tokens with vault and sell tokens with paraswap
     */
    function swapTokensVaultAndPara(
        address para,
        Utils.SimpleData memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline
    ) private {
        address buyStrategy = getVaultStrategy(vault);
        address sellStrategy = getParaStrategy(para);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(assets[swaps[0].assetInIndex]);
        tokenIn.safeTransferFrom(_msgSender(), address(this), swaps[0].amount);
        tokenIn.safeTransfer(buyStrategy, swaps[0].amount);

        // Buy tokens
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        IVaultStrategy(buyStrategy).batchSwap(
            vault,
            IVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            fundsBuy,
            getLimitsForVault(assets.length),
            deadline
        );

        // Sell tokens
        data.fromAmount = IERC20Upgradeable(data.fromToken).balanceOf(sellStrategy);
        IParaswapStrategy(sellStrategy).simpleSwap(para, data);

        _ensureProfit(swaps[0].amount, tokenIn);
    }

    /**
     * @dev Buy tokens with paraswap and sell tokens with vault
     */
    function swapTokensParaAndVault(
        address para,
        Utils.SimpleData memory data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline
    ) private {
        address buyStrategy = getParaStrategy(para);
        address sellStrategy = getVaultStrategy(vault);
        IERC20Upgradeable tokenIn = IERC20Upgradeable(data.fromToken);
        tokenIn.safeTransferFrom(_msgSender(), address(this), data.fromAmount);
        tokenIn.safeTransfer(buyStrategy, data.fromAmount);

        // Buy tokens
        IParaswapStrategy(buyStrategy).simpleSwap(para, data);

        // Sell tokens
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        swaps[0].amount = IERC20Upgradeable(data.toToken).balanceOf(sellStrategy);
        IVaultStrategy(sellStrategy).batchSwap(
            vault,
            IVault.SwapKind.GIVEN_IN,
            swaps,
            assets,
            fundsSell,
            getLimitsForVault(assets.length),
            deadline
        );

        _ensureProfit(data.fromAmount, tokenIn);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './IAggregationExecutor.sol';

interface I1InchRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3SwapToWithPermit(
        address payable recipient,
        IERC20 srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        bytes calldata permit
    ) external returns (uint256 returnAmount);

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IAggregationExecutor.sol';
import './I1InchRouter.sol';

interface I1InchStrategy {
    // For uniswapV3SwapTo
    struct UniV3SwapTo {
        address payable recipient;
        address srcToken;
        uint256 amount;
        uint256 minReturn;
        uint256[] pools;
    }

    function swap(
        address router,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);

    function uniswapV3Swap(
        address router,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3SwapTo(
        address router,
        UniV3SwapTo calldata uniV3Swap
    ) external payable returns (uint256 returnAmount);

    function uniswapV3SwapToWithPermit(
        address router,
        address payable recipient,
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools,
        bytes calldata permit
    ) external returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable;

    function callBytes(bytes calldata data, address srcSpender) external payable; // 0xd9c45357
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IAggregationExecutor.sol';

interface IFireBirdRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    event Exchange(address pair, uint amountOut, address output);

    function factory() external view returns (address);

    function formula() external view returns (address);

    function WETH() external view returns (address);

    function swapFeeReward() external view returns (address);

    function addLiquidity(
        address pair,
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
        address pair,
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        address tokenOut,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        address tokenIn,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        address tokenOut,
        uint amountOut,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external;

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256 returnAmount);

    function createPair(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB,
        uint32 tokenWeightA,
        uint32 swapFee,
        address to
    ) external returns (uint liquidity);

    function createPairETH(
        address token,
        uint amountToken,
        uint32 tokenWeight,
        uint32 swapFee,
        address to
    ) external payable returns (uint liquidity);

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address pair,
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
        address pair,
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

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IAggregationExecutor.sol';
import '../interfaces/IFireBirdRouter.sol';

interface IFireBirdStrategy {
    function swapExactTokensForTokens(
        address router,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        address router,
        address tokenOut,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        address router,
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address router,
        address tokenOut,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address router,
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint8[] calldata dexIds,
        address to,
        uint deadline
    ) external;

    function swap(
        address router,
        IAggregationExecutor caller,
        IFireBirdRouter.SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256 returnAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOdosRouter {
    /// @dev Contains all information needed to describe the input and output for a swap
    //solhint-disable-next-line contract-name-camelcase
    struct swapTokenInfo {
        address inputToken;
        uint256 inputAmount;
        address inputReceiver;
        address outputToken;
        uint256 outputQuote;
        uint256 outputMin;
        address outputReceiver;
    }
    /// @dev Contains all information needed to describe an intput token for swapMulti
    //solhint-disable-next-line contract-name-camelcase
    struct inputTokenInfo {
        address tokenAddress;
        uint256 amountIn;
        address receiver;
    }
    /// @dev Contains all information needed to describe an output token for swapMulti
    //solhint-disable-next-line contract-name-camelcase
    struct outputTokenInfo {
        address tokenAddress;
        uint256 relativeValue;
        address receiver;
    }

    /// @notice Custom decoder to swap with compact calldata for efficient execution on L2s
    function swapCompact() external payable returns (uint256);

    /// @notice Externally facing interface for swapping two tokens
    /// @param tokenInfo All information about the tokens being swapped
    /// @param pathDefinition Encoded path definition for executor
    /// @param executor Address of contract that will execute the path
    /// @param referralCode referral code to specify the source of the swap
    function swap(
        swapTokenInfo memory tokenInfo,
        bytes calldata pathDefinition,
        address executor,
        uint32 referralCode
    ) external payable returns (uint256 amountOut);

    /// @notice Externally facing interface for swapping between two sets of tokens
    /// @param inputs list of input token structs for the path being executed
    /// @param outputs list of output token structs for the path being executed
    /// @param valueOutMin minimum amount of value out the user will accept
    /// @param pathDefinition Encoded path definition for executor
    /// @param executor Address of contract that will execute the path
    /// @param referralCode referral code to specify the source of the swap
    function swapMulti(
        inputTokenInfo[] memory inputs,
        outputTokenInfo[] memory outputs,
        uint256 valueOutMin,
        bytes calldata pathDefinition,
        address executor,
        uint32 referralCode
    ) external payable returns (uint256[] memory amountsOut);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IOdosRouter.sol';

interface IOdosStrategy {
    function swapCompact(
        address router,
        IOdosRouter.swapTokenInfo memory tokenInfo,
        bytes calldata data
    ) external payable returns (uint256);

    function swap(
        address router,
        IOdosRouter.swapTokenInfo memory tokenInfo,
        bytes calldata pathDefinition,
        address executor,
        uint32 referralCode
    ) external payable returns (uint256 amountOut);

    function swapMulti(
        address router,
        IOdosRouter.inputTokenInfo[] memory inputs,
        IOdosRouter.outputTokenInfo[] memory outputs,
        uint256 valueOutMin,
        bytes calldata pathDefinition,
        address executor,
        uint32 referralCode
    ) external payable returns (uint256[] memory amountsOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../libraries/Utils.sol';

interface IParaswapStrategy {
    // function multiSwap(Utils.SellData calldata data) external payable returns (uint256);

    // function megaSwap(Utils.MegaSwapSellData calldata data) external payable returns (uint256);

    // function protectedMultiSwap(Utils.SellData calldata data) external payable returns (uint256);

    // function protectedMegaSwap(Utils.MegaSwapSellData calldata data) external payable returns (uint256);

    // function protectedSimpleSwap(Utils.SimpleData calldata data) external payable returns (uint256 receivedAmount);

    // function protectedSimpleBuy(Utils.SimpleData calldata data) external payable;

    function simpleSwap(
        address router,
        Utils.SimpleData calldata data
    ) external payable returns (uint256 receivedAmount);

    // function simpleBuy(Utils.SimpleData calldata data) external payable;

    // function swapOnUniswap(uint256 amountIn, uint256 amountOutMin, address[] calldata path) external payable;

    // function swapOnUniswapFork(
    //     address factory,
    //     bytes32 initCode,
    //     uint256 amountIn,
    //     uint256 amountOutMin,
    //     address[] calldata path
    // ) external payable;

    // function buyOnUniswap(uint256 amountInMax, uint256 amountOut, address[] calldata path) external payable;

    // function buyOnUniswapFork(
    //     address factory,
    //     bytes32 initCode,
    //     uint256 amountInMax,
    //     uint256 amountOut,
    //     address[] calldata path
    // ) external payable;

    // function swapOnUniswapV2Fork(
    //     address tokenIn,
    //     uint256 amountIn,
    //     uint256 amountOutMin,
    //     address weth,
    //     uint256[] calldata pools
    // ) external payable;

    // function buyOnUniswapV2Fork(
    //     address tokenIn,
    //     uint256 amountInMax,
    //     uint256 amountOut,
    //     address weth,
    //     uint256[] calldata pools
    // ) external payable;

    // function swapOnZeroXv2(
    //     IERC20 fromToken,
    //     IERC20 toToken,
    //     uint256 fromAmount,
    //     uint256 amountOutMin,
    //     address exchange,
    //     bytes calldata payload
    // ) external payable;

    // function swapOnZeroXv4(
    //     IERC20 fromToken,
    //     IERC20 toToken,
    //     uint256 fromAmount,
    //     uint256 amountOutMin,
    //     address exchange,
    //     bytes calldata payload
    // ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenTransferProxy {
    function transferFrom(address token, address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniV2Strategy {
    function swapExactTokensForTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETH(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(
        address router,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/ISwapRouter.sol';

interface IUniV3Strategy {
    function exactInputSingle(
        address router,
        ISwapRouter.ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    function exactInput(
        address router,
        ISwapRouter.ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    function exactOutputSingle(
        address router,
        ISwapRouter.ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    function exactOutput(
        address router,
        ISwapRouter.ExactOutputParams calldata params
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";

interface IVaultStrategy {
    function batchSwap(
        address vault,
        IVault.SwapKind kind,
        IVault.BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        IVault.FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external payable;

    function swap(
        address vault,
        IVault.SingleSwap calldata singleSwap,
        IVault.FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // ArbSwap
    uint internal constant NOT_WHITELIST = 101;
    uint internal constant NO_PROFIT = 102;
    uint internal constant NO_AMOUNT = 103;
    uint internal constant NOT_WITHDRAWABLE = 104;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../interfaces/ITokenTransferProxy.sol';

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(address addressToApprove, address token, uint256 amount) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(address token, address payable destination, uint256 amount) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{ value: amount, gas: 10000 }('');
                require(result, 'Failed to transfer Ether');
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, 'Permit failed');
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(abi.encodePacked(IERC20PermitLegacy.permit.selector, permit));
            require(success, 'Permit failed');
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount, gas: 10000 }('');
            require(result, 'Transfer ETH failed');
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import '../interfaces/IUniV2Strategy.sol';
import '../interfaces/IVaultStrategy.sol';
import '../interfaces/IUniV3Strategy.sol';
import '../interfaces/I1InchStrategy.sol';
import '../interfaces/IFireBirdStrategy.sol';
import '../interfaces/IOdosStrategy.sol';
import '../interfaces/IParaswapStrategy.sol';
import '../interfaces/IVault.sol';
import '../interfaces/IAggregationExecutor.sol';
import '../interfaces/I1InchRouter.sol';
import '../interfaces/IOdosRouter.sol';
import '../libraries/Errors.sol';
import '../libraries/Utils.sol';
import '../WithdrawableUpgradeable.sol';

contract ArbStrategy is WithdrawableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    bytes internal constant ZERO_BYTES = '';

    address public defaultUniV2Strategy;
    mapping(address => address) private uniV2Strategies;

    address public defaultVaultStrategy;
    mapping(address => address) private vaultStrategies;

    address public defaultUniV3Strategy;
    mapping(address => address) private uniV3Strategies;

    address public default1InchStrategy;
    mapping(address => address) private oneInchStrategies;

    address public defaultFireBirdStrategy;
    mapping(address => address) private fireBirdStrategies;

    address public defaultOdosStrategy;
    mapping(address => address) private odosStrategies;

    address public defaultParaStrategy;
    mapping(address => address) private paraStrategies;

    mapping(address => bool) public whitelist;

    modifier onlyWhitelist() {
        _require(whitelist[_msgSender()], Errors.NOT_WHITELIST);
        _;
    }

    //solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // Required to receive funds
    }

    /**
     * @dev Initialize functions for withdrawable, reentrancy guard, pausable
     */
    function initialize() public initializer {
        __Withdrawable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    /**
     * @dev Get strategy address for univ2 router
     * @param uniV2 Address of univ2 router
     * @return strategy Address of strategy for univ2 router
     */
    function getUniV2Strategy(address uniV2) public view returns (address strategy) {
        address _strat = uniV2Strategies[uniV2];
        return _strat != address(0) ? _strat : defaultUniV2Strategy;
    }

    /**
     * @dev Get strategy address for vault
     * @param vault Address of vault
     * @return strategy Address of strategy for vault
     */
    function getVaultStrategy(address vault) public view returns (address strategy) {
        address _strat = vaultStrategies[vault];
        return _strat != address(0) ? _strat : defaultVaultStrategy;
    }

    /**
     * @dev Get strategy address for univ3 router
     * @param uniV3 Address of univ3 router
     * @return strategy Address of strategy for univ3 router
     */
    function getUniV3Strategy(address uniV3) public view returns (address strategy) {
        address _strat = uniV3Strategies[uniV3];
        return _strat != address(0) ? _strat : defaultUniV3Strategy;
    }

    /**
     * @dev Get strategy address for 1inch router
     * @param oneInch Address of 1inch router
     * @return strategy Address of strategy for 1inch router
     */
    function get1InchStrategy(address oneInch) public view returns (address strategy) {
        address _strat = oneInchStrategies[oneInch];
        return _strat != address(0) ? _strat : default1InchStrategy;
    }

    /**
     * @dev Get strategy address for firebird router
     * @param fireBird Address of firebird router
     * @return strategy Address of strategy for firebird router
     */
    function getFireBirdStrategy(address fireBird) public view returns (address strategy) {
        address _strat = fireBirdStrategies[fireBird];
        return _strat != address(0) ? _strat : defaultFireBirdStrategy;
    }

    /**
     * @dev Get strategy address for odos router
     * @param odos Address of odos router
     * @return strategy Address of strategy for odos router
     */
    function getOdosStrategy(address odos) public view returns (address strategy) {
        address _strat = odosStrategies[odos];
        return _strat != address(0) ? _strat : defaultOdosStrategy;
    }

    /**
     * @dev Get strategy address for paraswap router
     * @param para Address of paraswap router
     * @return strategy Address of strategy for paraswap router
     */
    function getParaStrategy(address para) public view returns (address strategy) {
        address _strat = paraStrategies[para];
        return _strat != address(0) ? _strat : defaultParaStrategy;
    }

    /**
     * @dev Set default strategy for univ2 router
     * @param strategy Address of strategy for univ2 router
     */
    function setDefaultUniV2Strategy(address strategy) external onlyOwner {
        defaultUniV2Strategy = strategy;
    }

    /**
     * @dev Set default strategy for vault
     * @param strategy Address of strategy for vault
     */
    function setDefaultVaultStrategy(address strategy) external onlyOwner {
        defaultVaultStrategy = strategy;
    }

    /**
     * @dev Set default strategy for univ3 router
     * @param strategy Address of strategy for univ3 router
     */
    function setDefaultUniV3Strategy(address strategy) external onlyOwner {
        defaultUniV3Strategy = strategy;
    }

    /**
     * @dev Set default strategy for 1inch router
     * @param strategy Address of strategy for 1inch router
     */
    function setDefault1InchStrategy(address strategy) external onlyOwner {
        default1InchStrategy = strategy;
    }

    /**
     * @dev Set default strategy for firebird router
     * @param strategy Address of strategy for firebird router
     */
    function setDefaultFireBirdStrategy(address strategy) external onlyOwner {
        defaultFireBirdStrategy = strategy;
    }

    /**
     * @dev Set default strategy for odos router
     * @param strategy Address of strategy for odos router
     */
    function setDefaultOdosStrategy(address strategy) external onlyOwner {
        defaultOdosStrategy = strategy;
    }

    /**
     * @dev Set default strategy for paraswap router
     * @param strategy Address of strategy for odos router
     */
    function setDefaultParaStrategy(address strategy) external onlyOwner {
        defaultParaStrategy = strategy;
    }

    /**
     * @dev Set strategy for univ2 router
     * @param uniV2 Address of univ2 router
     * @param strategy Address of strategy for univ2 router
     */
    function setUniV2Strategy(address uniV2, address strategy) external onlyOwner {
        uniV2Strategies[uniV2] = strategy;
    }

    /**
     * @dev Set strategy for vault
     * @param vault Address of vault
     * @param strategy Address of strategy for vault
     */
    function setVaultStrategy(address vault, address strategy) external onlyOwner {
        vaultStrategies[vault] = strategy;
    }

    /**
     * @dev Set strategy for univ3 router
     * @param uniV3 Address of univ3 router
     * @param strategy Address of strategy for univ3 router
     */
    function setUniV3Strategy(address uniV3, address strategy) external onlyOwner {
        uniV3Strategies[uniV3] = strategy;
    }

    /**
     * @dev Set strategy for 1inch router
     * @param oneInch Address of 1inch router
     * @param strategy Address of strategy for 1inch router
     */
    function set1InchStrategy(address oneInch, address strategy) external onlyOwner {
        oneInchStrategies[oneInch] = strategy;
    }

    /**
     * @dev Set strategy for firebird router
     * @param fireBird Address of firebird router
     * @param strategy Address of strategy for firebird router
     */
    function setFireBirdStrategy(address fireBird, address strategy) external onlyOwner {
        fireBirdStrategies[fireBird] = strategy;
    }

    /**
     * @dev Set strategy for odos router
     * @param odos Address of odos router
     * @param strategy Address of strategy for odos router
     */
    function setOdosStrategy(address odos, address strategy) external onlyOwner {
        odosStrategies[odos] = strategy;
    }

    /**
     * @dev Set strategy for paraswap router
     * @param para Address of paraswap router
     * @param strategy Address of strategy for paraswap router
     */
    function setParaStrategy(address para, address strategy) external onlyOwner {
        paraStrategies[para] = strategy;
    }

    /**
     * @dev Set the whitelist status of an address.
     * @param user Address of user
     * @param isWhitelist If true, add the address to the whitelist. If false, remove it from the whitelist.
     */
    function setWhitelist(address user, bool isWhitelist) external onlyOwner {
        whitelist[user] = isWhitelist;
    }

    /**
     * @dev Set the default strategies
     */
    function setup(
        address uniV2Strategy,
        address vaultStrategy,
        address uniV3Strategy,
        address oneInchStrategy,
        address fireBirdStrategy,
        address odosStrategy,
        address paraStrategy
    ) external onlyOwner {
        defaultUniV2Strategy = uniV2Strategy;
        defaultVaultStrategy = vaultStrategy;
        defaultUniV3Strategy = uniV3Strategy;
        default1InchStrategy = oneInchStrategy;
        defaultFireBirdStrategy = fireBirdStrategy;
        defaultOdosStrategy = odosStrategy;
        defaultParaStrategy = paraStrategy;
    }

    /**
     * @dev Pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Resume the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Get balance of this contract.
     */
    function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Ensure we got a profit
     */
    function _ensureProfit(uint256 amountIn, IERC20Upgradeable tokenOut) internal returns (uint256 actualAmountOut) {
        if (tokenOut == ZERO_ADDRESS) {
            actualAmountOut = getBalance();
            payable(_msgSender()).sendValue(actualAmountOut);
        } else {
            actualAmountOut = tokenOut.balanceOf(address(this));
            tokenOut.transfer(_msgSender(), actualAmountOut);
        }
        _require(actualAmountOut > amountIn, Errors.NO_PROFIT);
    }

    /**
     * @dev Transfer profit to treasury
     */
    function _transferProfit(uint256 amountIn, IERC20Upgradeable tokenOut) internal returns (uint256 profit) {
        uint256 amountOut;
        if (tokenOut == ZERO_ADDRESS) amountOut = getBalance();
        else amountOut = tokenOut.balanceOf(address(this));

        _require(amountOut > amountIn, Errors.NO_PROFIT);

        profit = amountOut - amountIn;
        if (tokenOut == ZERO_ADDRESS) payable(treasury).sendValue(profit);
        else tokenOut.safeTransfer(treasury, profit);
    }

    /**
     * @dev Get limits for vault
     */
    function getLimitsForVault(uint length) internal pure returns (int256[] memory) {
        int256[] memory limits = new int256[](length);
        for (uint256 i = 0; i < length; i++) {
            limits[i] = type(int256).max;
        }
        return limits;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import './libraries/Errors.sol';

abstract contract WithdrawableUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    // constants
    IERC20Upgradeable internal constant ZERO_ADDRESS = IERC20Upgradeable(address(0));

    // state variables
    address public treasury; // Address to transfer profit

    modifier withdrawable(address _to) {
        _require(_to == treasury || _to == owner(), Errors.NOT_WITHDRAWABLE);
        _;
    }

    // solhint-disable-next-line
    function __Withdrawable_init() internal initializer {
        __Ownable_init_unchained();
        __Withdrawable_init_unchained();
    }

    // solhint-disable-next-line
    function __Withdrawable_init_unchained() internal initializer {}

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function withdraw(IERC20Upgradeable _token, address _to, uint _amount) external onlyOwner withdrawable(_to) {
        if (_token == ZERO_ADDRESS) payable(_to).sendValue(_amount);
        else _token.safeTransfer(_to, _amount);
    }

    function withdrawAll(IERC20Upgradeable _token, address _to) external onlyOwner withdrawable(_to) {
        if (_token == ZERO_ADDRESS) payable(_to).sendValue(address(this).balance);
        else _token.safeTransfer(_to, _token.balanceOf(address(this)));
    }
}