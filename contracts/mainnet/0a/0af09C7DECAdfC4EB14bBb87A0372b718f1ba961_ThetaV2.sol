// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
pragma solidity 0.8.20;

interface IFixtool {
    function fixAmountBridgeData(bytes memory data, uint256 newAmount) external pure returns (bytes memory);
    function getBridgeTokenAndAmount(bytes memory data) external pure returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct OutputToken {
    address dstToken;
}

struct InputToken {
    address srcToken;
    uint256 amount;
}

struct DupToken {
    address token;
    uint256 amount;
}
struct SwapData {
    address router;
    address user;
    InputToken[] input;
    OutputToken[] output;
    DupToken[] dup;
    bytes callData;
    address feeToken;
    bytes plexusData;
}

struct BridgeData {
    address srcToken;
    uint256 amount;
    uint64 dstChainId;
    address recipient;
    bytes plexusData;
}

struct ThetaValue {
    uint256 value;
    bytes callData;
}

struct SplitData {
    uint256[][] splitRate; // [[100],[20,40,40],[100]] splitRate.length max 3
    bool multiStandard; // swapThetaV2Call,thetaV2BridgeCall default is true,
}

struct Result {
    bool success;
    bytes returnData;
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IThetaV2.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IFixtool.sol";

contract ThetaV2 is Ownable {
    using SafeERC20 for IERC20;

    address private constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public PLEXUS;

    event WholeTheta(address user, OutputToken[] indexed srcToken, uint256[] fromAmount, string bridge);

    mapping(bytes4 => SelectorCheck) functionSelectInfo;
    mapping(address => bool) allowedDex;
    mapping(address => address) proxy;

    error NotSupported();
    error ZeroAddr();
    error SWAP_FAILED();
    error MUST_ALLOWED();
    error MORE_VALUE();
    error NOT_CORRECT_RATE();
    error THETA_V2_FAILED();
    error MISSMATCH();

    struct SelectorCheck {
        bool check;
        address selectorAddr;
    }

    constructor(address _plexus) Ownable(msg.sender) {
        PLEXUS = _plexus;
    }

    //setter
    function setSelector(bytes4[] calldata _selector, address[] calldata _selectorAddr) external onlyOwner {
        require(_selector.length == _selectorAddr.length);
        for (uint i; i < _selector.length; ) {
            functionSelectInfo[_selector[i]].check = true;
            functionSelectInfo[_selector[i]].selectorAddr = _selectorAddr[i];
            unchecked {
                ++i;
            }
        }
    }
    function removeSelector(bytes4[] calldata _selector, address[] calldata _selectorAddr) external onlyOwner {
        require(_selector.length == _selectorAddr.length);
        for (uint i; i < _selector.length; ) {
            functionSelectInfo[_selector[i]].check = false;
            functionSelectInfo[_selector[i]].selectorAddr = address(0);
            unchecked {
                ++i;
            }
        }
    }
    function addDex(address[] calldata _dex) external onlyOwner {
        uint256 len = _dex.length;

        for (uint256 i; i < len; ) {
            if (_dex[i] == address(0)) {
                revert ZeroAddr();
            }
            allowedDex[_dex[i]] = true;
            unchecked {
                ++i;
            }
        }
    }
    function removeDex(address[] calldata _dex) external onlyOwner {
        uint256 len = _dex.length;

        for (uint256 i; i < len; ) {
            if (_dex[i] == address(0)) {
                revert ZeroAddr();
            }
            allowedDex[_dex[i]] = false;
            unchecked {
                ++i;
            }
        }
    }
    function setProxy(address _dex, address _proxy) external onlyOwner {
        proxy[_dex] = _proxy;
    }

    //getter
    function getSelectorChecker(bytes4 _selector) external view returns (bool, address) {
        return (functionSelectInfo[_selector].check, functionSelectInfo[_selector].selectorAddr);
    }
    function getProxy(address _dex) external view returns (address) {
        return proxy[_dex];
    }
    function dexCheck(address _dex) external view returns (bool result) {
        return allowedDex[_dex];
    }

    // Bridge
    function thetaV2BridgeCall(ThetaValue[] memory thetas) public payable {
        for (uint256 i = 0; i < thetas.length; ) {
            SelectorCheck memory selectorCheck = functionSelectInfo[bytes4(thetas[i].callData)];
            if (selectorCheck.check == false) revert NotSupported();
            (address srcToken, uint256 amount) = IFixtool(selectorCheck.selectorAddr).getBridgeTokenAndAmount(thetas[i].callData);
            _approvePlexus(srcToken, amount);
            unchecked {
                ++i;
            }
        }
        _thetaV2Call(thetas);
    }

    //swap + Bridge
    //eachBridgeTotalRate total sum is 100.

    function swapThetaV2Call(SwapData calldata _swap, ThetaValue[] memory thetas, SplitData memory splitData) public payable {
        _isSwapTokenDeposit(_swap.input);

        uint256[] memory _bridgeAmount = _bridgeSwapStart(_swap);
        uint256 _outputLength = _swap.output.length;
        for (uint256 i = 0; i < _outputLength; ) {
            for (uint256 j = 0; j < _swap.dup.length; ) {
                if (_swap.dup[j].token == _swap.output[i].dstToken) {
                    _isTokenDeposit(_swap.dup[j].token, _swap.dup[j].amount);
                    unchecked {
                        _bridgeAmount[i] += _swap.dup[j].amount;
                    }
                }
                unchecked {
                    ++j;
                }
            }

            if (_swap.output[i].dstToken != NATIVE_ADDRESS) {
                uint256 currentAllowance = IERC20(_swap.output[i].dstToken).allowance(address(this), PLEXUS);
                if (currentAllowance != 0) {
                    IERC20(_swap.output[i].dstToken).safeApprove(PLEXUS, 0);
                }
                IERC20(_swap.output[i].dstToken).safeApprove(PLEXUS, _bridgeAmount[i]);
            }

            unchecked {
                ++i;
            }
        }
        emit WholeTheta(msg.sender, _swap.output, _bridgeAmount, "THETAV2");

        if (_outputLength == 1) {
            uint256 totalRate;
            //single Token Multi Bridge
            // 1. oneToken - multi bridge - NO MORE SPLIT
            for (uint256 i = 0; i < splitData.splitRate[0].length; ) {
                SelectorCheck memory selectorCheck = functionSelectInfo[bytes4(thetas[i].callData)];
                if (selectorCheck.check == false) revert NotSupported();

                bytes memory newData = IFixtool(selectorCheck.selectorAddr).fixAmountBridgeData(
                    thetas[i].callData,
                    (_bridgeAmount[0] * splitData.splitRate[0][i]) / 100
                );
                thetas[i].callData = newData;

                if (_swap.output[0].dstToken == NATIVE_ADDRESS) {
                    thetas[i].value = (_bridgeAmount[0] * splitData.splitRate[0][i]) / 100;
                }

                unchecked {
                    totalRate += splitData.splitRate[0][i];
                    ++i;
                }
            }
            if (totalRate != 100) revert NOT_CORRECT_RATE();
        } else {
            //multi Token Multi Bridge
            //1.swap - multi Token -  multi bridge - NO MORE SPLIT
            if (splitData.multiStandard == true) {
                for (uint256 i = 0; i < thetas.length; ) {
                    SelectorCheck memory selectorCheck = functionSelectInfo[bytes4(thetas[i].callData)];
                    if (selectorCheck.check == false) revert NotSupported();
                    bytes memory newData = IFixtool(selectorCheck.selectorAddr).fixAmountBridgeData(thetas[i].callData, _bridgeAmount[i]);
                    thetas[i].callData = newData;
                    if (_swap.output[i].dstToken == NATIVE_ADDRESS) {
                        thetas[i].value = _bridgeAmount[i];
                    }

                    unchecked {
                        ++i;
                    }
                }
            } else if (splitData.multiStandard == false) {
                //2. swap -  multi bridge -  SPLIT
                uint256 thetaIndex = 0;
                for (uint256 i = 0; i < splitData.splitRate.length; i++) {
                    uint256[] memory currentSplitRates = splitData.splitRate[i];
                    uint256 totalRate = 0;
                    for (uint256 j = 0; j < currentSplitRates.length; ) {
                        SelectorCheck memory selectorCheck = functionSelectInfo[bytes4(thetas[thetaIndex].callData)];
                        uint256 newAmount = (_bridgeAmount[i] * currentSplitRates[j]) / 100;
                        if (_swap.output[i].dstToken == NATIVE_ADDRESS) {
                            thetas[thetaIndex].value = newAmount;
                        }
                        bytes memory newData = IFixtool(selectorCheck.selectorAddr).fixAmountBridgeData(thetas[thetaIndex].callData, newAmount);
                        thetas[thetaIndex].callData = newData;
                        thetaIndex++;
                        totalRate += currentSplitRates[j];
                        unchecked {
                            ++j;
                        }
                    }
                    if (totalRate != 100) revert NOT_CORRECT_RATE();
                }
                if (thetaIndex != thetas.length) revert MISSMATCH();
            }
        }

        _thetaV2Call(thetas);
    }

    function _thetaV2Call(ThetaValue[] memory thetas) internal {
        for (uint256 i = 0; i < thetas.length; ) {
            (bool success, bytes memory result) = PLEXUS.call{value: thetas[i].value}(thetas[i].callData);
            if (!success) {
                _revertWithError(result);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _revertWithError(bytes memory result) internal pure {
        if (result.length > 0) {
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(result)
                revert(add(32, result), returndata_size)
            }
        } else {
            revert("without error message");
        }
    }

    function _getBalance(address token) internal view returns (uint256) {
        return token == NATIVE_ADDRESS ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    function _isNative(address _token) internal pure returns (bool) {
        return (IERC20(_token) == IERC20(NATIVE_ADDRESS));
    }

    function _approvePlexus(address srcToken, uint256 amount) internal {
        _isTokenDeposit(srcToken, amount);
        if (srcToken != NATIVE_ADDRESS) {
            IERC20(srcToken).safeIncreaseAllowance(PLEXUS, amount);
        }
    }

    function _isTokenDeposit(address _token, uint256 _amount) internal returns (bool isNotNative) {
        isNotNative = !_isNative(_token);

        if (isNotNative) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        } else {
            if (msg.value < _amount) revert MORE_VALUE();
        }
    }

    function _isSwapTokenDeposit(InputToken[] calldata input) internal {
        uint256 nativeAmount = 0;
        if (input.length > 3) revert NotSupported(); //input token maximum 3
        for (uint i; i < input.length; ) {
            if (!_isNative(input[i].srcToken)) {
                IERC20(input[i].srcToken).safeTransferFrom(msg.sender, address(this), input[i].amount);
            } else {
                nativeAmount = nativeAmount + input[i].amount;
            }
            unchecked {
                ++i;
            }
        }
        if (msg.value < nativeAmount) revert MORE_VALUE();
    }

    function _isTokenApprove(SwapData calldata swap) internal returns (uint256) {
        if (!allowedDex[swap.router]) revert MUST_ALLOWED();
        InputToken[] calldata input = swap.input;
        uint256 nativeAmount = 0;

        for (uint i; i < input.length; ) {
            if (!_isNative(input[i].srcToken)) {
                address proxyRouter = proxy[swap.router];
                if (proxyRouter != address(0)) {
                    //using paraswap
                    IERC20(input[i].srcToken).safeApprove(proxyRouter, 0);
                    IERC20(input[i].srcToken).safeApprove(proxyRouter, input[i].amount);
                }
                IERC20(input[i].srcToken).safeApprove(swap.router, 0);
                IERC20(input[i].srcToken).safeApprove(swap.router, input[i].amount);
            } else {
                nativeAmount = input[i].amount;
            }
            unchecked {
                ++i;
            }
        }
        if (msg.value < nativeAmount) revert MORE_VALUE();

        return nativeAmount;
    }

    function _bridgeSwapStart(SwapData calldata swap) internal returns (uint256[] memory) {
        uint256 nativeAmount = _isTokenApprove(swap);

        uint256 length = swap.output.length;
        uint256[] memory initDstTokenBalance = new uint256[](length);
        uint256[] memory dstTokenBalance = new uint256[](length);

        for (uint i; i < length; ) {
            initDstTokenBalance[i] = _getBalance(swap.output[i].dstToken);
            unchecked {
                ++i;
            }
        }
        (bool succ, ) = swap.router.call{value: nativeAmount}(swap.callData);
        if (succ) {
            for (uint i; i < length; ) {
                uint256 currentBalance = _getBalance(swap.output[i].dstToken);
                if (swap.output[i].dstToken == NATIVE_ADDRESS) {
                    dstTokenBalance[i] = currentBalance;
                } else {
                    dstTokenBalance[i] = currentBalance >= initDstTokenBalance[i] ? currentBalance - initDstTokenBalance[i] : currentBalance;
                }
                unchecked {
                    ++i;
                }
            }
            return dstTokenBalance;
        } else {
            revert SWAP_FAILED();
        }
    }
    function _safeNativeTransfer(address to_, uint256 amount_) internal {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe safeTransfer fail");
    }
    function EmergencyWithdraw(address _tokenAddress, uint256 amount) public onlyOwner {
        bool isNotNative = !_isNative(_tokenAddress);
        if (isNotNative) {
            IERC20(_tokenAddress).safeTransfer(owner(), amount);
        } else {
            _safeNativeTransfer(owner(), amount);
        }
    }
    receive() external payable {}
}