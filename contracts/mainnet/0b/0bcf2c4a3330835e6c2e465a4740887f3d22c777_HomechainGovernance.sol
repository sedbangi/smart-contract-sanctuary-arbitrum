// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IBaseIndex} from "../interfaces/IBaseIndex.sol";
import {IConfigBuilder} from "../interfaces/IConfigBuilder.sol";
import {IConfigMigration} from "../interfaces/IConfigMigration.sol";
import {IHomechainOmnichainMessenger} from "../interfaces/IHomechainOmnichainMessenger.sol";
import {IL2Index} from "../interfaces/IL2Index.sol";
import {IOrderBook} from "../interfaces/IOrderBook.sol";
import {IValidator} from "../interfaces/IValidator.sol";
import {IPriceOracleDeployer} from "../price-oracles/interfaces/IPriceOracleDeployer.sol";
import {IVault} from "../interfaces/IVault.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

import {Governance} from "./Governance.sol";

contract HomechainGovernance is Governance {
    event SetConfigBuilder(address);

    error Forbidden();

    function startIndexRebalancing(address index) external {
        IBaseIndex(index).startIndexRebalancing();
    }

    function setInitialConfig(address index, address configBuilder, IConfigBuilder.Config calldata baseConfig)
        external
    {
        if (IConfigBuilder(configBuilder).configHash() != bytes32(0)) revert Forbidden();

        IBaseIndex(index).startIndexRebalancing();

        IBaseIndex.Config memory config;
        (IBaseIndex.DepositConfig memory depositConfig, IBaseIndex.RedemptionConfig memory redemptionConfig) =
            IConfigBuilder(configBuilder).setConfig(baseConfig);
        IBaseIndex(index).setConfig(config, depositConfig, redemptionConfig);

        emit SetConfigBuilder(configBuilder);
    }

    function configure(address messenger, address index, address orderBook, address builder) external {
        IHomechainOmnichainMessenger(messenger).configure(index, orderBook, builder);
    }

    function setConfig(address configBuilder, IConfigBuilder.Config calldata baseConfig) external {
        if (IConfigBuilder(configBuilder).configHash() == bytes32(0)) revert Forbidden();

        IConfigBuilder(configBuilder).setConfig(baseConfig);
    }

    function updateConfig(
        address index,
        address configBuilder,
        IBaseIndex.Config calldata prevConfig,
        IConfigBuilder.Config calldata baseConfig
    ) external {
        if (IConfigBuilder(configBuilder).configHash() == bytes32(0)) revert Forbidden();

        IBaseIndex(index).startIndexRebalancing();

        (IBaseIndex.DepositConfig memory depositConfig, IBaseIndex.RedemptionConfig memory redemptionConfig) =
            IConfigBuilder(configBuilder).setConfig(baseConfig);

        IBaseIndex(index).setConfig(prevConfig, depositConfig, redemptionConfig);
    }

    function startRebalancing(
        address configBuilder,
        IConfigBuilder.StartRebalancingParams calldata params,
        bytes calldata data
    ) external payable {
        IConfigBuilder(configBuilder).startRebalancing{value: msg.value}(params, data);
    }

    function updateTarget(address validator, address target, bool isAllowed) external {
        IValidator(validator).updateTarget(target, isAllowed);
    }

    function startReserveRebalancing(
        address configBuilder,
        IConfigBuilder.StartReserveRebalancingParams calldata params,
        bytes calldata data
    ) external payable {
        IConfigBuilder(configBuilder).startReserveRebalancing{value: msg.value}(params, data);
    }

    function finishRebalancing(
        address index,
        address configBuilder,
        address messenger,
        IVault.RebalancingResult[] calldata results,
        IConfigBuilder.Config calldata config,
        IHomechainOmnichainMessenger.LzConfig calldata lzConfig,
        IBaseIndex.Config calldata currentConfig
    ) external {
        (IBaseIndex.DepositConfig memory deposit, IBaseIndex.RedemptionConfig memory redemption) =
            IConfigBuilder(configBuilder).finishRebalancing(results, config);
        IBaseIndex(index).setConfig(currentConfig, deposit, redemption);
        IHomechainOmnichainMessenger(messenger).setLayerZeroConfig(lzConfig);
    }

    function setLayerZeroConfig(address messenger, IHomechainOmnichainMessenger.LzConfig calldata lzConfig) external {
        IHomechainOmnichainMessenger(messenger).setLayerZeroConfig(lzConfig);
    }

    function setPriceSourceMapper(address priceOracleDeployer, address mapper) external {
        IPriceOracleDeployer(priceOracleDeployer).setPriceSourceMapper(mapper);
    }

    function setSequencerUptimeFeed(address priceOracleDeployer, address feed) external {
        IL2Index(priceOracleDeployer).setSequencerUptimeFeed(feed);
    }

    function registerChain(address configBuilder, uint256 chainId) external {
        IConfigBuilder(configBuilder).registerChain(chainId);
    }

    function registerCurrencies(address index, address messenger, Currency[] calldata currencies) external {
        IHomechainOmnichainMessenger(messenger).currenciesUpdated(IBaseIndex(index).registerCurrencies(currencies));
    }

    function finishVaultRebalancing(
        address messenger,
        IOrderBook.FinishOrderExecutionParams calldata orderBookParams,
        IVault.EndRebalancingParams calldata params,
        IHomechainOmnichainMessenger.SgParams[] calldata sgParams,
        IHomechainOmnichainMessenger.LzParams calldata lzParams
    ) external payable {
        IHomechainOmnichainMessenger(messenger).finishRebalancing{value: msg.value}(
            orderBookParams, params, sgParams, lzParams
        );
    }

    function migrateConfig(address newConfigBuilder, IConfigMigration.State calldata state) external {
        IConfigMigration(newConfigBuilder).setState(state);

        emit SetConfigBuilder(newConfigBuilder);
    }

    function accrueFee(address index, address recipient) external {
        IBaseIndex(index).accrueFee(recipient);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IVault} from "./IVault.sol";

import {Currency} from "../libraries/CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IBaseIndex is IVault {
    struct IndexState {
        uint128 totalSupply;
        uint96 fees;
        uint32 lastAUMAccrualTimestamp;
        uint96 reserve;
    }

    struct Config {
        uint256 latestSnapshot; // needed to get the latest k value
        uint256 AUMDilutionPerSecond;
        bool useCustomAUMFee;
        address staticPriceOracle;
        address metadata;
    }

    struct FeeConfig {
        uint16 BPs;
        bool useCustomCallback;
    }

    struct DepositConfig {
        Config shared;
        FeeConfig fee;
    }

    struct RedemptionConfig {
        Config shared;
        FeeConfig fee;
        address forwarder;
        a160u96[] homeCurrencies; // Reserve currency + Vault's currencies
    }

    struct DepositParams {
        DepositConfig config;
        uint96 amount;
        address recipient;
        bytes payload;
    }

    struct RedemptionParams {
        RedemptionConfig config;
        uint256 expectedReserveValuation;
        uint256 AUMScaledK;
        address owner;
        uint128 shares;
        bytes payload;
        address payable recipient;
    }

    struct RedeemedInfo {
        uint96 reserve;
        uint256 reserveValuation;
        uint256 k;
    }

    error IndexConfigHash();
    error IndexConfigMismatch();
    error IndexInitialConfig();
    error PermitDeadlineExpired();
    error InvalidSigner();
    error ZeroAddressTransfer();
    error InvalidSender();

    function startIndexRebalancing() external;

    function setConfig(
        Config calldata _prevConfig,
        DepositConfig calldata _depositConfig,
        RedemptionConfig calldata _redemptionConfig
    ) external;

    function accrueFee(address recipient) external;

    function reserve() external view returns (Currency);
    function reserveBalance() external view returns (uint96);
    function kSelf() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IBaseIndex} from "./IBaseIndex.sol";
