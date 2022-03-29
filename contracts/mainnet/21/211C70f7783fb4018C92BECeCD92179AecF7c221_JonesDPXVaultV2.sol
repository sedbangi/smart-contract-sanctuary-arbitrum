// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

/// Libraries
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SushiRouterWrapper} from "./library/SushiRouterWrapper.sol";
import {DopexDpxSsovWrapper} from "./library/DopexDpxSsovWrapper.sol";
import {Curve2PoolSsovPutWrapper} from "./library/Curve2PoolSsovPutWrapper.sol";
import {DopexFarmWrapper} from "./library/DopexFarmWrapper.sol";
import {Curve2PoolWrapper} from "./library/Curve2PoolWrapper.sol";

/// Interfaces
import {IDPXSSOVV2} from "../interfaces/IDPXSSOVV2.sol";
import {IDPXSingleStaking} from "../interfaces/IDPXSingleStaking.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IJonesAsset} from "../interfaces/IJonesAsset.sol";
import {ICurve2PoolSsovPut} from "../interfaces/ICurve2PoolSsovPut.sol";
import {IStableSwap} from "../interfaces/IStableSwap.sol";

/// @title Jones DPX V2 Vault
/// @author Jones DAO

contract JonesDPXVaultV2 is Ownable {
    using SafeERC20 for IERC20;
    using SushiRouterWrapper for IUniswapV2Router02;
    using DopexDpxSsovWrapper for IDPXSSOVV2;
    using Curve2PoolSsovPutWrapper for ICurve2PoolSsovPut;
    using Curve2PoolWrapper for IStableSwap;
    using DopexFarmWrapper for IDPXSingleStaking;

    // jDPX Token
    IJonesAsset public jonesAssetToken;

    // DPX Token
    IERC20 public assetToken;

    // DPX SSOV contract
    IDPXSSOVV2 private SSOV;

    // DPX SSOV-P contract
    ICurve2PoolSsovPut private SSOVP;

    // DPX Single Staking contract
    IDPXSingleStaking private DPXFarm;

    // Sushiswap router
    IUniswapV2Router02 private sushiRouter;

    // Curve stable swap
    IStableSwap private stableSwap;

    // SushiRouterSellingtokens
    address[] private sellingTokens;

    // SushiRoutes
    address[][] private routes;

    // true if assets are under management
    // false if users can deposit and claim
    bool public MANAGEMENT_WINDOW_OPEN = true;

    // If epoch as already been settled
    bool public SETTLED_EPOCH = false;

    // vault cap status
    bool public vaultCapSet = false;

    // whether we should charge fees
    bool public chargeFees = false;

    // vault cap value
    uint256 public vaultCap;

    // snapshot of the vault's DPX balance from previous epoch / before management starts
    uint256 public snapshotVaultBalance;

    // snapshot of jDPX total supply from previous epoch / before management starts
    uint256 public snapshotJonesAssetSupply;

    // DAO whitelist mapping
    mapping(address => uint256) public daoWhitelist;

    // Governance address
    address private AUMMultisig;

    // Fee distributor contract address
    address private FeeDistributor;

    // Whitelistoor address
    address private Whitelistoor;

    // rDPX Token address
    address private rDPX;

    // wETH Token address
    address private wETH;

    // USDC Token address
    address private USDC;

    /**
     * @param _jonesAsset jDPX contract address.
     * @param _asset DPX contract address.
     * @param _SSOV SSOV contract address.
     * @param _SSOVP SSOV-P contract address.
     * @param _aumMultisigAddr AUM multisig address.
     * @param _feeDistributor Address to which we send management and performance fees.
     * @param _externalWhitelister Non multisig address which can add new addresses to the DAO whitelist.
     * @param _snapshotVaultBalance Vault balance snapshot value.
     * @param _snapshotJonesAssetSupply jDPX supply snapshot value.
     */
    constructor(
        IJonesAsset _jonesAsset,
        IERC20 _asset,
        IDPXSSOVV2 _SSOV,
        ICurve2PoolSsovPut _SSOVP,
        address _aumMultisigAddr,
        address _feeDistributor,
        address _externalWhitelister,
        uint256 _snapshotVaultBalance,
        uint256 _snapshotJonesAssetSupply
    ) {
        if (_aumMultisigAddr == address(0)) revert VE1();
        if (_snapshotVaultBalance == 0) revert VE2();
        if (_snapshotJonesAssetSupply == 0) revert VE2();

        // set snapshot values
        snapshotVaultBalance = _snapshotVaultBalance;
        snapshotJonesAssetSupply = _snapshotJonesAssetSupply;

        // set addresses
        jonesAssetToken = _jonesAsset;
        assetToken = _asset;
        SSOV = _SSOV;
        SSOVP = _SSOVP;
        AUMMultisig = _aumMultisigAddr;
        FeeDistributor = _feeDistributor;
        Whitelistoor = _externalWhitelister;
        rDPX = 0x32Eb7902D4134bf98A28b963D26de779AF92A212;
        wETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        DPXFarm = IDPXSingleStaking(0xc6D714170fE766691670f12c2b45C1f34405AAb6);

        // SushiSwap router
        sushiRouter = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );

        // 2CRV
        stableSwap = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

        // Token spending approval for Curve 2pool
        IERC20(USDC).safeApprove(address(stableSwap), type(uint256).max);

        // Token spending approvals for SushiSwap
        IERC20(rDPX).safeApprove(address(sushiRouter), type(uint256).max);
        IERC20(USDC).safeApprove(address(sushiRouter), type(uint256).max);
        _asset.safeApprove(address(sushiRouter), type(uint256).max);

        // Token spending approval for SSOV
        assetToken.safeApprove(address(SSOV), type(uint256).max);

        // Token spending approval for SSOV-P
        stableSwap.approve(address(SSOVP), type(uint256).max);

        // Token spending approval for DPX Single Staking farm
        assetToken.safeApprove(address(DPXFarm), type(uint256).max);

        sellingTokens = [rDPX, USDC];

        // 0: rDPX -> DPX | 1: USDC -> DPX
        routes = [[rDPX, wETH, address(_asset)], [USDC, wETH, address(_asset)]];

        // Give governance contract ownership
        transferOwnership(_aumMultisigAddr);
    }

    // ============================== Depositing ==============================

    /**
     * Mint jDPX by depositing DPX into the vault.
     * @param _amount Amount of DPX to deposit.
     */
    function depositAsset(uint256 _amount) public {
        _whenNotManagementWindow();
        if (_amount == 0) revert VE2();

        if (vaultCapSet) {
            // if user is a whitelisted DAO
            if (isWhitelisted(msg.sender)) {
                if (_amount > daoWhitelist[msg.sender]) revert VE2();

                // update whitelisted amount
                daoWhitelist[msg.sender] = daoWhitelist[msg.sender] - _amount;

                emit WhitelistUpdate(msg.sender, daoWhitelist[msg.sender]);
            } else {
                if (assetToken.balanceOf(address(this)) + _amount > vaultCap)
                    revert VE3();
            }
        }

        uint256 mintableJAsset = convertToJAsset(_amount);

        // deposit DPX into the vault
        assetToken.safeTransferFrom(msg.sender, address(this), _amount);

        // deposit DPX into single stake farm
        DPXFarm.depositAllIfWhitelisted(address(this));

        // mint jDPX
        jonesAssetToken.mint(msg.sender, mintableJAsset);

        emit Deposited(msg.sender, mintableJAsset, _amount);
    }

    // ============================== Claiming ==============================

    /**
     * Burn jDPX and redeem DPX from the vault.
     * @dev Assumes both tokens have same decimal places.
     * @param _amount Amount of jDPX to burn.
     */
    function claimAsset(uint256 _amount) public {
        _whenNotManagementWindow();
        if (_amount == 0) revert VE2();
        if (jonesAssetToken.balanceOf(msg.sender) < _amount) revert VE4();
        uint256 redeemableAsset = convertToAsset(_amount);

        // burn jDPX
        jonesAssetToken.burnFrom(msg.sender, _amount);

        // If not enough balance remove from single stake dpx
        uint256 vaultAssetBalance = assetToken.balanceOf(address(this));
        if (vaultAssetBalance < redeemableAsset) {
            DPXFarm.removeSingleStakeAsset(
                redeemableAsset - vaultAssetBalance,
                false
            );
        }

        // redeem DPX
        assetToken.transfer(msg.sender, redeemableAsset);

        emit Claimed(msg.sender, redeemableAsset, _amount);
    }

    // ============================== Setters ==============================

    /**
     * Claims and deposits close, assets are under vault control.
     */
    function openManagementWindow() public onlyOwner {
        _whenNotManagementWindow();

        // Remove all the deposited assets from the farm
        if (DPXFarm.balanceOf(address(this)) > 0)
            DPXFarm.removeAll(address(this));

        _executeSnapshot();

        // Claim all rewards from the farm
        if (DPXFarm.earnedDPX(address(this)) > 0) DPXFarm.claimRewards();

        MANAGEMENT_WINDOW_OPEN = true;
        emit EpochStarted(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    /**
     * Initial setup of the vault.
     * @dev run when vault should open for the first contract's epoch.
     * @param _vaultCapSet True if vault cap is set.
     * @param _vaultCap Vault cap (18 decimal).
     * @param _snapshotVaultBalance Update vault balance (18 decimal).
     */
    function initialRun(
        bool _vaultCapSet,
        uint256 _vaultCap,
        uint256 _snapshotVaultBalance
    ) public onlyOwner {
        _whenManagementWindow();
        // set vault cap if true
        if (_vaultCapSet) {
            if (_vaultCap == 0) revert VE2();
            vaultCap = _vaultCap;
            vaultCapSet = true;
        }

        snapshotVaultBalance = _snapshotVaultBalance;

        MANAGEMENT_WINDOW_OPEN = false;
        emit EpochEnded(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    /**
     * @notice Settles the SSOV and SSOV-P epochs and exits farms
     * @param _usdcAmount The minumum amount of USDC to receive.
     * @param _ssovEpoch The SSOV epoch to settle.
     * @param _ssovStrikes The SSOV strike indexes to settle.
     * @param _ssovpEpoch The SSOV-P epoch to settle.
     * @param _ssovpStrikes The SSOV-P strike indexes to settle.
     */
    function settleEpoch(
        uint256 _usdcAmount,
        uint256 _ssovEpoch,
        uint256[] memory _ssovStrikes,
        uint256 _ssovpEpoch,
        uint256[] memory _ssovpStrikes
    ) public onlyOwner {
        _whenManagementWindow();

        // claim deposits and settle calls/puts from SSOV/SSOV-P
        SSOV.settleEpoch(address(this), _ssovEpoch, _ssovStrikes);
        SSOVP.settleEpoch(address(this), _ssovpEpoch, _ssovpStrikes);

        // Exit the single stake farm
        DPXFarm.exitIfPossible(address(this));

        // Sell 2CRV for USDC
        uint256 _2crvBalance = stableSwap.balanceOf(address(this));
        if (_2crvBalance > 0)
            stableSwap.swap2CrvForStable(USDC, _2crvBalance, _usdcAmount);

        SETTLED_EPOCH = true;
    }

    /**
     * Used in case of any emergency to withdraw from SSOV's
     * @param _ssovcStrikeIndexes SSOV-C indexes to withdraw (empty if not needed)
     * @param _ssovcEpoch SSOV-C epoch to withdraw
     * @param _ssovpStrikeIndexes SSOV-P indexes to withdraw (empty if not needed)
     * @param _ssovpEpoch SSOV-P epoch to withdraw
     */
    function emergencyWithdrawSSOV(
        uint256[] memory _ssovcStrikeIndexes,
        uint256 _ssovcEpoch,
        uint256[] memory _ssovpStrikeIndexes,
        uint256 _ssovpEpoch
    ) public onlyOwner {
        _whenManagementWindow();
        SSOV.withdrawEpoch(_ssovcStrikeIndexes, _ssovcEpoch);
        SSOVP.withdrawEpoch(_ssovpStrikeIndexes, _ssovpEpoch);
    }

    /**
     * @notice Open vault for deposits and claims.
     * @dev claims rewards from Dopex, sells DPX and rDPX rewards, sends performance fee to fee distributor.
     * @param _vaultCapSet True if vault cap is set.
     * @param _vaultCap Vault cap (18 decimal).
     * @param _assetAmtFromrDpx wETH output amount from selling rDPX.
     * @param _assetAmtFromrUsdc The minumum amount of DPX to receive from selling USDC
     */
    function closeManagementWindow(
        bool _vaultCapSet,
        uint256 _vaultCap,
        uint256 _assetAmtFromrDpx,
        uint256 _assetAmtFromrUsdc
    ) public onlyOwner {
        _whenManagementWindow();
        if (!SETTLED_EPOCH) revert VE8();

        // Sell rDPX and USDC for DPX
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _assetAmtFromrDpx;
        amounts[1] = _assetAmtFromrUsdc;

        sushiRouter.sellTokens(amounts, sellingTokens, address(this), routes);

        // Charge fees if needed
        _chargeFees();

        // update snapshot
        _executeSnapshot();

        // deposit DPX into single stake farm
        if (assetToken.balanceOf(address(this)) > 0) {
            DPXFarm.depositAllIfWhitelisted(address(this));
        }

        // set vault cap if true
        if (_vaultCapSet) {
            if (_vaultCap == 0) revert VE2();
            vaultCap = _vaultCap;
            vaultCapSet = true;
        }

        MANAGEMENT_WINDOW_OPEN = false;
        SETTLED_EPOCH = false;
        emit EpochEnded(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    /**
     * Update SSOV contract address in case it changes.
     * @dev This function is called by the AUM multisig.
     */
    function updateSSOVAddress(IDPXSSOVV2 _newSSOV) public onlyOwner {
        assetToken.safeApprove(address(SSOV), 0); // revoke old
        SSOV = _newSSOV;
        assetToken.safeApprove(address(SSOV), type(uint256).max); // approve new
    }

    /**
     * Update SSOV-P contract address in case it changes.
     * @dev This function is called by the AUM multisig.
     */
    function updateSSOVPAddress(ICurve2PoolSsovPut _newSSOVP) public onlyOwner {
        stableSwap.approve(address(SSOVP), 0); // revoke old
        SSOVP = _newSSOVP;
        stableSwap.approve(address(SSOVP), type(uint256).max); // approve new
    }

    /**
     * Update vault value snapshot.
     */
    function _executeSnapshot() private {
        snapshotJonesAssetSupply = jonesAssetToken.totalSupply();
        snapshotVaultBalance = assetToken.balanceOf(address(this));

        emit Snapshot(
            block.timestamp,
            snapshotVaultBalance,
            snapshotJonesAssetSupply
        );
    }

    /**
     * Charge performance and management fees if needed
     */
    function _chargeFees() private {
        if (chargeFees) {
            uint256 balanceNow = assetToken.balanceOf(address(this));

            if (balanceNow > snapshotVaultBalance) {
                // send performance fee to fee distributor (20% on profit wrt benchmark)
                // 1 / 5 = 20 / 100
                assetToken.safeTransfer(
                    FeeDistributor,
                    (balanceNow - snapshotVaultBalance) / 5
                );
            }
            // send management fee to fee distributor (2% annually)
            // 1 / 600 = 2 / (100 * 12)
            assetToken.safeTransfer(FeeDistributor, snapshotVaultBalance / 600);
        }
    }

    // ============================== AUM multisig functions ==============================

    /**
     * Migrate vault to new vault contract.
     * @dev acts as emergency withdrawal if needed.
     * @param _to New vault contract address.
     * @param _tokens Addresses of tokens to be migrated.
     */
    function migrateVault(address _to, address[] memory _tokens)
        public
        onlyOwner
    {
        // migrate other ERC20 Tokens
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 tkn = IERC20(_tokens[i]);
            uint256 assetBalance = tkn.balanceOf(address(this));
            if (assetBalance > 0) {
                tkn.safeTransfer(_to, assetBalance);
            }
        }

        // migrate ETH balance
        uint256 balanceGwei = address(this).balance;
        if (balanceGwei > 0) {
            payable(_to).transfer(balanceGwei);
        }
    }

    /**
     * Update whether we should be charging fees.
     */
    function setChargeFees(bool _status) public onlyOwner {
        chargeFees = _status;
    }

    // ============================== Dopex interaction ==============================

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of DPX to deposit.
     * @return Whether deposit was successful.
     */
    function depositSSOV(uint256 _strikeIndex, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        _whenManagementWindow();
        return SSOV.depositSSOV(_strikeIndex, _amount, address(this));
    }

    /**
     * Deposits funds to SSOV at multiple desired strike prices.
     * @param _strikeIndices Strike price indices.
     * @param _amounts Amounts of DPX to deposit.
     * @return Whether deposits went through successfully.
     */
    function depositSSOVMultiple(
        uint256[] memory _strikeIndices,
        uint256[] memory _amounts
    ) public onlyOwner returns (bool) {
        _whenManagementWindow();
        return
            SSOV.depositSSOVMultiple(_strikeIndices, _amounts, address(this));
    }

    /**
     * Buys calls from Dopex SSOV.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of calls to purchase.
     * @return Whether call purchase went through successfully.
     */
    function purchaseCall(uint256 _strikeIndex, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        _whenManagementWindow();
        return SSOV.purchaseCall(_strikeIndex, _amount, address(this));
    }

    /**
     * Deposits funds to SSOV-P at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of 2CRV to deposit.
     * @return Whether deposit was successful.
     */
    function depositSSOVP(uint256 _strikeIndex, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        _whenManagementWindow();
        return SSOVP.depositSSOVP(_strikeIndex, _amount, address(this));
    }

    /**
     * Deposits funds to SSOV at multiple desired strike prices.
     * @param _strikeIndices Strike price indices.
     * @param _amounts Amounts of DPX to deposit.
     * @return Whether deposits went through successfully.
     */
    function depositSSOVPMultiple(
        uint256[] memory _strikeIndices,
        uint256[] memory _amounts
    ) public onlyOwner returns (bool) {
        _whenManagementWindow();
        return
            SSOVP.depositSSOVPMultiple(_strikeIndices, _amounts, address(this));
    }

    /** Buys puts from Dopex SSOV-P.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of puts to purchase.
     * @return Whether put purchase went through sucessfully.
     */
    function purchasePut(uint256 _strikeIndex, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        _whenManagementWindow();
        return SSOVP.purchasePut(_strikeIndex, _amount, address(this));
    }

    // ============================== DPX Single Stake Interactions ==============================

    /**
     * Single stakes DPX in Dopex farms.
     * @param _amount Amount of DPX to stake.
     * @return Whether staking was successful.
     */
    function addSingleStakeDPX(uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        _whenManagementWindow();
        return DPXFarm.addSingleStakeAsset(_amount);
    }

    /**
     * Unstakes DPX from Dopex farms and collects rewards.
     * @param _amount Amount of DPX to unstake.
     * @param _getRewards If true gets the farm rewards.
     * @return Whether unstaking was successful.
     */
    function removeSingleStakeDPX(uint256 _amount, bool _getRewards)
        public
        onlyOwner
        returns (bool)
    {
        _whenManagementWindow();
        return DPXFarm.removeSingleStakeAsset(_amount, _getRewards);
    }

    /**
     * Unstakes all DPX from Dopex farms and collects rewards.
     * @return Whether exiting position was successful.
     */
    function exitSingleStakeDPX() public onlyOwner returns (bool) {
        return DPXFarm.exitSingleStakeAsset();
    }

    /**
     * Compounds DPX farming rewards.
     * @return Whether compounding was successful.
     */
    function compoundSingleStakeDPX() public onlyOwner returns (bool) {
        _whenManagementWindow();
        return DPXFarm.compoundRewards();
    }

    // ============================== 2CRV Interactions ==============================

    /**
     * @notice Sells the base asset for 2CRV
     * @param _baseAmount The amount of base asset to sell
     * @param _stableToken The address of the stable token that will be used as intermediary to get 2CRV
     * @param _minStableAmount The minimum amount of `_stableToken` to get when swapping base
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * @return The amount of 2CRV tokens
     */
    function sellBaseFor2Crv(
        uint256 _baseAmount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount
    ) public onlyOwner returns (uint256) {
        _whenManagementWindow();
        return
            stableSwap.swapTokenFor2Crv(
                address(assetToken),
                _baseAmount,
                _stableToken,
                _minStableAmount,
                _min2CrvAmount,
                address(this)
            );
    }

    /**
     * @notice Sells 2CRV for the base asset
     * @param _amount The amount of 2CRV to sell
     * @param _stableToken The address of the stable token to receive when removing 2CRV lp
     * @param _minStableAmount The minimum amount of `_stableToken` to get when swapping 2CRV
     * @param _minAssetAmount The minimum amount of base asset to receive
     * @return The amount of base asset
     */
    function sell2CrvForBase(
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minAssetAmount
    ) public onlyOwner returns (uint256) {
        _whenManagementWindow();
        return
            stableSwap.swap2CrvForToken(
                address(assetToken),
                _amount,
                _stableToken,
                _minStableAmount,
                _minAssetAmount,
                address(this)
            );
    }

    // ============================== DAO Whitelist ==============================

    /**
     * Updates whitelisted amount for a DAO. (Set to 0 to remove)
     * @param _addr whitelisted address.
     * @param _amount whitelisted deposit amount for this DAO.
     */
    function updateWhitelistedAmount(address _addr, uint256 _amount) public {
        _onlyWhitelistoors();
        daoWhitelist[_addr] = _amount;
        emit WhitelistUpdate(_addr, _amount);
    }

    /**
     * Check if address is whitelisted.
     * @param _addr address to be checked.
     * @return Whether address is whitelisted.
     */
    function isWhitelisted(address _addr) public view returns (bool) {
        return daoWhitelist[_addr] > 0;
    }

    // ============================== Views ==============================

    /**
     * Calculates claimable DPX for a given user.
     * @param _user user address.
     * @return claimable DPX.
     */
    function claimableAsset(address _user) public view returns (uint256) {
        uint256 usrBalance = jonesAssetToken.balanceOf(_user);
        if (usrBalance > 0) {
            return convertToAsset(usrBalance);
        }
        return 0;
    }

    /**
     * Calculates claimable DPX amount for a given amount of jDPX.
     * @param _jAssetAmount Amount of jDPX.
     * @return claimable DPX amount.
     */
    function convertToAsset(uint256 _jAssetAmount)
        public
        view
        returns (uint256)
    {
        return
            (_jAssetAmount * snapshotVaultBalance) / snapshotJonesAssetSupply;
    }

    /**
     * Calculates mintable jDPX amount for a given amount of DPX.
     * @param _assetAmount Amount of DPX.
     * @return mintable jDPX amount.
     */
    function convertToJAsset(uint256 _assetAmount)
        public
        view
        returns (uint256)
    {
        return (_assetAmount * snapshotJonesAssetSupply) / snapshotVaultBalance;
    }

    // ============================== Helpers ==============================

    /**
     * When both deposits and claiming are closed, vault can manage DPX.
     */
    function _whenManagementWindow() internal view {
        if (!MANAGEMENT_WINDOW_OPEN) revert VE5();
    }

    /**
     * When management window is closed, deposits and claiming are open.
     */
    function _whenNotManagementWindow() internal view {
        if (MANAGEMENT_WINDOW_OPEN) revert VE6();
    }

    /**
     * When message sender is either the multisig or the whitelist manager
     */
    function _onlyWhitelistoors() internal view {
        if (!(msg.sender == owner() || msg.sender == Whitelistoor))
            revert VE7();
    }

    // ============================== Events ==============================

    /**
     * emitted on user deposit
     * @param _from depositor address (indexed)
     * @param _assetAmount DPX deposit amount
     * @param _jonesAssetAmount jDPX mint amount
     */
    event Deposited(
        address indexed _from,
        uint256 _assetAmount,
        uint256 _jonesAssetAmount
    );

    /**  emitted on user claim
     * @param _from claimer address (indexed)
     * @param _assetAmount DPX claim amount
     * @param _jonesAssetAmount jDPX burn amount
     */
    event Claimed(
        address indexed _from,
        uint256 _assetAmount,
        uint256 _jonesAssetAmount
    );

    /**
     * emitted when vault balance snapshot is taken
     * @param _timestamp snapshot timestamp (indexed)
     * @param _vaultBalance vault balance value
     * @param _jonesAssetSupply jDPX total supply value
     */
    event Snapshot(
        uint256 indexed _timestamp,
        uint256 _vaultBalance,
        uint256 _jonesAssetSupply
    );

    /**
     * emitted when asset management window is opened
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetAmount new vault balance value
     * @param _jonesAssetSupply jDPX total supply at this time
     */
    event EpochStarted(
        uint256 indexed _timestamp,
        uint256 _assetAmount,
        uint256 _jonesAssetSupply
    );

    /** emitted when claim and deposit windows are open
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetAmount new vault balance value
     * @param _jonesAssetSupply jDPX total supply at this time
     */
    event EpochEnded(
        uint256 indexed _timestamp,
        uint256 _assetAmount,
        uint256 _jonesAssetSupply
    );

    /**
     * emitted when whitelist is updated
     * @param _address whitelisted address (indexed)
     * @param _amount whitelisted new amount
     */
    event WhitelistUpdate(address indexed _address, uint256 _amount);

    /**
     * Errors
     */
    error VE1();
    error VE2();
    error VE3();
    error VE4();
    error VE5();
    error VE6();
    error VE7();
    error VE8();
}

/**
 * ERROR MAPPING:
 * {
 *   "VE1": "Vault: Address cannot be a zero address",
 *   "VE2": "Vault: Invalid amount",
 *   "VE3": "Vault: Amount exceeds vault cap",
 *   "VE4": "Vault: Insufficient balance",
 *   "VE5": "Vault: Management window is not open",
 *   "VE6": "Vault: Management window is  open",
 *   "VE7": "Vault: User does not have whitelisting permissions",
 *   "VE8": "Vault: Cannot close management window if settle is not done"
 * }
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

library SushiRouterWrapper {
    using SafeERC20 for IERC20;

    /**
     * Sells the received tokens for the provided amounts for the last token in the route
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token
     */
    function sellTokens(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokens(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    /**
     * Sells the received tokens for the provided amounts for ETH
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token.
     */
    function sellTokensForEth(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokensForEth(
                self,
                IERC20(_tokens[i]),
                _assetAmounts[i],
                _recepient,
                deadline,
                _routes[i]
            );
        }
    }

    /**
     * Sells one token for a given amount of another.
     * @param self the Sushi router used to perform the sale.
     * @param _route route to swap the token.
     * @param _assetAmount output amount of the last token in the route from selling the first.
     * @param _recepient recepient address.
     */
    function sellTokensForExactTokens(
        IUniswapV2Router02 self,
        address[] memory _route,
        uint256 _assetAmount,
        address _recepient,
        address _token
    ) public {
        require(_route.length >= 2, "SRE2");
        uint256 balance = IERC20(_route[0]).balanceOf(_recepient);
        if (balance > 0) {
            uint256 deadline = block.timestamp + 120; // Two minutes
            _sellTokens(
                self,
                IERC20(_token),
                _assetAmount,
                _recepient,
                deadline,
                _route
            );
        }
    }

    function _sellTokensForEth(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForETH(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    function _sellTokens(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForTokens(
                balance,
                _assetAmount,
                _route,
                _recepient,
                _deadline
            );
        }
    }

    // ERROR MAPPING:
    // {
    //   "SRE1": "Rewards: token, amount and routes lenght must match",
    //   "SRE2": "Length of route must be at least 2",
    // }
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDPXSSOVV2} from "../../interfaces/IDPXSSOVV2.sol";

library DopexDpxSsovWrapper {
    using SafeERC20 for IERC20;

    address constant TOKEN = 0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55;

    // ============================== Dopex Arb Ssov wrapper interaction ==============================

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of token to deposit.
     * @param _depositor The depositor contract
     * @return Whether deposit was successful.
     */
    function depositSSOV(
        IDPXSSOVV2 self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _depositor
    ) public returns (bool) {
        self.deposit(_strikeIndex, _amount, _depositor);
        emit SSOVDeposit(self.currentEpoch(), _strikeIndex, _amount, TOKEN);
        return true;
    }

    /**
     * Deposits funds to SSOV at multiple desired strike prices.
     * @param _strikeIndices Strike price indices.
     * @param _amounts Amounts of ETH to deposit.
     * @param _depositor The depositor contract
     * @return Whether deposits went through successfully.
     */
    function depositSSOVMultiple(
        IDPXSSOVV2 self,
        uint256[] memory _strikeIndices,
        uint256[] memory _amounts,
        address _depositor
    ) public returns (bool) {
        require(
            _strikeIndices.length == _amounts.length,
            "Arguments Lenght do not match"
        );

        self.depositMultiple(_strikeIndices, _amounts, _depositor);

        for (uint256 i = 0; i < _amounts.length; i++) {
            emit SSOVDeposit(
                self.currentEpoch(),
                _strikeIndices[i],
                _amounts[i],
                TOKEN
            );
        }

        return true;
    }

    /**
     * Buys calls from Dopex SSOV.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of calls to purchase.
     * @param _buyer call buyer
     * @return Whether call purchase went through successfully.
     */
    function purchaseCall(
        IDPXSSOVV2 self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _buyer
    ) public returns (bool) {
        (uint256 premium, uint256 totalFee) = self.purchase(
            _strikeIndex,
            _amount,
            _buyer
        );
        emit SSOVCallPurchase(
            self.currentEpoch(),
            _strikeIndex,
            _amount,
            premium,
            totalFee,
            TOKEN
        );
        return true;
    }

    /**
     * Claims deposits and settle calls from Dopex SSOV at the end of an epoch.
     * @param _caller the address seleting the epoch
     * @param _epoch the epoch to settle
     * @param _strikes the strikes to settle
     * @return Whether settling was successful.
     */
    function settleEpoch(
        IDPXSSOVV2 self,
        address _caller,
        uint256 _epoch,
        uint256[] memory _strikes
    ) public returns (bool) {
        if (_strikes.length == 0) {
            return false;
        }

        uint256 price = self.settlementPrices(_epoch);

        // calls
        address[] memory strikeTokens = self.getEpochStrikeTokens(_epoch);
        for (uint256 i = 0; i < _strikes.length; i++) {
            uint256 index = _strikes[i];
            // Get the strike token
            IERC20 strikeToken = IERC20(strikeTokens[index]);
            // Obtain the current balance
            uint256 strikeTokenBalance = strikeToken.balanceOf(_caller);
            // Get the strike price
            uint256 strikePrice = self.epochStrikes(_epoch, index);
            // Calculate PnL
            uint256 pnl = self.calculatePnl(
                price,
                strikePrice,
                strikeTokenBalance
            );

            // Settle only if possible
            if (strikeTokenBalance > 0 && pnl > 0) {
                strikeToken.safeApprove(address(self), strikeTokenBalance);
                self.settle(index, strikeTokenBalance, _epoch);
            }
        }

        // deposits
        uint256[] memory vaultDeposits = self.getUserEpochDeposits(
            _epoch,
            _caller
        );
        for (uint256 i = 0; i < vaultDeposits.length; i++) {
            if (vaultDeposits[i] > 0) {
                self.withdraw(_epoch, i);
            }
        }

        return true;
    }

    /**
     * Allows withdraw of ssov deposits, mostly used in case of any emergency.
     * @param _strikeIndexes strikes to withdraw from
     * @param _epoch epoch to withdraw
     */
    function withdrawEpoch(
        IDPXSSOVV2 self,
        uint256[] memory _strikeIndexes,
        uint256 _epoch
    ) public {
        for (uint256 i = 0; i < _strikeIndexes.length; i++) {
            self.withdraw(_epoch, _strikeIndexes[i]);
        }
    }

    // ============================== Events ==============================

    /**
     * Emitted when new Deposit to SSOV is made
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount deposit amount
     */
    event SSOVDeposit(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        address _token
    );

    /**
     * emitted when new call from SSOV is purchased
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount call amount
     * @param _premium call premium
     * @param _totalFee call total fee
     */
    event SSOVCallPurchase(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        uint256 _premium,
        uint256 _totalFee,
        address _token
    );
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {ICurve2PoolSsovPut} from "../../interfaces/ICurve2PoolSsovPut.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Curve2PoolSsovPutWrapper {
    using SafeERC20 for IERC20;

    /**
     * Deposits funds to SSOV at multiple desired strike prices.
     * @param _strikeIndices Strike price indices.
     * @param _amounts Amounts of 2CRV to deposit.
     * @param _depositor The depositor contract
     * @return Whether deposits went through successfully.
     */
    function depositSSOVPMultiple(
        ICurve2PoolSsovPut self,
        uint256[] memory _strikeIndices,
        uint256[] memory _amounts,
        address _depositor
    ) public returns (bool) {
        require(
            _strikeIndices.length == _amounts.length,
            "Lengths of arguments do not match"
        );

        self.depositMultiple(_strikeIndices, _amounts, _depositor);

        for (uint256 i = 0; i < _amounts.length; i++) {
            emit SSOVPDeposit(
                self.currentEpoch(),
                _strikeIndices[i],
                _amounts[i]
            );
        }

        return true;
    }

    /**
     * Deposits funds to SSOV-P at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of 2CRV to deposit.
     * @param _depositor The depositor contract
     * @return Whether deposit was successful.
     */
    function depositSSOVP(
        ICurve2PoolSsovPut self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _depositor
    ) public returns (bool) {
        self.deposit(_strikeIndex, _amount, _depositor);

        emit SSOVPDeposit(self.currentEpoch(), _strikeIndex, _amount);

        return true;
    }

    /**
     * Purchase Dopex puts.
     * @param self Dopex SSOV-P contract.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of puts to purchase.
     * @param _buyer Jones vault contract.
     * @return Whether deposit was successful.
     */
    function purchasePut(
        ICurve2PoolSsovPut self,
        uint256 _strikeIndex,
        uint256 _amount,
        address _buyer
    ) public returns (bool) {
        (uint256 premium, uint256 totalFee) = self.purchase(
            _strikeIndex,
            _amount,
            _buyer
        );

        emit SSOVPutPurchase(
            self.currentEpoch(),
            _strikeIndex,
            _amount,
            premium,
            totalFee,
            self.baseToken()
        );

        return true;
    }

    /**
     * Claims deposits and settle puts from Dopex SSOV-P at the end of an epoch.
     * @param _caller the address settling the epoch
     * @param _epoch the epoch to settle
     * @param _strikes the strikes to settle
     * @return Whether settling was successful.
     */
    function settleEpoch(
        ICurve2PoolSsovPut self,
        address _caller,
        uint256 _epoch,
        uint256[] memory _strikes
    ) public returns (bool) {
        if (_strikes.length == 0) {
            return false;
        }

        uint256 price = self.settlementPrices(_epoch);

        // puts
        address[] memory strikeTokens = self.getEpochStrikeTokens(_epoch);
        for (uint256 i = 0; i < _strikes.length; i++) {
            uint256 index = _strikes[i];
            IERC20 strikeToken = IERC20(strikeTokens[index]);
            uint256 strikeTokenBalance = strikeToken.balanceOf(_caller);
            uint256 strikePrice = self.epochStrikes(_epoch, index);
            uint256 pnl = self.calculatePnl(
                price,
                strikePrice,
                strikeTokenBalance
            );

            if (strikeTokenBalance > 0 && pnl > 0) {
                strikeToken.safeApprove(address(self), strikeTokenBalance);
                self.settle(index, strikeTokenBalance, _epoch);
            }
        }

        // deposits
        uint256[] memory vaultDeposits = self.getUserEpochDeposits(
            _epoch,
            _caller
        );
        for (uint256 i = 0; i < vaultDeposits.length; i++) {
            if (vaultDeposits[i] > 0) {
                self.withdraw(_epoch, i);
            }
        }

        return true;
    }

    /**
     * Allows withdraw of ssov deposits, mostly used in case of any emergency.
     * @param _strikeIndexes strikes to withdraw from
     * @param _epoch epoch to withdraw
     */
    function withdrawEpoch(
        ICurve2PoolSsovPut self,
        uint256[] memory _strikeIndexes,
        uint256 _epoch
    ) public {
        for (uint256 i = 0; i < _strikeIndexes.length; i++) {
            self.withdraw(_epoch, _strikeIndexes[i]);
        }
    }

    // ============================== Events ==============================

    /**
     * emitted when new put from SSOV-P is purchased
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV-P strike index
     * @param _amount put amount
     * @param _premium put premium
     * @param _totalFee put total fee
     */
    event SSOVPutPurchase(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        uint256 _premium,
        uint256 _totalFee,
        address _token
    );

    /**
     * Emitted when new Deposit to SSOV-P is made
     * @param _epoch SSOV-P epoch (indexed)
     * @param _strikeIndex SSOV-P strike index
     * @param _amount deposited 2CRV amount
     */
    event SSOVPDeposit(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount
    );

    // ERROR MAPPING:
    // {
    //   "P1": "Curve 2pool deposit slippage must not exceed 0.05%",
    // }
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/
pragma solidity ^0.8.2;

/// Interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDPXSingleStaking} from "../../interfaces/IDPXSingleStaking.sol";

/// @title A Dopex single stake farm wrapper library
/// @author Jones DAO
/// @notice Adds a few utility functions to Dopex single stake farms
library DopexFarmWrapper {
    /**
     * @notice Stakes an amount of assets
     * @param _amount a parameter just like in doxygen (must be followed by parameter name)
     */
    function addSingleStakeAsset(IDPXSingleStaking self, uint256 _amount)
        external
        returns (bool)
    {
        self.stake(_amount);

        return true;
    }

    /**
     * @notice Stakes the complete balance if the caller is whitelisted
     * @param _caller The address to check whitelist and get the staking token balance
     */
    function depositAllIfWhitelisted(IDPXSingleStaking self, address _caller)
        external
        returns (bool)
    {
        if (self.whitelistedContracts(_caller)) {
            uint256 amount = IERC20(self.stakingToken()).balanceOf(_caller);

            self.stake(amount);
        }

        return true;
    }

    /**
     * @notice Removes an amount from staking with an option to claim rewards
     * @param _amount the amount to withdraw from staking
     * @param _getRewards if true the function will claim rewards
     */
    function removeSingleStakeAsset(
        IDPXSingleStaking self,
        uint256 _amount,
        bool _getRewards
    ) public returns (bool) {
        if (_getRewards) {
            self.getReward(2);
        }

        if (_amount > 0) {
            self.withdraw(_amount);
        }

        return true;
    }

    /**
     * @notice Removes the complete position from staking
     * @param _caller The address to get the deposited balance
     */
    function removeAll(IDPXSingleStaking self, address _caller)
        external
        returns (bool)
    {
        uint256 amount = self.balanceOf(_caller);

        removeSingleStakeAsset(self, amount, false);

        return true;
    }

    /**
     * @notice Claim all rewards
     */
    function claimRewards(IDPXSingleStaking self) external returns (bool) {
        return removeSingleStakeAsset(self, 0, true);
    }

    /**
     * @notice Removes all assets from the farm and claim all rewards
     */
    function exitSingleStakeAsset(IDPXSingleStaking self)
        external
        returns (bool)
    {
        self.exit();

        return true;
    }

    /**
     * @notice Removes all assets from the farm and claim rewards only if the caller has assets staked
     * @param _caller the address used to check if it has staked assets on the farm
     */
    function exitIfPossible(IDPXSingleStaking self, address _caller)
        external
        returns (bool)
    {
        if (self.balanceOf(_caller) > 0) {
            self.exit();
        }

        return true;
    }

    /**
     * @notice Obtain the amount of DPX earned on the farm
     * @param _caller the address used to check if it has rewards
     */
    function earnedDPX(IDPXSingleStaking self, address _caller)
        public
        view
        returns (uint256)
    {
        (uint256 reward, ) = self.earned(_caller);

        return reward;
    }

    /**
     * @notice Obtain the amount of rDPX earned on the farm
     * @param _caller the address used to check if it has rewards
     */
    function earnedRDPX(IDPXSingleStaking self, address _caller)
        external
        view
        returns (uint256)
    {
        (, uint256 reward) = self.earned(_caller);

        return reward;
    }

    /**
     * @notice Compound Single stake rewards
     */
    function compoundRewards(IDPXSingleStaking self) external returns (bool) {
        self.compound();
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.10;

// Interfaces
import {IStableSwap} from "../../interfaces/IStableSwap.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

library Curve2PoolWrapper {
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    IUniswapV2Router02 constant sushiRouter = IUniswapV2Router02(SUSHI_ROUTER);

    /**
     * @notice Swaps a token for 2CRV
     * @param _inputToken The token to swap
     * @param _amount The token amount to swap
     * @param _stableToken The address of the stable token to swap the `_inputToken`
     * @param _minStableAmount The minimum output amount of `_stableToken`
     * @param _min2CrvAmount The minimum output amount of 2CRV to receive
     * @param _recipient The address that's going to receive the 2CRV
     * @return The amount of 2CRV received
     */
    function swapTokenFor2Crv(
        IStableSwap self,
        address _inputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        address[] memory route = new address[](3);

        route[0] = _inputToken;
        route[1] = WETH;
        route[2] = _stableToken;

        uint256[] memory swapOutputs = sushiRouter.swapExactTokensForTokens(
            _amount,
            _minStableAmount,
            route,
            _recipient,
            block.timestamp
        );

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = _swapStableFor2Crv(
            self,
            _stableToken,
            stableOutput,
            _min2CrvAmount
        );

        emit SwapTokenFor2Crv(_amount, amountOut, _inputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for `_outputToken`
     * @param _outputToken The output token to receive
     * @param _amount The amount of 2CRV to swap
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minTokenAmount The minimum output amount of `_outputToken` to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swap2CrvForToken(
        IStableSwap self,
        address _outputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minTokenAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        uint256 stableAmount = swap2CrvForStable(
            self,
            _stableToken,
            _amount,
            _minStableAmount
        );

        address[] memory route = new address[](3);

        route[0] = _stableToken;
        route[1] = WETH;
        route[2] = _outputToken;

        uint256[] memory swapOutputs = sushiRouter.swapExactTokensForTokens(
            stableAmount,
            _minTokenAmount,
            route,
            _recipient,
            block.timestamp
        );

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForToken(_amount, amountOut, _outputToken);

        return amountOut;
    }

    /**
     * @notice Swaps the native asset for 2CRV
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _min2CrvAmount The minimum output amount of 2CRV to receive
     * @param _recipient The address that's going to receive the 2CRV
     * @return The amount of 2CRV received
     */
    function swapNativeFor2Crv(
        IStableSwap self,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        address[] memory route = new address[](2);

        route[0] = WETH;
        route[1] = _stableToken;

        uint256[] memory swapOutputs = sushiRouter.swapExactETHForTokens{
            value: _amount
        }(_minStableAmount, route, _recipient, block.timestamp);

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = _swapStableFor2Crv(
            self,
            _stableToken,
            stableOutput,
            _min2CrvAmount
        );

        emit SwapNativeFor2Crv(_amount, amountOut);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for native currency
     * @param _amount The amount of 2CRV to swap
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minNativeAmount The minimum output amount of native currency to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swap2CrvForNative(
        IStableSwap self,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minNativeAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        uint256 stableAmount = swap2CrvForStable(
            self,
            _stableToken,
            _amount,
            _minStableAmount
        );

        address[] memory route = new address[](2);

        route[0] = _stableToken;
        route[1] = WETH;

        uint256[] memory swapOutputs = sushiRouter.swapExactTokensForETH(
            stableAmount,
            _minNativeAmount,
            route,
            _recipient,
            block.timestamp
        );

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForNative(_amount, amountOut);

        return amountOut;
    }

    /**
     * @notice Swaps all 2CRV balance for `_outputToken`
     * @param _outputToken The output token to receive
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minTokenAmount The minimum output amount of `_outputToken` to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swapAll2CrvForToken(
        IStableSwap self,
        address _outputToken,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minTokenAmount,
        address _recipient
    ) public returns (uint256) {
        uint256 amount = self.balanceOf(_recipient);

        if (amount > 0) {
            return
                swap2CrvForToken(
                    self,
                    _outputToken,
                    amount,
                    _stableToken,
                    _minStableAmount,
                    _minTokenAmount,
                    _recipient
                );
        }

        return 0;
    }

    /**
     * @notice Swaps all 2CRV balance for native currency
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minNativeAmount The minimum output amount of native currency to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swapAll2CrvForNative(
        IStableSwap self,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minNativeAmount,
        address _recipient
    ) public returns (uint256) {
        uint256 amount = self.balanceOf(_recipient);

        if (amount > 0) {
            return
                swap2CrvForNative(
                    self,
                    amount,
                    _stableToken,
                    _minStableAmount,
                    _minNativeAmount,
                    _recipient
                );
        }

        return 0;
    }

    /**
     * @notice Swaps 2CRV for a stable token
     * @param _stableToken The stable token address
     * @param _amount The amount of 2CRV to sell
     * @param _minStableAmount The minimum amount stables to receive
     * @return The amount of stables received
     */
    function swap2CrvForStable(
        IStableSwap self,
        address _stableToken,
        uint256 _amount,
        uint256 _minStableAmount
    ) public returns (uint256) {
        int128 stableIndex;

        require(_stableToken == USDC || _stableToken == USDT, "P1");

        if (_stableToken == USDC) {
            stableIndex = 0;
        }
        if (_stableToken == USDT) {
            stableIndex = 1;
        }

        return
            self.remove_liquidity_one_coin(
                _amount,
                stableIndex,
                _minStableAmount
            );
    }

    /**
     * @notice Swaps a stable token for 2CRV
     * @param _stableToken The stable token address
     * @param _amount The amount of `_stableToken` to sell
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * @return The amount of 2CRV received
     */
    function _swapStableFor2Crv(
        IStableSwap self,
        address _stableToken,
        uint256 _amount,
        uint256 _min2CrvAmount
    ) private returns (uint256) {
        uint256[2] memory deposits;
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        if (_stableToken == USDC) {
            deposits = [_amount, 0];
        }
        if (_stableToken == USDT) {
            deposits = [0, _amount];
        }

        return self.add_liquidity(deposits, _min2CrvAmount);
    }

    event Swap2CrvForToken(
        uint256 _amountIn,
        uint256 _amountOut,
        address _token
    );
    event SwapTokenFor2Crv(
        uint256 _amountIn,
        uint256 _amountOut,
        address _token
    );
    event Swap2CrvForNative(uint256 _amountIn, uint256 _amountOut);
    event SwapNativeFor2Crv(uint256 _amountIn, uint256 _amountOut);
    /**
     * ERROR MAPPING:
     * {
     *   "P1": "Invalid stable token",
     * }
     */
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IDPXSSOVV2 {
    function currentEpoch() external view returns (uint256);

    function deposit(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (bool);

    function depositMultiple(
        uint256[] calldata strikeIndices,
        uint256[] calldata amounts,
        address user
    ) external returns (bool);

    function purchase(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (uint256, uint256);

    function settle(
        uint256 strikeIndex,
        uint256 amount,
        uint256 epoch
    ) external returns (uint256 pnl);

    function withdraw(uint256 withdrawEpoch, uint256 strikeIndex)
        external
        returns (uint256[2] memory); // biggest difference

    function getEpochStrikeTokens(uint256 epoch)
        external
        view
        returns (address[] memory);

    function getUserEpochDeposits(uint256 epoch, address user)
        external
        view
        returns (uint256[] memory);

    function getEpochStrikes(uint256 epoch)
        external
        view
        returns (uint256[] memory);

    function addToContractWhitelist(address _contract) external returns (bool);

    function bootstrap() external returns (bool);

    function calculatePnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external pure returns (uint256);

    function settlementPrices(uint256 epoch) external view returns (uint256);

    function epochStrikes(uint256 epoch, uint256 index)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

interface IDPXSingleStaking {
    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward(uint256 rewardsTokenID) external;

    function compound() external;

    function exit() external;

    function earned(address account)
        external
        view
        returns (uint256 DPXEarned, uint256 RDPXEarned);

    function stakingToken() external view returns (address);

    function rewardsTokenDPX() external view returns (address);

    function whitelistedContracts(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJonesAsset is IERC20 {
    /// @dev JonesAsset interface
    function mint(address recipient, uint256 amount) external;

    function giveMinterRole(address account) external;

    function revokeMinterRole(address account) external;

    /// @dev IERC20Burnable interface
    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface ICurve2PoolSsovPut {
    function deposit(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (bool);

    function depositMultiple(
        uint256[] memory strikeIndices,
        uint256[] memory amounts,
        address user
    ) external returns (bool);

    function purchase(
        uint256 strikeIndex,
        uint256 amount,
        address user
    ) external returns (uint256 premium, uint256 totalFee);

    function calculatePremium(uint256 strike, uint256 amount)
        external
        view
        returns (uint256);

    function calculatePurchaseFees(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external view returns (uint256);

    function getEpochStrikes(uint256 epoch)
        external
        view
        returns (uint256[] memory);

    function getEpochStrikeTokens(uint256 epoch)
        external
        view
        returns (address[] memory);

    function getUserEpochDeposits(uint256 epoch, address user)
        external
        view
        returns (uint256[] memory);

    function settle(
        uint256 strikeIndex,
        uint256 amount,
        uint256 epoch
    ) external returns (uint256);

    function withdraw(uint256 epoch, uint256 strikeIndex)
        external
        returns (uint256[2] memory);

    function addToContractWhitelist(address _contract) external returns (bool);

    function baseToken() external view returns (address);

    function currentEpoch() external view returns (uint256);

    function getUsdPrice() external view returns (uint256);

    function getLpPrice() external view returns (uint256);

    function calculatePnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external pure returns (uint256);

    function settlementPrices(uint256 epoch) external view returns (uint256);

    function epochStrikes(uint256 epoch, uint256 index)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity(
        uint256 burn_amount,
        uint256[2] calldata min_amounts
    ) external returns (uint256[2] memory);

    function remove_liquidity_one_coin(
        uint256 burn_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i)
        external
        view
        returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}