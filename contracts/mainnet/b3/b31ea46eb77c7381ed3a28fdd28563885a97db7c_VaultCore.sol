//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {OwnableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    SafeERC20Upgradeable,
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IFeeCalculator} from "./interfaces/IFeeCalculator.sol";
import {IUSDs} from "../interfaces/IUSDs.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IRebaseManager} from "../interfaces/IRebaseManager.sol";
import {ICollateralManager} from "./interfaces/ICollateralManager.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {Helpers} from "../libraries/Helpers.sol";

/// @title Savings Manager (Vault) Contract for USDs Protocol
/// @author Sperax Foundation
/// @notice This contract enables users to mint and redeem USDs with allowed collaterals.
/// @notice It also allocates collateral to strategies based on the Collateral Manager contract.
contract VaultCore is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public feeVault; // Address of the SPABuyback contract
    address public yieldReceiver; // Address of the Yield Receiver contract
    address public collateralManager; // Address of the Collateral Manager contract
    address public feeCalculator; // Address of the Fee Calculator contract
    address public oracle; // Address of the Oracle contract
    address public rebaseManager; // Address of the Rebase Manager contract

    // Events
    event FeeVaultUpdated(address newFeeVault);
    event YieldReceiverUpdated(address newYieldReceiver);
    event CollateralManagerUpdated(address newCollateralManager);
    event FeeCalculatorUpdated(address newFeeCalculator);
    event RebaseManagerUpdated(address newRebaseManager);
    event OracleUpdated(address newOracle);
    event Minted(
        address indexed wallet, address indexed collateralAddr, uint256 usdsAmt, uint256 collateralAmt, uint256 feeAmt
    );
    event Redeemed(
        address indexed wallet, address indexed collateralAddr, uint256 usdsAmt, uint256 collateralAmt, uint256 feeAmt
    );
    event RebasedUSDs(uint256 rebaseAmt);
    event Allocated(address indexed collateral, address indexed strategy, uint256 amount);

    // Custom Error messages
    error AllocationNotAllowed(address collateral, address strategy, uint256 amount);
    error RedemptionPausedForCollateral(address collateral);
    error InsufficientCollateral(address collateral, address strategy, uint256 amount, uint256 availableAmount);
    error InvalidStrategy(address _collateral, address _strategyAddr);
    error MintFailed();

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Updates the address receiving fee.
    /// @param _feeVault New desired SPABuyback address.
    function updateFeeVault(address _feeVault) external onlyOwner {
        Helpers._isNonZeroAddr(_feeVault);
        feeVault = _feeVault;
        emit FeeVaultUpdated(_feeVault);
    }

    /// @notice Updates the address receiving yields from strategies.
    /// @param _yieldReceiver New desired yield receiver address.
    function updateYieldReceiver(address _yieldReceiver) external onlyOwner {
        Helpers._isNonZeroAddr(_yieldReceiver);
        yieldReceiver = _yieldReceiver;
        emit YieldReceiverUpdated(_yieldReceiver);
    }

    /// @notice Updates the address having the configuration for collaterals.
    /// @param _collateralManager New desired collateral manager address.
    function updateCollateralManager(address _collateralManager) external onlyOwner {
        Helpers._isNonZeroAddr(_collateralManager);
        collateralManager = _collateralManager;
        emit CollateralManagerUpdated(_collateralManager);
    }

    /// @notice Updates the address having the configuration for rebases.
    /// @param _rebaseManager New desired rebase manager address.
    function updateRebaseManager(address _rebaseManager) external onlyOwner {
        Helpers._isNonZeroAddr(_rebaseManager);
        rebaseManager = _rebaseManager;
        emit RebaseManagerUpdated(_rebaseManager);
    }

    /// @notice Updates the fee calculator library.
    /// @param _feeCalculator New desired fee calculator address.
    function updateFeeCalculator(address _feeCalculator) external onlyOwner {
        Helpers._isNonZeroAddr(_feeCalculator);
        feeCalculator = _feeCalculator;
        emit FeeCalculatorUpdated(_feeCalculator);
    }

    /// @notice Updates the price oracle address.
    /// @param _oracle New desired oracle address.
    function updateOracle(address _oracle) external onlyOwner {
        Helpers._isNonZeroAddr(_oracle);
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }

    /// @notice Allocates `_amount` of `_collateral` to `_strategy`.
    /// @param _collateral Address of the desired collateral.
    /// @param _strategy Address of the desired strategy.
    /// @param _amount Amount of collateral to be allocated.
    function allocate(address _collateral, address _strategy, uint256 _amount) external nonReentrant {
        // Validate the allocation based on the desired configuration
        if (!ICollateralManager(collateralManager).validateAllocation(_collateral, _strategy, _amount)) {
            revert AllocationNotAllowed(_collateral, _strategy, _amount);
        }
        IERC20Upgradeable(_collateral).forceApprove(_strategy, _amount);
        IStrategy(_strategy).deposit(_collateral, _amount);
        emit Allocated(_collateral, _strategy, _amount);
    }

    /// @notice Mint USDs by depositing collateral.
    /// @param _collateral Address of the collateral.
    /// @param _collateralAmt Amount of collateral to mint USDs with.
    /// @param _minUSDSAmt Minimum expected amount of USDs to be minted.
    /// @param _deadline Expiry time of the transaction.
    function mint(address _collateral, uint256 _collateralAmt, uint256 _minUSDSAmt, uint256 _deadline)
        external
        nonReentrant
    {
        _mint(_collateral, _collateralAmt, _minUSDSAmt, _deadline);
    }

    /// @notice Mint USDs by depositing collateral (backward compatibility).
    /// @param _collateral Address of the collateral.
    /// @param _collateralAmt Amount of collateral to mint USDs with.
    /// @param _minUSDSAmt Minimum expected amount of USDs to be minted.
    /// @param _deadline Expiry time of the transaction.
    /// @dev This function is for backward compatibility.
    function mintBySpecifyingCollateralAmt(
        address _collateral,
        uint256 _collateralAmt,
        uint256 _minUSDSAmt,
        uint256, // Deprecated
        uint256 _deadline
    ) external nonReentrant {
        _mint(_collateral, _collateralAmt, _minUSDSAmt, _deadline);
    }

    /// @notice Redeem USDs for `_collateral`.
    /// @param _collateral Address of the collateral.
    /// @param _usdsAmt Amount of USDs to be redeemed.
    /// @param _minCollAmt Minimum expected amount of collateral to be received.
    /// @param _deadline Expiry time of the transaction.
    /// @dev In case where there is not sufficient collateral available in the vault,
    ///      the collateral is withdrawn from the default strategy configured for the collateral.
    function redeem(address _collateral, uint256 _usdsAmt, uint256 _minCollAmt, uint256 _deadline)
        external
        nonReentrant
    {
        _redeem({
            _collateral: _collateral,
            _usdsAmt: _usdsAmt,
            _minCollateralAmt: _minCollAmt,
            _deadline: _deadline,
            _strategyAddr: address(0)
        });
    }

    /// @notice Redeem USDs for `_collateral` from a specific strategy.
    /// @param _collateral Address of the collateral.
    /// @param _usdsAmt Amount of USDs to be redeemed.
    /// @param _minCollAmt Minimum expected amount of collateral to be received.
    /// @param _deadline Expiry time of the transaction.
    /// @param _strategy Address of the strategy to withdraw excess collateral from.
    function redeem(address _collateral, uint256 _usdsAmt, uint256 _minCollAmt, uint256 _deadline, address _strategy)
        external
        nonReentrant
    {
        _redeem({
            _collateral: _collateral,
            _usdsAmt: _usdsAmt,
            _minCollateralAmt: _minCollAmt,
            _deadline: _deadline,
            _strategyAddr: _strategy
        });
    }

    /// @notice Get the expected redeem result.
    /// @param _collateral Desired collateral address.
    /// @param _usdsAmt Amount of USDs to be redeemed.
    /// @return calculatedCollateralAmt Expected amount of collateral to be released
    /// based on the price calculation.
    /// @return usdsBurnAmt Expected amount of USDs to be burnt in the process.
    /// @return feeAmt Amount of USDs collected as fee for redemption.
    /// @return vaultAmt Amount of collateral released from Vault.
    /// @return strategyAmt Amount of collateral to withdraw from the strategy.
    function redeemView(address _collateral, uint256 _usdsAmt)
        external
        view
        returns (
            uint256 calculatedCollateralAmt,
            uint256 usdsBurnAmt,
            uint256 feeAmt,
            uint256 vaultAmt,
            uint256 strategyAmt
        )
    {
        (calculatedCollateralAmt, usdsBurnAmt, feeAmt, vaultAmt, strategyAmt,) =
            _redeemView(_collateral, _usdsAmt, address(0));
    }

    /// @notice Get the expected redeem result from a specific strategy.
    /// @param _collateral Desired collateral address.
    /// @param _usdsAmt Amount of USDs to be redeemed.
    /// @param _strategyAddr Address of strategy to redeem from.
    /// @return calculatedCollateralAmt Expected amount of collateral to be released
    /// based on the price calculation.
    /// @return usdsBurnAmt Expected amount of USDs to be burnt in the process.
    /// @return feeAmt Amount of USDs collected as fee for redemption.
    /// @return vaultAmt Amount of collateral released from Vault.
    /// @return strategyAmt Amount of collateral to withdraw from the strategy.
    function redeemView(address _collateral, uint256 _usdsAmt, address _strategyAddr)
        external
        view
        returns (
            uint256 calculatedCollateralAmt,
            uint256 usdsBurnAmt,
            uint256 feeAmt,
            uint256 vaultAmt,
            uint256 strategyAmt
        )
    {
        (calculatedCollateralAmt, usdsBurnAmt, feeAmt, vaultAmt, strategyAmt,) =
            _redeemView(_collateral, _usdsAmt, _strategyAddr);
    }

    /// @notice Rebase USDs to share earned yield with the USDs holders.
    /// @dev If Rebase manager returns a non-zero value, it calls the rebase function on the USDs contract.
    function rebase() public {
        uint256 rebaseAmt = IRebaseManager(rebaseManager).fetchRebaseAmt();
        if (rebaseAmt != 0) {
            IUSDs(Helpers.USDS).rebase(rebaseAmt);
            emit RebasedUSDs(rebaseAmt);
        }
    }

    /// @notice Get the expected mint result (USDs amount, fee).
    /// @param _collateral Address of collateral.
    /// @param _collateralAmt Amount of collateral.
    /// @return Returns the expected USDs mint amount and fee for minting.
    function mintView(address _collateral, uint256 _collateralAmt) public view returns (uint256, uint256) {
        // Get mint configuration
        ICollateralManager.CollateralMintData memory collateralMintConfig =
            ICollateralManager(collateralManager).getMintParams(_collateral);

        // Fetch the latest price of the collateral
        IOracle.PriceData memory collateralPriceData = IOracle(oracle).getPrice(_collateral);
        // Calculate the downside peg
        uint256 downsidePeg =
            (collateralPriceData.precision * collateralMintConfig.downsidePeg) / Helpers.MAX_PERCENTAGE;

        // Downside peg check
        if (collateralPriceData.price < downsidePeg || !collateralMintConfig.mintAllowed) {
            return (0, 0);
        }

        // Skip fee collection for owner
        uint256 feePercentage = 0;
        if (msg.sender != owner() && msg.sender != yieldReceiver) {
            // Calculate mint fee based on collateral data
            feePercentage = IFeeCalculator(feeCalculator).getMintFee(_collateral);
        }

        // Normalize _collateralAmt to be of decimals 18
        uint256 normalizedCollateralAmt = _collateralAmt * collateralMintConfig.conversionFactor;

        // Calculate total USDs amount
        uint256 usdsAmt = normalizedCollateralAmt;
        if (collateralPriceData.price < collateralPriceData.precision) {
            usdsAmt = (normalizedCollateralAmt * collateralPriceData.price) / collateralPriceData.precision;
        }

        // Calculate the fee amount and usds to mint
        uint256 feeAmt = (usdsAmt * feePercentage) / Helpers.MAX_PERCENTAGE;
        uint256 toMinterAmt = usdsAmt - feeAmt;

        return (toMinterAmt, feeAmt);
    }

    /// @notice Mint USDs by depositing collateral.
    /// @param _collateral Address of the collateral.
    /// @param _collateralAmt Amount of collateral to deposit.
    /// @param _minUSDSAmt Minimum expected amount of USDs to be minted.
    /// @param _deadline Deadline timestamp for executing mint.
    /// @dev Mints USDs by locking collateral based on user input, ensuring a minimum
    /// expected minted amount is met.
    /// @dev If the minimum expected amount is not met, the transaction will revert.
    /// @dev Fee is collected, and collateral is transferred accordingly.
    /// @dev A rebase operation is triggered after minting.
    function _mint(address _collateral, uint256 _collateralAmt, uint256 _minUSDSAmt, uint256 _deadline) private {
        Helpers._checkDeadline(_deadline);
        (uint256 toMinterAmt, uint256 feeAmt) = mintView(_collateral, _collateralAmt);
        if (toMinterAmt == 0) revert MintFailed();
        if (toMinterAmt < _minUSDSAmt) {
            revert Helpers.MinSlippageError(toMinterAmt, _minUSDSAmt);
        }

        rebase();

        IERC20Upgradeable(_collateral).safeTransferFrom(msg.sender, address(this), _collateralAmt);
        IUSDs(Helpers.USDS).mint(msg.sender, toMinterAmt);
        if (feeAmt != 0) {
            IUSDs(Helpers.USDS).mint(feeVault, feeAmt);
        }

        emit Minted({
            wallet: msg.sender,
            collateralAddr: _collateral,
            usdsAmt: toMinterAmt,
            collateralAmt: _collateralAmt,
            feeAmt: feeAmt
        });
    }

    /// @notice Redeem USDs for collateral.
    /// @param _collateral Address of the collateral to receive.
    /// @param _usdsAmt Amount of USDs to redeem.
    /// @param _minCollateralAmt Minimum expected collateral amount to be received.
    /// @param _deadline Deadline timestamp for executing the redemption.
    /// @param _strategyAddr Address of the strategy to withdraw from.
    /// @dev Redeems USDs for collateral, ensuring a minimum expected collateral amount
    /// is met.
    /// @dev If the minimum expected collateral amount is not met, the transaction will revert.
    /// @dev Fee is collected, collateral is transferred, and a rebase operation is triggered.
    function _redeem(
        address _collateral,
        uint256 _usdsAmt,
        uint256 _minCollateralAmt,
        uint256 _deadline,
        address _strategyAddr
    ) private {
        Helpers._checkDeadline(_deadline);
        (
            uint256 collateralAmt,
            uint256 burnAmt,
            uint256 feeAmt,
            uint256 vaultAmt,
            uint256 strategyAmt,
            IStrategy strategy
        ) = _redeemView(_collateral, _usdsAmt, _strategyAddr);

        if (strategyAmt != 0) {
            // Withdraw from the strategy to VaultCore
            uint256 strategyAmtReceived = strategy.withdraw(address(this), _collateral, strategyAmt);
            // Update collateral amount according to the received amount from the strategy
            strategyAmt = strategyAmtReceived < strategyAmt ? strategyAmtReceived : strategyAmt;
            collateralAmt = vaultAmt + strategyAmt;
        }

        if (collateralAmt < _minCollateralAmt) {
            revert Helpers.MinSlippageError(collateralAmt, _minCollateralAmt);
        }

        // Collect USDs for Redemption
        IERC20Upgradeable(Helpers.USDS).safeTransferFrom(msg.sender, address(this), _usdsAmt);
        IUSDs(Helpers.USDS).burn(burnAmt);
        if (feeAmt != 0) {
            IERC20Upgradeable(Helpers.USDS).safeTransfer(feeVault, feeAmt);
        }
        // Transfer desired collateral to the user
        IERC20Upgradeable(_collateral).safeTransfer(msg.sender, collateralAmt);
        rebase();
        emit Redeemed({
            wallet: msg.sender,
            collateralAddr: _collateral,
            usdsAmt: burnAmt,
            collateralAmt: collateralAmt,
            feeAmt: feeAmt
        });
    }

    /// @notice Get the expected redeem result.
    /// @param _collateral Desired collateral address.
    /// @param _usdsAmt Amount of USDs to be redeemed.
    /// @param _strategyAddr Address of the strategy to redeem from.
    /// @return calculatedCollateralAmt Expected amount of collateral to be released
    ///         based on the price calculation.
    /// @return usdsBurnAmt Expected amount of USDs to be burnt in the process.
    /// @return feeAmt Amount of USDs collected as a fee for redemption.
    /// @return vaultAmt Amount of collateral released from Vault.
    /// @return strategyAmt Amount of collateral to withdraw from the strategy.
    /// @return strategy Strategy contract to withdraw collateral from.
    /// @dev Calculates the expected results of a redemption, including collateral
    ///      amount, fees, and strategy-specific details.
    /// @dev Ensures that the redemption is allowed for the specified collateral.
    /// @dev Calculates fees, burn amounts, and collateral amounts based on prices
    ///      and conversion factors.
    /// @dev Determines if collateral needs to be withdrawn from a strategy, and if
    ///      so, checks the availability of collateral in the strategy.

    function _redeemView(address _collateral, uint256 _usdsAmt, address _strategyAddr)
        private
        view
        returns (
            uint256 calculatedCollateralAmt,
            uint256 usdsBurnAmt,
            uint256 feeAmt,
            uint256 vaultAmt,
            uint256 strategyAmt,
            IStrategy strategy
        )
    {
        ICollateralManager.CollateralRedeemData memory collateralRedeemConfig =
            ICollateralManager(collateralManager).getRedeemParams(_collateral);

        if (!collateralRedeemConfig.redeemAllowed) {
            revert RedemptionPausedForCollateral(_collateral);
        }

        IOracle.PriceData memory collateralPriceData = IOracle(oracle).getPrice(_collateral);

        // Skip fee collection for Owner
        uint256 feePercentage = 0;
        if (msg.sender != owner()) {
            feePercentage = IFeeCalculator(feeCalculator).getRedeemFee(_collateral);
        }

        // Calculate actual fee and burn amount in terms of USDs
        feeAmt = (_usdsAmt * feePercentage) / Helpers.MAX_PERCENTAGE;
        usdsBurnAmt = _usdsAmt - feeAmt;

        // Calculate collateral amount
        calculatedCollateralAmt = usdsBurnAmt;
        if (collateralPriceData.price >= collateralPriceData.precision) {
            // Apply downside peg
            calculatedCollateralAmt = (usdsBurnAmt * collateralPriceData.precision) / collateralPriceData.price;
        }

        // Normalize collateral amount to be of base decimal
        calculatedCollateralAmt /= collateralRedeemConfig.conversionFactor;

        vaultAmt = IERC20Upgradeable(_collateral).balanceOf(address(this));

        if (calculatedCollateralAmt > vaultAmt) {
            // @dev Insufficient fund in the vault to support redemption Check in linked strategy
            unchecked {
                strategyAmt = calculatedCollateralAmt - vaultAmt;
            }
            if (_strategyAddr == address(0)) {
                // Withdraw from default strategy if strategy not specified
                if (collateralRedeemConfig.defaultStrategy == address(0)) {
                    revert InsufficientCollateral(_collateral, address(0), calculatedCollateralAmt, vaultAmt);
                }
                strategy = IStrategy(collateralRedeemConfig.defaultStrategy);
            } else {
                // Withdraw from specified strategy
                if (!ICollateralManager(collateralManager).isValidStrategy(_collateral, _strategyAddr)) {
                    revert InvalidStrategy(_collateral, _strategyAddr);
                }
                strategy = IStrategy(_strategyAddr);
            }
            uint256 availableBal = strategy.checkAvailableBalance(_collateral);
            if (availableBal < strategyAmt) {
                revert InsufficientCollateral(
                    _collateral, _strategyAddr, calculatedCollateralAmt, vaultAmt + availableBal
                );
            }
        } else {
            // @dev Case where the redemption amount is less <= vaultAmt
            vaultAmt = calculatedCollateralAmt;
        }
    }
}

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFeeCalculator {
    /// @notice Calculates fee to be collected for minting
    /// @param _collateralAddr Address of the collateral
    /// @return (uint256) baseFeeIn
    function getMintFee(address _collateralAddr) external view returns (uint256);

    /// @notice Calculates fee to be collected for redeeming
    /// @param _collateralAddr Address of the collateral
    /// @return (uint256) baseFeeOut
    function getRedeemFee(address _collateralAddr) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUSDs {
    function mint(address _account, uint256 _amount) external;

    function burn(uint256 _amount) external;

    function rebase(uint256 _rebaseAmt) external;

    function totalSupply() external view returns (uint256);

    function nonRebasingSupply() external view returns (uint256);

    function creditsBalanceOf(address _account) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOracle {
    struct PriceData {
        uint256 price;
        uint256 precision;
    }

    struct PriceFeedData {
        address source;
        bytes msgData;
    }

    /// @notice Validates if price feed exists for a `_token`
    /// @param _token address of the desired token.
    /// @return bool if price feed exists.
    /// @dev Function reverts if price feed not set.
    function priceFeedExists(address _token) external view returns (bool);

    /// @notice Gets the price feed for `_token`.
    /// @param _token address of the desired token.
    /// @return (uint256 price, uint256 precision).
    /// @dev Function reverts if the price feed does not exists.
    function getPrice(address _token) external view returns (PriceData memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRebaseManager {
    function fetchRebaseAmt() external returns (uint256);

    function getMinAndMaxRebaseAmt() external view returns (uint256, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICollateralManager {
    struct CollateralBaseData {
        bool mintAllowed;
        bool redeemAllowed;
        bool allocationAllowed;
        uint16 baseMintFee;
        uint16 baseRedeemFee;
        uint16 downsidePeg;
        uint16 desiredCollateralComposition;
    }

    struct CollateralMintData {
        bool mintAllowed;
        uint16 baseMintFee;
        uint16 downsidePeg;
        uint16 desiredCollateralComposition;
        uint256 conversionFactor;
    }

    struct CollateralRedeemData {
        bool redeemAllowed;
        address defaultStrategy;
        uint16 baseRedeemFee;
        uint16 desiredCollateralComposition;
        uint256 conversionFactor;
    }

    /// @notice Update existing collateral configuration
    /// @param _collateral Address of the collateral
    /// @param _updateData Updated configuration for the collateral
    function updateCollateralData(address _collateral, CollateralBaseData memory _updateData) external;

    function updateCollateralDefaultStrategy(address _collateral, address _strategy) external;

    /// @notice Validate allocation for a collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the desired strategy
    /// @param _amount Amount to be allocated.
    /// @return True for valid allocation request.
    function validateAllocation(address _collateral, address _strategy, uint256 _amount) external view returns (bool);

    /// @notice Get the required data for mint
    /// @param _collateral Address of the collateral
    /// @return Base fee config for collateral (baseMintFee, baseRedeemFee, composition, totalCollateral)
    function getFeeCalibrationData(address _collateral) external view returns (uint16, uint16, uint16, uint256);

    /// @notice Get the required data for mint
    /// @param _collateral Address of the collateral
    /// @return mintData
    function getMintParams(address _collateral) external view returns (CollateralMintData memory mintData);

    /// @notice Get the required data for USDs redemption
    /// @param _collateral Address of the collateral
    /// @return redeemData
    function getRedeemParams(address _collateral) external view returns (CollateralRedeemData memory redeemData);

    /// @notice Gets list of all the listed collateral
    /// @return address[] of listed collaterals
    function getAllCollaterals() external view returns (address[] memory);

    /// @notice Get the amount of collateral in all Strategies
    /// @param _collateral Address of the collateral
    /// @return amountInStrategies
    function getCollateralInStrategies(address _collateral) external view returns (uint256 amountInStrategies);

    /// @notice Get the amount of collateral in vault
    /// @param _collateral Address of the collateral
    /// @return amountInVault
    function getCollateralInVault(address _collateral) external view returns (uint256 amountInVault);

    /// @notice Verify if a strategy is linked to a collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @return boolean true if the strategy is linked to the collateral
    function isValidStrategy(address _collateral, address _strategy) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStrategy {
    /// @notice Deposit asset into the strategy
    /// @param _asset Address of the asset
    /// @param _amount Amount of asset to be deposited
    function deposit(address _asset, uint256 _amount) external;

    /// @notice Withdraw `_asset` to `_recipient` (usually vault)
    /// @param _recipient Address of the recipient
    /// @param _asset Address of the asset
    /// @param _amount Amount to be withdrawn
    /// @return amountReceived The actual amount received
    function withdraw(address _recipient, address _asset, uint256 _amount) external returns (uint256);

    /// @notice Check if collateral allocation is supported by the strategy
    /// @param _asset Address of the asset which is to be checked
    /// @return isSupported True if supported and False if not
    function supportsCollateral(address _asset) external view returns (bool);

    /// @notice Get the amount of a specific asset held in the strategy
    ///           excluding the interest
    /// @dev    Assuming balanced withdrawal
    /// @param  _asset      Address of the asset
    /// @return Balance of the asset
    function checkBalance(address _asset) external view returns (uint256);

    /// @notice Gets the amount of asset withdrawable at any given time
    /// @param _asset Address of the asset
    /// @return availableBalance Available balance of the asset
    function checkAvailableBalance(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title A standard library for errors and constant values
/// @author Sperax Foundation
library Helpers {
    // Constants
    uint16 internal constant MAX_PERCENTAGE = 10000;
    address internal constant SPA = 0x5575552988A3A80504bBaeB1311674fCFd40aD4B;
    address internal constant USDS = 0xD74f5255D557944cf7Dd0E45FF521520002D5748;

    // Errors
    error CustomError(string message);
    error InvalidAddress();
    error GTMaxPercentage(uint256 actual);
    error InvalidAmount();
    error MinSlippageError(uint256 actualAmt, uint256 minExpectedAmt);
    error MaxSlippageError(uint256 actualAmt, uint256 maxExpectedAmt);

    /// @notice Checks the expiry of a transaction's deadline
    /// @param _deadline Deadline specified by the sender of the transaction
    /// @dev Reverts if the current block's timestamp is greater than `_deadline`
    function _checkDeadline(uint256 _deadline) internal view {
        if (block.timestamp > _deadline) revert CustomError("Deadline passed");
    }

    /// @notice Checks for a non-zero address
    /// @param _addr Address to be validated
    /// @dev Reverts if `_addr` is equal to `address(0)`
    function _isNonZeroAddr(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }

    /// @notice Checks for a non-zero amount
    /// @param _amount Amount to be validated
    /// @dev Reverts if `_amount` is equal to `0`
    function _isNonZeroAmt(uint256 _amount) internal pure {
        if (_amount == 0) revert InvalidAmount();
    }

    /// @notice Checks for a non-zero amount with a custom error message
    /// @param _amount Amount to be validated
    /// @param _err Custom error message
    /// @dev Reverts if `_amount` is equal to `0` with the provided custom error message
    function _isNonZeroAmt(uint256 _amount, string memory _err) internal pure {
        if (_amount == 0) revert CustomError(_err);
    }

    /// @notice Checks whether the `_percentage` is less than or equal to `MAX_PERCENTAGE`
    /// @param _percentage The percentage to be checked
    /// @dev Reverts if `_percentage` is greater than `MAX_PERCENTAGE`
    function _isLTEMaxPercentage(uint256 _percentage) internal pure {
        if (_percentage > MAX_PERCENTAGE) revert GTMaxPercentage(_percentage);
    }

    /// @notice Checks whether the `_percentage` is less than or equal to `MAX_PERCENTAGE` with a custom error message
    /// @param _percentage The percentage to be checked
    /// @param _err Custom error message
    /// @dev Reverts with the provided custom error message if `_percentage` is greater than `MAX_PERCENTAGE`
    function _isLTEMaxPercentage(uint256 _percentage, string memory _err) internal pure {
        if (_percentage > MAX_PERCENTAGE) revert CustomError(_err);
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