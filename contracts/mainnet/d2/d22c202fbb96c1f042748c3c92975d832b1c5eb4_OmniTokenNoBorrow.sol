// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IOmniPool.sol";
import "./interfaces/IOmniTokenNoBorrow.sol";
import "./SubAccount.sol";
import "./WithUnderlying.sol";

/**
 * @title OmniTokenNoBorrow
 * @notice This contract represents a token pool with deposit and withdrawal capabilities, without borrowing features. Should only be used for isolated collateral, never borrowable. There is only supply caps.
 * @dev It inherits functionalities from WithUnderlying, ReentrancyGuardUpgradeable (includes Initializable), and implements IOmniTokenNoBorrow interface.
 * The contract allows depositors to deposit and withdraw their funds, and for the OmniPool to seize funds if necessary.
 * It keeps track of the total supply and individual balances, and enforces a supply cap. This contract does not handle rebasing tokens.
 */
contract OmniTokenNoBorrow is IOmniTokenNoBorrow, WithUnderlying, ReentrancyGuardUpgradeable {
    using SubAccount for address;

    uint256 private constant MAX_VIEW_ACCOUNTS = 25;

    address public omniPool;
    uint256 public totalSupply;
    uint256 public supplyCap;
    mapping(bytes32 => uint256) public balanceOfAccount;

    /**
     * @notice Contract initializes the OmniTokenNoBorrow with required parameters.
     * @param _omniPool Address of the OmniPool contract.
     * @param _underlying Address of the underlying asset.
     * @param _supplyCap Initial supply cap.
     */
    function initialize(address _omniPool, address _underlying, uint256 _supplyCap) external initializer {
        __ReentrancyGuard_init();
        __WithUnderlying_init(_underlying);
        omniPool = _omniPool;
        supplyCap = _supplyCap;
    }

    /**
     * @notice Deposits a specified amount to the account associated with the message sender and the specified subId.
     * @param _subId The sub-account identifier.
     * @param _amount The amount to deposit.
     * @return amount The actual amount deposited.
     */
    function deposit(uint96 _subId, uint256 _amount) external nonReentrant returns (uint256 amount) {
        bytes32 account = msg.sender.toAccount(_subId);
        amount = _inflowTokens(msg.sender, _amount);
        require(totalSupply + amount <= supplyCap, "OmniTokenNoBorrow::deposit: Supply cap exceeded.");
        totalSupply += amount;
        balanceOfAccount[account] += amount;
        emit Deposit(account, amount);
    }

    /**
     * @notice Withdraws a specified amount from the account associated with the message sender and the specified subId.
     * @param _subId The sub-account identifier.
     * @param _amount The amount to withdraw.
     * @return amount The actual amount withdrawn.
     */
    function withdraw(uint96 _subId, uint256 _amount) external nonReentrant returns (uint256 amount) {
        bytes32 account = msg.sender.toAccount(_subId);
        if (_amount == 0) {
            _amount = balanceOfAccount[account];
        }
        balanceOfAccount[account] -= _amount;
        totalSupply -= _amount;
        amount = _outflowTokens(msg.sender, _amount);
        require(IOmniPool(omniPool).isAccountHealthy(account), "OmniTokenNoBorrow::withdraw: Not healthy.");
        emit Withdraw(account, amount);
    }

    /**
     * @notice Transfers a specified amount of tokens from the sender's account to another account.
     * The transfer operation is subject to the sender's account remaining healthy post-transfer.
     * @dev This function can only be called externally and is protected against reentrant calls.
     * @param _subId The subscription ID associated with the sender's account.
     * @param _to The account identifier to which the tokens are being transferred.
     * @param _amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful.
     */
    function transfer(uint96 _subId, bytes32 _to, uint256 _amount) external nonReentrant returns (bool) {
        bytes32 from = msg.sender.toAccount(_subId);
        balanceOfAccount[from] -= _amount;
        balanceOfAccount[_to] += _amount;
        require(IOmniPool(omniPool).isAccountHealthy(from), "OmniTokenNoBorrow::transfer: Not healthy.");
        emit Transfer(from, _to, _amount);
        return true;
    }

    /**
     * @notice Allows the a liquidator to seize funds from a user's account. OmniPool is responsible for defining how this function is called. Should be called carefully, as it has strong privileges.
     * @param _account The account from which funds are seized.
     * @param _to The account to which funds are transferred.
     * @param _amount The amount of funds to seize.
     * @return seizedShares The shares corresponding to the seized amount.
     */
    function seize(bytes32 _account, bytes32 _to, uint256 _amount)
        external
        override
        nonReentrant
        returns (uint256[] memory)
    {
        require(msg.sender == omniPool, "OmniTokenNoBorrow::seize: Bad caller.");
        uint256 accountBalance = balanceOfAccount[_account];
        if (accountBalance < _amount) {
            _amount = accountBalance;
            balanceOfAccount[_account] = 0;
            balanceOfAccount[_to] += accountBalance;
        } else {
            balanceOfAccount[_account] -= _amount;
            balanceOfAccount[_to] += _amount;
        }
        uint256[] memory seizedShares = new uint256[](1);
        seizedShares[0] = _amount;
        emit Seize(_account, _to, _amount, seizedShares);
        return seizedShares;
    }

    /**
     * @notice Returns the deposit balance of a specific account.
     * @param _account The account identifier.
     * @return The deposit balance of the account.
     */
    function getAccountDepositInUnderlying(bytes32 _account) external view override returns (uint256) {
        return balanceOfAccount[_account];
    }

    /**
     * @notice Sets a new supply cap for the contract.
     * @param _supplyCap The new supply cap amount.
     */
    function setSupplyCap(uint256 _supplyCap) external {
        require(msg.sender == omniPool, "OmniTokenNoBorrow::setSupplyCap: Bad caller.");
        supplyCap = _supplyCap;
        emit SetSupplyCap(_supplyCap);
    }

    /**
     * @notice Calculates the total deposited amount for a specific owner across MAX_VIEW_ACCOUNTS sub-accounts. Above will be excluded, function is imperfect.
     * @dev This is just for wallets and Etherscan to pick up the deposit balance of a user for the first MAX_VIEW_ACCOUNTS sub-accounts.
     * @param _owner The address of the owner.
     * @return The total deposited amount.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        uint256 totalDeposit = 0;
        for (uint96 i = 0; i < MAX_VIEW_ACCOUNTS; ++i) {
            totalDeposit += balanceOfAccount[_owner.toAccount(i)];
        }
        return totalDeposit;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @title IOmniPool Interface
 * @dev This interface outlines the functions available in the OmniPool contract.
 */
interface IOmniPool {
    /// Events
    event ClearedMarkets(bytes32 indexed account);
    event EnteredIsolatedMarket(bytes32 indexed account, address market);
    event EnteredMarkets(bytes32 indexed account, address[] markets);
    event EnteredMode(bytes32 indexed account, uint256 modeId);
    event ExitedMarket(bytes32 indexed account, address market);
    event ExitedMode(bytes32 indexed account);
    event Liquidated(
        address indexed liquidator,
        bytes32 indexed targetAccount,
        bytes32 liquidatorAccount,
        address liquidateMarket,
        address collateralMarket,
        uint256 amount
    );
    event PausedTranche(uint8 trancheId);
    event UnpausedTranche();
    event SetMarketConfiguration(address indexed market, MarketConfiguration marketConfig);
    event RemovedMarketConfiguration(address indexed market);
    event SetModeConfiguration(uint256 indexed modeId, ModeConfiguration modeConfig);
    event SocializedLoss(address indexed market, uint8 trancheId, bytes32 account);

    // Structs
    /**
     * @dev Structure to hold market configuration data.
     */
    struct MarketConfiguration {
        uint32 collateralFactor;
        uint32 borrowFactor; // Set to 0 if not borrowable.
        uint32 expirationTimestamp;
        uint8 riskTranche;
        bool isIsolatedCollateral; // If this is false, riskTranche must be 0
    }

    /**
     * @dev Structure to hold mode configuration data.
     */
    struct ModeConfiguration {
        uint32 collateralFactor;
        uint32 borrowFactor;
        uint8 modeTranche;
        uint32 expirationTimestamp; // Only prevents people from entering a mode, does not affect users already in existing mode
        address[] markets;
    }

    /**
     * @dev Structure to hold account specific data.
     */
    struct AccountInfo {
        uint8 modeId;
        address isolatedCollateralMarket;
        uint32 softThreshold;
    }

    /**
     * @dev Structure to hold evaluation data for an account.
     */
    struct Evaluation {
        uint256 depositTrueValue;
        uint256 borrowTrueValue;
        uint256 depositAdjValue;
        uint256 borrowAdjValue;
        uint64 numDeposit; // To combine into 1 storage slot
        uint64 numBorrow;
        bool isExpired;
    }

    /**
     * @dev Structure to hold liquidation bonus configuration data.
     */
    struct LiquidationBonusConfiguration {
        uint64 start; // 1e9 precision
        uint64 end; // 1e9 precision
        uint64 kink; // 1e9 precision
        uint32 expiredBonus; // 1e9 precision
        uint32 softThreshold; // 1e9 precision
    }

    /**
     * @dev Structure to hold liquidation arguments.
     */
    struct LiquidationParams {
        bytes32 targetAccountId; // The unique identifier of the target account to be liquidated.
        bytes32 liquidatorAccountId; // The unique identifier of the account initiating the liquidation.
        address liquidateMarket; // The address of the market from which to repay the borrow.
        address collateralMarket; // The address of the market from which to seize collateral.
        uint256 amount; // The amount of the target account's borrow balance to repay. If _amount is 0, liquidator will repay the entire borrow balance, and will error if the repayment is too large.
    }

    // Function Signatures
    /**
     * @dev Returns the address of the oracle contract.
     * @return The address of the oracle.
     */
    function oracle() external view returns (address);

    /**
     * @dev Returns the pause tranche value.
     * @return The pause tranche value.
     */
    function pauseTranche() external view returns (uint8);

    /**
     * @dev Returns the reserve receiver.
     * @return The reserve receiver identifier.
     */
    function reserveReceiver() external view returns (bytes32);

    /**
     * @dev Allows a user to enter an isolated market, the market configuration must be for isolated collateral.
     * @param _subId The identifier of the sub-account.
     * @param _isolatedMarket The address of the isolated market to enter.
     */
    function enterIsolatedMarket(uint96 _subId, address _isolatedMarket) external;

    /**
     * @dev Allows a user to enter multiple unique markets, none of them are isolated collateral markets.
     * @param _subId The identifier of the sub-account.
     * @param _markets The addresses of the markets to enter.
     */
    function enterMarkets(uint96 _subId, address[] calldata _markets) external;

    /**
     * @dev Allows a user to exit a single market including their isolated market. There must be no borrows active on the subaccount to exit a market.
     * @param _subId The identifier of the sub-account.
     * @param _market The addresses of the markets to exit.
     */
    function exitMarket(uint96 _subId, address _market) external;

    /**
     * @dev Clears all markets for a user. The subaccount must have no active borrows to clear markets.
     * @param _subId The identifier of the sub-account.
     */
    function clearMarkets(uint96 _subId) external;

    /**
     * @dev Sets a mode for a sub-account.
     * @param _subId The identifier of the sub-account.
     * @param _modeId The identifier of the mode to enter.
     */
    function enterMode(uint96 _subId, uint8 _modeId) external;

    /**
     * @dev Exits the mode currently set for a sub-account.
     * @param _subId The identifier of the sub-account.
     */
    function exitMode(uint96 _subId) external;

    /**
     * @dev Evaluates an account's financial metrics.
     * @param _accountId The identifier of the account.
     * @return eval A struct containing the evaluated metrics of the account.
     */
    function evaluateAccount(bytes32 _accountId) external returns (Evaluation memory eval);

    /**
     * @dev Allows a sub-account to borrow assets from a specified market.
     * @param _subId The identifier of the sub-account.
     * @param _market The address of the market to borrow from.
     * @param _amount The amount of assets to borrow.
     */
    function borrow(uint96 _subId, address _market, uint256 _amount) external;

    /**
     * @dev Allows a sub-account to repay borrowed assets to a specified market.
     * @param _subId The identifier of the sub-account.
     * @param _market The address of the market to repay to.
     * @param _amount The amount of assets to repay.
     */
    function repay(uint96 _subId, address _market, uint256 _amount) external;

    /**
     * @dev Initiates a liquidation process to recover assets from an under-collateralized account.
     * @param _params The liquidation parameters.
     * @return seizedShares The amount of shares seized from the liquidated account.
     */
    function liquidate(
        LiquidationParams calldata _params
    ) external returns (uint256[] memory seizedShares);

    /**
     * @dev Distributes loss incurred in a market to a specified tranche of accounts.
     * @param _market The address of the market where the loss occurred.
     * @param _account The account identifier to record the loss.
     */
    function socializeLoss(address _market, bytes32 _account) external;

    /**
     * @dev Retrieves the borrow tier of an account.
     * @param _account The account info struct containing the account's details.
     * @return The borrowing tier of the account.
     */
    function getAccountBorrowTier(AccountInfo memory _account) external view returns (uint8);

    /**
     * @dev Retrieves the market addresses associated with an account.
     * @param _accountId The identifier of the account.
     * @param _account The account info struct containing the account's details.
     * @return A list of market addresses associated with the account.
     */
    function getAccountPoolMarkets(bytes32 _accountId, AccountInfo memory _account)
        external
        view
        returns (address[] memory);

    /**
     * @dev Retrieves the liquidation bonus and soft threshold values for a market.
     * @param _depositAdjValue The adjusted value of deposits in the market.
     * @param _borrowAdjValue The adjusted value of borrows in the market.
     * @param _collateralMarket The address of the collateral market.
     * @return bonus The liquidation bonus value.
     * @return softThreshold The soft liquidation threshold value.
     */
    function getLiquidationBonusAndThreshold(
        uint256 _depositAdjValue,
        uint256 _borrowAdjValue,
        address _collateralMarket
    ) external view returns (uint256 bonus, uint256 softThreshold);

    /**
     * @dev Checks if an account is healthy based on its financial metrics.
     * @param _accountId The identifier of the account.
     * @return A boolean indicating whether the account is healthy.
     */
    function isAccountHealthy(bytes32 _accountId) external returns (bool);

    /**
     * @dev Resets the pause tranche to its initial state.
     */
    function resetPauseTranche() external;

    /**
     * @dev Updates the market configuration.
     * @param _market The address of the market.
     * @param _marketConfig The market configuration data.
     */
    function setMarketConfiguration(address _market, MarketConfiguration calldata _marketConfig) external;

    /**
     * @dev Updates mode configurations one at a time.
     * @param _modeConfiguration An single mode configuration.
     */
    function setModeConfiguration(ModeConfiguration calldata _modeConfiguration) external;

    /**
     * @dev Updates the soft liquidation threshold for an account.
     * @param _accountId The account identifier.
     * @param _softThreshold The soft liquidation threshold value.
     */
    function setAccountSoftLiquidation(bytes32 _accountId, uint32 _softThreshold) external;

    /**
     * @dev Updates the liquidation bonus configuration for a market.
     * @param _market The address of the market.
     * @param _config The liquidation bonus configuration data.
     */
    function setLiquidationBonusConfiguration(address _market, LiquidationBonusConfiguration calldata _config) external;

    /**
     * @notice Sets the tranche count for a specific market.
     * @dev This function allows to set the number of tranches for a given market.
     * It's an external function that can only be called by an account with the `MARKET_CONFIGURATOR_ROLE`.
     * @param _market The address of the market contract.
     * @param _trancheCount The number of tranches to be set for the market.
     */
    function setTrancheCount(address _market, uint8 _trancheCount) external;

    /**
     * @dev This function can only be called by an account with the MARKET_CONFIGURATOR_ROLE.
     * It invokes the setTrancheBorrowCaps function of the IOmniToken contract associated with the specified market.
     * @param _market The address of the market for which to set the borrow caps.
     * @param _borrowCaps An array of borrow cap values, one for each tranche of the market.
     */
    function setBorrowCap(address _market, uint256[] calldata _borrowCaps) external;

    /**
     * @dev This function can only be called by an account with the MARKET_CONFIGURATOR_ROLE.
     * It invokes the setSupplyCap function of the IOmniTokenNoBorrow contract associated with the specified market.
     * @param _market The address of the market for which to set the no-borrow supply cap.
     * @param _noBorrowSupplyCap The value of the no-borrow supply cap to set.
     */
    function setNoBorrowSupplyCap(address _market, uint256 _noBorrowSupplyCap) external;

    /**
     * @notice Sets the reserve receiver's address. This function can only be called by an account with the DEFAULT_ADMIN_ROLE.
     * @dev The reserve receiver's address is converted to a bytes32 account identifier using the toAccount function with a subId of 0.
     * @param _reserveReceiver The address of the reserve receiver to be set.
     */
    function setReserveReceiver(address _reserveReceiver) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IOmniTokenBase.sol";

/**
 * @title IOmniTokenNoBorrow
 * @notice Interface for the OmniTokenNoBorrow contract which provides deposit and withdrawal features, without borrowing features.
 */
interface IOmniTokenNoBorrow is IOmniTokenBase {
    /// Events
    event Deposit(bytes32 indexed account, uint256 amount);
    event Withdraw(bytes32 indexed account, uint256 amount);
    event Seize(bytes32 indexed account, bytes32 indexed to, uint256 amount, uint256[] seizeShares);
    event SetSupplyCap(uint256 supplyCap);
    event Transfer(bytes32 indexed from, bytes32 indexed to, uint256 amount);
    
    /**
     * @notice Deposits a specified amount to the account.
     * @param _subId The sub-account identifier.
     * @param _amount The amount to deposit.
     * @return amount The actual amount deposited.
     */
    function deposit(uint96 _subId, uint256 _amount) external returns (uint256 amount);

    /**
     * @notice Withdraws a specified amount from the account.
     * @param _subId The sub-account identifier.
     * @param _amount The amount to withdraw.
     * @return amount The actual amount withdrawn.
     */
    function withdraw(uint96 _subId, uint256 _amount) external returns (uint256 amount);

    /**
     * @notice Transfers a specified amount of tokens from the sender's account to another account.
     * @param _subId The subscription ID associated with the sender's account.
     * @param _to The account identifier to which the tokens are being transferred.
     * @param _amount The amount of tokens to transfer.
     * @return A boolean value indicating whether the transfer was successful.
     */
    function transfer(uint96 _subId, bytes32 _to, uint256 _amount) external returns (bool);

    /**
     * @notice Sets a new supply cap for the contract.
     * @param _supplyCap The new supply cap amount.
     */
    function setSupplyCap(uint256 _supplyCap) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @title SubAccount
 * @notice This library provides utility functions to handle sub-accounts using bytes32 types, where id is most significant bytes.
 */
library SubAccount {
    /**
     * @notice Combines an address and a sub-account identifier into a bytes32 account representation.
     * @param _sender The address component.
     * @param _subId The sub-account identifier component.
     * @return A bytes32 representation of the account.
     */
    function toAccount(address _sender, uint96 _subId) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_sender)) | (uint256(_subId) << 160));
    }

    /**
     * @notice Extracts the address component from a bytes32 account representation.
     * @param _account The bytes32 representation of the account.
     * @return The address component.
     */
    function toAddress(bytes32 _account) internal pure returns (address) {
        return address(uint160(uint256(_account)));
    }

    /**
     * @notice Extracts the sub-account identifier component from a bytes32 account representation.
     * @param _account The bytes32 representation of the account.
     * @return The sub-account identifier component.
     */
    function toSubId(bytes32 _account) internal pure returns (uint96) {
        return uint96(uint256(_account) >> 160);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IWithUnderlying.sol";

/**
 * @title WithUnderlying
 * @notice A helper contract to handle the inflow and outflow of ERC20 tokens.
 * @dev Utilizes OpenZeppelin's SafeERC20 library to handle ERC20 transactions.
 */
abstract contract WithUnderlying is Initializable, IWithUnderlying {
    using SafeERC20 for IERC20;

    address public underlying;

    /**
     * @notice Initialies the abstract contract instance.
     * @param _underlying The address of the underlying ERC20 token.
     */
    function __WithUnderlying_init(address _underlying) internal onlyInitializing {
        underlying = _underlying;
    }

    /**
     * @notice Retrieves the name of the token.
     * @return The name of the token, either prefixed from the underlying token or the default "Omni Token".
     */
    function name() external view returns (string memory) {
        try IERC20Metadata(underlying).name() returns (string memory data) {
            return string(abi.encodePacked("Omni ", data));
        } catch (bytes memory) {
            return "Omni Token";
        }
    }

    /**
     * @notice Retrieves the symbol of the token.
     * @return The symbol of the token, either prefixed from the underlying token or the default "oToken".
     */
    function symbol() external view returns (string memory) {
        try IERC20Metadata(underlying).symbol() returns (string memory data) {
            return string(abi.encodePacked("o", data));
        } catch (bytes memory) {
            return "oToken";
        }
    }

    /**
     * @notice Retrieves the number of decimals the token uses.
     * @return The number of decimals of the token, either from the underlying token or the default 18.
     */
    function decimals() external view returns (uint8) {
        try IERC20Metadata(underlying).decimals() returns (uint8 data) {
            return data;
        } catch (bytes memory) {
            return 18;
        }
    }

    /**
     * @notice Handles the inflow of tokens to the contract.
     * @dev Transfers `_amount` tokens from `_from` to this contract and returns the actual amount received.
     * @param _from The address from which tokens are transferred.
     * @param _amount The amount of tokens to transfer.
     * @return The actual amount of tokens received by the contract.
     */
    function _inflowTokens(address _from, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    /**
     * @notice Handles the outflow of tokens from the contract.
     * @dev Transfers `_amount` tokens from this contract to `_to` and returns the actual amount sent.
     * @param _to The address to which tokens are transferred.
     * @param _amount The amount of tokens to transfer.
     * @return The actual amount of tokens sent from the contract.
     */
    function _outflowTokens(address _to, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(_to, _amount);
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));
        return balanceBefore - balanceAfter;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/**
 * @title IOmniTokenBase
 * @notice Base interface shared by the IOmniToken and IOmniTokenNoBorrow interfaces.
 */
interface IOmniTokenBase {
    /**
     * @notice Retrieves the total deposit amount for a specific account.
     * @param _account The account identifier.
     * @return The total deposit amount.
     */
    function getAccountDepositInUnderlying(bytes32 _account) external view returns (uint256);

    /**
     * @notice Calculates the total deposited amount for a specific owner across sub-accounts. This funciton is for wallets and Etherscan to pick up balances.
     * @param _owner The address of the owner.
     * @return The total deposited amount.
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @notice Seizes funds from a user's account in the event of a liquidation. This is a priveleged function only callable by the OmniPool and must be implemented carefully.
     * @param _account The account from which funds will be seized.
     * @param _to The account to which seized funds will be sent.
     * @param _amount The amount of funds to seize.
     * @return The shares seized from each tranche.
     */
    function seize(bytes32 _account, bytes32 _to, uint256 _amount) external returns (uint256[] memory);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWithUnderlying
 * @notice Interface for the WithUnderlying contract to handle the inflow and outflow of ERC20 tokens.
 */
interface IWithUnderlying {
    /**
     * @notice Gets the address of the underlying ERC20 token.
     * @return The address of the underlying ERC20 token.
     */
    function underlying() external view returns (address);
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