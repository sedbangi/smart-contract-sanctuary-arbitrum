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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Constants {
    uint8 internal constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 internal constant BASIS_POINTS_DIVISOR = 100000;
    uint256 internal constant LIQUIDATE_THRESHOLD_DIVISOR = 10 * BASIS_POINTS_DIVISOR;
    uint256 internal constant DEFAULT_VLP_PRICE = 100000;
    uint256 internal constant FUNDING_RATE_PRECISION = BASIS_POINTS_DIVISOR ** 3; // 1e15
    uint256 internal constant MAX_DEPOSIT_WITHDRAW_FEE = 10000; // 10%
    uint256 internal constant MAX_DELTA_TIME = 24 hours;
    uint256 internal constant MAX_COOLDOWN_DURATION = 30 days;
    uint256 internal constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 internal constant MAX_PRICE_MOVEMENT_PERCENT = 10000; // 10%
    uint256 internal constant MAX_BORROW_FEE_FACTOR = 500; // 0.5% per hour
    uint256 internal constant MAX_FUNDING_RATE = FUNDING_RATE_PRECISION / 10; // 10% per hour
    uint256 internal constant MAX_STAKING_UNSTAKING_FEE = 10000; // 10%
    uint256 internal constant MAX_EXPIRY_DURATION = 60; // 60 seconds
    uint256 internal constant MAX_SELF_EXECUTE_COOLDOWN = 300; // 5 minutes
    uint256 internal constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 internal constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_MARKET_ORDER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_VESTING_DURATION = 700 days;
    uint256 internal constant MIN_LEVERAGE = 10000; // 1x
    uint256 internal constant POSITION_MARKET = 0;
    uint256 internal constant POSITION_LIMIT = 1;
    uint256 internal constant POSITION_STOP_MARKET = 2;
    uint256 internal constant POSITION_STOP_LIMIT = 3;
    uint256 internal constant POSITION_TRAILING_STOP = 4;
    uint256 internal constant PRICE_PRECISION = 10 ** 30;
    uint256 internal constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 internal constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 internal constant VLP_DECIMALS = 18;

    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function checkSlippage(bool isLong, uint256 allowedPrice, uint256 actualMarketPrice) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <= allowedPrice,
                string(
                    abi.encodePacked(
                        "long: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        } else {
            require(
                actualMarketPrice >= allowedPrice,
                string(
                    abi.encodePacked(
                        "short: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Order, OrderType, OrderStatus, AddPositionOrder, DecreasePositionOrder, PositionTrigger} from "../structs.sol";

interface IOrderVault {
    function addTrailingStop(address _account, uint256 _posId, uint256[] memory _params) external;

    function addTriggerOrders(
        uint256 _posId,
        address _account,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) external;

    function cancelPendingOrder(address _account, uint256 _posId) external;

    function updateOrder(
        uint256 _posId,
        uint256 _positionType,
        uint256 _collateral,
        uint256 _size,
        OrderStatus _status
    ) external;

    function cancelMarketOrder(uint256 _posId) external;

    function createNewOrder(
        uint256 _posId,
        address _accout,
        bool _isLong,
        uint256 _tokenId,
        uint256 _positionType,
        uint256[] memory _params,
        address _refer
    ) external;

    function createAddPositionOrder(
        address _owner,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice,
        uint256 _fee
    ) external;

    function createAddPositionTrigger(
        bool _isTriggerAbove,
        uint256 _posId,
        uint256 _tokenId,
        uint256 _triggerPrice,
        uint256 _collateral,
        uint256 _size,
        uint256 _fee
    ) external;

    function createDecreasePositionOrder(uint256 _posId, uint256 _sizeDelta, uint256 _allowedPrice) external;

    function cancelAddPositionOrder(uint256 _posId) external;

    function deleteAddPositionOrder(uint256 _posId) external;

    function cancelPosAddPositionTriggers(uint256 _posId, address _positionOwner) external;

    function deleteDecreasePositionOrder(uint256 _posId) external;

    function getOrder(uint256 _posId) external view returns (Order memory);

    function getAddPositionOrder(uint256 _posId) external view returns (AddPositionOrder memory);

    function getDecreasePositionOrder(uint256 _posId) external view returns (DecreasePositionOrder memory);

    function getTriggerOrderInfo(uint256 _posId) external view returns (PositionTrigger memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Position, Order, OrderType, PaidFees} from "../structs.sol";

interface IPositionVault {
    function newPositionOrder(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external;

    function addOrRemoveCollateral(address _account, uint256 _posId, bool isPlus, uint256 _amount) external;

    function createAddPositionOrder(
        address _account,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function createAddPositionTrigger(
        address _account,
        bool _isTriggerAbove,
        uint256 _posId,
        uint256 _triggerPrice,
        uint256 _collateral,
        uint256 _size
    ) external;

    function createDecreasePositionOrder(
        uint256 _posId,
        address _account,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function increasePosition(
        uint256 _posId,
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _price,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function decreasePositionByOrderVault(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function removeUserAlivePosition(address _user, uint256 _posId) external;

    function removeUserOpenOrder(address _user, uint256 _posId) external;

    function lastPosId() external view returns (uint256);

    function getPosition(uint256 _posId) external view returns (Position memory);

    function getUserPositionIds(address _account) external view returns (uint256[] memory);

    function getUserOpenOrderIds(address _account) external view returns (uint256[] memory);

    function getPaidFees(uint256 _posId) external view returns (PaidFees memory);

    function getVaultUSDBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISettingsManager {
    function decreaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint32, uint32);

    function checkBanList(address _delegate) external view returns (bool);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function minCollateral() external view returns (uint256);

    function closeDeltaTime() external view returns (uint256);

    function expiryDuration() external view returns (uint256);

    function selfExecuteCooldown() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function liquidationPendingTime() external view returns (uint256);

    function depositFee(address token) external view returns (uint256);

    function withdrawFee(address token) external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(uint256 tokenId) external view returns (uint256);

    function totalOpenInterest() external view returns (uint256);

    function basisFundingRateFactor() external view returns (uint256);

    function deductFeePercent(address _account) external view returns (uint256);

    function referrerTiers(address _referrer) external view returns (uint256);

    function tierFees(uint256 _tier) external view returns (uint256);

    function fundingIndex(uint256 _tokenId) external view returns (int256);

    function fundingRateFactor(uint256 _tokenId) external view returns (uint256);

    function slippageFactor(uint256 _tokenId) external view returns (uint256);

    function getFundingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getBorrowRate(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function getFundingRate(uint256 _tokenId) external view returns (int256);

    function getTradingFee(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getPnl(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _averagePrice,
        uint256 _lastPrice,
        uint256 _lastIncreasedTime,
        uint256 _accruedBorrowFee,
        int256 _fundingIndex
    ) external view returns (int256, int256, int256);

    function updateFunding(uint256 _tokenId) external;

    function getBorrowFee(
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime,
        uint256 _tokenId,
        bool _isLong
    ) external view returns (uint256);

    function getUndiscountedTradingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getReferFee(address _refer) external view returns (uint256);

    function getReferFeeAndTraderRebate(address _refer) external view returns (uint256 referFee, uint256 traderRebate);

    function platformFees(address _platform) external view returns (uint256);

    function getPriceWithSlippage(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _price
    ) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function getSlippage(uint256 _slippageFactor, uint256 _size) external view returns (uint256);

    function isDeposit(address _token) external view returns (bool);

    function isStakingEnabled(address _token) external view returns (bool);

    function isUnstakingEnabled(address _token) external view returns (bool);

    function isIncreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isDecreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isWhitelistedFromCooldown(address _addr) external view returns (bool);

    function isWhitelistedFromTransferCooldown(address _addr) external view returns (bool);

    function isWithdraw(address _token) external view returns (bool);

    function lastFundingTimes(uint256 _tokenId) external view returns (uint256);

    function liquidateThreshold(uint256) external view returns (uint256);

    function tradingFee(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function defaultMaxOpenInterestPerUser() external view returns (uint256);

    function maxProfitPercent(uint256 _tokenId) external view returns (uint256);

    function defaultMaxProfitPercent() external view returns (uint256);

    function maxOpenInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function priceMovementPercent() external view returns (uint256);

    function maxOpenInterestPerUser(address _account) external view returns (uint256);

    function stakingFee(address token) external view returns (uint256);

    function unstakingFee(address token) external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function marketOrderGasFee() external view returns (uint256);

    function maxTriggerPerPosition() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);

    function maxTotalVlp() external view returns (uint256);

    function minProfitDurations(uint256 tokenId) external view returns (uint256);

    function maxCloseProfits(uint256 tokenId) external view returns (uint256);

    function maxCloseProfitPercents(uint256 tokenId) external view returns (uint256);

    function setMaxOpenInterestPerAsset(uint256 _tokenId, uint256 _maxAmount) external;

    function withdrawalExecutionDelay() external view returns (uint256);

    function lastFundingRates(uint256 tokenId) external view returns (int256);

    function tempMaxFundingRateFactors(uint256 tokenId) external view returns (uint256);

    function volatilityFactors(uint256 tokenId) external view returns (uint256);

    function longBiasFactors(uint256 tokenId) external view returns (uint256);

    function fundingRateVelocityFactors(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVault {
    function deposit(address _account, address _token, uint256 _amount) external;

    function stake(address _account, address _token, uint256 _amount) external;

    function accountDeltaIntoTotalUSD(bool _isIncrease, uint256 _delta) external;

    function distributeFee(uint256 _fee, address _refer, address _trader) external;

    function takeVUSDIn(address _account, uint256 _amount) external;

    function takeVUSDOut(address _account, uint256 _amount) external;

    function lastStakedAt(address _account) external view returns (uint256);

    function getVaultUSDBalance() external view returns (uint256);

    function getVLPPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPositionVault.sol";
import "./interfaces/IOrderVault.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ISettingsManager.sol";

import "../staking/interfaces/ITokenFarm.sol";

import {Constants} from "../access/Constants.sol";
import {OrderStatus, PositionTrigger, TriggerInfo, PaidFees} from "./structs.sol";

contract ReaderV2 is Constants, Initializable {
    struct AccruedFees {
        uint256 positionFee;
        uint256 borrowFee;
        int256 fundingFee;
    }

    IOrderVault private orderVault;
    IPositionVault private positionVault;
    ISettingsManager private settingsManager;
    ITokenFarm private tokenFarm;
    IVault private vault;
    IERC20 private USDC;
    IERC20 private vUSD;
    IERC20 private vlp;
    IERC20 private vela;
    IERC20 private esVela;
    IERC20 private nativeUSDC;

    function initialize(
        address _vault,
        address _positionVault,
        address _orderVault,
        address _settingsManager,
        address _tokenFarm,
        address _esVela,
        address _vela,
        address _vlp,
        address _usdc,
        address _vusd
    ) public initializer {
        vault = IVault(_vault);
        positionVault = IPositionVault(_positionVault);
        orderVault = IOrderVault(_orderVault);
        settingsManager = ISettingsManager(_settingsManager);
        tokenFarm = ITokenFarm(_tokenFarm);
        esVela = IERC20(_esVela);
        vela = IERC20(_vela);
        vlp = IERC20(_vlp);
        USDC = IERC20(_usdc);
        vUSD = IERC20(_vusd);
    }

    function initializeV2(address _usdc) public reinitializer(2) {
        nativeUSDC = IERC20(_usdc);
    }

    function getUserAlivePositions(
        address _user
    )
        public
        view
        returns (
            uint256[] memory,
            Position[] memory,
            Order[] memory,
            PositionTrigger[] memory,
            PaidFees[] memory,
            AccruedFees[] memory
        )
    {
        uint256[] memory posIds = positionVault.getUserPositionIds(_user);
        uint256 length = posIds.length;
        Position[] memory positions_ = new Position[](length);
        Order[] memory orders_ = new Order[](length);
        PositionTrigger[] memory triggers_ = new PositionTrigger[](length);
        PaidFees[] memory paidFees_ = new PaidFees[](length);
        AccruedFees[] memory accruedFees_ = new AccruedFees[](length);
        for (uint i; i < length; ++i) {
            uint256 posId = posIds[i];
            positions_[i] = positionVault.getPosition(posId);
            orders_[i] = orderVault.getOrder(posId);
            triggers_[i] = orderVault.getTriggerOrderInfo(posId);
            paidFees_[i] = positionVault.getPaidFees(posId);
            accruedFees_[i] = getAccruedFee(posId);
        }
        return (posIds, positions_, orders_, triggers_, paidFees_, accruedFees_);
    }

    function getAccruedFee(uint256 _posId) internal view returns (AccruedFees memory) {
        Position memory position = positionVault.getPosition(_posId);
        AccruedFees memory accruedFees;
        accruedFees.positionFee = settingsManager.getTradingFee(
            position.owner,
            position.tokenId,
            position.isLong,
            position.size
        );
        accruedFees.borrowFee =
            settingsManager.getBorrowFee(position.size, position.lastIncreasedTime, position.tokenId, position.isLong) +
            position.accruedBorrowFee;
        accruedFees.fundingFee = settingsManager.getFundingFee(
            position.tokenId,
            position.isLong,
            position.size,
            position.fundingIndex
        );
        return accruedFees;
    }

    function getGlobalInfo(
        address _account,
        uint256 _tokenId
    )
        external
        view
        returns (
            int256 fundingRate,
            uint256 borrowRateForLong,
            uint256 borrowRateForShort,
            uint256 longOpenInterest,
            uint256 shortOpenInterest,
            uint256 maxLongOpenInterest,
            uint256 maxShortOpenInterest,
            uint256 longTradingFee,
            uint256 shortTradingFee
        )
    {
        fundingRate = settingsManager.getFundingRate(_tokenId);
        borrowRateForLong = settingsManager.getBorrowRate(_tokenId, true);
        borrowRateForShort = settingsManager.getBorrowRate(_tokenId, false);
        longOpenInterest = settingsManager.openInterestPerAssetPerSide(_tokenId, true);
        shortOpenInterest = settingsManager.openInterestPerAssetPerSide(_tokenId, false);
        maxLongOpenInterest = settingsManager.maxOpenInterestPerAssetPerSide(_tokenId, true);
        maxShortOpenInterest = settingsManager.maxOpenInterestPerAssetPerSide(_tokenId, false);
        longTradingFee = settingsManager.getTradingFee(_account, _tokenId, true, PRICE_PRECISION);
        shortTradingFee = settingsManager.getTradingFee(_account, _tokenId, false, PRICE_PRECISION);
    }

    function getUserOpenOrders(
        address _user
    )
        public
        view
        returns (
            uint256[] memory,
            Position[] memory,
            Order[] memory,
            PositionTrigger[] memory,
            PaidFees[] memory,
            AccruedFees[] memory
        )
    {
        uint256[] memory posIds = positionVault.getUserOpenOrderIds(_user);
        uint256 length = posIds.length;
        Position[] memory positions_ = new Position[](length);
        Order[] memory orders_ = new Order[](length);
        PositionTrigger[] memory triggers_ = new PositionTrigger[](length);
        PaidFees[] memory paidFees_ = new PaidFees[](length);
        AccruedFees[] memory accruedFees_ = new AccruedFees[](length);
        for (uint i; i < length; ++i) {
            uint256 posId = posIds[i];
            positions_[i] = positionVault.getPosition(posId);
            orders_[i] = orderVault.getOrder(posId);
            triggers_[i] = orderVault.getTriggerOrderInfo(posId);
            paidFees_[i] = positionVault.getPaidFees(posId);
            accruedFees_[i] = getAccruedFee(posId);
        }
        return (posIds, positions_, orders_, triggers_, paidFees_, accruedFees_);
    }

    function getFeesFor1CT(address _normal, address _oneCT) external view returns (bool, uint256) {
        uint256 tierVelaPercent = tokenFarm.getTierVela(_normal);
        uint256 deductFeePercentForNormal = settingsManager.deductFeePercent(_normal);
        uint256 deductFeePercentForOneCT = settingsManager.deductFeePercent(_oneCT);
        if (
            (tierVelaPercent * (BASIS_POINTS_DIVISOR - deductFeePercentForNormal)) / BASIS_POINTS_DIVISOR !=
            (BASIS_POINTS_DIVISOR - deductFeePercentForOneCT)
        ) {
            return (
                true,
                BASIS_POINTS_DIVISOR -
                    (tierVelaPercent * (BASIS_POINTS_DIVISOR - deductFeePercentForNormal)) /
                    BASIS_POINTS_DIVISOR
            );
        } else {
            return (false, 0);
        }
    }

    function validateMinCloseProfits(uint256 _posId, uint256 _price, uint256 _sizeDelta) external view returns (bool) {
        Position memory position = positionVault.getPosition(_posId);
        _price = settingsManager.getPriceWithSlippage(position.tokenId, !position.isLong, _sizeDelta, _price);
        uint256 countedBorrowFee;
        if (position.accruedBorrowFee > 0) {
            countedBorrowFee = (position.accruedBorrowFee * _sizeDelta) / position.size;
        }

        (int256 pnl, , ) = settingsManager.getPnl(
            position.tokenId,
            position.isLong,
            _sizeDelta,
            position.averagePrice,
            _price,
            position.lastIncreasedTime,
            countedBorrowFee,
            position.fundingIndex
        );
        uint256 collateralDelta = (position.collateral * _sizeDelta) / position.size;

        if (pnl >= 0) {
            if (block.timestamp - position.lastIncreasedTime < settingsManager.minProfitDurations(position.tokenId)) {
                uint256 profitPercent = (BASIS_POINTS_DIVISOR * uint256(pnl)) / collateralDelta;
                if (
                    profitPercent > settingsManager.maxCloseProfitPercents(position.tokenId) ||
                    uint256(pnl) > settingsManager.maxCloseProfits(position.tokenId)
                ) {
                    return false;
                }
            }
        }
        return true;
    }

    function validateMaxOILimit(
        address _account,
        bool _isLong,
        uint256 _size,
        uint256 _tokenId
    ) external view returns (uint256, uint256, uint256, uint8) {
        uint256 _openInterestPerUser = settingsManager.openInterestPerUser(_account);
        uint256 _maxOpenInterestPerUser = settingsManager.maxOpenInterestPerUser(_account);
        uint256 tradingFee = settingsManager.getTradingFee(_account, _tokenId, _isLong, _size);
        uint256 triggerGasFee = settingsManager.triggerGasFee();
        uint256 marketOrderGasFee = settingsManager.marketOrderGasFee();
        if (_maxOpenInterestPerUser == 0) _maxOpenInterestPerUser = settingsManager.defaultMaxOpenInterestPerUser();
        if (_openInterestPerUser + _size > _maxOpenInterestPerUser)
            return (triggerGasFee, marketOrderGasFee, tradingFee, 1);
        uint256 _openInterestPerAssetPerSide = settingsManager.openInterestPerAssetPerSide(_tokenId, _isLong);
        if (_openInterestPerAssetPerSide + _size > settingsManager.maxOpenInterestPerAssetPerSide(_tokenId, _isLong))
            return (triggerGasFee, marketOrderGasFee, tradingFee, 2);
        return (triggerGasFee, marketOrderGasFee, tradingFee, 0);
    }

    function getSpread(uint256 _tokenId, uint256 _size) external view returns (uint256) {
        uint256 slippageFactor = settingsManager.slippageFactor(_tokenId);
        uint256 spread = settingsManager.getSlippage(slippageFactor, _size);
        return spread;
    }

    function getUserBalances(
        address _account
    )
        external
        view
        returns (
            uint256 ethBalance,
            uint256 usdcBalance,
            uint256 nativeUSDCBalance,
            uint256 usdcAllowance,
            uint256 nativeUSDCAllowance,
            uint256 vusdBalance
        )
    {
        ethBalance = _account.balance;
        usdcBalance = USDC.balanceOf(_account);
        nativeUSDCBalance = nativeUSDC.balanceOf(_account);
        usdcAllowance = USDC.allowance(_account, address(vault));
        nativeUSDCAllowance = nativeUSDC.allowance(_account, address(vault));
        vusdBalance = vUSD.balanceOf(_account);
    }

    function getUserVelaAndEsVelaInfo(
        address _account
    ) external view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory balances = new uint256[](2);
        uint256[] memory allowances = new uint256[](2);
        uint256[] memory stakedAmounts = new uint256[](2);
        balances[0] = vela.balanceOf(_account);
        balances[1] = esVela.balanceOf(_account);
        allowances[0] = vela.allowance(_account, address(tokenFarm));
        allowances[1] = esVela.allowance(_account, address(tokenFarm));
        (uint256 velaStakedAmount, uint256 esVelaStakedAmount) = tokenFarm.getStakedVela(_account);
        stakedAmounts[0] = velaStakedAmount;
        stakedAmounts[1] = esVelaStakedAmount;
        (, , uint256[] memory decimals, uint256[] memory pendingTokens) = tokenFarm.pendingTokens(true, _account);
        return (balances, allowances, decimals, pendingTokens, stakedAmounts);
    }

    function getUserVLPInfo(
        address _account
    ) external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256 balance = vlp.balanceOf(_account);
        uint256 allowance = vlp.allowance(_account, address(tokenFarm));
        uint256 vlpPrice = vault.getVLPPrice();
        (uint256 vlpStakedAmount, uint256 startTimestamp) = tokenFarm.getStakedVLP(_account);
        uint256 cooldownDuration = tokenFarm.cooldownDuration();
        uint256[] memory vlpInfo = new uint256[](6);
        vlpInfo[0] = balance;
        vlpInfo[1] = allowance;
        vlpInfo[2] = vlpStakedAmount;
        vlpInfo[3] = vlpPrice;
        vlpInfo[4] = startTimestamp;
        vlpInfo[5] = cooldownDuration;
        (, , uint256[] memory decimals, uint256[] memory pendingTokens) = tokenFarm.pendingTokens(false, _account);
        return (vlpInfo, decimals, pendingTokens);
    }

    function getUserVestingInfo(address _account) external view returns (uint256, uint256) {
        uint256 totalVestedAmount = tokenFarm.getTotalVested(_account);
        uint256 vestingClaimableAmount = tokenFarm.claimable(_account);
        return (totalVestedAmount, vestingClaimableAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    NONE,
    PENDING,
    OPEN,
    TRIGGERED,
    CANCELLED
}

struct Order {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 size;
    uint256 collateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    uint256 timestamp;
}

struct AddPositionOrder {
    address owner;
    uint256 collateral;
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
    uint256 fee;
}

struct AddPositionTrigger {
    bool isTriggerAbove;
    uint256 posId;
    uint256 triggerPrice;
    uint256 collateral;
    uint256 size;
    uint256 fee;
}

struct DecreasePositionOrder {
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
}

struct Position {
    address owner;
    address refer;
    bool isLong;
    uint256 tokenId;
    uint256 averagePrice;
    uint256 collateral;
    int256 fundingIndex;
    uint256 lastIncreasedTime;
    uint256 size;
    uint256 accruedBorrowFee;
}

struct PaidFees {
    uint256 paidPositionFee;
    uint256 paidBorrowFee;
    int256 paidFundingFee;
}

struct Temp {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;
    uint256 e;
}

struct TriggerInfo {
    bool isTP;
    uint256 amountPercent;
    uint256 createdAt;
    uint256 price;
    uint256 triggeredAmount;
    uint256 triggeredAt;
    TriggerStatus status;
}

struct PositionTrigger {
    TriggerInfo[] triggers;
}

struct WithdrawalRequest {
    bool isOpen;
    address account;
    address token;
    uint256 vusdAmount;
    uint256 timestamp;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the VeDxp
 */
interface ITokenFarm {
    function claimable(address _account) external view returns (uint256);
    function cooldownDuration() external view returns (uint256);
    function getTierVela(address _account) external view returns (uint256);
    function getStakedVela(address _account) external view returns (uint256, uint256);
    function getStakedVLP(address _account) external view returns (uint256, uint256);
    function getTotalVested(address _account) external view returns (uint256);
    function pendingTokens(bool _isVelaPool, address _user) external view returns (
        address[] memory,
        string[] memory,
        uint256[] memory,
        uint256[] memory
    );
}