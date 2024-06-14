// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// THIRD-PARTY
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// LIBRARIES & CONSTANTS
import {
    DEFAULT_FEE_INTEREST,
    DEFAULT_FEE_LIQUIDATION,
    DEFAULT_LIQUIDATION_PREMIUM,
    DEFAULT_FEE_LIQUIDATION_EXPIRED,
    DEFAULT_LIQUIDATION_PREMIUM_EXPIRED,
    DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER,
    PERCENTAGE_FACTOR,
    WAD
} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
import {BitMask, UNDERLYING_TOKEN_MASK} from "../libraries/BitMask.sol";

// CONTRACTS
import {ACLNonReentrantTrait} from "../traits/ACLNonReentrantTrait.sol";
import {CreditFacadeV3} from "./CreditFacadeV3.sol";
import {CreditManagerV3} from "./CreditManagerV3.sol";

// INTERFACES
import {IAdapter} from "@gearbox-protocol/core-v2/contracts/interfaces/IAdapter.sol";
import {ICreditConfiguratorV3, CreditManagerOpts, AllowanceAction} from "../interfaces/ICreditConfiguratorV3.sol";
import {IPriceOracleBase} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceOracleBase.sol";
import {IPoolQuotaKeeperV3} from "../interfaces/IPoolQuotaKeeperV3.sol";
import "../interfaces/IAddressProviderV3.sol";

// EXCEPTIONS
import "../interfaces/IExceptions.sol";

/// @title Credit configurator V3
/// @notice Provides funcionality to configure various aspects of credit manager and facade's behavior
/// @dev Most of the functions can only be accessed by configurator or timelock controller
contract CreditConfiguratorV3 is ICreditConfiguratorV3, ACLNonReentrantTrait {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using BitMask for uint256;

    /// @notice Contract version
    uint256 public constant override version = 3_01;

    /// @notice Address provider contract address
    address public immutable override addressProvider;

    /// @notice Credit manager address
    address public immutable override creditManager;

    /// @notice Underlying token address
    address public immutable override underlying;

    /// @dev Set of allowed contracts
    EnumerableSet.AddressSet internal allowedAdaptersSet;

    /// @dev Set of emergency liquidators
    EnumerableSet.AddressSet internal emergencyLiquidatorsSet;

    /// @dev Ensures that function is not called for underlying token
    modifier nonUnderlyingTokenOnly(address token) {
        _revertIfUnderlyingToken(token);
        _;
    }

    /// @notice Constructor
    ///         - For a newly deployed credit manager, performs initial configuration:
    ///           * sets its fee parameters to default values
    ///           * connects the credit facade and sets debt limits in it
    ///         - For an existing credit manager, simply copies lists of allowed adapters and emergency liquidators
    ///           from the currently connected credit configurator
    /// @param _creditManager Credit manager to connect to
    /// @param _creditFacade Facade to connect to the credit manager (ignored for existing credit managers)
    /// @param opts Credit manager configuration paramaters, see `CreditManagerOpts` for details
    /// @dev When deploying a new credit suite, this contract must be deployed via `create2`. By the moment of deployment,
    ///      new credit manager must already have pre-computed address of this contract set as credit configurator.
    constructor(CreditManagerV3 _creditManager, CreditFacadeV3 _creditFacade, CreditManagerOpts memory opts)
        ACLNonReentrantTrait(_creditManager.addressProvider())
    {
        creditManager = address(_creditManager); // I:[CC-1]

        underlying = _creditManager.underlying(); // I:[CC-1]

        addressProvider = _creditManager.addressProvider(); // I:[CC-1]

        address currentConfigurator = CreditManagerV3(creditManager).creditConfigurator(); // I:[CC-41]

        // existing credit manager
        if (currentConfigurator != address(this)) {
            address[] memory allowedAdaptersPrev = CreditConfiguratorV3(currentConfigurator).allowedAdapters(); // I:[CC-29]
            uint256 len = allowedAdaptersPrev.length;
            unchecked {
                for (uint256 i = 0; i < len; ++i) {
                    allowedAdaptersSet.add(allowedAdaptersPrev[i]); // I:[CC-29]
                }
            }

            address[] memory emergencyLiquidatorsPrev = CreditConfiguratorV3(currentConfigurator).emergencyLiquidators(); // I:[CC-29]
            len = emergencyLiquidatorsPrev.length;
            unchecked {
                for (uint256 i = 0; i < len; ++i) {
                    emergencyLiquidatorsSet.add(emergencyLiquidatorsPrev[i]); // I:[CC-29]
                }
            }
        }
        // new credit manager
        else {
            _setFees({
                feeInterest: DEFAULT_FEE_INTEREST,
                feeLiquidation: DEFAULT_FEE_LIQUIDATION,
                liquidationDiscount: PERCENTAGE_FACTOR - DEFAULT_LIQUIDATION_PREMIUM,
                feeLiquidationExpired: DEFAULT_FEE_LIQUIDATION_EXPIRED,
                liquidationDiscountExpired: PERCENTAGE_FACTOR - DEFAULT_LIQUIDATION_PREMIUM_EXPIRED
            }); // I:[CC-1]

            CreditManagerV3(creditManager).setCreditFacade(address(_creditFacade)); // I:[CC-1]

            emit SetCreditFacade(address(_creditFacade)); // I:[CC-1A]
            emit SetPriceOracle(CreditManagerV3(creditManager).priceOracle()); // I:[CC-1A]

            _setMaxDebtPerBlockMultiplier(address(_creditFacade), uint8(DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER)); // I:[CC-1]
            _setLimits({_creditFacade: address(_creditFacade), minDebt: opts.minDebt, maxDebt: opts.maxDebt}); // I:[CC-1]
        }
    }

    /// @notice Returns the facade currently connected to the credit manager
    function creditFacade() public view override returns (address) {
        return CreditManagerV3(creditManager).creditFacade();
    }

    // ------ //
    // TOKENS //
    // ------ //

    /// @notice Makes token recognizable as collateral in the credit manager and sets its liquidation threshold
    /// @notice In case token is quoted in the quota keeper, also makes it quoted in the credit manager
    /// @param token Token to add
    /// @param liquidationThreshold LT to set in bps
    /// @dev Reverts if `token` is not a valid ERC-20 token
    /// @dev Reverts if `token` does not have a price feed in the price oracle
    /// @dev Reverts if `token` is underlying
    /// @dev Reverts if `liquidationThreshold` is greater than underlying's LT
    function addCollateralToken(address token, uint16 liquidationThreshold)
        external
        override
        nonZeroAddress(token)
        configuratorOnly // I:[CC-2]
    {
        _addCollateralToken({token: token}); // I:[CC-3,4]
        _setLiquidationThreshold({token: token, liquidationThreshold: liquidationThreshold}); // I:[CC-4]
    }

    /// @dev `addCollateralToken` implementation
    function _addCollateralToken(address token) internal {
        if (!token.isContract()) revert AddressIsNotContractException(token); // I:[CC-3]

        try IERC20(token).balanceOf(address(this)) returns (uint256) {}
        catch {
            revert IncorrectTokenContractException(); // I:[CC-3]
        }

        if (IPriceOracleBase(CreditManagerV3(creditManager).priceOracle()).priceFeeds(token) == address(0)) {
            revert PriceFeedDoesNotExistException(); // I:[CC-3]
        }

        CreditManagerV3(creditManager).addToken({token: token}); // I:[CC-4]

        if (_isQuotedToken(token)) {
            _makeTokenQuoted(token);
        }

        emit AddCollateralToken({token: token}); // I:[CC-4]
    }

    /// @notice Sets token's liquidation threshold
    /// @param token Token to set the LT for
    /// @param liquidationThreshold LT to set in bps
    /// @dev Reverts if `token` is underlying
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    /// @dev Reverts if `liquidationThreshold` is greater than underlying's LT
    function setLiquidationThreshold(address token, uint16 liquidationThreshold)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        _setLiquidationThreshold({token: token, liquidationThreshold: liquidationThreshold}); // I:[CC-5]
    }

    /// @dev `setLiquidationThreshold` implementation
    function _setLiquidationThreshold(address token, uint16 liquidationThreshold)
        internal
        nonUnderlyingTokenOnly(token)
    {
        (, uint16 ltUnderlying) =
            CreditManagerV3(creditManager).collateralTokenByMask({tokenMask: UNDERLYING_TOKEN_MASK});

        if (liquidationThreshold > ltUnderlying) {
            revert IncorrectLiquidationThresholdException(); // I:[CC-5]
        }

        CreditManagerV3(creditManager).setCollateralTokenData({
            token: token,
            ltInitial: liquidationThreshold,
            ltFinal: liquidationThreshold,
            timestampRampStart: type(uint40).max,
            rampDuration: 0
        }); // I:[CC-6]

        emit SetTokenLiquidationThreshold({token: token, liquidationThreshold: liquidationThreshold}); // I:[CC-6]
    }

    /// @notice Schedules token's liquidation threshold ramping
    /// @param token Token to ramp the LT for
    /// @param liquidationThresholdFinal Final LT after ramping in bps
    /// @param rampStart Timestamp to start the ramping at
    /// @param rampDuration Ramping duration
    /// @dev Reverts if `token` is underlying
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    /// @dev Reverts if `liquidationThresholdFinal` is greater than underlying's LT
    function rampLiquidationThreshold(
        address token,
        uint16 liquidationThresholdFinal,
        uint40 rampStart,
        uint24 rampDuration
    )
        external
        override
        nonUnderlyingTokenOnly(token)
        controllerOnly // I:[CC-2B]
    {
        (, uint16 ltUnderlying) =
            CreditManagerV3(creditManager).collateralTokenByMask({tokenMask: UNDERLYING_TOKEN_MASK});

        if (liquidationThresholdFinal > ltUnderlying) {
            revert IncorrectLiquidationThresholdException(); // I:[CC-30]
        }

        // if function is executed later than `rampStart`, start from `block.timestamp` to avoid LT jumps
        rampStart = block.timestamp > rampStart ? uint40(block.timestamp) : rampStart; // I:[CC-30]

        uint16 currentLT = CreditManagerV3(creditManager).liquidationThresholds({token: token}); // I:[CC-30]
        CreditManagerV3(creditManager).setCollateralTokenData({
            token: token,
            ltInitial: currentLT,
            ltFinal: liquidationThresholdFinal,
            timestampRampStart: rampStart,
            rampDuration: rampDuration
        }); // I:[CC-30]

        emit ScheduleTokenLiquidationThresholdRamp({
            token: token,
            liquidationThresholdInitial: currentLT,
            liquidationThresholdFinal: liquidationThresholdFinal,
            timestampRampStart: rampStart,
            timestampRampEnd: rampStart + rampDuration
        }); // I:[CC-30]
    }

    /// @notice Forbids collateral token in the credit facade
    /// @param token Token to forbid
    /// @dev Reverts if `token` is underlying
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function forbidToken(address token)
        external
        override
        nonZeroAddress(token)
        nonUnderlyingTokenOnly(token)
        pausableAdminsOnly // I:[CC-2A]
    {
        _forbidToken({_creditFacade: creditFacade(), token: token});
    }

    /// @dev `forbidToken` implementation
    function _forbidToken(address _creditFacade, address token) internal {
        CreditFacadeV3 cf = CreditFacadeV3(_creditFacade);

        uint256 tokenMask = _getTokenMaskOrRevert({token: token}); // I:[CC-9]
        if (cf.forbiddenTokenMask() & tokenMask != 0) return; // I:[CC-9]

        cf.setTokenAllowance({token: token, allowance: AllowanceAction.FORBID}); // I:[CC-9]
        emit ForbidToken({token: token}); // I:[CC-9]
    }

    /// @notice Allows a previously forbidden collateral token in the credit facade
    /// @param token Token to allow
    /// @dev Reverts if `token` is underlying
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function allowToken(address token)
        external
        override
        nonZeroAddress(token)
        nonUnderlyingTokenOnly(token)
        configuratorOnly // I:[CC-2]
    {
        CreditFacadeV3 cf = CreditFacadeV3(creditFacade());

        uint256 tokenMask = _getTokenMaskOrRevert({token: token}); // I:[CC-7]
        if (cf.forbiddenTokenMask() & tokenMask == 0) return; // I:[CC-8]

        cf.setTokenAllowance({token: token, allowance: AllowanceAction.ALLOW}); // I:[CC-8]
        emit AllowToken({token: token}); // I:[CC-8]
    }

    /// @notice Makes token quoted
    /// @param token Token to make quoted
    /// @dev Reverts if `token` is not quoted in the quota keeper
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function makeTokenQuoted(address token)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        if (!_isQuotedToken(token)) {
            revert TokenIsNotQuotedException();
        }
        _makeTokenQuoted(token);
    }

    /// @dev `makeTokenQuoted` implementation
    function _makeTokenQuoted(address token) internal nonUnderlyingTokenOnly(token) {
        uint256 tokenMask = _getTokenMaskOrRevert({token: token});
        uint256 quotedTokensMask = CreditManagerV3(creditManager).quotedTokensMask();
        if (quotedTokensMask & tokenMask != 0) return;

        CreditManagerV3(creditManager).setQuotedMask(quotedTokensMask.enable(tokenMask));
        emit QuoteToken(token);
    }

    // -------- //
    // ADAPTERS //
    // -------- //

    /// @notice Returns all allowed adapters
    function allowedAdapters() external view override returns (address[] memory) {
        return allowedAdaptersSet.values();
    }

    /// @notice Allows a new adapter in the credit manager
    /// @notice If adapter's target contract already has an adapter in the credit manager, it is removed
    /// @param adapter Adapter to allow
    /// @dev Reverts if `adapter` is incompatible with the credit manager
    /// @dev Reverts if `adapter`'s target contract is not a contract
    /// @dev Reverts if `adapter` or its target contract is credit manager or credit facade
    function allowAdapter(address adapter)
        external
        override
        nonZeroAddress(adapter)
        configuratorOnly // I:[CC-2]
    {
        address targetContract = _getTargetContractOrRevert({adapter: adapter});
        if (!targetContract.isContract()) {
            revert AddressIsNotContractException(targetContract); // I:[CC-10A]
        }

        if (
            targetContract == creditManager || targetContract == creditFacade() || adapter == creditManager
                || adapter == creditFacade()
        ) revert TargetContractNotAllowedException(); // I:[CC-10C]

        address currentAdapter = CreditManagerV3(creditManager).contractToAdapter(targetContract);
        if (currentAdapter != address(0)) {
            CreditManagerV3(creditManager).setContractAllowance({adapter: currentAdapter, targetContract: address(0)}); // I:[CC-12]
            allowedAdaptersSet.remove(currentAdapter); // I:[CC-12]
        }

        CreditManagerV3(creditManager).setContractAllowance({adapter: adapter, targetContract: targetContract}); // I:[CC-11]

        allowedAdaptersSet.add(adapter); // I:[CC-11]

        emit AllowAdapter({targetContract: targetContract, adapter: adapter}); // I:[CC-11]
    }

    /// @notice Forbids both adapter and its target contract in the credit manager
    /// @param adapter Adapter to forbid
    /// @dev Reverts if `adapter` is incompatible with the credit manager
    /// @dev Reverts if `adapter` is not registered in the credit manager
    function forbidAdapter(address adapter)
        external
        override
        nonZeroAddress(adapter)
        controllerOnly // I:[CC-2B]
    {
        address targetContract = _getTargetContractOrRevert({adapter: adapter});
        if (CreditManagerV3(creditManager).adapterToContract(adapter) == address(0)) {
            revert AdapterIsNotRegisteredException(); // I:[CC-13]
        }

        CreditManagerV3(creditManager).setContractAllowance({adapter: adapter, targetContract: address(0)}); // I:[CC-14]
        CreditManagerV3(creditManager).setContractAllowance({adapter: address(0), targetContract: targetContract}); // I:[CC-14]

        allowedAdaptersSet.remove(adapter); // I:[CC-14]

        emit ForbidAdapter({targetContract: targetContract, adapter: adapter}); // I:[CC-14]
    }

    /// @dev Checks that adapter is compatible with credit manager and returns its target contract
    function _getTargetContractOrRevert(address adapter) internal view returns (address targetContract) {
        _revertIfContractIncompatible(adapter); // I:[CC-10,10B]

        try IAdapter(adapter).targetContract() returns (address tc) {
            targetContract = tc;
        } catch {
            revert IncompatibleContractException();
        }

        if (targetContract == address(0)) revert TargetContractNotAllowedException();
    }

    // -------------- //
    // CREDIT MANAGER //
    // -------------- //

    /// @notice Sets the maximum number of tokens enabled as collateral on a credit account
    /// @param newMaxEnabledTokens New maximum number of enabled tokens
    /// @dev Reverts if `newMaxEnabledTokens` is zero
    function setMaxEnabledTokens(uint8 newMaxEnabledTokens)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        CreditManagerV3 cm = CreditManagerV3(creditManager);

        if (newMaxEnabledTokens == 0) revert IncorrectParameterException(); // I:[CC-26]

        if (newMaxEnabledTokens == cm.maxEnabledTokens()) return;

        cm.setMaxEnabledTokens(newMaxEnabledTokens); // I:[CC-26]
        emit SetMaxEnabledTokens(newMaxEnabledTokens); // I:[CC-26]
    }

    /// @notice Sets new fees params in the credit manager (all fields in bps)
    /// @notice Sets underlying token's liquidation threshold to 1 - liquidation fee - liquidation premium and
    ///         upper-bounds all other tokens' LTs with this number, which interrupts ongoing LT rampings
    /// @param feeInterest Percentage of accrued interest taken by the protocol as profit
    /// @param feeLiquidation Percentage of liquidated account value taken by the protocol as profit
    /// @param liquidationPremium Percentage of liquidated account value that can be taken by liquidator
    /// @param feeLiquidationExpired Percentage of liquidated expired account value taken by the protocol as profit
    /// @param liquidationPremiumExpired Percentage of liquidated expired account value that can be taken by liquidator
    /// @dev Reverts if `feeInterest` is above 100%
    /// @dev Reverts if `liquidationPremium + feeLiquidation` is above 100%
    /// @dev Reverts if `liquidationPremiumExpired + feeLiquidationExpired` is above 100%
    function setFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationPremium,
        uint16 feeLiquidationExpired,
        uint16 liquidationPremiumExpired
    )
        external
        override
        configuratorOnly // I:[CC-2]
    {
        if (
            feeInterest >= PERCENTAGE_FACTOR || (liquidationPremium + feeLiquidation) >= PERCENTAGE_FACTOR
                || (liquidationPremiumExpired + feeLiquidationExpired) >= PERCENTAGE_FACTOR
        ) revert IncorrectParameterException(); // I:[CC-17]

        _setFees({
            feeInterest: feeInterest,
            feeLiquidation: feeLiquidation,
            liquidationDiscount: PERCENTAGE_FACTOR - liquidationPremium,
            feeLiquidationExpired: feeLiquidationExpired,
            liquidationDiscountExpired: PERCENTAGE_FACTOR - liquidationPremiumExpired
        });
    }

    /// @dev `setFees` implementation
    function _setFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationDiscount,
        uint16 feeLiquidationExpired,
        uint16 liquidationDiscountExpired
    ) internal {
        uint16 newLTUnderlying = uint16(liquidationDiscount - feeLiquidation); // I:[CC-18]
        (, uint16 ltUnderlying) =
            CreditManagerV3(creditManager).collateralTokenByMask({tokenMask: UNDERLYING_TOKEN_MASK});

        if (newLTUnderlying != ltUnderlying) {
            _updateUnderlyingLT(newLTUnderlying); // I:[CC-18]
            emit SetTokenLiquidationThreshold({token: underlying, liquidationThreshold: newLTUnderlying}); // I:[CC-1A,18]
        }

        (
            uint16 _feeInterestCurrent,
            uint16 _feeLiquidationCurrent,
            uint16 _liquidationDiscountCurrent,
            uint16 _feeLiquidationExpiredCurrent,
            uint16 _liquidationDiscountExpiredCurrent
        ) = CreditManagerV3(creditManager).fees();

        if (
            (feeInterest == _feeInterestCurrent) && (feeLiquidation == _feeLiquidationCurrent)
                && (liquidationDiscount == _liquidationDiscountCurrent)
                && (feeLiquidationExpired == _feeLiquidationExpiredCurrent)
                && (liquidationDiscountExpired == _liquidationDiscountExpiredCurrent)
        ) return;

        CreditManagerV3(creditManager).setFees({
            _feeInterest: feeInterest,
            _feeLiquidation: feeLiquidation,
            _liquidationDiscount: liquidationDiscount,
            _feeLiquidationExpired: feeLiquidationExpired,
            _liquidationDiscountExpired: liquidationDiscountExpired
        }); // I:[CC-19]

        emit UpdateFees({
            feeInterest: feeInterest,
            feeLiquidation: feeLiquidation,
            liquidationPremium: PERCENTAGE_FACTOR - liquidationDiscount,
            feeLiquidationExpired: feeLiquidationExpired,
            liquidationPremiumExpired: PERCENTAGE_FACTOR - liquidationDiscountExpired
        }); // I:[CC-1A,19]
    }

    /// @dev Updates underlying token's liquidation threshold
    function _updateUnderlyingLT(uint16 ltUnderlying) internal {
        CreditManagerV3(creditManager).setCollateralTokenData({
            token: underlying,
            ltInitial: ltUnderlying,
            ltFinal: ltUnderlying,
            timestampRampStart: type(uint40).max,
            rampDuration: 0
        }); // I:[CC-25]

        uint256 len = CreditManagerV3(creditManager).collateralTokensCount();
        unchecked {
            for (uint256 i = 1; i < len; ++i) {
                (address token, uint16 lt) = CreditManagerV3(creditManager).collateralTokenByMask({tokenMask: 1 << i});
                if (lt > ltUnderlying) {
                    _setLiquidationThreshold({token: token, liquidationThreshold: ltUnderlying}); // I:[CC-25]
                }
            }
        }
    }

    // -------- //
    // UPGRADES //
    // -------- //

    /// @notice Sets the new price oracle contract in the credit manager
    /// @param newVersion Version of the new price oracle to take from the address provider
    /// @dev Reverts if price oracle of given version is not found in the address provider
    function setPriceOracle(uint256 newVersion)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        address priceOracle = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_PRICE_ORACLE, newVersion); // I:[CC-21]

        if (priceOracle == CreditManagerV3(creditManager).priceOracle()) return;

        CreditManagerV3(creditManager).setPriceOracle(priceOracle); // I:[CC-21]
        emit SetPriceOracle(priceOracle); // I:[CC-21]
    }

    /// @notice Sets the new bot list contract in the credit facade
    /// @param newVersion Version of the new bot list to take from the address provider
    /// @dev Reverts if bot list of given version is not found in the address provider
    function setBotList(uint256 newVersion)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        address botList = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_BOT_LIST, newVersion); // I:[CC-33]
        _setBotList(creditFacade(), botList); // I:[CC-33]
    }

    /// @dev `setBotList` implementation
    function _setBotList(address _creditFacade, address botList) internal {
        CreditFacadeV3 cf = CreditFacadeV3(_creditFacade);
        if (botList == cf.botList()) return;
        cf.setBotList(botList); // I:[CC-33]
        emit SetBotList(botList); // I:[CC-33]
    }

    /// @notice Upgrades a facade connected to the credit manager
    /// @param newCreditFacade New credit facade
    /// @param migrateParams Whether to migrate old credit facade params
    /// @dev Reverts if `newCreditFacade` is incompatible with credit manager
    function setCreditFacade(address newCreditFacade, bool migrateParams)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        CreditFacadeV3 prevCreditFacade = CreditFacadeV3(creditFacade());
        if (newCreditFacade == address(prevCreditFacade)) return;

        _revertIfContractIncompatible(newCreditFacade); // I:[CC-20]

        CreditManagerV3(creditManager).setCreditFacade(newCreditFacade); // I:[CC-22]

        if (migrateParams) {
            _setMaxDebtPerBlockMultiplier(newCreditFacade, prevCreditFacade.maxDebtPerBlockMultiplier()); // I:[CC-22]

            (uint128 minDebt, uint128 maxDebt) = prevCreditFacade.debtLimits();
            _setLimits({_creditFacade: newCreditFacade, minDebt: minDebt, maxDebt: maxDebt}); // I:[CC-22]

            (, uint128 maxCumulativeLoss) = prevCreditFacade.lossParams();
            _setMaxCumulativeLoss(newCreditFacade, maxCumulativeLoss); // [CC-22]

            _migrateEmergencyLiquidators(newCreditFacade); // I:[CC-22C]

            _migrateForbiddenTokens(newCreditFacade, prevCreditFacade.forbiddenTokenMask()); // I:[CC-22C]

            if (prevCreditFacade.expirable() && CreditFacadeV3(newCreditFacade).expirable()) {
                _setExpirationDate(newCreditFacade, prevCreditFacade.expirationDate()); // I:[CC-22]
            }

            address botList = prevCreditFacade.botList();
            if (botList != address(0)) _setBotList(newCreditFacade, botList); // I:[CC-22A]
        } else {
            // emergency liquidators set must be cleared to keep it consistent between facade and configurator
            _clearEmergencyLiquidatorsSet(); // I:[CC-22C]
        }

        emit SetCreditFacade(newCreditFacade); // I:[CC-22]
    }

    /// @dev Migrate emergency liquidators to the new credit facade
    function _migrateEmergencyLiquidators(address _creditFacade) internal {
        uint256 len = emergencyLiquidatorsSet.length();
        unchecked {
            for (uint256 i; i < len; ++i) {
                _addEmergencyLiquidator(_creditFacade, emergencyLiquidatorsSet.at(i));
            }
        }
    }

    /// @dev Migrates forbidden tokens to the new credit facade
    function _migrateForbiddenTokens(address _creditFacade, uint256 forbiddenTokensMask) internal {
        unchecked {
            while (forbiddenTokensMask != 0) {
                uint256 mask = forbiddenTokensMask & uint256(-int256(forbiddenTokensMask));
                address token = CreditManagerV3(creditManager).getTokenByMask(mask);
                _forbidToken(_creditFacade, token);
                forbiddenTokensMask ^= mask;
            }
        }
    }

    /// @dev Clears emergency liquidators set
    function _clearEmergencyLiquidatorsSet() internal {
        uint256 len = emergencyLiquidatorsSet.length();
        unchecked {
            for (uint256 i; i < len; ++i) {
                emergencyLiquidatorsSet.remove(emergencyLiquidatorsSet.at(len - i - 1));
            }
        }
    }

    /// @notice Upgrades credit manager's configurator contract
    /// @param newCreditConfigurator New credit configurator
    /// @dev Reverts if `newCreditConfigurator` is incompatible with credit manager
    function upgradeCreditConfigurator(address newCreditConfigurator)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        if (newCreditConfigurator == address(this)) return;

        _revertIfContractIncompatible(newCreditConfigurator); // I:[CC-20]
        CreditManagerV3(creditManager).setCreditConfigurator(newCreditConfigurator); // I:[CC-23]
        emit CreditConfiguratorUpgraded(newCreditConfigurator); // I:[CC-23]
    }

    // ------------- //
    // CREDIT FACADE //
    // ------------- //

    /// @notice Sets the new min debt limit in the credit facade
    /// @param minDebt New minimum debt per credit account
    /// @dev Reverts if `minDebt` is greater than the current max debt
    function setMinDebtLimit(uint128 minDebt) external override controllerOnly {
        address cf = creditFacade();
        (, uint128 currentMaxDebt) = CreditFacadeV3(cf).debtLimits();
        _setLimits(cf, minDebt, currentMaxDebt);
    }

    /// @notice Sets the new max debt limit in the credit facade
    /// @param maxDebt New maximum debt per credit account
    /// @dev Reverts if `maxDebt` is less than the current min debt
    function setMaxDebtLimit(uint128 maxDebt) external override controllerOnly {
        address cf = creditFacade();
        (uint128 currentMinDebt,) = CreditFacadeV3(cf).debtLimits();
        _setLimits(cf, currentMinDebt, maxDebt);
    }

    /// @dev `set{Min|Max}DebtLimit` implementation
    function _setLimits(address _creditFacade, uint128 minDebt, uint128 maxDebt) internal {
        if (minDebt > maxDebt) {
            revert IncorrectLimitsException(); // I:[CC-15]
        }

        CreditFacadeV3 cf = CreditFacadeV3(_creditFacade);

        (uint128 currentMinDebt, uint128 currentMaxDebt) = cf.debtLimits();
        if (currentMinDebt == minDebt && currentMaxDebt == maxDebt) return;

        cf.setDebtLimits(minDebt, maxDebt, cf.maxDebtPerBlockMultiplier()); // I:[CC-16]
        emit SetBorrowingLimits(minDebt, maxDebt); // I:[CC-1A,19]
    }

    /// @notice Sets the new max debt per block multiplier in the credit facade
    /// @param newMaxDebtLimitPerBlockMultiplier The new max debt per block multiplier
    function setMaxDebtPerBlockMultiplier(uint8 newMaxDebtLimitPerBlockMultiplier)
        external
        override
        controllerOnly // I:[CC-2B]
    {
        _setMaxDebtPerBlockMultiplier(creditFacade(), newMaxDebtLimitPerBlockMultiplier); // I:[CC-24]
    }

    /// @notice Disables borrowing in the credit facade by setting max debt per block multiplier to zero
    function forbidBorrowing()
        external
        override
        pausableAdminsOnly // I:[CC-2A]
    {
        _setMaxDebtPerBlockMultiplier(creditFacade(), 0); // I:[CC-24]
    }

    /// @dev `setMaxDebtPerBlockMultiplier` implementation
    function _setMaxDebtPerBlockMultiplier(address _creditFacade, uint8 newMaxDebtLimitPerBlockMultiplier) internal {
        CreditFacadeV3 cf = CreditFacadeV3(_creditFacade);

        if (newMaxDebtLimitPerBlockMultiplier == cf.maxDebtPerBlockMultiplier()) return;

        (uint128 minDebt, uint128 maxDebt) = cf.debtLimits();
        cf.setDebtLimits(minDebt, maxDebt, newMaxDebtLimitPerBlockMultiplier); // I:[CC-24]
        emit SetMaxDebtPerBlockMultiplier(newMaxDebtLimitPerBlockMultiplier); // I:[CC-1A,24]
    }

    /// @notice Sets the new maximum cumulative loss from bad debt liquidations
    /// @param newMaxCumulativeLoss New max cumulative lossd
    function setMaxCumulativeLoss(uint128 newMaxCumulativeLoss)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        _setMaxCumulativeLoss(creditFacade(), newMaxCumulativeLoss); // I:[CC-31]
    }

    /// @dev `setMaxCumulativeLoss` implementation
    function _setMaxCumulativeLoss(address _creditFacade, uint128 _maxCumulativeLoss) internal {
        CreditFacadeV3 cf = CreditFacadeV3(_creditFacade);

        (, uint128 maxCumulativeLossCurrent) = cf.lossParams(); // I:[CC-31]
        if (_maxCumulativeLoss == maxCumulativeLossCurrent) return;

        cf.setCumulativeLossParams(_maxCumulativeLoss, false); // I:[CC-31]
        emit SetMaxCumulativeLoss(_maxCumulativeLoss); // I:[CC-31]
    }

    /// @notice Resets the current cumulative loss from bad debt liquidations to zero
    function resetCumulativeLoss()
        external
        override
        configuratorOnly // I:[CC-2]
    {
        CreditFacadeV3 cf = CreditFacadeV3(creditFacade());
        (, uint128 maxCumulativeLossCurrent) = cf.lossParams(); // I:[CC-32]
        cf.setCumulativeLossParams(maxCumulativeLossCurrent, true); // I:[CC-32]
        emit ResetCumulativeLoss(); // I:[CC-32]
    }

    /// @notice Sets a new credit facade expiration timestamp
    /// @param newExpirationDate New expiration timestamp
    /// @dev Reverts if `newExpirationDate` is in the past
    /// @dev Reverts if `newExpirationDate` is older than the current expiration date
    /// @dev Reverts if credit facade is not expirable
    function setExpirationDate(uint40 newExpirationDate)
        external
        override
        controllerOnly // I:[CC-2B]
    {
        _setExpirationDate(creditFacade(), newExpirationDate); // I:[CC-25]
    }

    /// @dev `setExpirationDate` implementation
    function _setExpirationDate(address _creditFacade, uint40 newExpirationDate) internal {
        CreditFacadeV3 cf = CreditFacadeV3(_creditFacade);

        if (block.timestamp > newExpirationDate || cf.expirationDate() >= newExpirationDate) {
            revert IncorrectExpirationDateException(); // I:[CC-25]
        }

        cf.setExpirationDate(newExpirationDate); // I:[CC-25]
        emit SetExpirationDate(newExpirationDate); // I:[CC-25]
    }

    /// @notice Returns all emergency liquidators
    function emergencyLiquidators() external view override returns (address[] memory) {
        return emergencyLiquidatorsSet.values();
    }

    /// @notice Adds an address to the list of emergency liquidators
    /// @param liquidator Address to add to the list
    function addEmergencyLiquidator(address liquidator)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        _addEmergencyLiquidator(creditFacade(), liquidator); // I:[CC-27]
    }

    /// @dev `addEmergencyLiquidator` implementation
    function _addEmergencyLiquidator(address _creditFacade, address liquidator) internal {
        CreditFacadeV3 cf = CreditFacadeV3(_creditFacade);

        emergencyLiquidatorsSet.add(liquidator); // I:[CC-27]

        if (cf.canLiquidateWhilePaused(liquidator)) return;

        cf.setEmergencyLiquidator(liquidator, AllowanceAction.ALLOW); // I:[CC-27]
        emit AddEmergencyLiquidator(liquidator); // I:[CC-27]
    }

    /// @notice Removes an address from the list of emergency liquidators
    /// @param liquidator Address to remove from the list
    function removeEmergencyLiquidator(address liquidator)
        external
        override
        configuratorOnly // I:[CC-2]
    {
        CreditFacadeV3 cf = CreditFacadeV3(creditFacade());

        emergencyLiquidatorsSet.remove(liquidator); // I:[CC-28]

        if (!cf.canLiquidateWhilePaused(liquidator)) return;

        cf.setEmergencyLiquidator(liquidator, AllowanceAction.FORBID); // I:[CC-28]
        emit RemoveEmergencyLiquidator(liquidator); // I:[CC-28]
    }

    // --------- //
    // INTERNALS //
    // --------- //

    /// @dev Checks whether the quota keeper (if it is set) has a token registered as quoted
    function _isQuotedToken(address token) internal view returns (bool) {
        address quotaKeeper = CreditManagerV3(creditManager).poolQuotaKeeper();
        if (quotaKeeper == address(0)) return false;
        return IPoolQuotaKeeperV3(quotaKeeper).isQuotedToken(token);
    }

    /// @dev Internal wrapper for `creditManager.getTokenMaskOrRevert` call to reduce contract size
    function _getTokenMaskOrRevert(address token) internal view returns (uint256 tokenMask) {
        return CreditManagerV3(creditManager).getTokenMaskOrRevert(token); // I:[CC-7]
    }

    /// @dev Ensures that contract is compatible with credit manager by checking that it implements
    ///      the `creditManager()` function that returns the correct address
    function _revertIfContractIncompatible(address _contract)
        internal
        view
        nonZeroAddress(_contract) // I:[CC-12,29]
    {
        if (!_contract.isContract()) {
            revert AddressIsNotContractException(_contract); // I:[CC-12A,29]
        }

        // any interface with `creditManager()` would work instead of `CreditFacadeV3` here
        try CreditFacadeV3(_contract).creditManager() returns (address cm) {
            if (cm != creditManager) revert IncompatibleContractException(); // I:[CC-12B,29]
        } catch {
            revert IncompatibleContractException(); // I:[CC-12B,29]
        }
    }

    /// @dev Reverts if `token` is underlying
    function _revertIfUnderlyingToken(address token) internal view {
        if (token == underlying) revert TokenNotAllowedException();
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
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// Denominations

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;
uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 50%
uint16 constant DEFAULT_FEE_INTEREST = 50_00; // 50%

// LIQUIDATION_FEE 1.5%
uint16 constant DEFAULT_FEE_LIQUIDATION = 1_50; // 1.5%

// LIQUIDATION PREMIUM 4%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 4_00; // 4%

// LIQUIDATION_FEE_EXPIRED 2%
uint16 constant DEFAULT_FEE_LIQUIDATION_EXPIRED = 1_00; // 2%

// LIQUIDATION PREMIUM EXPIRED 2%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM_EXPIRED = 2_00; // 2%

// DEFAULT PROPORTION OF MAX BORROWED PER BLOCK TO MAX BORROWED PER ACCOUNT
uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Leverage decimals - 100 is equal to 2x leverage (100% * collateral amount + 100% * borrowed amount)
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in PERCENTAGE_FACTOR format
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IncorrectParameterException} from "../interfaces/IExceptions.sol";

