// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { Initializable } from "openzeppelin/proxy/utils/Initializable.sol";

import { IPoolAdapter } from "pwn/interfaces/IPoolAdapter.sol";
import { IStateFingerpringComputer } from "pwn/interfaces/IStateFingerpringComputer.sol";


/**
 * @title PWN Config
 * @notice Contract holding configurable values of PWN protocol.
 * @dev Is intended to be used as a proxy via `TransparentUpgradeableProxy`.
 */
contract PWNConfig is Ownable2Step, Initializable {

    string internal constant VERSION = "1.2";

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    uint16 public constant MAX_FEE = 1000; // 10%

    /**
     * @notice Protocol fee value in basis points.
     * @dev Value of 100 is 1% fee.
     */
    uint16 public fee;

    /**
     * @notice Address that collects protocol fees.
     */
    address public feeCollector;

    /**
     * @notice Mapping of a loan contract address to LOAN token metadata uri.
     * @dev LOAN token minted by a loan contract will return metadata uri stored in this mapping.
     *      If there is no metadata uri for a loan contract, default metadata uri will be used stored under address(0).
     */
    mapping (address => string) private _loanMetadataUri;

    /**
     * @notice Mapping holding registered state fingerprint computer to an asset.
     */
    mapping (address => address) private _sfComputerRegistry;

    /**
     * @notice Mapping holding registered pool adapter to a pool address.
     */
    mapping (address => address) private _poolAdapterRegistry;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Emitted when new fee value is set.
     */
    event FeeUpdated(uint16 oldFee, uint16 newFee);

    /**
     * @notice Emitted when new fee collector address is set.
     */
    event FeeCollectorUpdated(address oldFeeCollector, address newFeeCollector);

    /**
     * @notice Emitted when new LOAN token metadata uri is set.
     */
    event LOANMetadataUriUpdated(address indexed loanContract, string newUri);

    /**
     * @notice Emitted when new default LOAN token metadata uri is set.
     */
    event DefaultLOANMetadataUriUpdated(string newUri);


    /*----------------------------------------------------------*|
    |*  # ERRORS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @notice Thrown when registering a computer which does not support the asset it is registered for.
     */
    error InvalidComputerContract(address computer, address asset);

    /**
     * @notice Thrown when trying to set a fee value higher than `MAX_FEE`.
     */
    error InvalidFeeValue(uint256 fee, uint256 limit);

    /**
     * @notice Thrown when trying to set a fee collector to zero address.
     */
    error ZeroFeeCollector();

    /**
     * @notice Thrown when trying to set a LOAN token metadata uri for zero address loan contract.
     */
    error ZeroLoanContract();


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() Ownable2Step() {
        // PWNConfig is used as a proxy. Use initializer to setup initial properties.
        _disableInitializers();
        _transferOwnership(address(0));
    }

    function initialize(address _owner, uint16 _fee, address _feeCollector) external initializer {
        require(_owner != address(0), "Owner is zero address");
        _transferOwnership(_owner);
        _setFeeCollector(_feeCollector);
        _setFee(_fee);
    }


    /*----------------------------------------------------------*|
    |*  # FEE MANAGEMENT                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set new protocol fee value.
     * @param _fee New fee value in basis points. Value of 100 is 1% fee.
     */
    function setFee(uint16 _fee) external onlyOwner {
        _setFee(_fee);
    }

    /**
     * @notice Internal implementation of setting new protocol fee value.
     * @param _fee New fee value in basis points. Value of 100 is 1% fee.
     */
    function _setFee(uint16 _fee) private {
        if (_fee > MAX_FEE)
            revert InvalidFeeValue({ fee: _fee, limit: MAX_FEE });

        uint16 oldFee = fee;
        fee = _fee;
        emit FeeUpdated(oldFee, _fee);
    }

    /**
     * @notice Set new fee collector address.
     * @param _feeCollector New fee collector address.
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Internal implementation of setting new fee collector address.
     * @param _feeCollector New fee collector address.
     */
    function _setFeeCollector(address _feeCollector) private {
        if (_feeCollector == address(0))
            revert ZeroFeeCollector();

        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(oldFeeCollector, _feeCollector);
    }


    /*----------------------------------------------------------*|
    |*  # LOAN METADATA                                         *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set a LOAN token metadata uri for a specific loan contract.
     * @param loanContract Address of a loan contract.
     * @param metadataUri New value of LOAN token metadata uri for given `loanContract`.
     */
    function setLOANMetadataUri(address loanContract, string memory metadataUri) external onlyOwner {
        if (loanContract == address(0))
            // address(0) is used as a default metadata uri. Use `setDefaultLOANMetadataUri` to set default metadata uri.
            revert ZeroLoanContract();

        _loanMetadataUri[loanContract] = metadataUri;
        emit LOANMetadataUriUpdated(loanContract, metadataUri);
    }

    /**
     * @notice Set a default LOAN token metadata uri.
     * @param metadataUri New value of default LOAN token metadata uri.
     */
    function setDefaultLOANMetadataUri(string memory metadataUri) external onlyOwner {
        _loanMetadataUri[address(0)] = metadataUri;
        emit DefaultLOANMetadataUriUpdated(metadataUri);
    }

    /**
     * @notice Return a LOAN token metadata uri base on a loan contract that minted the token.
     * @param loanContract Address of a loan contract.
     * @return uri Metadata uri for given loan contract.
     */
    function loanMetadataUri(address loanContract) external view returns (string memory uri) {
        uri = _loanMetadataUri[loanContract];
        // If there is no metadata uri for a loan contract, use default metadata uri.
        if (bytes(uri).length == 0)
            uri = _loanMetadataUri[address(0)];
    }


    /*----------------------------------------------------------*|
    |*  # STATE FINGERPRINT COMPUTER                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Returns the state fingerprint computer for a given asset.
     * @param asset The asset for which the computer is requested.
     * @return The computer for the given asset.
     */
    function getStateFingerprintComputer(address asset) external view returns (IStateFingerpringComputer) {
        return IStateFingerpringComputer(_sfComputerRegistry[asset]);
    }

    /**
     * @notice Registers a state fingerprint computer for a given asset.
     * @param asset The asset for which the computer is registered.
     * @param computer The computer to be registered. Use address(0) to remove a computer.
     */
    function registerStateFingerprintComputer(address asset, address computer) external onlyOwner {
        if (computer != address(0))
            if (!IStateFingerpringComputer(computer).supportsToken(asset))
                revert InvalidComputerContract({ computer: computer, asset: asset });

        _sfComputerRegistry[asset] = computer;
    }


    /*----------------------------------------------------------*|
    |*  # POOL ADAPTER                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Returns the pool adapter for a given pool.
     * @param pool The pool for which the adapter is requested.
     * @return The adapter for the given pool.
     */
    function getPoolAdapter(address pool) external view returns (IPoolAdapter) {
        return IPoolAdapter(_poolAdapterRegistry[pool]);
    }

    /**
     * @notice Registers a pool adapter for a given pool.
     * @param pool The pool for which the adapter is registered.
     * @param adapter The adapter to be registered.
     */
    function registerPoolAdapter(address pool, address adapter) external onlyOwner {
        _poolAdapterRegistry[pool] = adapter;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IPoolAdapter
 * @notice Interface for pool adapters used to withdraw and supply assets to the pool.
 */
interface IPoolAdapter {

    /**
     * @notice Withdraw an asset from the pool on behalf of the owner.
     * @dev Withdrawn asset remains in the owner. Caller must have the ACTIVE_LOAN tag in the hub.
     * @param pool The address of the pool from which the asset is withdrawn.
     * @param owner The address of the owner from whom the asset is withdrawn.
     * @param asset The address of the asset to withdraw.
     * @param amount The amount of the asset to withdraw.
     */
    function withdraw(address pool, address owner, address asset, uint256 amount) external;

    /**
     * @notice Supply an asset to the pool on behalf of the owner.
     * @dev Need to transfer the asset to the adapter before calling this function.
     * @param pool The address of the pool to which the asset is supplied.
     * @param owner The address of the owner on whose behalf the asset is supplied.
     * @param asset The address of the asset to supply.
     * @param amount The amount of the asset to supply.
     */
    function supply(address pool, address owner, address asset, uint256 amount) external;

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IStateFingerpringComputer
 * @notice State Fingerprint Computer Interface.
 * @dev Contract can compute state fingerprint of several tokens as long as they share the same state structure.
 */
interface IStateFingerpringComputer {

    /**
     * @notice Compute current token state fingerprint for a given token.
     * @param token Address of a token contract.
     * @param tokenId Token id to compute state fingerprint for.
     * @return Current token state fingerprint.
     */
    function computeStateFingerprint(address token, uint256 tokenId) external view returns (bytes32);

    /**
     * @notice Check if the computer supports a given token address.
     * @param token Address of a token contract.
     * @return True if the computer supports the token address, false otherwise.
     */
    function supportsToken(address token) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}