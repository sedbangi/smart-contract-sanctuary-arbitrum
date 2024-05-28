// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./base/Admin.sol";
import "./base/NonDelegateMulticall.sol";

contract Compounder is Admin, NonDelegateMulticall {
    error NotApprovedCompounder();

    event ApprovedCompounderSet(address approvedCompounder);
    event CompoundedFor(address[] targets);

    address payable public approvedCompounder;

    constructor(
        SickleRegistry registry_,
        address payable approvedCompounder_
    ) Admin(msg.sender) NonDelegateMulticall(registry_) {
        approvedCompounder = approvedCompounder_;
    }

    modifier onlyApprovedCompounder() {
        if (msg.sender != approvedCompounder) revert NotApprovedCompounder();
        _;
    }

    /// @notice Update approved compounder address.
    /// @dev Controls which external address is allowed to
    /// compound farming positions for Sickles. This is expected to be the EOA
    /// of a compounder bot.
    /// @custom:access Restricted to protocol admin.
    function setApprovedCompounder(address payable approvedCompounder_)
        external
        onlyAdmin
    {
        approvedCompounder = approvedCompounder_;
        emit ApprovedCompounderSet(approvedCompounder_);
    }

    function compoundFor(
        address[] memory targets,
        bytes[] memory data
    ) external onlyApprovedCompounder {
        this.multicall(targets, data);
        emit CompoundedFor(targets);
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Admin contract
/// @author vfat.tools
/// @notice Provides an administration mechanism allowing restricted functions
abstract contract Admin {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the admin
    error NotAdminError(); //0xb5c42b3b

    /// EVENTS ///

    /// @notice Emitted when a new admin is set
    /// @param oldAdmin Address of the old admin
    /// @param newAdmin Address of the new admin
    event AdminSet(address oldAdmin, address newAdmin);

    /// STORAGE ///

    /// @notice Address of the current admin
    address public admin;

    /// MODIFIERS ///

    /// @dev Restricts a function to the admin
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdminError();
        _;
    }

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    constructor(address admin_) {
        emit AdminSet(admin, admin_);
        admin = admin_;
    }

    /// @notice Sets a new admin
    /// @param newAdmin Address of the new admin
    /// @custom:access Restricted to protocol admin.
    function setAdmin(address newAdmin) external onlyAdmin {
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../base/SickleStorage.sol";
import "../SickleRegistry.sol";

/// @title Multicall contract
/// @author vfat.tools
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract NonDelegateMulticall is SickleStorage {
    /// ERRORS ///

    error MulticallParamsMismatchError(); // 0xc1e637c9

    /// @notice Thrown when the target contract is not whitelisted
    /// @param target Address of the non-whitelisted target
    error TargetNotWhitelisted(address target); // 0x47ccabe7

    /// @notice Thrown when the caller is not whitelisted
    /// @param caller Address of the non-whitelisted caller
    error CallerNotWhitelisted(address caller); // 0x252c8273

    /// STORAGE ///

    /// @notice Address of the SickleRegistry contract
    /// @dev Needs to be immutable so that it's accessible for Sickle proxies
    SickleRegistry public immutable registry;

    /// INITIALIZATION ///

    /// @param registry_ Address of the SickleRegistry contract
    constructor(SickleRegistry registry_) initializer {
        registry = registry_;
    }

    /// WRITE FUNCTIONS ///

    /// @notice Batch multiple calls together (calls or delegatecalls)
    /// @param targets Array of targets to call
    /// @param data Array of data to pass with the calls
    function multicall(
        address[] calldata targets,
        bytes[] calldata data
    ) external payable {
        if (targets.length != data.length) {
            revert MulticallParamsMismatchError();
        }

        if (!registry.isWhitelistedCaller(msg.sender)) {
            revert CallerNotWhitelisted(msg.sender);
        }

        for (uint256 i = 0; i != data.length;) {
            if (targets[i] == address(0)) {
                unchecked {
                    ++i;
                }
                continue; // No-op
            }

            if (targets[i] != address(this)) {
                if (!registry.isWhitelistedTarget(targets[i])) {
                    revert TargetNotWhitelisted(targets[i]);
                }
            }

            (bool success, bytes memory result) = targets[i].call(data[i]);

            if (!success) {
                if (result.length == 0) revert();
                assembly {
                    revert(add(32, result), mload(result))
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

library SickleStorageEvents {
    event ApprovedAddressChanged(address newApproved);
}

/// @title SickleStorage contract
/// @author vfat.tools
/// @notice Base storage of the Sickle contract
/// @dev This contract needs to be inherited by stub contracts meant to be used
/// with `delegatecall`
abstract contract SickleStorage is Initializable {
    /// ERRORS ///

    /// @notice Thrown when the caller is not the owner of the Sickle contract
    error NotOwnerError(); // 0x74a21527

    /// @notice Thrown when the caller is not a strategy contract or the
    /// Flashloan Stub
    error NotStrategyError(); // 0x4581ba62

    /// STORAGE ///

    /// @notice Address of the owner
    address public owner;

    /// @notice An address that can be set by the owner of the Sickle contract
    /// in order to trigger specific functions.
    address public approved;

    /// MODIFIERS ///

    /// @dev Restricts a function call to the owner, however if the admin was
    /// not set yet,
    /// the modifier will not restrict the call, this allows the SickleFactory
    /// to perform
    /// some calls on the user's behalf before passing the admin rights to them
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwnerError();
        _;
    }

    /// INITIALIZATION ///

    /// @param owner_ Address of the owner of this Sickle contract
    function _SickleStorage_initialize(
        address owner_,
        address approved_
    ) internal onlyInitializing {
        owner = owner_;
        approved = approved_;
    }

    /// WRITE FUNCTIONS ///

    /// @notice Sets the approved address of this Sickle
    /// @param newApproved Address meant to be approved by the owner
    function setApproved(address newApproved) external onlyOwner {
        approved = newApproved;
        emit SickleStorageEvents.ApprovedAddressChanged(newApproved);
    }

    /// @notice Checks if `caller` is either the owner of the Sickle contract
    /// or was approved by them
    /// @param caller Address to check
    /// @return True if `caller` is either the owner of the Sickle contract
    function isOwnerOrApproved(address caller) public view returns (bool) {
        return caller == owner || caller == approved;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./base/Admin.sol";

library SickleRegistryEvents {
    event CollectorChanged(address newCollector);
    event FeesUpdated(bytes32[] feeHashes, uint256[] feesInBP);
    event ReferralCodeCreated(bytes32 indexed code, address indexed referrer);

    // Multicall caller and target whitelist status changes
    event CallerStatusChanged(address caller, bool isWhitelisted);
    event TargetStatusChanged(address target, bool isWhitelisted);
}

/// @title SickleRegistry contract
/// @author vfat.tools
/// @notice Manages the whitelisted contracts and the collector address
contract SickleRegistry is Admin {
    /// ERRORS ///

    error ArrayLengthMismatch(); // 0xa24a13a6
    error FeeAboveMaxLimit(); // 0xd6cf7b5e
    error InvalidReferralCode(); // 0xe55b4629

    /// STORAGE ///

    /// @notice Address of the fee collector
    address public collector;

    /// @notice Tracks the contracts that can be called through Sickle multicall
    /// @return True if the contract is a whitelisted target
    mapping(address => bool) public isWhitelistedTarget;

    /// @notice Tracks the contracts that can call Sickle multicall
    /// @return True if the contract is a whitelisted caller
    mapping(address => bool) public isWhitelistedCaller;

    /// @notice Keeps track of the referrers and their associated code
    mapping(bytes32 => address) public referralCodes;

    /// @notice Mapping for fee hashes (hash of the strategy contract addresses
    /// and the function selectors) and their associated fees
    /// @return The fee in basis points to apply to the transaction amount
    mapping(bytes32 => uint256) public feeRegistry;

    /// WRITE FUNCTIONS ///

    /// @param admin_ Address of the admin
    /// @param collector_ Address of the collector
    constructor(address admin_, address collector_) Admin(admin_) {
        collector = collector_;
    }

    /// @notice Updates the whitelist status for multiple multicall targets
    /// @param targets Addresses of the contracts to update
    /// @param isApproved New status for the contracts
    /// @custom:access Restricted to protocol admin.
    function setWhitelistedTargets(
        address[] calldata targets,
        bool isApproved
    ) external onlyAdmin {
        for (uint256 i; i < targets.length;) {
            isWhitelistedTarget[targets[i]] = isApproved;
            emit SickleRegistryEvents.TargetStatusChanged(
                targets[i], isApproved
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Updates the fee collector address
    /// @param newCollector Address of the new fee collector
    /// @custom:access Restricted to protocol admin.
    function updateCollector(address newCollector) external onlyAdmin {
        collector = newCollector;
        emit SickleRegistryEvents.CollectorChanged(newCollector);
    }

    /// @notice Update the whitelist status for multiple multicall callers
    /// @param callers Addresses of the callers
    /// @param isApproved New status for the caller
    /// @custom:access Restricted to protocol admin.
    function setWhitelistedCallers(
        address[] calldata callers,
        bool isApproved
    ) external onlyAdmin {
        for (uint256 i; i < callers.length;) {
            isWhitelistedCaller[callers[i]] = isApproved;
            emit SickleRegistryEvents.CallerStatusChanged(
                callers[i], isApproved
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Associates a referral code to the address of the caller
    function setReferralCode(bytes32 referralCode) external {
        if (referralCodes[referralCode] != address(0)) {
            revert InvalidReferralCode();
        }

        referralCodes[referralCode] = msg.sender;
        emit SickleRegistryEvents.ReferralCodeCreated(referralCode, msg.sender);
    }

    /// @notice Update the fees for multiple strategy functions
    /// @param feeHashes Array of fee hashes
    /// @param feesArray Array of fees to apply (in basis points)
    /// @custom:access Restricted to protocol admin.
    function setFees(
        bytes32[] calldata feeHashes,
        uint256[] calldata feesArray
    ) external onlyAdmin {
        if (feeHashes.length != feesArray.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < feeHashes.length;) {
            if (feesArray[i] <= 500) {
                // maximum fee of 5%
                feeRegistry[feeHashes[i]] = feesArray[i];
            } else {
                revert FeeAboveMaxLimit();
            }
            unchecked {
                ++i;
            }
        }

        emit SickleRegistryEvents.FeesUpdated(feeHashes, feesArray);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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