uint256 constant UNDERLYING_TOKEN_MASK = 1;

/// @title Bit mask library
/// @notice Implements functions that manipulate bit masks
///         Bit masks are utilized extensively by Gearbox to efficiently store token sets (enabled tokens on accounts
///         or forbidden tokens) and check for set inclusion. A mask is a uint256 number that has its i-th bit set to
///         1 if i-th item is included into the set. For example, each token has a mask equal to 2**i, so set inclusion
///         can be checked by checking tokenMask & setMask != 0.
library BitMask {
    /// @dev Calculates an index of an item based on its mask (using a binary search)
    /// @dev The input should always have only 1 bit set, otherwise the result may be unpredictable
    function calcIndex(uint256 mask) internal pure returns (uint8 index) {
        if (mask == 0) revert IncorrectParameterException(); // U:[BM-1]
        uint16 lb = 0; // U:[BM-2]
        uint16 ub = 256; // U:[BM-2]
        uint16 mid = 128; // U:[BM-2]

        unchecked {
            while (true) {
                uint256 newMask = 1 << mid;
                if (newMask & mask != 0) return uint8(mid); // U:[BM-2]

                if (newMask > mask) ub = mid; // U:[BM-2]

                else lb = mid; // U:[BM-2]
                mid = (lb + ub) >> 1; // U:[BM-2]
            }
        }
    }

    /// @dev Calculates the number of `1` bits
    /// @param enabledTokensMask Bit mask to compute the number of `1` bits in
    function calcEnabledTokens(uint256 enabledTokensMask) internal pure returns (uint256 totalTokensEnabled) {
        unchecked {
            while (enabledTokensMask > 0) {
                enabledTokensMask &= enabledTokensMask - 1; // U:[BM-3]
                ++totalTokensEnabled; // U:[BM-3]
            }
        }
    }

    /// @dev Enables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToEnable Mask of bits to enable
    function enable(uint256 enabledTokenMask, uint256 bitsToEnable) internal pure returns (uint256) {
        return enabledTokenMask | bitsToEnable; // U:[BM-4]
    }

    /// @dev Disables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToDisable Mask of bits to disable
    function disable(uint256 enabledTokenMask, uint256 bitsToDisable) internal pure returns (uint256) {
        return enabledTokenMask & ~bitsToDisable; // U:[BM-4]
    }

    /// @dev Computes a new mask with sets of new enabled and disabled bits
    /// @dev bitsToEnable and bitsToDisable are applied sequentially to original mask
    /// @param enabledTokensMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param bitsToDisable Mask with bits to disable
    function enableDisable(uint256 enabledTokensMask, uint256 bitsToEnable, uint256 bitsToDisable)
        internal
        pure
        returns (uint256)
    {
        return (enabledTokensMask | bitsToEnable) & (~bitsToDisable); // U:[BM-5]
    }

    /// @dev Enables bits from the second mask in the first mask, skipping specified bits
    /// @param enabledTokenMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function enable(uint256 enabledTokenMask, uint256 bitsToEnable, uint256 invertedSkipMask)
        internal
        pure
        returns (uint256)
    {
        return enabledTokenMask | (bitsToEnable & invertedSkipMask); // U:[BM-6]
    }

    /// @dev Disables bits from the second mask in the first mask, skipping specified bits
    /// @param enabledTokenMask The initial mask
    /// @param bitsToDisable Mask with bits to disable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function disable(uint256 enabledTokenMask, uint256 bitsToDisable, uint256 invertedSkipMask)
        internal
        pure
        returns (uint256)
    {
        return enabledTokenMask & (~(bitsToDisable & invertedSkipMask)); // U:[BM-6]
    }

    /// @dev Computes a new mask with sets of new enabled and disabled bits, skipping some bits
    /// @dev bitsToEnable and bitsToDisable are applied sequentially to original mask. Skipmask is applied in both cases.
    /// @param enabledTokensMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param bitsToDisable Mask with bits to disable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function enableDisable(
        uint256 enabledTokensMask,
        uint256 bitsToEnable,
        uint256 bitsToDisable,
        uint256 invertedSkipMask
    ) internal pure returns (uint256) {
        return (enabledTokensMask | (bitsToEnable & invertedSkipMask)) & (~(bitsToDisable & invertedSkipMask)); // U:[BM-7]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";
import {
    CallerNotControllerException,
    CallerNotPausableAdminException,
    CallerNotUnpausableAdminException
} from "../interfaces/IExceptions.sol";

import {ACLTrait} from "./ACLTrait.sol";
import {ReentrancyGuardTrait} from "./ReentrancyGuardTrait.sol";

/// @title ACL non-reentrant trait
/// @notice Extended version of `ACLTrait` that implements pausable functionality,
///         reentrancy protection and external controller role
abstract contract ACLNonReentrantTrait is ACLTrait, Pausable, ReentrancyGuardTrait {
    /// @notice Emitted when new external controller is set
    event NewController(address indexed newController);

    /// @notice External controller address
    address public controller;

    /// @dev Ensures that function caller is external controller or configurator
    modifier controllerOnly() {
        _ensureCallerIsControllerOrConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not controller or configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsControllerOrConfigurator() internal view {
        if (msg.sender != controller && !_isConfigurator({account: msg.sender})) {
            revert CallerNotControllerException();
        }
    }

    /// @dev Ensures that function caller has pausable admin role
    modifier pausableAdminsOnly() {
        _ensureCallerIsPausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not pausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsPausableAdmin() internal view {
        if (!_isPausableAdmin({account: msg.sender})) {
            revert CallerNotPausableAdminException();
        }
    }

    /// @dev Ensures that function caller has unpausable admin role
    modifier unpausableAdminsOnly() {
        _ensureCallerIsUnpausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not unpausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsUnpausableAdmin() internal view {
        if (!_isUnpausableAdmin({account: msg.sender})) {
            revert CallerNotUnpausableAdminException();
        }
    }

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) ACLTrait(addressProvider) {
        controller = IACL(acl).owner();
    }

    /// @notice Pauses contract, can only be called by an account with pausable admin role
    function pause() external virtual pausableAdminsOnly {
        _pause();
    }

    /// @notice Unpauses contract, can only be called by an account with unpausable admin role
    function unpause() external virtual unpausableAdminsOnly {
        _unpause();
    }

    /// @notice Sets new external controller, can only be called by configurator
    function setController(address newController) external configuratorOnly {
        if (controller == newController) return;
        controller = newController;
        emit NewController(newController);
    }

    /// @dev Checks whether given account has pausable admin role
    function _isPausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isPausableAdmin(account);
    }

    /// @dev Checks whether given account has unpausable admin role
    function _isUnpausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isUnpausableAdmin(account);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// THIRD-PARTY
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

// LIBS & TRAITS
import {BalancesLogic, Balance, BalanceDelta, BalanceWithMask, Comparison} from "../libraries/BalancesLogic.sol";
import {ACLNonReentrantTrait} from "../traits/ACLNonReentrantTrait.sol";
import {BitMask, UNDERLYING_TOKEN_MASK} from "../libraries/BitMask.sol";

// INTERFACES
import "../interfaces/ICreditFacadeV3.sol";
import "../interfaces/IAddressProviderV3.sol";
import {
    ICreditManagerV3,
    ManageDebtAction,
    RevocationPair,
    CollateralDebtData,
    CollateralCalcTask,
    BOT_PERMISSIONS_SET_FLAG,
    INACTIVE_CREDIT_ACCOUNT_ADDRESS
} from "../interfaces/ICreditManagerV3.sol";
import {AllowanceAction} from "../interfaces/ICreditConfiguratorV3.sol";
import {IPriceOracleV3} from "../interfaces/IPriceOracleV3.sol";
import {IUpdatablePriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";

import {IPoolV3} from "../interfaces/IPoolV3.sol";
import {IDegenNFTV2} from "@gearbox-protocol/core-v2/contracts/interfaces/IDegenNFTV2.sol";
import {IWETH} from "@gearbox-protocol/core-v2/contracts/interfaces/external/IWETH.sol";
import {IBotListV3} from "../interfaces/IBotListV3.sol";

// CONSTANTS
import {PERCENTAGE_FACTOR} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

// EXCEPTIONS
import "../interfaces/IExceptions.sol";

uint256 constant OPEN_CREDIT_ACCOUNT_FLAGS = ALL_PERMISSIONS & ~DECREASE_DEBT_PERMISSION;

uint256 constant CLOSE_CREDIT_ACCOUNT_FLAGS = ALL_PERMISSIONS & ~INCREASE_DEBT_PERMISSION;

uint256 constant LIQUIDATE_CREDIT_ACCOUNT_FLAGS =
    EXTERNAL_CALLS_PERMISSION | ADD_COLLATERAL_PERMISSION | WITHDRAW_COLLATERAL_PERMISSION;

/// @title Credit facade V3
/// @notice Provides a user interface to open, close and liquidate leveraged positions in the credit manager,
///         and implements the main entry-point for credit accounts management: multicall.
/// @notice Multicall allows account owners to batch all the desired operations (adding or withdrawing collateral,
///         changing debt size, interacting with external protocols via adapters or increasing quotas) into one call,
///         followed by the collateral check that ensures that account is sufficiently collateralized.
///         For more details on what one can achieve with multicalls, see `_multicall` and  `ICreditFacadeV3Multicall`.
/// @notice Users can also let external bots manage their accounts via `botMulticall`. Bots can be relatively general,
///         the facade only ensures that they can do no harm to the protocol by running the collateral check after the
///         multicall and checking the permissions given to them by users. See `BotListV3` for additional details.
/// @notice Credit facade implements a few safeguards on top of those present in the credit manager, including debt and
///         quota size validation, pausing on large protocol losses, Degen NFT whitelist mode, and forbidden tokens
///         (they count towards account value, but having them enabled as collateral restricts available actions and
///         activates a safer version of collateral check).
contract CreditFacadeV3 is ICreditFacadeV3, ACLNonReentrantTrait {
    using Address for address;
    using Address for address payable;
    using BitMask for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /// @notice Contract version
    uint256 public constant override version = 3_01;

    /// @notice Maximum quota size, as a multiple of `maxDebt`
    uint256 public constant override maxQuotaMultiplier = 2;

    /// @notice Credit manager connected to this credit facade
    address public immutable override creditManager;

    /// @notice Whether credit facade is expirable
    bool public immutable override expirable;

    /// @notice WETH token address
    address public immutable override weth;

    /// @notice Degen NFT address
    address public immutable override degenNFT;

    /// @notice Expiration timestamp
    uint40 public override expirationDate;

    /// @notice Maximum amount that can be borrowed by a credit manager in a single block, as a multiple of `maxDebt`
    uint8 public override maxDebtPerBlockMultiplier;

    /// @notice Last block when underlying was borrowed by a credit manager
    uint64 internal lastBlockBorrowed;

    /// @notice The total amount borrowed by a credit manager in `lastBlockBorrowed`
    uint128 internal totalBorrowedInBlock;

    /// @notice Bot list address
    address public override botList;

    /// @notice Credit account debt limits packed into a single slot
    DebtLimits public override debtLimits;

    /// @notice Bit mask encoding a set of forbidden tokens
    uint256 public override forbiddenTokenMask;

    /// @notice Info on bad debt liquidation losses packed into a single slot
    CumulativeLossParams public override lossParams;

    /// @notice Mapping account => emergency liquidator status
    mapping(address => bool) public override canLiquidateWhilePaused;

    /// @dev Ensures that function caller is credit configurator
    modifier creditConfiguratorOnly() {
        _checkCreditConfigurator();
        _;
    }

    /// @dev Ensures that function caller is `creditAccount`'s owner
    modifier creditAccountOwnerOnly(address creditAccount) {
        _checkCreditAccountOwner(creditAccount);
        _;
    }

    /// @dev Ensures that function can't be called when the contract is paused, unless caller is an emergency liquidator
    modifier whenNotPausedOrEmergency() {
        require(!paused() || canLiquidateWhilePaused[msg.sender], "Pausable: paused");
        _;
    }

    /// @dev Ensures that function can't be called when the contract is expired
    modifier whenNotExpired() {
        _checkExpired();
        _;
    }

    /// @dev Wraps any ETH sent in a function call and sends it back to the caller
    modifier wrapETH() {
        _wrapETH();
        _;
    }

    /// @notice Constructor
    /// @param _creditManager Credit manager to connect this facade to
    /// @param _degenNFT Degen NFT address or `address(0)`
    /// @param _expirable Whether this facade should be expirable
    constructor(address _creditManager, address _degenNFT, bool _expirable)
        ACLNonReentrantTrait(ICreditManagerV3(_creditManager).addressProvider())
    {
        creditManager = _creditManager; // U:[FA-1]

        address addressProvider = ICreditManagerV3(_creditManager).addressProvider();
        weth = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_WETH_TOKEN, NO_VERSION_CONTROL); // U:[FA-1]
        botList = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_BOT_LIST, 3_00); // U:[FA-1]

        degenNFT = _degenNFT; // U:[FA-1]

        expirable = _expirable; // U:[FA-1]
    }

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    /// @notice Opens a new credit account
    ///         - Wraps any ETH sent in the function call and sends it back to the caller
    ///         - If Degen NFT is enabled, burns one from the caller
    ///         - Opens an account in the credit manager
    ///         - Performs a multicall (all calls allowed except debt decrease and withdrawals)
    ///         - Runs the collateral check
    /// @param onBehalfOf Address on whose behalf to open the account
    /// @param calls List of calls to perform after opening the account
    /// @param referralCode Referral code to use for potential rewards, 0 if no referral code is provided
    /// @return creditAccount Address of the newly opened account
    /// @dev Reverts if credit facade is paused or expired
    /// @dev Reverts if `onBehalfOf` is not caller while Degen NFT is enabled
    function openCreditAccount(address onBehalfOf, MultiCall[] calldata calls, uint256 referralCode)
        external
        payable
        override
        whenNotPaused // U:[FA-2]
        whenNotExpired // U:[FA-3]
        nonReentrant // U:[FA-4]
        wrapETH // U:[FA-7]
        returns (address creditAccount)
    {
        if (degenNFT != address(0)) {
            if (msg.sender != onBehalfOf) {
                revert ForbiddenInWhitelistedModeException(); // U:[FA-9]
            }
            IDegenNFTV2(degenNFT).burn(onBehalfOf, 1); // U:[FA-9]
        }

        creditAccount = ICreditManagerV3(creditManager).openCreditAccount({onBehalfOf: onBehalfOf}); // U:[FA-10]

        emit OpenCreditAccount(creditAccount, onBehalfOf, msg.sender, referralCode); // U:[FA-10]

        if (calls.length != 0) {
            // same as `_multicallFullCollateralCheck` but leverages the fact that account is freshly opened to save gas
            BalanceWithMask[] memory forbiddenBalances;

            uint256 skipCalls = _applyOnDemandPriceUpdates(calls);
            FullCheckParams memory fullCheckParams = _multicall({
                creditAccount: creditAccount,
                calls: calls,
                enabledTokensMask: 0,
                flags: OPEN_CREDIT_ACCOUNT_FLAGS,
                skip: skipCalls
            }); // U:[FA-10]

            _fullCollateralCheck({
                creditAccount: creditAccount,
                enabledTokensMaskBefore: 0,
                fullCheckParams: fullCheckParams,
                forbiddenBalances: forbiddenBalances,
                forbiddenTokensMask: forbiddenTokenMask
            }); // U:[FA-10]
        }
    }

    /// @notice Closes a credit account
    ///         - Wraps any ETH sent in the function call and sends it back to the caller
    ///         - Performs a multicall (all calls are allowed except debt increase)
    ///         - Closes a credit account in the credit manager
    ///         - Erases all bots permissions
    /// @param creditAccount Account to close
    /// @param calls List of calls to perform before closing the account
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager by caller
    /// @dev Reverts if facade is paused
    /// @dev Reverts if account has enabled tokens after executing `calls`
    /// @dev Reverts if account's debt is not zero after executing `calls`
    function closeCreditAccount(address creditAccount, MultiCall[] calldata calls)
        external
        payable
        override
        creditAccountOwnerOnly(creditAccount) // U:[FA-5]
        whenNotPaused // U:[FA-2]
        nonReentrant // U:[FA-4]
        wrapETH // U:[FA-7]
    {
        uint256 enabledTokensMask = _enabledTokensMaskOf(creditAccount);

        if (calls.length != 0) {
            FullCheckParams memory fullCheckParams =
                _multicall(creditAccount, calls, enabledTokensMask, CLOSE_CREDIT_ACCOUNT_FLAGS, 0); // U:[FA-11]
            enabledTokensMask = fullCheckParams.enabledTokensMaskAfter;
        }

        if (enabledTokensMask != 0) revert CloseAccountWithEnabledTokensException(); // U:[FA-11]

        if (_flagsOf(creditAccount) & BOT_PERMISSIONS_SET_FLAG != 0) {
            IBotListV3(botList).eraseAllBotPermissions(creditManager, creditAccount); // U:[FA-11]
        }

        ICreditManagerV3(creditManager).closeCreditAccount(creditAccount); // U:[FA-11]

        emit CloseCreditAccount(creditAccount, msg.sender); // U:[FA-11]
    }

    /// @notice Liquidates a credit account
    ///         - Updates price feeds before running all computations if such calls are present in the multicall
    ///         - Evaluates account's collateral and debt to determine whether liquidated account is unhealthy or expired
    ///         - Performs a multicall (only `addCollateral`, `withdrawCollateral` and adapter calls are allowed)
    ///         - Liquidates a credit account in the credit manager, which repays debt to the pool, removes quotas, and
    ///           transfers underlying to the liquidator
    ///         - If pool incurs a loss on liquidation, further borrowing through the facade is forbidden
    ///         - If cumulative loss from bad debt liquidations exceeds the threshold, the facade is paused
    /// @notice The function computes account’s total value (oracle value of enabled tokens), discounts it by liquidator’s
    ///         premium, and uses this value to compute funds due to the pool and owner.
    ///         Debt to the pool must be repaid in underlying, while funds due to owner might be covered by underlying
    ///         as well as by tokens that counted towards total value calculation, with the only condition that balance
    ///         of such tokens can’t be increased in the multicall.
    ///         Typically, a liquidator would swap all holdings on the account to underlying via multicall and receive
    ///         the premium in underlying.
    ///         An alternative strategy would be to add underlying collateral to repay debt and withdraw desired tokens
    ///         to handle them in another way, while remaining tokens would cover funds due to owner.
    /// @param creditAccount Account to liquidate
    /// @param to Address to transfer underlying left after liquidation
    /// @param calls List of calls to perform before liquidating the account
    /// @dev When the credit facade is paused, reverts if caller is not an approved emergency liquidator
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager
    /// @dev Reverts if account has no debt or is neither unhealthy nor expired
    /// @dev Reverts if remaining token balances increase during the multicall
    function liquidateCreditAccount(address creditAccount, address to, MultiCall[] calldata calls)
        external
        override
        whenNotPausedOrEmergency // U:[FA-2,12]
        nonReentrant // U:[FA-4]
    {
        uint256 skipCalls = _applyOnDemandPriceUpdates(calls);

        CollateralDebtData memory collateralDebtData =
            ICreditManagerV3(creditManager).calcDebtAndCollateral(creditAccount, CollateralCalcTask.DEBT_COLLATERAL); // U:[FA-16]

        bool isUnhealthy = collateralDebtData.twvUSD < collateralDebtData.totalDebtUSD;
        if (collateralDebtData.debt == 0 || !isUnhealthy && !_isExpired()) {
            revert CreditAccountNotLiquidatableException(); // U:[FA-13]
        }

        collateralDebtData.enabledTokensMask = collateralDebtData.enabledTokensMask.disable(UNDERLYING_TOKEN_MASK); // U:[FA-14]

        BalanceWithMask[] memory initialBalances = BalancesLogic.storeBalances({
            creditAccount: creditAccount,
            tokensMask: collateralDebtData.enabledTokensMask,
            getTokenByMaskFn: _getTokenByMask
        });

        FullCheckParams memory fullCheckParams = _multicall(
            creditAccount, calls, collateralDebtData.enabledTokensMask, LIQUIDATE_CREDIT_ACCOUNT_FLAGS, skipCalls
        ); // U:[FA-16]
        collateralDebtData.enabledTokensMask &= fullCheckParams.enabledTokensMaskAfter; // U:[FA-16]

        bool success = BalancesLogic.compareBalances({
            creditAccount: creditAccount,
            tokensMask: collateralDebtData.enabledTokensMask,
            balances: initialBalances,
            comparison: Comparison.LESS
        });
        if (!success) revert RemainingTokenBalanceIncreasedException(); // U:[FA-14]

        collateralDebtData.enabledTokensMask = collateralDebtData.enabledTokensMask.enable(UNDERLYING_TOKEN_MASK); // U:[FA-16]

        (uint256 remainingFunds, uint256 reportedLoss) = ICreditManagerV3(creditManager).liquidateCreditAccount({
            creditAccount: creditAccount,
            collateralDebtData: collateralDebtData,
            to: to,
            isExpired: !isUnhealthy
        }); // U:[FA-15,16]

        emit LiquidateCreditAccount(creditAccount, msg.sender, to, remainingFunds); // U:[FA-16]

        if (reportedLoss != 0) {
            maxDebtPerBlockMultiplier = 0; // U:[FA-17]

            // both cast and addition are safe because amounts are of much smaller scale
            lossParams.currentCumulativeLoss += uint128(reportedLoss); // U:[FA-17]

            // can't pause an already paused contract
            if (!paused() && lossParams.currentCumulativeLoss > lossParams.maxCumulativeLoss) {
                _pause(); // U:[FA-17]
            }
        }
    }

    /// @notice Executes a batch of calls allowing user to manage their credit account
    ///         - Wraps any ETH sent in the function call and sends it back to the caller
    ///         - Performs a multicall (all calls are allowed)
    ///         - Runs the collateral check
    /// @param creditAccount Account to perform the calls on
    /// @param calls List of calls to perform
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager by caller
    /// @dev Reverts if credit facade is paused or expired
    function multicall(address creditAccount, MultiCall[] calldata calls)
        external
        payable
        override
        creditAccountOwnerOnly(creditAccount) // U:[FA-5]
        whenNotPaused // U:[FA-2]
        whenNotExpired // U:[FA-3]
        nonReentrant // U:[FA-4]
        wrapETH // U:[FA-7]
    {
        _multicallFullCollateralCheck(creditAccount, calls, ALL_PERMISSIONS); // U:[FA-18]
    }

    /// @notice Executes a batch of calls allowing bot to manage a credit account
    ///         - Performs a multicall (allowed calls are determined by permissions given by account's owner
    ///           or by DAO in case bot has special permissions in the credit manager)
    ///         - Runs the collateral check
    /// @param creditAccount Account to perform the calls on
    /// @param calls List of calls to perform
    /// @dev Reverts if credit facade is paused or expired
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager
    /// @dev Reverts if calling bot is forbidden or has no permissions to manage `creditAccount`
    function botMulticall(address creditAccount, MultiCall[] calldata calls)
        external
        override
        whenNotPaused // U:[FA-2]
        whenNotExpired // U:[FA-3]
        nonReentrant // U:[FA-4]
    {
        _getBorrowerOrRevert(creditAccount); // U:[FA-5]

        (uint256 botPermissions, bool forbidden, bool hasSpecialPermissions) = IBotListV3(botList).getBotStatus({
            bot: msg.sender,
            creditManager: creditManager,
            creditAccount: creditAccount
        });

        if (
            botPermissions == 0 || forbidden
                || (!hasSpecialPermissions && (_flagsOf(creditAccount) & BOT_PERMISSIONS_SET_FLAG == 0))
        ) {
            revert NotApprovedBotException(); // U:[FA-19]
        }

        _multicallFullCollateralCheck(creditAccount, calls, botPermissions); // U:[FA-19, 20]
    }

    /// @notice Sets `bot`'s permissions to manage `creditAccount`
    /// @param creditAccount Account to set permissions for
    /// @param bot Bot to set permissions for
    /// @param permissions A bit mask encoding bot permissions
    /// @dev Reverts if `creditAccount` is not opened in connected credit manager by caller
    /// @dev Reverts if `permissions` has unexpected bits enabled
    /// @dev Reverts if account has more active bots than allowed after changing permissions
    /// @dev Changes account's `BOT_PERMISSIONS_SET_FLAG` in the credit manager if needed
    function setBotPermissions(address creditAccount, address bot, uint192 permissions)
        external
        override
        creditAccountOwnerOnly(creditAccount) // U:[FA-5]
        nonReentrant // U:[FA-4]
    {
        if (permissions & ~ALL_PERMISSIONS != 0) revert UnexpectedPermissionsException(); // U:[FA-41]

        uint256 remainingBots = IBotListV3(botList).setBotPermissions({
            bot: bot,
            creditManager: creditManager,
            creditAccount: creditAccount,
            permissions: permissions
        }); // U:[FA-41]

        if (remainingBots == 0) {
            _setFlagFor({creditAccount: creditAccount, flag: BOT_PERMISSIONS_SET_FLAG, value: false}); // U:[FA-41]
        } else if (_flagsOf(creditAccount) & BOT_PERMISSIONS_SET_FLAG == 0) {
            _setFlagFor({creditAccount: creditAccount, flag: BOT_PERMISSIONS_SET_FLAG, value: true}); // U:[FA-41]
        }
    }

    // --------- //
    // MULTICALL //
    // --------- //

    /// @dev Batches price feed updates, multicall and collateral check into a single function
    function _multicallFullCollateralCheck(address creditAccount, MultiCall[] calldata calls, uint256 flags) internal {
        uint256 forbiddenTokensMask = forbiddenTokenMask;
        uint256 enabledTokensMaskBefore = _enabledTokensMaskOf(creditAccount); // U:[FA-18]
        BalanceWithMask[] memory forbiddenBalances = BalancesLogic.storeBalances({
            creditAccount: creditAccount,
            tokensMask: forbiddenTokensMask & enabledTokensMaskBefore,
            getTokenByMaskFn: _getTokenByMask
        });

        uint256 skipCalls = _applyOnDemandPriceUpdates(calls);
        FullCheckParams memory fullCheckParams = _multicall(
            creditAccount,
            calls,
            enabledTokensMaskBefore,
            forbiddenBalances.length != 0 ? flags.enable(FORBIDDEN_TOKENS_BEFORE_CALLS) : flags,
            skipCalls
        );

        _fullCollateralCheck({
            creditAccount: creditAccount,
            enabledTokensMaskBefore: enabledTokensMaskBefore,
            fullCheckParams: fullCheckParams,
            forbiddenBalances: forbiddenBalances,
            forbiddenTokensMask: forbiddenTokensMask
        }); // U:[FA-18]
    }

    /// @dev Multicall implementation
    /// @param creditAccount Account to perform actions with
    /// @param calls Array of `(target, callData)` tuples representing a sequence of calls to perform
    ///        - if `target` is this contract's address, `callData` must be an ABI-encoded calldata of a method
    ///          from `ICreditFacadeV3Multicall`, which is dispatched and handled appropriately
    ///        - otherwise, `target` must be an allowed adapter, which is called with `callData`, and is expected to
    ///          return two ABI-encoded `uint256` masks of tokens that should be enabled/disabled after the call
    /// @param enabledTokensMask Bitmask of account's enabled collateral tokens before the multicall
    /// @param flags Permissions and flags that dictate what methods can be called
    /// @param skip The number of calls that can be skipped (see `_applyOnDemandPriceUpdates`)
    /// @return fullCheckParams Collateral check parameters, see `FullCheckParams` for details
    function _multicall(
        address creditAccount,
        MultiCall[] calldata calls,
        uint256 enabledTokensMask,
        uint256 flags,
        uint256 skip
    ) internal returns (FullCheckParams memory fullCheckParams) {
        emit StartMultiCall({creditAccount: creditAccount, caller: msg.sender}); // U:[FA-18]

        uint256 quotedTokensMaskInverted;
        Balance[] memory expectedBalances;
        fullCheckParams.minHealthFactor = PERCENTAGE_FACTOR;

        unchecked {
            uint256 len = calls.length;
            for (uint256 i = skip; i < len; ++i) {
                MultiCall calldata mcall = calls[i];

                // credit facade calls
                if (mcall.target == address(this)) {
                    bytes4 method = bytes4(mcall.callData);

                    // storeExpectedBalances
                    if (method == ICreditFacadeV3Multicall.storeExpectedBalances.selector) {
                        if (expectedBalances.length != 0) revert ExpectedBalancesAlreadySetException(); // U:[FA-23]

                        BalanceDelta[] memory balanceDeltas = abi.decode(mcall.callData[4:], (BalanceDelta[])); // U:[FA-23]
                        expectedBalances = BalancesLogic.storeBalances(creditAccount, balanceDeltas); // U:[FA-23]
                    }
                    // compareBalances
                    else if (method == ICreditFacadeV3Multicall.compareBalances.selector) {
                        if (expectedBalances.length == 0) revert ExpectedBalancesNotSetException(); // U:[FA-23]

                        if (!BalancesLogic.compareBalances(creditAccount, expectedBalances, Comparison.GREATER)) {
                            revert BalanceLessThanExpectedException(); // U:[FA-23]
                        }
                        expectedBalances = new Balance[](0); // U:[FA-23]
                    }
                    // addCollateral
                    else if (method == ICreditFacadeV3Multicall.addCollateral.selector) {
                        _revertIfNoPermission(flags, ADD_COLLATERAL_PERMISSION); // U:[FA-21]

                        quotedTokensMaskInverted = _quotedTokensMaskInvertedLoE(quotedTokensMaskInverted);

                        enabledTokensMask = enabledTokensMask.enable({
                            bitsToEnable: _addCollateral(creditAccount, mcall.callData[4:]),
                            invertedSkipMask: quotedTokensMaskInverted
                        }); // U:[FA-26]
                    }
                    // addCollateralWithPermit
                    else if (method == ICreditFacadeV3Multicall.addCollateralWithPermit.selector) {
                        _revertIfNoPermission(flags, ADD_COLLATERAL_PERMISSION); // U:[FA-21]

                        quotedTokensMaskInverted = _quotedTokensMaskInvertedLoE(quotedTokensMaskInverted);

                        enabledTokensMask = enabledTokensMask.enable({
                            bitsToEnable: _addCollateralWithPermit(creditAccount, mcall.callData[4:]),
                            invertedSkipMask: quotedTokensMaskInverted
                        }); // U:[FA-26B]
                    }
                    // updateQuota
                    else if (method == ICreditFacadeV3Multicall.updateQuota.selector) {
                        _revertIfNoPermission(flags, UPDATE_QUOTA_PERMISSION); // U:[FA-21]

                        (uint256 tokensToEnable, uint256 tokensToDisable) =
                            _updateQuota(creditAccount, mcall.callData[4:], flags & FORBIDDEN_TOKENS_BEFORE_CALLS != 0); // U:[FA-34]
                        enabledTokensMask = enabledTokensMask.enableDisable(tokensToEnable, tokensToDisable); // U:[FA-34]
                    }
                    // withdrawCollateral
                    else if (method == ICreditFacadeV3Multicall.withdrawCollateral.selector) {
                        _revertIfNoPermission(flags, WITHDRAW_COLLATERAL_PERMISSION); // U:[FA-21]

                        fullCheckParams.revertOnForbiddenTokens = true; // U:[FA-30]
                        fullCheckParams.useSafePrices = true;

                        uint256 tokensToDisable = _withdrawCollateral(creditAccount, mcall.callData[4:]); // U:[FA-34]

                        quotedTokensMaskInverted = _quotedTokensMaskInvertedLoE(quotedTokensMaskInverted);

                        enabledTokensMask = enabledTokensMask.disable({
                            bitsToDisable: tokensToDisable,
                            invertedSkipMask: quotedTokensMaskInverted
                        }); // U:[FA-35]
                    }
                    // increaseDebt
                    else if (method == ICreditFacadeV3Multicall.increaseDebt.selector) {
                        _revertIfNoPermission(flags, INCREASE_DEBT_PERMISSION); // U:[FA-21]

                        fullCheckParams.revertOnForbiddenTokens = true; // U:[FA-30]

                        (uint256 tokensToEnable,) = _manageDebt(
                            creditAccount, mcall.callData[4:], enabledTokensMask, ManageDebtAction.INCREASE_DEBT
                        ); // U:[FA-27]
                        enabledTokensMask = enabledTokensMask.enable(tokensToEnable); // U:[FA-27]
                    }
                    // decreaseDebt
                    else if (method == ICreditFacadeV3Multicall.decreaseDebt.selector) {
                        _revertIfNoPermission(flags, DECREASE_DEBT_PERMISSION); // U:[FA-21]

                        (, uint256 tokensToDisable) = _manageDebt(
                            creditAccount, mcall.callData[4:], enabledTokensMask, ManageDebtAction.DECREASE_DEBT
                        ); // U:[FA-31]
                        enabledTokensMask = enabledTokensMask.disable(tokensToDisable); // U:[FA-31]
                    }
                    // setFullCheckParams
                    else if (method == ICreditFacadeV3Multicall.setFullCheckParams.selector) {
                        (fullCheckParams.collateralHints, fullCheckParams.minHealthFactor) =
                            abi.decode(mcall.callData[4:], (uint256[], uint16)); // U:[FA-24]

                        if (fullCheckParams.minHealthFactor < PERCENTAGE_FACTOR) {
                            revert CustomHealthFactorTooLowException(); // U:[FA-24]
                        }

                        uint256 hintsLen = fullCheckParams.collateralHints.length;
                        for (uint256 j; j < hintsLen; ++j) {
                            uint256 mask = fullCheckParams.collateralHints[j];
                            if (mask == 0 || mask & mask - 1 != 0) revert InvalidCollateralHintException(); // U:[FA-24]
                        }
                    }
                    // enableToken
                    else if (method == ICreditFacadeV3Multicall.enableToken.selector) {
                        _revertIfNoPermission(flags, ENABLE_TOKEN_PERMISSION); // U:[FA-21]
                        address token = abi.decode(mcall.callData[4:], (address)); // U:[FA-33]

                        quotedTokensMaskInverted = _quotedTokensMaskInvertedLoE(quotedTokensMaskInverted);

                        enabledTokensMask = enabledTokensMask.enable({
                            bitsToEnable: _getTokenMaskOrRevert(token),
                            invertedSkipMask: quotedTokensMaskInverted
                        }); // U:[FA-33]
                    }
                    // disableToken
                    else if (method == ICreditFacadeV3Multicall.disableToken.selector) {
                        _revertIfNoPermission(flags, DISABLE_TOKEN_PERMISSION); // U:[FA-21]
                        address token = abi.decode(mcall.callData[4:], (address)); // U:[FA-33]

                        quotedTokensMaskInverted = _quotedTokensMaskInvertedLoE(quotedTokensMaskInverted);

                        enabledTokensMask = enabledTokensMask.disable({
                            bitsToDisable: _getTokenMaskOrRevert(token),
                            invertedSkipMask: quotedTokensMaskInverted
                        }); // U:[FA-33]
                    }
                    // revokeAdapterAllowances
                    else if (method == ICreditFacadeV3Multicall.revokeAdapterAllowances.selector) {
                        _revertIfNoPermission(flags, REVOKE_ALLOWANCES_PERMISSION); // U:[FA-21]
                        _revokeAdapterAllowances(creditAccount, mcall.callData[4:]); // U:[FA-36]
                    }
                    // unknown method
                    else {
                        revert UnknownMethodException(); // U:[FA-22]
                    }
                }
                // adapter calls
                else {
                    _revertIfNoPermission(flags, EXTERNAL_CALLS_PERMISSION); // U:[FA-21]

                    bytes memory result;
                    {
                        address targetContract = ICreditManagerV3(creditManager).adapterToContract(mcall.target);
                        if (targetContract == address(0)) {
                            revert TargetContractNotAllowedException();
                        }

                        if (flags & EXTERNAL_CONTRACT_WAS_CALLED == 0) {
                            flags = flags.enable(EXTERNAL_CONTRACT_WAS_CALLED);
                            _setActiveCreditAccount(creditAccount); // U:[FA-38]
                        }

                        result = mcall.target.functionCall(mcall.callData); // U:[FA-38]

                        emit Execute({creditAccount: creditAccount, targetContract: targetContract});
                    }

                    (uint256 tokensToEnable, uint256 tokensToDisable) = abi.decode(result, (uint256, uint256)); // U:[FA-38]

                    quotedTokensMaskInverted = _quotedTokensMaskInvertedLoE(quotedTokensMaskInverted);

                    enabledTokensMask = enabledTokensMask.enableDisable({
                        bitsToEnable: tokensToEnable,
                        bitsToDisable: tokensToDisable,
                        invertedSkipMask: quotedTokensMaskInverted
                    }); // U:[FA-38]
                }
            }
        }

        if (expectedBalances.length != 0) {
            if (!BalancesLogic.compareBalances(creditAccount, expectedBalances, Comparison.GREATER)) {
                revert BalanceLessThanExpectedException(); // U:[FA-23]
            }
        }

        if (enabledTokensMask & forbiddenTokenMask != 0) {
            fullCheckParams.useSafePrices = true;
        }

        if (flags & EXTERNAL_CONTRACT_WAS_CALLED != 0) {
            _unsetActiveCreditAccount(); // U:[FA-38]
        }

        fullCheckParams.enabledTokensMaskAfter = enabledTokensMask; // U:[FA-38]

        emit FinishMultiCall(); // U:[FA-18]
    }

    /// @dev Applies on-demand price feed updates placed at the beginning of the multicall (if there are any)
    /// @return skipCalls Number of update calls made that can be skiped later in the `_multicall`
    function _applyOnDemandPriceUpdates(MultiCall[] calldata calls) internal returns (uint256 skipCalls) {
        address priceOracle;
        unchecked {
            uint256 len = calls.length;
            for (uint256 i; i < len; ++i) {
                MultiCall calldata mcall = calls[i];
                if (
                    mcall.target == address(this)
                        && bytes4(mcall.callData) == ICreditFacadeV3Multicall.onDemandPriceUpdate.selector
                ) {
                    (address token, bool reserve, bytes memory data) =
                        abi.decode(mcall.callData[4:], (address, bool, bytes)); // U:[FA-25]

                    priceOracle = _priceOracleLoE(priceOracle); // U:[FA-25]
                    address priceFeed = IPriceOracleV3(priceOracle).priceFeedsRaw(token, reserve); // U:[FA-25]

                    if (priceFeed == address(0)) {
                        revert PriceFeedDoesNotExistException(); // U:[FA-25]
                    }

                    IUpdatablePriceFeed(priceFeed).updatePrice(data); // U:[FA-25]
                } else {
                    return i;
                }
            }
            return len;
        }
    }

    /// @dev Performs collateral check to ensure that
    ///      - account is sufficiently collateralized
    ///      - account has no forbidden tokens after risky operations
    ///      - no forbidden tokens have been enabled during the multicall
    ///      - no enabled forbidden token balance has increased during the multicall
    function _fullCollateralCheck(
        address creditAccount,
        uint256 enabledTokensMaskBefore,
        FullCheckParams memory fullCheckParams,
        BalanceWithMask[] memory forbiddenBalances,
        uint256 forbiddenTokensMask
    ) internal {
        uint256 enabledTokensMask = ICreditManagerV3(creditManager).fullCollateralCheck(
            creditAccount,
            fullCheckParams.enabledTokensMaskAfter,
            fullCheckParams.collateralHints,
            fullCheckParams.minHealthFactor,
            fullCheckParams.useSafePrices
        ); // U:[FA-45]

        uint256 enabledForbiddenTokensMask = enabledTokensMask & forbiddenTokensMask;
        if (enabledForbiddenTokensMask != 0) {
            if (fullCheckParams.revertOnForbiddenTokens) revert ForbiddenTokensException(); // U:[FA-45]

            uint256 enabledForbiddenTokensMaskBefore = enabledTokensMaskBefore & forbiddenTokensMask;
            if (enabledForbiddenTokensMask & ~enabledForbiddenTokensMaskBefore != 0) {
                revert ForbiddenTokenEnabledException(); // U:[FA-45]
            }

            bool success = BalancesLogic.compareBalances({
                creditAccount: creditAccount,
                tokensMask: enabledForbiddenTokensMask,
                balances: forbiddenBalances,
                comparison: Comparison.LESS
            });

            if (!success) revert ForbiddenTokenBalanceIncreasedException(); // U:[FA-45]
        }
    }

    /// @dev `ICreditFacadeV3Multicall.addCollateral` implementation
    function _addCollateral(address creditAccount, bytes calldata callData) internal returns (uint256 tokensToEnable) {
        (address token, uint256 amount) = abi.decode(callData, (address, uint256)); // U:[FA-26]

        tokensToEnable = _addCollateral({payer: msg.sender, creditAccount: creditAccount, token: token, amount: amount}); // U:[FA-26]

        emit AddCollateral(creditAccount, token, amount); // U:[FA-26]
    }

    /// @dev `ICreditFacadeV3Multicall.addCollateralWithPermit` implementation
    function _addCollateralWithPermit(address creditAccount, bytes calldata callData)
        internal
        returns (uint256 tokensToEnable)
    {
        (address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) =
            abi.decode(callData, (address, uint256, uint256, uint8, bytes32, bytes32)); // U:[FA-26B]

        // `token` is only validated later in `addCollateral`, but to benefit off of it the attacker would have to make
        // it recognizable as collateral in the credit manager, which requires gaining configurator access rights
        try IERC20Permit(token).permit(msg.sender, creditManager, amount, deadline, v, r, s) {} catch {} // U:[FA-26B]

        tokensToEnable = _addCollateral({payer: msg.sender, creditAccount: creditAccount, token: token, amount: amount}); // U:[FA-26B]

        emit AddCollateral(creditAccount, token, amount); // U:[FA-26B]
    }

    /// @dev `ICreditFacadeV3Multicall.{increase|decrease}Debt` implementation
    function _manageDebt(
        address creditAccount,
        bytes calldata callData,
        uint256 enabledTokensMask,
        ManageDebtAction action
    ) internal returns (uint256 tokensToEnable, uint256 tokensToDisable) {
        uint256 amount = abi.decode(callData, (uint256)); // U:[FA-27,31]

        if (action == ManageDebtAction.INCREASE_DEBT) {
            _revertIfOutOfBorrowingLimit(amount); // U:[FA-28]
        }

        uint256 newDebt;
        (newDebt, tokensToEnable, tokensToDisable) =
            ICreditManagerV3(creditManager).manageDebt(creditAccount, amount, enabledTokensMask, action); // U:[FA-27,31]

        _revertIfOutOfDebtLimits(newDebt); // U:[FA-28, 32, 33, 33A]

        if (action == ManageDebtAction.INCREASE_DEBT) {
            emit IncreaseDebt({creditAccount: creditAccount, amount: amount}); // U:[FA-27]
        } else {
            emit DecreaseDebt({creditAccount: creditAccount, amount: amount}); // U:[FA-31]
        }
    }

    /// @dev `ICreditFacadeV3Multicall.updateQuota` implementation
    function _updateQuota(address creditAccount, bytes calldata callData, bool hasForbiddenTokens)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (address token, int96 quotaChange, uint96 minQuota) = abi.decode(callData, (address, int96, uint96)); // U:[FA-34]

        // Ensures that user is not trying to increase quota for a forbidden token. This happens implicitly when user
        // has no enabled forbidden tokens because quota increase would try to enable the token, which is prohibited.
        // Thus some gas is saved in this case by not querying token's mask.
        if (hasForbiddenTokens && quotaChange > 0) {
            if (_getTokenMaskOrRevert(token) & forbiddenTokenMask != 0) {
                revert ForbiddenTokensException();
            }
        }

        (tokensToEnable, tokensToDisable) = ICreditManagerV3(creditManager).updateQuota({
            creditAccount: creditAccount,
            token: token,
            quotaChange: quotaChange != type(int96).min
                ? quotaChange / int96(uint96(PERCENTAGE_FACTOR)) * int96(uint96(PERCENTAGE_FACTOR))
                : quotaChange,
            minQuota: minQuota,
            maxQuota: uint96(Math.min(type(uint96).max, maxQuotaMultiplier * debtLimits.maxDebt))
        }); // U:[FA-34]
    }

    /// @dev `ICreditFacadeV3Multicall.withdrawCollateral` implementation
    function _withdrawCollateral(address creditAccount, bytes calldata callData)
        internal
        returns (uint256 tokensToDisable)
    {
        (address token, uint256 amount, address to) = abi.decode(callData, (address, uint256, address)); // U:[FA-35]

        if (amount == type(uint256).max) {
            amount = IERC20(token).balanceOf(creditAccount);
            if (amount <= 1) return 0;
            unchecked {
                --amount;
            }
        }
        tokensToDisable = ICreditManagerV3(creditManager).withdrawCollateral(creditAccount, token, amount, to); // U:[FA-35]

        emit WithdrawCollateral(creditAccount, token, amount, to); // U:[FA-35]
    }

    /// @dev `ICreditFacadeV3Multicall.revokeAdapterAllowances` implementation
    function _revokeAdapterAllowances(address creditAccount, bytes calldata callData) internal {
        RevocationPair[] memory revocations = abi.decode(callData, (RevocationPair[])); // U:[FA-36]

        ICreditManagerV3(creditManager).revokeAdapterAllowances(creditAccount, revocations); // U:[FA-36]
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Sets the credit facade expiration timestamp
    /// @param newExpirationDate New expiration timestamp
    /// @dev Reverts if caller is not credit configurator
    /// @dev Reverts if credit facade is not expirable
    function setExpirationDate(uint40 newExpirationDate)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        if (!expirable) {
            revert NotAllowedWhenNotExpirableException(); // U:[FA-48]
        }
        expirationDate = newExpirationDate; // U:[FA-48]
    }

    /// @notice Sets debt limits per credit account
    /// @param newMinDebt New minimum debt amount per credit account
    /// @param newMaxDebt New maximum debt amount per credit account
    /// @param newMaxDebtPerBlockMultiplier New max debt per block multiplier, `type(uint8).max` to disable the check
    /// @dev Reverts if caller is not credit configurator
    /// @dev Reverts if `maxDebt * maxDebtPerBlockMultiplier` doesn't fit into `uint128`
    function setDebtLimits(uint128 newMinDebt, uint128 newMaxDebt, uint8 newMaxDebtPerBlockMultiplier)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        if ((uint256(newMaxDebtPerBlockMultiplier) * newMaxDebt) >= type(uint128).max) {
            revert IncorrectParameterException(); // U:[FA-49]
        }

        debtLimits.minDebt = newMinDebt; // U:[FA-49]
        debtLimits.maxDebt = newMaxDebt; // U:[FA-49]
        maxDebtPerBlockMultiplier = newMaxDebtPerBlockMultiplier; // U:[FA-49]
    }

    /// @notice Sets the new bot list
    /// @param newBotList New bot list address
    /// @dev Reverts if caller is not credit configurator
    function setBotList(address newBotList)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        botList = newBotList; // U:[FA-50]
    }

    /// @notice Sets the new max cumulative loss
    /// @param newMaxCumulativeLoss New max cumulative loss
    /// @param resetCumulativeLoss Whether to reset the current cumulative loss to zero
    /// @dev Reverts if caller is not credit configurator
    function setCumulativeLossParams(uint128 newMaxCumulativeLoss, bool resetCumulativeLoss)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        lossParams.maxCumulativeLoss = newMaxCumulativeLoss; // U:[FA-51]
        if (resetCumulativeLoss) {
            lossParams.currentCumulativeLoss = 0; // U:[FA-51]
        }
    }

    /// @notice Changes token's forbidden status
    /// @param token Token to change the status for
    /// @param allowance Status to set
    /// @dev Reverts if caller is not credit configurator
    function setTokenAllowance(address token, AllowanceAction allowance)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        uint256 tokenMask = _getTokenMaskOrRevert(token); // U:[FA-52]

        forbiddenTokenMask = (allowance == AllowanceAction.ALLOW)
            ? forbiddenTokenMask.disable(tokenMask)
            : forbiddenTokenMask.enable(tokenMask); // U:[FA-52]
    }

    /// @notice Changes account's status as emergency liquidator
    /// @param liquidator Account to change the status for
    /// @param allowance Status to set
    /// @dev Reverts if caller is not credit configurator
    function setEmergencyLiquidator(address liquidator, AllowanceAction allowance)
        external
        override
        creditConfiguratorOnly // U:[FA-6]
    {
        canLiquidateWhilePaused[liquidator] = allowance == AllowanceAction.ALLOW; // U:[FA-53]
    }

    // --------- //
    // INTERNALS //
    // --------- //

    /// @dev Ensures that amount borrowed by credit manager in the current block does not exceed the limit
    /// @dev Skipped when `maxDebtPerBlockMultiplier == type(uint8).max`
    function _revertIfOutOfBorrowingLimit(uint256 amount) internal {
        uint8 _maxDebtPerBlockMultiplier = maxDebtPerBlockMultiplier; // U:[FA-43]
        if (_maxDebtPerBlockMultiplier == type(uint8).max) return; // U:[FA-43]

        uint256 newDebtInCurrentBlock;
        if (lastBlockBorrowed == block.number) {
            newDebtInCurrentBlock = amount + totalBorrowedInBlock; // U:[FA-43]
        } else {
            newDebtInCurrentBlock = amount;
            lastBlockBorrowed = uint64(block.number); // U:[FA-43]
        }

        if (newDebtInCurrentBlock > uint256(_maxDebtPerBlockMultiplier) * debtLimits.maxDebt) {
            revert BorrowedBlockLimitException(); // U:[FA-43]
        }

        // the conversion is safe because of the check in `setDebtLimits`
        totalBorrowedInBlock = uint128(newDebtInCurrentBlock); // U:[FA-43]
    }

    /// @dev Ensures that account's debt principal is within allowed range or is zero
    function _revertIfOutOfDebtLimits(uint256 debt) internal view {
        uint256 minDebt;
        uint256 maxDebt;

        // minDebt = debtLimits.minDebt;
        // maxDebt = debtLimits.maxDebt;
        assembly {
            let data := sload(debtLimits.slot)
            maxDebt := shr(128, data)
            minDebt := and(data, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        if (debt != 0 && ((debt < minDebt) || (debt > maxDebt))) {
            revert BorrowAmountOutOfLimitsException(); // U:[FA-44]
        }
    }

    /// @dev Ensures that `flags` has the `permission` bit enabled
    function _revertIfNoPermission(uint256 flags, uint256 permission) internal pure {
        if (flags & permission == 0) {
            revert NoPermissionException(permission); // U:[FA-39]
        }
    }

    /// @dev Load-on-empty function to read inverted quoted tokens mask at most once if it's needed,
    ///      returns its argument if it's not empty or inverted `quotedTokensMask` from credit manager otherwise
    /// @dev Non-empty inverted quoted tokens mask always has it's LSB set to 1 since underlying can't be quoted
    function _quotedTokensMaskInvertedLoE(uint256 quotedTokensMaskInvertedOrEmpty) internal view returns (uint256) {
        return quotedTokensMaskInvertedOrEmpty == 0
            ? ~ICreditManagerV3(creditManager).quotedTokensMask()
            : quotedTokensMaskInvertedOrEmpty;
    }

    /// @dev Load-on-empty function to read price oracle at most once if it's needed,
    ///      returns its argument if it's not empty or `priceOracle` from credit manager otherwise
    /// @dev Non-empty price oracle always has non-zero address
    function _priceOracleLoE(address priceOracleOrEmpty) internal view returns (address) {
        return priceOracleOrEmpty == address(0) ? ICreditManagerV3(creditManager).priceOracle() : priceOracleOrEmpty;
    }

    /// @dev Wraps any ETH sent in the function call and sends it back to `msg.sender`
    function _wrapETH() internal {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}(); // U:[FA-7]
            IERC20(weth).safeTransfer(msg.sender, msg.value); // U:[FA-7]
        }
    }

    /// @dev Whether credit facade has expired (`false` if it's not expirable or expiration timestamp is not set)
    function _isExpired() internal view returns (bool) {
        if (!expirable) return false; // U:[FA-46]
        uint40 _expirationDate = expirationDate;
        return _expirationDate != 0 && block.timestamp >= _expirationDate; // U:[FA-46]
    }

    /// @dev Internal wrapper for `creditManager.getBorrowerOrRevert` call to reduce contract size
    function _getBorrowerOrRevert(address creditAccount) internal view returns (address) {
        return ICreditManagerV3(creditManager).getBorrowerOrRevert({creditAccount: creditAccount});
    }

    /// @dev Internal wrapper for `creditManager.getTokenMaskOrRevert` call to reduce contract size
    function _getTokenMaskOrRevert(address token) internal view returns (uint256) {
        return ICreditManagerV3(creditManager).getTokenMaskOrRevert(token);
    }

    /// @dev Internal wrapper for `creditManager.getTokenByMask` call to reduce contract size
    function _getTokenByMask(uint256 mask) internal view returns (address) {
        return ICreditManagerV3(creditManager).getTokenByMask(mask);
    }

    /// @dev Internal wrapper for `creditManager.flagsOf` call to reduce contract size
    function _flagsOf(address creditAccount) internal view returns (uint16) {
        return ICreditManagerV3(creditManager).flagsOf(creditAccount);
    }

    /// @dev Internal wrapper for `creditManager.setFlagFor` call to reduce contract size
    function _setFlagFor(address creditAccount, uint16 flag, bool value) internal {
        ICreditManagerV3(creditManager).setFlagFor(creditAccount, flag, value);
    }

    /// @dev Internal wrapper for `creditManager.setActiveCreditAccount` call to reduce contract size
    function _setActiveCreditAccount(address creditAccount) internal {
        ICreditManagerV3(creditManager).setActiveCreditAccount(creditAccount);
    }

    /// @dev Same as above but unsets active credit account
    function _unsetActiveCreditAccount() internal {
        _setActiveCreditAccount(INACTIVE_CREDIT_ACCOUNT_ADDRESS);
    }

    /// @dev Internal wrapper for `creditManager.addCollateral` call to reduce contract size
    function _addCollateral(address payer, address creditAccount, address token, uint256 amount)
        internal
        returns (uint256 tokenMask)
    {
        tokenMask = ICreditManagerV3(creditManager).addCollateral({
            payer: payer,
            creditAccount: creditAccount,
            token: token,
            amount: amount
        });
    }

    /// @dev Internal wrapper for `creditManager.enabledTokensMaskOf` call to reduce contract size
    function _enabledTokensMaskOf(address creditAccount) internal view returns (uint256) {
        return ICreditManagerV3(creditManager).enabledTokensMaskOf(creditAccount);
    }

    /// @dev Reverts if `msg.sender` is not credit configurator
    function _checkCreditConfigurator() internal view {
        if (msg.sender != ICreditManagerV3(creditManager).creditConfigurator()) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Reverts if `msg.sender` is not `creditAccount` owner
    function _checkCreditAccountOwner(address creditAccount) internal view {
        if (msg.sender != _getBorrowerOrRevert(creditAccount)) {
            revert CallerNotCreditAccountOwnerException();
        }
    }

    /// @dev Reverts if credit facade is expired
    function _checkExpired() internal view {
        if (_isExpired()) {
            revert NotAllowedAfterExpirationException();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// THIRD-PARTY
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// LIBS & TRAITS
import {UNDERLYING_TOKEN_MASK, BitMask} from "../libraries/BitMask.sol";
import {CreditLogic} from "../libraries/CreditLogic.sol";
import {CollateralLogic} from "../libraries/CollateralLogic.sol";
import {CreditAccountHelper} from "../libraries/CreditAccountHelper.sol";

import {ReentrancyGuardTrait} from "../traits/ReentrancyGuardTrait.sol";
import {SanityCheckTrait} from "../traits/SanityCheckTrait.sol";

// INTERFACES
import {IAccountFactoryBase} from "../interfaces/IAccountFactoryV3.sol";
import {ICreditAccountBase} from "../interfaces/ICreditAccountV3.sol";
import {IPoolV3} from "../interfaces/IPoolV3.sol";
import {
    ICreditManagerV3,
    CollateralTokenData,
    ManageDebtAction,
    CreditAccountInfo,
    RevocationPair,
    CollateralDebtData,
    CollateralCalcTask,
    DEFAULT_MAX_ENABLED_TOKENS,
    INACTIVE_CREDIT_ACCOUNT_ADDRESS
} from "../interfaces/ICreditManagerV3.sol";
import "../interfaces/IAddressProviderV3.sol";
import {IPriceOracleV3} from "../interfaces/IPriceOracleV3.sol";
import {IPoolQuotaKeeperV3} from "../interfaces/IPoolQuotaKeeperV3.sol";

// CONSTANTS
import {PERCENTAGE_FACTOR} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

// EXCEPTIONS
import "../interfaces/IExceptions.sol";

/// @title Credit manager V3
/// @notice Credit manager implements core logic for credit accounts management.
///         The contract itself is not open to neither external users nor the DAO: users should use `CreditFacadeV3`
///         to open accounts and perform interactions with external protocols, while the DAO can configure manager
///         params using `CreditConfiguratorV3`. Both mentioned contracts perform some important safety checks.
contract CreditManagerV3 is ICreditManagerV3, SanityCheckTrait, ReentrancyGuardTrait {
    using EnumerableSet for EnumerableSet.AddressSet;
    using BitMask for uint256;
    using Math for uint256;
    using CreditLogic for CollateralDebtData;
    using CollateralLogic for CollateralDebtData;
    using SafeERC20 for IERC20;
    using CreditAccountHelper for ICreditAccountBase;

    /// @notice Contract version
    uint256 public constant override version = 3_01;

    /// @notice Address provider contract address
    address public immutable override addressProvider;

    /// @notice Account factory contract address
    address public immutable override accountFactory;

    /// @notice Underlying token address
    address public immutable override underlying;

    /// @notice Address of the pool credit manager is connected to
    address public immutable override pool;

    /// @notice Address of the connected credit facade
    address public override creditFacade;

    /// @notice Address of the connected credit configurator
    address public override creditConfigurator;

    /// @notice Price oracle contract address
    address public override priceOracle;

    /// @notice Maximum number of tokens that a credit account can have enabled as collateral
    uint8 public override maxEnabledTokens = DEFAULT_MAX_ENABLED_TOKENS;

    /// @notice Number of known collateral tokens
    uint8 public override collateralTokensCount;

    /// @dev Liquidation threshold for the underlying token in bps
    uint16 internal ltUnderlying;

    /// @dev Percentage of accrued interest in bps taken by the protocol as profit
    uint16 internal feeInterest;

    /// @dev Percentage of liquidated account value in bps taken by the protocol as profit
    uint16 internal feeLiquidation;

    /// @dev Percentage of liquidated account value in bps that is used to repay debt
    uint16 internal liquidationDiscount;

    /// @dev Percentage of liquidated expired account value in bps taken by the protocol as profit
    uint16 internal feeLiquidationExpired;

    /// @dev Percentage of liquidated expired account value in bps that is used to repay debt
    uint16 internal liquidationDiscountExpired;

    /// @dev Active credit account which is an account adapters can interfact with
    address internal _activeCreditAccount = INACTIVE_CREDIT_ACCOUNT_ADDRESS;

    /// @notice Bitmask of quoted tokens
    uint256 public override quotedTokensMask;

    /// @dev Mapping collateral token mask => data (packed address and LT parameters)
    mapping(uint256 => CollateralTokenData) internal collateralTokensData;

    /// @dev Mapping collateral token address => mask
    mapping(address => uint256) internal tokenMasksMapInternal;

    /// @notice Mapping adapter => target contract
    mapping(address => address) public override adapterToContract;

    /// @notice Mapping target contract => adapter
    mapping(address => address) public override contractToAdapter;

    /// @notice Mapping credit account => account info (owner, debt amount, etc.)
    mapping(address => CreditAccountInfo) public override creditAccountInfo;

    /// @dev Set of all credit accounts opened in this credit manager
    EnumerableSet.AddressSet internal creditAccountsSet;

    /// @notice Credit manager name
    string public override name;

    /// @dev Ensures that function caller is the credit facade
    modifier creditFacadeOnly() {
        _checkCreditFacade();
        _;
    }

    /// @dev Ensures that function caller is the credit configurator
    modifier creditConfiguratorOnly() {
        _checkCreditConfigurator();
        _;
    }

    /// @notice Constructor
    /// @param _addressProvider Address provider contract address
    /// @param _pool Address of the lending pool to connect this credit manager to
    /// @param _name Credit manager name
    /// @dev Adds pool's underlying as collateral token with LT = 0
    /// @dev Sets `msg.sender` as credit configurator
    constructor(address _addressProvider, address _pool, string memory _name) {
        addressProvider = _addressProvider;
        pool = _pool; // U:[CM-1]

        underlying = IPoolV3(_pool).underlyingToken(); // U:[CM-1]
        _addToken(underlying); // U:[CM-1]

        priceOracle = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_PRICE_ORACLE, 3_00); // U:[CM-1]
        accountFactory = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_ACCOUNT_FACTORY, NO_VERSION_CONTROL); // U:[CM-1]

        creditConfigurator = msg.sender; // U:[CM-1]

        name = _name;
    }

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    /// @notice Opens a new credit account
    /// @param onBehalfOf Owner of a newly opened credit account
    /// @return creditAccount Address of the newly opened credit account
    function openCreditAccount(address onBehalfOf)
        external
        override
        nonZeroAddress(onBehalfOf)
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (address creditAccount)
    {
        creditAccount = IAccountFactoryBase(accountFactory).takeCreditAccount(0, 0); // U:[CM-6]

        CreditAccountInfo storage newCreditAccountInfo = creditAccountInfo[creditAccount];

        // newCreditAccountInfo.flags = 0;
        // newCreditAccountInfo.lastDebtUpdate = 0;
        // newCreditAccountInfo.borrower = onBehalfOf;
        assembly {
            let slot := add(newCreditAccountInfo.slot, 4)
            let value := shl(80, onBehalfOf)
            sstore(slot, value)
        } // U:[CM-6]

        // newCreditAccountInfo.cumulativeQuotaInterest = 1;
        // newCreditAccountInfo.quotaFees = 0;
        assembly {
            let slot := add(newCreditAccountInfo.slot, 2)
            sstore(slot, 1)
        } // U:[CM-6]

        creditAccountsSet.add(creditAccount); // U:[CM-6]
    }

    /// @notice Closes a credit account
    /// @param creditAccount Account to close
    /// @custom:expects Credit facade ensures that `creditAccount` is opened in this credit manager
    function closeCreditAccount(address creditAccount)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
    {
        CreditAccountInfo storage currentCreditAccountInfo = creditAccountInfo[creditAccount];
        if (currentCreditAccountInfo.debt != 0) {
            revert CloseAccountWithNonZeroDebtException(); // U:[CM-7]
        }

        // currentCreditAccountInfo.borrower = address(0);
        // currentCreditAccountInfo.lastDebtUpdate = 0;
        // currentCreditAccountInfo.flags = 0;
        assembly {
            let slot := add(currentCreditAccountInfo.slot, 4)
            sstore(slot, 0)
        } // U:[CM-7]

        currentCreditAccountInfo.enabledTokensMask = 0; // U:[CM-7]

        IAccountFactoryBase(accountFactory).returnCreditAccount({creditAccount: creditAccount}); // U:[CM-7]
        creditAccountsSet.remove(creditAccount); // U:[CM-7]
    }

    /// @notice Liquidates a credit account
    ///         - Removes account's quotas, and, if there's loss incurred on liquidation,
    ///           also zeros out limits for account's quoted tokens in the quota keeper
    ///         - Repays debt to the pool
    ///         - Ensures that the value of funds remaining on the account is sufficient
    ///         - Transfers underlying surplus (if any) to the liquidator
    ///         - Resets account's debt, quota interest and fees to zero
    /// @param creditAccount Account to liquidate
    /// @param collateralDebtData A struct with account's debt and collateral data
    /// @param to Address to transfer underlying left after liquidation
    /// @return remainingFunds Total value of assets left on the account after liquidation
    /// @return loss Loss incurred on liquidation
    /// @custom:expects Credit facade ensures that `creditAccount` is opened in this credit manager
    /// @custom:expects `collateralDebtData` is a result of `calcDebtAndCollateral` in `DEBT_COLLATERAL` mode
    function liquidateCreditAccount(
        address creditAccount,
        CollateralDebtData calldata collateralDebtData,
        address to,
        bool isExpired
    )
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (uint256 remainingFunds, uint256 loss)
    {
        uint256 amountToPool;
        uint256 minRemainingFunds;
        uint256 profit;
        (amountToPool, minRemainingFunds, profit, loss) = collateralDebtData.calcLiquidationPayments({
            liquidationDiscount: isExpired ? liquidationDiscountExpired : liquidationDiscount,
            feeLiquidation: isExpired ? feeLiquidationExpired : feeLiquidation,
            amountWithFeeFn: _amountWithFee,
            amountMinusFeeFn: _amountMinusFee
        }); // U:[CM-8]

        if (collateralDebtData.quotedTokens.length != 0) {
            IPoolQuotaKeeperV3(collateralDebtData._poolQuotaKeeper).removeQuotas({
                creditAccount: creditAccount,
                tokens: collateralDebtData.quotedTokens,
                setLimitsToZero: loss > 0
            }); // U:[CM-8]
        }

        if (amountToPool != 0) {
            ICreditAccountBase(creditAccount).transfer({token: underlying, to: pool, amount: amountToPool}); // U:[CM-8]
        }
        _poolRepayCreditAccount(collateralDebtData.debt, profit, loss); // U:[CM-8]

        uint256 underlyingBalance;
        (remainingFunds, underlyingBalance) =
            _getRemainingFunds({creditAccount: creditAccount, enabledTokensMask: collateralDebtData.enabledTokensMask}); // U:[CM-8]

        if (remainingFunds < minRemainingFunds) {
            revert InsufficientRemainingFundsException(); // U:[CM-8]
        }

        unchecked {
            uint256 amountToLiquidator = Math.min(remainingFunds - minRemainingFunds, underlyingBalance);

            if (amountToLiquidator != 0) {
                ICreditAccountBase(creditAccount).transfer({token: underlying, to: to, amount: amountToLiquidator}); // U:[CM-8]

                remainingFunds -= amountToLiquidator; // U:[CM-8]
            }
        }

        CreditAccountInfo storage currentCreditAccountInfo = creditAccountInfo[creditAccount];
        if (currentCreditAccountInfo.lastDebtUpdate == block.number) {
            revert DebtUpdatedTwiceInOneBlockException(); // U:[CM-9]
        }

        currentCreditAccountInfo.debt = 0; // U:[CM-8]
        currentCreditAccountInfo.lastDebtUpdate = uint64(block.number); // U:[CM-8]
        currentCreditAccountInfo.enabledTokensMask =
            collateralDebtData.enabledTokensMask.disable(collateralDebtData.quotedTokensMask); // U:[CM-8]

        // currentCreditAccountInfo.cumulativeQuotaInterest = 1;
        // currentCreditAccountInfo.quotaFees = 0;
        assembly {
            let slot := add(currentCreditAccountInfo.slot, 2)
            sstore(slot, 1)
        } // U:[CM-8]
    }

    /// @notice Increases or decreases credit account's debt
    /// @param creditAccount Account to increase/decrease debr for
    /// @param amount Amount of underlying to change the total debt by
    /// @param enabledTokensMask  Bitmask of account's enabled collateral tokens
    /// @param action Manage debt type, see `ManageDebtAction`
    /// @return newDebt Debt principal after update
    /// @return tokensToEnable Tokens that should be enabled after the operation
    ///         (underlying mask on increase, zero on decrease)
    /// @return tokensToDisable Tokens that should be disabled after the operation
    ///         (zero on increase, underlying mask on decrease if account has no underlying after repayment)
    /// @custom:expects Credit facade ensures that `creditAccount` is opened in this credit manager
    function manageDebt(address creditAccount, uint256 amount, uint256 enabledTokensMask, ManageDebtAction action)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (uint256 newDebt, uint256 tokensToEnable, uint256 tokensToDisable)
    {
        CreditAccountInfo storage currentCreditAccountInfo = creditAccountInfo[creditAccount];
        if (currentCreditAccountInfo.lastDebtUpdate == block.number) {
            revert DebtUpdatedTwiceInOneBlockException(); // U:[CM-12A]
        }
        if (amount == 0) return (currentCreditAccountInfo.debt, 0, 0); // U:[CM-12B]

        uint256[] memory collateralHints;
        CollateralDebtData memory collateralDebtData = _calcDebtAndCollateral({
            creditAccount: creditAccount,
            enabledTokensMask: enabledTokensMask,
            collateralHints: collateralHints,
            minHealthFactor: PERCENTAGE_FACTOR,
            task: (action == ManageDebtAction.INCREASE_DEBT)
                ? CollateralCalcTask.GENERIC_PARAMS
                : CollateralCalcTask.DEBT_ONLY,
            useSafePrices: false
        });

        uint256 newCumulativeIndex;
        if (action == ManageDebtAction.INCREASE_DEBT) {
            (newDebt, newCumulativeIndex) = CreditLogic.calcIncrease({
                amount: amount,
                debt: collateralDebtData.debt,
                cumulativeIndexNow: collateralDebtData.cumulativeIndexNow,
                cumulativeIndexLastUpdate: collateralDebtData.cumulativeIndexLastUpdate
            }); // U:[CM-10]

            _poolLendCreditAccount(amount, creditAccount); // U:[CM-10]
            tokensToEnable = UNDERLYING_TOKEN_MASK; // U:[CM-12C]
        } else {
            uint256 maxRepayment = _amountWithFee(collateralDebtData.calcTotalDebt());
            if (amount >= maxRepayment) {
                amount = maxRepayment; // U:[CM-11]
            }

            ICreditAccountBase(creditAccount).transfer({token: underlying, to: pool, amount: amount}); // U:[CM-11]

            uint128 newCumulativeQuotaInterest;
            uint256 profit;
            if (amount == maxRepayment) {
                newDebt = 0;
                newCumulativeIndex = collateralDebtData.cumulativeIndexNow;
                profit = collateralDebtData.accruedFees;
                newCumulativeQuotaInterest = 0;
                currentCreditAccountInfo.quotaFees = 0;
            } else {
                (newDebt, newCumulativeIndex, profit, newCumulativeQuotaInterest, currentCreditAccountInfo.quotaFees) =
                CreditLogic.calcDecrease({
                    amount: _amountMinusFee(amount),
                    debt: collateralDebtData.debt,
                    cumulativeIndexNow: collateralDebtData.cumulativeIndexNow,
                    cumulativeIndexLastUpdate: collateralDebtData.cumulativeIndexLastUpdate,
                    cumulativeQuotaInterest: collateralDebtData.cumulativeQuotaInterest,
                    quotaFees: currentCreditAccountInfo.quotaFees,
                    feeInterest: feeInterest
                }); // U:[CM-11]
            }

            if (collateralDebtData.quotedTokens.length != 0) {
                // zero-debt is a special state that disables collateral checks so having quotas on
                // the account should be forbidden as they entail debt in a form of quota interest
                if (newDebt == 0) revert DebtToZeroWithActiveQuotasException(); // U:[CM-11A]

                // quota interest is accrued in credit manager regardless of whether anything has been repaid,
                // so they are also accrued in the quota keeper to keep the contracts in sync
                IPoolQuotaKeeperV3(collateralDebtData._poolQuotaKeeper).accrueQuotaInterest({
                    creditAccount: creditAccount,
                    tokens: collateralDebtData.quotedTokens
                }); // U:[CM-11A]
            }

            _poolRepayCreditAccount(collateralDebtData.debt - newDebt, profit, 0); // U:[CM-11]

            currentCreditAccountInfo.cumulativeQuotaInterest = newCumulativeQuotaInterest + 1; // U:[CM-11]

            if (IERC20(underlying).safeBalanceOf({account: creditAccount}) <= 1) {
                tokensToDisable = UNDERLYING_TOKEN_MASK; // U:[CM-12C]
            }
        }

        currentCreditAccountInfo.debt = newDebt; // U:[CM-10,11]
        currentCreditAccountInfo.lastDebtUpdate = uint64(block.number); // U:[CM-10,11]
        currentCreditAccountInfo.cumulativeIndexLastUpdate = newCumulativeIndex; // U:[CM-10,11]
    }

    /// @notice Adds `amount` of `payer`'s `token` as collateral to `creditAccount`
    /// @param payer Address to transfer token from
    /// @param creditAccount Account to add collateral to
    /// @param token Token to add as collateral
    /// @param amount Amount to add
    /// @return tokensToEnable Mask of tokens that should be enabled after the operation (always `token` mask)
    /// @dev Requires approval for `token` from `payer` to this contract
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function addCollateral(address payer, address creditAccount, address token, uint256 amount)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (uint256 tokensToEnable)
    {
        tokensToEnable = getTokenMaskOrRevert({token: token}); // U:[CM-13]
        IERC20(token).safeTransferFrom({from: payer, to: creditAccount, amount: amount}); // U:[CM-13]
    }

    /// @notice Withdraws `amount` of `token` collateral from `creditAccount` to `to`
    /// @param creditAccount Credit account to withdraw collateral from
    /// @param token Token to withdraw
    /// @param amount Amount to withdraw
    /// @param to Address to transfer token to
    /// @return tokensToDisable Mask of tokens that should be disabled after the operation
    ///         (`token` mask if withdrawing the entire balance, zero otherwise)
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function withdrawCollateral(address creditAccount, address token, uint256 amount, address to)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (uint256 tokensToDisable)
    {
        uint256 tokenMask = getTokenMaskOrRevert({token: token}); // U:[CM-26]

        ICreditAccountBase(creditAccount).transfer({token: token, to: to, amount: amount}); // U:[CM-27]

        if (IERC20(token).safeBalanceOf({account: creditAccount}) <= 1) {
            tokensToDisable = tokenMask; // U:[CM-27]
        }
    }

    /// @notice Instructs `creditAccount` to make an external call to target with `callData`
    function externalCall(address creditAccount, address target, bytes calldata callData)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (bytes memory result)
    {
        return _execute(creditAccount, target, callData);
    }

    /// @notice Instructs `creditAccount` to approve `amount` of `token` to `spender`
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function approveToken(address creditAccount, address token, address spender, uint256 amount)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
    {
        _approveSpender({creditAccount: creditAccount, token: token, spender: spender, amount: amount});
    }

    /// @notice Revokes credit account's allowances for specified spender/token pairs
    /// @param creditAccount Account to revoke allowances for
    /// @param revocations Array of spender/token pairs
    /// @dev Exists primarily to allow users to revoke allowances on accounts from old account factory on mainnet
    /// @dev Reverts if any of provided tokens is not recognized as collateral in the credit manager
    function revokeAdapterAllowances(address creditAccount, RevocationPair[] calldata revocations)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
    {
        uint256 numRevocations = revocations.length;
        unchecked {
            for (uint256 i; i < numRevocations; ++i) {
                address spender = revocations[i].spender;
                address token = revocations[i].token;
                if (spender == address(0) || token == address(0)) {
                    revert ZeroAddressException(); // U:[CM-15]
                }
                _approveSpender({creditAccount: creditAccount, token: token, spender: spender, amount: 0}); // U:[CM-15]
            }
        }
    }

    // -------- //
    // ADAPTERS //
    // -------- //

    /// @notice Instructs active credit account to approve `amount` of `token` to adater's target contract
    /// @param token Token to approve
    /// @param amount Amount to approve
    /// @dev Reverts if active credit account is not set
    /// @dev Reverts if `msg.sender` is not a registered adapter
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function approveCreditAccount(address token, uint256 amount)
        external
        override
        nonReentrant // U:[CM-5]
    {
        address targetContract = _getTargetContractOrRevert(); // U:[CM-3]
        address creditAccount = getActiveCreditAccountOrRevert(); // U:[CM-14]
        _approveSpender({creditAccount: creditAccount, token: token, spender: targetContract, amount: amount}); // U:[CM-14]
    }

    /// @notice Instructs active credit account to call adapter's target contract with provided data
    /// @param data Data to call the target contract with
    /// @return result Call result
    /// @dev Reverts if active credit account is not set
    /// @dev Reverts if `msg.sender` is not a registered adapter
    function execute(bytes calldata data)
        external
        override
        nonReentrant // U:[CM-5]
        returns (bytes memory result)
    {
        address targetContract = _getTargetContractOrRevert(); // U:[CM-3]
        address creditAccount = getActiveCreditAccountOrRevert(); // U:[CM-16]
        return _execute(creditAccount, targetContract, data); // U:[CM-16]
    }

    /// @dev Returns adapter's target contract, reverts if `msg.sender` is not a registered adapter
    function _getTargetContractOrRevert() internal view returns (address targetContract) {
        targetContract = adapterToContract[msg.sender]; // U:[CM-15, 16]
        if (targetContract == address(0)) {
            revert CallerNotAdapterException(); // U:[CM-3]
        }
    }

    /// @notice Sets/unsets active credit account adapters can interact with
    /// @param creditAccount Credit account to set as active or `INACTIVE_CREDIT_ACCOUNT_ADDRESS` to unset it
    function setActiveCreditAccount(address creditAccount)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
    {
        if (_activeCreditAccount != INACTIVE_CREDIT_ACCOUNT_ADDRESS && creditAccount != INACTIVE_CREDIT_ACCOUNT_ADDRESS)
        {
            revert ActiveCreditAccountOverridenException();
        }
        _activeCreditAccount = creditAccount;
    }

    /// @notice Returns active credit account, reverts if it is not set
    function getActiveCreditAccountOrRevert() public view override returns (address creditAccount) {
        creditAccount = _activeCreditAccount;
        if (creditAccount == INACTIVE_CREDIT_ACCOUNT_ADDRESS) {
            revert ActiveCreditAccountNotSetException();
        }
    }

    // ----------------- //
    // COLLATERAL CHECKS //
    // ----------------- //

    /// @notice Performs full check of `creditAccount`'s collateral to ensure it is sufficiently collateralized,
    ///         might disable tokens with zero balances
    /// @param creditAccount Credit account to check
    /// @param enabledTokensMask Bitmask of account's enabled collateral tokens
    /// @param collateralHints Optional array of token masks to check first to reduce the amount of computation
    ///        when known subset of account's collateral tokens covers all the debt
    /// @param minHealthFactor Health factor threshold in bps, the check fails if `twvUSD < minHealthFactor * totalDebtUSD`
    /// @param useSafePrices Whether to use safe prices when evaluating collateral
    /// @return enabledTokensMaskAfter Bitmask of account's enabled collateral tokens after potential cleanup
    /// @dev Even when `collateralHints` are specified, quoted tokens are evaluated before non-quoted ones
    /// @custom:expects Credit facade ensures that `creditAccount` is opened in this credit manager
    function fullCollateralCheck(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] calldata collateralHints,
        uint16 minHealthFactor,
        bool useSafePrices
    )
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (uint256 enabledTokensMaskAfter)
    {
        CollateralDebtData memory cdd = _calcDebtAndCollateral({
            creditAccount: creditAccount,
            minHealthFactor: minHealthFactor,
            collateralHints: collateralHints,
            enabledTokensMask: enabledTokensMask,
            task: CollateralCalcTask.FULL_COLLATERAL_CHECK_LAZY,
            useSafePrices: useSafePrices
        }); // U:[CM-18]

        if (cdd.twvUSD < cdd.totalDebtUSD * minHealthFactor / PERCENTAGE_FACTOR) {
            revert NotEnoughCollateralException(); // U:[CM-18B]
        }

        enabledTokensMaskAfter = cdd.enabledTokensMask;
        _saveEnabledTokensMask(creditAccount, enabledTokensMaskAfter); // U:[CM-18]
    }

    /// @notice Whether `creditAccount`'s health factor is below `minHealthFactor`
    /// @param creditAccount Credit account to check
    /// @param minHealthFactor Health factor threshold in bps
    /// @dev Reverts if account is not opened in this credit manager
    function isLiquidatable(address creditAccount, uint16 minHealthFactor) external view override returns (bool) {
        getBorrowerOrRevert(creditAccount); // U:[CM-17]

        uint256[] memory collateralHints;
        CollateralDebtData memory cdd = _calcDebtAndCollateral({
            creditAccount: creditAccount,
            enabledTokensMask: enabledTokensMaskOf(creditAccount),
            collateralHints: collateralHints,
            minHealthFactor: minHealthFactor,
            task: CollateralCalcTask.FULL_COLLATERAL_CHECK_LAZY,
            useSafePrices: false
        }); // U:[CM-18]

        return cdd.twvUSD < cdd.totalDebtUSD * minHealthFactor / PERCENTAGE_FACTOR; // U:[CM-18B]
    }

    /// @notice Returns `creditAccount`'s debt and collateral data with level of detail controlled by `task`
    /// @param creditAccount Credit account to return data for
    /// @param task Calculation mode, see `CollateralCalcTask` for details, can't be `FULL_COLLATERAL_CHECK_LAZY`
    /// @return cdd A struct with debt and collateral data
    /// @dev Reverts if account is not opened in this credit manager
    function calcDebtAndCollateral(address creditAccount, CollateralCalcTask task)
        external
        view
        override
        returns (CollateralDebtData memory cdd)
    {
        if (task == CollateralCalcTask.FULL_COLLATERAL_CHECK_LAZY) {
            revert IncorrectParameterException(); // U:[CM-19]
        }

        bool useSafePrices;
        if (task == CollateralCalcTask.DEBT_COLLATERAL_SAFE_PRICES) {
            task = CollateralCalcTask.DEBT_COLLATERAL;
            useSafePrices = true;
        }

        getBorrowerOrRevert(creditAccount); // U:[CM-17]

        uint256[] memory collateralHints;
        cdd = _calcDebtAndCollateral({
            creditAccount: creditAccount,
            enabledTokensMask: enabledTokensMaskOf(creditAccount),
            collateralHints: collateralHints,
            minHealthFactor: PERCENTAGE_FACTOR,
            task: task,
            useSafePrices: useSafePrices
        }); // U:[CM-20]
    }

    /// @dev `calcDebtAndCollateral` implementation
    /// @param creditAccount Credit account to return data for
    /// @param enabledTokensMask Bitmask of account's enabled collateral tokens
    /// @param collateralHints Optional array of token masks specifying the order of checking collateral tokens
    /// @param minHealthFactor Health factor in bps to stop the calculations after when performing collateral check
    /// @param task Calculation mode, see `CollateralCalcTask` for details
    /// @param useSafePrices Whether to use safe prices when evaluating collateral
    /// @return cdd A struct with debt and collateral data
    function _calcDebtAndCollateral(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] memory collateralHints,
        uint16 minHealthFactor,
        CollateralCalcTask task,
        bool useSafePrices
    ) internal view returns (CollateralDebtData memory cdd) {
        CreditAccountInfo storage currentCreditAccountInfo = creditAccountInfo[creditAccount];

        cdd.debt = currentCreditAccountInfo.debt; // U:[CM-20]
        cdd.cumulativeIndexLastUpdate = currentCreditAccountInfo.cumulativeIndexLastUpdate; // U:[CM-20]
        cdd.cumulativeIndexNow = IPoolV3(pool).baseInterestIndex(); // U:[CM-20]

        if (task == CollateralCalcTask.GENERIC_PARAMS) {
            return cdd; // U:[CM-20]
        }

        cdd.enabledTokensMask = enabledTokensMask; // U:[CM-21]
        cdd._poolQuotaKeeper = poolQuotaKeeper(); // U:[CM-21]

        uint256[] memory quotasPacked;
        (cdd.quotedTokens, cdd.cumulativeQuotaInterest, quotasPacked, cdd.quotedTokensMask) = _getQuotedTokensData({
            creditAccount: creditAccount,
            enabledTokensMask: enabledTokensMask,
            collateralHints: collateralHints,
            _poolQuotaKeeper: cdd._poolQuotaKeeper
        }); // U:[CM-21]
        cdd.cumulativeQuotaInterest += currentCreditAccountInfo.cumulativeQuotaInterest - 1; // U:[CM-21]

        cdd.accruedInterest = CreditLogic.calcAccruedInterest({
            amount: cdd.debt,
            cumulativeIndexLastUpdate: cdd.cumulativeIndexLastUpdate,
            cumulativeIndexNow: cdd.cumulativeIndexNow
        });
        cdd.accruedFees = currentCreditAccountInfo.quotaFees + cdd.accruedInterest * feeInterest / PERCENTAGE_FACTOR;

        cdd.accruedInterest += cdd.cumulativeQuotaInterest; // U:[CM-21]
        cdd.accruedFees += cdd.cumulativeQuotaInterest * feeInterest / PERCENTAGE_FACTOR; // U:[CM-21]

        if (task == CollateralCalcTask.DEBT_ONLY) {
            return cdd; // U:[CM-21]
        }

        address _priceOracle = priceOracle;

        {
            uint256 totalDebt = _amountWithFee(cdd.calcTotalDebt());
            if (totalDebt != 0) {
                cdd.totalDebtUSD = _convertToUSD(_priceOracle, totalDebt, underlying); // U:[CM-22]
            } else if (task == CollateralCalcTask.FULL_COLLATERAL_CHECK_LAZY) {
                return cdd; // U:[CM-18A]
            }
        }

        uint256 targetUSD = (task == CollateralCalcTask.FULL_COLLATERAL_CHECK_LAZY)
            ? cdd.totalDebtUSD * minHealthFactor / PERCENTAGE_FACTOR
            : type(uint256).max;

        uint256 tokensToDisable;
        (cdd.totalValueUSD, cdd.twvUSD, tokensToDisable) = cdd.calcCollateral({
            creditAccount: creditAccount,
            underlying: underlying,
            twvUSDTarget: targetUSD,
            collateralHints: collateralHints,
            quotasPacked: quotasPacked,
            priceOracle: _priceOracle,
            collateralTokenByMaskFn: _collateralTokenByMask,
            convertToUSDFn: useSafePrices ? _safeConvertToUSD : _convertToUSD
        }); // U:[CM-22]
        cdd.enabledTokensMask = enabledTokensMask.disable(tokensToDisable); // U:[CM-22]

        if (task == CollateralCalcTask.FULL_COLLATERAL_CHECK_LAZY) {
            return cdd;
        }

        cdd.totalValue = _convertFromUSD(_priceOracle, cdd.totalValueUSD, underlying); // U:[CM-22,23]
    }

    /// @dev Returns quotas data for credit manager and credit account
    /// @param creditAccount Credit account to return quotas data for
    /// @param enabledTokensMask Bitmask of account's enabled collateral tokens
    /// @param collateralHints Optional array of token masks specifying tokens order
    /// @param _poolQuotaKeeper Cached quota keeper address
    /// @return quotedTokens Array of quoted tokens enabled as collateral on the account,
    ///         sorted according to `collateralHints` if specified
    /// @return outstandingQuotaInterest Account's quota interest that has not yet been accounted for
    /// @return quotasPacked Array of quotas packed with tokens' LTs
    /// @return _quotedTokensMask The bitmask of all quoted tokens in the credit manager
    function _getQuotedTokensData(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] memory collateralHints,
        address _poolQuotaKeeper
    )
        internal
        view
        returns (
            address[] memory quotedTokens,
            uint128 outstandingQuotaInterest,
            uint256[] memory quotasPacked,
            uint256 _quotedTokensMask
        )
    {
        _quotedTokensMask = quotedTokensMask; // U:[CM-24]

        uint256 tokensToCheckMask = enabledTokensMask & _quotedTokensMask; // U:[CM-24]
        if (tokensToCheckMask == 0) {
            return (quotedTokens, 0, quotasPacked, _quotedTokensMask);
        }

        uint256 tokensIdx;
        uint256 tokensLen = tokensToCheckMask.calcEnabledTokens(); // U:[CM-24]
        quotedTokens = new address[](tokensLen); // U:[CM-24]
        quotasPacked = new uint256[](tokensLen); // U:[CM-24]

        uint256 hintsIdx;
        uint256 hintsLen = collateralHints.length;

        // puts credit account on top of the stack to avoid the "stack too deep" error
        address _creditAccount = creditAccount;

        unchecked {
            while (tokensToCheckMask != 0) {
                uint256 tokenMask;
                if (hintsIdx < hintsLen) {
                    tokenMask = collateralHints[hintsIdx++];
                    if (tokensToCheckMask & tokenMask == 0) continue;
                } else {
                    // mask with only the LSB of `tokensToCheckMask` enabled
                    tokenMask = tokensToCheckMask & uint256(-int256(tokensToCheckMask));
                }

                (address token, uint16 lt) = _collateralTokenByMask({tokenMask: tokenMask, calcLT: true}); // U:[CM-24]

                (uint256 quota, uint128 outstandingInterestDelta) =
                    IPoolQuotaKeeperV3(_poolQuotaKeeper).getQuotaAndOutstandingInterest(_creditAccount, token); // U:[CM-24]

                quotedTokens[tokensIdx] = token; // U:[CM-24]
                quotasPacked[tokensIdx] = CollateralLogic.packQuota(uint96(quota), lt);

                // quota interest is of roughly the same scale as quota, which is stored as `uint96`,
                // thus this addition is very unlikely to overflow and can be unchecked
                outstandingQuotaInterest += outstandingInterestDelta; // U:[CM-24]

                ++tokensIdx;
                tokensToCheckMask = tokensToCheckMask.disable(tokenMask);
            }
        }
    }

    /// @dev Returns total value of funds remaining on the credit account after liquidation, which consists of underlying
    ///      token balance and total value of other enabled tokens remaining after transferring specified tokens
    /// @param creditAccount Account to compute value for
    /// @param enabledTokensMask Bit mask of tokens enabled on the account
    /// @return remainingFunds Remaining funds denominated in underlying
    /// @return underlyingBalance Balance of underlying token
    function _getRemainingFunds(address creditAccount, uint256 enabledTokensMask)
        internal
        view
        returns (uint256 remainingFunds, uint256 underlyingBalance)
    {
        underlyingBalance = IERC20(underlying).safeBalanceOf({account: creditAccount});
        remainingFunds = underlyingBalance;

        uint256 remainingTokensMask = enabledTokensMask.disable(UNDERLYING_TOKEN_MASK);
        if (remainingTokensMask == 0) return (remainingFunds, underlyingBalance);

        address _priceOracle = priceOracle;
        uint256 totalValueUSD;
        while (remainingTokensMask != 0) {
            uint256 tokenMask = remainingTokensMask & uint256(-int256(remainingTokensMask));
            remainingTokensMask ^= tokenMask;

            address token = getTokenByMask(tokenMask);
            uint256 balance = IERC20(token).safeBalanceOf({account: creditAccount});
            if (balance > 1) {
                totalValueUSD += _convertToUSD(_priceOracle, balance, token);
            }
        }

        if (totalValueUSD != 0) {
            remainingFunds += _convertFromUSD(_priceOracle, totalValueUSD, underlying);
        }
    }

    // ------ //
    // QUOTAS //
    // ------ //

    /// @notice Returns address of the quota keeper connected to the pool
    function poolQuotaKeeper() public view override returns (address) {
        return IPoolV3(pool).poolQuotaKeeper(); // U:[CM-47]
    }

    /// @notice Requests quota keeper to update credit account's quota for a given token
    /// @param creditAccount Account to update the quota for
    /// @param token Token to update the quota for
    /// @param quotaChange Requested quota change
    /// @param minQuota Minimum resulting account's quota for token required not to revert
    ///        (set by the user to prevent slippage)
    /// @param maxQuota Maximum resulting account's quota for token required not to revert
    ///        (set by the credit facade to prevent pool's diesel rate manipulation)
    /// @return tokensToEnable Mask of tokens that should be enabled after the operation
    ///         (equals `token`'s mask if changing quota from zero to non-zero value, zero otherwise)
    /// @return tokensToDisable Mask of tokens that should be disabled after the operation
    ///         (equals `token`'s mask if changing quota from non-zero value to zero, zero otherwise)
    /// @dev Accounts with zero debt are not allowed to increase quotas
    function updateQuota(address creditAccount, address token, int96 quotaChange, uint96 minQuota, uint96 maxQuota)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        CreditAccountInfo storage currentCreditAccountInfo = creditAccountInfo[creditAccount];
        if (currentCreditAccountInfo.debt == 0) {
            revert UpdateQuotaOnZeroDebtAccountException();
        }

        (uint128 caInterestChange, uint128 quotaFees, bool enable, bool disable) = IPoolQuotaKeeperV3(poolQuotaKeeper())
            .updateQuota({
            creditAccount: creditAccount,
            token: token,
            requestedChange: quotaChange,
            minQuota: minQuota,
            maxQuota: maxQuota
        }); // U:[CM-25]

        if (enable) {
            tokensToEnable = getTokenMaskOrRevert(token); // U:[CM-25]
        } else if (disable) {
            tokensToDisable = getTokenMaskOrRevert(token); // U:[CM-25]
        }

        currentCreditAccountInfo.cumulativeQuotaInterest += caInterestChange; // U:[CM-25]
        if (quotaFees != 0) {
            currentCreditAccountInfo.quotaFees += quotaFees;
        }
    }

    // --------------------- //
    // CREDIT MANAGER PARAMS //
    // --------------------- //

    /// @notice Returns `token`'s collateral mask in the credit manager
    /// @param token Token address
    /// @return tokenMask Collateral token mask in the credit manager
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function getTokenMaskOrRevert(address token) public view override returns (uint256 tokenMask) {
        if (token == underlying) return UNDERLYING_TOKEN_MASK; // U:[CM-34]

        tokenMask = tokenMasksMapInternal[token]; // U:[CM-34]
        if (tokenMask == 0) revert TokenNotAllowedException(); // U:[CM-34]
    }

    /// @notice Returns collateral token's address by its mask in the credit manager
    /// @param tokenMask Collateral token mask in the credit manager
    /// @return token Token address
    /// @dev Reverts if `tokenMask` doesn't correspond to any known collateral token
    function getTokenByMask(uint256 tokenMask) public view override returns (address token) {
        (token,) = _collateralTokenByMask({tokenMask: tokenMask, calcLT: false}); // U:[CM-34]
    }

    /// @notice Returns collateral token's liquidation threshold
    /// @param token Token address
    /// @return lt Token's liquidation threshold in bps
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function liquidationThresholds(address token) public view override returns (uint16 lt) {
        uint256 tokenMask = getTokenMaskOrRevert(token);
        (, lt) = _collateralTokenByMask({tokenMask: tokenMask, calcLT: true}); // U:[CM-42]
    }

    /// @notice Returns `token`'s liquidation threshold ramp parameters
    /// @param token Token to get parameters for
    /// @return ltInitial LT at the beginning of the ramp in bps
    /// @return ltFinal LT at the end of the ramp in bps
    /// @return timestampRampStart Timestamp of the beginning of the ramp
    /// @return rampDuration Ramp duration in seconds
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function ltParams(address token)
        external
        view
        override
        returns (uint16 ltInitial, uint16 ltFinal, uint40 timestampRampStart, uint24 rampDuration)
    {
        uint256 tokenMask = getTokenMaskOrRevert(token);
        CollateralTokenData memory tokenData = collateralTokensData[tokenMask];

        return (tokenData.ltInitial, tokenData.ltFinal, tokenData.timestampRampStart, tokenData.rampDuration);
    }

    /// @notice Returns collateral token's address and liquidation threshold by its mask
    /// @param tokenMask Collateral token mask in the credit manager
    /// @return token Token address
    /// @return liquidationThreshold Token's liquidation threshold in bps
    /// @dev Reverts if `tokenMask` doesn't correspond to any known collateral token
    function collateralTokenByMask(uint256 tokenMask)
        public
        view
        override
        returns (address token, uint16 liquidationThreshold)
    {
        return _collateralTokenByMask({tokenMask: tokenMask, calcLT: true}); // U:[CM-34, 42]
    }

    /// @dev Returns collateral token's address by its mask, optionally returns its liquidation threshold
    /// @dev Reverts if `tokenMask` doesn't correspond to any known collateral token
    function _collateralTokenByMask(uint256 tokenMask, bool calcLT)
        internal
        view
        returns (address token, uint16 liquidationThreshold)
    {
        if (tokenMask == UNDERLYING_TOKEN_MASK) {
            token = underlying; // U:[CM-34]
            if (calcLT) liquidationThreshold = ltUnderlying; // U:[CM-35]
        } else {
            CollateralTokenData storage tokenData = collateralTokensData[tokenMask]; // U:[CM-34]

            bytes32 rawData;
            assembly {
                rawData := sload(tokenData.slot)
                token := and(rawData, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) // U:[CM-34]
            }

            if (token == address(0)) {
                revert TokenNotAllowedException(); // U:[CM-34]
            }

            if (calcLT) {
                uint16 ltInitial;
                uint16 ltFinal;
                uint40 timestampRampStart;
                uint24 rampDuration;

                assembly {
                    ltInitial := and(shr(160, rawData), 0xFFFF)
                    ltFinal := and(shr(176, rawData), 0xFFFF)
                    timestampRampStart := and(shr(192, rawData), 0xFFFFFFFFFF)
                    rampDuration := and(shr(232, rawData), 0xFFFFFF)
                }

                liquidationThreshold = CreditLogic.getLiquidationThreshold({
                    ltInitial: ltInitial,
                    ltFinal: ltFinal,
                    timestampRampStart: timestampRampStart,
                    rampDuration: rampDuration
                }); // U:[CM-42]
            }
        }
    }

    /// @notice Returns credit manager's fee parameters (all fields in bps)
    /// @return _feeInterest Percentage of accrued interest taken by the protocol as profit
    /// @return _feeLiquidation Percentage of liquidated account value taken by the protocol as profit
    /// @return _liquidationDiscount Percentage of liquidated account value that is used to repay debt
    /// @return _feeLiquidationExpired Percentage of liquidated expired account value taken by the protocol as profit
    /// @return _liquidationDiscountExpired Percentage of liquidated expired account value that is used to repay debt
    function fees()
        external
        view
        override
        returns (
            uint16 _feeInterest,
            uint16 _feeLiquidation,
            uint16 _liquidationDiscount,
            uint16 _feeLiquidationExpired,
            uint16 _liquidationDiscountExpired
        )
    {
        _feeInterest = feeInterest; // U:[CM-41]
        _feeLiquidation = feeLiquidation; // U:[CM-41]
        _liquidationDiscount = liquidationDiscount; // U:[CM-41]
        _feeLiquidationExpired = feeLiquidationExpired; // U:[CM-41]
        _liquidationDiscountExpired = liquidationDiscountExpired; // U:[CM-41]
    }

    // ------------ //
    // ACCOUNT INFO //
    // ------------ //

    /// @notice Returns `creditAccount`'s owner or reverts if account is not opened in this credit manager
    function getBorrowerOrRevert(address creditAccount) public view override returns (address borrower) {
        borrower = creditAccountInfo[creditAccount].borrower; // U:[CM-35]
        if (borrower == address(0)) revert CreditAccountDoesNotExistException(); // U:[CM-35]
    }

    /// @notice Returns `creditAccount`'s flags as a bit mask
    /// @dev Does not revert if `creditAccount` is not opened in this credit manager
    function flagsOf(address creditAccount) public view override returns (uint16) {
        return creditAccountInfo[creditAccount].flags; // U:[CM-35]
    }

    /// @notice Sets `creditAccount`'s flag to a given value
    /// @param creditAccount Account to set a flag for
    /// @param flag Flag to set
    /// @param value The new flag value
    /// @custom:expects Credit facade ensures that `creditAccount` is opened in this credit manager
    function setFlagFor(address creditAccount, uint16 flag, bool value)
        external
        override
        nonReentrant // U:[CM-5]
        creditFacadeOnly // U:[CM-2]
    {
        if (value) {
            _enableFlag(creditAccount, flag); // U:[CM-36]
        } else {
            _disableFlag(creditAccount, flag); // U:[CM-36]
        }
    }

    /// @dev Enables `creditAccount`'s flag
    function _enableFlag(address creditAccount, uint16 flag) internal {
        creditAccountInfo[creditAccount].flags |= flag; // U:[CM-36]
    }

    /// @dev Disables `creditAccount`'s flag
    function _disableFlag(address creditAccount, uint16 flag) internal {
        creditAccountInfo[creditAccount].flags &= ~flag; // U:[CM-36]
    }

    /// @notice Returns `creditAccount`'s enabled tokens mask
    /// @dev Does not revert if `creditAccount` is not opened to this credit manager
    function enabledTokensMaskOf(address creditAccount) public view override returns (uint256) {
        return creditAccountInfo[creditAccount].enabledTokensMask; // U:[CM-37]
    }

    /// @dev Saves `creditAccount`'s `enabledTokensMask` in the storage
    /// @dev Ensures that the number of enabled tokens excluding underlying does not exceed `maxEnabledTokens`
    function _saveEnabledTokensMask(address creditAccount, uint256 enabledTokensMask) internal {
        if (enabledTokensMask.disable(UNDERLYING_TOKEN_MASK).calcEnabledTokens() > maxEnabledTokens) {
            revert TooManyEnabledTokensException(); // U:[CM-37]
        }

        creditAccountInfo[creditAccount].enabledTokensMask = enabledTokensMask; // U:[CM-37]
    }

    /// @notice Returns an array of all credit accounts opened in this credit manager
    function creditAccounts() external view override returns (address[] memory) {
        return creditAccountsSet.values();
    }

    /// @notice Returns chunk of up to `limit` credit accounts opened in this credit manager starting from `offset`
    function creditAccounts(uint256 offset, uint256 limit) external view override returns (address[] memory result) {
        uint256 len = creditAccountsSet.length();
        uint256 resultLen = offset + limit > len ? (offset > len ? 0 : len - offset) : limit;

        result = new address[](resultLen);
        unchecked {
            for (uint256 i = 0; i < resultLen; ++i) {
                result[i] = creditAccountsSet.at(offset + i);
            }
        }
    }

    /// @notice Returns the number of open credit accounts opened in this credit manager
    function creditAccountsLen() external view override returns (uint256) {
        return creditAccountsSet.length();
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Adds `token` to the list of collateral tokens, see `_addToken` for details
    function addToken(address token)
        external
        override
        creditConfiguratorOnly // U:[CM-4]
    {
        _addToken(token); // U:[CM-38, 39]
    }

    /// @dev `addToken` implementation:
    ///      - Ensures that token is not already added
    ///      - Forbids adding more than 255 collateral tokens
    ///      - Adds token with LT = 0
    ///      - Increases the number of collateral tokens
    /// @param token Address of the token to add
    function _addToken(address token) internal {
        if (tokenMasksMapInternal[token] != 0) {
            revert TokenAlreadyAddedException(); // U:[CM-38]
        }
        if (collateralTokensCount >= 255) {
            revert TooManyTokensException(); // U:[CM-38]
        }

        uint256 tokenMask = 1 << collateralTokensCount; // U:[CM-39]
        tokenMasksMapInternal[token] = tokenMask; // U:[CM-39]

        collateralTokensData[tokenMask].token = token; // U:[CM-39]
        collateralTokensData[tokenMask].timestampRampStart = type(uint40).max; // U:[CM-39]

        unchecked {
            ++collateralTokensCount; // U:[CM-39]
        }
    }

    /// @notice Sets credit manager's fee parameters (all fields in bps)
    /// @param _feeInterest Percentage of accrued interest taken by the protocol as profit
    /// @param _feeLiquidation Percentage of liquidated account value taken by the protocol as profit
    /// @param _liquidationDiscount Percentage of liquidated account value that is used to repay debt
    /// @param _feeLiquidationExpired Percentage of liquidated expired account value taken by the protocol as profit
    /// @param _liquidationDiscountExpired Percentage of liquidated expired account value that is used to repay debt
    function setFees(
        uint16 _feeInterest,
        uint16 _feeLiquidation,
        uint16 _liquidationDiscount,
        uint16 _feeLiquidationExpired,
        uint16 _liquidationDiscountExpired
    )
        external
        override
        creditConfiguratorOnly // U:[CM-4]
    {
        feeInterest = _feeInterest; // U:[CM-40]
        feeLiquidation = _feeLiquidation; // U:[CM-40]
        liquidationDiscount = _liquidationDiscount; // U:[CM-40]
        feeLiquidationExpired = _feeLiquidationExpired; // U:[CM-40]
        liquidationDiscountExpired = _liquidationDiscountExpired; // U:[CM-40]
    }

    /// @notice Sets `token`'s liquidation threshold ramp parameters
    /// @param token Token to set parameters for
    /// @param ltInitial LT at the beginning of the ramp in bps
    /// @param ltFinal LT at the end of the ramp in bps
    /// @param timestampRampStart Timestamp of the beginning of the ramp
    /// @param rampDuration Ramp duration in seconds
    /// @dev If `token` is `underlying`, sets LT to `ltInitial` and ignores other parameters
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function setCollateralTokenData(
        address token,
        uint16 ltInitial,
        uint16 ltFinal,
        uint40 timestampRampStart,
        uint24 rampDuration
    )
        external
        override
        creditConfiguratorOnly // U:[CM-4]
    {
        if (token == underlying) {
            ltUnderlying = ltInitial; // U:[CM-42]
        } else {
            uint256 tokenMask = getTokenMaskOrRevert({token: token}); // U:[CM-41]
            CollateralTokenData storage tokenData = collateralTokensData[tokenMask];

            tokenData.ltInitial = ltInitial; // U:[CM-42]
            tokenData.ltFinal = ltFinal; // U:[CM-42]
            tokenData.timestampRampStart = timestampRampStart; // U:[CM-42]
            tokenData.rampDuration = rampDuration; // U:[CM-42]
        }
    }

    /// @notice Sets a new quoted token mask
    /// @param _quotedTokensMask The new quoted tokens mask
    /// @dev Excludes underlying token from the new mask
    function setQuotedMask(uint256 _quotedTokensMask)
        external
        override
        creditConfiguratorOnly // U:[CM-4]
    {
        quotedTokensMask = _quotedTokensMask.disable(UNDERLYING_TOKEN_MASK); // U:[CM-43]
    }

    /// @notice Sets a new max number of enabled tokens
    /// @param _maxEnabledTokens The new max number of enabled tokens
    function setMaxEnabledTokens(uint8 _maxEnabledTokens)
        external
        override
        creditConfiguratorOnly // U: [CM-4]
    {
        maxEnabledTokens = _maxEnabledTokens; // U:[CM-44]
    }

    /// @notice Sets the link between the adapter and the target contract
    /// @param adapter Address of the adapter contract to use to access the third-party contract,
    ///        passing `address(0)` will forbid accessing `targetContract`
    /// @param targetContract Address of the third-pary contract for which the adapter is set,
    ///        passing `address(0)` will forbid using `adapter`
    /// @dev Reverts if `targetContract` or `adapter` is this contract's address
    function setContractAllowance(address adapter, address targetContract)
        external
        override
        creditConfiguratorOnly // U: [CM-4]
    {
        if (targetContract == address(this) || adapter == address(this)) {
            revert TargetContractNotAllowedException();
        } // U:[CM-45]

        if (adapter != address(0)) {
            adapterToContract[adapter] = targetContract; // U:[CM-45]
        }
        if (targetContract != address(0)) {
            contractToAdapter[targetContract] = adapter; // U:[CM-45]
        }
    }

    /// @notice Sets a new credit facade
    /// @param _creditFacade Address of the new credit facade
    function setCreditFacade(address _creditFacade)
        external
        override
        creditConfiguratorOnly // U: [CM-4]
    {
        creditFacade = _creditFacade; // U:[CM-46]
    }

    /// @notice Sets a new price oracle
    /// @param _priceOracle Address of the new price oracle
    function setPriceOracle(address _priceOracle)
        external
        override
        creditConfiguratorOnly // U: [CM-4]
    {
        priceOracle = _priceOracle; // U:[CM-46]
    }

    /// @notice Sets a new credit configurator
    /// @param _creditConfigurator Address of the new credit configurator
    function setCreditConfigurator(address _creditConfigurator)
        external
        override
        creditConfiguratorOnly // U: [CM-4]
    {
        creditConfigurator = _creditConfigurator; // U:[CM-46]
        emit SetCreditConfigurator(_creditConfigurator); // U:[CM-46]
    }

    // --------- //
    // INTERNALS //
    // --------- //

    /// @dev Approves `amount` of `token` from `creditAccount` to `spender`
    /// @dev Reverts if `token` is not recognized as collateral in the credit manager
    function _approveSpender(address creditAccount, address token, address spender, uint256 amount) internal {
        getTokenMaskOrRevert({token: token}); // U:[CM-15]
        ICreditAccountBase(creditAccount).safeApprove({token: token, spender: spender, amount: amount}); // U:[CM-15]
    }

    /// @dev Returns amount of token that should be transferred to receive `amount`
    ///      Pools with fee-on-transfer underlying should override this method
    function _amountWithFee(uint256 amount) internal view virtual returns (uint256) {
        return amount;
    }

    /// @dev Returns amount of token that will be received if `amount` is transferred
    ///      Pools with fee-on-transfer underlying should override this method
    function _amountMinusFee(uint256 amount) internal view virtual returns (uint256) {
        return amount;
    }

    /// @dev Internal wrapper for `creditAccount.execute` call to reduce contract size
    function _execute(address creditAccount, address target, bytes calldata callData) internal returns (bytes memory) {
        return ICreditAccountBase(creditAccount).execute(target, callData);
    }

    /// @dev Internal wrapper for `pool.repayCreditAccount` call to reduce contract size
    function _poolRepayCreditAccount(uint256 debt, uint256 profit, uint256 loss) internal {
        IPoolV3(pool).repayCreditAccount(debt, profit, loss);
    }

    /// @dev Internal wrapper for `pool.lendCreditAccount` call to reduce contract size
    function _poolLendCreditAccount(uint256 amount, address creditAccount) internal {
        IPoolV3(pool).lendCreditAccount(amount, creditAccount); // F:[CM-20]
    }

    /// @dev Internal wrapper for `priceOracle.convertToUSD` call to reduce contract size
    function _convertToUSD(address _priceOracle, uint256 amountInToken, address token)
        internal
        view
        returns (uint256 amountInUSD)
    {
        amountInUSD = IPriceOracleV3(_priceOracle).convertToUSD(amountInToken, token);
    }

    /// @dev Internal wrapper for `priceOracle.convertFromUSD` call to reduce contract size
    function _convertFromUSD(address _priceOracle, uint256 amountInUSD, address token)
        internal
        view
        returns (uint256 amountInToken)
    {
        amountInToken = IPriceOracleV3(_priceOracle).convertFromUSD(amountInUSD, token);
    }

    /// @dev Internal wrapper for `priceOracle.safeConvertToUSD` call to reduce contract size
    /// @dev `underlying` is always converted with default conversion function
    function _safeConvertToUSD(address _priceOracle, uint256 amountInToken, address token)
        internal
        view
        returns (uint256 amountInUSD)
    {
        amountInUSD = (token == underlying)
            ? _convertToUSD(_priceOracle, amountInToken, token)
            : IPriceOracleV3(_priceOracle).safeConvertToUSD(amountInToken, token);
    }

    /// @dev Reverts if `msg.sender` is not the credit facade
    function _checkCreditFacade() private view {
        if (msg.sender != creditFacade) revert CallerNotCreditFacadeException();
    }

    /// @dev Reverts if `msg.sender` is not the credit configurator
    function _checkCreditConfigurator() private view {
        if (msg.sender != creditConfigurator) revert CallerNotConfiguratorException();
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

import { AdapterType } from "@gearbox-protocol/sdk-gov/contracts/AdapterType.sol";

/// @title Adapter interface
interface IAdapter {
    function _gearboxAdapterType() external view returns (AdapterType);

    function _gearboxAdapterVersion() external view returns (uint16);

    function creditManager() external view returns (address);

    function addressProvider() external view returns (address);

    function targetContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

enum AllowanceAction {
    FORBID,
    ALLOW
}

/// @notice Struct with credit manager configuration parameters
/// @param minDebt Minimum debt amount per account
/// @param maxDebt Maximum debt amount per account
/// @param degenNFT Whether to apply Degen NFT whitelist logic
/// @param expirable Whether facade must be expirable
/// @param name Credit manager name
struct CreditManagerOpts {
    uint128 minDebt;
    uint128 maxDebt;
    address degenNFT;
    bool expirable;
    string name;
}

interface ICreditConfiguratorV3Events {
    // ------ //
    // TOKENS //
    // ------ //

    /// @notice Emitted when a token is made recognizable as collateral in the credit manager
    event AddCollateralToken(address indexed token);

    /// @notice Emitted when a new collateral token liquidation threshold is set
    event SetTokenLiquidationThreshold(address indexed token, uint16 liquidationThreshold);

    /// @notice Emitted when a collateral token liquidation threshold ramping is scheduled
    event ScheduleTokenLiquidationThresholdRamp(
        address indexed token,
        uint16 liquidationThresholdInitial,
        uint16 liquidationThresholdFinal,
        uint40 timestampRampStart,
        uint40 timestampRampEnd
    );

    /// @notice Emitted when a collateral token is forbidden
    event ForbidToken(address indexed token);

    /// @notice Emitted when a previously forbidden collateral token is allowed
    event AllowToken(address indexed token);

    /// @notice Emitted when a token is made quoted
    event QuoteToken(address indexed token);

    // -------- //
    // ADAPTERS //
    // -------- //

    /// @notice Emitted when a new adapter and its target contract are allowed in the credit manager
    event AllowAdapter(address indexed targetContract, address indexed adapter);

    /// @notice Emitted when adapter and its target contract are forbidden in the credit manager
    event ForbidAdapter(address indexed targetContract, address indexed adapter);

    // -------------- //
    // CREDIT MANAGER //
    // -------------- //

    /// @notice Emitted when a new maximum number of enabled tokens is set in the credit manager
    event SetMaxEnabledTokens(uint8 maxEnabledTokens);

    /// @notice Emitted when new fee parameters are set in the credit manager
    event UpdateFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationPremium,
        uint16 feeLiquidationExpired,
        uint16 liquidationPremiumExpired
    );

    // -------- //
    // UPGRADES //
    // -------- //

    /// @notice Emitted when a new price oracle is set in the credit manager
    event SetPriceOracle(address indexed priceOracle);

    /// @notice Emitted when a new bot list is set in the credit facade
    event SetBotList(address indexed botList);

    /// @notice Emitted when a new facade is connected to the credit manager
    event SetCreditFacade(address indexed creditFacade);

    /// @notice Emitted when credit manager's configurator contract is upgraded
    event CreditConfiguratorUpgraded(address indexed creditConfigurator);

    // ------------- //
    // CREDIT FACADE //
    // ------------- //

    /// @notice Emitted when new debt principal limits are set
    event SetBorrowingLimits(uint256 minDebt, uint256 maxDebt);

    /// @notice Emitted when a new max debt per block multiplier is set
    event SetMaxDebtPerBlockMultiplier(uint8 maxDebtPerBlockMultiplier);

    /// @notice Emitted when a new max cumulative loss is set
    event SetMaxCumulativeLoss(uint128 maxCumulativeLoss);

    /// @notice Emitted when cumulative loss is reset to zero in the credit facade
    event ResetCumulativeLoss();

    /// @notice Emitted when a new expiration timestamp is set in the credit facade
    event SetExpirationDate(uint40 expirationDate);

    /// @notice Emitted when an address is added to the list of emergency liquidators
    event AddEmergencyLiquidator(address indexed liquidator);

    /// @notice Emitted when an address is removed from the list of emergency liquidators
    event RemoveEmergencyLiquidator(address indexed liquidator);
}

/// @title Credit configurator V3 interface
interface ICreditConfiguratorV3 is IVersion, ICreditConfiguratorV3Events {
    function addressProvider() external view returns (address);

    function creditManager() external view returns (address);

    function creditFacade() external view returns (address);

    function underlying() external view returns (address);

    // ------ //
    // TOKENS //
    // ------ //

    function addCollateralToken(address token, uint16 liquidationThreshold) external;

    function setLiquidationThreshold(address token, uint16 liquidationThreshold) external;

    function rampLiquidationThreshold(
        address token,
        uint16 liquidationThresholdFinal,
        uint40 rampStart,
        uint24 rampDuration
    ) external;

    function forbidToken(address token) external;

    function allowToken(address token) external;

    function makeTokenQuoted(address token) external;

    // -------- //
    // ADAPTERS //
    // -------- //

    function allowedAdapters() external view returns (address[] memory);

    function allowAdapter(address adapter) external;

    function forbidAdapter(address adapter) external;

    // -------------- //
    // CREDIT MANAGER //
    // -------------- //

    function setFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationPremium,
        uint16 feeLiquidationExpired,
        uint16 liquidationPremiumExpired
    ) external;

    function setMaxEnabledTokens(uint8 newMaxEnabledTokens) external;

    // -------- //
    // UPGRADES //
    // -------- //

    function setPriceOracle(uint256 newVersion) external;

    function setBotList(uint256 newVersion) external;

    function setCreditFacade(address newCreditFacade, bool migrateParams) external;

    function upgradeCreditConfigurator(address newCreditConfigurator) external;

    // ------------- //
    // CREDIT FACADE //
    // ------------- //

    function setMinDebtLimit(uint128 newMinDebt) external;

    function setMaxDebtLimit(uint128 newMaxDebt) external;

    function setMaxDebtPerBlockMultiplier(uint8 newMaxDebtLimitPerBlockMultiplier) external;

    function forbidBorrowing() external;

    function setMaxCumulativeLoss(uint128 newMaxCumulativeLoss) external;

    function resetCumulativeLoss() external;

    function setExpirationDate(uint40 newExpirationDate) external;

    function emergencyLiquidators() external view returns (address[] memory);

    function addEmergencyLiquidator(address liquidator) external;

    function removeEmergencyLiquidator(address liquidator) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IVersion } from "./IVersion.sol";

/// @title Price oracle base interface
/// @notice Functions shared accross newer and older versions
interface IPriceOracleBase is IVersion {
    function getPrice(address token) external view returns (uint256);

    function convertToUSD(
        uint256 amount,
        address token
    ) external view returns (uint256);

    function convertFromUSD(
        uint256 amount,
        address token
    ) external view returns (uint256);

    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) external view returns (uint256);

    function priceFeeds(
        address token
    ) external view returns (address priceFeed);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

struct TokenQuotaParams {
    uint16 rate;
    uint192 cumulativeIndexLU;
    uint16 quotaIncreaseFee;
    uint96 totalQuoted;
    uint96 limit;
}

struct AccountQuota {
    uint96 quota;
    uint192 cumulativeIndexLU;
}

interface IPoolQuotaKeeperV3Events {
    /// @notice Emitted when account's quota for a token is updated
    event UpdateQuota(address indexed creditAccount, address indexed token, int96 quotaChange);

    /// @notice Emitted when token's quota rate is updated
    event UpdateTokenQuotaRate(address indexed token, uint16 rate);

    /// @notice Emitted when the gauge is updated
    event SetGauge(address indexed newGauge);

    /// @notice Emitted when a new credit manager is allowed
    event AddCreditManager(address indexed creditManager);

    /// @notice Emitted when a new token is added as quoted
    event AddQuotaToken(address indexed token);

    /// @notice Emitted when a new total quota limit is set for a token
    event SetTokenLimit(address indexed token, uint96 limit);

    /// @notice Emitted when a new one-time quota increase fee is set for a token
    event SetQuotaIncreaseFee(address indexed token, uint16 fee);
}

/// @title Pool quota keeper V3 interface
interface IPoolQuotaKeeperV3 is IPoolQuotaKeeperV3Events, IVersion {
    function pool() external view returns (address);

    function underlying() external view returns (address);

    // ----------------- //
    // QUOTAS MANAGEMENT //
    // ----------------- //

    function updateQuota(address creditAccount, address token, int96 requestedChange, uint96 minQuota, uint96 maxQuota)
        external
        returns (uint128 caQuotaInterestChange, uint128 fees, bool enableToken, bool disableToken);

    function removeQuotas(address creditAccount, address[] calldata tokens, bool setLimitsToZero) external;

    function accrueQuotaInterest(address creditAccount, address[] calldata tokens) external;

    function getQuotaRate(address) external view returns (uint16);

    function cumulativeIndex(address token) external view returns (uint192);

    function isQuotedToken(address token) external view returns (bool);

    function getQuota(address creditAccount, address token)
        external
        view
        returns (uint96 quota, uint192 cumulativeIndexLU);

    function getTokenQuotaParams(address token)
        external
        view
        returns (
            uint16 rate,
            uint192 cumulativeIndexLU,
            uint16 quotaIncreaseFee,
            uint96 totalQuoted,
            uint96 limit,
            bool isActive
        );

    function getQuotaAndOutstandingInterest(address creditAccount, address token)
        external
        view
        returns (uint96 quoted, uint128 outstandingInterest);

    function poolQuotaRevenue() external view returns (uint256);

    function lastQuotaRateUpdate() external view returns (uint40);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function gauge() external view returns (address);

    function setGauge(address _gauge) external;

    function creditManagers() external view returns (address[] memory);

    function addCreditManager(address _creditManager) external;

    function quotedTokens() external view returns (address[] memory);

    function addQuotaToken(address token) external;

    function updateRates() external;

    function setTokenLimit(address token, uint96 limit) external;

    function setTokenQuotaIncreaseFee(address token, uint16 fee) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint256 constant NO_VERSION_CONTROL = 0;

bytes32 constant AP_CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant AP_ACL = "ACL";
bytes32 constant AP_PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant AP_ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant AP_DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant AP_TREASURY = "TREASURY";
bytes32 constant AP_GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant AP_WETH_TOKEN = "WETH_TOKEN";
bytes32 constant AP_WETH_GATEWAY = "WETH_GATEWAY";
bytes32 constant AP_ROUTER = "ROUTER";
bytes32 constant AP_BOT_LIST = "BOT_LIST";
bytes32 constant AP_GEAR_STAKING = "GEAR_STAKING";
bytes32 constant AP_ZAPPER_REGISTER = "ZAPPER_REGISTER";

interface IAddressProviderV3Events {
    /// @notice Emitted when an address is set for a contract key
    event SetAddress(bytes32 indexed key, address indexed value, uint256 indexed version);
}

/// @title Address provider V3 interface
interface IAddressProviderV3 is IAddressProviderV3Events, IVersion {
    function addresses(bytes32 key, uint256 _version) external view returns (address);

    function getAddressOrRevert(bytes32 key, uint256 _version) external view returns (address result);

    function setAddress(bytes32 key, address value, bool saveVersion) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IACLExceptions {
    /// @dev Thrown when attempting to delete an address from a set that is not a pausable admin
    error AddressNotPausableAdminException(address addr);

    /// @dev Thrown when attempting to delete an address from a set that is not a unpausable admin
    error AddressNotUnpausableAdminException(address addr);
}

interface IACLEvents {
    /// @dev Emits when a new admin is added that can pause contracts
    event PausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when a Pausable admin is removed
    event PausableAdminRemoved(address indexed admin);

    /// @dev Emits when a new admin is added that can unpause contracts
    event UnpausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when an Unpausable admin is removed
    event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IACLExceptions, IVersion {
    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account) external view returns (bool);

    /// @dev Returns address of configurator
    function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";

import {AP_ACL, IAddressProviderV3, NO_VERSION_CONTROL} from "../interfaces/IAddressProviderV3.sol";
import {CallerNotConfiguratorException} from "../interfaces/IExceptions.sol";

import {SanityCheckTrait} from "./SanityCheckTrait.sol";

/// @title ACL trait
/// @notice Utility class for ACL (access-control list) consumers
abstract contract ACLTrait is SanityCheckTrait {
    /// @notice ACL contract address
    address public immutable acl;

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) nonZeroAddress(addressProvider) {
        acl = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_ACL, NO_VERSION_CONTROL);
    }

    /// @dev Ensures that function caller has configurator role
    modifier configuratorOnly() {
        _ensureCallerIsConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not the configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsConfigurator() internal view {
        if (!_isConfigurator({account: msg.sender})) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Checks whether given account has configurator role
    function _isConfigurator(address account) internal view returns (bool) {
        return IACL(acl).isConfigurator(account);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/// @title Reentrancy guard trait
/// @notice Same as OpenZeppelin's `ReentrancyGuard` but only uses 1 byte of storage instead of 32
abstract contract ReentrancyGuardTrait {
    uint8 internal _reentrancyStatus = NOT_ENTERED;

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and making it call a
    /// `private` function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        _ensureNotEntered();

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = NOT_ENTERED;
    }

    /// @dev Reverts if the contract is currently entered
    /// @dev Used to cut contract size on modifiers
    function _ensureNotEntered() internal view {
        require(_reentrancyStatus != ENTERED, "ReentrancyGuard: reentrant call");
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../interfaces/IPermit2.sol";
import "../interfaces/IWETH.sol";
import "../libraries/RevertReasonForwarder.sol";

/// @title Implements efficient safe methods for ERC20 interface.
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();
    error Permit2TransferAmountTooHigh();

    address private constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    bytes4 private constant _PERMIT_LENGTH_ERROR = 0x68275857;  // SafePermitBadLength.selector
    uint256 private constant _RAW_CALL_GAS_LIMIT = 5000;

    function safeBalanceOf(
        IERC20 token,
        address account
    ) internal view returns(uint256 tokenBalance) {
        bytes4 selector = IERC20.balanceOf.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            mstore(0x00, selector)
            mstore(0x04, account)
            let success := staticcall(gas(), token, 0x00, 0x24, 0x00, 0x20)
            tokenBalance := mload(0)

            if or(iszero(success), lt(returndatasize(), 0x20)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransferFromUniversal(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        bool permit2
    ) internal {
        if (permit2) {
            safeTransferFromPermit2(token, from, to, amount);
        } else {
            safeTransferFrom(token, from, to, amount);
        }
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /// @dev Permit2 version of safeTransferFrom above.
    function safeTransferFromPermit2(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > type(uint160).max) revert Permit2TransferAmountTooHigh();
        bytes4 selector = IPermit2.transferFrom.selector;
        bool success;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            mstore(add(data, 0x64), token)
            success := call(gas(), _PERMIT2, 0, data, 0x84, 0x0, 0x0)
            if success {
                success := gt(extcodesize(_PERMIT2), 0)
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /// @dev If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry.
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /// @dev Allowance increase with safe math check.
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /// @dev Allowance decrease with safe math check.
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        if (!tryPermit(token, msg.sender, address(this), permit)) RevertReasonForwarder.reRevert();
    }

    function safePermit(IERC20 token, address owner, address spender, bytes calldata permit) internal {
        if (!tryPermit(token, owner, spender, permit)) RevertReasonForwarder.reRevert();
    }

    function tryPermit(IERC20 token, bytes calldata permit) internal returns(bool success) {
        return tryPermit(token, msg.sender, address(this), permit);
    }

    function tryPermit(IERC20 token, address owner, address spender, bytes calldata permit) internal returns(bool success) {
        bytes4 permitSelector = IERC20Permit.permit.selector;
        bytes4 daiPermitSelector = IDaiLikePermit.permit.selector;
        bytes4 permit2Selector = IPermit2.permit.selector;
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            switch permit.length
            case 100 {
                mstore(ptr, permitSelector)
                mstore(add(ptr, 0x04), owner)
                mstore(add(ptr, 0x24), spender)

                // Compact IERC20Permit.permit(uint256 value, uint32 deadline, uint256 r, uint256 vs)
                {  // stack too deep
                    let deadline := shr(224, calldataload(add(permit.offset, 0x20)))
                    let vs := calldataload(add(permit.offset, 0x44))

                    calldatacopy(add(ptr, 0x44), permit.offset, 0x20) // value
                    mstore(add(ptr, 0x64), sub(deadline, 1))
                    mstore(add(ptr, 0x84), add(27, shr(255, vs)))
                    calldatacopy(add(ptr, 0xa4), add(permit.offset, 0x24), 0x20) // r
                    mstore(add(ptr, 0xc4), shr(1, shl(1, vs)))
                }
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            case 72 {
                mstore(ptr, daiPermitSelector)
                mstore(add(ptr, 0x04), owner)
                mstore(add(ptr, 0x24), spender)

                // Compact IDaiLikePermit.permit(uint32 nonce, uint32 expiry, uint256 r, uint256 vs)
                {  // stack too deep
                    let expiry := shr(224, calldataload(add(permit.offset, 0x04)))
                    let vs := calldataload(add(permit.offset, 0x28))

                    mstore(add(ptr, 0x44), shr(224, calldataload(permit.offset)))
                    mstore(add(ptr, 0x64), sub(expiry, 1))
                    mstore(add(ptr, 0x84), true)
                    mstore(add(ptr, 0xa4), add(27, shr(255, vs)))
                    calldatacopy(add(ptr, 0xc4), add(permit.offset, 0x08), 0x20) // r
                    mstore(add(ptr, 0xe4), shr(1, shl(1, vs)))
                }
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            case 224 {
                mstore(ptr, permitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length)
                // IERC20Permit.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0xe4, 0, 0)
            }
            case 256 {
                mstore(ptr, daiPermitSelector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length)
                // IDaiLikePermit.permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s)
                success := call(gas(), token, 0, ptr, 0x104, 0, 0)
            }
            case 96 {
                // Compact IPermit2.permit(uint160 amount, uint32 expiration, uint32 nonce, uint32 sigDeadline, uint256 r, uint256 vs)
                mstore(ptr, permit2Selector)
                mstore(add(ptr, 0x04), owner)
                mstore(add(ptr, 0x24), token)
                calldatacopy(add(ptr, 0x50), permit.offset, 0x14) // amount
                mstore(add(ptr, 0x64), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x14))), 1))) // expiration
                mstore(add(ptr, 0x84), shr(224, calldataload(add(permit.offset, 0x18)))) // nonce
                mstore(add(ptr, 0xa4), spender)
                mstore(add(ptr, 0xc4), and(0xffffffffffff, sub(shr(224, calldataload(add(permit.offset, 0x1c))), 1))) // sigDeadline
                mstore(add(ptr, 0xe4), 0x100)
                mstore(add(ptr, 0x104), 0x40)
                calldatacopy(add(ptr, 0x124), add(permit.offset, 0x20), 0x20) // r
                calldatacopy(add(ptr, 0x144), add(permit.offset, 0x40), 0x20) // vs
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            case 352 {
                mstore(ptr, permit2Selector)
                calldatacopy(add(ptr, 0x04), permit.offset, permit.length)
                // IPermit2.permit(address owner, PermitSingle calldata permitSingle, bytes calldata signature)
                success := call(gas(), _PERMIT2, 0, ptr, 0x164, 0, 0)
            }
            default {
                mstore(ptr, _PERMIT_LENGTH_ERROR)
                revert(ptr, 4)
            }
        }
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function safeDeposit(IWETH weth, uint256 amount) internal {
        if (amount > 0) {
            bytes4 selector = IWETH.deposit.selector;
            assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
                mstore(0, selector)
                if iszero(call(gas(), weth, amount, 0, 4, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function safeWithdraw(IWETH weth, uint256 amount) internal {
        bytes4 selector = IWETH.withdraw.selector;
        assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
            mstore(0, selector)
            mstore(4, amount)
            if iszero(call(gas(), weth, 0, 0, 0x24, 0, 0)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }

    function safeWithdrawTo(IWETH weth, uint256 amount, address to) internal {
        safeWithdraw(weth, amount);
        if (to != address(this)) {
            assembly ("memory-safe") {  // solhint-disable-line no-inline-assembly
                if iszero(call(_RAW_CALL_GAS_LIMIT, to, amount, 0, 0, 0, 0)) {
                    let ptr := mload(0x40)
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {BitMask} from "./BitMask.sol";

import {Balance} from "@gearbox-protocol/core-v2/contracts/libraries/Balances.sol";

struct BalanceWithMask {
    address token;
    uint256 tokenMask;
    uint256 balance;
}

struct BalanceDelta {
    address token;
    int256 amount;
}

enum Comparison {
    GREATER,
    LESS
}

/// @title Balances logic library
/// @notice Implements functions for before-and-after balance comparisons
library BalancesLogic {
    using BitMask for uint256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /// @dev Compares current `token` balance with `value`
    /// @param token Token to check balance for
    /// @param value Value to compare current token balance with
    /// @param comparison Whether current balance must be greater/less than or equal to `value`
    function checkBalance(address creditAccount, address token, uint256 value, Comparison comparison)
        internal
        view
        returns (bool)
    {
        uint256 current = IERC20(token).safeBalanceOf(creditAccount);
        return (comparison == Comparison.GREATER && current >= value)
            || (comparison == Comparison.LESS && current <= value); // U:[BLL-1]
    }

    /// @dev Returns an array of expected token balances after operations
    /// @param creditAccount Credit account to compute balances for
    /// @param deltas Array of expected token balance changes
    function storeBalances(address creditAccount, BalanceDelta[] memory deltas)
        internal
        view
        returns (Balance[] memory balances)
    {
        uint256 len = deltas.length;
        balances = new Balance[](len); // U:[BLL-2]
        for (uint256 i = 0; i < len;) {
            int256 balance = IERC20(deltas[i].token).safeBalanceOf(creditAccount).toInt256();
            balances[i] = Balance({token: deltas[i].token, balance: (balance + deltas[i].amount).toUint256()}); // U:[BLL-2]
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Compares current balances with the previously stored ones
    /// @param creditAccount Credit account to compare balances for
    /// @param balances Array of previously stored balances
    /// @param comparison Whether current balances must be greater/less than or equal to stored ones
    /// @return success True if condition specified by `comparison` holds for all tokens, false otherwise
    function compareBalances(address creditAccount, Balance[] memory balances, Comparison comparison)
        internal
        view
        returns (bool success)
    {
        uint256 len = balances.length;
        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                if (!BalancesLogic.checkBalance(creditAccount, balances[i].token, balances[i].balance, comparison)) {
                    return false; // U:[BLL-3]
                }
            }
        }
        return true; // U:[BLL-3]
    }

    /// @dev Returns balances of specified tokens on the credit account
    /// @param creditAccount Credit account to compute balances for
    /// @param tokensMask Bit mask of tokens to compute balances for
    /// @param getTokenByMaskFn Function that returns token's address by its mask
    function storeBalances(
        address creditAccount,
        uint256 tokensMask,
        function (uint256) view returns (address) getTokenByMaskFn
    ) internal view returns (BalanceWithMask[] memory balances) {
        if (tokensMask == 0) return balances;

        balances = new BalanceWithMask[](tokensMask.calcEnabledTokens()); // U:[BLL-4]
        unchecked {
            uint256 i;
            while (tokensMask != 0) {
                uint256 tokenMask = tokensMask & uint256(-int256(tokensMask));
                tokensMask ^= tokenMask;

                address token = getTokenByMaskFn(tokenMask);
                balances[i] = BalanceWithMask({
                    token: token,
                    tokenMask: tokenMask,
                    balance: IERC20(token).safeBalanceOf(creditAccount)
                }); // U:[BLL-4]
                ++i;
            }
        }
    }

    /// @dev Compares current balances of specified tokens with the previously stored ones
    /// @param creditAccount Credit account to compare balances for
    /// @param tokensMask Bit mask of tokens to compare balances for
    /// @param balances Array of previously stored balances
    /// @param comparison Whether current balances must be greater/less than or equal to stored ones
    /// @return success True if condition specified by `comparison` holds for all tokens, false otherwise
    function compareBalances(
        address creditAccount,
        uint256 tokensMask,
        BalanceWithMask[] memory balances,
        Comparison comparison
    ) internal view returns (bool) {
        if (tokensMask == 0) return true;

        unchecked {
            uint256 len = balances.length;
            for (uint256 i; i < len; ++i) {
                if (tokensMask & balances[i].tokenMask != 0) {
                    if (!BalancesLogic.checkBalance(creditAccount, balances[i].token, balances[i].balance, comparison))
                    {
                        return false; // U:[BLL-5]
                    }
                }
            }
        }
        return true; // U:[BLL-5]
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {MultiCall} from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";
import "./ICreditFacadeV3Multicall.sol";
import {AllowanceAction} from "../interfaces/ICreditConfiguratorV3.sol";

/// @notice Debt limits packed into a single slot
/// @param minDebt Minimum debt amount per credit account
/// @param maxDebt Maximum debt amount per credit account
struct DebtLimits {
    uint128 minDebt;
    uint128 maxDebt;
}

/// @notice Info on bad debt liquidation losses packed into a single slot
/// @param currentCumulativeLoss Current cumulative loss from bad debt liquidations
/// @param maxCumulativeLoss Max cumulative loss incurred before the facade gets paused
struct CumulativeLossParams {
    uint128 currentCumulativeLoss;
    uint128 maxCumulativeLoss;
}

/// @notice Collateral check params
/// @param collateralHints Optional array of token masks to check first to reduce the amount of computation
///        when known subset of account's collateral tokens covers all the debt
/// @param minHealthFactor Min account's health factor in bps in order not to revert
/// @param enabledTokensMaskAfter Bitmask of account's enabled collateral tokens after the multicall
/// @param revertOnForbiddenTokens Whether to revert on enabled forbidden tokens after the multicall
/// @param useSafePrices Whether to use safe pricing (min of main and reserve feeds) when evaluating collateral
struct FullCheckParams {
    uint256[] collateralHints;
    uint16 minHealthFactor;
    uint256 enabledTokensMaskAfter;
    bool revertOnForbiddenTokens;
    bool useSafePrices;
}

interface ICreditFacadeV3Events {
    /// @notice Emitted when a new credit account is opened
    event OpenCreditAccount(
        address indexed creditAccount, address indexed onBehalfOf, address indexed caller, uint256 referralCode
    );

    /// @notice Emitted when account is closed
    event CloseCreditAccount(address indexed creditAccount, address indexed borrower);

    /// @notice Emitted when account is liquidated
    event LiquidateCreditAccount(
        address indexed creditAccount, address indexed liquidator, address to, uint256 remainingFunds
    );

    /// @notice Emitted when account's debt is increased
    event IncreaseDebt(address indexed creditAccount, uint256 amount);

    /// @notice Emitted when account's debt is decreased
    event DecreaseDebt(address indexed creditAccount, uint256 amount);

    /// @notice Emitted when collateral is added to account
    event AddCollateral(address indexed creditAccount, address indexed token, uint256 amount);

    /// @notice Emitted when collateral is withdrawn from account
    event WithdrawCollateral(address indexed creditAccount, address indexed token, uint256 amount, address to);

    /// @notice Emitted when a multicall is started
    event StartMultiCall(address indexed creditAccount, address indexed caller);

    /// @notice Emitted when a call from account to an external contract is made during a multicall
    event Execute(address indexed creditAccount, address indexed targetContract);

    /// @notice Emitted when a multicall is finished
    event FinishMultiCall();
}

/// @title Credit facade V3 interface
interface ICreditFacadeV3 is IVersion, ICreditFacadeV3Events {
    function creditManager() external view returns (address);

    function degenNFT() external view returns (address);

    function weth() external view returns (address);

    function botList() external view returns (address);

    function maxDebtPerBlockMultiplier() external view returns (uint8);

    function maxQuotaMultiplier() external view returns (uint256);

    function expirable() external view returns (bool);

    function expirationDate() external view returns (uint40);

    function debtLimits() external view returns (uint128 minDebt, uint128 maxDebt);

    function lossParams() external view returns (uint128 currentCumulativeLoss, uint128 maxCumulativeLoss);

    function forbiddenTokenMask() external view returns (uint256);

    function canLiquidateWhilePaused(address) external view returns (bool);

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    function openCreditAccount(address onBehalfOf, MultiCall[] calldata calls, uint256 referralCode)
        external
        payable
        returns (address creditAccount);

    function closeCreditAccount(address creditAccount, MultiCall[] calldata calls) external payable;

    function liquidateCreditAccount(address creditAccount, address to, MultiCall[] calldata calls) external;

    function multicall(address creditAccount, MultiCall[] calldata calls) external payable;

    function botMulticall(address creditAccount, MultiCall[] calldata calls) external;

    function setBotPermissions(address creditAccount, address bot, uint192 permissions) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setExpirationDate(uint40 newExpirationDate) external;

    function setDebtLimits(uint128 newMinDebt, uint128 newMaxDebt, uint8 newMaxDebtPerBlockMultiplier) external;

    function setBotList(address newBotList) external;

    function setCumulativeLossParams(uint128 newMaxCumulativeLoss, bool resetCumulativeLoss) external;

    function setTokenAllowance(address token, AllowanceAction allowance) external;

    function setEmergencyLiquidator(address liquidator, AllowanceAction allowance) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint8 constant BOT_PERMISSIONS_SET_FLAG = 1;

uint8 constant DEFAULT_MAX_ENABLED_TOKENS = 4;
address constant INACTIVE_CREDIT_ACCOUNT_ADDRESS = address(1);

/// @notice Debt management type
///         - `INCREASE_DEBT` borrows additional funds from the pool, updates account's debt and cumulative interest index
///         - `DECREASE_DEBT` repays debt components (quota interest and fees -> base interest and fees -> debt principal)
///           and updates all corresponding state varibles (base interest index, quota interest and fees, debt).
///           When repaying all the debt, ensures that account has no enabled quotas.
enum ManageDebtAction {
    INCREASE_DEBT,
    DECREASE_DEBT
}

/// @notice Collateral/debt calculation mode
///         - `GENERIC_PARAMS` returns generic data like account debt and cumulative indexes
///         - `DEBT_ONLY` is same as `GENERIC_PARAMS` but includes more detailed debt info, like accrued base/quota
///           interest and fees
///         - `FULL_COLLATERAL_CHECK_LAZY` checks whether account is sufficiently collateralized in a lazy fashion,
///           i.e. it stops iterating over collateral tokens once TWV reaches the desired target.
///           Since it may return underestimated TWV, it's only available for internal use.
///         - `DEBT_COLLATERAL` is same as `DEBT_ONLY` but also returns total value and total LT-weighted value of
///           account's tokens, this mode is used during account liquidation
///         - `DEBT_COLLATERAL_SAFE_PRICES` is same as `DEBT_COLLATERAL` but uses safe prices from price oracle
enum CollateralCalcTask {
    GENERIC_PARAMS,
    DEBT_ONLY,
    FULL_COLLATERAL_CHECK_LAZY,
    DEBT_COLLATERAL,
    DEBT_COLLATERAL_SAFE_PRICES
}

struct CreditAccountInfo {
    uint256 debt;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint128 quotaFees;
    uint256 enabledTokensMask;
    uint16 flags;
    uint64 lastDebtUpdate;
    address borrower;
}

struct CollateralDebtData {
    uint256 debt;
    uint256 cumulativeIndexNow;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint256 accruedInterest;
    uint256 accruedFees;
    uint256 totalDebtUSD;
    uint256 totalValue;
    uint256 totalValueUSD;
    uint256 twvUSD;
    uint256 enabledTokensMask;
    uint256 quotedTokensMask;
    address[] quotedTokens;
    address _poolQuotaKeeper;
}

struct CollateralTokenData {
    address token;
    uint16 ltInitial;
    uint16 ltFinal;
    uint40 timestampRampStart;
    uint24 rampDuration;
}

struct RevocationPair {
    address spender;
    address token;
}

interface ICreditManagerV3Events {
    /// @notice Emitted when new credit configurator is set
    event SetCreditConfigurator(address indexed newConfigurator);
}

/// @title Credit manager V3 interface
interface ICreditManagerV3 is IVersion, ICreditManagerV3Events {
    function pool() external view returns (address);

    function underlying() external view returns (address);

    function creditFacade() external view returns (address);

    function creditConfigurator() external view returns (address);

    function addressProvider() external view returns (address);

    function accountFactory() external view returns (address);

    function name() external view returns (string memory);

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    function openCreditAccount(address onBehalfOf) external returns (address);

    function closeCreditAccount(address creditAccount) external;

    function liquidateCreditAccount(
        address creditAccount,
        CollateralDebtData calldata collateralDebtData,
        address to,
        bool isExpired
    ) external returns (uint256 remainingFunds, uint256 loss);

    function manageDebt(address creditAccount, uint256 amount, uint256 enabledTokensMask, ManageDebtAction action)
        external
        returns (uint256 newDebt, uint256 tokensToEnable, uint256 tokensToDisable);

    function addCollateral(address payer, address creditAccount, address token, uint256 amount)
        external
        returns (uint256 tokensToEnable);

    function withdrawCollateral(address creditAccount, address token, uint256 amount, address to)
        external
        returns (uint256 tokensToDisable);

    function externalCall(address creditAccount, address target, bytes calldata callData)
        external
        returns (bytes memory result);

    function approveToken(address creditAccount, address token, address spender, uint256 amount) external;

    function revokeAdapterAllowances(address creditAccount, RevocationPair[] calldata revocations) external;

    // -------- //
    // ADAPTERS //
    // -------- //

    function adapterToContract(address adapter) external view returns (address targetContract);

    function contractToAdapter(address targetContract) external view returns (address adapter);

    function execute(bytes calldata data) external returns (bytes memory result);

    function approveCreditAccount(address token, uint256 amount) external;

    function setActiveCreditAccount(address creditAccount) external;

    function getActiveCreditAccountOrRevert() external view returns (address creditAccount);

    // ----------------- //
    // COLLATERAL CHECKS //
    // ----------------- //

    function priceOracle() external view returns (address);

    function fullCollateralCheck(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] calldata collateralHints,
        uint16 minHealthFactor,
        bool useSafePrices
    ) external returns (uint256 enabledTokensMaskAfter);

    function isLiquidatable(address creditAccount, uint16 minHealthFactor) external view returns (bool);

    function calcDebtAndCollateral(address creditAccount, CollateralCalcTask task)
        external
        view
        returns (CollateralDebtData memory cdd);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotedTokensMask() external view returns (uint256);

    function updateQuota(address creditAccount, address token, int96 quotaChange, uint96 minQuota, uint96 maxQuota)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // --------------------- //
    // CREDIT MANAGER PARAMS //
    // --------------------- //

    function maxEnabledTokens() external view returns (uint8);

    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    function collateralTokensCount() external view returns (uint8);

    function getTokenMaskOrRevert(address token) external view returns (uint256 tokenMask);

    function getTokenByMask(uint256 tokenMask) external view returns (address token);

    function liquidationThresholds(address token) external view returns (uint16 lt);

    function ltParams(address token)
        external
        view
        returns (uint16 ltInitial, uint16 ltFinal, uint40 timestampRampStart, uint24 rampDuration);

    function collateralTokenByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    // ------------ //
    // ACCOUNT INFO //
    // ------------ //

    function creditAccountInfo(address creditAccount)
        external
        view
        returns (
            uint256 debt,
            uint256 cumulativeIndexLastUpdate,
            uint128 cumulativeQuotaInterest,
            uint128 quotaFees,
            uint256 enabledTokensMask,
            uint16 flags,
            uint64 lastDebtUpdate,
            address borrower
        );

    function getBorrowerOrRevert(address creditAccount) external view returns (address borrower);

    function flagsOf(address creditAccount) external view returns (uint16);

    function setFlagFor(address creditAccount, uint16 flag, bool value) external;

    function enabledTokensMaskOf(address creditAccount) external view returns (uint256);

    function creditAccounts() external view returns (address[] memory);

    function creditAccounts(uint256 offset, uint256 limit) external view returns (address[] memory);

    function creditAccountsLen() external view returns (uint256);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function addToken(address token) external;

    function setCollateralTokenData(
        address token,
        uint16 ltInitial,
        uint16 ltFinal,
        uint40 timestampRampStart,
        uint24 rampDuration
    ) external;

    function setFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationDiscount,
        uint16 feeLiquidationExpired,
        uint16 liquidationDiscountExpired
    ) external;

    function setQuotedMask(uint256 quotedTokensMask) external;

    function setMaxEnabledTokens(uint8 maxEnabledTokens) external;

    function setContractAllowance(address adapter, address targetContract) external;

    function setCreditFacade(address creditFacade) external;

    function setPriceOracle(address priceOracle) external;

    function setCreditConfigurator(address creditConfigurator) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IPriceOracleBase} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceOracleBase.sol";

struct PriceFeedParams {
    address priceFeed;
    uint32 stalenessPeriod;
    bool skipCheck;
    uint8 decimals;
    bool useReserve;
    bool trusted;
}

interface IPriceOracleV3Events {
    /// @notice Emitted when new price feed is set for token
    event SetPriceFeed(
        address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck, bool trusted
    );

    /// @notice Emitted when new reserve price feed is set for token
    event SetReservePriceFeed(address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck);

    /// @notice Emitted when new reserve price feed status is set for a token
    event SetReservePriceFeedStatus(address indexed token, bool active);
}

/// @title Price oracle V3 interface
interface IPriceOracleV3 is IPriceOracleBase, IPriceOracleV3Events {
    function getPriceSafe(address token) external view returns (uint256);

    function getPriceRaw(address token, bool reserve) external view returns (uint256);

    function priceFeedsRaw(address token, bool reserve) external view returns (address);

    function priceFeedParams(address token)
        external
        view
        returns (address priceFeed, uint32 stalenessPeriod, bool skipCheck, uint8 decimals, bool trusted);

    function safeConvertToUSD(uint256 amount, address token) external view returns (uint256);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setPriceFeed(address token, address priceFeed, uint32 stalenessPeriod, bool trusted) external;

    function setReservePriceFeed(address token, address priceFeed, uint32 stalenessPeriod) external;

    function setReservePriceFeedStatus(address token, bool active) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

import { PriceFeedType } from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";

/// @title Price feed interface
interface IPriceFeed {
    function priceFeedType() external view returns (PriceFeedType);

    function version() external view returns (uint256);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function skipPriceCheck() external view returns (bool);

    function latestRoundData()
        external
        view
        returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80);
}

/// @title Updatable price feed interface
interface IUpdatablePriceFeed is IPriceFeed {
    function updatable() external view returns (bool);

    function updatePrice(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;
pragma abicoder v1;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

interface IPoolV3Events {
    /// @notice Emitted when depositing liquidity with referral code
    event Refer(address indexed onBehalfOf, uint256 indexed referralCode, uint256 amount);

    /// @notice Emitted when credit account borrows funds from the pool
    event Borrow(address indexed creditManager, address indexed creditAccount, uint256 amount);

    /// @notice Emitted when credit account's debt is repaid to the pool
    event Repay(address indexed creditManager, uint256 borrowedAmount, uint256 profit, uint256 loss);

    /// @notice Emitted when incurred loss can't be fully covered by burning treasury's shares
    event IncurUncoveredLoss(address indexed creditManager, uint256 loss);

    /// @notice Emitted when new interest rate model contract is set
    event SetInterestRateModel(address indexed newInterestRateModel);

    /// @notice Emitted when new pool quota keeper contract is set
    event SetPoolQuotaKeeper(address indexed newPoolQuotaKeeper);

    /// @notice Emitted when new total debt limit is set
    event SetTotalDebtLimit(uint256 limit);

    /// @notice Emitted when new credit manager is connected to the pool
    event AddCreditManager(address indexed creditManager);

    /// @notice Emitted when new debt limit is set for a credit manager
    event SetCreditManagerDebtLimit(address indexed creditManager, uint256 newLimit);

    /// @notice Emitted when new withdrawal fee is set
    event SetWithdrawFee(uint256 fee);
}

/// @title Pool V3 interface
interface IPoolV3 is IVersion, IPoolV3Events, IERC4626, IERC20Permit {
    function addressProvider() external view returns (address);

    function underlyingToken() external view returns (address);

    function treasury() external view returns (address);

    function withdrawFee() external view returns (uint16);

    function creditManagers() external view returns (address[] memory);

    function availableLiquidity() external view returns (uint256);

    function expectedLiquidity() external view returns (uint256);

    function expectedLiquidityLU() external view returns (uint256);

    // ---------------- //
    // ERC-4626 LENDING //
    // ---------------- //

    function depositWithReferral(uint256 assets, address receiver, uint256 referralCode)
        external
        returns (uint256 shares);

    function mintWithReferral(uint256 shares, address receiver, uint256 referralCode)
        external
        returns (uint256 assets);

    // --------- //
    // BORROWING //
    // --------- //

    function totalBorrowed() external view returns (uint256);

    function totalDebtLimit() external view returns (uint256);

    function creditManagerBorrowed(address creditManager) external view returns (uint256);

    function creditManagerDebtLimit(address creditManager) external view returns (uint256);

    function creditManagerBorrowable(address creditManager) external view returns (uint256 borrowable);

    function lendCreditAccount(uint256 borrowedAmount, address creditAccount) external;

    function repayCreditAccount(uint256 repaidAmount, uint256 profit, uint256 loss) external;

    // ------------- //
    // INTEREST RATE //
    // ------------- //

    function interestRateModel() external view returns (address);

    function baseInterestRate() external view returns (uint256);

    function supplyRate() external view returns (uint256);

    function baseInterestIndex() external view returns (uint256);

    function baseInterestIndexLU() external view returns (uint256);

    function lastBaseInterestUpdate() external view returns (uint40);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotaRevenue() external view returns (uint256);

    function lastQuotaRevenueUpdate() external view returns (uint40);

    function updateQuotaRevenue(int256 quotaRevenueDelta) external;

    function setQuotaRevenue(uint256 newQuotaRevenue) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setInterestRateModel(address newInterestRateModel) external;

    function setPoolQuotaKeeper(address newPoolQuotaKeeper) external;

    function setTotalDebtLimit(uint256 newLimit) external;

    function setCreditManagerDebtLimit(address creditManager, uint256 newLimit) external;

    function setWithdrawFee(uint256 newWithdrawFee) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IDegenNFTV2Exceptions {
    /// @dev Thrown if an access-restricted function was called by non-CreditFacade
    error CreditFacadeOrConfiguratorOnlyException();

    /// @dev Thrown if an access-restricted function was called by non-minter
    error MinterOnlyException();

    /// @dev Thrown if trying to add a burner address that is not a correct Credit Facade
    error InvalidCreditFacadeException();

    /// @dev Thrown if the account's balance is not sufficient for an action (usually a burn)
    error InsufficientBalanceException();
}

interface IDegenNFTV2Events {
    /// @dev Minted when new minter set
    event NewMinterSet(address indexed);

    /// @dev Minted each time when new credit facade added
    event NewCreditFacadeAdded(address indexed);

    /// @dev Minted each time when new credit facade added
    event NewCreditFacadeRemoved(address indexed);
}

interface IDegenNFTV2 is
    IDegenNFTV2Exceptions,
    IDegenNFTV2Events,
    IVersion,
    IERC721Metadata
{
    /// @dev address of the current minter
    function minter() external view returns (address);

    /// @dev Stores the total number of tokens on holder accounts
    function totalSupply() external view returns (uint256);

    /// @dev Stores the base URI for NFT metadata
    function baseURI() external view returns (string memory);

    /// @dev Mints a specified amount of tokens to the address
    /// @param to Address the tokens are minted to
    /// @param amount The number of tokens to mint
    function mint(address to, uint256 amount) external;

    /// @dev Burns a number of tokens from a specified address
    /// @param from The address a token will be burnt from
    /// @param amount The number of tokens to burn
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

interface IWETH {
    /// @dev Deposits native ETH into the contract and mints WETH
    function deposit() external payable;

    /// @dev Transfers WETH to another account
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Burns WETH from msg.sender and send back native ETH
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

/// @notice Bot info
/// @param forbidden Whether bot is forbidden
/// @param specialPermissions Mapping credit manager => bot's special permissions
/// @param permissions Mapping credit manager => credit account => bot's permissions
struct BotInfo {
    bool forbidden;
    mapping(address => uint192) specialPermissions;
    mapping(address => mapping(address => uint192)) permissions;
}

interface IBotListV3Events {
    // ----------- //
    // PERMISSIONS //
    // ----------- //

    /// @notice Emitted when new `bot`'s permissions and funding params are set for `creditAccount` in `creditManager`
    event SetBotPermissions(
        address indexed bot, address indexed creditManager, address indexed creditAccount, uint192 permissions
    );

    /// @notice Emitted when `bot`'s permissions and funding params are removed for `creditAccount` in `creditManager`
    event EraseBot(address indexed bot, address indexed creditManager, address indexed creditAccount);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Emitted when `bot`'s forbidden status is set
    event SetBotForbiddenStatus(address indexed bot, bool forbidden);

    /// @notice Emitted when `bot`'s special permissions in `creditManager` are set
    event SetBotSpecialPermissions(address indexed bot, address indexed creditManager, uint192 permissions);

    /// @notice Emitted when `creditManager`'s approved status is set
    event SetCreditManagerApprovedStatus(address indexed creditManager, bool approved);
}

/// @title Bot list V3 interface
interface IBotListV3 is IBotListV3Events, IVersion {
    // ----------- //
    // PERMISSIONS //
    // ----------- //

    function botPermissions(address bot, address creditManager, address creditAccount)
        external
        view
        returns (uint192);

    function activeBots(address creditManager, address creditAccount) external view returns (address[] memory);

    function getBotStatus(address bot, address creditManager, address creditAccount)
        external
        view
        returns (uint192 permissions, bool forbidden, bool hasSpecialPermissions);

    function setBotPermissions(address bot, address creditManager, address creditAccount, uint192 permissions)
        external
        returns (uint256 activeBotsRemaining);

    function eraseAllBotPermissions(address creditManager, address creditAccount) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function botForbiddenStatus(address bot) external view returns (bool);

    function botSpecialPermissions(address bot, address creditManager) external view returns (uint192);

    function approvedCreditManager(address creditManager) external view returns (bool);

    function setBotForbiddenStatus(address bot, bool forbidden) external;

    function setBotSpecialPermissions(address bot, address creditManager, uint192 permissions) external;

    function setCreditManagerApprovedStatus(address creditManager, bool approved) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {CollateralDebtData, CollateralTokenData} from "../interfaces/ICreditManagerV3.sol";
import {SECONDS_PER_YEAR, PERCENTAGE_FACTOR} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

import {BitMask} from "./BitMask.sol";

uint256 constant INDEX_PRECISION = 10 ** 9;

/// @title Credit logic library
/// @notice Implements functions used for debt and repayment calculations
library CreditLogic {
    using BitMask for uint256;
    using SafeCast for uint256;

    // ----------------- //
    // DEBT AND INTEREST //
    // ----------------- //

    /// @dev Computes growth since last update given yearly growth
    function calcLinearGrowth(uint256 value, uint256 timestampLastUpdate) internal view returns (uint256) {
        return value * (block.timestamp - timestampLastUpdate) / SECONDS_PER_YEAR;
    }

    /// @dev Computes interest accrued since the last update
    function calcAccruedInterest(uint256 amount, uint256 cumulativeIndexLastUpdate, uint256 cumulativeIndexNow)
        internal
        pure
        returns (uint256)
    {
        if (amount == 0) return 0;
        return (amount * cumulativeIndexNow) / cumulativeIndexLastUpdate - amount; // U:[CL-1]
    }

    /// @dev Computes total debt, given raw debt data
    /// @param collateralDebtData See `CollateralDebtData` (must have debt data filled)
    function calcTotalDebt(CollateralDebtData memory collateralDebtData) internal pure returns (uint256) {
        return collateralDebtData.debt + collateralDebtData.accruedInterest + collateralDebtData.accruedFees;
    }

    // ----------- //
    // LIQUIDATION //
    // ----------- //

    /// @dev Computes the amount of underlying tokens to send to the pool on credit account liquidation
    ///      - First, liquidation premium and fee are subtracted from account's total value
    ///      - The resulting value is then used to repay the debt to the pool, and any remaining fudns
    ///        are send back to the account owner
    ///      - If, however, funds are insufficient to fully repay the debt, the function will first reduce
    ///        protocol profits before finally reporting a bad debt liquidation with loss
    /// @param collateralDebtData See `CollateralDebtData` (must have both collateral and debt data filled)
    /// @param feeLiquidation Liquidation fee charged by the DAO on the account collateral
    /// @param liquidationDiscount Percentage to discount account collateral by (equals 1 - liquidation premium)
    /// @param amountWithFeeFn Function that, given the exact amount of underlying tokens to receive,
    ///        returns the amount that needs to be sent
    /// @param amountWithFeeFn Function that, given the exact amount of underlying tokens to send,
    ///        returns the amount that will be received
    /// @return amountToPool Amount of underlying tokens to send to the pool
    /// @return remainingFunds Amount of underlying tokens to send to the credit account owner
    /// @return profit Amount of underlying tokens received as fees by the DAO
    /// @return loss Portion of account's debt that can't be repaid
    function calcLiquidationPayments(
        CollateralDebtData memory collateralDebtData,
        uint16 feeLiquidation,
        uint16 liquidationDiscount,
        function (uint256) view returns (uint256) amountWithFeeFn,
        function (uint256) view returns (uint256) amountMinusFeeFn
    ) internal view returns (uint256 amountToPool, uint256 remainingFunds, uint256 profit, uint256 loss) {
        amountToPool = calcTotalDebt(collateralDebtData); // U:[CL-4]

        uint256 debtWithInterest = collateralDebtData.debt + collateralDebtData.accruedInterest;

        uint256 totalValue = collateralDebtData.totalValue;

        uint256 totalFunds = totalValue * liquidationDiscount / PERCENTAGE_FACTOR;

        amountToPool += totalValue * feeLiquidation / PERCENTAGE_FACTOR; // U:[CL-4]

        uint256 amountToPoolWithFee = amountWithFeeFn(amountToPool);
        unchecked {
            if (totalFunds > amountToPoolWithFee) {
                remainingFunds = totalFunds - amountToPoolWithFee; // U:[CL-4]
            } else {
                amountToPoolWithFee = totalFunds;
                amountToPool = amountMinusFeeFn(totalFunds); // U:[CL-4]
            }

            if (amountToPool >= debtWithInterest) {
                profit = amountToPool - debtWithInterest; // U:[CL-4]
            } else {
                loss = debtWithInterest - amountToPool; // U:[CL-4]
            }
        }

        amountToPool = amountToPoolWithFee; // U:[CL-4]
    }

    // --------------------- //
    // LIQUIDATION THRESHOLD //
    // --------------------- //

    /// @dev Returns the current liquidation threshold based on token data
    /// @dev GearboxV3 supports liquidation threshold ramping, which means that the LT can be set to change dynamically
    ///      from one value to another over time. LT changes linearly, starting at `ltInitial` and ending at `ltFinal`.
    ///      To make LT static, the value can be written to `ltInitial` with ramp start set far in the future.
    function getLiquidationThreshold(uint16 ltInitial, uint16 ltFinal, uint40 timestampRampStart, uint24 rampDuration)
        internal
        view
        returns (uint16)
    {
        uint40 timestampRampEnd = timestampRampStart + rampDuration;
        if (block.timestamp <= timestampRampStart) {
            return ltInitial; // U:[CL-5]
        } else if (block.timestamp < timestampRampEnd) {
            return _getRampingLiquidationThreshold(ltInitial, ltFinal, timestampRampStart, timestampRampEnd); // U:[CL-5]
        } else {
            return ltFinal; // U:[CL-5]
        }
    }

    /// @dev Computes the LT during the ramping process
    function _getRampingLiquidationThreshold(
        uint16 ltInitial,
        uint16 ltFinal,
        uint40 timestampRampStart,
        uint40 timestampRampEnd
    ) internal view returns (uint16) {
        return uint16(
            (ltInitial * (timestampRampEnd - block.timestamp) + ltFinal * (block.timestamp - timestampRampStart))
                / (timestampRampEnd - timestampRampStart)
        ); // U:[CL-5]
    }

    // ----------- //
    // MANAGE DEBT //
    // ----------- //

    /// @dev Computes new debt principal and interest index after increasing debt
    ///      - The new debt principal is simply `debt + amount`
    ///      - The new credit account's interest index is a solution to the equation
    ///        `debt * (indexNow / indexLastUpdate - 1) = (debt + amount) * (indexNow / indexNew - 1)`,
    ///        which essentially writes that interest accrued since last update remains the same
    /// @param amount Amount to increase debt by
    /// @param debt Debt principal before increase
    /// @param cumulativeIndexNow The current interest index
    /// @param cumulativeIndexLastUpdate Credit account's interest index as of last update
    /// @return newDebt Debt principal after increase
    /// @return newCumulativeIndex New credit account's interest index
    function calcIncrease(uint256 amount, uint256 debt, uint256 cumulativeIndexNow, uint256 cumulativeIndexLastUpdate)
        internal
        pure
        returns (uint256 newDebt, uint256 newCumulativeIndex)
    {
        if (debt == 0) return (amount, cumulativeIndexNow);
        newDebt = debt + amount; // U:[CL-2]
        newCumulativeIndex = (
            (cumulativeIndexNow * newDebt * INDEX_PRECISION)
                / ((INDEX_PRECISION * cumulativeIndexNow * debt) / cumulativeIndexLastUpdate + INDEX_PRECISION * amount)
        ); // U:[CL-2]
    }

    /// @dev Computes new debt principal and interest index (and other values) after decreasing debt
    ///      - Debt comprises of multiple components which are repaid in the following order:
    ///        quota update fees => quota interest => base interest => debt principal.
    ///        New values for all these components depend on what portion of each was repaid.
    ///      - Debt principal, for example, only decreases if all previous components were fully repaid
    ///      - The new credit account's interest index stays the same if base interest was not repaid at all,
    ///        is set to the current interest index if base interest was repaid fully, and is a solution to
    ///        the equation `debt * (indexNow / indexLastUpdate - 1) - delta = debt * (indexNow / indexNew - 1)`
    ///        when only `delta` of accrued interest was repaid
    /// @param amount Amount of debt to repay
    /// @param debt Debt principal before repayment
    /// @param cumulativeIndexNow The current interest index
    /// @param cumulativeIndexLastUpdate Credit account's interest index as of last update
    /// @param cumulativeQuotaInterest Credit account's quota interest before repayment
    /// @param quotaFees Accrued quota fees
    /// @param feeInterest Fee on accrued interest (both base and quota) charged by the DAO
    /// @return newDebt Debt principal after repayment
    /// @return newCumulativeIndex Credit account's quota interest after repayment
    /// @return profit Amount of underlying tokens received as fees by the DAO
    /// @return newCumulativeQuotaInterest Credit account's accrued quota interest after repayment
    /// @return newQuotaFees Amount of unpaid quota fees left after repayment
    function calcDecrease(
        uint256 amount,
        uint256 debt,
        uint256 cumulativeIndexNow,
        uint256 cumulativeIndexLastUpdate,
        uint128 cumulativeQuotaInterest,
        uint128 quotaFees,
        uint16 feeInterest
    )
        internal
        pure
        returns (
            uint256 newDebt,
            uint256 newCumulativeIndex,
            uint256 profit,
            uint128 newCumulativeQuotaInterest,
            uint128 newQuotaFees
        )
    {
        uint256 amountToRepay = amount;

        unchecked {
            if (quotaFees != 0) {
                if (amountToRepay > quotaFees) {
                    newQuotaFees = 0; // U:[CL-3]
                    amountToRepay -= quotaFees;
                    profit = quotaFees; // U:[CL-3]
                } else {
                    newQuotaFees = quotaFees - uint128(amountToRepay); // U:[CL-3]
                    profit = amountToRepay; // U:[CL-3]
                    amountToRepay = 0;
                }
            }
        }

        if (cumulativeQuotaInterest != 0 && amountToRepay != 0) {
            uint256 quotaProfit = (cumulativeQuotaInterest * feeInterest) / PERCENTAGE_FACTOR;

            if (amountToRepay >= cumulativeQuotaInterest + quotaProfit) {
                amountToRepay -= cumulativeQuotaInterest + quotaProfit; // U:[CL-3]
                profit += quotaProfit; // U:[CL-3]

                newCumulativeQuotaInterest = 0; // U:[CL-3]
            } else {
                // If amount is not enough to repay quota interest + DAO fee, then it is split pro-rata between them
                uint256 amountToPool = (amountToRepay * PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR + feeInterest);

                profit += amountToRepay - amountToPool; // U:[CL-3]
                amountToRepay = 0; // U:[CL-3]

                newCumulativeQuotaInterest = uint128(cumulativeQuotaInterest - amountToPool); // U:[CL-3]
            }
        } else {
            newCumulativeQuotaInterest = cumulativeQuotaInterest;
        }

        if (amountToRepay != 0) {
            uint256 interestAccrued = calcAccruedInterest({
                amount: debt,
                cumulativeIndexLastUpdate: cumulativeIndexLastUpdate,
                cumulativeIndexNow: cumulativeIndexNow
            }); // U:[CL-3]
            uint256 profitFromInterest = (interestAccrued * feeInterest) / PERCENTAGE_FACTOR; // U:[CL-3]

            if (amountToRepay >= interestAccrued + profitFromInterest) {
                amountToRepay -= interestAccrued + profitFromInterest;

                profit += profitFromInterest; // U:[CL-3]

                newCumulativeIndex = cumulativeIndexNow; // U:[CL-3]
            } else {
                // If amount is not enough to repay base interest + DAO fee, then it is split pro-rata between them
                uint256 amountToPool = (amountToRepay * PERCENTAGE_FACTOR) / (PERCENTAGE_FACTOR + feeInterest);

                profit += amountToRepay - amountToPool; // U:[CL-3]
                amountToRepay = 0; // U:[CL-3]

                newCumulativeIndex = (INDEX_PRECISION * cumulativeIndexNow * cumulativeIndexLastUpdate)
                    / (
                        INDEX_PRECISION * cumulativeIndexNow
                            - (INDEX_PRECISION * amountToPool * cumulativeIndexLastUpdate) / debt
                    ); // U:[CL-3]
            }
        } else {
            newCumulativeIndex = cumulativeIndexLastUpdate; // U:[CL-3]
        }
        newDebt = debt - amountToRepay; // U:[CL-3]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {CollateralDebtData} from "../interfaces/ICreditManagerV3.sol";
import {PERCENTAGE_FACTOR, RAY} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

import {BitMask} from "./BitMask.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Collateral logic Library
/// @notice Implements functions that compute value of collateral on a credit account
library CollateralLogic {
    using BitMask for uint256;
    using SafeERC20 for IERC20;

    /// @dev Computes USD-denominated total value and TWV of a credit account.
    ///      If finite TWV target is specified, the function will stop processing tokens after cumulative TWV reaches
    ///      the target, in which case the returned values will be smaller than actual collateral.
    ///      This is useful to check whether account is sufficiently collateralized. To speed up this check, collateral
    ///      hints can be used to specify the order to scan tokens in.
    /// @param collateralDebtData See `CollateralDebtData` (must have enabled and quoted tokens filled)
    /// @param creditAccount Credit account to compute collateral for
    /// @param underlying The underlying token of the corresponding credit manager
    /// @param twvUSDTarget Target twvUSD value to stop calculation after
    /// @param collateralHints Array of token masks denoting the order to scan tokens in
    /// @param quotasPacked Array of packed values (quota, LT), in the same order as `collateralDebtData.quotedTokens`
    /// @param collateralTokenByMaskFn A function that returns collateral token data by its mask. Must accept inputs:
    ///        * `mask` - mask of the token
    ///        * `computeLT` - whether to compute the token's LT
    /// @param convertToUSDFn A function that returns token value in USD and accepts the following inputs:
    ///        * `priceOracle` - price oracle to convert assets in
    ///        * `amount` - amount of token to convert
    ///        * `token` - token to convert
    /// @param priceOracle Price oracle to convert assets, passed to `convertToUSDFn`
    /// @return totalValueUSD Total value of credit account's assets
    /// @return twvUSD Total LT-weighted value of credit account's assets
    /// @return tokensToDisable Mask of non-quoted tokens that have zero balances and can be disabled
    function calcCollateral(
        CollateralDebtData memory collateralDebtData,
        address creditAccount,
        address underlying,
        uint256 twvUSDTarget,
        uint256[] memory collateralHints,
        uint256[] memory quotasPacked,
        function (uint256, bool) view returns (address, uint16) collateralTokenByMaskFn,
        function (address, uint256, address) view returns(uint256) convertToUSDFn,
        address priceOracle
    ) internal view returns (uint256 totalValueUSD, uint256 twvUSD, uint256 tokensToDisable) {
        // Quoted tokens collateral value
        if (collateralDebtData.quotedTokens.length != 0) {
            // The underlying price is required for quotas but only needs to be computed once
            uint256 underlyingPriceRAY = convertToUSDFn(priceOracle, RAY, underlying);

            (totalValueUSD, twvUSD) = calcQuotedTokensCollateral({
                quotedTokens: collateralDebtData.quotedTokens,
                quotasPacked: quotasPacked,
                creditAccount: creditAccount,
                underlyingPriceRAY: underlyingPriceRAY,
                twvUSDTarget: twvUSDTarget,
                convertToUSDFn: convertToUSDFn,
                priceOracle: priceOracle
            }); // U:[CLL-5]

            if (twvUSD >= twvUSDTarget) {
                return (totalValueUSD, twvUSD, 0); // U:[CLL-5]
            } else {
                unchecked {
                    twvUSDTarget -= twvUSD; // U:[CLL-5]
                }
            }
        }

        // Non-quoted tokens collateral value
        {
            uint256 tokensToCheckMask =
                collateralDebtData.enabledTokensMask.disable(collateralDebtData.quotedTokensMask); // U:[CLL-5]

            uint256 tvDelta;
            uint256 twvDelta;

            (tvDelta, twvDelta, tokensToDisable) = calcNonQuotedTokensCollateral({
                tokensToCheckMask: tokensToCheckMask,
                priceOracle: priceOracle,
                creditAccount: creditAccount,
                twvUSDTarget: twvUSDTarget,
                collateralHints: collateralHints,
                collateralTokenByMaskFn: collateralTokenByMaskFn,
                convertToUSDFn: convertToUSDFn
            }); // U:[CLL-5]

            totalValueUSD += tvDelta; // U:[CLL-5]
            twvUSD += twvDelta; // U:[CLL-5]
        }
    }

    /// @dev Computes USD value of quoted tokens on a credit account
    /// @param quotedTokens Array of quoted tokens on the account
    /// @param quotasPacked Array of (quota, LT) tuples packed into uint256
    /// @param creditAccount Address of the credit account
    /// @param underlyingPriceRAY USD price of 1 RAY of underlying
    /// @param twvUSDTarget The twvUSD threshold to stop the computation at
    /// @param convertToUSDFn Function to convert asset amounts to USD
    /// @param priceOracle Address of the price oracle
    /// @return totalValueUSD Total value of credit account's quoted assets
    /// @return twvUSD Total LT-weighted value of credit account's quoted assets
    function calcQuotedTokensCollateral(
        address[] memory quotedTokens,
        uint256[] memory quotasPacked,
        address creditAccount,
        uint256 underlyingPriceRAY,
        uint256 twvUSDTarget,
        function (address, uint256, address) view returns(uint256) convertToUSDFn,
        address priceOracle
    ) internal view returns (uint256 totalValueUSD, uint256 twvUSD) {
        uint256 len = quotedTokens.length; // U:[CLL-4]

        for (uint256 i; i < len;) {
            address token = quotedTokens[i]; // U:[CLL-4]

            {
                (uint256 quota, uint16 liquidationThreshold) = unpackQuota(quotasPacked[i]); // U:[CLL-4]
                uint256 quotaUSD = quota * underlyingPriceRAY / RAY; // U:[CLL-4]

                (uint256 valueUSD, uint256 weightedValueUSD,) = calcOneTokenCollateral({
                    priceOracle: priceOracle,
                    creditAccount: creditAccount,
                    token: token,
                    liquidationThreshold: liquidationThreshold,
                    quotaUSD: quotaUSD,
                    convertToUSDFn: convertToUSDFn
                }); // U:[CLL-4]

                totalValueUSD += valueUSD; // U:[CLL-4]
                twvUSD += weightedValueUSD; // U:[CLL-4]
            }
            if (twvUSD >= twvUSDTarget) {
                return (totalValueUSD, twvUSD); // U:[CLL-4]
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Computes USD value of non-quoted tokens on a credit account
    /// @param creditAccount Address of the credit account
    /// @param twvUSDTarget The twvUSD threshold to stop the computation at
    /// @param collateralHints Array of token masks for order of priority during collateral computation
    /// @param convertToUSDFn Function to convert asset amounts to USD
    /// @param collateralTokenByMaskFn Function to retrieve the token's address and LT by its mask
    /// @param tokensToCheckMask Mask of tokens that need to be included into the computation
    /// @param priceOracle Address of the price oracle
    /// @return totalValueUSD Total value of credit account's quoted assets
    /// @return twvUSD Total LT-weighted value of credit account's quoted assets
    /// @return tokensToDisable Mask of non-quoted tokens that have zero balances and can be disabled
    function calcNonQuotedTokensCollateral(
        address creditAccount,
        uint256 twvUSDTarget,
        uint256[] memory collateralHints,
        function (address, uint256, address) view returns(uint256) convertToUSDFn,
        function (uint256, bool) view returns (address, uint16) collateralTokenByMaskFn,
        uint256 tokensToCheckMask,
        address priceOracle
    ) internal view returns (uint256 totalValueUSD, uint256 twvUSD, uint256 tokensToDisable) {
        uint256 len = collateralHints.length; // U:[CLL-3]

        address ca = creditAccount; // U:[CLL-3]
        uint256 i;
        while (tokensToCheckMask != 0) {
            uint256 tokenMask;

            if (i < len) {
                tokenMask = collateralHints[i];
                unchecked {
                    ++i;
                }
                if (tokensToCheckMask & tokenMask == 0) continue;
            } else {
                tokenMask = tokensToCheckMask & uint256(-int256(tokensToCheckMask));
            }

            bool nonZero;
            {
                uint256 valueUSD;
                uint256 weightedValueUSD;
                (valueUSD, weightedValueUSD, nonZero) = calcOneNonQuotedCollateral({
                    priceOracle: priceOracle,
                    creditAccount: ca,
                    tokenMask: tokenMask,
                    convertToUSDFn: convertToUSDFn,
                    collateralTokenByMaskFn: collateralTokenByMaskFn
                }); // U:[CLL-3]
                totalValueUSD += valueUSD; // U:[CLL-3]
                twvUSD += weightedValueUSD; // U:[CLL-3]
            }
            if (nonZero) {
                if (twvUSD >= twvUSDTarget) {
                    break; // U:[CLL-3]
                }
            } else {
                // Zero balance tokens are disabled after the collateral computation
                tokensToDisable = tokensToDisable.enable(tokenMask); // U:[CLL-3]
            }
            tokensToCheckMask = tokensToCheckMask.disable(tokenMask);
        }
    }

    /// @dev Computes value of a single non-quoted asset on a credit account
    /// @param creditAccount Address of the credit account
    /// @param convertToUSDFn Function to convert asset amounts to USD
    /// @param collateralTokenByMaskFn Function to retrieve the token's address and LT by its mask
    /// @param tokenMask Mask of the token
    /// @param priceOracle Address of the price oracle
    /// @return valueUSD Value of the token
    /// @return weightedValueUSD LT-weighted value of the token
    /// @return nonZeroBalance Whether the token has a zero balance
    function calcOneNonQuotedCollateral(
        address creditAccount,
        function (address, uint256, address) view returns(uint256) convertToUSDFn,
        function (uint256, bool) view returns (address, uint16) collateralTokenByMaskFn,
        uint256 tokenMask,
        address priceOracle
    ) internal view returns (uint256 valueUSD, uint256 weightedValueUSD, bool nonZeroBalance) {
        (address token, uint16 liquidationThreshold) = collateralTokenByMaskFn(tokenMask, true); // U:[CLL-2]

        (valueUSD, weightedValueUSD, nonZeroBalance) = calcOneTokenCollateral({
            priceOracle: priceOracle,
            creditAccount: creditAccount,
            token: token,
            liquidationThreshold: liquidationThreshold,
            quotaUSD: type(uint256).max,
            convertToUSDFn: convertToUSDFn
        }); // U:[CLL-2]
    }

    /// @dev Computes USD value of a single asset on a credit account
    /// @param creditAccount Address of the credit account
    /// @param convertToUSDFn Function to convert asset amounts to USD
    /// @param priceOracle Address of the price oracle
    /// @param token Address of the token
    /// @param liquidationThreshold LT of the token
    /// @param quotaUSD Quota of the token converted to USD
    /// @return valueUSD Value of the token
    /// @return weightedValueUSD LT-weighted value of the token
    /// @return nonZeroBalance Whether the token has a zero balance
    function calcOneTokenCollateral(
        address creditAccount,
        function (address, uint256, address) view returns(uint256) convertToUSDFn,
        address priceOracle,
        address token,
        uint16 liquidationThreshold,
        uint256 quotaUSD
    ) internal view returns (uint256 valueUSD, uint256 weightedValueUSD, bool nonZeroBalance) {
        uint256 balance = IERC20(token).safeBalanceOf({account: creditAccount}); // U:[CLL-1]

        if (balance > 1) {
            unchecked {
                valueUSD = convertToUSDFn(priceOracle, balance - 1, token); // U:[CLL-1]
            }
            weightedValueUSD = Math.min(valueUSD * liquidationThreshold / PERCENTAGE_FACTOR, quotaUSD); // U:[CLL-1]
            nonZeroBalance = true; // U:[CLL-1]
        }
    }

    /// @dev Packs quota and LT into one word
    function packQuota(uint96 quota, uint16 lt) internal pure returns (uint256) {
        return (uint256(lt) << 96) | quota;
    }

    /// @dev Unpacks one word into quota and LT
    function unpackQuota(uint256 packedQuota) internal pure returns (uint256 quota, uint16 lt) {
        lt = uint16(packedQuota >> 96);
        quota = uint96(packedQuota);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {ICreditAccountBase} from "../interfaces/ICreditAccountV3.sol";
import {AllowanceFailedException} from "../interfaces/IExceptions.sol";

/// @title Credit account helper library
/// @notice Implements functions that help manage assets on a credit account
library CreditAccountHelper {
    using SafeERC20 for IERC20;

    /// @dev Requests a credit account to do an approval with support for various kinds of tokens
    /// @dev Supports up-to-spec ERC20 tokens, ERC20 tokens that revert on transfer failure,
    ///      tokens that require 0 allowance before changing to non-zero value, and non-ERC20 tokens
    ///      that do not return a `success` value
    /// @param creditAccount Credit account to approve tokens from
    /// @param token Token to approve
    /// @param spender Address to approve to
    /// @param amount Amount to approve
    function safeApprove(ICreditAccountBase creditAccount, address token, address spender, uint256 amount) internal {
        if (!_approve(creditAccount, token, spender, amount, false)) {
            _approve(creditAccount, token, spender, 0, true); //U:[CAH-1,2]
            _approve(creditAccount, token, spender, amount, true); // U:[CAH-1,2]
        }
    }

    /// @dev Internal function used to approve tokens from a credit account to a third-party contrat.
    ///      Uses credit account's `execute` to properly handle both ERC20-compliant and on-compliant
    ///      (no returned value from "approve") tokens
    /// @param creditAccount Credit account to approve tokens from
    /// @param token Token to approve
    /// @param spender Address to approve to
    /// @param amount Amount to approve
    /// @param revertIfFailed Whether to revert or return `false` on receiving `false` or an error from `approve`
    function _approve(
        ICreditAccountBase creditAccount,
        address token,
        address spender,
        uint256 amount,
        bool revertIfFailed
    ) private returns (bool) {
        // Makes a low-level call to approve from the credit account and parses the value.
        // If nothing or true was returned, assumes that the call succeeded.
        try creditAccount.execute(token, abi.encodeCall(IERC20.approve, (spender, amount))) returns (
            bytes memory result
        ) {
            if (result.length == 0 || abi.decode(result, (bool))) return true;
        } catch {}

        // On the first try, failure is allowed to handle tokens that prohibit changing allowance from non-zero value.
        // After that, failure results in a revert.
        if (revertIfFailed) revert AllowanceFailedException();
        return false;
    }

    /// @dev Performs a token transfer from a credit account, accounting for non-ERC20 tokens
    /// @param creditAccount Credit account to send tokens from
    /// @param token Token to send
    /// @param to Address to send to
    /// @param amount Amount to send
    function transfer(ICreditAccountBase creditAccount, address token, address to, uint256 amount) internal {
        creditAccount.safeTransfer(token, to, amount);
    }

    /// @dev Performs a token transfer from a Credit account and returns the actual amount of token transferred
    /// @dev For some tokens, such as stETH or USDT (with fee enabled), the amount that arrives to the recipient can
    ///      differ from the sent amount. This ensures that calculations are correct in such cases.
    /// @param creditAccount Credit account to send tokens from
    /// @param token Token to send
    /// @param to Address to send to
    /// @param amount Amount to send
    /// @return delivered The actual amount that the `to` address received
    function transferDeliveredBalanceControl(
        ICreditAccountBase creditAccount,
        address token,
        address to,
        uint256 amount
    ) internal returns (uint256 delivered) {
        uint256 balanceBefore = IERC20(token).safeBalanceOf({account: to});
        transfer(creditAccount, token, to, amount);
        delivered = IERC20(token).safeBalanceOf({account: to}) - balanceBefore;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ZeroAddressException} from "../interfaces/IExceptions.sol";

/// @title Sanity check trait
abstract contract SanityCheckTrait {
    /// @dev Ensures that passed address is non-zero
    modifier nonZeroAddress(address addr) {
        _revertIfZeroAddress(addr);
        _;
    }

    /// @dev Reverts if address is zero
    function _revertIfZeroAddress(address addr) private pure {
        if (addr == address(0)) revert ZeroAddressException();
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

/// @title Account factory base interface
/// @notice Functions shared accross newer and older versions
interface IAccountFactoryBase is IVersion {
    function takeCreditAccount(uint256, uint256) external returns (address creditAccount);
    function returnCreditAccount(address creditAccount) external;
}

interface IAccountFactoryV3Events {
    /// @notice Emitted when new credit account is deployed
    event DeployCreditAccount(address indexed creditAccount, address indexed creditManager);

    /// @notice Emitted when credit account is taken by the credit manager
    event TakeCreditAccount(address indexed creditAccount, address indexed creditManager);

    /// @notice Emitted when used credit account is returned to the queue
    event ReturnCreditAccount(address indexed creditAccount, address indexed creditManager);

    /// @notice Emitted when new credit manager is added to the factory
    event AddCreditManager(address indexed creditManager, address masterCreditAccount);

    /// @notice Emitted when the DAO performs a proxy call from Credit Account to rescue funds
    event Rescue(address indexed creditAccount, address indexed target, bytes data);
}

/// @title Account factory V3 interface
interface IAccountFactoryV3 is IAccountFactoryBase, IAccountFactoryV3Events {
    function delay() external view returns (uint40);

    function takeCreditAccount(uint256, uint256) external override returns (address creditAccount);

    function returnCreditAccount(address creditAccount) external override;

    function addCreditManager(address creditManager) external;

    function rescue(address creditAccount, address target, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

/// @title Credit account base interface
/// @notice Functions shared accross newer and older versions
interface ICreditAccountBase is IVersion {
    function creditManager() external view returns (address);
    function safeTransfer(address token, address to, uint256 amount) external;
    function execute(address target, bytes calldata data) external returns (bytes memory result);
}

/// @title Credit account V3 interface
interface ICreditAccountV3 is ICreditAccountBase {
    function factory() external view returns (address);

    function creditManager() external view override returns (address);

    function safeTransfer(address token, address to, uint256 amount) external override;

    function execute(address target, bytes calldata data) external override returns (bytes memory result);

    function rescue(address target, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Foundation, 2023
pragma solidity ^0.8.17;

enum AdapterType {
    ABSTRACT,
    UNISWAP_V2_ROUTER,
    UNISWAP_V3_ROUTER,
    CURVE_V1_EXCHANGE_ONLY,
    YEARN_V2,
    CURVE_V1_2ASSETS,
    CURVE_V1_3ASSETS,
    CURVE_V1_4ASSETS,
    CURVE_V1_STECRV_POOL,
    CURVE_V1_WRAPPER,
    CONVEX_V1_BASE_REWARD_POOL,
    CONVEX_V1_BOOSTER,
    CONVEX_V1_CLAIM_ZAP,
    LIDO_V1,
    UNIVERSAL,
    LIDO_WSTETH_V1,
    BALANCER_VAULT,
    AAVE_V2_LENDING_POOL,
    AAVE_V2_WRAPPED_ATOKEN,
    COMPOUND_V2_CERC20,
    COMPOUND_V2_CETHER,
    ERC4626_VAULT,
    VELODROME_V2_ROUTER,
    CURVE_STABLE_NG,
    CAMELOT_V3_ROUTER,
    CONVEX_L2_BOOSTER,
    CONVEX_L2_REWARD_POOL,
    AAVE_V3_LENDING_POOL
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDaiLikePermit {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPermit2 {
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }
    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
    /// @notice Packed allowance
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    function transferFrom(address user, address spender, uint160 amount, address token) external;

    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    function allowance(address user, address token, address spender) external view returns (PackedAllowance memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Revert reason forwarder.
library RevertReasonForwarder {
    /// @dev Forwards latest externall call revert.
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        assembly ("memory-safe") { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

struct Balance {
    address token;
    uint256 balance;
}

library BalanceOps {
    error UnknownToken(address);

    function copyBalance(Balance memory b)
        internal
        pure
        returns (Balance memory)
    {
        return Balance({ token: b.token, balance: b.balance });
    }

    function addBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance += amount;
    }

    function subBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance -= amount;
    }

    function getBalance(Balance[] memory b, address token)
        internal
        pure
        returns (uint256 amount)
    {
        return b[getIndex(b, token)].balance;
    }

    function setBalance(
        Balance[] memory b,
        address token,
        uint256 amount
    ) internal pure {
        b[getIndex(b, token)].balance = amount;
    }

    function getIndex(Balance[] memory b, address token)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i; i < b.length; ) {
            if (b[i].token == token) {
                return i;
            }

            unchecked {
                ++i;
            }
        }
        revert UnknownToken(token);
    }

    function copy(Balance[] memory b, uint256 len)
        internal
        pure
        returns (Balance[] memory res)
    {
        res = new Balance[](len);
        for (uint256 i; i < len; ) {
            res[i] = copyBalance(b[i]);
            unchecked {
                ++i;
            }
        }
    }

    function clone(Balance[] memory b)
        internal
        pure
        returns (Balance[] memory)
    {
        return copy(b, b.length);
    }

    function getModifiedAfterSwap(
        Balance[] memory b,
        address tokenFrom,
        uint256 amountFrom,
        address tokenTo,
        uint256 amountTo
    ) internal pure returns (Balance[] memory res) {
        res = copy(b, b.length);
        setBalance(res, tokenFrom, getBalance(b, tokenFrom) - amountFrom);
        setBalance(res, tokenTo, getBalance(b, tokenTo) + amountTo);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct MultiCall {
    address target;
    bytes callData;
}

library MultiCallOps {
    function copyMulticall(MultiCall memory call)
        internal
        pure
        returns (MultiCall memory)
    {
        return MultiCall({ target: call.target, callData: call.callData });
    }

    function trim(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory trimmed)
    {
        uint256 len = calls.length;

        if (len == 0) return calls;

        uint256 foundLen;
        while (calls[foundLen].target != address(0)) {
            unchecked {
                ++foundLen;
                if (foundLen == len) return calls;
            }
        }

        if (foundLen > 0) return copy(calls, foundLen);
    }

    function copy(MultiCall[] memory calls, uint256 len)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        res = new MultiCall[](len);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function clone(MultiCall[] memory calls)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        return copy(calls, calls.length);
    }

    function append(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        for (uint256 i; i < len; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
        res[len] = copyMulticall(newCall);
    }

    function prepend(MultiCall[] memory calls, MultiCall memory newCall)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len = calls.length;
        res = new MultiCall[](len + 1);
        res[0] = copyMulticall(newCall);

        for (uint256 i = 1; i < len + 1; ) {
            res[i] = copyMulticall(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function concat(MultiCall[] memory calls1, MultiCall[] memory calls2)
        internal
        pure
        returns (MultiCall[] memory res)
    {
        uint256 len1 = calls1.length;
        uint256 lenTotal = len1 + calls2.length;

        if (lenTotal == calls1.length) return clone(calls1);
        if (lenTotal == calls2.length) return clone(calls2);

        res = new MultiCall[](lenTotal);

        for (uint256 i; i < lenTotal; ) {
            res[i] = (i < len1)
                ? copyMulticall(calls1[i])
                : copyMulticall(calls2[i - len1]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {BalanceDelta} from "../libraries/BalancesLogic.sol";
import {RevocationPair} from "./ICreditManagerV3.sol";

// ----------- //
// PERMISSIONS //
// ----------- //

uint192 constant ADD_COLLATERAL_PERMISSION = 1;
uint192 constant INCREASE_DEBT_PERMISSION = 1 << 1;
uint192 constant DECREASE_DEBT_PERMISSION = 1 << 2;
uint192 constant ENABLE_TOKEN_PERMISSION = 1 << 3;
uint192 constant DISABLE_TOKEN_PERMISSION = 1 << 4;
uint192 constant WITHDRAW_COLLATERAL_PERMISSION = 1 << 5;
uint192 constant UPDATE_QUOTA_PERMISSION = 1 << 6;
uint192 constant REVOKE_ALLOWANCES_PERMISSION = 1 << 7;

uint192 constant EXTERNAL_CALLS_PERMISSION = 1 << 16;

uint256 constant ALL_CREDIT_FACADE_CALLS_PERMISSION = ADD_COLLATERAL_PERMISSION | WITHDRAW_COLLATERAL_PERMISSION
    | INCREASE_DEBT_PERMISSION | DECREASE_DEBT_PERMISSION | ENABLE_TOKEN_PERMISSION | DISABLE_TOKEN_PERMISSION
    | UPDATE_QUOTA_PERMISSION | REVOKE_ALLOWANCES_PERMISSION;

uint256 constant ALL_PERMISSIONS = ALL_CREDIT_FACADE_CALLS_PERMISSION | EXTERNAL_CALLS_PERMISSION;

// ----- //
// FLAGS //
// ----- //

/// @dev Indicates that there are enabled forbidden tokens on the account before multicall
uint256 constant FORBIDDEN_TOKENS_BEFORE_CALLS = 1 << 192;

/// @dev Indicates that external calls from credit account to adapters were made during multicall,
///      set to true on the first call to the adapter
uint256 constant EXTERNAL_CONTRACT_WAS_CALLED = 1 << 193;

/// @title Credit facade V3 multicall interface
/// @dev Unless specified otherwise, all these methods are only available in `openCreditAccount`,
///      `closeCreditAccount`, `multicall`, and, with account owner's permission, `botMulticall`
interface ICreditFacadeV3Multicall {
    /// @notice Updates the price for a token with on-demand updatable price feed
    /// @param token Token to push the price update for
    /// @param reserve Whether to update reserve price feed or main price feed
    /// @param data Data to call `updatePrice` with
    /// @dev Calls of this type must be placed before all other calls in the multicall not to revert
    /// @dev This method is available in all kinds of multicalls
    function onDemandPriceUpdate(address token, bool reserve, bytes calldata data) external;

    /// @notice Stores expected token balances (current balance + delta) after operations for a slippage check.
    ///         Normally, a check is performed automatically at the end of the multicall, but more fine-grained
    ///         behavior can be achieved by placing `storeExpectedBalances` and `compareBalances` where needed.
    /// @param balanceDeltas Array of (token, minBalanceDelta) pairs, deltas are allowed to be negative
    /// @dev Reverts if expected balances are already set
    /// @dev This method is available in all kinds of multicalls
    function storeExpectedBalances(BalanceDelta[] calldata balanceDeltas) external;

    /// @notice Performs a slippage check ensuring that current token balances are greater than saved expected ones
    /// @dev Resets stored expected balances
    /// @dev Reverts if expected balances are not stored
    /// @dev This method is available in all kinds of multicalls
    function compareBalances() external;

    /// @notice Adds collateral to account
    /// @param token Token to add
    /// @param amount Amount to add
    /// @dev Requires token approval from caller to the credit manager
    /// @dev This method can also be called during liquidation
    function addCollateral(address token, uint256 amount) external;

    /// @notice Adds collateral to account using signed EIP-2612 permit message
    /// @param token Token to add
    /// @param amount Amount to add
    /// @param deadline Permit deadline
    /// @dev `v`, `r`, `s` must be a valid signature of the permit message from caller to the credit manager
    /// @dev This method can also be called during liquidation
    function addCollateralWithPermit(address token, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /// @notice Increases account's debt
    /// @param amount Underlying amount to borrow
    /// @dev Increasing debt is prohibited when closing an account
    /// @dev Increasing debt is prohibited if it was previously updated in the same block
    /// @dev The resulting debt amount must be within allowed range
    /// @dev Increasing debt is prohibited if there are forbidden tokens enabled as collateral on the account
    /// @dev After debt increase, total amount borrowed by the credit manager in the current block must not exceed
    ///      the limit defined in the facade
    function increaseDebt(uint256 amount) external;

    /// @notice Decreases account's debt
    /// @param amount Underlying amount to repay, value above account's total debt indicates full repayment
    /// @dev Decreasing debt is prohibited when opening an account
    /// @dev Decreasing debt is prohibited if it was previously updated in the same block
    /// @dev The resulting debt amount must be within allowed range or zero
    /// @dev Full repayment brings account into a special mode that skips collateral checks and thus requires
    ///      an account to have no potential debt sources, e.g., all quotas must be disabled
    function decreaseDebt(uint256 amount) external;

    /// @notice Updates account's quota for a token
    /// @param token Token to update the quota for
    /// @param quotaChange Desired quota change in underlying token units (`type(int96).min` to disable quota)
    /// @param minQuota Minimum resulting account's quota for token required not to revert
    /// @dev Enables token as collateral if quota is increased from zero, disables if decreased to zero
    /// @dev Quota increase is prohibited if there are forbidden tokens enabled as collateral on the account
    /// @dev Quota update is prohibited if account has zero debt
    /// @dev Resulting account's quota for token must not exceed the limit defined in the facade
    function updateQuota(address token, int96 quotaChange, uint96 minQuota) external;

    /// @notice Withdraws collateral from account
    /// @param token Token to withdraw
    /// @param amount Amount to withdraw, `type(uint256).max` to withdraw all balance
    /// @param to Token recipient
    /// @dev This method can also be called during liquidation
    /// @dev Withdrawals are prohibited in multicalls if there are forbidden tokens enabled as collateral on the account
    /// @dev Withdrawals activate safe pricing (min of main and reserve feeds) in collateral check
    function withdrawCollateral(address token, uint256 amount, address to) external;

    /// @notice Sets advanced collateral check parameters
    /// @param collateralHints Optional array of token masks to check first to reduce the amount of computation
    ///        when known subset of account's collateral tokens covers all the debt
    /// @param minHealthFactor Min account's health factor in bps in order not to revert, must be at least 10000
    function setFullCheckParams(uint256[] calldata collateralHints, uint16 minHealthFactor) external;

    /// @notice Enables token as account's collateral, which makes it count towards account's total value
    /// @param token Token to enable as collateral
    /// @dev Enabling forbidden tokens is prohibited
    /// @dev Quoted tokens can only be enabled via `updateQuota`, this method is no-op for them
    function enableToken(address token) external;

    /// @notice Disables token as account's collateral
    /// @param token Token to disable as collateral
    /// @dev Quoted tokens can only be disabled via `updateQuota`, this method is no-op for them
    function disableToken(address token) external;

    /// @notice Revokes account's allowances for specified spender/token pairs
    /// @param revocations Array of spender/token pairs
    /// @dev Exists primarily to allow users to revoke allowances on accounts from old account factory on mainnet
    function revokeAdapterAllowances(RevocationPair[] calldata revocations) external;
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Foundation, 2023
pragma solidity ^0.8.17;

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE,
    WSTETH_ORACLE,
    BOUNDED_ORACLE,
    COMPOSITE_ORACLE,
    WRAPPED_AAVE_V2_ORACLE,
    COMPOUND_V2_ORACLE,
    BALANCER_STABLE_LP_ORACLE,
    BALANCER_WEIGHTED_LP_ORACLE,
    CURVE_CRYPTO_ORACLE,
    THE_SAME_AS,
    REDSTONE_ORACLE,
    ERC4626_VAULT_ORACLE,
    NETWORK_DEPENDENT,
    CURVE_USD_ORACLE,
    PYTH_ORACLE
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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