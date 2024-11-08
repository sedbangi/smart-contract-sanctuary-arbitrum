// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.21;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";
import {FactoryContract} from "../interfaces/IFactory.sol";
import {TreasuryContract} from "../interfaces/ITreasury.sol";
import {VaultFeeHandler} from "./VaultFeeHandler.sol";

contract Vault is Context, Pausable, VaultFeeHandler {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public vaultId;
    uint256 public minimumInvestmentAmount;
    address public vaultCreator;
    address public factory;
    address[] public privateWalletAddresses;
    uint256 public timeLockDate;
    uint256 private totalWeightage;
    uint256 public tvl;
    struct UserInvestment {
        uint256 individualWeightage;
        uint256 amount;
    }
    mapping(address => UserInvestment) private addressToUserInvestment;

    event Invest(address investor, uint256 amount);
    event Withdraw(address withdrawer, uint256 share, uint256 amount);
    event AdminWithdraw(IERC20 token, address to, uint256 amount);
    event TokensApproved(IERC20[] tokens, uint256[] amount, address spender);
    event FeeDistribution(uint vaultCreatorReward, uint treasuryFee);
    event WithdrawTrade(address receiver, uint256 amount, uint256 amountsOut);
    event UpdatedPrivateWalletAddresses(
        address[] updatedPrivateWalletAddresses
    );
    event UpdatedMinimumInvestmentAmount(
        uint256 updatedMinimumInvestmentAmount
    );
    event ReceivedEther(address payer, uint amount);
    event FallbackReceivedEther(address payer, uint amount, bytes data);

    modifier investorCheck() {
        if (privateWalletAddresses.length > 0) {
            bool isPremium = false;
            for (uint256 i = 0; i < privateWalletAddresses.length; i++) {
                if (privateWalletAddresses[i] == msg.sender) {
                    isPremium = true;
                    break;
                }
            }
            require(isPremium, "Only premium wallet addresses allowed");
        }
        _;
    }

    modifier amountCheck(uint256 amount) {
        require(
            amount >= minimumInvestmentAmount,
            "Amount less than minimumInvestmentAmount"
        );
        _;
    }

    modifier isAdmin() {
        address treasuryContractAddress = FactoryContract(factory)
            .treasuryContractAddress();
        require(
            TreasuryContract(treasuryContractAddress).isAdmin(msg.sender),
            "Not authorized"
        );
        _;
    }

    modifier isPlatformWallet() {
        address treasuryContractAddress = FactoryContract(factory)
            .treasuryContractAddress();
        require(
            TreasuryContract(treasuryContractAddress).isPlatformWallet(
                msg.sender
            ),
            "Not authorized"
        );
        _;
    }

    modifier isTimeLockReached() {
        require(
            block.timestamp < timeLockDate,
            "Vault: exceeded timelock date"
        );
        _;
    }

    function initialize(
        uint256 _vaultId,
        address[] memory _privateWalletAddresses,
        address _vaultCreator,
        uint256 _minimumInvestmentAmount,
        address _factory
    ) external {
        vaultId = _vaultId;
        privateWalletAddresses = _privateWalletAddresses;
        vaultCreator = _vaultCreator;
        minimumInvestmentAmount = _minimumInvestmentAmount;
        factory = _factory;
        uint256 fiveYears = 365 days * 5;
        timeLockDate = block.timestamp + fiveYears;
    }

    /**
     * Receive function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    /**
     * Fallback function for receiving Ether in case of msg.data not empty
     */
    fallback() external payable {
        emit FallbackReceivedEther(msg.sender, msg.value, msg.data);
    }

    /**
     * Allows admin to unpause the transaction related functionalities on contract
     */
    function pause() public isAdmin {
        _pause();
    }

    /**
     * Allows admin to pause the transaction related functionalities on contract
     */
    function unpause() public isAdmin {
        _unpause();
    }

    /**
     * Allows vault creator to update private wallet addresses
     */
    function updatePrivateWalletAddresses(
        address[] memory _privateWalletAddresses
    ) external isPlatformWallet whenNotPaused {
        privateWalletAddresses = _privateWalletAddresses;
        emit UpdatedPrivateWalletAddresses(privateWalletAddresses);
    }

    /**
     * Allows vault creator to update minimum investment amount
     */
    function updateMinimumInvestmentAmount(
        uint256 _minimumInvestmentAmount
    ) external isPlatformWallet whenNotPaused {
        minimumInvestmentAmount = _minimumInvestmentAmount;
        emit UpdatedMinimumInvestmentAmount(minimumInvestmentAmount);
    }

    /**
     * Function to allow users to invest in vault,
     * @param _amount amount of accepted token users wants to invest
     */
    function invest(
        uint256 _amount
    )
        external
        isTimeLockReached
        investorCheck
        amountCheck(_amount)
        whenNotPaused
    {
        address acceptedToken = FactoryContract(factory).acceptedToken();
        IERC20(acceptedToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        uint256 weightage = (timeLockDate - block.timestamp) * _amount;
        UserInvestment storage userInvestment = addressToUserInvestment[
            msg.sender
        ];

        userInvestment.individualWeightage =
            userInvestment.individualWeightage +
            weightage;
        userInvestment.amount = userInvestment.amount + _amount;
        totalWeightage += weightage;
        tvl += _amount;
        emit Invest(msg.sender, _amount);
    }

    /**
     * Function to send token swap function call to odos router
     * @param router address of odos router contract
     * @param data data for the function call to odos router contract
     */
    function purchase(
        address router,
        bytes memory data
    ) external isPlatformWallet whenNotPaused {
        _callMandatoryReturnData(router, data);
    }

    /**
     * Sends token swap function call to odos router,
     * distributes feeAmount to the Vault creator if applicable, and the rest to the Treasury.
     * @param router address of odos router contract
     * @param data data for the function call to odos router contract
     * @param feeAmount corresponding to this trade
     */
    function copyTrade(
        address router,
        bytes memory data,
        uint feeAmount
    ) external isPlatformWallet whenNotPaused {
        _callMandatoryReturnData(router, data);
        _calculateAndSendFees(feeAmount);
    }

    /**
     * Function called by user to update share state and emit withdraw event with the calculated share
     */
    function withdraw() external whenNotPaused {
        UserInvestment memory userInvestment = addressToUserInvestment[
            msg.sender
        ];

        require(
            userInvestment.individualWeightage > 0,
            "Zero share in the vault"
        );
        uint256 share = _evaluateShares(userInvestment.individualWeightage);
        totalWeightage -= userInvestment.individualWeightage;
        tvl -= userInvestment.amount;
        delete addressToUserInvestment[msg.sender];
        emit Withdraw(msg.sender, share, userInvestment.amount);
    }

    /**
     * Sends token swap function call to odos router, sends tokens to given user's address after deducting the fees
     * and from the collected fees, distributes a share to the Vault creator if applicable, and the rest to the Treasury.
     * @param router The Address of odos router contract
     * @param data The Data for the function call to odos router contract
     */
    function withdrawal(
        address router,
        bytes memory data,
        address userWalletAddress
    ) external isPlatformWallet whenNotPaused {
        uint256 amountsOut = _tradeForWithdrawal(router, data);
        uint256 txnFee = _calculateTotalFee(
            amountsOut,
            FactoryContract(factory).withdrawalFee()
        );
        uint userShare = amountsOut - txnFee;
        address acceptedToken = FactoryContract(factory).acceptedToken();
        IERC20(acceptedToken).safeTransfer(userWalletAddress, userShare);
        _calculateAndSendFees(txnFee);
        emit WithdrawTrade(userWalletAddress, userShare, amountsOut);
    }

    /**
     * Provides Approval to spender corresponding to the token addresses and their amount
     * @param _spender address of router
     * @param _tokens array of token addresses
     * @param _amount array of amount corresponding to token addresses
     */
    function approveTokens(
        address _spender,
        IERC20[] memory _tokens,
        uint256[] memory _amount
    ) external isPlatformWallet whenNotPaused {
        require(
            _tokens.length == _amount.length,
            "Vault: tokens & amount should have same length"
        );
        for (uint8 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeIncreaseAllowance(_spender, _amount[i]);
        }
        emit TokensApproved(_tokens, _amount, _spender);
    }

    /**
     * get function to calculate given users wallet's shares for the withdrawal
     * @param _investor address of investor to calculate weightage
     */
    function evaluateShares(address _investor) external view returns (uint256) {
        UserInvestment memory userInvestment = addressToUserInvestment[
            _investor
        ];
        return _evaluateShares(userInvestment.individualWeightage);
    }

    /**
     * Allows the ADMIN_ROLE to withdraw a specified amount of ERC20 tokens or native token from the contract.
     * @param _tokenAddress The address of ERC20 token to withdraw
     * @param _to The address to send the tokens to
     * @param _amount amount of tokens to withdraw, if equals 0, it transfers the available balance of the token.
     */
    function adminWithdrawFunds(
        IERC20 _tokenAddress,
        address _to,
        uint256 _amount
    ) external isAdmin {
        require(_to != address(0), "address zero not allowed");
        uint256 amount;
        if (address(_tokenAddress) == address(0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "Insufficient native balance");
            amount = _amount == 0 ? balance : _amount;
            bool sent = _sendEthersTo(_to, amount);
            require(sent, "Failed to send native token");
        } else {
            uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
            require(balance > 0, "Insufficient balance");
            amount = _amount == 0 ? balance : _amount;
            _tokenAddress.safeTransfer(_to, amount);
        }
        emit AdminWithdraw(_tokenAddress, _to, amount);
    }

    /**
     * sends call to odos router contract with given data and decodes the return data recieved from function call
     * @param router address of the odos router contract
     * @param data data for the function call to odos router contract
     * @return amountsOut
     */
    function _tradeForWithdrawal(
        address router,
        bytes memory data
    ) private returns (uint256 amountsOut) {
        bytes memory returndata = router.functionCall(
            data,
            "Vault: low-level call failed"
        );
        (amountsOut) = abi.decode(returndata, (uint256));
        return amountsOut;
    }

    function _sendEthersTo(
        address _receiver,
        uint256 _amount
    ) private returns (bool) {
        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        return sent;
    }

    /**
     * get function to calculate given users wallet's shares for the withdrawal
     * @param weightage user's individual weightage
     */
    function _evaluateShares(uint weightage) private view returns (uint256) {
        return
            totalWeightage > 0
                ? (weightage * TOTAL_BASIS_POINT) / totalWeightage
                : 0;
    }

    /**
     * Calculate and distribute fee share to the Treausry contract and vault creator (if applied).
     * @param _txnFeeAmount fee amount for the transaction
     */
    function _calculateAndSendFees(uint256 _txnFeeAmount) private {
        (
            uint256 feeToTreasury,
            uint256 rewardToVaultCreator
        ) = _calculateFeeDistribution(
                _txnFeeAmount,
                FactoryContract(factory).getVaultCreatorReward(
                    vaultCreator,
                    tvl
                )
            );

        address treasuryContractAddress = FactoryContract(factory)
            .treasuryContractAddress();
        address acceptedToken = FactoryContract(factory).acceptedToken();

        IERC20(acceptedToken).safeTransfer(
            treasuryContractAddress,
            feeToTreasury
        );
        if (rewardToVaultCreator > 0) {
            IERC20(acceptedToken).safeTransfer(
                vaultCreator,
                rewardToVaultCreator
            );
        }

        emit FeeDistribution(rewardToVaultCreator, feeToTreasury);
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is mandatory (returndata.length > 0).
     * @param targetContract The contract address targeted by the call.
     * @param data The call data .
     */
    function _callMandatoryReturnData(
        address targetContract,
        bytes memory data
    ) private {
        targetContract.functionCall(data, "Vault: low-level call failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.21;

interface FactoryContract {
    function acceptedToken() external view returns (address);

    function tradeFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function treasuryContractAddress() external view returns (address);

    function getVaultCreatorReward(
        address vaultCreator,
        uint tvl
    ) external view returns (uint64);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.21;

interface TreasuryContract {
    function isAdmin(address account) external view returns (bool);

    function isPlatformWallet(address account) external view returns (bool);

    function isReferralDisburser(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.21;

abstract contract VaultFeeHandler {
    uint256 public constant TOTAL_BASIS_POINT = 1000000;

    /**
     * Calculates and returns fee according to the given fee basis point
     * @param _txnAmount total amount of the transaction
     * @param _fee percentage of fee in basis points
     */
    function _calculateTotalFee(
        uint256 _txnAmount,
        uint256 _fee
    ) internal pure returns (uint256 fee) {
        fee = (_txnAmount * _fee) / TOTAL_BASIS_POINT;
    }

    /**
     * Calculates fee share
     * @param _txnFeeAmount transaction fee amount
     * @param _vaultCreatorReward fee share in basis point for vault creator
     */
    function _calculateFeeDistribution(
        uint256 _txnFeeAmount,
        uint256 _vaultCreatorReward
    )
        internal
        pure
        returns (uint256 feeToTreasury, uint256 rewardToVaultCreator)
    {
        feeToTreasury = _txnFeeAmount;
        if (_vaultCreatorReward > 0) {
            rewardToVaultCreator =
                (_txnFeeAmount * _vaultCreatorReward) /
                TOTAL_BASIS_POINT;
            feeToTreasury = _txnFeeAmount - rewardToVaultCreator;
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