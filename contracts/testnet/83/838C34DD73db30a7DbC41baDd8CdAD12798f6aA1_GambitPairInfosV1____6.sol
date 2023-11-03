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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStableCoinDecimals {
    function usdcDecimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library GambitErrorsV1 {
    // msg.sender is not gov
    error NotGov();

    // msg.sender is not manager (GambitPairInfosV1)
    error NotManager();

    // msg.sender is not trading contract
    error NotTrading();

    // msg.sender is not callback contract
    error NotCallbacks();

    // msg.sender is not price aggregator contract
    error NotAggregator();

    error NotTimelockOwner();
    error NotTradingOrCallback();
    error NotNftRewardsOrReferralsOrCallbacks();
    error ZeroAddress();

    // Not authorized
    error NoAuth();

    // contract is not done
    error NotDone();

    // contract is done
    error Done();

    // contract is not paused
    error NotPaused();

    // contract is paused
    error Paused();

    // Wrong parameters
    error WrongParams();

    // Wrong length of array
    error WrongLength();

    // Wrong order of array
    error WrongOrder();

    // unknown group id
    error GroupNotListed();
    // unknown fee id
    error FeeNotListed();
    // unknown pair id
    error PairNotListed();

    error AlreadyListedPair();

    // invalid data for group
    error WrongGroup();
    // invalid data for pair
    error InvalidPair();
    // invalid data for fee
    error WrongFee();
    // invalid data for feed
    error WrongFeed();

    // stablecoin decimals mismatch
    error StablecoinDecimalsMismatch();

    // zero value
    error ZeroValue();

    // same value
    error SameValue();

    // trade errors
    error MaxTradesPerPair();
    error MaxPendingOrders();
    error NoTrade();
    error AboveMaxPos();
    error BelowMinPos();
    error AlreadyBeingClosed();
    error LeverageIncorrect();
    error NoCorrespondingNftSpreadReduction();
    error WrongTp();
    error WrongSl();
    error PriceImpactTooHigh();
    error NoLimit();
    error LimitTimelock();
    error AbovePos();
    error BelowFee();
    error WrongNftType();
    error NoNFT();
    error HasSl();
    error NoSl();
    error NoTp();
    error PriceFeedFailed();
    error WaitTimeout();
    error NotYourOrder();
    error WrongMarketOrderType();

    // address is zero
    error ZeroAdress();

    // pyth caller doesn't have enough balance to pay the fee
    error InsufficientPythFee();

    // value is too high
    error TooHigh();
    // value is too low
    error TooLow();

    // price errors
    error InvalidPrice();
    error InvalidChainlinkPrice();
    error InvalidPythPrice();
    error InvalidPythExpo();

    // nft reward trigger timing error
    error TooLate();
    error TooEarly();
    error SameBlockLimit();
    error NotTriggered();
    error NothingToClaim();

    // referral
    error InvalidTailingZero();
    error RewardUnavailable();

    // trading storage
    error AlreadyAddedToken();
    error NotOpenLimitOrder();

    // SimpleGToken
    error ZeroPrice();
    error PendingWithdrawal();
    error EndOfEpoch();
    error NotAllowed();
    error NotTradingPnlHandler();
    error NotPnlFeed();
    error MaxDailyPnl();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../common/IStableCoinDecimals.sol";
import "../trading-storage/interfaces/IGambitTradingStorageV1.sol";

import "../GambitErrorsV1.sol";

abstract contract GambitPairInfosV1 is IStableCoinDecimals, Initializable {
    bytes32[63] private _gap0; // storage slot gap (1 slot for Initializeable)

    // Addresses
    IGambitTradingStorageV1 public storageT;
    address public manager;

    bytes32[62] private _gap1; // storage slot gap (2 slots for above variables)

    // Params (constant)
    uint constant PRECISION = 1e10; // 10 decimals
    uint constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)
    uint constant MAX_ROLLOVER_FEE_PER_BLOCK_P = 25000000; // 0.0025%
    uint constant MAX_FULDING_FEE_PER_BLOCK_P = 10000000; // 0.001%

    bytes32[64] private _gap2; // storage slot gap (no slot allocated yet)

    // Params (adjustable)
    uint public maxNegativePnlOnOpenP; // PRECISION (%)

    bytes32[63] private _gap3; // storage slot gap (1 slot for above variable)

    // Pair parameters
    struct PairParams {
        uint onePercentDepthAbove; // 1e6 (USDC) or 1e18 (DAI)
        uint onePercentDepthBelow; // 1e6 (USDC) or 1e18 (DAI)
        uint rolloverFeePerBlockP; // PRECISION (%)
        uint fundingFeePerBlockP; // PRECISION (%)
    }

    mapping(uint => PairParams) public pairParams;

    // Pair acc funding fees
    struct PairFundingFees {
        int accPerOiLong; // 1e6 (USDC) or 1e18 (DAI)
        int accPerOiShort; // 1e6 (USDC) or 1e18 (DAI)
        uint lastUpdateBlock;
    }

    mapping(uint => PairFundingFees) public pairFundingFees;

    // Pair acc rollover fees
    struct PairRolloverFees {
        uint accPerCollateral; // 1e6 (USDC) or 1e18 (DAI)
        uint lastUpdateBlock;
    }

    mapping(uint => PairRolloverFees) public pairRolloverFees;

    // Trade initial acc fees
    struct TradeInitialAccFees {
        uint rollover; // 1e6 (USDC) or 1e18 (DAI)
        int funding; // 1e6 (USDC) or 1e18 (DAI)
        bool openedAfterUpdate;
    }

    mapping(address => mapping(uint => mapping(uint => TradeInitialAccFees)))
        public tradeInitialAccFees;

    bytes32[60] private _gap4; // storage slot gap (4 slots for above variables)

    // Events
    event ManagerUpdated(address indexed value);
    event MaxNegativePnlOnOpenPUpdated(uint value);

    event PairParamsUpdated(uint indexed pairIndex, PairParams value);
    event OnePercentDepthUpdated(
        uint pairIndex,
        uint valueAbove,
        uint valueBelow
    );
    event RolloverFeePerBlockPUpdated(uint indexed pairIndex, uint value);
    event FundingFeePerBlockPUpdated(uint indexed pairIndex, uint value);

    event TradeInitialAccFeesStored(
        address trader,
        uint pairIndex,
        uint index,
        uint rollover,
        int funding
    );

    event AccFundingFeesStored(
        uint indexed pairIndex,
        int valueLong,
        int valueShort
    );
    event AccRolloverFeesStored(uint indexed pairIndex, uint value);

    event FeesCharged(
        uint indexed pairIndex,
        bool long,
        uint collateral, // 1e6 (USDC) or 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint rolloverFees, // 1e6 (USDC) or 1e18 (DAI)
        int fundingFees // 1e6 (USDC) or 1e18 (DAI)
    );

    // Modifiers
    modifier onlyGov() {
        if (msg.sender != storageT.gov()) revert GambitErrorsV1.NotGov();
        _;
    }
    modifier onlyManager() {
        if (msg.sender != manager) revert GambitErrorsV1.NotManager();
        _;
    }
    modifier onlyCallbacks() {
        if (msg.sender != storageT.callbacks())
            revert GambitErrorsV1.NotCallbacks();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    // Initialize proxy
    function initialize(
        IGambitTradingStorageV1 _storageT
    ) external initializer {
        if (
            IERC20MetadataUpgradeable(address(_storageT.usdc())).decimals() !=
            usdcDecimals()
        ) revert GambitErrorsV1.StablecoinDecimalsMismatch();

        storageT = _storageT;
        maxNegativePnlOnOpenP = 40 * PRECISION; // PRECISION (%)
    }

    // Set manager address
    function setManager(address _manager) external onlyGov {
        manager = _manager;

        emit ManagerUpdated(_manager);
    }

    // Set max negative PnL % on trade opening
    function setMaxNegativePnlOnOpenP(uint value) external onlyManager {
        maxNegativePnlOnOpenP = value;

        emit MaxNegativePnlOnOpenPUpdated(value);
    }

    // Set parameters for pair
    function setPairParams(
        uint pairIndex,
        PairParams calldata value
    ) public onlyManager {
        if (value.rolloverFeePerBlockP > MAX_ROLLOVER_FEE_PER_BLOCK_P)
            revert GambitErrorsV1.TooHigh(); // ≈ 100% per day
        if (value.fundingFeePerBlockP > MAX_FULDING_FEE_PER_BLOCK_P)
            revert GambitErrorsV1.TooHigh(); // ≈ 40% per day

        storeAccRolloverFees(pairIndex);
        storeAccFundingFees(pairIndex);

        pairParams[pairIndex] = value;

        emit PairParamsUpdated(pairIndex, value);
    }

    /**
     * @dev the size of indices, values should be small enough to prevent going out of gas
     */
    function setPairParamsArray(
        uint[] calldata indices,
        PairParams[] calldata values
    ) external onlyManager {
        if (indices.length != values.length)
            revert GambitErrorsV1.WrongLength();

        for (uint i = 0; i < indices.length; i++) {
            setPairParams(indices[i], values[i]);
        }
    }

    // Set one percent depth for pair
    function setOnePercentDepth(
        uint pairIndex,
        uint valueAbove,
        uint valueBelow
    ) public onlyManager {
        PairParams storage p = pairParams[pairIndex];

        p.onePercentDepthAbove = valueAbove;
        p.onePercentDepthBelow = valueBelow;

        emit OnePercentDepthUpdated(pairIndex, valueAbove, valueBelow);
    }

    /**
     * @dev the size of indices, valuesAbove, valuesBelow should be small enough to prevent going out of gas
     */
    function setOnePercentDepthArray(
        uint[] calldata indices,
        uint[] calldata valuesAbove,
        uint[] calldata valuesBelow
    ) external onlyManager {
        if (
            indices.length != valuesAbove.length ||
            indices.length != valuesBelow.length
        ) revert GambitErrorsV1.WrongLength();

        for (uint i = 0; i < indices.length; i++) {
            setOnePercentDepth(indices[i], valuesAbove[i], valuesBelow[i]);
        }
    }

    // Set rollover fee for pair
    function setRolloverFeePerBlockP(
        uint pairIndex,
        uint value
    ) public onlyManager {
        if (value > MAX_ROLLOVER_FEE_PER_BLOCK_P)
            revert GambitErrorsV1.TooHigh(); // ≈ 100% per day

        storeAccRolloverFees(pairIndex);

        pairParams[pairIndex].rolloverFeePerBlockP = value;

        emit RolloverFeePerBlockPUpdated(pairIndex, value);
    }

    /**
     * @dev the size of indices, values should be small enough to prevent going out of gas
     */
    function setRolloverFeePerBlockPArray(
        uint[] calldata indices,
        uint[] calldata values
    ) external onlyManager {
        if (indices.length != values.length)
            revert GambitErrorsV1.WrongLength();

        for (uint i = 0; i < indices.length; i++) {
            setRolloverFeePerBlockP(indices[i], values[i]);
        }
    }

    // Set funding fee for pair
    function setFundingFeePerBlockP(
        uint pairIndex,
        uint value
    ) public onlyManager {
        if (value > MAX_FULDING_FEE_PER_BLOCK_P)
            revert GambitErrorsV1.TooHigh(); // ≈ 40% per day

        storeAccFundingFees(pairIndex);

        pairParams[pairIndex].fundingFeePerBlockP = value;

        emit FundingFeePerBlockPUpdated(pairIndex, value);
    }

    /**
     * @dev the size of indices, values should be small enough to prevent going out of gas
     */
    function setFundingFeePerBlockPArray(
        uint[] calldata indices,
        uint[] calldata values
    ) external onlyManager {
        if (indices.length != values.length)
            revert GambitErrorsV1.WrongLength();

        for (uint i = 0; i < indices.length; i++) {
            setFundingFeePerBlockP(indices[i], values[i]);
        }
    }

    // Store trade details when opened (acc fee values)
    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external onlyCallbacks {
        storeAccFundingFees(pairIndex);

        TradeInitialAccFees storage t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        t.rollover = getPendingAccRolloverFees(pairIndex);

        t.funding = long
            ? pairFundingFees[pairIndex].accPerOiLong
            : pairFundingFees[pairIndex].accPerOiShort;

        t.openedAfterUpdate = true;

        emit TradeInitialAccFeesStored(
            trader,
            pairIndex,
            index,
            t.rollover,
            t.funding
        );
    }

    // Acc rollover fees (store right before fee % update)
    function storeAccRolloverFees(uint pairIndex) private {
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        r.accPerCollateral = getPendingAccRolloverFees(pairIndex);
        r.lastUpdateBlock = block.number;

        emit AccRolloverFeesStored(pairIndex, r.accPerCollateral);
    }

    // correct: 1e6, incorrect: 1e12
    function getPendingAccRolloverFees(
        uint pairIndex
    )
        public
        view
        returns (
            uint // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        // 1e6 (USDC) or 1e18 (DAI)
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        return
            r.accPerCollateral +
            // USDC: 1e6 = 1e10 * "1e6" / 1e10
            // DAI: 1e18 = 1e10 * "1e18" / 1e10
            ((block.number - r.lastUpdateBlock) *
                pairParams[pairIndex].rolloverFeePerBlockP *
                10 ** (usdcDecimals())) /
            PRECISION /
            100;
    }

    // Acc funding fees (store right before trades opened / closed and fee % update)
    function storeAccFundingFees(uint pairIndex) private {
        PairFundingFees storage f = pairFundingFees[pairIndex];

        (f.accPerOiLong, f.accPerOiShort) = getPendingAccFundingFees(pairIndex);
        f.lastUpdateBlock = block.number;

        emit AccFundingFeesStored(pairIndex, f.accPerOiLong, f.accPerOiShort);
    }

    function getOpenPnL(
        uint pairIndex,
        uint currentPrice // 1e10
    )
        public
        view
        returns (
            int pnl // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        pnl =
            getOpenPnLSide(pairIndex, currentPrice, true) +
            getOpenPnLSide(pairIndex, currentPrice, false);
    }

    function getOpenPnLSide(
        uint pairIndex,
        uint currentPrice, // 1e10
        bool buy // true = long, false = short
    )
        public
        view
        returns (
            int pnl // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        uint index = buy ? 0 : 1;
        uint openInterestToken = storageT.openInterestToken(pairIndex, index); // 1e15 (USDC or DAI)
        uint openInterestUsdc = storageT.openInterestUsdc(pairIndex, index); // 1e6 (USDC) or 1e18 (DAI)

        if (openInterestToken == 0 || openInterestUsdc == 0) return 0;

        // 1e19 (USDC) or 1e7 (DAI)
        uint d = 10 ** (25 - usdcDecimals());

        // USDC: 1e10 = 1e6  * "1e19" / 1e15
        // DAI:  1e10 = 1e18 * "1e7" / 1e15
        uint avgOpenPrice = (openInterestUsdc * d) / openInterestToken;

        // 1e10
        int priceDiff = (
            avgOpenPrice > currentPrice
                ? -int(avgOpenPrice - currentPrice) // price drop => loss (long)
                : int(currentPrice - avgOpenPrice) // price rise => profit (long)
        );

        // reverse direction if short
        if (!buy) priceDiff *= -1;

        // USDC: 1e6  = 1e10 * 1e15 / "1e19"
        // DAI:  1e18 = 1e10 * 1e15 / "1e7"
        pnl = (priceDiff * int(openInterestToken)) / int(d);
    }

    function getPendingAccFundingFees(
        uint pairIndex
    )
        public
        view
        returns (
            int valueLong, // 1e6 (USDC) or 1e18 (DAI)
            int valueShort // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        PairFundingFees storage f = pairFundingFees[pairIndex];

        valueLong = f.accPerOiLong;
        valueShort = f.accPerOiShort;

        // 1e6 (USDC) or 1e18 (DAI)
        int openInterestUsdcLong = int(storageT.openInterestUsdc(pairIndex, 0));
        int openInterestUsdcShort = int(
            storageT.openInterestUsdc(pairIndex, 1)
        );

        // 1e6 (USDC) or 1e18 (DAI)
        int fundingFeesPaidByLongs = ((openInterestUsdcLong -
            openInterestUsdcShort) *
            int(block.number - f.lastUpdateBlock) *
            int(pairParams[pairIndex].fundingFeePerBlockP)) /
            int(PRECISION) /
            100;

        int d = int(10 ** usdcDecimals());

        if (openInterestUsdcLong > 0) {
            valueLong += (fundingFeesPaidByLongs * d) / openInterestUsdcLong;
        }

        if (openInterestUsdcShort > 0) {
            valueShort +=
                (fundingFeesPaidByLongs * d * (-1)) /
                openInterestUsdcShort;
        }
    }

    // Dynamic price impact value on trade opening
    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint tradeOpenInterest // 1e6 (USDC) or 1e18 (DAI)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        )
    {
        (priceImpactP, priceAfterImpact) = getTradePriceImpactPure(
            openPrice,
            long,
            storageT.openInterestUsdc(pairIndex, long ? 0 : 1),
            tradeOpenInterest,
            long
                ? pairParams[pairIndex].onePercentDepthAbove
                : pairParams[pairIndex].onePercentDepthBelow
        );
    }

    function getTradePriceImpactPure(
        uint openPrice, // PRECISION
        bool long,
        uint startOpenInterest, // 1e6 (USDC) or 1e18 (DAI)
        uint tradeOpenInterest, // 1e6 (USDC) or 1e18 (DAI)
        uint onePercentDepth // 1e6 (USDC) or 1e18 (DAI)
    )
        public
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        )
    {
        if (onePercentDepth == 0) {
            return (0, openPrice);
        }

        // USDC: 1e10 = 1e6  * 1e10 / 1e6
        // DAI:  1e10 = 1e18 * 1e10 / 1e18
        priceImpactP =
            ((startOpenInterest + tradeOpenInterest / 2) * PRECISION) /
            onePercentDepth;

        uint priceImpact = (priceImpactP * openPrice) / PRECISION / 100;

        priceAfterImpact = long
            ? openPrice + priceImpact
            : openPrice - priceImpact;
    }

    // Rollover fee value
    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // 1e6 (USDC) or 1e18 (DAI)
    ) public view returns (uint) {
        // 1e6 (USDC) or 1e18 (DAI)
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        return
            getTradeRolloverFeePure(
                t.rollover,
                getPendingAccRolloverFees(pairIndex),
                collateral
            );
    }

    function getTradeRolloverFeePure(
        uint accRolloverFeesPerCollateral, // 1e6 (USDC) or 1e18 (DAI)
        uint endAccRolloverFeesPerCollateral, // 1e6 (USDC) or 1e18 (DAI)
        uint collateral // 1e6 (USDC) or 1e18 (DAI)
    ) public view returns (uint) {
        // 1e6 (USDC) or 1e18 (DAI)
        return
            ((endAccRolloverFeesPerCollateral - accRolloverFeesPerCollateral) *
                collateral) / (10 ** usdcDecimals());
    }

    // Funding fee value
    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e6 (USDC) or 1e18 (DAI)
        uint leverage
    )
        public
        view
        returns (
            int // 1e6 (USDC) or 1e18 (DAI) | Positive => Fee, Negative => Reward
        )
    {
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        (int pendingLong, int pendingShort) = getPendingAccFundingFees(
            pairIndex
        );

        return
            getTradeFundingFeePure(
                t.funding,
                long ? pendingLong : pendingShort,
                collateral,
                leverage
            );
    }

    function getTradeFundingFeePure(
        int accFundingFeesPerOi, // 1e6 (USDC) or 1e18 (DAI)
        int endAccFundingFeesPerOi, // 1e6 (USDC) or 1e18 (DAI)
        uint collateral, // 1e6 (USDC) or 1e18 (DAI)
        uint leverage
    )
        public
        view
        returns (
            int // 1e6 (USDC) or 1e18 (DAI) | Positive => Fee, Negative => Reward
        )
    {
        return
            ((endAccFundingFeesPerOi - accFundingFeesPerOi) *
                int(collateral) *
                int(leverage)) /
            int(10 ** usdcDecimals()) /
            1e18;
    }

    // Liquidation price value after rollover and funding fees
    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e6 (USDC) or 1e18 (DAI)
        uint leverage
    ) external view returns (uint) {
        // PRECISION
        return
            getTradeLiquidationPricePure(
                openPrice,
                long,
                collateral,
                leverage,
                getTradeRolloverFee(trader, pairIndex, index, collateral),
                getTradeFundingFee(
                    trader,
                    pairIndex,
                    index,
                    long,
                    collateral,
                    leverage
                )
            );
    }

    function getTradeLiquidationPricePure(
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e6 (USDC) or 1e18 (DAI)
        uint leverage,
        uint rolloverFee, // 1e6 (USDC) or 1e18 (DAI)
        int fundingFee // 1e6 (USDC) or 1e18 (DAI)
    )
        public
        pure
        returns (
            uint // 1e10
        )
    {
        // PRECISION
        int liqPriceDistance = ((int(openPrice) *
            (int((collateral * LIQ_THRESHOLD_P) / 100) -
                int(rolloverFee) -
                fundingFee)) * 1e18) /
            int(collateral) /
            int(leverage);

        int liqPrice = long
            ? int(openPrice) - liqPriceDistance
            : int(openPrice) + liqPriceDistance;

        return liqPrice > 0 ? uint(liqPrice) : 0;
    }

    // Usdc sent to trader after PnL and fees
    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e6 (USDC) or 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e6 (USDC) or 1e18 (DAI)
    )
        external
        onlyCallbacks
        returns (
            uint amount // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        storeAccFundingFees(pairIndex);

        uint r = getTradeRolloverFee(trader, pairIndex, index, collateral);
        int f = getTradeFundingFee(
            trader,
            pairIndex,
            index,
            long,
            collateral,
            leverage
        );

        amount = getTradeValuePure(collateral, percentProfit, r, f, closingFee);

        emit FeesCharged(
            pairIndex,
            long,
            collateral,
            leverage,
            percentProfit,
            r,
            f
        );
    }

    function getTradeValuePure(
        uint collateral, // 1e6 (USDC) or 1e18 (DAI)
        int percentProfit, // PRECISION (%)
        uint rolloverFee, // 1e6 (USDC) or 1e18 (DAI)
        int fundingFee, // 1e6 (USDC) or 1e18 (DAI)
        uint closingFee // 1e6 (USDC) or 1e18 (DAI)
    )
        public
        pure
        returns (
            uint // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        // 1e6 (USDC) or 1e18 (DAI)
        int value = int(collateral) +
            (int(collateral) * percentProfit) /
            int(PRECISION) /
            100 -
            int(rolloverFee) -
            fundingFee;

        if (value <= (int(collateral) * int(100 - LIQ_THRESHOLD_P)) / 100) {
            return 0;
        }

        value -= int(closingFee);

        return value > 0 ? uint(value) : 0;
    }

    // Useful getters
    function getPairInfos(
        uint[] calldata indices
    )
        external
        view
        returns (
            PairParams[] memory,
            PairRolloverFees[] memory,
            PairFundingFees[] memory
        )
    {
        PairParams[] memory params = new PairParams[](indices.length);
        PairRolloverFees[] memory rolloverFees = new PairRolloverFees[](
            indices.length
        );
        PairFundingFees[] memory fundingFees = new PairFundingFees[](
            indices.length
        );

        for (uint i = 0; i < indices.length; i++) {
            uint index = indices[i];

            params[i] = pairParams[index];
            rolloverFees[i] = pairRolloverFees[index];
            fundingFees[i] = pairFundingFees[index];
        }

        return (params, rolloverFees, fundingFees);
    }

    function getOnePercentDepthAbove(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].onePercentDepthAbove;
    }

    function getOnePercentDepthBelow(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].onePercentDepthBelow;
    }

    function getRolloverFeePerBlockP(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].rolloverFeePerBlockP;
    }

    function getFundingFeePerBlockP(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].fundingFeePerBlockP;
    }

    function getAccRolloverFees(uint pairIndex) external view returns (uint) {
        return pairRolloverFees[pairIndex].accPerCollateral;
    }

    function getAccRolloverFeesUpdateBlock(
        uint pairIndex
    ) external view returns (uint) {
        return pairRolloverFees[pairIndex].lastUpdateBlock;
    }

    function getAccFundingFeesLong(uint pairIndex) external view returns (int) {
        return pairFundingFees[pairIndex].accPerOiLong;
    }

    function getAccFundingFeesShort(
        uint pairIndex
    ) external view returns (int) {
        return pairFundingFees[pairIndex].accPerOiShort;
    }

    function getAccFundingFeesUpdateBlock(
        uint pairIndex
    ) external view returns (uint) {
        return pairFundingFees[pairIndex].lastUpdateBlock;
    }

    function getTradeInitialAccRolloverFeesPerCollateral(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (uint) {
        return tradeInitialAccFees[trader][pairIndex][index].rollover;
    }

    function getTradeInitialAccFundingFeesPerOi(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (int) {
        return tradeInitialAccFees[trader][pairIndex][index].funding;
    }

    function getTradeOpenedAfterUpdate(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (bool) {
        return tradeInitialAccFees[trader][pairIndex][index].openedAfterUpdate;
    }

    struct ExposureCalcParamsStruct {
        uint pairIndex;
        bool buy;
        uint positionSizeUsdc;
        uint leverage;
        uint currentPrice; // 1e10
        uint openPrice; // 1e10
    }

    function isWithinExposureLimits(
        ExposureCalcParamsStruct memory params
    ) external view returns (bool) {
        IGambitPairsStorageV1 pairsStored = storageT
            .priceAggregator()
            .pairsStorage();

        // NOTE: checking net exposure (smaller, balanced) is diabled for now. Below commented code is left for the future.
        // // exposure = col * lev + pnl
        // // new exposure of the trade
        // // 1e6 (USDC) or 1e18 (DAI)
        // int newExp = int(
        //     (params.positionSizeUsdc *
        //         params.leverage *
        //         (params.openPrice -
        //             (
        //                 params.buy
        //                     ? (params.openPrice - params.currentPrice)
        //                     : (params.currentPrice - params.openPrice)
        //             ))) /
        //         params.openPrice /
        //         1e18
        // );

        // int newExpDiff; // = diff(new long exposure, new short exposure)
        // int expDiff; // = diff(long exposure, short exposure)

        // // scope for pairPnl{Long,Short} and {long,short}Exp
        // {
        //     int pairPnlLong = getOpenPnLSide(
        //         params.pairIndex,
        //         params.currentPrice,
        //         true
        //     );
        //     int pairPnlShort = getOpenPnLSide(
        //         params.pairIndex,
        //         params.currentPrice,
        //         false
        //     );
        //     int longExp = int(storageT.openInterestUsdc(params.pairIndex, 0)) +
        //         pairPnlLong;
        //     int shortExp = int(storageT.openInterestUsdc(params.pairIndex, 1)) +
        //         pairPnlShort;
        //     newExpDiff = diff(
        //         params.buy ? longExp + newExp : longExp,
        //         params.buy ? shortExp : shortExp + newExp
        //     );
        //     expDiff = diff(longExp, shortExp);
        // }

        uint vaultUsdc = storageT.vault().currentBalanceUsdc();

        return
            (// max open interest := open interest after trade < max open interest
            storageT.openInterestUsdc(params.pairIndex, params.buy ? 0 : 1) +
                (params.positionSizeUsdc * params.leverage) /
                1e18 <=
                storageT.openInterestUsdc(params.pairIndex, 2)) &&
            // NOTE: checking net exposure (smaller, balanced) is diabled for now. Below commented code is left for the future.
            // (// smaller net exposure or balanced net exposure
            // (// smaller net exposure := exposure diff after trade < exposure diff before trade
            // newExpDiff < expDiff) ||
            //     (// balanced net exposure := (exposure diff after trade) < vault balance * ExposureUtilsP
            //     abs(newExpDiff) <=
            //         int(
            //             (vaultUsdc *
            //                 pairsStored.pairExposureUtilsP(params.pairIndex)) /
            //                 100
            //         ))) &&
            (// within collateral := (group collateral after trade) < vault balance * MaxCollateralP
            pairsStored.groupCollateral(params.pairIndex, params.buy) +
                params.positionSizeUsdc <=
                (vaultUsdc *
                    pairsStored.groupMaxCollateralP(params.pairIndex)) /
                    100);
    }

    function usdcDecimals() public pure virtual returns (uint8);

    function abs(int a) internal pure returns (int) {
        return a > 0 ? a : -a;
    }

    function diff(int a, int b) internal pure returns (int) {
        return abs(a - b);
    }
}

/**
 * @dev GambitPairInfosV1 with stablecoin decimals set to 6.
 */
contract GambitPairInfosV1____6 is GambitPairInfosV1 {
    function usdcDecimals() public pure override returns (uint8) {
        return 6;
    }
}

/**
 * @dev GambitPairInfosV1 with stablecoin decimals set to 18.
 */
contract GambitPairInfosV1____18 is GambitPairInfosV1 {
    function usdcDecimals() public pure override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGambitPairsStorageV1 {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        bytes32 priceId1;
        bytes32 priceId2;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(
        uint
    ) external returns (string memory, string memory, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairConfMultiplierP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFeeP(uint) external view returns (uint);

    function pairNftLimitOrderFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosUsdc(uint) external view returns (uint);

    function pairsCount() external view returns (uint);

    function pairExposureUtilsP(uint) external view returns (uint);

    function groupMaxCollateralP(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../vault/interfaces/ISimpleGToken.sol";
import "../../pair-storage/interfaces/IGambitPairsStorageV1.sol";

import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

interface IGambitTradingStorageV1 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint openPrice; // PRECISION
        bool buy;
        uint leverage; // 1e18
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUsdc; // PRECISION
        uint openInterestUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e6 (USDC) or 1e18 (DAI)
        uint spreadReductionP;
        bool buy;
        uint leverage; // 1e18
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    struct PendingRemoveCollateralOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint amount;
        uint openPrice;
        bool buy;
    }

    function PRECISION() external pure returns (uint);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function usdc() external view returns (IERC20);

    function usdcDecimals() external view returns (uint8);

    function token() external view returns (TokenInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

    function vault() external view returns (ISimpleGToken);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferUsdc(address, address, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint,
        bool
    ) external;

    function openTrades(
        address,
        uint,
        uint
    ) external view returns (Trade memory);

    function openTradesInfo(
        address,
        uint,
        uint
    ) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(
        uint
    ) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function reqID_pendingRemoveCollateralOrder(
        uint
    ) external view returns (PendingRemoveCollateralOrder memory);

    function storePendingRemoveCollateralOrder(
        PendingRemoveCollateralOrder memory,
        uint
    ) external;

    function unregisterPendingRemoveCollateralOrder(uint) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(
        address,
        uint
    ) external view returns (uint);

    function increaseNftRewards(uint, uint) external;

    function nftSuccessTimelock() external view returns (uint);

    function reqID_pendingNftOrder(
        uint
    ) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint) external view returns (uint);

    function unregisterPendingNftOrder(uint) external;

    function handleDevGovFees(uint, uint, bool) external returns (uint);

    function getDevGovFees(uint, uint, bool) external view returns (uint);

    function distributeLpRewards(uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(
        address,
        uint
    ) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function openInterestUsdc(uint, uint) external view returns (uint);

    function openInterestToken(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function nfts(uint) external view returns (NftInterfaceV5);

    function fakeBlockNumber() external view returns (uint); // Testing
}

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL,
        REMOVE_COLLATERAL
    }

    function pyth() external returns (IPyth);

    function PYTH_PRICE_AGE() external returns (uint);

    function pairsStorage() external view returns (IGambitPairsStorageV1);

    function getPrice(uint, OrderType, uint) external returns (uint);

    function fulfill(
        uint orderId,
        bytes[] calldata priceUpdateData
    ) external payable returns (uint256 price, uint256 conf, bool success);

    function tokenPriceUsdc() external returns (uint);

    function openFeeP(uint) external view returns (uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }
}

interface NftRewardsInterfaceV6 {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        IGambitTradingStorageV1.LimitOrder order;
    }
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeNftReward(TriggeredLimitId calldata, uint) external;

    function openLimitOrderTypes(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(
        address,
        uint,
        uint,
        OpenLimitOrderType
    ) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISimpleGToken {
    function manager() external view returns (address);

    function gov() external view returns (address);

    function currentEpoch() external view returns (uint);

    function currentEpochStart() external view returns (uint);

    function currentEpochPositiveOpenPnl() external view returns (uint);

    function updateAccPnlPerTokenUsed(
        uint prevPositiveOpenPnl,
        uint newPositiveOpenPnl
    ) external returns (uint);

    function sendAssets(uint assets, address receiver) external;

    function receiveAssets(uint assets, address user) external;

    function distributeReward(uint assets) external;

    function currentBalanceUsdc() external view returns (uint);
}