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