import {IVault} from "./IVault.sol";
import {ICurrencyMetadata} from "./ICurrencyMetadata.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

interface IConfigBuilder {
    struct Anatomy {
        uint256[] chainIdSet;
        uint256[][] currencyIdSets;
    }

    struct SharedConfig {
        uint256 AUMDilutionPerSecond;
        bool useCustomAUMFee;
        address metadata;
    }

    struct FeeConfig {
        uint16 BPs;
        bool useCustomCallback;
    }

    struct Config {
        SharedConfig shared;
        FeeConfig depositFee;
        FeeConfig redemptionFee;
    }

    struct StartReserveRebalancingParams {
        Anatomy anatomy;
        uint256[] chainIds;
        Currency[][] currencies;
    }

    struct StartRebalancingParams {
        Anatomy anatomy;
        Anatomy newAnatomy;
        uint256[] chainIds;
        Currency[][] currencies;
        uint256[] newWeights;
        uint256[] orderCounts; // count of orders for current anatomy chains
        bytes payload;
    }

    function startRebalancing(StartRebalancingParams calldata params, bytes calldata data) external payable;

    function startReserveRebalancing(StartReserveRebalancingParams calldata params, bytes calldata data)
        external
        payable;

    function finishRebalancing(IVault.RebalancingResult[] calldata results, IConfigBuilder.Config calldata config)
        external
        returns (IBaseIndex.DepositConfig memory deposit, IBaseIndex.RedemptionConfig memory redemption);

    function chainRebalancingFinished(uint256 chainId, bytes32 resultHash) external;

    function currenciesUpdated(ICurrencyMetadata.RegisteredMetadata calldata result) external;

    function registerChain(uint256 chainId) external;

    function setMessenger(address _messenger) external;

    function setConfig(IConfigBuilder.Config memory _config)
        external
        returns (IBaseIndex.DepositConfig memory deposit, IBaseIndex.RedemptionConfig memory redemption);

    function configs(Config calldata _config)
        external
        view
        returns (IBaseIndex.DepositConfig memory deposit, IBaseIndex.RedemptionConfig memory redemption);

    function configHash() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {a160u96} from "../utils/a160u96.sol";

interface IConfigMigration {
    struct State {
        bool hasRemote;
        uint8 pendingChainCount;
        uint256[] snapshotChainIndexSet;
        uint256[] weights;
        uint256[] chainIdSet;
        bytes32 chainsHash;
        bytes32 configHash;
        uint256 latestSnapshot;
        address staticPriceOracle;
        a160u96[] homeCurrencies;
        ChainState[] chainStates;
    }

    struct ChainState {
        bytes32 currenciesHash;
        bytes32 resultHash;
    }

    function setState(State calldata _state) external;
    function getState() external view returns (State memory _state);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IOmnichainMessenger} from "./IOmnichainMessenger.sol";
import {IOrderBook} from "./IOrderBook.sol";
import {IVault} from "./IVault.sol";

import {u16x15} from "../utils/u16x15.sol";
import {RebalancingLib} from "../libraries/RebalancingLib.sol";

interface IHomechainOmnichainMessenger is IOmnichainMessenger {
    struct LzConfig {
        u16x15 eIds;
        uint256[] minGas;
    }

    struct Batches {
        address escrow;
        bytes[] callbacks;
        uint256[] additionalGas;
        uint256 airdropAmount;
    }

    struct SendParams {
        LzConfig config;
        Batches[] batches;
        address zroPaymentAddress;
        bytes packedRecipient;
    }

    struct Retry {
        uint16 eid;
        bytes[] options;
        bytes[] callbacks;
    }

    function configure(address index, address orderBook, address builder) external;

    function setLayerZeroConfig(LzConfig calldata config) external;

    function currenciesUpdated(IVault.RegisterCurrenciesResult calldata result) external;

    function broadcastOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders calldata homeChainOrders,
        bytes32[] calldata chainOrdersHash,
        IVault.CurrencyWithdrawal[] calldata withdrawals,
        bytes calldata lzParams
    ) external payable;

    function broadcastReserveOrders(
        uint256[] calldata chainIds,
        uint256[] calldata chainIdSet,
        RebalancingLib.ChainOrders[] calldata chainOrders,
        bytes calldata lzParams
    ) external payable;

