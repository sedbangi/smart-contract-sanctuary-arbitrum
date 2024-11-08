// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILPStaking} from "./interfaces/ILPStaking.sol";
import {IStargateRouter} from "./interfaces/IStargateRouter.sol";
import {IStargatePool} from "./interfaces/IStargatePool.sol";
import {InitializableAbstractStrategy, Helpers, IStrategyVault} from "../InitializableAbstractStrategy.sol";

/// @title Stargate strategy for USDs protocol
/// @author Sperax Foundation
/// @notice A yield earning strategy for USDs protocol
/// @notice Important contract addresses:
///         Addresses https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet#arbitrum
contract StargateStrategy is InitializableAbstractStrategy {
    using SafeERC20 for IERC20;

    struct AssetInfo {
        uint256 allocatedAmt; // tracks the allocated amount for an asset.
        uint256 rewardPID; // maps asset to farm reward pool id
        uint16 pid; // maps asset to pool id
    }

    address public router; // Address of the Stargate router contract
    address public farm; // Address of the Stargate farm contract (LPStaking)
    mapping(address => AssetInfo) public assetInfo;

    // Events
    event FarmUpdated(address newFarm);

    // Custom errors
    error IncorrectPoolId(address asset, uint16 pid);
    error IncorrectRewardPoolId(address asset, uint256 rewardPid);

    function initialize(
        address _router,
        address _vault,
        address _eToken,
        address _farm,
        uint16 _depositSlippage, // 200 = 2%
        uint16 _withdrawSlippage // 200 = 2%
    ) external initializer {
        Helpers._isNonZeroAddr(_router);
        Helpers._isNonZeroAddr(_eToken);
        Helpers._isNonZeroAddr(_farm);
        router = _router;
        farm = _farm;

        // register reward token
        rewardTokenAddress.push(_eToken);

        InitializableAbstractStrategy._initialize(_vault, _depositSlippage, _withdrawSlippage);
    }

    /// @notice Provide support for asset by passing its pToken address.
    ///      This method can only be called by the system owner
    /// @param _asset    Address for the asset
    /// @param _lpToken   Address for the corresponding platform token
    /// @param _pid   Pool Id for the asset
    /// @param _rewardPid   Farm Pool Id for the asset
    function setPTokenAddress(address _asset, address _lpToken, uint16 _pid, uint256 _rewardPid) external onlyOwner {
        if (IStargatePool(_lpToken).token() != _asset) {
            revert InvalidAssetLpPair(_asset, _lpToken);
        }
        if (IStargatePool(_lpToken).poolId() != _pid) {
            revert IncorrectPoolId(_asset, _pid);
        }
        (IERC20 lpToken,,,) = ILPStaking(farm).poolInfo(_rewardPid);
        if (address(lpToken) != _lpToken) {
            revert IncorrectRewardPoolId(_asset, _rewardPid);
        }
        _setPTokenAddress(_asset, _lpToken);
        assetInfo[_asset] = AssetInfo({allocatedAmt: 0, pid: _pid, rewardPID: _rewardPid});
    }

    /// @dev Remove a supported asset by passing its index.
    ///       This method can only be called by the system owner
    ///  @param _assetIndex Index of the asset to be removed
    function removePToken(uint256 _assetIndex) external onlyOwner {
        address asset = _removePTokenAddress(_assetIndex);
        if (assetInfo[asset].allocatedAmt != 0) {
            revert CollateralAllocated(asset);
        }
        delete assetInfo[asset];
    }

    /// @inheritdoc InitializableAbstractStrategy
    function deposit(address _asset, uint256 _amount) external override onlyVault nonReentrant {
        Helpers._isNonZeroAmt(_amount);
        if (!supportsCollateral(_asset)) revert CollateralNotSupported(_asset);
        address lpToken = assetToPToken[_asset];
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_asset).forceApprove(router, _amount);

        AssetInfo storage asset = assetInfo[_asset];
        // Add liquidity in the stargate pool.
        IStargateRouter(router).addLiquidity(asset.pid, _amount, address(this));
        // Deposit the generated lpToken in the farm.
        // @dev We are assuming that the 100% of lpToken is deposited in the farm.
        uint256 lpTokenBal = IERC20(lpToken).balanceOf(address(this));
        uint256 depositAmt = _convertToCollateral(_asset, lpTokenBal);
        uint256 minDepositAmt = (_amount * (Helpers.MAX_PERCENTAGE - depositSlippage)) / Helpers.MAX_PERCENTAGE;
        if (depositAmt < minDepositAmt) {
            revert Helpers.MinSlippageError(depositAmt, minDepositAmt);
        }

        // Update the allocated amount in the strategy
        asset.allocatedAmt += depositAmt;

        IERC20(lpToken).forceApprove(farm, lpTokenBal);
        ILPStaking(farm).deposit(asset.rewardPID, lpTokenBal);
        emit Deposit(_asset, depositAmt);
    }

    /// @inheritdoc InitializableAbstractStrategy
    function withdraw(address _recipient, address _asset, uint256 _amount)
        external
        override
        onlyVault
        nonReentrant
        returns (uint256)
    {
        return _withdraw(false, _recipient, _asset, _amount);
    }

    /// @inheritdoc InitializableAbstractStrategy
    function withdrawToVault(address _asset, uint256 _amount)
        external
        override
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        return _withdraw(false, vault, _asset, _amount);
    }

    /// @notice Function to withdraw position from LPStaking
    /// @dev Useful when there are not enough rewards in the pool
    /// @param _asset Asset to withdraw
    function emergencyWithdrawToVault(address _asset) external onlyOwner nonReentrant {
        uint256 lpTokenAmt = checkLPTokenBalance(_asset);
        AssetInfo storage asset = assetInfo[_asset];
        // Withdraw from LPStaking without caring for rewards
        ILPStaking(farm).emergencyWithdraw(asset.rewardPID);
        uint256 amtRecv = IStargateRouter(router).instantRedeemLocal(asset.pid, lpTokenAmt, vault)
            * IStargatePool(assetToPToken[_asset]).convertRate();
        asset.allocatedAmt -= amtRecv;
        emit Withdrawal(_asset, amtRecv);
    }

    /// @inheritdoc InitializableAbstractStrategy
    function collectInterest(address _asset) external override nonReentrant {
        address yieldReceiver = IStrategyVault(vault).yieldReceiver();
        uint256 earnedInterest = checkInterestEarned(_asset);
        if (earnedInterest != 0) {
            uint256 interestCollected = _withdraw(true, address(this), _asset, earnedInterest);
            uint256 harvestAmt = _splitAndSendReward(_asset, yieldReceiver, msg.sender, interestCollected);
            emit InterestCollected(_asset, yieldReceiver, harvestAmt);
        }
    }

    /// @inheritdoc InitializableAbstractStrategy
    function collectReward() external override nonReentrant {
        address yieldReceiver = IStrategyVault(vault).yieldReceiver();
        address rewardToken = rewardTokenAddress[0];
        uint256 numAssets = assetsMapped.length;
        for (uint256 i; i < numAssets;) {
            address asset = assetsMapped[i];
            uint256 rewardAmt = checkPendingRewards(asset);
            if (rewardAmt != 0) {
                ILPStaking(farm).deposit(assetInfo[asset].rewardPID, 0);
            }
            unchecked {
                ++i;
            }
        }
        uint256 rewardEarned = IERC20(rewardToken).balanceOf(address(this));
        uint256 harvestAmt = _splitAndSendReward(rewardToken, yieldReceiver, msg.sender, rewardEarned);
        emit RewardTokenCollected(rewardToken, yieldReceiver, harvestAmt);
    }

    /// @notice A function to withdraw from old farm, update farm and deposit in new farm
    /// @param _newFarm Address of the new farm
    /// @dev Only callable by owner
    /// @dev @note Claim the rewards before calling this function!
    function updateFarm(address _newFarm, address _rewardToken) external nonReentrant onlyOwner {
        Helpers._isNonZeroAddr(_rewardToken);
        Helpers._isNonZeroAddr(_newFarm);
        address _oldFarm = farm;
        uint256 _numAssets = assetsMapped.length;
        address _asset;
        uint256 _rewardPID;
        uint256 _lpTokenAmt;
        for (uint8 i; i < _numAssets;) {
            _asset = assetsMapped[i];
            _rewardPID = assetInfo[_asset].rewardPID;
            _lpTokenAmt = checkLPTokenBalance(_asset);
            ILPStaking(_oldFarm).withdraw(_rewardPID, _lpTokenAmt);
            IERC20(assetToPToken[_asset]).forceApprove(_newFarm, _lpTokenAmt);
            ILPStaking(_newFarm).deposit(_rewardPID, _lpTokenAmt);
            unchecked {
                ++i;
            }
        }
        farm = _newFarm;
        rewardTokenAddress[0] = _rewardToken;
        emit FarmUpdated(_newFarm);
    }

    /// @inheritdoc InitializableAbstractStrategy
    function checkRewardEarned() external view override returns (RewardData[] memory) {
        uint256 pendingRewards = 0;
        uint256 numAssets = assetsMapped.length;
        for (uint256 i; i < numAssets;) {
            address asset = assetsMapped[i];
            pendingRewards += ILPStaking(farm).pendingEmissionToken(assetInfo[asset].rewardPID, address(this));
            unchecked {
                ++i;
            }
        }
        uint256 claimedRewards = IERC20(rewardTokenAddress[0]).balanceOf(address(this));
        RewardData[] memory rewardData = new RewardData[](1);
        rewardData[0] = RewardData(rewardTokenAddress[0], claimedRewards + pendingRewards);
        return rewardData;
    }

    /// @inheritdoc InitializableAbstractStrategy
    function supportsCollateral(address _asset) public view override returns (bool) {
        return assetToPToken[_asset] != address(0);
    }

    /// @notice Get the amount STG pending to be collected.
    /// @param _asset Address for the asset
    /// @return Amount of STG pending to be collected.
    function checkPendingRewards(address _asset) public view returns (uint256) {
        if (!supportsCollateral(_asset)) revert CollateralNotSupported(_asset);
        return ILPStaking(farm).pendingEmissionToken(assetInfo[_asset].rewardPID, address(this));
    }

    /// @inheritdoc InitializableAbstractStrategy
    function checkInterestEarned(address _asset) public view override returns (uint256) {
        uint256 lpTokenBal = checkLPTokenBalance(_asset);

        uint256 collateralBal = _convertToCollateral(_asset, lpTokenBal);
        uint256 allocatedAmt = assetInfo[_asset].allocatedAmt;
        if (collateralBal <= allocatedAmt) {
            return 0;
        }
        return collateralBal - allocatedAmt;
    }

    /// @inheritdoc InitializableAbstractStrategy
    function checkBalance(address _asset) public view override returns (uint256) {
        uint256 lpTokenBal = checkLPTokenBalance(_asset);
        uint256 calcCollateralBal = _convertToCollateral(_asset, lpTokenBal);
        uint256 allocatedAmt = assetInfo[_asset].allocatedAmt;
        if (allocatedAmt <= calcCollateralBal) {
            return allocatedAmt;
        }
        return calcCollateralBal;
    }

    /// @inheritdoc InitializableAbstractStrategy
    function checkAvailableBalance(address _asset) public view override returns (uint256) {
        IStargatePool pool = IStargatePool(assetToPToken[_asset]);
        uint256 availableFunds = _convertToCollateral(_asset, pool.deltaCredit());
        uint256 allocatedAmt = assetInfo[_asset].allocatedAmt;
        if (availableFunds <= allocatedAmt) {
            return availableFunds;
        }
        return allocatedAmt;
    }

    /// @inheritdoc InitializableAbstractStrategy
    function checkLPTokenBalance(address _asset) public view override returns (uint256) {
        if (!supportsCollateral(_asset)) revert CollateralNotSupported(_asset);
        (uint256 lpTokenStaked,) = ILPStaking(farm).userInfo(assetInfo[_asset].rewardPID, address(this));
        return lpTokenStaked;
    }

    /// @inheritdoc InitializableAbstractStrategy
    /* solhint-disable no-empty-blocks */
    function _abstractSetPToken(address _asset, address _pToken) internal override {}

    /* solhint-enable no-empty-blocks */

    /// @notice Convert amount of lpToken to collateral.
    /// @param _asset Address for the asset
    /// @param _lpTokenAmount Amount of lpToken
    /// @return Amount of collateral equivalent to the lpToken amount
    function _convertToCollateral(address _asset, uint256 _lpTokenAmount) internal view returns (uint256) {
        IStargatePool pool = IStargatePool(assetToPToken[_asset]);
        return ((_lpTokenAmount * pool.totalLiquidity()) / pool.totalSupply()) * pool.convertRate();
    }

    /// @notice Convert amount of collateral to lpToken.
    /// @param _asset Address for the asset
    /// @param _collateralAmount Amount of collateral
    /// @return Amount of lpToken equivalent to the collateral amount
    function _convertToPToken(address _asset, uint256 _collateralAmount) internal view returns (uint256) {
        IStargatePool pool = IStargatePool(assetToPToken[_asset]);
        return (_collateralAmount * pool.totalSupply()) / (pool.totalLiquidity() * pool.convertRate());
    }

    /// @notice Helper function for withdrawal.
    /// @param _withdrawInterest Withdraws interest as well if this is set to `true`
    /// @param _recipient Recipient of the amount
    /// @param _asset Address of the asset token
    /// @param _amount Amount to be withdrawn
    /// @return Amount withdrawn
    /// @dev Validate if the farm has enough STG to withdraw as rewards.
    /// @dev It is designed to be called from functions with the `nonReentrant` modifier to ensure reentrancy protection.
    function _withdraw(bool _withdrawInterest, address _recipient, address _asset, uint256 _amount)
        private
        returns (uint256)
    {
        Helpers._isNonZeroAddr(_recipient);
        Helpers._isNonZeroAmt(_amount, "Must withdraw something");
        if (!supportsCollateral(_asset)) revert CollateralNotSupported(_asset);

        uint256 lpTokenAmt = _convertToPToken(_asset, _amount);
        AssetInfo storage asset = assetInfo[_asset];
        ILPStaking(farm).withdraw(asset.rewardPID, lpTokenAmt);
        uint256 minRecvAmt = (_amount * (Helpers.MAX_PERCENTAGE - withdrawSlippage)) / Helpers.MAX_PERCENTAGE;
        uint256 amtRecv = IStargateRouter(router).instantRedeemLocal(asset.pid, lpTokenAmt, _recipient)
            * IStargatePool(assetToPToken[_asset]).convertRate();
        if (amtRecv < minRecvAmt) {
            revert Helpers.MinSlippageError(amtRecv, minRecvAmt);
        }

        if (!_withdrawInterest) {
            asset.allocatedAmt -= amtRecv;
            emit Withdrawal(_asset, amtRecv);
        }

        return amtRecv;
    }

    /// @notice Validate if the farm has sufficient funds to claim rewards.
    /// @param _asset Address for the asset
    /// @return bool if the farm has sufficient funds to claim rewards.
    /// @dev skipRwdValidation is a flag to skip the validation.
    function _validateRwdClaim(address _asset) private view returns (bool) {
        return checkPendingRewards(_asset) <= IERC20(rewardTokenAddress[0]).balanceOf(farm);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ILPStaking {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function pendingEmissionToken(uint256 _poolId, address _user) external view returns (uint256);

    function poolInfo(uint256 _poolId) external view returns (IERC20, uint256, uint256, address);

    function userInfo(uint256 _poolId, address _user) external view returns (uint256 balance, uint256 rewardDebt);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

interface IStargateRouter {
    // solhint-disable-next-line contract-name-camelcase
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress)
        external
        payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

pragma solidity 0.8.19;

interface IStargatePool {
    function totalLiquidity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function convertRate() external view returns (uint256);

    function deltaCredit() external view returns (uint256);

    function poolId() external view returns (uint256);

    function token() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Helpers} from "../libraries/Helpers.sol";

interface IStrategyVault {
    function yieldReceiver() external view returns (address);
}

/// @title Base strategy for USDs protocol
/// @author Sperax Foundation
/// @dev Contract acts as a single interface for implementing specific yield-earning strategies.
abstract contract InitializableAbstractStrategy is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    struct RewardData {
        address token; // Reward token
        uint256 amount; // Collectible amount
    }

    address public vault;
    uint16 public withdrawSlippage;
    uint16 public depositSlippage;
    uint16 public harvestIncentiveRate;
    address[] internal assetsMapped;
    address[] public rewardTokenAddress;
    mapping(address => address) public assetToPToken;

    /* solhint-disable-next-line var-name-mixedcase*/
    uint256[40] private __gap__;

    event VaultUpdated(address newVaultAddr);
    event YieldReceiverUpdated(address newYieldReceiver);
    event PTokenAdded(address indexed asset, address pToken);
    event PTokenRemoved(address indexed asset, address pToken);
    event Deposit(address indexed asset, uint256 amount);
    event Withdrawal(address indexed asset, uint256 amount);
    event SlippageUpdated(uint16 depositSlippage, uint16 withdrawSlippage);
    event HarvestIncentiveCollected(address indexed token, address indexed harvestor, uint256 amount);
    event HarvestIncentiveRateUpdated(uint16 newRate);
    event InterestCollected(address indexed asset, address indexed recipient, uint256 amount);
    event RewardTokenCollected(address indexed rwdToken, address indexed recipient, uint256 amount);

    error CallerNotVault(address caller);
    error CallerNotVaultOrOwner(address caller);
    error PTokenAlreadySet(address collateral, address pToken);
    error InvalidIndex();
    error CollateralNotSupported(address asset);
    error InvalidAssetLpPair(address asset, address lpToken);
    error CollateralAllocated(address asset);

    modifier onlyVault() {
        if (msg.sender != vault) revert CallerNotVault(msg.sender);
        _;
    }

    modifier onlyVaultOrOwner() {
        if (!(msg.sender == vault || msg.sender == owner())) {
            revert CallerNotVaultOrOwner(msg.sender);
        }
        _;
    }

    // Disabling initializer for the implementation contract.
    constructor() {
        _disableInitializers();
    }

    /// @notice Update the linked vault contract.
    /// @param _newVault Address of the new Vault.
    function updateVault(address _newVault) external onlyOwner {
        Helpers._isNonZeroAddr(_newVault);
        vault = _newVault;
        emit VaultUpdated(_newVault);
    }

    /// @notice Updates the HarvestIncentive rate for the user.
    /// @param _newRate new Desired rate.
    function updateHarvestIncentiveRate(uint16 _newRate) external onlyOwner {
        Helpers._isLTEMaxPercentage(_newRate);
        harvestIncentiveRate = _newRate;
        emit HarvestIncentiveRateUpdated(_newRate);
    }

    /// @notice A function to recover any erc20 token sent to this strategy mistakenly.
    /// @dev Only callable by owner.
    /// @param token Address of the token.
    /// @param receiver Receiver of the token.
    /// @param amount Amount to be recovered.
    /// @dev reverts if amount > balance.
    function recoverERC20(address token, address receiver, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(receiver, amount);
    }

    /// @dev Deposit an amount of asset into the platform.
    /// @param _asset Address for the asset.
    /// @param _amount Units of asset to deposit.
    function deposit(address _asset, uint256 _amount) external virtual;

    /// @dev Withdraw an amount of asset from the platform.
    /// @param _recipient Address to which the asset should be sent.
    /// @param _asset Address of the asset.
    /// @param _amount Units of asset to withdraw.
    /// @return amountReceived The actual amount received.
    function withdraw(address _recipient, address _asset, uint256 _amount)
        external
        virtual
        returns (uint256 amountReceived);

    /// @dev Withdraw an amount of asset from the platform to vault.
    /// @param _asset  Address of the asset.
    /// @param _amount  Units of asset to withdraw.
    function withdrawToVault(address _asset, uint256 _amount) external virtual returns (uint256 amount);

    /// @notice Withdraw the interest earned of asset from the platform.
    /// @param _asset Address of the asset.
    function collectInterest(address _asset) external virtual;

    /// @notice Collect accumulated reward token and send to Vault.
    function collectReward() external virtual;

    /// @notice Get the amount of a specific asset held in the strategy,
    ///           excluding the interest.
    /// @dev Curve: assuming balanced withdrawal.
    /// @param _asset Address of the asset.
    /// @return uint256 Balance of _asset in the strategy.
    function checkBalance(address _asset) external view virtual returns (uint256);

    /// @notice Get the amount of a specific asset held in the strategy,
    ///         excluding the interest and any locked liquidity that is not
    ///         available for instant withdrawal.
    /// @dev Curve: assuming balanced withdrawal.
    /// @param _asset Address of the asset.
    /// @return uint256 Available balance inside the strategy for _asset.
    function checkAvailableBalance(address _asset) external view virtual returns (uint256);

    /// @notice AAVE: Get the interest earned on a specific asset.
    /// Curve: Get the total interest earned.
    /// @dev Curve: to avoid double-counting, _asset has to be of index
    ///           'entryTokenIndex'.
    /// @param _asset Address of the asset.
    /// @return uint256 Amount of interest earned.
    function checkInterestEarned(address _asset) external view virtual returns (uint256);

    /// @notice Get the amount of claimable reward.
    /// @return struct array of type RewardData (address token, uint256 amount).
    function checkRewardEarned() external view virtual returns (RewardData[] memory);

    /// @notice Get the total LP token balance for a asset.
    /// @param _asset Address of the asset.
    function checkLPTokenBalance(address _asset) external view virtual returns (uint256);

    /// @notice Check if an asset/collateral is supported.
    /// @param _asset Address of the asset.
    /// @return bool Whether asset is supported.
    function supportsCollateral(address _asset) external view virtual returns (bool);

    /// @notice Change to a new depositSlippage & withdrawSlippage.
    /// @param _depositSlippage Slippage tolerance for allocation.
    /// @param _withdrawSlippage Slippage tolerance for withdrawal.
    function updateSlippage(uint16 _depositSlippage, uint16 _withdrawSlippage) public onlyOwner {
        Helpers._isLTEMaxPercentage(_depositSlippage);
        Helpers._isLTEMaxPercentage(_withdrawSlippage);
        depositSlippage = _depositSlippage;
        withdrawSlippage = _withdrawSlippage;
        emit SlippageUpdated(_depositSlippage, _withdrawSlippage);
    }

    /// @notice Initialize the base properties of the strategy.
    /// @param _vault Address of the USDs Vault.
    /// @param _depositSlippage Allowed max slippage for Deposit.
    /// @param _withdrawSlippage Allowed max slippage for withdraw.
    function _initialize(address _vault, uint16 _depositSlippage, uint16 _withdrawSlippage) internal {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        Helpers._isNonZeroAddr(_vault);
        updateSlippage(_depositSlippage, _withdrawSlippage);
        vault = _vault;
        harvestIncentiveRate = 10;
    }

    ///  @notice Provide support for asset by passing its pToken address.
    ///       Add to internal mappings and execute the platform specific,
    ///  abstract method `_abstractSetPToken`.
    ///  @param _asset Address for the asset.
    ///  @param _pToken Address for the corresponding platform token.
    function _setPTokenAddress(address _asset, address _pToken) internal {
        address currentPToken = assetToPToken[_asset];
        if (currentPToken != address(0)) {
            revert PTokenAlreadySet(_asset, currentPToken);
        }
        Helpers._isNonZeroAddr(_asset);
        Helpers._isNonZeroAddr(_pToken);

        assetToPToken[_asset] = _pToken;
        assetsMapped.push(_asset);

        emit PTokenAdded(_asset, _pToken);
        // Perform any strategy specific logic.
        _abstractSetPToken(_asset, _pToken);
    }

    /// @notice Remove a supported asset by passing its index.
    ///      This method can only be called by the system owner.
    /// @param _assetIndex Index of the asset to be removed.
    /// @return asset address which is removed.
    function _removePTokenAddress(uint256 _assetIndex) internal returns (address asset) {
        uint256 numAssets = assetsMapped.length;
        if (_assetIndex >= numAssets) revert InvalidIndex();
        asset = assetsMapped[_assetIndex];
        address pToken = assetToPToken[asset];

        assetsMapped[_assetIndex] = assetsMapped[numAssets - 1];
        assetsMapped.pop();
        delete assetToPToken[asset];

        emit PTokenRemoved(asset, pToken);
    }

    /// @notice Splits and sends the accumulated rewards to harvestor and yield receiver.
    /// @param _token Address of the reward token.
    /// @param _yieldReceiver Address of the yield receiver.
    /// @param _harvestor Address of the harvestor.
    /// @param _amount to be split and sent.
    /// @dev Sends the amount to harvestor as per `harvestIncentiveRate` and sends the rest to yield receiver.
    /// @return uint256 Harvested amount sent to yield receiver.
    function _splitAndSendReward(address _token, address _yieldReceiver, address _harvestor, uint256 _amount)
        internal
        returns (uint256)
    {
        if (harvestIncentiveRate != 0) {
            uint256 incentiveAmt = (_amount * harvestIncentiveRate) / Helpers.MAX_PERCENTAGE;
            uint256 harvestedAmt = _amount - incentiveAmt;
            IERC20(_token).safeTransfer(_harvestor, incentiveAmt);
            IERC20(_token).safeTransfer(_yieldReceiver, harvestedAmt);
            emit HarvestIncentiveCollected(_token, _harvestor, incentiveAmt);
            return harvestedAmt;
        }
        IERC20(_token).safeTransfer(_yieldReceiver, _amount);
        return _amount;
    }

    /// @notice Call the necessary approvals for the underlying strategy.
    /// @param _asset Address of the asset.
    /// @param _pToken Address of the corresponding receipt token.
    function _abstractSetPToken(address _asset, address _pToken) internal virtual;
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