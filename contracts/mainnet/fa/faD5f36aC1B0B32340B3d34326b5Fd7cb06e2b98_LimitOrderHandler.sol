// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint32 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);
    function getTruncatedCVIValue(int256 cviOracleValue) external view returns (uint32);
    function getTruncatedMaxCVIValue() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IVolatilityTokenActionHandler.sol";

interface IHedgedThetaVaultActionHandler {
    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue, bool shouldStake) external returns (uint256 hedgedThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 hedgedThetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IRequestFulfillerV3.sol";
import "./IRequestFulfillerV3ManagementConfig.sol";

enum OrderType {
    NONE,
    CVI_LIMIT,
    CVI_TP,
    CVI_SL,
    UCVI_LIMIT,
    UCVI_TP,
    UCVI_SL,
    REVERSE_LIMIT,
    REVERSE_TP,
    REVERSE_SL
}

interface ILimitOrderHandler {

    function createOrder(OrderType orderType, uint256 requestId, address requester, uint256 executionFee, uint32 triggerIndex, bytes memory eventData) external;
    function editOrder(uint256 requestId, uint32 triggerIndex, bytes memory eventData, address sender) external;
    function cancelOrder(uint256 requestId, address sender) external returns(address requester, uint256 executionFee);
    function removeExpiredOrder(uint256 requestId) external returns(address requester, uint256 executionFee);

    function getActiveOrders() external view returns(uint256[] memory ids);
    function checkOrders(int256 cviValue, uint256[] calldata idsToCheck) external view returns(bool[] memory isTriggerable);
    function checkAllOrders(int256 cviValue) external view returns(uint256[] memory triggerableIds);

    function triggerOrder(uint256 requestId, int256 cviValue) external returns(RequestType orderType, address requester, uint256 executionFee, bytes memory eventData);

    function setRequestFulfiller(address newRequestFulfiller) external;
    function setRequestFulfillerConfig(IRequestFulfillerV3ManagementConfig newRequestFulfillerConfig) external;
    function setOrderExpirationPeriod(uint32 newOrderExpirationPeriod) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IThetaVaultActionHandler.sol";

interface IMegaThetaVaultActionHandler {
    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue) external returns (uint256 megaThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 thetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);
    function thetaVault() external view returns (IThetaVaultActionHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./ICVIOracle.sol";

interface IPlatformPositionHandler {
    function openPositionForOwner(address owner, bytes32 referralCode, uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage, uint32 realTimeCVIValue) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function closePositionForOwner(address owner, uint168 positionUnitsAmount, uint32 minCVI, uint32 realTimeCVIValue) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function cviOracle() external view returns (ICVIOracle);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IRequestFulfillerV3ManagementConfig.sol";

enum RequestType {
    NONE,
    CVI_OPEN,
    CVI_CLOSE,
    UCVI_OPEN,
    UCVI_CLOSE,
    REVERSE_OPEN,
    REVERSE_CLOSE,
    CVI_MINT,
    CVI_BURN,
    UCVI_MINT,
    UCVI_BURN,
    HEDGED_DEPOSIT,
    HEDGED_WITHDRAW,
    MEGA_DEPOSIT,
    MEGA_WITHDRAW
}

interface IRequestFulfillerV3 {
    event RequestFulfillerV3ManagementConfigSet(address newRequestFulfillerConfig);

    function setRequestFulfillerV3ManagementConfig(IRequestFulfillerV3ManagementConfig newRequestFulfillerConfig) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";
import "./IVolatilityTokenActionHandler.sol";
import "./IVolatilityTokenActionHandler.sol";
import "./IHedgedThetaVaultActionHandler.sol";
import "./IMegaThetaVaultActionHandler.sol";
import "./ILimitOrderHandler.sol";

interface IRequestFulfillerV3ManagementConfig {

    function minOpenAmount() external view returns(uint168);
    function minCloseAmount() external view returns(uint168);

    function minMintAmount() external view returns(uint168);
    function minBurnAmount() external view returns(uint168);

    function minDepositAmount() external view returns(uint256);
    function minWithdrawAmount() external view returns(uint256);

    function platformCVI() external view returns(IPlatformPositionHandler);
    function platformUCVI() external view returns(IPlatformPositionHandler);
    function platformReverse() external view returns(IPlatformPositionHandler);

    function volTokenCVI() external view returns(IVolatilityTokenActionHandler);
    function volTokenUCVI() external view returns(IVolatilityTokenActionHandler);

    function hedgedVault() external view returns(IHedgedThetaVaultActionHandler);
    function megaVault() external view returns(IMegaThetaVaultActionHandler);

    function minCVIDiffAllowedPercentage() external view returns(uint32);

    function limitOrderHandler() external view returns(ILimitOrderHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";

interface IThetaVaultActionHandler {
    function platform() external view returns (IPlatformPositionHandler);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatformPositionHandler.sol";

interface IVolatilityTokenActionHandler {
    function mintTokensForOwner(address owner, uint168 tokenAmount, uint32 maxBuyingPremiumFeePercentage, uint32 realTimeCVIValue) external returns (uint256 tokensMinted);
    function burnTokensForOwner(address owner,  uint168 burnAmount, uint32 realTimeCVIValue) external returns (uint256 tokensReceived);
    function platform() external view returns (IPlatformPositionHandler);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.23;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import "./interfaces/ILimitOrderHandler.sol";
import "./interfaces/IPlatformPositionHandler.sol";

contract LimitOrderHandler is ILimitOrderHandler, OwnableUpgradeable {
    event OrderCreated(uint8 indexed orderType, uint256 indexed requestId, address indexed requester, uint256 executionFee, uint32 triggerIndex, bytes eventData, uint256 timestamp);
    event OrderEdited(uint8 indexed orderType, uint256 indexed requestId, address indexed requester, uint256 executionFee, uint32 triggerIndex, bytes eventData, uint256 timestamp);
    event OrderTriggered(uint8 indexed orderType, uint256 indexed requestId, address indexed requester, uint256 timestamp);
    event OrderCanceled(uint8 indexed orderType, uint256 indexed requestId, address indexed requester, uint256 timestamp);
    event OrderExpired(uint8 indexed orderType, uint256 indexed requestId, address indexed requester, uint256 timestamp);

    struct Order {
        OrderType orderType;
        address requester;
        uint256 executionFee;
        uint32 triggerIndex;
        bytes eventData;
        uint256 createdAt;
    }

    mapping(uint256 => Order) public limitOrders;
    EnumerableSet.UintSet private orderIds;

    address public requestFulfiller;
    IRequestFulfillerV3ManagementConfig public requestFulfillerConfig;

    uint32 public orderExpirationPeriod;

    constructor() {
        _disableInitializers();
    }

    modifier onlyRequestFulfiller() {
        if (msg.sender == requestFulfiller) _;
    }

    function initialize(address _owner) external initializer {
        OwnableUpgradeable.__Ownable_init();
        _transferOwnership(_owner);

        orderExpirationPeriod = 60 days;
    }

    function setRequestFulfiller(address _newRequestFulfiller) external override onlyOwner() {
        requestFulfiller = _newRequestFulfiller;
    }

    function setRequestFulfillerConfig(IRequestFulfillerV3ManagementConfig _newRequestFulfillerConfig) external override onlyOwner() {
        requestFulfillerConfig = _newRequestFulfillerConfig;
    }

    function setOrderExpirationPeriod(uint32 _newOrderExpirationPeriod) external override onlyOwner() {
        require(_newOrderExpirationPeriod > 0, "Must be > 0");

        orderExpirationPeriod = _newOrderExpirationPeriod;
    }

    function createOrder(OrderType _orderType, uint256 _requestId, address _requester, uint256 _executionFee, uint32 _triggerIndex, bytes memory _eventData) external onlyRequestFulfiller() {
        limitOrders[_requestId] = Order(_orderType, _requester, _executionFee, _triggerIndex, _eventData, block.timestamp);
        EnumerableSet.add(orderIds, _requestId);

        emit OrderCreated(uint8(_orderType), _requestId, _requester, _executionFee, _triggerIndex, _eventData, block.timestamp);
    }

    function editOrder(uint256 _requestId, uint32 _triggerIndex, bytes memory _eventData, address _sender) external override onlyRequestFulfiller() {
        Order storage order = limitOrders[_requestId];
        require(order.requester == _sender, 'Not Owner');
        order.eventData = _eventData;
        order.triggerIndex = _triggerIndex;

        emit OrderEdited(uint8(order.orderType), _requestId, order.requester, order.executionFee, order.triggerIndex, order.eventData, block.timestamp);
    }

    function cancelOrder(uint256 _requestId, address _sender) external override onlyRequestFulfiller() returns(address requester, uint256 executionFee) {
        Order memory order = limitOrders[_requestId];
        require(order.requester == _sender, 'Not Owner');

        removeOrder(_requestId);

        emit OrderCanceled(uint8(order.orderType), _requestId, order.requester, block.timestamp);
        return (order.requester, order.executionFee);
    }

    function removeExpiredOrder(uint256 _requestId) external onlyRequestFulfiller() returns(address requester, uint256 executionFee) {
        Order memory order = limitOrders[_requestId];
        require(order.requester != address(0) && block.timestamp - order.createdAt >= orderExpirationPeriod, 'Not expired');

        removeOrder(_requestId);

        emit OrderExpired(uint8(order.orderType), _requestId, order.requester, block.timestamp);
        return (order.requester, order.executionFee);
    }

    function triggerOrder(uint256 _requestId, int256 _cviValue) external onlyRequestFulfiller() returns(RequestType requestType, address requester, uint256 executionFee, bytes memory eventData) {
        Order memory order = limitOrders[_requestId];
        require(order.requester != address(0), 'Invalid order');
        validateOrderTrigger(_cviValue, order);

        removeOrder(_requestId);

        emit OrderTriggered(uint8(order.orderType), _requestId, order.requester, block.timestamp);
        return (orderTypeToRequestType(order.orderType), order.requester, order.executionFee, order.eventData);
    }

    function getActiveOrders() external override view returns(uint256[] memory) {
        return EnumerableSet.values(orderIds);
    }

    function checkOrders(int256 _cviValue, uint256[] calldata _idsToCheck) external override view returns(bool[] memory isTriggerable) {
        isTriggerable = new bool[](_idsToCheck.length);
        for (uint256 i = 0; i < _idsToCheck.length; i++) {
            Order memory order = limitOrders[_idsToCheck[i]];
            isTriggerable[i] = order.requester != address(0) && isOrderTriggered(_cviValue, order);
        }
    }

    function checkAllOrders(int256 _cviValue) external override view returns(uint256[] memory triggerableIds) {
        uint256[] memory ids = EnumerableSet.values(orderIds);
        uint16 count = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            Order memory order = limitOrders[ids[i]];
            if (isOrderTriggered(_cviValue, order)) {
                count++;
            }
        }

        triggerableIds = new uint256[](count);
        count = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            Order memory order = limitOrders[ids[i]];
            if (isOrderTriggered(_cviValue, order)) {
                triggerableIds[count++] = ids[i];
            }
        }
    }

    function removeOrder(uint256 _requestId) internal {
        delete limitOrders[_requestId];
        EnumerableSet.remove(orderIds, _requestId);
    }

    function isOrderTriggered(int256 _cviValue, Order memory _order) internal view returns (bool) {
        OrderType orderType = OrderType(_order.orderType);
        (uint32 smoothedIndexValue,,) = getPlatformFromOrderType(orderType).cviOracle().getCVILatestRoundData();
        uint32 realtimeIndexValue = getPlatformFromOrderType(orderType).cviOracle().getTruncatedCVIValue(_cviValue);
        if (orderType == OrderType.CVI_LIMIT || orderType == OrderType.UCVI_LIMIT || orderType == OrderType.REVERSE_TP) {
            uint32 maxIndexValue = realtimeIndexValue > smoothedIndexValue ? realtimeIndexValue : smoothedIndexValue;
            return maxIndexValue <= _order.triggerIndex;
        } else if (orderType == OrderType.CVI_SL || orderType == OrderType.UCVI_SL) {
            uint32 minIndexValue = realtimeIndexValue < smoothedIndexValue ? realtimeIndexValue : smoothedIndexValue;
            return minIndexValue <= _order.triggerIndex;
        } else if (orderType == OrderType.CVI_TP || orderType == OrderType.UCVI_TP || orderType == OrderType.REVERSE_LIMIT) {
            uint32 minIndexValue = realtimeIndexValue < smoothedIndexValue ? realtimeIndexValue : smoothedIndexValue;
            return minIndexValue >= _order.triggerIndex;
        } else if (orderType == OrderType.REVERSE_SL) {
            uint32 maxIndexValue = realtimeIndexValue > smoothedIndexValue ? realtimeIndexValue : smoothedIndexValue;
            return maxIndexValue >= _order.triggerIndex;
        } 
        return false;
    }

    function validateOrderTrigger(int256 _cviValue, Order memory _order) internal view {
        require(isOrderTriggered(_cviValue, _order), 'Trigger index not reached');
    }   

    function getPlatformFromOrderType(OrderType _orderType) internal view returns(IPlatformPositionHandler) {
        if (_orderType == OrderType.CVI_LIMIT || _orderType == OrderType.CVI_TP || _orderType == OrderType.CVI_SL) {
            return requestFulfillerConfig.platformCVI();
        } else if (_orderType == OrderType.UCVI_LIMIT || _orderType == OrderType.UCVI_TP || _orderType == OrderType.UCVI_SL) {
            return requestFulfillerConfig.platformUCVI();
        } else if (_orderType == OrderType.REVERSE_LIMIT || _orderType == OrderType.REVERSE_TP || _orderType == OrderType.REVERSE_SL) {
            return requestFulfillerConfig.platformReverse();
        }
        revert('Invalid order type');
    }

    function orderTypeToRequestType(OrderType _orderType) internal pure returns(RequestType) {
        if (_orderType == OrderType.CVI_LIMIT) {
            return RequestType.CVI_OPEN;
        } else if (_orderType == OrderType.CVI_TP || _orderType == OrderType.CVI_SL) {
            return RequestType.CVI_CLOSE;
        } else if (_orderType == OrderType.UCVI_LIMIT) {
            return RequestType.UCVI_OPEN;
        } else if (_orderType == OrderType.UCVI_TP || _orderType == OrderType.UCVI_SL) {
            return RequestType.UCVI_CLOSE;
        } else if (_orderType == OrderType.REVERSE_LIMIT) {
            return RequestType.REVERSE_OPEN;
        } else if (_orderType == OrderType.REVERSE_TP || _orderType == OrderType.REVERSE_SL) {
            return RequestType.REVERSE_CLOSE;
        }
        revert('Invalid order type');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}