    function finishRebalancing(
        IOrderBook.FinishOrderExecutionParams calldata pendingOrders,
        IVault.EndRebalancingParams calldata params,
        SgParams[] calldata sgParams,
        LzParams calldata lzParams
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IL2Index {
    function setSequencerUptimeFeed(address _sequencerUptimeFeed) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";
import {OrderLib} from "../libraries/OrderLib.sol";

/// @title IOrderBook interface
interface IOrderBook {
    struct TradeParams {
        address target;
        bytes data;
    }

    struct BoughtOrder {
        // Bought amount of local buy currency, sell amount on the remote
        uint256 amount;
        // Buy currency on the remote
        Currency buyCurrency;
    }

    struct PendingOrder {
        uint256 chainId;
        Currency currency;
        uint256 totalBought;
        BoughtOrder[] orders;
    }

    struct FinishOrderExecutionParams {
        OrderLib.OrderId[] orderIds;
        uint256[] idIndices;
        uint256[] pendingOrderCounts;
    }

    struct ExecuteOrderParams {
        OrderLib.OrderId orderId;
        uint96 sell;
        TradeParams tradeParams;
        bytes payload;
    }

    event OrderFilled(bytes32 indexed id, uint256 sold, uint256 bought);

    function receiveIncomingOrders(OrderLib.Order[] calldata orders, Currency currency, uint256 amount) external;
    function removeDustOrders(uint256 _incomingOrders) external;

    function setOrders(uint256 _incomingOrders, OrderLib.Order[] calldata orders) external;

    /// @notice Execute the given local order
    /// @param params Execute order data
    function executeOrder(ExecuteOrderParams calldata params) external;

    function finishOrderExecution(FinishOrderExecutionParams calldata params)
        external
        returns (PendingOrder[] memory pendingOrders);

    function updateFundManager(address fundManager, bool isAllowed) external;

    function setMessenger(address messenger) external;

    function setPriceOracle(address priceOracle) external;

    function setMaxSlippageInBP(uint16 maxSlippageInBP) external;

    function orderOf(OrderLib.OrderId calldata orderIdParams) external view returns (uint96 amount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {CommandLib} from "../libraries/CommandLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IValidator {
    function validate(
        CommandLib.BalanceState[] calldata currencyStates,
        a160u96 target,
        uint256[] calldata packedConfigs
    ) external;

    function mapTarget(
        CommandLib.BalanceState calldata currencyState,
        a160u96 target,
        uint256 packedConfig,
        bytes calldata data
    ) external returns (CommandLib.Info memory targetInfo);

    function updateTarget(address target, bool isAllowed) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {a160u96} from "../../utils/a160u96.sol";

interface IPriceOracleDeployer {
    function deploy(uint256[] calldata chainIds, a160u96[][] calldata currencyBalances)
        external
        returns (address staticPriceOracle);

    function setPriceSourceMapper(address _priceSourceMapper) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

interface IVault {
    struct CurrencyWithdrawal {
        uint256[] currencyIndexSet;
        uint96[] amounts;
    }

    struct SnapshotAnatomy {
        a160u96[] currencies;
        uint256[] currencyIndexSet;
    }

    struct EndRebalancingParams {
        a160u96[] anatomyCurrencies;
        SnapshotAnatomy newAnatomy;
        CurrencyWithdrawal withdrawals;
        uint256 lastKBalance;
        Currency[] currencies;
    }

    struct RebalancingResult {
        uint256 chainId;
        uint256 snapshot;
        uint256[] currencyIdSet;
        a160u96[] currencies;
    }

    struct RegisterCurrenciesResult {
        Currency[] currencies;
        bytes32 currenciesHash;
    }

    function setOrderBook(address _orderBook) external;
    function setMessenger(address _messenger) external;

    function startRebalancingPhase(CurrencyWithdrawal calldata withdrawals) external;

    function finishRebalancingPhase(EndRebalancingParams calldata params) external returns (bytes32);
    function transferLatestSnapshot(address recipient, uint256 kAmountWads) external returns (uint256);
    function withdraw(uint256 snapshot, uint256 kAmount, address recipient) external;
    function registerCurrencies(Currency[] calldata currencies) external returns (RegisterCurrenciesResult memory);

    function donate(Currency currency, bytes memory data) external;
    function consume(Currency currency, uint96 amount, address target, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import {a160u96} from "../utils/a160u96.sol";

type Currency is address;

using {eq as ==, neq as !=} for Currency global;

function eq(Currency currency, Currency other) pure returns (bool) {
    return Currency.unwrap(currency) == Currency.unwrap(other);
}

function neq(Currency currency, Currency other) pure returns (bool) {
    return !eq(currency, other);
}

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
/// @author Modified from Uniswap (https://github.com/Uniswap/v4-core/blob/main/src/types/Currency.sol)
library CurrencyLib {
    using SafeERC20 for IERC20;
    using FixedPointMathLib for uint256;
    using CurrencyLib for Currency;

    /// @dev Currency wrapper for native currency
    Currency public constant NATIVE = Currency.wrap(address(0));

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    /// @notice Thrown when an ERC20 transfer fails
    error ERC20TransferFailed();

    /// @notice Thrown when deposit amount exceeds current balance
    error AmountExceedsBalance();

    /// @notice Transfers currency
    /// @param currency Currency to transfer
    /// @param to Address of recipient
    /// @param amount Currency amount ot transfer
    function transfer(Currency currency, address to, uint256 amount) internal {
        if (amount == 0) return;
        // implementation from
        // https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/SafeTransferLib.sol

        bool success;
        if (currency.isNative()) {
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }

            if (!success) revert NativeTransferFailed();
        } else {
            assembly {
                // We'll write our calldata to this slot below, but restore it later.
                let freeMemoryPointer := mload(0x40)

                // Write the abi-encoded calldata into memory, beginning with the function selector.
                mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
                mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

                success :=
                    and(
                        // Set success to whether the call reverted, if not we check it either
                        // returned exactly 1 (can't just be non-zero data), or had no return data.
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                        // Counterintuitively, this call() must be positioned after the or() in the
                        // surrounding and() because and() evaluates its arguments from right to left.
                        call(gas(), currency, 0, freeMemoryPointer, 68, 0, 32)
                    )
            }

            if (!success) revert ERC20TransferFailed();
        }
    }

    /// @notice Approves currency
    /// @param currency Currency to approve
    /// @param spender Address of spender
    /// @param amount Currency amount to approve
    function approve(Currency currency, address spender, uint256 amount) internal {
        if (isNative(currency)) return;
        IERC20(Currency.unwrap(currency)).forceApprove(spender, amount);
    }

    /// @notice Deposits a specified amount of a given currency into the contract
    /// @dev Handles both native and ERC20 token deposits
    /// @param currency The currency to deposit
    /// @param amount The amount of currency to deposit
    /// @return deposited The actual amount deposited
    function selfDeposit(Currency currency, uint96 amount) internal returns (uint96 deposited) {
        if (currency.isNative()) {
            if (msg.value < amount) revert AmountExceedsBalance();
            deposited = amount;
        } else {
            IERC20 token = IERC20(Currency.unwrap(currency));
            uint256 _balance = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            // safe cast, transferred amount is <= 2^96-1
            deposited = SafeCastLib.safeCastTo96(token.balanceOf(address(this)) - _balance);
        }
    }

    /// @notice Withdraws a specified amount of a given currency to a specified address
    /// @param currency The currency and amount to withdraw (a160u96 format)
    /// @param kAmount The K amount to withdraw (in kind of currency)
    /// @param to The address to which the currency will be withdrawn
    /// @return amount The actual amount withdrawn
    function withdraw(a160u96 currency, uint256 kAmount, address to) internal returns (uint96 amount) {
        amount = uint96(kAmount.mulWadDown(currency.value()));
        if (to != address(this)) {
            currency.currency().transfer(to, amount);
        }
    }

    /// @notice Returns the balance of a given currency for a specific account
    /// @param currency The currency to check
    /// @param account The address of the account
    /// @return The balance of the specified currency for the given account
    function balanceOf(Currency currency, address account) internal view returns (uint256) {
        return currency.isNative() ? account.balance : IERC20(Currency.unwrap(currency)).balanceOf(account);
    }

    /// @notice Returns the balance of a given currency for this contract
    /// @param currency The currency to check
    /// @return The balance of the specified currency for this contract
    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        return currency.isNative() ? address(this).balance : IERC20(Currency.unwrap(currency)).balanceOf(address(this));
    }

    /// @notice Checks if the specified currency is the native currency
    /// @param currency The currency to check
    /// @return `true` if the specified currency is the native currency, `false` otherwise
    function isNative(Currency currency) internal pure returns (bool) {
        return currency == NATIVE;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IBlockingApp} from "../interfaces/IBlockingApp.sol";
import {IOrderBook} from "../interfaces/IOrderBook.sol";
import {IOmnichainMessenger, Currency} from "../interfaces/IOmnichainMessenger.sol";
import {IVault} from "../interfaces/IVault.sol";

import {Owned} from "solmate/auth/Owned.sol";

contract Governance {
    function setOrderBook(address vault, address orderBook) external {
        IVault(vault).setOrderBook(orderBook);
    }

    function setMessenger(address target, address messenger) external {
        IVault(target).setMessenger(messenger);
    }

    function updateFundManager(address orderBook, address fundManager, bool isAllowed) external {
        IOrderBook(orderBook).updateFundManager(fundManager, isAllowed);
    }

    function setPriceOracle(address orderBook, address priceOracle) external {
        IOrderBook(orderBook).setPriceOracle(priceOracle);
    }

    function setMaxSlippageInBP(address orderBook, uint16 maxSlippageInBP) external {
        IOrderBook(orderBook).setMaxSlippageInBP(maxSlippageInBP);
    }

    function setConfig(address messenger, uint16 version, uint16 eid, uint256 configType, bytes calldata config)
        external
    {
        IBlockingApp(messenger).setConfig(version, eid, configType, config);
    }

    function setSendVersion(address messenger, uint16 version) external {
        IBlockingApp(messenger).setSendVersion(version);
    }

    function setReceiveVersion(address messenger, uint16 version) external {
        IBlockingApp(messenger).setReceiveVersion(version);
    }

    function forceResumeReceive(address messenger, uint16 srcEid, bytes calldata srcAddress) external {
        IBlockingApp(messenger).forceResumeReceive(srcEid, srcAddress);
    }

    function setTrustedRemote(
        address messenger,
        uint256 remoteChainId,
        uint16 remoteEid,
        uint256 minGasAmount,
        bytes calldata path,
        IBlockingApp.PoolIds calldata poolIds
    ) external {
        IBlockingApp(messenger).setTrustedRemote(remoteChainId, remoteEid, minGasAmount, path, poolIds);
    }

    function withdrawCurrency(address messenger, Currency currency, address to, uint256 amount) external {
        IOmnichainMessenger(messenger).withdrawCurrency(currency, to, amount);
    }

    function setBridgingInfo(address messenger, IOmnichainMessenger.BridgingInfo[] calldata _infos) external {
        IOmnichainMessenger(messenger).setBridgingInfo(_infos);
    }

    function setHomeEid(address messenger, uint16 homeEid) external {
        IOmnichainMessenger(messenger).setHomeEid(homeEid);
    }

    function transferContractOwnership(address owned, address newOwner) external {
        Owned(owned).transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";

type a160u96 is uint256;

using {addr, unpack, unpackRaw, currency, value, eq as ==, neq as !=} for a160u96 global;

error AddressMismatch(address, address);

function neq(a160u96 a, a160u96 b) pure returns (bool) {
    return !eq(a, b);
}

function eq(a160u96 a, a160u96 b) pure returns (bool) {
    return a160u96.unwrap(a) == a160u96.unwrap(b);
}

function currency(a160u96 packed) pure returns (Currency) {
    return Currency.wrap(addr(packed));
}

function addr(a160u96 packed) pure returns (address) {
    return address(uint160(a160u96.unwrap(packed)));
}

function value(a160u96 packed) pure returns (uint96) {
    return uint96(a160u96.unwrap(packed) >> 160);
}

function unpack(a160u96 packed) pure returns (Currency _curr, uint96 _value) {
    uint256 raw = a160u96.unwrap(packed);
    _curr = Currency.wrap(address(uint160(raw)));
    _value = uint96(raw >> 160);
}

function unpackRaw(a160u96 packed) pure returns (address _addr, uint96 _value) {
    uint256 raw = a160u96.unwrap(packed);
    _addr = address(uint160(raw));
    _value = uint96(raw >> 160);
}

library A160U96Factory {
    function create(address _addr, uint96 _value) internal pure returns (a160u96) {
        return a160u96.wrap((uint256(_value) << 160) | uint256(uint160(_addr)));
    }

    function create(Currency _currency, uint96 _value) internal pure returns (a160u96) {
        return create(Currency.unwrap(_currency), _value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {Currency} from "../libraries/CurrencyLib.sol";

interface ICurrencyMetadata {
    struct RegisteredMetadata {
        uint256 chainId;
        CurrencyMetadata[] metadata;
        bytes32 currenciesHash;
    }

    struct CurrencyMetadata {
        string name;
        string symbol;
        uint8 decimals;
        Currency currency;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {IOrderBook} from "./IOrderBook.sol";
import {IStargateRouter} from "./stargate/IStargateRouter.sol";

import {Currency} from "../libraries/CurrencyLib.sol";

interface IOmnichainMessenger {
    struct BridgingInfo {
        uint256 finalDstChainId;
        Currency localCurrency;
    }

    struct HashedResult {
        uint256 chainId;
        bytes32 hash;
    }

    struct LzParams {
        bytes[] options;
        address zroPaymentAddress;
    }

    struct SgParams {
        IStargateRouter.lzTxObj lzTxObj;
        uint256 minAmountLD;
    }

    function withdrawCurrency(Currency currency, address to, uint256 amount) external;

    function setHomeEid(uint16 homeEid) external;

    function setOrderBook(address orderBook) external;

    function setBridgingInfo(BridgingInfo[] calldata _infos) external;

    function pushIncomingOrders(
        uint256 srcChainId,
        IOrderBook.BoughtOrder[] memory boughtOrders,
        uint256 boughtOrdersTotalAmount,
        Currency currency,
        uint256 receivedAmount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

type u16x15 is uint256;

using {length, at} for u16x15 global;

function at(u16x15 packed, uint256 index) pure returns (uint16 value) {
    assembly ("memory-safe") {
        value := shr(mul(index, 16), packed)
    }
}

function length(u16x15 packed) pure returns (uint256 value) {
    assembly ("memory-safe") {
        value := shr(240, packed)
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Currency} from "./CurrencyLib.sol";
import {BitSet} from "./BitSet.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OrderLib} from "./OrderLib.sol";
import {PriceLib} from "../price-oracles/libraries/PriceLib.sol";
import {StackLib} from "./StackLib.sol";

import {IVault} from "../interfaces/IVault.sol";
import {IConfigBuilder} from "../interfaces/IConfigBuilder.sol";

library RebalancingLib {
    using SafeCastLib for *;
    using BitSet for *;
    using FixedPointMathLib for *;
    using PriceLib for *;
    using StackLib for StackLib.Node;

    struct RebalancingVars {
        StackLib.Node sellDeltas;
        StackLib.Node buyDeltas;
        uint256 targetInBase;
        uint256 currentInBase;
        uint256 i;
        uint256 j;
        uint256 priorChainIndex;
        uint256 activeChainIndex;
        uint256 currencyIndex;
        uint256 orderIndex;
        uint256 weightIndex;
        bytes32 chainsHash;
        bytes32 currenciesHash;
        uint256[] counters;
        bool priorChain;
        bool activeChain;
        bool priorAsset;
    }

    struct ChainOrders {
        OrderLib.Order[] orders;
        uint128 incomingOrders;
    }

    struct ReserveRebalancingVars {
        uint256 orderCount;
        uint96 utilized;
        uint256 i;
        uint256 j;
        uint256 lastIndex;
        uint256 orderIndex;
        uint256 weightIndex;
        bytes32 chainsHash;
    }

    struct ValuationInfo {
        uint96[] balances;
        uint256[] prices;
        uint256 totalValuation;
    }

    struct RebalancingResult {
        ChainOrders[] chainOrders;
        IVault.CurrencyWithdrawal[] withdrawals;
        uint256[] chainIdSet;
        uint256[] counters;
    }

    uint256 internal constant MAX_WEIGHT = type(uint16).max;

    error CurrenciesHashMismatch(uint256);
    error TotalWeight();
    error UnutilizedWeights();
    error ChainsHashMismatch();

    function previewRebalancingOrders(
        mapping(uint256 => bytes32) storage currenciesHashOf,
        ValuationInfo memory valuationInfo,
        IConfigBuilder.StartRebalancingParams calldata params,
        bytes32 chainsHash
    ) internal view returns (RebalancingResult memory result) {
        result.chainIdSet = params.anatomy.chainIdSet.addAll(params.newAnatomy.chainIdSet);
        result.chainOrders = new ChainOrders[](result.chainIdSet.size());
        result.withdrawals = new IVault.CurrencyWithdrawal[](result.chainOrders.length);

        result.counters = new uint256[](result.chainOrders.length);

        RebalancingVars memory vars;
        for (; vars.i < params.chainIds.length;) {
            vars.chainsHash = keccak256(abi.encode(vars.chainsHash, params.chainIds[vars.i]));

            vars.priorChain = params.anatomy.chainIdSet.contains(vars.i);
            vars.activeChain = params.newAnatomy.chainIdSet.contains(vars.i);
            if (vars.activeChain || vars.priorChain) {
                if (vars.priorChain) {
                    result.chainOrders[vars.orderIndex].orders =
                        new OrderLib.Order[](params.orderCounts[vars.orderIndex]);
                    result.withdrawals[vars.orderIndex] = IVault.CurrencyWithdrawal(
                        BitSet.create(params.currencies[vars.orderIndex].length),
                        new uint96[](params.anatomy.currencyIdSets[vars.priorChainIndex].size())
                    );
                }

                IVault.CurrencyWithdrawal memory withdrawal = result.withdrawals[vars.orderIndex];

                vars.currenciesHash = bytes32(0);
                Currency[] calldata currencies = params.currencies[vars.orderIndex];
                for (vars.j = 0; vars.j < currencies.length;) {
                    vars.currenciesHash = keccak256(abi.encode(vars.currenciesHash, currencies[vars.j]));
                    vars.priorAsset =
                        vars.priorChain && params.anatomy.currencyIdSets[vars.priorChainIndex].contains(vars.j);

                    vars.targetInBase = vars.activeChain
                        && params.newAnatomy.currencyIdSets[vars.activeChainIndex].contains(vars.j)
                        ? valuationInfo.totalValuation.mulDivUp(params.newWeights[vars.weightIndex++], MAX_WEIGHT)
                        : 0;

                    vars.currentInBase = vars.priorAsset
                        ? valuationInfo.balances[vars.currencyIndex].convertToBaseUp(
                            valuationInfo.prices[vars.currencyIndex]
                        )
                        : 0;

                    if (vars.currentInBase < vars.targetInBase) {
                        uint256 delta = vars.targetInBase - vars.currentInBase;
                        vars.buyDeltas =
                            vars.buyDeltas.push(delta, vars.orderIndex, currencies[vars.j], params.chainIds[vars.i]);
                    } else if (vars.currentInBase > vars.targetInBase) {
                        // result will never exceed type(uint96).max.
                        uint96 assets = uint96(
                            valuationInfo.balances[vars.currencyIndex].mulDivDown(
                                vars.currentInBase - vars.targetInBase, vars.currentInBase
                            )
                        );

                        if (assets != 0) {
                            vars.sellDeltas = vars.sellDeltas.push(
                                vars.currentInBase - vars.targetInBase,
                                assets,
                                vars.orderIndex,
                                currencies[vars.j],
                                valuationInfo.prices[vars.currencyIndex]
                            );

                            withdrawal.amounts[withdrawal.currencyIndexSet.size()] = assets;
                            withdrawal.currencyIndexSet.add(vars.j);
                        }
                    }

                    unchecked {
                        if (vars.priorAsset) ++vars.currencyIndex;
                        ++vars.j;
                    }
                }

                if (vars.currenciesHash != currenciesHashOf[vars.i]) {
                    revert CurrenciesHashMismatch(params.chainIds[vars.i]);
                }

                (vars.sellDeltas, vars.buyDeltas) =
                    _createOrders(result.chainOrders, vars.sellDeltas, vars.buyDeltas, result.counters);

                unchecked {
                    if (vars.priorChain) ++vars.priorChainIndex;
                    if (vars.activeChain) ++vars.activeChainIndex;
                    ++vars.orderIndex;
                }
            }

            unchecked {
                ++vars.i;
            }
        }

        if (params.newWeights.length != vars.weightIndex) revert UnutilizedWeights();
        if (vars.chainsHash != chainsHash) revert ChainsHashMismatch();
    }

    function previewReserveRebalancingOrders(
        mapping(uint256 => bytes32) storage currenciesHashOf,
        uint256[] memory weights,
        IConfigBuilder.StartReserveRebalancingParams calldata params,
        uint96 reserveAmount,
        Currency reserve,
        bytes32 chainsHash
    ) internal view returns (ChainOrders[] memory orders) {
        orders = new ChainOrders[](params.anatomy.chainIdSet.size());

        ReserveRebalancingVars memory vars;
        vars.orderCount = weights.length;
        vars.lastIndex = vars.orderCount - 1;

        orders[0].orders = new OrderLib.Order[](vars.orderCount);

        for (; vars.i < params.chainIds.length; ++vars.i) {
            vars.chainsHash = keccak256(abi.encode(vars.chainsHash, params.chainIds[vars.i]));

            if (!params.anatomy.chainIdSet.contains(vars.i)) continue;

            bytes32 currenciesHash;
            Currency[] calldata currencies = params.currencies[vars.orderIndex];
            for (vars.j = 0; vars.j < currencies.length; ++vars.j) {
                currenciesHash = keccak256(abi.encode(currenciesHash, currencies[vars.j]));

                if (params.anatomy.currencyIdSets[vars.orderIndex].contains(vars.j)) {
                    uint96 orderSellAmount = vars.weightIndex == vars.lastIndex
                        ? reserveAmount - vars.utilized
                        : reserveAmount.mulDivDown(weights[vars.weightIndex], MAX_WEIGHT).safeCastTo96();
                    orders[0].orders[vars.weightIndex] = OrderLib.Order(
                        orderSellAmount,
                        OrderLib.OrderId(reserve, currencies[vars.j], currencies[vars.j], params.chainIds[vars.i])
                    );

                    unchecked {
                        if (vars.orderIndex != 0 && orderSellAmount != 0) {
                            ++orders[vars.orderIndex].incomingOrders;
                        }
                        vars.utilized += orderSellAmount;
                        ++vars.weightIndex;
                    }
                }
            }

            if (currenciesHash != currenciesHashOf[vars.i]) revert CurrenciesHashMismatch(params.chainIds[vars.i]);

            unchecked {
                ++vars.orderIndex;
            }
        }

        if (vars.chainsHash != chainsHash) revert ChainsHashMismatch();
    }

    function checkTotalWeight(uint256[] calldata weights) internal pure {
        uint256 total;
        for (uint256 i; i < weights.length; ++i) {
            total += weights[i];
        }
        if (total != MAX_WEIGHT) revert TotalWeight();
    }

    function _createOrders(
        ChainOrders[] memory orders,
        StackLib.Node memory sellDeltas,
        StackLib.Node memory buyDeltas,
        uint256[] memory counters
    ) internal pure returns (StackLib.Node memory, StackLib.Node memory) {
        // while one of lists is not empty
        while (sellDeltas.notEmpty() && buyDeltas.notEmpty()) {
            // get first nodes from both lists
            StackLib.Data memory sell = sellDeltas.peek();
            StackLib.Data memory buy = buyDeltas.peek();

            uint256 fill = Math.min(sell.delta, buy.delta);
            sell.delta -= fill;
            buy.delta -= fill;

            uint256 sellAmount = Math.min(fill.convertToAssetsUp(sell.data), sell.availableAssets);
            sell.availableAssets -= sellAmount;

            orders[sell.orderIndex].orders[counters[sell.orderIndex]++] = OrderLib.Order(
                sellAmount.safeCastTo96(), OrderLib.OrderId(sell.currency, buy.currency, buy.currency, buy.data)
            );

            // increment "fence" counter
            if (buy.orderIndex != sell.orderIndex && sellAmount != 0) {
                ++orders[buy.orderIndex].incomingOrders;
            }

            // remove nodes with zero delta. Notice, both deltas can be set to zero.
            if (sell.delta == 0) {
                sellDeltas = sellDeltas.pop();
            }
            if (buy.delta == 0) {
                buyDeltas = buyDeltas.pop();
            }
        }

        return (sellDeltas, buyDeltas);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {Currency} from "./CurrencyLib.sol";

library OrderLib {
    struct OrderId {
        // Sell currency of order
        Currency sellCurrency;
        // Local buy currency of order
        Currency localBuyCurrency;
        // Final destination buy currency of order
        Currency finalDestinationBuyCurrency;
        // Final destination chainId of order
        uint256 finalDestinationChainId;
    }

    struct Order {
        // Sell amount of order
        uint96 sellAmount;
        // Id params of order
        OrderId idParams;
    }

    struct OrderRegistry {
        // Sell amount of given order
        mapping(bytes32 => uint96) orderOf;
        // Hash of registry state
        bytes32 ordersHash;
    }

    /// @notice Emitted when a new order is created
    event NewOrder(
        uint256 sellAmount,
        Currency indexed sellCurrency,
        Currency localBuyCurrency,
        Currency indexed finalDestinationBuyCurrency,
        uint256 finalDestinationChainId
    );

    /// @dev Thrown when there's a mismatch in order hashes
    error OrderHashMismatch();
    /// @dev Thrown when an order is not filled
    error OrderNotFilled(bytes32 id);

    /// @notice Sets multiple orders in the registry
    /// @param self The order registry where orders are stored
    /// @param orders An array of orders to set in the registry
    function set(OrderRegistry storage self, Order[] calldata orders) internal {
        bytes32 newHash = self.ordersHash;
        for (uint256 i; i < orders.length; ++i) {
            if (orders[i].sellAmount == 0) continue;

            OrderId calldata params = orders[i].idParams;
            // don't need to create order for the same currency within a single chain, as it's already in the final destination
            if (params.sellCurrency != params.localBuyCurrency || params.finalDestinationChainId != block.chainid) {
                bytes32 idKey = id(params);
                newHash = keccak256(abi.encode(newHash, idKey));
                self.orderOf[idKey] += orders[i].sellAmount;

                emit NewOrder(
                    orders[i].sellAmount,
                    params.sellCurrency,
                    params.localBuyCurrency,
                    params.finalDestinationBuyCurrency,
                    params.finalDestinationChainId
                );
            }
        }
        self.ordersHash = newHash;
    }

    /// @notice Fills a specific order from the registry
    /// @param self The order registry
    /// @param orderId The id params of the order to fill
    /// @param sell The sell amount of the order
    function fill(OrderRegistry storage self, OrderId calldata orderId, uint96 sell) internal {
        self.orderOf[id(orderId)] -= sell;
    }

    /// @notice Resets the orders in the registry
    /// @param self The order registry to reset
    /// @param orderIds An array of order id parameters to reset
    function reset(OrderRegistry storage self, OrderId[] calldata orderIds) internal {
        bytes32 ordersHash;
        for (uint256 i; i < orderIds.length; ++i) {
            bytes32 idKey = id(orderIds[i]);
            ordersHash = keccak256(abi.encode(ordersHash, idKey));

            if (self.orderOf[idKey] != 0) revert OrderNotFilled(idKey);
        }

        if (ordersHash != self.ordersHash) revert OrderHashMismatch();

        self.ordersHash = bytes32(0);
    }

    /// @notice Retrieves the sell amount of a specific order
    /// @param self The order registry
    /// @param orderId The id parameters of the order to retrieve
    /// @return The sell amount of the specified order
    function get(OrderRegistry storage self, OrderId calldata orderId) internal view returns (uint96) {
        return self.orderOf[id(orderId)];
    }

    /// @dev Generates a unique id for an order based on its parameters
    /// @param self The order id parameters
    /// @return A unique bytes32 id for the order
    function id(OrderId calldata self) internal pure returns (bytes32) {
        return keccak256(abi.encode(self));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import {IValidator} from "../interfaces/IValidator.sol";

import {CurrencyLib, Currency} from "./CurrencyLib.sol";
import {a160u96} from "../utils/a160u96.sol";

library CommandLib {
    using CurrencyLib for Currency;

    struct CommandTarget {
        a160u96 target;
        address spender;
        bool mapTarget;
        bytes[] datas;
        uint256[] packedConfigs;
    }

    struct BalanceState {
        Currency currency;
        uint256 minBalance;
    }

    struct Info {
        a160u96 target;
        address spender;
        bytes data;
    }

    uint256 internal constant PACKED_CONFIG_TARGET_CONFIG_BITS = 4;
    uint256 internal constant PACKED_CONFIG_SIZE_BITS = 20;
    uint256 internal constant PACKED_CONFIG_MASK = ~(type(uint256).max << PACKED_CONFIG_SIZE_BITS);

    error CallFailed(bytes);

    function callCommand(CommandTarget calldata command, address validator, BalanceState memory currencyState)
        internal
    {
        BalanceState[] memory currencyStates = new BalanceState[](1);
        currencyStates[0] = currencyState;

        _executeCommand(command, IValidator(validator), currencyStates);
    }

    function executeCommands(CommandTarget[] calldata commands, address validator, BalanceState[] memory currencyStates)
        internal
    {
        for (uint256 i; i < commands.length; ++i) {
            _executeCommand(commands[i], IValidator(validator), currencyStates);
        }
    }

    function _executeCommand(CommandTarget calldata cmd, IValidator validator, BalanceState[] memory currencyStates)
        internal
    {
        // only-target flag is set, batch call can be executed
        if (!cmd.mapTarget) validator.validate(currencyStates, cmd.target, cmd.packedConfigs);

        uint256 k;
        for (uint256 j; j < cmd.packedConfigs.length; ++j) {
            for (uint256 pc = cmd.packedConfigs[j]; pc != 0; pc >>= PACKED_CONFIG_SIZE_BITS) {
                BalanceState memory state = currencyStates[uint16(pc >> PACKED_CONFIG_TARGET_CONFIG_BITS) - 1];
                if (cmd.mapTarget) {
                    Info memory info = validator.mapTarget(state, cmd.target, pc & PACKED_CONFIG_MASK, cmd.datas[k]);
                    _call(state.currency, info.target, info.spender, info.data);
                } else {
                    _call(state.currency, cmd.target, cmd.spender, cmd.datas[k]);
                }

                unchecked {
                    // cannot overflow,
                    ++k;
                }
            }
        }
    }

    function _call(Currency currency, a160u96 target, address spender, bytes memory data)
        private
        returns (bool success, bytes memory returnData)
    {
        bool approve = spender != address(0);
        if (approve) currency.approve(spender, type(uint256).max);

        (address targetAddr, uint96 value) = target.unpackRaw();
        (success, returnData) = targetAddr.call{value: value}(data);
        if (!success) revert CallFailed(returnData);

        if (approve) currency.approve(spender, 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo232(uint256 x) internal pure returns (uint232 y) {
        require(x < 1 << 232);

        y = uint232(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastTo208(uint256 x) internal pure returns (uint208 y) {
        require(x < 1 << 208);

        y = uint208(x);
    }

    function safeCastTo200(uint256 x) internal pure returns (uint200 y) {
        require(x < 1 << 200);

        y = uint200(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
        require(x < 1 << 176);

        y = uint176(x);
    }

    function safeCastTo168(uint256 x) internal pure returns (uint168 y) {
        require(x < 1 << 168);

        y = uint168(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo152(uint256 x) internal pure returns (uint152 y) {
        require(x < 1 << 152);

        y = uint152(x);
    }

    function safeCastTo144(uint256 x) internal pure returns (uint144 y) {
        require(x < 1 << 144);

        y = uint144(x);
    }

    function safeCastTo136(uint256 x) internal pure returns (uint136 y) {
        require(x < 1 << 136);

        y = uint136(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo120(uint256 x) internal pure returns (uint120 y) {
        require(x < 1 << 120);

        y = uint120(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo104(uint256 x) internal pure returns (uint104 y) {
        require(x < 1 << 104);

        y = uint104(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo88(uint256 x) internal pure returns (uint88 y) {
        require(x < 1 << 88);

        y = uint88(x);
    }

    function safeCastTo80(uint256 x) internal pure returns (uint80 y) {
        require(x < 1 << 80);

        y = uint80(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo56(uint256 x) internal pure returns (uint56 y) {
        require(x < 1 << 56);

        y = uint56(x);
    }

    function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
        require(x < 1 << 48);

        y = uint48(x);
    }

    function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {ILayerZeroReceiver} from "layerzero/interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "layerzero/interfaces/ILayerZeroUserApplicationConfig.sol";

interface IBlockingApp is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    struct PoolIds {
        uint128 src;
        uint128 dst;
    }

    function setConfig(uint16 version, uint16 eid, uint256 configType, bytes calldata config) external;

    function setSendVersion(uint16 version) external;

    function setReceiveVersion(uint16 version) external;

    function setTrustedRemote(
        uint256 remoteChainId,
        uint16 remoteEid,
        uint256 minGasAmount,
        bytes calldata path,
        PoolIds calldata poolIds
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall; // extra gas, if calling smart contract,
        uint256 dstNativeAmount; // amount of dust dropped in destination wallet
        bytes dstNativeAddr; // destination wallet for dust
    }

    function swap(
        uint16 _dstEid,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstEid,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);

    function factory() external view returns (address);
}

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library BitSet {
    uint256 private constant WORD_SHIFT = 8;

    function hasNext(uint256 word, uint256 bit) internal pure returns (bool r) {
        assembly ("memory-safe") {
            r := and(shr(bit, word), 1)
        }
    }

    function find(uint256 word, uint256 b) internal pure returns (uint256 nb) {
        assembly ("memory-safe") {
            let w := shr(b, word)
            switch w
            case 0 {
                // no more bits
                nb := 256
            }
            default {
                // 0b000 = 0
                // 0b001 = 1
                // 0b010 = 2
                // 0b011 = 3
                // 0b100 = 4
                // 0b101 = 5
                // 0b110 = 6
                // 0b111 = 7
                switch and(w, 7)
                case 0 { nb := add(lsb(w), b) }
                case 2 { nb := add(b, 1) }
                case 4 { nb := add(b, 2) }
                case 6 { nb := add(b, 1) }
                default { nb := b }
            }

            function lsb(x) -> r {
                if iszero(x) { revert(0, 0) }
                r := 255
                switch gt(and(x, 0xffffffffffffffffffffffffffffffff), 0)
                case 1 { r := sub(r, 128) }
                case 0 { x := shr(128, x) }

                switch gt(and(x, 0xffffffffffffffff), 0)
                case 1 { r := sub(r, 64) }
                case 0 { x := shr(64, x) }

                switch gt(and(x, 0xffffffff), 0)
                case 1 { r := sub(r, 32) }
                case 0 { x := shr(32, x) }

                switch gt(and(x, 0xffff), 0)
                case 1 { r := sub(r, 16) }
                case 0 { x := shr(16, x) }

                switch gt(and(x, 0xff), 0)
                case 1 { r := sub(r, 8) }
                case 0 { x := shr(8, x) }

                switch gt(and(x, 0xf), 0)
                case 1 { r := sub(r, 4) }
                case 0 { x := shr(4, x) }

                switch gt(and(x, 0x3), 0)
                case 1 { r := sub(r, 2) }
                case 0 { x := shr(2, x) }

                switch gt(and(x, 0x1), 0)
                case 1 { r := sub(r, 1) }
            }
        }
    }

    function valueAt(uint256 wordIndex, uint256 bit) internal pure returns (uint256 r) {
        assembly ("memory-safe") {
            r := or(shl(8, wordIndex), bit)
        }
    }

    function create(uint256 maxSize) internal pure returns (uint256[] memory bitset) {
        bitset = new uint256[](_capacity(maxSize));
    }

    function contains(uint256[] memory bitset, uint256 value) internal pure returns (bool _contains) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        if (wordIndex < bitset.length) {
            _contains = (bitset[wordIndex] & (1 << bit)) != 0;
        }
    }

    function add(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] |= (1 << bit);
        return bitset;
    }

    // a + b, add all elements of b from a
    function addAll(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory c) {
        (uint256 min, uint256 max) = a.length < b.length ? (a.length, b.length) : (b.length, a.length);
        c = new uint256[](max);
        uint256 i;
        for (; i < min; ++i) {
            c[i] = a[i] | b[i];
        }
        // copy leftover elements from a
        for (; i < a.length; ++i) {
            c[i] = a[i];
        }
        // copy leftover elements from b
        for (; i < b.length; ++i) {
            c[i] = b[i];
        }
    }

    function remove(uint256[] memory bitset, uint256 value) internal pure returns (uint256[] memory) {
        (uint256 wordIndex, uint8 bit) = _bitOffset(value);
        bitset[wordIndex] &= ~(1 << bit);
        return bitset;
    }

    function size(uint256[] memory bitset) internal pure returns (uint256 count) {
        for (uint256 i; i < bitset.length; ++i) {
            count += _countSetBits(bitset[i]);
        }
    }

    function _bitOffset(uint256 value) private pure returns (uint256 wordIndex, uint8 bit) {
        assembly ("memory-safe") {
            wordIndex := shr(8, value)
            // mask bits that don't fit the first wordIndex's bits
            // n % 2^i = n & (2^i - 1)
            bit := and(value, 255)
        }
    }

    function _capacity(uint256 maxSize) private pure returns (uint256 words) {
        // round up
        words = (maxSize + type(uint8).max) >> WORD_SHIFT;
    }

    function _countSetBits(uint256 x) private pure returns (uint256 count) {
        // Brian Kernighan’s Algorithm
        while (x != 0) {
            unchecked {
                // cannot overflow, x > 0
                x = x & (x - 1);
                ++count;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title PriceLib
/// @notice A library for handling fixed-point arithmetic for prices
library PriceLib {
    using FixedPointMathLib for uint256;

    /// @dev 2**128
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
    uint16 internal constant PRICE_ORACLE_DECIMALS = 18;
    uint256 internal constant DECIMALS_MULTIPLIER = 10 ** PRICE_ORACLE_DECIMALS;

    /// @notice Converts (down) an amount in base units to an amount in asset units based on a fixed-price value
    /// @param base The amount to convert in base units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in asset units
    function convertToAssetsDown(uint256 base, uint256 price) internal pure returns (uint256) {
        return base.mulDivDown(price, Q128);
    }

    /// @notice Converts (up) an amount in base units to an amount in asset units based on a fixed-price value
    /// @param base The amount to convert in base units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in asset units
    function convertToAssetsUp(uint256 base, uint256 price) internal pure returns (uint256) {
        return base.mulDivUp(price, Q128);
    }

    /// @notice Converts (down) an amount in asset units to an amount in base units based on a fixed-price value
    /// @param assets The amount to convert in asset units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in base units
    function convertToBaseDown(uint256 assets, uint256 price) internal pure returns (uint256) {
        return assets.mulDivDown(Q128, price);
    }

    /// @notice Converts (up) an amount in asset units to an amount in base units based on a fixed-price value
    /// @param assets The amount to convert in asset units
    /// @param price The fixed-price value represented as a uint256
    /// @return The equivalent amount in base units
    function convertToBaseUp(uint256 assets, uint256 price) internal pure returns (uint256) {
        return assets.mulDivUp(Q128, price);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import {Currency} from "./CurrencyLib.sol";

/// @title A library for managing a stack data
library StackLib {
    /// @dev Represents the data held in each stack node
    struct Data {
        // Index of order
        uint256 orderIndex;
        // Currency of order
        Currency currency;
        // Amount of order
        uint256 delta;
        // `price` for sell, `chainId` for buy
        uint256 data;
        // Available asset for sell data, 0 for buy data
        uint256 availableAssets;
    }

    /// @dev Represents a node in the stack
    struct Node {
        // Pointer to the next node
        uint256 next;
        // Value of the node
        Data value;
    }

    /// @notice Pushes a new sell order onto the stack
    /// @param head The current head of the stack
    /// @param delta The delta value of the order
    /// @param availableAssets The number of assets available for selling
    /// @param orderIndex The index of the order
    /// @param currency The currency used in the order
    /// @param price The price of the assets in the order
    /// @return newNode The new node created with the given data
    function push(
        Node memory head,
        uint256 delta,
        uint256 availableAssets,
        uint256 orderIndex,
        Currency currency,
        uint256 price
    ) internal pure returns (Node memory newNode) {
        newNode.value = Data(orderIndex, currency, delta, price, availableAssets);

        assembly {
            mstore(newNode, head) // Store the address of the current head in the new node's 'next'
        }
    }

    /// @notice Pushes a new buy order onto the stack
    /// @param head The current head of the stack
    /// @param delta The delta value of the order
    /// @param orderIndex The index of the order
    /// @param currency The currency used in the order
    /// @param chainId The chain ID associated with the buy order
    /// @return newNode The new node created with the given data
    function push(Node memory head, uint256 delta, uint256 orderIndex, Currency currency, uint256 chainId)
        internal
        pure
        returns (Node memory newNode)
    {
        newNode.value = Data(orderIndex, currency, delta, chainId, 0);

        assembly {
            mstore(newNode, head) // Store the address of the current head in the new node's 'next'
        }
    }

    /// @notice Pops the top value from the stack
    /// @param head The current head of the stack
    /// @return nextNode The next node in the stack after popping
    function pop(Node memory head) internal pure returns (Node memory nextNode) {
        assembly {
            nextNode := mload(head) // Load the address of the next node (which head points to)
        }
    }

    /// @notice Checks if the stack is not empty
    /// @param head The head of the stack to check
    /// @return `true` if the stack is not empty, `false` otherwise
    function notEmpty(Node memory head) internal pure returns (bool) {
        return head.next != 0 || head.value.delta != 0;
    }

    /// @notice Retrieves the value of the top node of the stack
    /// @param head The head of the stack
    /// @return The data value of the top node of the stack
    function peek(Node memory head) internal pure returns (Data memory) {
        return head.value;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}