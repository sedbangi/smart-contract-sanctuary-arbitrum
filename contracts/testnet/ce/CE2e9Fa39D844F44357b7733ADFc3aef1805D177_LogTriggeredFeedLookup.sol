// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../interfaces/LinkTokenInterface.sol";
import "../../interfaces/automation/2_0/AutomationRegistryInterface2_0.sol";
import "../../interfaces/TypeAndVersionInterface.sol";
import "../../ConfirmedOwner.sol";
import "../../interfaces/ERC677ReceiverInterface.sol";

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract KeeperRegistrar2_0 is TypeAndVersionInterface, ConfirmedOwner, ERC677ReceiverInterface {
  /**
   * DISABLED: No auto approvals, all new upkeeps should be approved manually.
   * ENABLED_SENDER_ALLOWLIST: Auto approvals for allowed senders subject to max allowed. Manual for rest.
   * ENABLED_ALL: Auto approvals for all new upkeeps subject to max allowed.
   */
  enum AutoApproveType {
    DISABLED,
    ENABLED_SENDER_ALLOWLIST,
    ENABLED_ALL
  }

  bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

  mapping(bytes32 => PendingRequest) private s_pendingRequests;

  LinkTokenInterface public immutable LINK;

  /**
   * @notice versions:
   * - KeeperRegistrar 2.0.0: Remove source from register
   *                          Breaks our example of "Register an Upkeep using your own deployed contract"
   * - KeeperRegistrar 1.1.0: Add functionality for sender allowlist in auto approve
   *                        : Remove rate limit and add max allowed for auto approve
   * - KeeperRegistrar 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistrar 2.0.0";

  struct RegistrarConfig {
    AutoApproveType autoApproveConfigType;
    uint32 autoApproveMaxAllowed;
    uint32 approvedCount;
    AutomationRegistryBaseInterface keeperRegistry;
    uint96 minLINKJuels;
  }

  struct PendingRequest {
    address admin;
    uint96 balance;
  }

  struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
  }

  RegistrarConfig private s_config;
  // Only applicable if s_config.configType is ENABLED_SENDER_ALLOWLIST
  mapping(address => bool) private s_autoApproveAllowedSenders;

  event RegistrationRequested(
    bytes32 indexed hash,
    string name,
    bytes encryptedEmail,
    address indexed upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes checkData,
    uint96 amount
  );

  event RegistrationApproved(bytes32 indexed hash, string displayName, uint256 indexed upkeepId);

  event RegistrationRejected(bytes32 indexed hash);

  event AutoApproveAllowedSenderSet(address indexed senderAddress, bool allowed);

  event ConfigChanged(
    AutoApproveType autoApproveConfigType,
    uint32 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  );

  error InvalidAdminAddress();
  error RequestNotFound();
  error HashMismatch();
  error OnlyAdminOrOwner();
  error InsufficientPayment();
  error RegistrationRequestFailed();
  error OnlyLink();
  error AmountMismatch();
  error SenderMismatch();
  error FunctionNotPermitted();
  error LinkTransferFailed(address to);
  error InvalidDataLength();

  /*
   * @param LINKAddress Address of Link token
   * @param autoApproveConfigType setting for auto-approve registrations
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param keeperRegistry keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   */
  constructor(
    address LINKAddress,
    AutoApproveType autoApproveConfigType,
    uint16 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  ) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(LINKAddress);
    setRegistrationConfig(autoApproveConfigType, autoApproveMaxAllowed, keeperRegistry, minLINKJuels);
  }

  //EXTERNAL

  /**
   * @notice register can only be called through transferAndCall on LINK contract
   * @param name string of the upkeep to be registered
   * @param encryptedEmail email address of upkeep contact
   * @param upkeepContract address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when performing upkeep
   * @param adminAddress address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   * @param amount quantity of LINK upkeep is funded with (specified in Juels)
   * @param offchainConfig offchainConfig for upkeep in bytes
   * @param sender address of the sender making the request
   */
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes calldata offchainConfig,
    uint96 amount,
    address sender
  ) external onlyLINK {
    _register(
      RegistrationParams({
        name: name,
        encryptedEmail: encryptedEmail,
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        checkData: checkData,
        offchainConfig: offchainConfig,
        amount: amount
      }),
      sender
    );
  }

  /**
   * @notice Allows external users to register upkeeps; assumes amount is approved for transfer by the contract
   * @param requestParams struct of all possible registration parameters
   */
  function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256) {
    if (requestParams.amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }

    LINK.transferFrom(msg.sender, address(this), requestParams.amount);

    return _register(requestParams, msg.sender);
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function approve(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes calldata offchainConfig,
    bytes32 hash
  ) external onlyOwner {
    PendingRequest memory request = s_pendingRequests[hash];
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    bytes32 expectedHash = keccak256(abi.encode(upkeepContract, gasLimit, adminAddress, checkData, offchainConfig));
    if (hash != expectedHash) {
      revert HashMismatch();
    }
    delete s_pendingRequests[hash];
    _approve(
      RegistrationParams({
        name: name,
        encryptedEmail: "",
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        checkData: checkData,
        offchainConfig: offchainConfig,
        amount: request.balance
      }),
      expectedHash
    );
  }

  /**
   * @notice cancel will remove a registration request and return the refunds to the request.admin
   * @param hash the request hash
   */
  function cancel(bytes32 hash) external {
    PendingRequest memory request = s_pendingRequests[hash];
    if (!(msg.sender == request.admin || msg.sender == owner())) {
      revert OnlyAdminOrOwner();
    }
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    delete s_pendingRequests[hash];
    bool success = LINK.transfer(request.admin, request.balance);
    if (!success) {
      revert LinkTransferFailed(request.admin);
    }
    emit RegistrationRejected(hash);
  }

  /**
   * @notice owner calls this function to set if registration requests should be sent directly to the Keeper Registry
   * @param autoApproveConfigType setting for auto-approve registrations
   *                   note: autoApproveAllowedSenders list persists across config changes irrespective of type
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param keeperRegistry new keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   */
  function setRegistrationConfig(
    AutoApproveType autoApproveConfigType,
    uint16 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  ) public onlyOwner {
    uint32 approvedCount = s_config.approvedCount;
    s_config = RegistrarConfig({
      autoApproveConfigType: autoApproveConfigType,
      autoApproveMaxAllowed: autoApproveMaxAllowed,
      approvedCount: approvedCount,
      minLINKJuels: minLINKJuels,
      keeperRegistry: AutomationRegistryBaseInterface(keeperRegistry)
    });

    emit ConfigChanged(autoApproveConfigType, autoApproveMaxAllowed, keeperRegistry, minLINKJuels);
  }

  /**
   * @notice owner calls this function to set allowlist status for senderAddress
   * @param senderAddress senderAddress to set the allowlist status for
   * @param allowed true if senderAddress needs to be added to allowlist, false if needs to be removed
   */
  function setAutoApproveAllowedSender(address senderAddress, bool allowed) external onlyOwner {
    s_autoApproveAllowedSenders[senderAddress] = allowed;

    emit AutoApproveAllowedSenderSet(senderAddress, allowed);
  }

  /**
   * @notice read the allowlist status of senderAddress
   * @param senderAddress address to read the allowlist status for
   */
  function getAutoApproveAllowedSender(address senderAddress) external view returns (bool) {
    return s_autoApproveAllowedSenders[senderAddress];
  }

  /**
   * @notice read the current registration configuration
   */
  function getRegistrationConfig()
    external
    view
    returns (
      AutoApproveType autoApproveConfigType,
      uint32 autoApproveMaxAllowed,
      uint32 approvedCount,
      address keeperRegistry,
      uint256 minLINKJuels
    )
  {
    RegistrarConfig memory config = s_config;
    return (
      config.autoApproveConfigType,
      config.autoApproveMaxAllowed,
      config.approvedCount,
      address(config.keeperRegistry),
      config.minLINKJuels
    );
  }

  /**
   * @notice gets the admin address and the current balance of a registration request
   */
  function getPendingRequest(bytes32 hash) external view returns (address, uint96) {
    PendingRequest memory request = s_pendingRequests[hash];
    return (request.admin, request.balance);
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param sender Address of the sender transfering LINK
   * @param amount Amount of LINK sent (specified in Juels)
   * @param data Payload of the transaction
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  )
    external
    override
    onlyLINK
    permittedFunctionsForLINK(data)
    isActualAmount(amount, data)
    isActualSender(sender, data)
  {
    if (data.length < 292) revert InvalidDataLength();
    if (amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }
    (bool success, ) = address(this).delegatecall(data);
    // calls register
    if (!success) {
      revert RegistrationRequestFailed();
    }
  }

  //PRIVATE

  /**
   * @dev verify registration request and emit RegistrationRequested event
   */
  function _register(RegistrationParams memory params, address sender) private returns (uint256) {
    if (params.adminAddress == address(0)) {
      revert InvalidAdminAddress();
    }
    bytes32 hash = keccak256(
      abi.encode(params.upkeepContract, params.gasLimit, params.adminAddress, params.checkData, params.offchainConfig)
    );

    emit RegistrationRequested(
      hash,
      params.name,
      params.encryptedEmail,
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.checkData,
      params.amount
    );

    uint256 upkeepId;
    RegistrarConfig memory config = s_config;
    if (_shouldAutoApprove(config, sender)) {
      s_config.approvedCount = config.approvedCount + 1;

      upkeepId = _approve(params, hash);
    } else {
      uint96 newBalance = s_pendingRequests[hash].balance + params.amount;
      s_pendingRequests[hash] = PendingRequest({admin: params.adminAddress, balance: newBalance});
    }

    return upkeepId;
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function _approve(RegistrationParams memory params, bytes32 hash) private returns (uint256) {
    AutomationRegistryBaseInterface keeperRegistry = s_config.keeperRegistry;

    // register upkeep
    uint256 upkeepId = keeperRegistry.registerUpkeep(
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.checkData,
      params.offchainConfig
    );
    // fund upkeep
    bool success = LINK.transferAndCall(address(keeperRegistry), params.amount, abi.encode(upkeepId));
    if (!success) {
      revert LinkTransferFailed(address(keeperRegistry));
    }

    emit RegistrationApproved(hash, params.name, upkeepId);

    return upkeepId;
  }

  /**
   * @dev verify sender allowlist if needed and check max limit
   */
  function _shouldAutoApprove(RegistrarConfig memory config, address sender) private view returns (bool) {
    if (config.autoApproveConfigType == AutoApproveType.DISABLED) {
      return false;
    }
    if (
      config.autoApproveConfigType == AutoApproveType.ENABLED_SENDER_ALLOWLIST && (!s_autoApproveAllowedSenders[sender])
    ) {
      return false;
    }
    if (config.approvedCount < config.autoApproveMaxAllowed) {
      return true;
    }
    return false;
  }

  //MODIFIERS

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    if (msg.sender != address(LINK)) {
      revert OnlyLink();
    }
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `register` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(_data, 32)) // First 32 bytes contain length of data
    }
    if (funcSelector != REGISTER_REQUEST_SELECTOR) {
      revert FunctionNotPermitted();
    }
    _;
  }

  /**
   * @dev Reverts if the actual amount passed does not match the expected amount
   * @param expected amount that should match the actual amount
   * @param data bytes
   */
  modifier isActualAmount(uint256 expected, bytes calldata data) {
    // decode register function arguments to get actual amount
    (, , , , , , , uint96 amount, ) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, bytes, bytes, uint96, address)
    );
    if (expected != amount) {
      revert AmountMismatch();
    }
    _;
  }

  /**
   * @dev Reverts if the actual sender address does not match the expected sender address
   * @param expected address that should match the actual sender address
   * @param data bytes
   */
  modifier isActualSender(address expected, bytes calldata data) {
    // decode register function arguments to get actual sender
    (, , , , , , , , address sender) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, bytes, bytes, uint96, address)
    );
    if (expected != sender) {
      revert SenderMismatch();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FeedLookupCompatibleInterface {
  error FeedLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

  /**
   * @notice any contract which wants to utilize FeedLookup feature needs to
   * implement this interface as well as the automation compatible interface.
   * @param values an array of bytes returned from Mercury endpoint.
   * @param extraData context data from feed lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: MIT
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IKeeperRegistryMaster {
  error ArrayHasNoEntries();
  error CannotCancel();
  error ConfigDigestMismatch();
  error DuplicateEntry();
  error DuplicateSigners();
  error GasLimitCanOnlyIncrease();
  error GasLimitOutsideRange();
  error IncorrectNumberOfFaultyOracles();
  error IncorrectNumberOfSignatures();
  error IncorrectNumberOfSigners();
  error IndexOutOfRange();
  error InsufficientFunds();
  error InvalidDataLength();
  error InvalidPayee();
  error InvalidRecipient();
  error InvalidReport();
  error InvalidTrigger();
  error InvalidTriggerType();
  error MaxCheckDataSizeCanOnlyIncrease();
  error MaxPerformDataSizeCanOnlyIncrease();
  error MigrationNotPermitted();
  error NotAContract();
  error OnlyActiveSigners();
  error OnlyActiveTransmitters();
  error OnlyCallableByAdmin();
  error OnlyCallableByLINKToken();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedAdmin();
  error OnlyCallableByProposedPayee();
  error OnlyCallableByUpkeepPrivilegeManager();
  error OnlyPausedUpkeep();
  error OnlySimulatedBackend();
  error OnlyUnpausedUpkeep();
  error ParameterLengthError();
  error PaymentGreaterThanAllLINK();
  error PipelineDataExceedsLimit();
  error ReentrantCall();
  error RegistryPaused();
  error RepeatedSigner();
  error RepeatedTransmitter();
  error TargetCheckReverted(bytes reason);
  error TooManyOracles();
  error TranscoderNotSet();
  error UpkeepAlreadyExists();
  error UpkeepCancelled();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error ValueNotChanged();
  event CancelledUpkeepReport(uint256 indexed id, bytes trigger);
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    bytes32 configDigest,
    uint64 configCount,
    address[] signers,
    address[] transmitters,
    uint8 f,
    bytes onchainConfig,
    uint64 offchainConfigVersion,
    bytes offchainConfig
  );
  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event InsufficientFundsUpkeepReport(uint256 indexed id, bytes trigger);
  event OwnerFundsWithdrawn(uint96 amount);
  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);
  event Paused(address account);
  event PayeesUpdated(address[] transmitters, address[] payees);
  event PayeeshipTransferRequested(address indexed transmitter, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed transmitter, address indexed from, address indexed to);
  event PaymentWithdrawn(address indexed transmitter, uint256 indexed amount, address indexed to, address payee);
  event ReorgedUpkeepReport(uint256 indexed id, bytes trigger);
  event StaleUpkeepReport(uint256 indexed id, bytes trigger);
  event Transmitted(bytes32 configDigest, uint32 epoch);
  event Unpaused(address account);
  event UpkeepAdminTransferRequested(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepAdminTransferred(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepOffchainConfigSet(uint256 indexed id, bytes offchainConfig);
  event UpkeepPaused(uint256 indexed id);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    uint96 totalPayment,
    uint256 gasUsed,
    uint256 gasOverhead,
    bytes trigger
  );
  event UpkeepPipelineDataSet(uint256 indexed id, bytes newPipelineData);
  event UpkeepPrivilegeConfigSet(uint256 indexed id, bytes privilegeConfig);
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event UpkeepRegistered(uint256 indexed id, uint32 executeGas, address admin);
  event UpkeepTriggerConfigSet(uint256 indexed id, bytes triggerConfig);
  event UpkeepUnpaused(uint256 indexed id);

  fallback() external;

  function acceptOwnership() external;

  function fallbackTo() external view returns (address);

  function getFastGasFeedAddress() external view returns (address);

  function getLinkAddress() external view returns (address);

  function getLinkNativeFeedAddress() external view returns (address);

  function getMode() external view returns (uint8);

  function getTriggerType(uint256 upkeepId) external pure returns (uint8);

  function latestConfigDetails() external view returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest);

  function latestConfigDigestAndEpoch() external view returns (bool scanLogs, bytes32 configDigest, uint32 epoch);

  function onTokenTransfer(address sender, uint256 amount, bytes memory data) external;

  function owner() external view returns (address);

  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfigBytes,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external;

  function simulatePerformUpkeep(uint256 id, bytes memory performData) external returns (bool success, uint256 gasUsed);

  function transferOwnership(address to) external;

  function transmit(
    bytes32[3] memory reportContext,
    bytes memory rawReport,
    bytes32[] memory rs,
    bytes32[] memory ss,
    bytes32 rawVs
  ) external;

  function typeAndVersion() external view returns (string memory);

  function addFunds(uint256 id, uint96 amount) external;

  function cancelUpkeep(uint256 id) external;

  function checkCallback(
    uint256 id,
    bytes[] memory values,
    bytes memory extraData
  ) external returns (bool upkeepNeeded, bytes memory performData, uint8 upkeepFailureReason, uint256 gasUsed);

  function checkUpkeep(
    uint256 id,
    bytes memory checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      uint8 upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    );

  function checkUpkeep(
    uint256 id
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      uint8 upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    );

  function executeCallback(
    uint256 id,
    bytes memory payload
  ) external returns (bool upkeepNeeded, bytes memory performData, uint8 upkeepFailureReason, uint256 gasUsed);

  function migrateUpkeeps(uint256[] memory ids, address destination) external;

  function receiveUpkeeps(bytes memory encodedUpkeeps) external;

  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    uint8 triggerType,
    bytes memory checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig
  ) external returns (uint256 id);

  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes memory checkData,
    bytes memory offchainConfig
  ) external returns (uint256 id);

  function setUpkeepTriggerConfig(uint256 id, bytes memory triggerConfig) external;

  function upkeepTranscoderVersion() external view returns (uint8);

  function upkeepVersion() external view returns (uint8);

  function acceptPayeeship(address transmitter) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function getActiveUpkeepIDs(uint256 startIndex, uint256 endIndex) external view returns (uint256[] memory);

  function getActiveUpkeepIDsByType(
    uint256 startIndex,
    uint256 endIndex,
    uint8 trigger
  ) external view returns (uint256[] memory);

  function getBlockTriggerConfig(
    uint256 upkeepId
  ) external view returns (KeeperRegistryBase2_1.BlockTriggerConfig memory);

  function getLogTriggerConfig(uint256 upkeepId) external view returns (KeeperRegistryBase2_1.LogTriggerConfig memory);

  function getMaxPaymentForGas(uint8 triggerType, uint32 gasLimit) external view returns (uint96 maxPayment);

  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance);

  function getPeerRegistryMigrationPermission(address peer) external view returns (uint8);

  function getSignerInfo(address query) external view returns (bool active, uint8 index);

  function getState()
    external
    view
    returns (
      KeeperRegistryBase2_1.State memory state,
      KeeperRegistryBase2_1.OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );

  function getTransmitterInfo(
    address query
  ) external view returns (bool active, uint8 index, uint96 balance, uint96 lastCollected, address payee);

  function getUpkeep(uint256 id) external view returns (KeeperRegistryBase2_1.UpkeepInfo memory upkeepInfo);

  function getUpkeepPrivilegeConfig(uint256 upkeepId) external view returns (bytes memory);

  function getUpkeepTriggerConfig(uint256 upkeepId) external view returns (bytes memory);

  function pause() external;

  function pauseUpkeep(uint256 id) external;

  function recoverFunds() external;

  function setPayees(address[] memory payees) external;

  function setPeerRegistryMigrationPermission(address peer, uint8 permission) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes memory config) external;

  function setUpkeepPipelineData(uint256 id, bytes memory newPipelineData) external;

  function setUpkeepPrivilegeConfig(uint256 upkeepId, bytes memory newPrivilegeConfig) external;

  function transferPayeeship(address transmitter, address proposed) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function unpause() external;

  function unpauseUpkeep(uint256 id) external;

  function withdrawFunds(uint256 id, address to) external;

  function withdrawOwnerFunds() external;

  function withdrawPayment(address from, address to) external;
}

interface KeeperRegistryBase2_1 {
  struct BlockTriggerConfig {
    uint32 checkCadance;
  }

  struct LogTriggerConfig {
    address contractAddress;
    uint8 filterSelector;
    bytes32 topic0;
    bytes32 topic1;
    bytes32 topic2;
    bytes32 topic3;
  }

  struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint96 totalPremium;
    uint256 numUpkeeps;
    uint32 configCount;
    uint32 latestConfigBlockNumber;
    bytes32 latestConfigDigest;
    uint32 latestEpoch;
    bool paused;
  }

  struct OnchainConfig {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend;
    uint32 maxPerformGas;
    uint32 maxCheckDataSize;
    uint32 maxPerformDataSize;
    uint256 fallbackGasPrice;
    uint256 fallbackLinkPrice;
    address transcoder;
    address[] registrars;
    address upkeepPrivilegeManager;
  }

  struct UpkeepInfo {
    address target;
    address forwarder;
    uint32 executeGas;
    bytes checkData;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    uint32 lastPerformedBlockNumber;
    uint96 amountSpent;
    bool paused;
    bytes offchainConfig;
  }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"contract KeeperRegistryLogicA2_1","name":"logicA","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"ArrayHasNoEntries","type":"error"},{"inputs":[],"name":"CannotCancel","type":"error"},{"inputs":[],"name":"ConfigDigestMismatch","type":"error"},{"inputs":[],"name":"DuplicateEntry","type":"error"},{"inputs":[],"name":"DuplicateSigners","type":"error"},{"inputs":[],"name":"GasLimitCanOnlyIncrease","type":"error"},{"inputs":[],"name":"GasLimitOutsideRange","type":"error"},{"inputs":[],"name":"IncorrectNumberOfFaultyOracles","type":"error"},{"inputs":[],"name":"IncorrectNumberOfSignatures","type":"error"},{"inputs":[],"name":"IncorrectNumberOfSigners","type":"error"},{"inputs":[],"name":"IndexOutOfRange","type":"error"},{"inputs":[],"name":"InsufficientFunds","type":"error"},{"inputs":[],"name":"InvalidDataLength","type":"error"},{"inputs":[],"name":"InvalidPayee","type":"error"},{"inputs":[],"name":"InvalidRecipient","type":"error"},{"inputs":[],"name":"InvalidReport","type":"error"},{"inputs":[],"name":"InvalidTrigger","type":"error"},{"inputs":[],"name":"InvalidTriggerType","type":"error"},{"inputs":[],"name":"MaxCheckDataSizeCanOnlyIncrease","type":"error"},{"inputs":[],"name":"MaxPerformDataSizeCanOnlyIncrease","type":"error"},{"inputs":[],"name":"MigrationNotPermitted","type":"error"},{"inputs":[],"name":"NotAContract","type":"error"},{"inputs":[],"name":"OnlyActiveSigners","type":"error"},{"inputs":[],"name":"OnlyActiveTransmitters","type":"error"},{"inputs":[],"name":"OnlyCallableByAdmin","type":"error"},{"inputs":[],"name":"OnlyCallableByLINKToken","type":"error"},{"inputs":[],"name":"OnlyCallableByOwnerOrAdmin","type":"error"},{"inputs":[],"name":"OnlyCallableByOwnerOrRegistrar","type":"error"},{"inputs":[],"name":"OnlyCallableByPayee","type":"error"},{"inputs":[],"name":"OnlyCallableByProposedAdmin","type":"error"},{"inputs":[],"name":"OnlyCallableByProposedPayee","type":"error"},{"inputs":[],"name":"OnlyCallableByUpkeepPrivilegeManager","type":"error"},{"inputs":[],"name":"OnlyPausedUpkeep","type":"error"},{"inputs":[],"name":"OnlySimulatedBackend","type":"error"},{"inputs":[],"name":"OnlyUnpausedUpkeep","type":"error"},{"inputs":[],"name":"ParameterLengthError","type":"error"},{"inputs":[],"name":"PaymentGreaterThanAllLINK","type":"error"},{"inputs":[],"name":"PipelineDataExceedsLimit","type":"error"},{"inputs":[],"name":"ReentrantCall","type":"error"},{"inputs":[],"name":"RegistryPaused","type":"error"},{"inputs":[],"name":"RepeatedSigner","type":"error"},{"inputs":[],"name":"RepeatedTransmitter","type":"error"},{"inputs":[{"internalType":"bytes","name":"reason","type":"bytes"}],"name":"TargetCheckReverted","type":"error"},{"inputs":[],"name":"TooManyOracles","type":"error"},{"inputs":[],"name":"TranscoderNotSet","type":"error"},{"inputs":[],"name":"UpkeepAlreadyExists","type":"error"},{"inputs":[],"name":"UpkeepCancelled","type":"error"},{"inputs":[],"name":"UpkeepNotCanceled","type":"error"},{"inputs":[],"name":"UpkeepNotNeeded","type":"error"},{"inputs":[],"name":"ValueNotChanged","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"CancelledUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint32","name":"previousConfigBlockNumber","type":"uint32"},{"indexed":false,"internalType":"bytes32","name":"configDigest","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"configCount","type":"uint64"},{"indexed":false,"internalType":"address[]","name":"signers","type":"address[]"},{"indexed":false,"internalType":"address[]","name":"transmitters","type":"address[]"},{"indexed":false,"internalType":"uint8","name":"f","type":"uint8"},{"indexed":false,"internalType":"bytes","name":"onchainConfig","type":"bytes"},{"indexed":false,"internalType":"uint64","name":"offchainConfigVersion","type":"uint64"},{"indexed":false,"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"ConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":false,"internalType":"uint96","name":"amount","type":"uint96"}],"name":"FundsAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"address","name":"to","type":"address"}],"name":"FundsWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"InsufficientFundsUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint96","name":"amount","type":"uint96"}],"name":"OwnerFundsWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address[]","name":"transmitters","type":"address[]"},{"indexed":false,"internalType":"address[]","name":"payees","type":"address[]"}],"name":"PayeesUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"transmitter","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"PayeeshipTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"transmitter","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"PayeeshipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"transmitter","type":"address"},{"indexed":true,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"address","name":"payee","type":"address"}],"name":"PaymentWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"ReorgedUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"StaleUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"configDigest","type":"bytes32"},{"indexed":false,"internalType":"uint32","name":"epoch","type":"uint32"}],"name":"Transmitted","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"UpkeepAdminTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"UpkeepAdminTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"uint64","name":"atBlockHeight","type":"uint64"}],"name":"UpkeepCanceled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint96","name":"gasLimit","type":"uint96"}],"name":"UpkeepGasLimitSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"remainingBalance","type":"uint256"},{"indexed":false,"internalType":"address","name":"destination","type":"address"}],"name":"UpkeepMigrated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"UpkeepOffchainConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"UpkeepPaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"bool","name":"success","type":"bool"},{"indexed":false,"internalType":"uint96","name":"totalPayment","type":"uint96"},{"indexed":false,"internalType":"uint256","name":"gasUsed","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasOverhead","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"UpkeepPerformed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"newPipelineData","type":"bytes"}],"name":"UpkeepPipelineDataSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"privilegeConfig","type":"bytes"}],"name":"UpkeepPrivilegeConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"startingBalance","type":"uint256"},{"indexed":false,"internalType":"address","name":"importedFrom","type":"address"}],"name":"UpkeepReceived","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint32","name":"executeGas","type":"uint32"},{"indexed":false,"internalType":"address","name":"admin","type":"address"}],"name":"UpkeepRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"triggerConfig","type":"bytes"}],"name":"UpkeepTriggerConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"UpkeepUnpaused","type":"event"},{"stateMutability":"nonpayable","type":"fallback"},{"inputs":[],"name":"acceptOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"fallbackTo","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getFastGasFeedAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getLinkAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getLinkNativeFeedAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMode","outputs":[{"internalType":"enum KeeperRegistryBase2_1.Mode","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getTriggerType","outputs":[{"internalType":"enum KeeperRegistryBase2_1.Trigger","name":"","type":"uint8"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"latestConfigDetails","outputs":[{"internalType":"uint32","name":"configCount","type":"uint32"},{"internalType":"uint32","name":"blockNumber","type":"uint32"},{"internalType":"bytes32","name":"configDigest","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestConfigDigestAndEpoch","outputs":[{"internalType":"bool","name":"scanLogs","type":"bool"},{"internalType":"bytes32","name":"configDigest","type":"bytes32"},{"internalType":"uint32","name":"epoch","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"onTokenTransfer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"signers","type":"address[]"},{"internalType":"address[]","name":"transmitters","type":"address[]"},{"internalType":"uint8","name":"f","type":"uint8"},{"internalType":"bytes","name":"onchainConfigBytes","type":"bytes"},{"internalType":"uint64","name":"offchainConfigVersion","type":"uint64"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"setConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"performData","type":"bytes"}],"name":"simulatePerformUpkeep","outputs":[{"internalType":"bool","name":"success","type":"bool"},{"internalType":"uint256","name":"gasUsed","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32[3]","name":"reportContext","type":"bytes32[3]"},{"internalType":"bytes","name":"rawReport","type":"bytes"},{"internalType":"bytes32[]","name":"rs","type":"bytes32[]"},{"internalType":"bytes32[]","name":"ss","type":"bytes32[]"},{"internalType":"bytes32","name":"rawVs","type":"bytes32"}],"name":"transmit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"typeAndVersion","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract KeeperRegistryLogicB2_1","name":"logicB","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint96","name":"amount","type":"uint96"}],"name":"addFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"cancelUpkeep","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes[]","name":"values","type":"bytes[]"},{"internalType":"bytes","name":"extraData","type":"bytes"}],"name":"checkCallback","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"checkData","type":"bytes"}],"name":"checkUpkeep","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"},{"internalType":"uint256","name":"gasLimit","type":"uint256"},{"internalType":"uint256","name":"fastGasWei","type":"uint256"},{"internalType":"uint256","name":"linkNative","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"checkUpkeep","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"},{"internalType":"uint256","name":"gasLimit","type":"uint256"},{"internalType":"uint256","name":"fastGasWei","type":"uint256"},{"internalType":"uint256","name":"linkNative","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"payload","type":"bytes"}],"name":"executeCallback","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"internalType":"address","name":"destination","type":"address"}],"name":"migrateUpkeeps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes","name":"encodedUpkeeps","type":"bytes"}],"name":"receiveUpkeeps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint32","name":"gasLimit","type":"uint32"},{"internalType":"address","name":"admin","type":"address"},{"internalType":"enum KeeperRegistryBase2_1.Trigger","name":"triggerType","type":"uint8"},{"internalType":"bytes","name":"checkData","type":"bytes"},{"internalType":"bytes","name":"triggerConfig","type":"bytes"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"registerUpkeep","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint32","name":"gasLimit","type":"uint32"},{"internalType":"address","name":"admin","type":"address"},{"internalType":"bytes","name":"checkData","type":"bytes"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"registerUpkeep","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"triggerConfig","type":"bytes"}],"name":"setUpkeepTriggerConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"upkeepTranscoderVersion","outputs":[{"internalType":"enum UpkeepFormat","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"upkeepVersion","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"enum KeeperRegistryBase2_1.Mode","name":"mode","type":"uint8"},{"internalType":"address","name":"link","type":"address"},{"internalType":"address","name":"linkNativeFeed","type":"address"},{"internalType":"address","name":"fastGasFeed","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"address","name":"transmitter","type":"address"}],"name":"acceptPayeeship","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"acceptUpkeepAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"startIndex","type":"uint256"},{"internalType":"uint256","name":"endIndex","type":"uint256"}],"name":"getActiveUpkeepIDs","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"startIndex","type":"uint256"},{"internalType":"uint256","name":"endIndex","type":"uint256"},{"internalType":"enum KeeperRegistryBase2_1.Trigger","name":"trigger","type":"uint8"}],"name":"getActiveUpkeepIDsByType","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getBlockTriggerConfig","outputs":[{"components":[{"internalType":"uint32","name":"checkCadance","type":"uint32"}],"internalType":"struct KeeperRegistryBase2_1.BlockTriggerConfig","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getLogTriggerConfig","outputs":[{"components":[{"internalType":"address","name":"contractAddress","type":"address"},{"internalType":"uint8","name":"filterSelector","type":"uint8"},{"internalType":"bytes32","name":"topic0","type":"bytes32"},{"internalType":"bytes32","name":"topic1","type":"bytes32"},{"internalType":"bytes32","name":"topic2","type":"bytes32"},{"internalType":"bytes32","name":"topic3","type":"bytes32"}],"internalType":"struct KeeperRegistryBase2_1.LogTriggerConfig","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"enum KeeperRegistryBase2_1.Trigger","name":"triggerType","type":"uint8"},{"internalType":"uint32","name":"gasLimit","type":"uint32"}],"name":"getMaxPaymentForGas","outputs":[{"internalType":"uint96","name":"maxPayment","type":"uint96"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getMinBalanceForUpkeep","outputs":[{"internalType":"uint96","name":"minBalance","type":"uint96"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"peer","type":"address"}],"name":"getPeerRegistryMigrationPermission","outputs":[{"internalType":"enum KeeperRegistryBase2_1.MigrationPermission","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"query","type":"address"}],"name":"getSignerInfo","outputs":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint8","name":"index","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getState","outputs":[{"components":[{"internalType":"uint32","name":"nonce","type":"uint32"},{"internalType":"uint96","name":"ownerLinkBalance","type":"uint96"},{"internalType":"uint256","name":"expectedLinkBalance","type":"uint256"},{"internalType":"uint96","name":"totalPremium","type":"uint96"},{"internalType":"uint256","name":"numUpkeeps","type":"uint256"},{"internalType":"uint32","name":"configCount","type":"uint32"},{"internalType":"uint32","name":"latestConfigBlockNumber","type":"uint32"},{"internalType":"bytes32","name":"latestConfigDigest","type":"bytes32"},{"internalType":"uint32","name":"latestEpoch","type":"uint32"},{"internalType":"bool","name":"paused","type":"bool"}],"internalType":"struct KeeperRegistryBase2_1.State","name":"state","type":"tuple"},{"components":[{"internalType":"uint32","name":"paymentPremiumPPB","type":"uint32"},{"internalType":"uint32","name":"flatFeeMicroLink","type":"uint32"},{"internalType":"uint32","name":"checkGasLimit","type":"uint32"},{"internalType":"uint24","name":"stalenessSeconds","type":"uint24"},{"internalType":"uint16","name":"gasCeilingMultiplier","type":"uint16"},{"internalType":"uint96","name":"minUpkeepSpend","type":"uint96"},{"internalType":"uint32","name":"maxPerformGas","type":"uint32"},{"internalType":"uint32","name":"maxCheckDataSize","type":"uint32"},{"internalType":"uint32","name":"maxPerformDataSize","type":"uint32"},{"internalType":"uint256","name":"fallbackGasPrice","type":"uint256"},{"internalType":"uint256","name":"fallbackLinkPrice","type":"uint256"},{"internalType":"address","name":"transcoder","type":"address"},{"internalType":"address[]","name":"registrars","type":"address[]"},{"internalType":"address","name":"upkeepPrivilegeManager","type":"address"}],"internalType":"struct KeeperRegistryBase2_1.OnchainConfig","name":"config","type":"tuple"},{"internalType":"address[]","name":"signers","type":"address[]"},{"internalType":"address[]","name":"transmitters","type":"address[]"},{"internalType":"uint8","name":"f","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"query","type":"address"}],"name":"getTransmitterInfo","outputs":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint8","name":"index","type":"uint8"},{"internalType":"uint96","name":"balance","type":"uint96"},{"internalType":"uint96","name":"lastCollected","type":"uint96"},{"internalType":"address","name":"payee","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getUpkeep","outputs":[{"components":[{"internalType":"address","name":"target","type":"address"},{"internalType":"address","name":"forwarder","type":"address"},{"internalType":"uint32","name":"executeGas","type":"uint32"},{"internalType":"bytes","name":"checkData","type":"bytes"},{"internalType":"uint96","name":"balance","type":"uint96"},{"internalType":"address","name":"admin","type":"address"},{"internalType":"uint64","name":"maxValidBlocknumber","type":"uint64"},{"internalType":"uint32","name":"lastPerformedBlockNumber","type":"uint32"},{"internalType":"uint96","name":"amountSpent","type":"uint96"},{"internalType":"bool","name":"paused","type":"bool"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"internalType":"struct KeeperRegistryBase2_1.UpkeepInfo","name":"upkeepInfo","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getUpkeepPrivilegeConfig","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getUpkeepTriggerConfig","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"pauseUpkeep","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"recoverFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"payees","type":"address[]"}],"name":"setPayees","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"peer","type":"address"},{"internalType":"enum KeeperRegistryBase2_1.MigrationPermission","name":"permission","type":"uint8"}],"name":"setPeerRegistryMigrationPermission","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint32","name":"gasLimit","type":"uint32"}],"name":"setUpkeepGasLimit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"config","type":"bytes"}],"name":"setUpkeepOffchainConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"newPipelineData","type":"bytes"}],"name":"setUpkeepPipelineData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"},{"internalType":"bytes","name":"newPrivilegeConfig","type":"bytes"}],"name":"setUpkeepPrivilegeConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"transmitter","type":"address"},{"internalType":"address","name":"proposed","type":"address"}],"name":"transferPayeeship","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"proposed","type":"address"}],"name":"transferUpkeepAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"unpauseUpkeep","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"to","type":"address"}],"name":"withdrawFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawOwnerFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"}],"name":"withdrawPayment","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Log {
  uint256 index;
  uint256 txIndex;
  bytes32 txHash;
  uint256 blockNumber;
  bytes32 blockHash;
  address source;
  bytes32[] topics;
  bytes data;
}

interface ILogAutomation {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param log the raw log data matching the filter that this contract has
   * registered as a trigger
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkLog(Log calldata log) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ILogAutomation, Log} from "../2_1/interfaces/ILogAutomation.sol";
import "../2_1/interfaces/FeedLookupCompatibleInterface.sol";
import {ArbSys} from "../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "../../../automation/2_0/KeeperRegistrar2_0.sol";
import "../../../tests/VerifiableLoadBase.sol";

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @return verifierResponse The encoded response from the verifier.
   */
  function verify(bytes memory signedReport) external returns (bytes memory verifierResponse);
}

contract LogTriggeredFeedLookup is ILogAutomation, FeedLookupCompatibleInterface {
  event TriggerMercury(uint256 indexed upkeepId, uint256 indexed logBlockNumber); // keccak256(TriggerMercury(uint256,uint256)) => 0xcd89a1cdede3e128a8e92d77495b16cc12f0fc7564a712113f006adaf640a4a6
  event DoNotTriggerMercury(uint256 indexed bn, uint256 indexed ts); // keccak256(DoNotTriggerMercury(uint256,uint256)) => 0x3338104ccab396f091b767e17a2a863f70d777261982306eeb72053c94b9cd47
  event PerformingLogTriggerUpkeep(
    address indexed from,
    uint256 upkeepId,
    uint256 counter,
    uint256 logBlockNumber,
    uint256 blockNumber,
    bytes blob,
    bytes verified
  );

  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);
  IVerifierProxy internal constant VERIFIER = IVerifierProxy(0xa4D813064dc6E2eFfaCe02a060324626d4C5667f);

  // for log trigger
  bytes32 constant triggerSig = 0xcd89a1cdede3e128a8e92d77495b16cc12f0fc7564a712113f006adaf640a4a6;
  bytes32 constant NoTriggerSig = 0x3338104ccab396f091b767e17a2a863f70d777261982306eeb72053c94b9cd47;

  // for mercury config
  string[] public feedsHex = ["0x4554482d5553442d415242495452554d2d544553544e45540000000000000000"];
  string public constant feedParamKey = "feedIDHex";
  string public constant timeParamKey = "blockNumber";

  uint256 public testRange;
  uint256 public interval;
  uint256 public previousPerformBlock;
  uint256 public initialBlock;
  uint256 public counter;
  bool public useArbitrumBlockNum;

  constructor(uint256 _testRange, uint256 _interval, bool _useArbitrumBlockNum) {
    testRange = _testRange;
    interval = _interval;
    useArbitrumBlockNum = _useArbitrumBlockNum;
    previousPerformBlock = 0;
    initialBlock = 0;
    counter = 0;
  }

  function registerUpkeep() external returns (bytes memory logTrigger) {
    KeeperRegistryBase2_1.LogTriggerConfig memory cfg = KeeperRegistryBase2_1.LogTriggerConfig({
      contractAddress: address(this),
      filterSelector: 0, // not applying any filter, if 1, it will check topic1, if 3, it will check both topic1 and topic2, if 5, it will check both topic1 and topic3
      topic0: triggerSig, // only triggerSig will be available at `checkLog` this will always apply
      topic1: 0x000000000000000000000000000000000000000000000000000000000000000,
      topic2: 0x000000000000000000000000000000000000000000000000000000000000000,
      topic3: 0x000000000000000000000000000000000000000000000000000000000000000
    });
    bytes memory logTriggerConfig = abi.encode(cfg);

    return logTriggerConfig;
  }

  function startLogs(uint256 upkeepId) external {
    uint256 blockNumber = getBlockNumber();
    emit TriggerMercury(upkeepId, blockNumber);
    emit DoNotTriggerMercury(blockNumber, block.timestamp);
  }

  function setFeedsHex(string[] memory newFeeds) external {
    feedsHex = newFeeds;
  }

  function checkLog(Log calldata log) external override returns (bool upkeepNeeded, bytes memory performData) {
    uint256 blockNum = getBlockNumber();

    // filter by event signature
    if (log.topics[0] == triggerSig) {
      // filter by indexed parameters
      bytes memory p1 = abi.encodePacked(log.topics[1]); // bytes32 to bytes
      uint256 upkeepId = abi.decode(p1, (uint256));
      bytes memory p2 = abi.encodePacked(log.topics[2]);
      uint256 logBlockNumber = abi.decode(p2, (uint256));

      bool needed = eligible();
      if (needed) {
        revert FeedLookup(feedParamKey, feedsHex, timeParamKey, blockNum, abi.encodePacked(upkeepId, logBlockNumber));
      }
      revert("upkeep not needed");
    }
    revert("could not find matching event sig");
  }

  function performUpkeep(bytes calldata performData) external override {
    uint256 blockNumber = getBlockNumber();
    if (initialBlock == 0) {
      initialBlock = blockNumber;
    }
    counter = counter + 1;
    previousPerformBlock = blockNumber;

    (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
    (uint256 upkeepId, uint256 logBlockNumber) = abi.decode(extraData, (uint256, uint256));

    bytes memory verifiedResponse = VERIFIER.verify(values[0]);

    emit PerformingLogTriggerUpkeep(tx.origin, upkeepId, counter, logBlockNumber, blockNumber, values[0], verifiedResponse);
  }

  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view override returns (bool upkeepNeeded, bytes memory performData) {
    // do sth about the chainlinkBlob data in values and extraData
    bytes memory performData = abi.encode(values, extraData);
    return (true, performData);
  }

  function getBlockNumber() internal view returns (uint256) {
    if (useArbitrumBlockNum) {
      return ARB_SYS.arbBlockNumber();
    } else {
      return block.number;
    }
  }

  function eligible() public view returns (bool) {
    if (initialBlock == 0) {
      return true;
    }

    uint256 blockNumber = getBlockNumber();
    return (blockNumber - initialBlock) < testRange && (blockNumber - previousPerformBlock) >= interval;
  }

  function setSpread(uint256 _testRange, uint256 _interval) external {
    testRange = _testRange;
    interval = _interval;
    initialBlock = 0;
    counter = 0;
  }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct OnchainConfig {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint32 maxCheckDataSize;
  uint32 maxPerformDataSize;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint96 totalPremium;
  uint256 numUpkeeps;
  uint32 configCount;
  uint32 latestConfigBlockNumber;
  bytes32 latestConfigDigest;
  uint32 latestEpoch;
  bool paused;
}

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
  address target;
  uint32 executeGas;
  bytes checkData;
  uint96 balance;
  address admin;
  uint64 maxValidBlocknumber;
  uint32 lastPerformBlockNumber;
  uint96 amountSpent;
  bool paused;
  bytes offchainConfig;
}

enum UpkeepFailureReason {
  NONE,
  UPKEEP_CANCELLED,
  UPKEEP_PAUSED,
  TARGET_CHECK_REVERTED,
  UPKEEP_NOT_NEEDED,
  PERFORM_DATA_EXCEEDS_LIMIT,
  INSUFFICIENT_BALANCE
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external;

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getTransmitterInfo(
    address query
  ) external view returns (bool active, uint8 index, uint96 balance, uint96 lastCollected, address payee);

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId
  )
    external
    view
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ERC677ReceiverInterface {
  function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../automation/2_0/KeeperRegistrar2_0.sol";
import "../dev/automation/2_1/interfaces/IKeeperRegistryMaster.sol";
import {ArbSys} from "../dev/vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

abstract contract VerifiableLoadBase is ConfirmedOwner {
  error IndexOutOfRange();

  event UpkeepsRegistered(uint256[] upkeepIds);
  event UpkeepsCancelled(uint256[] upkeepIds);
  event RegistrarSet(address newRegistrar);
  event FundsAdded(uint256 upkeepId, uint96 amount);
  event UpkeepTopUp(uint256 upkeepId, uint96 amount, uint256 blockNum);
  event InsufficientFunds(uint256 balance, uint256 blockNum);
  event Received(address sender, uint256 value);
  event PerformingUpkeep(uint256 firstPerformBlock, uint256 lastBlock, uint256 previousBlock, uint256 counter);

  using EnumerableSet for EnumerableSet.UintSet;
  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);

  mapping(uint256 => uint256) public lastTopUpBlocks;
  mapping(uint256 => uint256) public intervals;
  mapping(uint256 => uint256) public previousPerformBlocks;
  mapping(uint256 => uint256) public firstPerformBlocks;
  mapping(uint256 => uint256) public counters;
  mapping(uint256 => uint256) public performGasToBurns;
  mapping(uint256 => uint256) public checkGasToBurns;
  mapping(uint256 => uint256) public performDataSizes;
  mapping(uint256 => uint256) public gasLimits;
  mapping(uint256 => bytes) public checkDatas;
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup
  mapping(uint256 => uint256[]) public delays; // how to query for delays for a certain past period: calendar day and/or past 24 hours

  mapping(uint256 => mapping(uint16 => uint256[])) public bucketedDelays;
  mapping(uint256 => mapping(uint16 => uint256[])) public timestampDelays;
  mapping(uint256 => uint256[]) public timestamps;
  mapping(uint256 => uint16) public timestampBuckets;
  mapping(uint256 => uint16) public buckets;
  EnumerableSet.UintSet internal s_upkeepIDs;
  KeeperRegistrar2_0 public registrar;
  LinkTokenInterface public linkToken;
  IKeeperRegistryMaster public registry;
  // check if an upkeep is eligible for adding funds at this interval
  uint256 public upkeepTopUpCheckInterval = 5;
  // an upkeep will get this amount of LINK for every top up
  uint96 public addLinkAmount = 200000000000000000; // 0.2 LINK
  // if an upkeep's balance is less than this threshold * min balance, this upkeep is eligible for adding funds
  uint8 public minBalanceThresholdMultiplier = 20;
  // if this contract is using arbitrum block number
  bool public immutable useArbitrumBlockNum;

  // the following fields are immutable bc if they are adjusted, the existing upkeeps' delays will be stored in
  // different sizes of buckets. it's better to redeploy this contract with new values.
  uint16 public immutable BUCKET_SIZE = 100;
  uint16 public immutable TIMESTAMP_INTERVAL = 3600;

  /**
   * @param registrarAddress a registrar address
   * @param useArb if this contract will use arbitrum block number
   */
  constructor(address registrarAddress, bool useArb) ConfirmedOwner(msg.sender) {
    registrar = KeeperRegistrar2_0(registrarAddress);
    (, , , address registryAddress, ) = registrar.getRegistrationConfig();
    registry = IKeeperRegistryMaster(payable(address(registryAddress)));
    linkToken = registrar.LINK();
    useArbitrumBlockNum = useArb;
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /**
   * @notice withdraws LINKs from this contract to msg sender when testing is finished.
   */
  function withdrawLinks() external onlyOwner {
    uint256 balance = linkToken.balanceOf(address(this));
    linkToken.transfer(msg.sender, balance);
  }

  function getBlockNumber() internal view returns (uint256) {
    if (useArbitrumBlockNum) {
      return ARB_SYS.arbBlockNumber();
    } else {
      return block.number;
    }
  }

  /**
   * @notice sets registrar, registry, and link token address.
   * @param newRegistrar the new registrar address
   */
  function setConfig(KeeperRegistrar2_0 newRegistrar) external {
    registrar = newRegistrar;
    (, , , address registryAddress, ) = registrar.getRegistrationConfig();
    registry = IKeeperRegistryMaster(payable(address(registryAddress)));
    linkToken = registrar.LINK();

    emit RegistrarSet(address(registrar));
  }

  /**
   * @notice gets an array of active upkeep IDs.
   * @param startIndex the start index of upkeep IDs
   * @param maxCount the max number of upkeep IDs requested
   * @return an array of active upkeep IDs
   */
  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory) {
    uint256 maxIdx = s_upkeepIDs.length();
    if (startIndex >= maxIdx) revert IndexOutOfRange();
    if (maxCount == 0) {
      maxCount = maxIdx - startIndex;
    }
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      ids[idx] = s_upkeepIDs.at(startIndex + idx);
    }
    return ids;
  }

  /**
   * @notice register an upkeep via the registrar.
   * @param params a registration params struct
   * @return an upkeep ID
   */
  function _registerUpkeep(KeeperRegistrar2_0.RegistrationParams memory params) private returns (uint256) {
    uint256 upkeepId = registrar.registerUpkeep(params);
    s_upkeepIDs.add(upkeepId);
    gasLimits[upkeepId] = params.gasLimit;
    checkDatas[upkeepId] = params.checkData;
    return upkeepId;
  }

  /**
   * @notice batch registering upkeeps.
   * @param number the number of upkeeps to be registered
   * @param gasLimit the gas limit of each upkeep
   * @param amount the amount of LINK to fund each upkeep
   * @param checkGasToBurn the amount of check gas to burn
   * @param performGasToBurn the amount of perform gas to burn
   */
  function batchRegisterUpkeeps(
    uint8 number,
    uint32 gasLimit,
    uint96 amount,
    uint256 checkGasToBurn,
    uint256 performGasToBurn
  ) external {
    KeeperRegistrar2_0.RegistrationParams memory params = KeeperRegistrar2_0.RegistrationParams({
      name: "test",
      encryptedEmail: bytes(""),
      upkeepContract: address(this),
      gasLimit: gasLimit,
      adminAddress: address(this), // use address of this contract as the admin
      checkData: bytes(""), // update pipeline data later bc upkeep id is not available now
      offchainConfig: bytes(""),
      amount: amount
    });

    linkToken.approve(address(registrar), amount * number);

    uint256[] memory upkeepIds = new uint256[](number);
    for (uint8 i = 0; i < number; i++) {
      uint256 upkeepId = _registerUpkeep(params);
      upkeepIds[i] = upkeepId;
      checkGasToBurns[upkeepId] = checkGasToBurn;
      performGasToBurns[upkeepId] = performGasToBurn;
    }
    emit UpkeepsRegistered(upkeepIds);
  }

  /**
   * @notice adds fund for an upkeep.
   * @param upkeepId the upkeep ID
   * @param amount the amount of LINK to be funded for the upkeep
   */
  function addFunds(uint256 upkeepId, uint96 amount) external {
    linkToken.approve(address(registry), amount);
    registry.addFunds(upkeepId, amount);
    emit FundsAdded(upkeepId, amount);
  }

  /**
   * @notice updates pipeline data for an upkeep. In order for the upkeep to be performed, the pipeline data must be the abi encoded upkeep ID.
   * @param upkeepId the upkeep ID
   * @param pipelineData the new pipeline data for the upkeep
   */
  function updateUpkeepPipelineData(uint256 upkeepId, bytes calldata pipelineData) external {
    registry.setUpkeepPipelineData(upkeepId, pipelineData);
    checkDatas[upkeepId] = pipelineData;
  }

  function withdrawLinks(uint256 upkeepId) external {
    registry.withdrawFunds(upkeepId, address(this));
  }

  function batchWithdrawLinks(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint32 i = 0; i < len; i++) {
      this.withdrawLinks(upkeepIds[i]);
    }
  }

  /**
   * @notice cancel an upkeep.
   * @param upkeepId the upkeep ID
   */
  function cancelUpkeep(uint256 upkeepId) external {
    registry.cancelUpkeep(upkeepId);
    s_upkeepIDs.remove(upkeepId);
  }

  /**
   * @notice batch canceling upkeeps.
   * @param upkeepIds an array of upkeep IDs
   */
  function batchCancelUpkeeps(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint8 i = 0; i < len; i++) {
      this.cancelUpkeep(upkeepIds[i]);
    }
    emit UpkeepsCancelled(upkeepIds);
  }

  function eligible(uint256 upkeepId) public view returns (bool) {
    if (firstPerformBlocks[upkeepId] == 0) {
      return true;
    }
    return (getBlockNumber() - previousPerformBlocks[upkeepId]) >= intervals[upkeepId];
  }

  /**
   * @notice set a new add LINK amount.
   * @param amount the new value
   */
  function setAddLinkAmount(uint96 amount) external {
    addLinkAmount = amount;
  }

  function setUpkeepTopUpCheckInterval(uint256 newInterval) external {
    upkeepTopUpCheckInterval = newInterval;
  }

  function setMinBalanceThresholdMultiplier(uint8 newMinBalanceThresholdMultiplier) external {
    minBalanceThresholdMultiplier = newMinBalanceThresholdMultiplier;
  }

  function setPerformGasToBurn(uint256 upkeepId, uint256 value) public {
    performGasToBurns[upkeepId] = value;
  }

  function setCheckGasToBurn(uint256 upkeepId, uint256 value) public {
    checkGasToBurns[upkeepId] = value;
  }

  function setPerformDataSize(uint256 upkeepId, uint256 value) public {
    performDataSizes[upkeepId] = value;
  }

  function setUpkeepGasLimit(uint256 upkeepId, uint32 gasLimit) public {
    registry.setUpkeepGasLimit(upkeepId, gasLimit);
    gasLimits[upkeepId] = gasLimit;
  }

  function setInterval(uint256 upkeepId, uint256 _interval) external {
    intervals[upkeepId] = _interval;
    firstPerformBlocks[upkeepId] = 0;
    counters[upkeepId] = 0;

    delete delays[upkeepId];
    uint16 currentBucket = buckets[upkeepId];
    for (uint16 i = 0; i <= currentBucket; i++) {
      delete bucketedDelays[upkeepId][i];
    }
    delete buckets[upkeepId];

    currentBucket = timestampBuckets[upkeepId];
    for (uint16 i = 0; i <= currentBucket; i++) {
      delete timestampDelays[upkeepId][i];
    }
    delete timestamps[upkeepId];
    delete timestampBuckets[upkeepId];
  }

  /**
   * @notice batch setting intervals for an array of upkeeps.
   * @param upkeepIds an array of upkeep IDs
   * @param interval a new interval
   */
  function batchSetIntervals(uint256[] calldata upkeepIds, uint32 interval) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      this.setInterval(upkeepIds[i], interval);
    }
  }

  /**
   * @notice batch updating pipeline data for all upkeeps.
   * @param upkeepIds an array of upkeep IDs
   */
  function batchUpdatePipelineData(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 upkeepId = upkeepIds[i];
      this.updateUpkeepPipelineData(upkeepId, abi.encode(upkeepId));
    }
  }

  function getDelaysLength(uint256 upkeepId) public view returns (uint256) {
    return delays[upkeepId].length;
  }

  function getDelaysLengthAtBucket(uint256 upkeepId, uint16 bucket) public view returns (uint256) {
    return bucketedDelays[upkeepId][bucket].length;
  }

  function getDelaysLengthAtTimestampBucket(uint256 upkeepId, uint16 timestampBucket) public view returns (uint256) {
    return timestampDelays[upkeepId][timestampBucket].length;
  }

  function getBucketedDelaysLength(uint256 upkeepId) public view returns (uint256) {
    uint16 currentBucket = buckets[upkeepId];
    uint256 len = 0;
    for (uint16 i = 0; i <= currentBucket; i++) {
      len += bucketedDelays[upkeepId][i].length;
    }
    return len;
  }

  function getTimestampBucketedDelaysLength(uint256 upkeepId) public view returns (uint256) {
    uint16 timestampBucket = timestampBuckets[upkeepId];
    uint256 len = 0;
    for (uint16 i = 0; i <= timestampBucket; i++) {
      len += timestampDelays[upkeepId][i].length;
    }
    return len;
  }

  function getDelays(uint256 upkeepId) public view returns (uint256[] memory) {
    return delays[upkeepId];
  }

  function getTimestampDelays(uint256 upkeepId, uint16 timestampBucket) public view returns (uint256[] memory) {
    return timestampDelays[upkeepId][timestampBucket];
  }

  function getBucketedDelays(uint256 upkeepId, uint16 bucket) public view returns (uint256[] memory) {
    return bucketedDelays[upkeepId][bucket];
  }

  function getSumDelayLastNPerforms(uint256 upkeepId, uint256 n) public view returns (uint256, uint256) {
    uint256[] memory delays = delays[upkeepId];
    return getSumDelayLastNPerforms(delays, n);
  }

  function getSumBucketedDelayLastNPerforms(uint256 upkeepId, uint256 n) public view returns (uint256, uint256) {
    uint256 len = this.getBucketedDelaysLength(upkeepId);
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 nn = n;
    uint256 sum = 0;
    uint16 currentBucket = buckets[upkeepId];
    for (uint16 i = currentBucket; i >= 0; i--) {
      uint256[] memory delays = bucketedDelays[upkeepId][i];
      (uint256 s, uint256 m) = getSumDelayLastNPerforms(delays, nn);
      sum += s;
      nn -= m;
      if (nn <= 0) {
        break;
      }
    }
    return (sum, n);
  }

  function getSumTimestampBucketedDelayLastNPerforms(
    uint256 upkeepId,
    uint256 n
  ) public view returns (uint256, uint256) {
    uint256 len = this.getTimestampBucketedDelaysLength(upkeepId);
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 nn = n;
    uint256 sum = 0;
    uint16 timestampBucket = timestampBuckets[upkeepId];
    for (uint16 i = timestampBucket; i >= 0; i--) {
      uint256[] memory delays = timestampDelays[upkeepId][i];
      (uint256 s, uint256 m) = getSumDelayLastNPerforms(delays, nn);
      sum += s;
      nn -= m;
      if (nn <= 0) {
        break;
      }
    }
    return (sum, n);
  }

  function getSumDelayInBucket(uint256 upkeepId, uint16 bucket) public view returns (uint256, uint256) {
    uint256[] memory delays = bucketedDelays[upkeepId][bucket];
    return getSumDelayLastNPerforms(delays, delays.length);
  }

  function getSumDelayInTimestampBucket(
    uint256 upkeepId,
    uint16 timestampBucket
  ) public view returns (uint256, uint256) {
    uint256[] memory delays = timestampDelays[upkeepId][timestampBucket];
    return getSumDelayLastNPerforms(delays, delays.length);
  }

  function getSumDelayLastNPerforms(uint256[] memory delays, uint256 n) internal view returns (uint256, uint256) {
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 sum = 0;

    for (i = 0; i < n; i++) sum = sum + delays[len - i - 1];
    return (sum, n);
  }

  function getPxDelayForAllUpkeeps(uint256 p) public view returns (uint256[] memory, uint256[] memory) {
    uint256 len = s_upkeepIDs.length();
    uint256[] memory upkeepIds = new uint256[](len);
    uint256[] memory pxDelays = new uint256[](len);

    for (uint256 idx = 0; idx < len; idx++) {
      uint256 upkeepId = s_upkeepIDs.at(idx);
      uint256[] memory delays = delays[upkeepId];
      upkeepIds[idx] = upkeepId;
      pxDelays[idx] = getPxDelayLastNPerforms(delays, p, delays.length);
    }

    return (upkeepIds, pxDelays);
  }

  function getPxBucketedDelaysForAllUpkeeps(uint256 p) public view returns (uint256[] memory, uint256[] memory) {
    uint256 len = s_upkeepIDs.length();
    uint256[] memory upkeepIds = new uint256[](len);
    uint256[] memory pxDelays = new uint256[](len);

    for (uint256 idx = 0; idx < len; idx++) {
      uint256 upkeepId = s_upkeepIDs.at(idx);
      upkeepIds[idx] = upkeepId;
      uint16 currentBucket = buckets[upkeepId];
      uint256 delayLen = this.getBucketedDelaysLength(upkeepId);
      uint256[] memory delays = new uint256[](delayLen);
      uint256 i = 0;
      mapping(uint16 => uint256[]) storage bucketedDelays = bucketedDelays[upkeepId];
      for (uint16 j = 0; j <= currentBucket; j++) {
        uint256[] memory d = bucketedDelays[j];
        for (uint256 k = 0; k < d.length; k++) {
          delays[i++] = d[k];
        }
      }
      pxDelays[idx] = getPxDelayLastNPerforms(delays, p, delayLen);
    }

    return (upkeepIds, pxDelays);
  }

  function getPxDelayInTimestampBucket(
    uint256 upkeepId,
    uint256 p,
    uint16 timestampBucket
  ) public view returns (uint256) {
    uint256[] memory delays = timestampDelays[upkeepId][timestampBucket];
    return getPxDelayLastNPerforms(delays, p, delays.length);
  }

  function getPxDelayInBucket(uint256 upkeepId, uint256 p, uint16 bucket) public view returns (uint256) {
    uint256[] memory delays = bucketedDelays[upkeepId][bucket];
    return getPxDelayLastNPerforms(delays, p, delays.length);
  }

  function getPxDelayLastNPerforms(uint256 upkeepId, uint256 p, uint256 n) public view returns (uint256) {
    return getPxDelayLastNPerforms(delays[upkeepId], p, n);
  }

  function getPxDelayLastNPerforms(uint256[] memory delays, uint256 p, uint256 n) internal view returns (uint256) {
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256[] memory subArr = new uint256[](n);

    for (i = 0; i < n; i++) subArr[i] = (delays[len - i - 1]);
    quickSort(subArr, int256(0), int256(subArr.length - 1));

    if (p == 100) {
      return subArr[subArr.length - 1];
    }
    return subArr[(p * subArr.length) / 100];
  }

  function quickSort(uint256[] memory arr, int256 left, int256 right) private pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint256(i)] < pivot) i++;
      while (pivot < arr[uint256(j)]) j--;
      if (i <= j) {
        (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) quickSort(arr, left, j);
    if (i < right) quickSort(arr, i, right);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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