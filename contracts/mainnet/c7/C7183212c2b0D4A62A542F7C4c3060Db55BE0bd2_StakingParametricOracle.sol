// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';

import '@dsla-protocol/core/contracts/interfaces/IMessenger.sol';
import '@dsla-protocol/core/contracts/SLA.sol';
import '@dsla-protocol/core/contracts/PeriodRegistry.sol';
import '@dsla-protocol/core/contracts/libraries/StringUtils.sol';
import '@dsla-protocol/core/contracts/StakeRegistry.sol';

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract StakingParametricOracle is
    ChainlinkClient,
    IMessenger,
    ReentrancyGuard
{
    using SafeERC20 for ERC20;
    using Chainlink for Chainlink.Request;

    mapping(bytes32 => SLIRequest) public requestIdToSLIRequest;
    bytes32[] public requests;
    address private _slaRegistryAddress;
    address private immutable _oracle;
    bytes32 private _jobId;
    uint256 private constant _baseFee = 0.1 ether;
    uint256 private _fee;
    uint256 private constant _messengerPrecision = 10**3;

    uint256 private _requestsCounter;
    uint256 private _fulfillsCounter;
    PeriodRegistry private periodRegistry;
    StakeRegistry private stakeRegistry;
    bool private retry = false;
    bytes32 public networkName;

    string public override lpName;
    string public override lpSymbol;

    string public override spName;
    string public override spSymbol;

    constructor(
        address _messengerChainlinkOracle,
        address _messengerChainlinkToken,
        uint256 _feeMultiplier,
        PeriodRegistry _periodRegistry,
        StakeRegistry _stakeRegistry,
        bytes32 _networkName,
        string memory _lpName,
        string memory _lpSymbol,
        string memory _spName,
        string memory _spSymbol
    ) {
        setChainlinkToken(_messengerChainlinkToken);
        _oracle = _messengerChainlinkOracle;
        _fee = _feeMultiplier * _baseFee;
        periodRegistry = _periodRegistry;
        stakeRegistry = _stakeRegistry;
        networkName = _networkName;
        lpName = _lpName;
        lpSymbol = _lpSymbol;
        spName = _spName;
        spSymbol = _spSymbol;
    }

    modifier onlySLARegistry() {
        if (!retry) {
            require(
                msg.sender == _slaRegistryAddress,
                'Can only be called by SLARegistry'
            );
        }
        _;
    }

    modifier retryLock() {
        retry = true;
        _;
        retry = false;
    }

    function setSLARegistry() public override {
        require(
            _slaRegistryAddress == address(0),
            'SLARegistry address has already been set'
        );

        _slaRegistryAddress = msg.sender;
    }

    function requestSLI(
        uint256 _periodId,
        address _slaAddress,
        bool _messengerOwnerApproval,
        address _callerAddress
    ) public override onlySLARegistry nonReentrant {
        require(_jobId != 0, '_jobI empty');
        SLA sla = SLA(_slaAddress);
        if (_messengerOwnerApproval) {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                owner(),
                address(this),
                _fee
            );
        } else {
            ERC20(chainlinkTokenAddress()).safeTransferFrom(
                _callerAddress,
                address(this),
                _fee
            );
        }
        Chainlink.Request memory request = buildChainlinkRequest(
            _jobId,
            address(this),
            this.fulfillSLI.selector
        );
        (
            uint256 sla_monitoring_start,
            uint256 sla_monitoring_end
        ) = periodRegistry.getPeriodStartAndEnd(sla.periodType(), _periodId);
        request.add(
            'sla_monitoring_start',
            StringUtils.uintToStr(sla_monitoring_start)
        );
        request.add(
            'sla_monitoring_end',
            StringUtils.uintToStr(sla_monitoring_end)
        );
        request.add('sla_address', StringUtils.addressToString(_slaAddress));
        request.add('network_name', StringUtils.bytes32ToStr(networkName));

        // Sends the request with 0.1 LINK to the oracle contract
        bytes32 requestId = sendChainlinkRequestTo(_oracle, request, _fee);

        requests.push(requestId);

        requestIdToSLIRequest[requestId] = SLIRequest({
            slaAddress: _slaAddress,
            periodId: _periodId
        });

        _requestsCounter += 1;
        emit SLIRequested(_callerAddress, _requestsCounter, requestId);
    }

    function fulfillSLI(bytes32 _requestId, uint256 _chainlinkResponse)
        external
        override
        nonReentrant
        recordChainlinkFulfillment(_requestId)
    {
        SLIRequest memory request = requestIdToSLIRequest[_requestId];
        emit SLIReceived(
            request.slaAddress,
            request.periodId,
            _requestId,
            bytes32(_chainlinkResponse)
        );
        _fulfillsCounter += 1;
        SLA(request.slaAddress).registerSLI(
            _chainlinkResponse,
            request.periodId
        );
    }

    function retryRequest(address _slaAddress, uint256 _periodId)
        external
        override
        retryLock
    {
        require(
            stakeRegistry.periodIsVerified(_slaAddress, _periodId),
            'StakeRegistry: not verified'
        );
        SLA sla = SLA(_slaAddress);
        (, , SLA.Status status) = sla.periodSLIs(_periodId);
        require(status == SLA.Status.NotVerified, 'SLA: verified');
        requestSLI(_periodId, _slaAddress, false, msg.sender);
    }

    function setChainlinkJobID(bytes32 _newJobId, uint256 _feeMultiplier)
        external
        override
        onlyOwner
    {
        _jobId = _newJobId;
        _fee = _feeMultiplier * _baseFee;
        emit JobIdModified(msg.sender, _newJobId, _fee);
    }

    function slaRegistryAddress() external view override returns (address) {
        return _slaRegistryAddress;
    }

    function messengerPrecision() external pure override returns (uint256) {
        return _messengerPrecision;
    }

    function oracle() external view override returns (address) {
        return _oracle;
    }

    function jobId() external view override returns (bytes32) {
        return _jobId;
    }

    function fee() external view override returns (uint256) {
        return _fee;
    }

    function requestsCounter() external view override returns (uint256) {
        return _requestsCounter;
    }

    function fulfillsCounter() external view override returns (uint256) {
        return _fulfillsCounter;
    }

    function lpSymbolSlaId(uint128 slaId)
        external
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(lpSymbol, '-', Strings.toString(slaId)));
    }

    function spSymbolSlaId(uint128 slaId)
        external
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(spSymbol, '-', Strings.toString(slaId)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title IMessenger
 * @dev Interface to create new Messenger contract to add lo Messenger lists
 */

abstract contract IMessenger is Ownable {
    struct SLIRequest {
        address slaAddress;
        uint256 periodId;
    }

    /**
     * @dev event emitted when created a new chainlink request
     * @param caller 1. Requester's address
     * @param requestsCounter 2. total count of requests
     * @param requestId 3. id of the Chainlink request
     */
    event SLIRequested(
        address indexed caller,
        uint256 requestsCounter,
        bytes32 requestId
    );

    /**
     * @dev event emitted when having a response from Chainlink with the SLI
     * @param slaAddress 1. SLA address to store the SLI
     * @param periodId 2. period id
     * @param requestId 3. id of the Chainlink request
     * @param chainlinkResponse 4. response from Chainlink
     */
    event SLIReceived(
        address indexed slaAddress,
        uint256 periodId,
        bytes32 indexed requestId,
        bytes32 chainlinkResponse
    );

    /**
     * @dev event emitted when updating Chainlink Job ID
     * @param owner 1. Oracle Owner
     * @param jobId 2. Updated job id
     * @param fee 3. Chainlink request fee
     */
    event JobIdModified(address indexed owner, bytes32 jobId, uint256 fee);

    /**
     * @dev sets the SLARegistry contract address and can only be called once
     */
    function setSLARegistry() external virtual;

    /**
     * @dev creates a ChainLink request to get a new SLI value for the
     * given params. Can only be called by the SLARegistry contract or Chainlink Oracle.
     * @param _periodId 1. id of the period to be queried
     * @param _slaAddress 2. address of the receiver SLA
     * @param _slaAddress 2. if approval by owner or msg.sender
     */
    function requestSLI(
        uint256 _periodId,
        address _slaAddress,
        bool _ownerApproval,
        address _callerAddress
    ) external virtual;

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param answer response object from Chainlink Oracles
     */
    function fulfillSLI(bytes32 _requestId, uint256 answer) external virtual;

    /**
     * @dev gets the interfaces precision
     */
    function messengerPrecision() external view virtual returns (uint256);

    /**
     * @dev gets the slaRegistryAddress
     */
    function slaRegistryAddress() external view virtual returns (address);

    /**
     * @dev gets the chainlink oracle contract address
     */
    function oracle() external view virtual returns (address);

    /**
     * @dev gets the chainlink job id
     */
    function jobId() external view virtual returns (bytes32);

    /**
     * @dev gets the fee amount of LINK token
     */
    function fee() external view virtual returns (uint256);

    /**
     * @dev returns the requestsCounter
     */
    function requestsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the fulfillsCounter
     */
    function fulfillsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the name of DSLA-LP token
     */
    function lpName() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-LP token
     */
    function lpSymbol() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-LP token with slaId
     */
    function lpSymbolSlaId(uint128 slaId)
        external
        view
        virtual
        returns (string memory);

    /**
     * @dev returns the name of DSLA-SP token
     */
    function spName() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-SP token
     */
    function spSymbol() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-SP token with slaId
     */
    function spSymbolSlaId(uint128 slaId)
        external
        view
        virtual
        returns (string memory);

    function setChainlinkJobID(bytes32 _newJobId, uint256 _feeMultiplier)
        external
        virtual;

    function retryRequest(address _slaAddress, uint256 _periodId)
        external
        virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/ISLARegistry.sol';
import './interfaces/IStakeRegistry.sol';
import './interfaces/IPeriodRegistry.sol';
import './interfaces/ISLORegistry.sol';
import './Staking.sol';

/**
 @title Service Level Agreement Contract
 */
contract SLA is Staking {
    enum Status {
        NotVerified,
        Respected,
        NotRespected
    }

    struct PeriodSLI {
        uint256 timestamp;
        uint256 sli;
        Status status;
    }

    string public ipfsHash;
    ISLARegistry private _slaRegistry;
    ISLORegistry private immutable _sloRegistry;
    uint256 public immutable creationBlockNumber;
    uint128 public immutable initialPeriodId;
    uint128 public immutable finalPeriodId;
    IPeriodRegistry.PeriodType public immutable periodType;
    /// @dev extra data for customized workflows
    uint256[] public severity;
    uint256[] public penalty;

    bool public terminateContract = false;
    uint256 public nextVerifiablePeriod;

    /// @dev periodId=>PeriodSLI mapping
    mapping(uint256 => PeriodSLI) public periodSLIs;

    /// @notice An event that is emitted when creating a new SLI
    event SLICreated(uint256 timestamp, uint256 sli, uint256 periodId);

    /// @notice An event that is emitted when staking in User or Provider Pool
    event Stake(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount,
        Position position
    );
    /// @notice An event that is emitted when withdrawing from Provider Pool
    event ProviderWithdraw(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount
    );

    /// @notice An event that is emitted when withdrawing from User Pool
    event UserWithdraw(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount
    );

    /// @notice An event that is emitted when toggles termination
    event ToggleTermination(bool termination);

    /// @dev Modifier ensuring that certain function can only be called by Messenger
    modifier onlyMessenger() {
        require(msg.sender == messengerAddress, 'not messenger');
        _;
    }

    /**
     * @notice Constructor
     */
    constructor(
        address _owner,
        bool _whitelisted,
        IPeriodRegistry.PeriodType _periodType,
        address _messengerAddress,
        uint128 _initialPeriodId,
        uint128 _finalPeriodId,
        uint128 _slaID,
        string memory _ipfsHash,
        uint256[] memory _severity,
        uint256[] memory _penalty,
        uint64 _leverage
    )
        Staking(
            ISLARegistry(msg.sender),
            _whitelisted,
            _slaID,
            _leverage,
            _owner,
            _messengerAddress
        )
    {
        transferOwnership(_owner);
        ipfsHash = _ipfsHash;
        _slaRegistry = ISLARegistry(msg.sender);
        _sloRegistry = ISLORegistry(_slaRegistry.sloRegistry());
        creationBlockNumber = block.number;
        initialPeriodId = _initialPeriodId;
        finalPeriodId = _finalPeriodId;
        periodType = _periodType;
        severity = _severity;
        penalty = _penalty;
        nextVerifiablePeriod = _initialPeriodId;
    }

    /**
     * @notice External function that registers new SLI
     * @param _sli sli value to register
     * @param _periodId period id of new sli
     */
    function registerSLI(uint256 _sli, uint256 _periodId)
        external
        onlyMessenger
    {
        require(_periodId == nextVerifiablePeriod, 'invalid period id');
        emit SLICreated(block.timestamp, _sli, _periodId);
        nextVerifiablePeriod = _periodId + 1;
        PeriodSLI storage periodSLI = periodSLIs[_periodId];
        periodSLI.sli = _sli;
        periodSLI.timestamp = block.timestamp;

        uint256 deviation = _sloRegistry.getDeviation(
            _sli,
            address(this),
            severity,
            penalty
        );

        if (_sloRegistry.isRespected(_sli, address(this))) {
            periodSLI.status = Status.Respected;
            _setProviderReward(_periodId, deviation);
        } else {
            periodSLI.status = Status.NotRespected;
            _setUserReward(_periodId, deviation);
        }
    }

    /**
     @notice External view function to see if a period id is allowed or not
     @param _periodId period id to check
     @return bool allowed or not
     */
    function isAllowedPeriod(uint256 _periodId) external view returns (bool) {
        return _periodId >= initialPeriodId && _periodId <= finalPeriodId;
    }

    /**
     * @notice Public view function to check if the contract is finished
     * @dev finish condition = should pass last verified period and final period should not be verified.
     * @return Bool whether finished or not
     */
    function contractFinished() public view returns (bool) {
        (, uint256 endOfLastValidPeriod) = _periodRegistry.getPeriodStartAndEnd(
            periodType,
            finalPeriodId
        );
        return ((block.timestamp >= endOfLastValidPeriod &&
            periodSLIs[finalPeriodId].status != Status.NotVerified) ||
            terminateContract);
    }

    /**
     * @notice External function to stake tokens in User or Provider Pools
     * @param _amount amount to withdraw
     * @param _tokenAddress token address to withdraw
     * @param _position User or Provider pool
     */
    function stakeTokens(
        uint256 _amount,
        address _tokenAddress,
        Position _position
    ) external {
        require(!contractFinished(), 'This SLA has finished.');

        require(_amount > 0, 'Stake must be greater than 0.');

        _stake(_tokenAddress, nextVerifiablePeriod, _amount, _position);

        emit Stake(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount,
            _position
        );

        IStakeRegistry(_slaRegistry.stakeRegistry()).registerStakedSla(
            msg.sender
        );
    }

    /**
     * @notice External function to withdraw staked tokens from Provider Pool
     * @param _amount amount to withdraw
     * @param _tokenAddress token address to withdraw
     */
    function withdrawProviderTokens(uint256 _amount, address _tokenAddress)
        external
    {
        _withdrawProviderTokens(
            _amount,
            _tokenAddress,
            nextVerifiablePeriod,
            contractFinished()
        );

        emit ProviderWithdraw(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount
        );
    }

    /**
     * @notice External function to withdraw staked tokens from User Pool
     * @param _amount amount to withdraw
     * @param _tokenAddress token address to withdraw
     */
    function withdrawUserTokens(uint256 _amount, address _tokenAddress)
        external
    {
        _withdrawUserTokens(
            _amount,
            _tokenAddress,
            nextVerifiablePeriod,
            contractFinished()
        );

        emit UserWithdraw(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount
        );
    }

    function toggleTermination() external onlyOwner {
        (, uint256 endOfLastValidPeriod) = _periodRegistry.getPeriodStartAndEnd(
            periodType,
            finalPeriodId
        );

        require(
            block.timestamp >= endOfLastValidPeriod,
            'This SLA has not finished.'
        );

        terminateContract = !terminateContract;

        emit ToggleTermination(terminateContract);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IPeriodRegistry.sol';

/**
 * @title PeriodRegistry
 * @notice PeriodRegistry is a contract for management of period definitions
 */
contract PeriodRegistry is IPeriodRegistry, Ownable {
    /// @notice struct to store the definition of a period
    struct PeriodDefinition {
        bool initialized;
        uint256[] starts;
        uint256[] ends;
    }

    /// @notice (periodType=>PeriodDefinition) period definitions by period type
    /// @dev period types are hourly / weekly / biWeekly / monthly / yearly
    mapping(PeriodType => PeriodDefinition) public periodDefinitions;

    /**
     * @notice event to log that a period is initialized
     * @param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     * @param periodsAdded 2. amount of periods added
     */
    event PeriodInitialized(PeriodType periodType, uint256 periodsAdded);

    /**
     * @dev event to log that a period is modified
     * @param periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     * @param periodsAdded 2. amount of periods added
     */
    event PeriodModified(PeriodType periodType, uint256 periodsAdded);

    /**
     * @notice External function for creating canonical service level agreements
     * @param _periodType 1. period type i.e. Hourly, Daily, Weekly, BiWeekly, Monthly, Yearly
     * @param _periodStarts 2. array of the starts of the period
     * @param _periodEnds 3. array of the ends of the period
     */
    function initializePeriod(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) external onlyOwner {
        _addPeriods(false, _periodType, _periodStarts, _periodEnds);
        emit PeriodInitialized(_periodType, _periodStarts.length);
    }

    /**
     * @notice External function to add a new period definition
     * @dev only owner can call this function
     * @param _periodType type of period to add
     * @param _periodStarts array of the period starting timestamps to add
     * @param _periodEnds 3. array of the period ending timestamps to add
     */
    function addPeriodsToPeriodType(
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) external onlyOwner {
        _addPeriods(true, _periodType, _periodStarts, _periodEnds);
        emit PeriodModified(_periodType, _periodStarts.length);
    }

    /**
     * @notice Internal function that add or update a period definition
     * @param _periodType type of period
     * @param _periodStarts array of the period starting timestamps
     * @param _periodEnds array of the period ending timestamps
     */
    function _addPeriods(
        bool _initialized,
        PeriodType _periodType,
        uint256[] memory _periodStarts,
        uint256[] memory _periodEnds
    ) internal {
        require(_periodStarts.length > 0, "Period length can't be 0");
        require(
            _periodStarts.length == _periodEnds.length,
            'Period length in start and end arrays should match'
        );
        PeriodDefinition storage periodDefinition = periodDefinitions[
            _periodType
        ];
        if (_initialized)
            require(
                periodDefinition.initialized,
                'Period was not initialized yet'
            );
        else
            require(
                !periodDefinition.initialized,
                'Period type already initialized'
            );

        for (uint256 index = 0; index < _periodStarts.length; index++) {
            require(
                _periodStarts[index] < _periodEnds[index],
                'Start should be before end'
            );
            if (index < _periodStarts.length - 1) {
                require(
                    _periodStarts[index + 1] - _periodEnds[index] == 1,
                    'Start of a period should be 1 second after the end of the previous period'
                );
            }
            periodDefinition.starts.push(_periodStarts[index]);
            periodDefinition.ends.push(_periodEnds[index]);
        }
        periodDefinition.initialized = true;
    }

    /**
     * @notice public function to get the start and end of a period
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return start starting timestamp
     * @return end ending timestamp
     */
    function getPeriodStartAndEnd(PeriodType _periodType, uint256 _periodId)
        external
        view
        override
        returns (uint256 start, uint256 end)
    {
        require(
            _periodId < periodDefinitions[_periodType].starts.length,
            'Invalid period id'
        );
        start = periodDefinitions[_periodType].starts[_periodId];
        end = periodDefinitions[_periodType].ends[_periodId];
    }

    /**
     * @notice public function to check if the period definition is initialized by period type
     * @param _periodType type of period to check
     * @return initialized if initialized or not
     */
    function isInitializedPeriod(PeriodType _periodType)
        external
        view
        override
        returns (bool initialized)
    {
        initialized = periodDefinitions[_periodType].initialized;
    }

    /**
     * @notice public function to check if a period id is valid i.e. it belongs to the added id array
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return valid if valid or invalid
     */
    function isValidPeriod(PeriodType _periodType, uint256 _periodId)
        public
        view
        override
        returns (bool valid)
    {
        valid = periodDefinitions[_periodType].starts.length - 1 >= _periodId;
    }

    /**
     * @notice public function to check if a period has finished
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return finished if finished or not
     */
    function periodIsFinished(PeriodType _periodType, uint256 _periodId)
        external
        view
        override
        returns (bool finished)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            'Period data is not valid'
        );
        finished =
            periodDefinitions[_periodType].ends[_periodId] < block.timestamp;
    }

    /**
     * @notice public function to check if a period has started
     * @param _periodType type of period to check
     * @param _periodId id of period to check
     * @return started if started or not
     */
    function periodHasStarted(PeriodType _periodType, uint256 _periodId)
        external
        view
        override
        returns (bool started)
    {
        require(
            isValidPeriod(_periodType, _periodId),
            'Period data is not valid'
        );
        started =
            periodDefinitions[_periodType].starts[_periodId] < block.timestamp;
    }

    /**
     * @notice public function to get the definitions of period for all period types
     * @return array of period definitions
     */
    function getPeriodDefinitions()
        public
        view
        returns (PeriodDefinition[] memory)
    {
        // 6 period types
        PeriodDefinition[] memory periodDefinition = new PeriodDefinition[](6);
        periodDefinition[0] = periodDefinitions[PeriodType.Hourly];
        periodDefinition[1] = periodDefinitions[PeriodType.Daily];
        periodDefinition[2] = periodDefinitions[PeriodType.Weekly];
        periodDefinition[3] = periodDefinitions[PeriodType.BiWeekly];
        periodDefinition[4] = periodDefinitions[PeriodType.Monthly];
        periodDefinition[5] = periodDefinitions[PeriodType.Yearly];
        return periodDefinition;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

library StringUtils {
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = '0123456789abcdef';
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function bytes32ToStr(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function bytesToUint(bytes memory b)
        internal
        pure
        returns (uint256 result)
    {
        result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }

    function uintToStr(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function stringFloatToUnit(bytes memory value)
        internal
        pure
        returns (uint256 result)
    {
        uint256 i;
        uint256 counterBeforeDot;
        uint256 counterAfterDot;
        result = 0;
        uint256 totNum = value.length;
        totNum--;
        bool hasDot = false;

        for (i = 0; i < value.length; i++) {
            uint8 c = uint8(value[i]);

            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
                counterBeforeDot++;
                totNum--;
            }

            if (c == 46) {
                hasDot = true;
                break;
            }
        }

        if (hasDot) {
            for (uint256 j = 0; j < 18; j++) {
                uint8 m = uint8(value[counterBeforeDot + 1 + j]);
                if (m >= 48 && m <= 57) {
                    result = result * 10 + (m - 48);
                    counterAfterDot++;
                    totNum--;
                }

                if (totNum == 0) {
                    break;
                }
            }
        }
        if (counterAfterDot <= 18) {
            uint256 addNum = 18 - counterAfterDot;
            result = result * 10**addNum;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './SLA.sol';
import './dToken.sol';
import './interfaces/IMessenger.sol';
import './interfaces/ISLARegistry.sol';
import './interfaces/IStakeRegistry.sol';

/**
 * @title StakeRegistry
 * @dev StakeRegistry is a contract to register the staking activity of the platform, along
 with controlling certain admin privileged parameters
 */
contract StakeRegistry is IStakeRegistry, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct LockedValue {
        uint256 lockedValue;
        uint256 slaPeriodIdsLength;
        uint256 dslaDepositByPeriod;
        uint256 dslaPlatformReward;
        uint256 dslaMessengerReward;
        uint256 dslaUserReward;
        uint256 dslaBurnedByVerification;
        mapping(uint256 => bool) verifiedPeriods;
    }

    address private _DSLATokenAddress;
    ISLARegistry public slaRegistry;

    //______ onlyOwner modifiable parameters ______

    /// @dev corresponds to the burn rate of DSLA tokens, but divided by 1000 i.e burn percentage = DSLAburnRate/1000 %
    uint256 private _DSLAburnRate = 3;
    /// @dev (ownerAddress => slaAddress => LockedValue) stores the locked value by the staker
    mapping(address => LockedValue) public slaLockedValue;
    /// @dev DSLA deposit by period to create SLA
    uint256 private _dslaDepositByPeriod = 1000 ether;
    /// @dev DSLA rewarded to the foundation
    uint256 private _dslaPlatformReward = 250 ether;
    /// @dev DSLA rewarded to the Messenger creator
    uint256 private _dslaMessengerReward = 250 ether;
    /// @dev DSLA rewarded to user calling the period verification
    uint256 private _dslaUserReward = 250 ether;
    /// @dev DSLA burned after every period verification
    uint256 private _dslaBurnedByVerification = 250 ether;
    /// @dev max token length for allowedTokens array of Staking contracts
    uint256 private _maxTokenLength = 1;
    /// @dev max times of hedge leverage
    uint64 private _maxLeverage = 100;
    /// @dev burn DSLA after verification
    bool private _burnDSLA = true;

    /// @dev array with the allowed tokens addresses of the StakeRegistry
    address[] public allowedTokens;

    /// @dev (userAddress => (SLA address => registered)) with user staked SLAs to get tokenPool
    mapping(address => mapping(address => bool)) public userStakedSlas;

    /**
     * @dev event to log a verifiation reward distributed
     * @param sla 1. The address of the created service level agreement contract
     * @param requester 2. -
     * @param userReward 3. -
     * @param platformReward 4. -
     * @param messengerReward 5. -
     * @param burnedDSLA 6. -
     */
    event VerificationRewardDistributed(
        address indexed sla,
        address indexed requester,
        uint256 userReward,
        uint256 platformReward,
        uint256 messengerReward,
        uint256 burnedDSLA
    );

    /**
     * @dev event to log modifications on the staking parameters
     * @param DSLAburnRate 1. (DSLAburnRate/1000)% of DSLA to be burned after a reward/compensation is paid
     * @param dslaDepositByPeriod 2. DSLA deposit by period to create SLA
     * @param dslaPlatformReward 3. DSLA rewarded to Stacktical team
     * @param dslaUserReward 4. DSLA rewarded to user calling the period verification
     * @param dslaBurnedByVerification 5. DSLA burned after every period verification
     */
    event StakingParametersModified(
        uint256 DSLAburnRate,
        uint256 dslaDepositByPeriod,
        uint256 dslaPlatformReward,
        uint256 dslaMessengerReward,
        uint256 dslaUserReward,
        uint256 dslaBurnedByVerification,
        uint256 maxTokenLength,
        uint64 maxLeverage,
        bool burnDSLA
    );

    /**
     * @dev event to log modifications on the staking parameters
     * @param sla 1. -
     * @param owner 2. -
     * @param amount 3. -
     */

    event LockedValueReturned(
        address indexed sla,
        address indexed owner,
        uint256 amount
    );

    /**
     * @dev event to log modifications on the staking parameters
     * @param dTokenAddress 1. -
     * @param sla 2. -
     * @param name 3. -
     * @param symbol 4. -
     */
    event DTokenCreated(
        address indexed dTokenAddress,
        address indexed sla,
        string name,
        string symbol
    );

    /**
     * @dev event to log modifications on the staking parameters
     * @param sla 1. -
     * @param owner 2. -
     * @param amount 3. -
     */
    event ValueLocked(
        address indexed sla,
        address indexed owner,
        uint256 amount
    );

    /// @dev Throws if called by any address other than the SLARegistry contract or Chainlink Oracle.
    modifier onlySLARegistry() {
        require(
            msg.sender == address(slaRegistry),
            'Can only be called by SLARegistry'
        );
        _;
    }

    /**
     * @notice Constructor
     * @param _dslaTokenAddress 1. DSLA Token
     */
    constructor(address _dslaTokenAddress) {
        require(
            _dslaTokenAddress != address(0x0),
            'invalid DSLA token address'
        );
        require(
            _dslaDepositByPeriod ==
                _dslaPlatformReward +
                    _dslaMessengerReward +
                    _dslaUserReward +
                    _dslaBurnedByVerification,
            'Staking parameters should match on summation'
        );
        _DSLATokenAddress = _dslaTokenAddress;
        allowedTokens.push(_dslaTokenAddress);
    }

    /**
     * @notice function to set the SLARegistry contract address
     * @dev this function can only be called once
     */
    function setSLARegistry() external override {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            'SLARegistry address has already been set'
        );

        slaRegistry = ISLARegistry(msg.sender);
    }

    /**
     * @notice add a token to ve allowed for staking
     * @dev only owner can call this function for non-registered tokens
     * @param _tokenAddress 1. address of the new allowed token
     */
    function addAllowedTokens(address _tokenAddress) external onlyOwner {
        require(
            !isAllowedToken(_tokenAddress),
            'This token has been allowed already.'
        );
        allowedTokens.push(_tokenAddress);
    }

    /**
     * @notice function to check if the token is registered
     * @param _tokenAddress token address to check
     * @return true if registered
     */
    function isAllowedToken(address _tokenAddress)
        public
        view
        override
        returns (bool)
    {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev public view function that returns true if the _owner has staked on _sla
     * @param _user 1. address to check
     * @param _sla 2. sla to check
     * @return bool, true if _sla was staked by _user
     */

    function slaWasStakedByUser(address _user, address _sla)
        public
        view
        returns (bool)
    {
        return userStakedSlas[_user][_sla];
    }

    /**
     * @notice function to register the sending SLA contract as staked by _owner
     * @dev only registered SLA can call this function
     * @param _owner 1. SLA contract to stake
     */
    function registerStakedSla(address _owner)
        external
        override
        returns (bool)
    {
        require(
            slaRegistry.isRegisteredSLA(msg.sender),
            'Only for registered SLAs'
        );
        if (!slaWasStakedByUser(_owner, msg.sender)) {
            userStakedSlas[_owner][msg.sender] = true;
        }
        return true;
    }

    /**
     * @notice function to create dTokens for staking
     * @dev only registered SLA can call this function
     * @param _name 1. token name
     * @param _symbol 2. token symbol
     * @param _decimals 3. token decimals
     */
    function createDToken(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    ) external override returns (address) {
        require(
            slaRegistry.isRegisteredSLA(msg.sender),
            'Only for registered SLAs'
        );
        dToken newDToken = new dToken(_name, _symbol, _decimals);
        newDToken.grantRole(newDToken.MINTER_ROLE(), msg.sender);
        emit DTokenCreated(address(newDToken), msg.sender, _name, _symbol);
        return address(newDToken);
    }

    /**
     * @notice function to lock DSLA
     * @dev only SLARegistry can call this function
     * @param _slaOwner owner address of sla
     * @param _sla address of sla
     * @param _periodIdsLength number of periods to lock
     */
    function lockDSLAValue(
        address _slaOwner,
        address _sla,
        uint256 _periodIdsLength
    ) external override onlySLARegistry nonReentrant {
        uint256 lockedValue = _dslaDepositByPeriod * _periodIdsLength;
        IERC20(_DSLATokenAddress).safeTransferFrom(
            _slaOwner,
            address(this),
            lockedValue
        );
        LockedValue storage _lockedValue = slaLockedValue[_sla];
        _lockedValue.lockedValue = lockedValue;
        _lockedValue.slaPeriodIdsLength = _periodIdsLength;
        _lockedValue.dslaDepositByPeriod = _dslaDepositByPeriod;
        _lockedValue.dslaPlatformReward = _dslaPlatformReward;
        _lockedValue.dslaMessengerReward = _dslaMessengerReward;
        _lockedValue.dslaUserReward = _dslaUserReward;
        _lockedValue.dslaBurnedByVerification = _dslaBurnedByVerification;
        emit ValueLocked(_sla, _slaOwner, lockedValue);
    }

    /**
     * @notice function to distribute verification rewards to verifier
     * @dev only SLARegistry can call this function
     * @param _sla address of sla
     * @param _verificationRewardReceiver verifier who verified the periodId
     * @param _periodId verified period id by verifier
     */
    function distributeVerificationRewards(
        address _sla,
        address _verificationRewardReceiver,
        uint256 _periodId
    ) external override onlySLARegistry nonReentrant {
        LockedValue storage _lockedValue = slaLockedValue[_sla];
        require(
            !_lockedValue.verifiedPeriods[_periodId],
            'Period rewards already distributed'
        );
        _lockedValue.verifiedPeriods[_periodId] = true;
        _lockedValue.lockedValue -= _lockedValue.dslaDepositByPeriod;
        IERC20(_DSLATokenAddress).safeTransfer(
            _verificationRewardReceiver,
            _lockedValue.dslaUserReward
        );
        IERC20(_DSLATokenAddress).safeTransfer(
            owner(),
            _lockedValue.dslaPlatformReward
        );
        IERC20(_DSLATokenAddress).safeTransfer(
            IMessenger(SLA(_sla).messengerAddress()).owner(),
            _lockedValue.dslaMessengerReward
        );
        if (_burnDSLA) {
            (bool success, ) = _DSLATokenAddress.call(
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes('burn(uint256)'))),
                    _lockedValue.dslaBurnedByVerification
                )
            );
            require(success, 'burn process failed');
        }
        emit VerificationRewardDistributed(
            _sla,
            _verificationRewardReceiver,
            _lockedValue.dslaUserReward,
            _lockedValue.dslaPlatformReward,
            _lockedValue.dslaMessengerReward,
            _lockedValue.dslaBurnedByVerification
        );
    }

    /**
     * @notice function to return locked tokens back to sla owner
     * @dev only SLARegistry can call this function
     * @param _sla address of SLA
     */
    function returnLockedValue(address _sla)
        external
        override
        onlySLARegistry
        nonReentrant
    {
        LockedValue storage _lockedValue = slaLockedValue[_sla];
        uint256 remainingBalance = _lockedValue.lockedValue;
        require(remainingBalance > 0, 'locked value is empty');
        _lockedValue.lockedValue = 0;
        IERC20(_DSLATokenAddress).safeTransfer(
            SLA(_sla).owner(),
            remainingBalance
        );
        emit LockedValueReturned(_sla, SLA(_sla).owner(), remainingBalance);
    }

    //_______ OnlyOwner functions _______
    /**
     * @notice external function that sets staking parameters
     * @dev only owner can call this function
     */
    function setStakingParameters(
        uint256 DSLAburnRate,
        uint256 dslaDepositByPeriod,
        uint256 dslaPlatformReward,
        uint256 dslaMessengerReward,
        uint256 dslaUserReward,
        uint256 dslaBurnedByVerification,
        uint256 maxTokenLength,
        uint64 maxLeverage,
        bool burnDSLA
    ) external onlyOwner {
        _DSLAburnRate = DSLAburnRate;
        _dslaDepositByPeriod = dslaDepositByPeriod;
        _dslaPlatformReward = dslaPlatformReward;
        _dslaMessengerReward = dslaMessengerReward;
        _dslaUserReward = dslaUserReward;
        _dslaBurnedByVerification = dslaBurnedByVerification;
        _maxTokenLength = maxTokenLength;
        _maxLeverage = maxLeverage;
        _burnDSLA = burnDSLA;
        require(
            _dslaDepositByPeriod ==
                _dslaPlatformReward +
                    _dslaMessengerReward +
                    _dslaUserReward +
                    _dslaBurnedByVerification,
            'Staking parameters should match on summation'
        );
        emit StakingParametersModified(
            DSLAburnRate,
            dslaDepositByPeriod,
            dslaPlatformReward,
            dslaMessengerReward,
            dslaUserReward,
            dslaBurnedByVerification,
            maxTokenLength,
            maxLeverage,
            burnDSLA
        );
    }

    /**
     * @notice external view function that returns staking parameters
     */
    function getStakingParameters()
        external
        view
        override
        returns (
            uint256 DSLAburnRate,
            uint256 dslaDepositByPeriod,
            uint256 dslaPlatformReward,
            uint256 dslaMessengerReward,
            uint256 dslaUserReward,
            uint256 dslaBurnedByVerification,
            uint256 maxTokenLength,
            uint64 maxLeverage,
            bool burnDSLA
        )
    {
        DSLAburnRate = _DSLAburnRate;
        dslaDepositByPeriod = _dslaDepositByPeriod;
        dslaPlatformReward = _dslaPlatformReward;
        dslaMessengerReward = _dslaMessengerReward;
        dslaUserReward = _dslaUserReward;
        dslaBurnedByVerification = _dslaBurnedByVerification;
        maxTokenLength = _maxTokenLength;
        maxLeverage = _maxLeverage;
        burnDSLA = _burnDSLA;
    }

    /**
     * @notice external view function that checks the verification of period
     * @param _sla address of SLA
     * @param _periodId period id
     * @return verified or not
     */
    function periodIsVerified(address _sla, uint256 _periodId)
        external
        view
        override
        returns (bool)
    {
        return slaLockedValue[_sla].verifiedPeriods[_periodId];
    }

    /**
     * @notice external view function that returns DSLA token address
     * @return address of DSLA token
     */
    function DSLATokenAddress() external view override returns (address) {
        return _DSLATokenAddress;
    }

    function owner()
        public
        view
        override(IStakeRegistry, Ownable)
        returns (address)
    {
        return super.owner();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
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

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface ISLARegistry {
    function sloRegistry() external view returns (address);

    function periodRegistry() external view returns (address);

    function messengerRegistry() external view returns (address);

    function stakeRegistry() external view returns (address);

    function isRegisteredSLA(address _slaAddress) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface IStakeRegistry {
    function registerStakedSla(address _owner) external returns (bool);

    function setSLARegistry() external;

    function lockDSLAValue(
        address slaOwner_,
        address sla_,
        uint256 periodIdsLength_
    ) external;

    function getStakingParameters()
        external
        view
        returns (
            uint256 DSLAburnRate,
            uint256 dslaDepositByPeriod,
            uint256 dslaPlatformReward,
            uint256 dslaMessengerReward,
            uint256 dslaUserReward,
            uint256 dslaBurnedByVerification,
            uint256 maxTokenLength,
            uint64 maxLeverage,
            bool burnDSLA
        );

    function DSLATokenAddress() external view returns (address);

    function isAllowedToken(address tokenAddress_) external view returns (bool);

    function periodIsVerified(address _sla, uint256 _periodId)
        external
        view
        returns (bool);

    function returnLockedValue(address sla_) external;

    function distributeVerificationRewards(
        address _sla,
        address _verificationRewardReceiver,
        uint256 _periodId
    ) external;

    function createDToken(
        string calldata _name,
        string calldata _symbol,
        uint8 decimals
    ) external returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface IPeriodRegistry {
    enum PeriodType {
        Hourly,
        Daily,
        Weekly,
        BiWeekly,
        Monthly,
        Yearly
    }

    function getPeriodStartAndEnd(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (uint256, uint256);

    function isValidPeriod(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (bool);

    function isInitializedPeriod(PeriodType _periodType)
        external
        view
        returns (bool);

    function periodHasStarted(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (bool);

    function periodIsFinished(PeriodType _periodType, uint256 _periodId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface ISLORegistry {
    function getDeviation(
        uint256 _sli,
        address _slaAddress,
        uint256[] calldata _severity,
        uint256[] calldata _penalty
    ) external view returns (uint256);

    function isRespected(uint256 _value, address _slaAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IStakeRegistry.sol';
import './interfaces/ISLARegistry.sol';
import './interfaces/IPeriodRegistry.sol';
import './interfaces/IMessenger.sol';
import './interfaces/IERC20Query.sol';
import './dToken.sol';

/**
 * @title Staking
 * @notice Staking of user and provider pool rewards
 */
contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Position of staking
    /// @dev OK => Provider Pool (LONG), KO => User Pool (SHORT)
    enum Position {
        OK,
        KO
    }

    /// @dev StakeRegistry contract
    IStakeRegistry private _stakeRegistry;

    /// @dev SLARegistry contract
    IPeriodRegistry internal immutable _periodRegistry;

    /// @dev DSLA token address to burn fees
    address private immutable _dslaTokenAddress;
    /// @dev messenger address
    address public immutable messengerAddress;
    /// @dev current SLA id
    uint128 public immutable slaID;

    /// @dev (tokenAddress=>uint256) total pooled token balance
    mapping(address => uint256) public providersPool;

    /// @dev (userAddress=>uint256) provider staking activity
    mapping(address => uint256) public lastProviderStake;

    /// @dev (tokenAddress=>uint256) user staking
    mapping(address => uint256) public usersPool;

    /// @dev (userAddress=>uint256) user staking activity
    mapping(address => uint256) public lastUserStake;

    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for users
    mapping(address => dToken) public duTokenRegistry;

    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for provider
    mapping(address => dToken) public dpTokenRegistry;

    /// @dev (slaOwner=>bool)
    mapping(address => bool) public registeredStakers;

    /// @dev number of stakers
    uint256 public stakersNum;

    /// @dev array with the allowed tokens addresses for the current SLA
    address[] public allowedTokens;

    /// @dev corresponds to the burn rate of DSLA tokens, but divided by 1000 i.e burn percentage = burnRate/1000 %
    uint256 public immutable DSLAburnRate;

    /// @dev boolean to declare if contract is whitelisted
    bool public immutable whitelistedContract;

    /// @dev (userAddress=bool) to declare whitelisted addresses
    mapping(address => bool) public whitelist;

    uint64 public immutable leverage;

    /// @dev claiming fees when a user claim tokens, base 10000
    uint16 private constant ownerRewardsRate = 30; // 0.3%, base 10000
    uint16 private constant protocolRewardsRate = 15; // 0.15%, base 10000
    uint16 private constant rewardsCapRate = 2500; // 25%, base 10000

    modifier onlyAllowedToken(address _token) {
        require(isAllowedToken(_token), 'This token is not allowed.');
        _;
    }

    modifier onlyWhitelisted() {
        if (whitelistedContract) {
            require(whitelist[msg.sender], 'not whitelisted');
        }
        _;
    }

    /// @notice An event that emitted when generating provider rewards
    event ProviderRewardGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 rewardPercentage,
        uint256 rewardPercentagePrecision,
        uint256 rewardAmount
    );

    /// @notice An event that emitted when generating user rewards
    event UserCompensationGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 userStake,
        uint256 leverage,
        uint256 compensation
    );

    /// @notice An event that emitted when owner adds new dTokens
    event DTokensCreated(
        address indexed tokenAddress,
        address indexed dpTokenAddress,
        string dpTokenName,
        string dpTokenSymbol,
        address indexed duTokenAddress,
        string duTokenName,
        string duTokenSymbol
    );

    /**
     * @notice Constructor
     * @param slaRegistry_ SLARegistry address
     * @param whitelistedContract_ Declare if contract is whitelisted
     * @param slaID_ ID of SLA
     * @param leverage_ Leverage of reward
     * @param contractOwner_ SLA Owner address
     * @param messengerAddress_ Messenger Address
     */
    constructor(
        ISLARegistry slaRegistry_,
        bool whitelistedContract_,
        uint128 slaID_,
        uint64 leverage_,
        address contractOwner_,
        address messengerAddress_
    ) {
        require(contractOwner_ != address(0x0), 'invalid owner address');
        require(messengerAddress_ != address(0x0), 'invalid messenger address');
        _stakeRegistry = IStakeRegistry(slaRegistry_.stakeRegistry());
        _periodRegistry = IPeriodRegistry(slaRegistry_.periodRegistry());
        whitelistedContract = whitelistedContract_;
        (
            uint256 _DSLAburnRate,
            ,
            ,
            ,
            ,
            ,
            ,
            uint64 _maxLeverage,

        ) = _stakeRegistry.getStakingParameters();
        _dslaTokenAddress = _stakeRegistry.DSLATokenAddress();
        DSLAburnRate = _DSLAburnRate;
        whitelist[contractOwner_] = true;
        slaID = slaID_;
        require(
            leverage_ <= _maxLeverage && leverage_ >= 1,
            'incorrect leverage'
        );
        leverage = leverage_;
        messengerAddress = messengerAddress_;
    }

    /**
     * @notice Add multiple addresses to whitelist
     * @dev only owner can call this function
     * @param _userAddresses Addresses to whitelist
     */
    function addUsersToWhitelist(address[] memory _userAddresses)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (!whitelist[_userAddresses[index]]) {
                whitelist[_userAddresses[index]] = true;
            }
        }
    }

    /**
     * @notice Remove multiple addresses from whitelist
     * @dev only owner can call this function
     * @param _userAddresses Addresses to remove
     */
    function removeUsersFromWhitelist(address[] calldata _userAddresses)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (whitelist[_userAddresses[index]]) {
                whitelist[_userAddresses[index]] = false;
            }
        }
    }

    /**
     * @notice Add token to allowedTokens list
     * @dev It creates dpToken(Provider) and duToken(User) that represents the position.
            only owner can call this function
     * @param _tokenAddress Token address to allow
     */
    function addAllowedTokens(address _tokenAddress) external onlyOwner {
        (, , , , , , uint256 maxTokenLength, , ) = _stakeRegistry
            .getStakingParameters();

        require(
            !isAllowedToken(_tokenAddress),
            'This token has been allowed already.'
        );

        require(
            _stakeRegistry.isAllowedToken(_tokenAddress),
            'This token is not allowed.'
        );
        allowedTokens.push(_tokenAddress);

        require(maxTokenLength >= allowedTokens.length, 'max token length');

        string memory duTokenName = IMessenger(messengerAddress).spName();
        string memory duTokenSymbol = IMessenger(messengerAddress)
            .spSymbolSlaId(slaID);
        string memory dpTokenName = IMessenger(messengerAddress).lpName();
        string memory dpTokenSymbol = IMessenger(messengerAddress)
            .lpSymbolSlaId(slaID);

        uint8 decimals = IERC20Query(_tokenAddress).decimals();

        dToken duToken = dToken(
            _stakeRegistry.createDToken(duTokenName, duTokenSymbol, decimals)
        );

        dToken dpToken = dToken(
            _stakeRegistry.createDToken(dpTokenName, dpTokenSymbol, decimals)
        );

        dpTokenRegistry[_tokenAddress] = dpToken;
        duTokenRegistry[_tokenAddress] = duToken;
        emit DTokensCreated(
            _tokenAddress,
            address(dpToken),
            dpTokenName,
            dpTokenSymbol,
            address(duToken),
            duTokenName,
            duTokenSymbol
        );
    }

    /**
     * @notice Stake allowed assets in User or Provider pools until next period
     * @param _tokenAddress Address of token to stake
     * @param _nextVerifiablePeriod Next verifiable PeriodId
     * @param _amount Amount of tokens to stake
     * @param _position Staking position, OK or KO
     */
    function _stake(
        address _tokenAddress,
        uint256 _nextVerifiablePeriod,
        uint256 _amount,
        Position _position
    ) internal onlyAllowedToken(_tokenAddress) onlyWhitelisted nonReentrant {
        IERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // DSLA-SP proofs of SLA Position
        if (_position == Position.KO) {
            require(
                (usersPool[_tokenAddress] + _amount) * leverage <=
                    providersPool[_tokenAddress],
                'Stake exceeds leveraged cap.'
            );

            dToken duToken = duTokenRegistry[_tokenAddress];
            uint256 p0 = duToken.totalSupply();

            // If there are no minted tokens, then mint them 1:1
            if (p0 == 0) {
                duToken.mint(msg.sender, _amount);
            } else {
                // mint dTokens proportionally
                duToken.mint(
                    msg.sender,
                    (_amount * p0) / usersPool[_tokenAddress]
                );
            }
            usersPool[_tokenAddress] += _amount;
            lastUserStake[msg.sender] = _nextVerifiablePeriod;
        }

        // DSLA-LP proofs of SLA Position
        if (_position == Position.OK) {
            dToken dpToken = dpTokenRegistry[_tokenAddress];
            uint256 p0 = dpToken.totalSupply();

            if (p0 == 0) {
                dpToken.mint(msg.sender, _amount);
            } else {
                // mint dTokens proportionally
                dpToken.mint(
                    msg.sender,
                    (_amount * p0) / providersPool[_tokenAddress]
                );
            }
            providersPool[_tokenAddress] += _amount;
            lastProviderStake[msg.sender] = _nextVerifiablePeriod;
        }

        if (!registeredStakers[msg.sender]) {
            registeredStakers[msg.sender] = true;
            stakersNum++;
        }
    }

    /**
     * @notice Set rewards of provider pool for specific periodId
     * @param _periodId Period ID to set rewards
     * @param _rewardPercentage Percentage to allocate for rewards, base 10000
     */
    function _setProviderReward(uint256 _periodId, uint256 _rewardPercentage)
        internal
    {
        uint256 _precision = 10000;
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];

            uint256 reward = (providersPool[tokenAddress] * _rewardPercentage) /
                (leverage * _precision);

            // Reward must be less than 25% of usersPool to ensure payout at all time
            if (
                reward > (usersPool[tokenAddress] * rewardsCapRate) / _precision
            ) {
                reward =
                    (usersPool[tokenAddress] * _rewardPercentage) /
                    _precision;
            }

            usersPool[tokenAddress] -= reward;
            providersPool[tokenAddress] += reward;

            emit ProviderRewardGenerated(
                _periodId,
                tokenAddress,
                _rewardPercentage,
                _precision,
                reward
            );
        }
    }

    /**
     * @notice Set rewards of user pool for specific periodId
     * @param _periodId Period ID to set rewards
     * @param _rewardPercentage Percentage to allocate for rewards, base 10000
     */
    function _setUserReward(uint256 _periodId, uint256 _rewardPercentage)
        internal
    {
        uint256 _precision = 10000;
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];

            uint256 compensation = (usersPool[tokenAddress] *
                leverage *
                _rewardPercentage) / _precision;

            // Compensation must be less than 25% of providersPool to ensure payout at all time
            if (
                compensation >
                (providersPool[tokenAddress] * rewardsCapRate) / _precision
            ) {
                compensation =
                    (providersPool[tokenAddress] * _rewardPercentage) /
                    _precision;
            }

            providersPool[tokenAddress] -= compensation;
            usersPool[tokenAddress] += compensation;

            emit UserCompensationGenerated(
                _periodId,
                tokenAddress,
                usersPool[tokenAddress],
                leverage,
                compensation
            );
        }
    }

    /**
     * @notice Withdraw staked tokens from Provider Pool
     * @param _amount Amount to withdraw
     * @param _tokenAddress Token address to withdraw
     * @param _nextVerifiablePeriod Next verifiable period id of current period
     * @param _contractFinished Present if SLA is terminated or finished
     */
    function _withdrawProviderTokens(
        uint256 _amount,
        address _tokenAddress,
        uint256 _nextVerifiablePeriod,
        bool _contractFinished
    ) internal onlyAllowedToken(_tokenAddress) nonReentrant {
        if (!_contractFinished) {
            require(
                lastProviderStake[msg.sender] < _nextVerifiablePeriod,
                'Provider lock-up until the next verification.'
            );

            // Allow provider withdrawal as long as the provider pool exceeds the leveraged user pool
            require(
                providersPool[_tokenAddress] - _amount >=
                    usersPool[_tokenAddress] * leverage,
                'Withdrawal exceeds leveraged cap.'
            );
        }

        dToken dpToken = dpTokenRegistry[_tokenAddress];
        // Burn duTokens in a way that doesn't affect the Provider Pool / DSLA-SP Pool average
        // t0/p0 = (t0-_amount)/(p0-burnedDPTokens)
        dpToken.burnFrom(
            msg.sender,
            (_amount * dpToken.totalSupply()) / providersPool[_tokenAddress]
        );
        providersPool[_tokenAddress] -= _amount;
        uint256 outstandingAmount = _distributeClaimingRewards(
            _amount,
            _tokenAddress
        );
        IERC20(_tokenAddress).safeTransfer(msg.sender, outstandingAmount);
    }

    /**
     * @notice Withdraw staked tokens from User Pool
     * @param _amount Amount to withdraw
     * @param _tokenAddress Token address to withdraw
     * @param _nextVerifiablePeriod Next verifiable period id of current period
     * @param _contractFinished Present if SLA is terminated or finished
     */
    function _withdrawUserTokens(
        uint256 _amount,
        address _tokenAddress,
        uint256 _nextVerifiablePeriod,
        bool _contractFinished
    ) internal onlyAllowedToken(_tokenAddress) nonReentrant {
        if (!_contractFinished) {
            require(
                lastUserStake[msg.sender] < _nextVerifiablePeriod,
                'User lock-up until the next verification.'
            );
        }

        dToken duToken = duTokenRegistry[_tokenAddress];
        // Burn duTokens in a way that doesn't affect the User Pool / DSLA-SP Pool average
        // t0/p0 = (t0-_amount)/(p0-burnedDUTokens)
        duToken.burnFrom(
            msg.sender,
            (_amount * duToken.totalSupply()) / usersPool[_tokenAddress]
        );
        usersPool[_tokenAddress] -= _amount;
        uint256 outstandingAmount = _distributeClaimingRewards(
            _amount,
            _tokenAddress
        );
        IERC20(_tokenAddress).safeTransfer(msg.sender, outstandingAmount);
    }

    /**
     * @notice Distribute rewards to owner and protocol when user claims
     * @param _amount Amount to withdraw
     * @param _tokenAddress Token address to withdraw
     * @return outstandingAmount
     */
    function _distributeClaimingRewards(uint256 _amount, address _tokenAddress)
        internal
        returns (uint256)
    {
        uint256 slaOwnerRewards = (_amount * ownerRewardsRate) / 10000;
        uint256 protocolRewards = (_amount * protocolRewardsRate) / 10000;
        IERC20(_tokenAddress).safeTransfer(owner(), slaOwnerRewards);
        IERC20(_tokenAddress).safeTransfer(
            _stakeRegistry.owner(),
            protocolRewards
        );
        return _amount - slaOwnerRewards - protocolRewards;
    }

    /**
     * @notice Get number of allowed tokens
     * @return Number of allowed tokens
     */
    function getAllowedTokensLength() external view returns (uint256) {
        return allowedTokens.length;
    }

    /**
     * @notice External view function that returns the number of stakers
     * @return Number of stakers
     */
    function getStakersLength() external view returns (uint256) {
        return stakersNum;
    }

    /**
     * @notice Check if the token is allowed or not
     * @param _tokenAddress Token address to check allowance
     * @return isAllowed
     */
    function isAllowedToken(address _tokenAddress) public view returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

interface IERC20Query {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';

contract dToken is ERC20PresetMinterPauser {
    uint8 _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20PresetMinterPauser(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}